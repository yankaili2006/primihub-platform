package com.primihub.biz.config.redis;

import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import redis.clients.jedis.JedisPoolConfig;

public class PrimaryRedisPoolConfigWrapper extends JedisPoolConfig implements InitializingBean {

    @Value("${spring.datasource.redis.primary.minIdle:0}")
    private int minIdle;
    @Value("${spring.datasource.redis.primary.maxIdle:8}")
    private int maxIdle;
    @Value("${spring.datasource.redis.primary.maxTotal:8}")
    private int maxTotal;
    @Value("${spring.datasource.redis.primary.lifo:true}")
    private boolean lifo;
    @Value("${spring.datasource.redis.primary.maxWaitMillis:-1}")
    private long maxWaitMillis;
    @Value("${spring.datasource.redis.primary.minEvictableIdleTimeMillis:1800000}")
    private long minEvictableIdleTimeMillis;
    @Value("${spring.datasource.redis.primary.softMinEvictableIdleTimeMillis:1800000}")
    private long softMinEvictableIdleTimeMillis;

    @Override
    public int getMinIdle() {
        return minIdle;
    }

    @Override
    public void setMinIdle(int minIdle) {
        this.minIdle = minIdle;
    }

    @Override
    public int getMaxIdle() {
        return maxIdle;
    }

    @Override
    public void setMaxIdle(int maxIdle) {
        this.maxIdle = maxIdle;
    }

    @Override
    public int getMaxTotal() {
        return maxTotal;
    }

    @Override
    public void setMaxTotal(int maxTotal) {
        this.maxTotal = maxTotal;
    }

    public boolean isLifo() {
        return lifo;
    }

    @Override
    public void setLifo(boolean lifo) {
        this.lifo = lifo;
    }

    @Override
    public long getMaxWaitMillis() {
        return maxWaitMillis;
    }

    @Override
    public void setMaxWaitMillis(long maxWaitMillis) {
        this.maxWaitMillis = maxWaitMillis;
    }

    @Override
    public long getMinEvictableIdleTimeMillis() {
        return minEvictableIdleTimeMillis;
    }

    @Override
    public void setMinEvictableIdleTimeMillis(long minEvictableIdleTimeMillis) {
        this.minEvictableIdleTimeMillis = minEvictableIdleTimeMillis;
    }

    @Override
    public long getSoftMinEvictableIdleTimeMillis() {
        return softMinEvictableIdleTimeMillis;
    }

    @Override
    public void setSoftMinEvictableIdleTimeMillis(long softMinEvictableIdleTimeMillis) {
        this.softMinEvictableIdleTimeMillis = softMinEvictableIdleTimeMillis;
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        super.setMinIdle(minIdle);
        super.setMaxIdle(maxIdle);
        super.setMaxTotal(maxTotal);
        super.setLifo(lifo);
        super.setMaxWaitMillis(maxWaitMillis);
        super.setMinEvictableIdleTimeMillis(minEvictableIdleTimeMillis);
        super.setSoftMinEvictableIdleTimeMillis(softMinEvictableIdleTimeMillis);
    }
}
