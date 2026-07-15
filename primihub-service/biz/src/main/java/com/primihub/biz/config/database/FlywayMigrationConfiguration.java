package com.primihub.biz.config.database;

import lombok.extern.slf4j.Slf4j;
import org.flywaydb.core.Flyway;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.DependsOn;
import org.springframework.context.annotation.Profile;

import javax.sql.DataSource;

/**
 * Flyway 迁移: 让应用自己拥有 schema/seed 的**演进**(版本化迁移随启动幂等应用),
 * 取代手维护的部署 SQL dump 与后端漂移的问题。
 *
 * - 绑定到 {@code primaryDB}(Druid) 数据源 → 迁移作用于该节点实际连接的库
 *   (arm64 上是 privacy1/2/3, 生产 .130 上是 fusion*), 自动对齐, 无需感知库名。
 * - baseline: 已有生产库/全新 dump 已含基础 schema 且无 flyway_schema_history →
 *   baselineOnMigrate 打 baseline(V1) 标记, 只跑 V2+; 绝不重建基础 schema。
 * - 只做前向迁移; cleanDisabled 永不删库; validateOnMigrate 防误改已应用迁移。
 * - simple(H2) profile 下不加载(那里没有 primaryDB, 由 schema-complete-h2.sql 建表)。
 * - 运维开关: {@code app.flyway.enabled=false}(或 env APP_FLYWAY_ENABLED=false) 可关掉,
 *   回退到 dump 初始化。
 */
@Slf4j
@Configuration
@Profile("!simple")
@ConditionalOnProperty(name = "app.flyway.enabled", havingValue = "true", matchIfMissing = true)
public class FlywayMigrationConfiguration {

    @Bean(name = "flyway", initMethod = "migrate")
    @DependsOn("primaryDB")
    public Flyway flyway(@Qualifier("primaryDB") DataSource primaryDB) {
        log.info("Flyway: migrating schema evolution against primaryDB");
        return Flyway.configure()
                .dataSource(primaryDB)
                .locations("classpath:db/migration")
                .table("flyway_schema_history")
                .baselineOnMigrate(true)
                .baselineVersion("1")
                .baselineDescription("base schema from initsql dump")
                .validateOnMigrate(true)
                .cleanDisabled(true)
                .outOfOrder(false)
                .load();
    }
}
