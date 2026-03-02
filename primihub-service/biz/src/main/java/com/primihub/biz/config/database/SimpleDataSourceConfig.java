package com.primihub.biz.config.database;

import com.alibaba.druid.pool.DruidDataSource;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;

import javax.sql.DataSource;

@Configuration
@Profile("simple")
public class SimpleDataSourceConfig {
    
    @Primary
    @Bean(name = "primaryDataSource")
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSource primaryDataSource() {
        return new DruidDataSource();
    }
    
    @Bean(name = "secondaryDataSource")
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSource secondaryDataSource() {
        return new DruidDataSource();
    }
    
    @Bean(name = "resourcePrimaryDataSource")
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSource resourcePrimaryDataSource() {
        return new DruidDataSource();
    }
    
    @Bean(name = "resourceSecondaryDataSource")
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSource resourceSecondaryDataSource() {
        return new DruidDataSource();
    }
}