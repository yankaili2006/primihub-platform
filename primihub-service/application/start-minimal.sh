#!/bin/bash

# 停止可能运行的服务
pkill -f "application-1.0-SNAPSHOT.jar" 2>/dev/null || true

echo "启动PrimiHub Application服务（最小化配置）..."
echo "使用H2内存数据库，禁用Nacos和gRPC依赖"

# 设置环境变量禁用云配置
export SPRING_CLOUD_CONFIG_ENABLED=false
export SPRING_CLOUD_NACOS_CONFIG_ENABLED=false
export SPRING_CLOUD_NACOS_DISCOVERY_ENABLED=false

# 启动服务
java -jar target/application-1.0-SNAPSHOT.jar \
  --spring.config.location=file:$(pwd)/application-minimal.yaml \
  --spring.cloud.nacos.config.enabled=false \
  --spring.cloud.nacos.discovery.enabled=false \
  --logging.level.com.primihub.sdk=ERROR \
  --logging.level.org.springframework.cloud=WARN \
  2>&1 | tee /tmp/primihub-app.log &

echo "服务启动中，查看日志: tail -f /tmp/primihub-app.log"
echo "前端地址: http://localhost:8080"
echo "API地址: http://localhost:8090"
echo "H2控制台: http://localhost:8090/h2-console"
echo "JDBC URL: jdbc:h2:mem:primarydb"
echo "用户名: sa"
echo "密码: (空)"
