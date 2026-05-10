package com.primihub.biz.service.data.analysis;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

import java.sql.SQLException;
import java.util.Map;

@Slf4j
public class DataSourceConnectorFactory {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    public static DataSourceConnector create(String sourceType, String sourceConfigJson) {
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> config = objectMapper.readValue(sourceConfigJson, Map.class);

            switch (sourceType.toLowerCase()) {
                case "mysql":
                case "postgresql":
                case "oracle":
                case "sqlserver":
                    return createRdbms(sourceType, config);
                default:
                    throw new IllegalArgumentException("Unsupported data source type: " + sourceType);
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to create data source connector: " + e.getMessage(), e);
        }
    }

    private static RdbmsConnector createRdbms(String type, Map<String, Object> config) throws SQLException {
        String host = (String) config.getOrDefault("host", "localhost");
        int port = config.get("port") != null ? Integer.parseInt(config.get("port").toString()) : 3306;
        String dbName = (String) config.getOrDefault("dbName", "");
        String username = (String) config.getOrDefault("username", "");
        String password = (String) config.getOrDefault("password", "");
        boolean ssl = config.get("ssl") != null && Boolean.parseBoolean(config.get("ssl").toString());
        return new RdbmsConnector(type, host, port, dbName, username, password, ssl);
    }
}
