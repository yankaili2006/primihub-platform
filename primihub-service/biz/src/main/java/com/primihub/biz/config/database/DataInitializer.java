package com.primihub.biz.config.database;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.util.List;
import java.util.Map;

/**
 * Data initialization component
 * Disabled: JdbcTemplate auto-configuration not available in current setup
 */
@Slf4j
// @Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    @Qualifier("primaryDB")
    private DataSource dataSource;
    
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        log.info("开始初始化数据库数据...");
        
        try {
            // 检查sys_user表是否有数据 (使用小写表名)
            List<Map<String, Object>> users = jdbcTemplate.queryForList("SELECT COUNT(*) as count FROM sys_user");
            long userCount = (Long) users.get(0).get("count");
            
            if (userCount == 0) {
                log.info("初始化默认管理员用户...");
                
                // 插入默认管理员用户 (密码: admin)
                String insertUserSql = "INSERT INTO sys_user (user_id, user_account, user_password, user_name, role_id_list, is_forbid, is_editable, is_del, c_time, u_time, register_type) VALUES " +
                        "(1, 'admin', 'a0f34ffac5a82245e4fca2e21f358a42', '管理员', '1', 0, 1, 0, NOW(), NOW(), 1)";
                jdbcTemplate.execute(insertUserSql);
                
                log.info("默认管理员用户创建成功 - 账号: admin, 密码: admin");
            } else {
                log.info("数据库已有用户数据，跳过初始化");
            }
            
            // 检查sys_organ表 (使用小写表名)
            List<Map<String, Object>> organs = jdbcTemplate.queryForList("SELECT COUNT(*) as count FROM sys_organ");
            long organCount = (Long) organs.get(0).get("count");
            
            if (organCount == 0) {
                log.info("初始化默认机构...");
                String insertOrganSql = "INSERT INTO sys_organ (organ_id, organ_name, gateway_address, public_key, private_key, pin_code, organ_status, is_del, c_time, u_time) VALUES " +
                        "('organ1', '默认机构', 'http://localhost:8090', 'public_key_dev', 'private_key_dev', '123456', 1, 0, NOW(), NOW())";
                jdbcTemplate.execute(insertOrganSql);
            }
            
            log.info("数据库数据初始化完成");
            
        } catch (Exception e) {
            log.error("数据库初始化失败: {}", e.getMessage());
            log.debug("详细错误:", e);
        }
    }
}