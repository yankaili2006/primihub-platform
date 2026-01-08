package com.primihub.biz.config.database;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.sql.DataSource;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Statement;

/**
 * 数据库初始化组件
 * 用于在应用启动时执行SQL初始化脚本
 */
@Slf4j
@Component
public class DatabaseInitializer {
    
    @Autowired
    @Qualifier("primaryDataSource")
    private DataSource primaryDataSource;
    
    @Autowired
    @Qualifier("secondaryDataSource")
    private DataSource secondaryDataSource;
    
    @PostConstruct
    public void init() {
        log.info("开始初始化数据库...");
        
        try {
            // 初始化主数据源
            initDataSource(primaryDataSource, "primary");
            
            // 初始化次数据源（对于H2内存数据库，它们共享同一个数据库）
            // 所以只需要初始化一次
            log.info("数据库初始化完成");
            
        } catch (Exception e) {
            log.error("数据库初始化失败", e);
            // 不抛出异常，让应用继续启动
            // 在开发环境中，我们允许数据库初始化失败
        }
    }
    
    private void initDataSource(DataSource dataSource, String dataSourceName) throws Exception {
        log.info("初始化{}数据源", dataSourceName);
        
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            
            // 设置H2兼容模式
            stmt.execute("SET MODE MySQL");
            
            // 执行schema-complete-h2.sql
            executeSqlFile(conn, "schema-complete-h2.sql", "表结构");
            
            // 执行data-complete-h2.sql
            executeSqlFile(conn, "data-complete-h2.sql", "测试数据");

            // 确保sys_user表有ip列（修复兼容性问题）
            try {
                stmt.execute("ALTER TABLE sys_user ADD COLUMN IF NOT EXISTS ip VARCHAR(255);");
                log.info("确保sys_user表有ip列");
            } catch (Exception e) {
                log.debug("添加ip列时出错（可能已存在）: {}", e.getMessage());
            }

            log.info("{}数据源初始化完成", dataSourceName);
            
        } catch (Exception e) {
            log.error("初始化{}数据源失败", dataSourceName, e);
            throw e;
        }
    }
    
    private void executeSqlFile(Connection conn, String fileName, String fileType) throws Exception {
        log.info("开始执行{}文件: {}", fileType, fileName);
        
        ClassPathResource resource = new ClassPathResource(fileName);
        if (!resource.exists()) {
            log.warn("{}文件不存在: {}", fileType, fileName);
            return;
        }
        
        try (InputStream inputStream = resource.getInputStream();
             BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
             Statement stmt = conn.createStatement()) {
            
            StringBuilder sqlBuilder = new StringBuilder();
            String line;
            int lineCount = 0;
            int executedCount = 0;
            
            while ((line = reader.readLine()) != null) {
                lineCount++;
                
                // 跳过注释和空行
                if (line.trim().isEmpty() || line.trim().startsWith("--")) {
                    continue;
                }
                
                sqlBuilder.append(line).append("\n");
                
                // 如果行以分号结束，执行SQL
                if (line.trim().endsWith(";")) {
                    String sql = sqlBuilder.toString();
                    try {
                        stmt.execute(sql);
                        executedCount++;
                    } catch (Exception e) {
                        // 对于CREATE TABLE IF NOT EXISTS，如果表已存在，忽略错误
                        if (sql.toUpperCase().contains("CREATE TABLE IF NOT EXISTS") && 
                            e.getMessage().contains("already exists")) {
                            log.debug("表已存在，跳过创建: {}", sql.substring(0, Math.min(sql.length(), 50)));
                        } else {
                            log.warn("执行SQL失败 (行{}): {}\n错误: {}", lineCount, 
                                    sql.substring(0, Math.min(sql.length(), 100)), e.getMessage());
                        }
                    }
                    sqlBuilder.setLength(0); // 清空StringBuilder
                }
            }
            
            // 执行最后一条可能没有分号的SQL
            if (sqlBuilder.length() > 0) {
                String sql = sqlBuilder.toString();
                try {
                    stmt.execute(sql);
                    executedCount++;
                } catch (Exception e) {
                    log.warn("执行最后一条SQL失败: {}\n错误: {}", 
                            sql.substring(0, Math.min(sql.length(), 100)), e.getMessage());
                }
            }
            
            log.info("{}文件执行完成: 总行数={}, 执行SQL数={}", fileType, lineCount, executedCount);
            
        } catch (Exception e) {
            log.error("执行{}文件失败: {}", fileType, fileName, e);
            throw e;
        }
    }
    
    /**
     * 检查表是否存在（用于测试）
     */
    public boolean checkTableExists(String tableName) {
        try (Connection conn = primaryDataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            
            // 尝试查询表
            stmt.executeQuery("SELECT 1 FROM " + tableName + " LIMIT 1");
            return true;
            
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * 获取数据库信息（用于测试）
     */
    public String getDatabaseInfo() {
        try (Connection conn = primaryDataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            
            return conn.getMetaData().getDatabaseProductName() + " " + 
                   conn.getMetaData().getDatabaseProductVersion();
            
        } catch (Exception e) {
            return "无法获取数据库信息: " + e.getMessage();
        }
    }
}