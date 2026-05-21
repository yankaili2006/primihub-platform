package com.primihub.biz.service.data.analysis;

import java.sql.*;
import java.util.*;

public interface DataSourceConnector {
    boolean testConnection();
    List<String> getTables();
    List<Map<String, String>> getColumns(String tableName);
    List<Map<String, Object>> executeQuery(String sql);
    void close();
}
