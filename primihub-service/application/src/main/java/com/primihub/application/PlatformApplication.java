package com.primihub.application;

import com.alibaba.nacos.spring.context.annotation.config.NacosPropertySource;
import com.alibaba.nacos.spring.context.annotation.config.NacosPropertySources;
import com.primihub.biz.config.mq.SingleTaskChannel;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.ServletComponentScan;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.cloud.stream.annotation.EnableBinding;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.boot.autoconfigure.hazelcast.HazelcastAutoConfiguration;

// @NacosPropertySources({
//         @NacosPropertySource(dataId = "base.json" ,autoRefreshed = true),
//         @NacosPropertySource(dataId = "components.json" ,autoRefreshed = true),
//         @NacosPropertySource(dataId = "database.yaml" ,autoRefreshed = true),
//         @NacosPropertySource(dataId = "redis.yaml" ,autoRefreshed = true)})
@SpringBootApplication(scanBasePackages="com.primihub",exclude = {HazelcastAutoConfiguration.class, org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration.class})
@EnableAsync
@ServletComponentScan(basePackages = {"com.primihub.biz.filter"})
// @EnableBinding({SingleTaskChannel.class})  // Disable messaging for local development
@EnableFeignClients(basePackages = {"com.primihub"})
@EnableScheduling
public class PlatformApplication {

    public static void main(String[] args) {
        SpringApplication.run(PlatformApplication.class, args);
    }

}
