package com.primihub.biz.service.data.analysis;

import lombok.extern.slf4j.Slf4j;

import java.sql.*;
import java.util.*;

@Slf4j
public class RdbmsConnector implements DataSourceConnector {

    private final Connection connection;

    public RdbmsConnector(String type, String host, int port, String dbName,
                          String username, String password, boolean ssl) throws SQLException {
        String jdbcUrl = buildJdbcUrl(type, host, port, dbName, ssl);
        Properties props = new Properties();
        props.setProperty("user", username);
        props.setProperty("password", password);
        props.setProperty("connectTimeout", "10000");
        this.connection = DriverManager.getConnection(jdbcUrl, props);
    }

    private String buildJdbcUrl(String type, String host, int port, String dbName, boolean ssl) {
        String sslParam = ssl ? "?useSSL=true&requireSSL=true" : "?useSSL=false";
        switch (type.toLowerCase()) {
            case "mysql":
                return "jdbc:mysql://" + host + ":" + port + "/" + dbName + sslParam + "&serverTimezone=Asia/Shanghai";
            case "postgresql":
                return "jdbc:postgresql://" + host + ":" + port + "/" + dbName;
            case "oracle":
                return "jdbc:oracle:thin:@" + host + ":" + port + ":" + dbName;
            case "sqlserver":
                return "jdbc:sqlserver://" + host + ":" + port + ";databaseName=" + dbName;
            default:
                throw new IllegalArgumentException("Unsupported RDBMS type: " + type);
        }
    }

    @Override
    public boolean testConnection() {
        try {
            return connection != null && !connection.isClosed() && connection.isValid(5);
        } catch (SQLException e) {
            log.warn("RDBMS连接测试失败", e);
            return false;
        }
    }

    @Override
    public List<String> getTables() {
        List<String> tables = new ArrayList<>();
        try {
            DatabaseMetaData meta = connection.getMetaData();
            ResultSet rs = meta.getTables(null, null, "%", new String[]{"TABLE", "VIEW"});
            while (rs.next()) {
                tables.add(rs.getString("TABLE_NAME"));
            }
            rs.close();
        } catch (SQLException e) {
            log.error("获取表列表失败", e);
        }
        return tables;
    }

    @Override
    public List<Map<String, String>> getColumns(String tableName) {
        List<Map<String, String>> columns = new ArrayList<>();
        try {
            DatabaseMetaData meta = connection.getMetaData();
            ResultSet rs = meta.getColumns(null, null, tableName, "%");
            while (rs.next()) {
                Map<String, String> col = new HashMap<>();
                col.put("name", rs.getString("COLUMN_NAME"));
                col.put("type", rs.getString("TYPE_NAME"));
                col.put("size", String.valueOf(rs.getInt("COLUMN_SIZE")));
                columns.add(col);
            }
            rs.close();
        } catch (SQLException e) {
            log.error("获取字段列表失败", e);
        }
        return columns;
    }

    @Override
    public List<Map<String, Object>> executeQuery(String sql) {
        List<Map<String, Object>> results = new ArrayList<>();
        try (Statement stmt = connection.createStatement()) {
            stmt.setQueryTimeout(30);
            try (ResultSet rs = stmt.executeQuery(sql)) {
                ResultSetMetaData meta = rs.getMetaData();
                int columnCount = meta.getColumnCount();
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        row.put(meta.getColumnLabel(i), rs.getObject(i));
                    }
                    results.add(row);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("SQL执行失败: " + e.getMessage(), e);
        }
        return results;
    }

    @Override
    public void close() {
        try {
            if (connection != null && !connection.isClosed()) {
                connection.close();
            }
        } catch (SQLException e) {
            log.warn("关闭RDBMS连接失败", e);
        }
    }
}
