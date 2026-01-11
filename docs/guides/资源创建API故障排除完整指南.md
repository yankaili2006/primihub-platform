# 资源创建API故障排除完整指南

> 本文档记录了通过API添加数据资源时遇到的所有问题及其完整解决方案

## 📋 目录

- [问题概述](#问题概述)
- [问题1: Nacos配置缺失](#问题1-nacos配置缺失)
- [问题2: organId长度错误](#问题2-organid长度错误)
- [问题3: gRPC代理干扰](#问题3-grpc代理干扰)
- [问题4: Protobuf版本冲突](#问题4-protobuf版本冲突)
- [完整解决方案](#完整解决方案)
- [验证步骤](#验证步骤)
- [技术要点](#技术要点)

---

## 问题概述

**症状**: 通过API添加数据资源时失败，请求超时或返回错误

**影响范围**:
- 文件上传API
- 资源创建API
- gRPC服务间通信

**最终状态**: ✅ 所有问题已解决，API正常工作

---

## 问题1: Nacos配置缺失

### 问题描述

**错误信息**:
```
java.lang.NullPointerException
at com.primihub.biz.config.base.OrganConfiguration.generateUniqueCode(OrganConfiguration.java:71)
```

**根本原因**:
- 系统缺少 `organ_info.json` Nacos配置
- 导致 `sysLocalOrganInfo` 为null
- `resourceFusionId` 无法生成

### 诊断过程

1. 检查application日志发现NullPointerException
2. 分析源码 `OrganConfiguration.java:149-150`
3. 发现需要从Nacos加载 `organ_info.json`
4. 查询Nacos确认配置不存在

### 解决方案

为所有命名空间创建 `organ_info.json` 配置：

```bash
TOKEN="your_nacos_token"

# demo0命名空间
curl -X POST "http://100.64.0.23:8848/nacos/v1/cs/configs" \
  -d "dataId=organ_info.json" \
  -d "group=DEFAULT_GROUP" \
  -d "tenant=demo0" \
  -d "content={\"organId\":\"000000000000000000000000demo0org0001\",\"organName\":\"Demo0 Organization\",\"gatewayAddress\":\"http://100.64.0.23:30811\",\"publicKey\":\"\"}" \
  -d "type=json" \
  -d "accessToken=$TOKEN"

# demo1命名空间
curl -X POST "http://100.64.0.23:8848/nacos/v1/cs/configs" \
  -d "dataId=organ_info.json" \
  -d "group=DEFAULT_GROUP" \
  -d "tenant=demo1" \
  -d "content={\"organId\":\"000000000000000000000000demo1org0001\",\"organName\":\"Demo1 Organization\",\"gatewayAddress\":\"http://100.64.0.23:30812\",\"publicKey\":\"\"}" \
  -d "type=json" \
  -d "accessToken=$TOKEN"

# demo2命名空间
curl -X POST "http://100.64.0.23:8848/nacos/v1/cs/configs" \
  -d "dataId=organ_info.json" \
  -d "group=DEFAULT_GROUP" \
  -d "tenant=demo2" \
  -d "content={\"organId\":\"000000000000000000000000demo2org0001\",\"organName\":\"Demo2 Organization\",\"gatewayAddress\":\"http://100.64.0.23:30813\",\"publicKey\":\"\"}" \
  -d "type=json" \
  -d "accessToken=$TOKEN"
```

**配置说明**:
- `organId`: 必须是36字符（见问题2）
- `organName`: 组织名称
- `gatewayAddress`: 网关地址
- `publicKey`: 公钥（可选）

### 验证

重启application服务后检查日志，不应再出现NullPointerException。

---

## 问题2: organId长度错误

### 问题描述

**错误信息**:
```
java.lang.StringIndexOutOfBoundsException: String index out of range: 36
at com.primihub.biz.config.base.OrganConfiguration.getLocalOrganShortCode(OrganConfiguration.java:64)
```

**根本原因**:
- 初始创建的organId只有32字符
- 代码要求至少36字符（substring(24, 36)）

### 诊断过程

1. 分析 `OrganConfiguration.java:60-65`:
```java
public String getLocalOrganShortCode() {
    if (sysLocalOrganInfo == null || sysLocalOrganInfo.getOrganId() == null) {
        return null;
    }
    return sysLocalOrganInfo.getOrganId().substring(24, 36);
}
```

2. 发现需要从位置24到36提取12个字符
3. 检查Nacos配置，发现organId只有32字符

### 解决方案

更新Nacos配置，使用36字符的organId：

**错误格式** (32字符):
```
000000000000000000000000demo0org
```

**正确格式** (36字符):
```
000000000000000000000000demo0org0001
```

格式说明：
- 前24个字符：填充字符（通常是0）
- 后12个字符：组织标识符

---

## 问题3: gRPC代理干扰

### 问题描述

**错误信息**:
```
W20260112 00:44:57.864032 1 grpc_impl.cc:53] PutMeta to Node [:primihub-meta0:9099:0:] rpc failed. 14: failed to connect to all addresses
E20260112 00:44:57.864594 1 service.cc:90] Put Meta data to meta service failed
```

**根本原因**:
- primihub-node容器继承了宿主机的HTTP_PROXY环境变量
- 代理地址为 `127.0.0.1:7890`（不存在）
- gRPC C++客户端尝试使用代理连接meta服务失败

### 诊断过程

1. 检查primihub-node日志，发现gRPC连接失败（错误码14: UNAVAILABLE）
2. 检查网络连通性：
```bash
docker exec primihub-node0 sh -c "timeout 5 bash -c '</dev/tcp/primihub-meta0/9099'"
# 结果：TCP连接正常 ✅
```

3. 检查容器环境变量：
```bash
docker inspect primihub-node0 | grep -A 15 "Env"
# 发现：HTTP_PROXY=http://127.0.0.1:7890
```

4. 结论：网络正常，但gRPC客户端被代理设置干扰

### 解决方案

修改 `docker-compose.yaml`，为所有node服务显式设置空的代理环境变量：

**文件**: `/home/primihub/github/primihub-deploy/docker-all-in-one/docker-compose.yaml`

```yaml
node0:
  image: $PRIMIHUB_NODE
  container_name: primihub-node0
  restart: "always"
  ports:
    - "50050:50050"
  volumes:
    - ./data:/data
  entrypoint:
    - "/bin/bash"
    - "-c"
    - "GLOG_logtostderr=1 GLOG_v=2 ./primihub-node --config=/app/config/primihub_node0.yaml"
  environment:
    - TZ=Asia/Shanghai
    - NO_PROXY=*
    - no_proxy=*
    - HTTP_PROXY=
    - HTTPS_PROXY=
    - http_proxy=
    - https_proxy=
  depends_on:
    meta0:
      condition: service_healthy
```

**同样修改 node1 和 node2**

### 部署

```bash
cd /home/primihub/github/primihub-deploy/docker-all-in-one
docker compose up -d --force-recreate node0 node1 node2
```

### 验证

检查node日志，不应再出现PutMeta连接错误：
```bash
docker logs primihub-node0 --tail 50 | grep "PutMeta.*failed"
# 应该没有输出
```

---

## 问题4: Protobuf版本冲突

### 问题描述

**错误信息**:
```
java.lang.NoSuchMethodError: com.google.protobuf.GeneratedMessageV3.isStringEmpty(Ljava/lang/Object;)Z
at java_data_service.MetaInfo.getSerializedSize(MetaInfo.java:532)
```

**根本原因**:
- 代码编译时使用了protobuf 3.21.x（包含 `isStringEmpty` 方法）
- 运行时加载的是protobuf 3.14.0（不包含此方法）
- Spring Boot的依赖管理覆盖了SDK中的protobuf版本

### 诊断过程

1. 检查application日志发现NoSuchMethodError
2. 分析错误：`isStringEmpty` 方法在protobuf 3.21.0+才存在
3. 检查JAR文件内容：
```bash
unzip -l application.jar | grep protobuf-java
# 发现：protobuf-java-3.14.0.jar ❌
```

4. 检查Maven依赖树：
```bash
mvn dependency:tree | grep protobuf
# 发现多个版本冲突
```

### 解决方案

需要在两个地方强制指定protobuf版本：

#### 步骤1: 修改 primihub-sdk/pom.xml

**文件**: `/home/primihub/github/primihub-platform/primihub-sdk/pom.xml`

```xml
<dependencies>
    <!-- 显式指定protobuf版本 -->
    <dependency>
        <groupId>com.google.protobuf</groupId>
        <artifactId>protobuf-java</artifactId>
        <version>3.21.12</version>
    </dependency>
    <dependency>
        <groupId>com.google.protobuf</groupId>
        <artifactId>protobuf-java-util</artifactId>
        <version>3.21.12</version>
    </dependency>

    <!-- 从grpc-all中排除旧版本 -->
    <dependency>
        <groupId>io.grpc</groupId>
        <artifactId>grpc-all</artifactId>
        <version>1.46.0</version>
        <exclusions>
            <exclusion>
                <groupId>com.google.protobuf</groupId>
                <artifactId>protobuf-java</artifactId>
            </exclusion>
            <exclusion>
                <groupId>com.google.protobuf</groupId>
                <artifactId>protobuf-java-util</artifactId>
            </exclusion>
        </exclusions>
    </dependency>
</dependencies>
```

#### 步骤2: 修改 primihub-service/pom.xml

**文件**: `/home/primihub/github/primihub-platform/primihub-service/pom.xml`

在 `<dependencyManagement>` 部分添加：

```xml
<dependencyManagement>
    <dependencies>
        <!-- 现有的依赖管理... -->

        <!-- 强制指定protobuf版本，覆盖Spring Boot的版本管理 -->
        <dependency>
            <groupId>com.google.protobuf</groupId>
            <artifactId>protobuf-java</artifactId>
            <version>3.21.12</version>
        </dependency>
        <dependency>
            <groupId>com.google.protobuf</groupId>
            <artifactId>protobuf-java-util</artifactId>
            <version>3.21.12</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

#### 步骤3: 重新编译

```bash
cd /home/primihub/github/primihub-platform

# 编译SDK
cd primihub-sdk
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=linux-x86_64

# 编译Service
cd ../primihub-service
mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true
```

#### 步骤4: 验证JAR内容

```bash
cd primihub-service/application/target
unzip -l application-1.0-SNAPSHOT.jar | grep protobuf-java
# 应该显示：
# protobuf-java-3.21.12.jar ✅
# protobuf-java-util-3.21.12.jar ✅
```

#### 步骤5: 部署

```bash
# 停止服务
docker stop application0 application1 application2

# 复制新的JAR文件
docker cp ~/github/primihub-platform/primihub-service/application/target/application-1.0-SNAPSHOT.jar application0:/applications/application.jar
docker cp ~/github/primihub-platform/primihub-service/application/target/application-1.0-SNAPSHOT.jar application1:/applications/application.jar
docker cp ~/github/primihub-platform/primihub-service/application/target/application-1.0-SNAPSHOT.jar application2:/applications/application.jar

# 启动服务
docker start application0 application1 application2
```

### 验证

等待服务启动后检查日志：
```bash
docker logs application0 2>&1 | grep "NoSuchMethodError"
# 应该没有输出 ✅
```

---

## 完整解决方案

### 修改的文件清单

1. **docker-compose.yaml**
   - 路径: `/home/primihub/github/primihub-deploy/docker-all-in-one/docker-compose.yaml`
   - 修改: 为node0/node1/node2添加空的代理环境变量

2. **primihub-sdk/pom.xml**
   - 路径: `/home/primihub/github/primihub-platform/primihub-sdk/pom.xml`
   - 修改: 添加protobuf 3.21.12依赖，排除grpc-all中的旧版本

3. **primihub-service/pom.xml**
   - 路径: `/home/primihub/github/primihub-platform/primihub-service/pom.xml`
   - 修改: 在dependencyManagement中强制指定protobuf版本

### Nacos配置

为demo0/demo1/demo2三个命名空间创建 `organ_info.json` 配置，包含36字符的organId。

### 部署步骤

```bash
# 1. 重新创建node容器（使用新的环境变量）
cd /home/primihub/github/primihub-deploy/docker-all-in-one
docker compose up -d --force-recreate node0 node1 node2

# 2. 重新编译并部署application
cd /home/primihub/github/primihub-platform
./build-platform-backend.sh 1.8.0-fixed
# 或手动编译并复制JAR文件（见问题4）

# 3. 重启application服务
docker restart application0 application1 application2
```

---

## 验证步骤

### 1. 检查gRPC连接

```bash
# 检查node日志，不应有PutMeta错误
docker logs primihub-node0 --tail 50 | grep "PutMeta.*failed"
# 预期：无输出
```

### 2. 检查protobuf错误

```bash
# 检查application日志，不应有NoSuchMethodError
docker logs application0 2>&1 | grep "NoSuchMethodError"
# 预期：无输出
```

### 3. 测试资源创建API

```bash
cd /home/primihub/primihub-platform/primihub-test-framework/tests
python3 create_resource_complete.py
```

**预期输出**:
```
✅ 文件上传成功 - fileId: XX
✅ 资源创建成功 - resourceId: XX
✅ 资源融合ID: demo0org0001-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 4. 检查服务健康状态

```bash
# 检查所有容器状态
docker ps | grep -E "application|node|meta"

# 检查application健康检查
curl http://100.64.0.23:30811/prod-api/healthConnection
# 预期：返回健康状态
```

---

## 技术要点

### 1. gRPC代理问题

**问题**: C++的gRPC客户端可能不正确处理NO_PROXY环境变量

**解决**: 显式设置空的代理环境变量（`HTTP_PROXY=`）而不是依赖NO_PROXY

**原因**:
- gRPC C++库的代理处理逻辑与Java不同
- NO_PROXY=* 在某些gRPC版本中不生效
- 必须显式清空代理变量

### 2. Maven依赖版本管理

**问题**: Spring Boot的依赖管理会覆盖传递依赖的版本

**解决**: 在父pom的dependencyManagement中强制指定版本

**最佳实践**:
```xml
<!-- 父pom.xml -->
<dependencyManagement>
    <dependencies>
        <!-- Spring Boot BOM -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-dependencies</artifactId>
            <version>${spring-boot.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>

        <!-- 在BOM之后强制指定版本，覆盖BOM中的版本 -->
        <dependency>
            <groupId>com.google.protobuf</groupId>
            <artifactId>protobuf-java</artifactId>
            <version>3.21.12</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

### 3. Protobuf版本兼容性

**版本对应关系**:
- protobuf 3.14.0 (2020-11): 不包含 `isStringEmpty` 方法
- protobuf 3.21.0 (2022-05): 添加 `isStringEmpty` 方法
- protobuf 3.21.12 (2022-12): 稳定版本，推荐使用

**gRPC版本对应**:
- gRPC 1.46.0: 默认使用protobuf 3.19.x
- gRPC 1.47.0+: 默认使用protobuf 3.21.x

**建议**: 如果使用gRPC 1.46.0，必须显式指定protobuf 3.21.x

### 4. Docker环境变量继承

**问题**: Docker容器会继承宿主机的环境变量

**影响**:
- HTTP_PROXY
- HTTPS_PROXY
- NO_PROXY

**解决**: 在docker-compose.yaml中显式设置环境变量，覆盖继承的值

### 5. Nacos配置热更新

**特性**: OrganConfiguration类有Nacos监听器，可以自动重新加载配置

**实际情况**: 某些情况下需要重启服务才能生效

**建议**: 修改Nacos配置后，重启相关服务以确保配置生效

---

## 故障排查流程

### 快速诊断清单

当资源创建API失败时，按以下顺序检查：

1. **检查Nacos配置**
```bash
TOKEN="your_token"
curl -s -X GET "http://100.64.0.23:8848/nacos/v1/cs/configs?dataId=organ_info.json&group=DEFAULT_GROUP&tenant=demo0&accessToken=$TOKEN"
```
- 确认配置存在
- 确认organId长度为36字符

2. **检查gRPC连接**
```bash
docker logs primihub-node0 --tail 50 | grep "PutMeta"
```
- 如果有"failed to connect"错误，检查代理设置

3. **检查protobuf版本**
```bash
docker exec application0 sh -c "unzip -l /applications/application.jar | grep protobuf-java"
```
- 确认版本为3.21.12

4. **检查服务日志**
```bash
docker logs application0 --tail 100 | grep -E "Exception|Error"
```
- 查找具体错误信息

### 常见错误速查表

| 错误信息 | 问题 | 解决方案 |
|---------|------|---------|
| NullPointerException at OrganConfiguration | Nacos配置缺失 | 创建organ_info.json |
| StringIndexOutOfBoundsException: 36 | organId长度不足 | 使用36字符organId |
| PutMeta rpc failed. 14 | gRPC连接失败 | 清空代理环境变量 |
| NoSuchMethodError: isStringEmpty | Protobuf版本冲突 | 升级到protobuf 3.21.12 |
| 503 Service Unavailable | 服务未启动 | 等待服务完全启动 |

---

## 后续建议

### 1. 升级依赖版本

考虑升级到更新的版本以避免类似问题：

```xml
<!-- 推荐版本 -->
<grpc.version>1.50.0</grpc.version>
<protobuf.version>3.21.12</protobuf.version>
```

### 2. 建立依赖管理规范

在项目根pom.xml中统一管理所有关键依赖的版本：

```xml
<properties>
    <protobuf.version>3.21.12</protobuf.version>
    <grpc.version>1.46.0</grpc.version>
</properties>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.google.protobuf</groupId>
            <artifactId>protobuf-java</artifactId>
            <version>${protobuf.version}</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

### 3. 添加CI/CD检查

在构建流程中添加依赖版本检查：

```bash
# 检查protobuf版本
mvn dependency:tree | grep protobuf-java | grep -v 3.21.12 && exit 1
```

### 4. 文档化环境要求

在README中明确说明：
- 不要在宿主机设置HTTP_PROXY环境变量
- 或者在docker-compose.yaml中显式清空代理变量

### 5. 监控和告警

添加监控指标：
- gRPC连接成功率
- API响应时间
- 错误日志告警（NoSuchMethodError, NullPointerException等）

---

## 参考资料

### 相关文档

- [添加数据资源指南.md](./添加数据资源指南.md)
- [gRPC修复部署指南.md](./gRPC修复部署指南.md)
- [Meta服务gRPC连接问题深度分析.md](./Meta服务gRPC连接问题深度分析.md)

### 源码位置

- OrganConfiguration: `primihub-service/biz/src/main/java/com/primihub/biz/config/base/OrganConfiguration.java`
- DataResourceService: `primihub-service/biz/src/main/java/com/primihub/biz/service/data/DataResourceService.java`
- primihub-node配置: `docker-all-in-one/config/node0/primihub_node0.yaml`

### 外部链接

- [Protobuf Release Notes](https://github.com/protocolbuffers/protobuf/releases)
- [gRPC Java Documentation](https://grpc.io/docs/languages/java/)
- [Spring Boot Dependency Management](https://docs.spring.io/spring-boot/docs/current/reference/html/dependency-versions.html)

---

## 更新日志

- **2026-01-11**: 初始版本，记录完整的问题诊断和解决过程
- 包含4个主要问题的详细解决方案
- 添加验证步骤和技术要点

---

**文档维护**: 如遇到新的问题或有改进建议，请更新本文档并记录在更新日志中。
