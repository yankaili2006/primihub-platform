package com.primihub.biz.config.database;

import com.alibaba.druid.pool.DruidDataSource;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

public class SecondaryDruidDataSourceWrapper extends DruidDataSource implements InitializingBean {
    @Value("${spring.datasource.druid.secondary.url}")
    private String url;
    @Value("${spring.datasource.druid.secondary.username}")
    private String username;
    @Value("${spring.datasource.druid.secondary.password}")
    private String password;
    @Value("${spring.datasource.druid.secondary.driver-class-name}")
    private String driverClassName;
    @Value("${spring.datasource.druid.secondary.connection-properties}")
    private String connectionProperties;
    @Value("${spring.datasource.druid.secondary.filter.config.enabled:false}")
    private Boolean filterConfigEnabled = false;


    public void setMaxWait(int maxWait) {
        this.maxWait = maxWait;
    }

    @Override
    public void setTimeBetweenEvictionRunsMillis(long timeBetweenEvictionRunsMillis) {
        this.timeBetweenEvictionRunsMillis = timeBetweenEvictionRunsMillis;
    }

    @Override
    public void setMinEvictableIdleTimeMillis(long minEvictableIdleTimeMillis) {
        this.minEvictableIdleTimeMillis = minEvictableIdleTimeMillis;
    }

    @Override
    public void setUrl(String url) {
        this.url = url;
    }

    @Override
    public void setDriverClassName(String driverClassName) {
        this.driverClassName = driverClassName;
    }

    @Override
    public void setConnectionProperties(String connectionProperties) {
        this.connectionProperties = connectionProperties;
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        super.setUrl(url);
        super.setUsername(username);
        super.setPassword(password);
        super.setDriverClassName(driverClassName);
        super.setInitialSize(initialSize);
        super.setMinIdle(minIdle);
        super.setMaxActive(maxActive);
        super.setMaxWait(maxWait);
        super.setTimeBetweenEvictionRunsMillis(timeBetweenEvictionRunsMillis);
        super.setMinEvictableIdleTimeMillis(minEvictableIdleTimeMillis);
        super.setValidationQuery(validationQuery);
        super.setTestWhileIdle(testWhileIdle);
        super.setTestOnBorrow(testOnBorrow);
        super.setTestOnReturn(testOnReturn);
        super.setPoolPreparedStatements(poolPreparedStatements);
        super.setMaxPoolPreparedStatementPerConnectionSize(maxPoolPreparedStatementPerConnectionSize);
        super.setConnectionProperties(connectionProperties);
        super.setDbType(dbType);
        if (filterConfigEnabled){
            super.addFilters("config");
        }
    }

}
