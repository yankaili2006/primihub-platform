package com.primihub.biz.config.database;

import com.alibaba.druid.pool.DruidDataSource;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

import javax.sql.DataSource;

@Slf4j
@Configuration
@MapperScan(basePackages = "com.primihub.biz.repository.secondarydb",sqlSessionFactoryRef="secondarySessionFactory")
public class SecondaryNacosDatabaseConfigConfiguration {

    @Value("classpath*:/mybatis/mapper/secondarydb/**/*.xml")
    private String locationPattern;

    @Value("${spring.datasource.druid.secondary.url:jdbc:mysql://mysql:3306/privacy?characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&allowMultiQueries=true&serverTimezone=Asia/Shanghai&useSSL=false}")
    private String secondaryUrl;

    @Value("${spring.datasource.druid.secondary.username:root}")
    private String secondaryUsername;

    @Value("${spring.datasource.druid.secondary.password:root}")
    private String secondaryPassword;

    @Bean(name = "secondaryDB",initMethod = "init")
    public DruidDataSource dataSource() {
        log.info("Init Secondary DruidDataSource, URL: {}", secondaryUrl);
        SecondaryDruidDataSourceWrapper ds = new SecondaryDruidDataSourceWrapper();
        ds.setUrl(secondaryUrl);
        ds.setUsername(secondaryUsername);
        ds.setPassword(secondaryPassword);
        return ds;
    }

    @Bean("secondarySessionFactory")
    public SqlSessionFactory sqlSessionFactory(@Qualifier("secondaryDB") DataSource dataSource) throws Exception {
        SqlSessionFactoryBean sessionFactory = new SqlSessionFactoryBean();
        sessionFactory.setDataSource(dataSource);
        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        sessionFactory.setMapperLocations(resolver.getResources(locationPattern));
        return sessionFactory.getObject();
    }

}
