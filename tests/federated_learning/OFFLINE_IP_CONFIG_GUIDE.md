# 离线环境 IP 配置说明

## 📋 当前配置中的 IP 地址

### 1. 镜像仓库地址（.env 文件）

```bash
PRIMIHUB_PLATFORM=192.168.99.10/primihub/privacy:1.8.0
PRIMIHUB_WEB_MANAGE=192.168.99.10/primihub/platform:1.8.0
```

**状态**：✅ **不影响离线部署**

**原因**：
- 这些是 Docker 镜像的完整名称，包含了私有镜像仓库地址
- 镜像已经打包在 tar 文件中
- 导入镜像时会保留这些名称，但 Docker 会使用本地镜像
- **Docker 不会尝试连接 192.168.99.10**

**验证方法**：
```bash
# 导入镜像后，查看本地镜像
docker images | grep 192.168.99.10

# 输出示例：
# 192.168.99.10/primihub/privacy    1.8.0    abc123    2 weeks ago    500MB
# 192.168.99.10/primihub/platform   1.8.0    def456    2 weeks ago    600MB
```

### 2. 服务间通信（docker-compose.yaml）

```yaml
# 示例：Meta 服务连接 Nacos
--spring.cloud.nacos.discovery.server-addr=nacos:8848
--spring.cloud.nacos.config.server-addr=nacos:8848

# 示例：环境变量中的 MySQL 主机
MYSQL_SERVICE_HOST=mysql
```

**状态**：✅ **不需要修改**

**原因**：
- 使用 Docker 容器名称进行通信（如 `nacos`, `mysql`）
- Docker Compose 会自动创建内部网络
- 容器名称会自动解析为容器的内部 IP
- 完全不依赖外部 IP 地址

### 3. 外部访问地址

```yaml
# 端口映射
ports:
  - "30811:80"  # 机构 0 Web 界面
  - "30812:80"  # 机构 1 Web 界面
  - "30813:80"  # 机构 2 Web 界面
  - "8848:8848" # Nacos 控制台
```

**状态**：⚠️ **需要知道离线服务器的 IP**

**说明**：
- 这些端口会映射到宿主机（离线服务器）
- 用户需要通过离线服务器的 IP 访问服务
- 例如：`http://离线服务器IP:30811`

## 🔧 离线环境部署配置

### 场景 1：单机部署（最常见）

**配置**：无需修改任何配置

**访问方式**：
```bash
# 获取服务器 IP
ip addr show | grep "inet " | grep -v 127.0.0.1

# 假设服务器 IP 是 10.0.0.100
# 访问地址：
http://10.0.0.100:30811  # 机构 0
http://10.0.0.100:30812  # 机构 1
http://10.0.0.100:30813  # 机构 2
http://10.0.0.100:8848/nacos  # Nacos
```

### 场景 2：多机部署（分布式）

如果需要在多台服务器上部署不同的服务，需要修改配置：

**步骤 1：修改 docker-compose.yaml**

将服务间通信的容器名称改为实际 IP 地址：

```yaml
# 原配置（单机）
--spring.cloud.nacos.discovery.server-addr=nacos:8848

# 修改为（多机）
--spring.cloud.nacos.discovery.server-addr=10.0.0.100:8848
```

**步骤 2：修改环境变量**

```bash
# data/env/nacos-mysql.env
MYSQL_SERVICE_HOST=10.0.0.101  # MySQL 服务器的 IP
```

### 场景 3：完全隔离的离线环境

**特点**：
- 无法访问任何外部网络
- 可能没有 DNS 服务
- 只能通过 IP 地址访问

**配置**：
1. ✅ 镜像仓库地址：无需修改（已在本地）
2. ✅ 服务间通信：使用容器名称（Docker 内部解析）
3. ⚠️ 外部访问：需要知道服务器 IP

**部署步骤**：
```bash
# 1. 解压部署包
tar -xzf primihub-offline-complete-*.tar.gz
cd primihub-offline-complete-*/

# 2. 一键部署（无需修改配置）
bash deploy-offline.sh primihub-images-*.tar

# 3. 获取服务器 IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "服务器 IP: $SERVER_IP"

# 4. 访问服务
echo "访问地址："
echo "  机构 0: http://$SERVER_IP:30811"
echo "  机构 1: http://$SERVER_IP:30812"
echo "  机构 2: http://$SERVER_IP:30813"
```

## 🚨 常见问题

### Q1: 镜像仓库 IP (192.168.99.10) 不通，会影响部署吗？

**A**: ❌ **不会影响**

- 镜像已经打包在 tar 文件中
- 导入后，Docker 会使用本地镜像
- 不会尝试连接远程仓库

### Q2: 如何验证不会连接外部 IP？

**A**: 可以在完全断网的环境中测试：

```bash
# 1. 断开网络（测试环境）
sudo ifconfig eth0 down

# 2. 部署 PrimiHub
bash deploy-offline.sh primihub-images-*.tar

# 3. 检查服务状态
docker compose ps

# 如果所有服务都正常启动，说明不依赖外部网络
```

### Q3: 如果离线服务器 IP 会变化怎么办？

**A**: 不需要担心

- 服务间通信使用容器名称，不依赖宿主机 IP
- 只有外部访问需要知道 IP
- IP 变化后，只需要用新 IP 访问即可
- 无需修改配置文件

### Q4: 如何在没有 DNS 的环境中部署？

**A**: 当前配置已经支持

- 服务间通信使用 Docker 内部 DNS（容器名称）
- 不依赖外部 DNS 服务
- 直接使用 IP 地址访问管理界面

### Q5: 多台服务器之间 IP 不通怎么办？

**A**: 如果是分布式部署，服务器之间必须能够通信

**解决方案**：
1. 配置网络，确保服务器之间可以互相访问
2. 或者使用单机部署（所有服务在一台服务器上）

## ✅ 推荐配置

### 单机离线部署（推荐）

**优点**：
- ✅ 无需修改任何配置
- ✅ 不依赖外部 IP
- ✅ 服务间通信通过 Docker 内部网络
- ✅ 部署简单，维护方便

**部署命令**：
```bash
# 一键部署，无需任何配置修改
bash deploy-offline.sh primihub-images-*.tar
```

**访问方式**：
```bash
# 获取服务器 IP
ip addr show | grep "inet " | grep -v 127.0.0.1

# 使用浏览器访问
http://<服务器IP>:30811
```

## 📝 配置检查清单

部署前检查：

- [ ] 离线服务器有足够的磁盘空间（至少 20GB）
- [ ] 离线服务器有足够的内存（至少 8GB）
- [ ] 部署包已完整传输（验证 MD5）
- [ ] 不需要修改镜像仓库地址（已在本地）
- [ ] 不需要修改服务间通信配置（使用容器名称）

部署后检查：

- [ ] 所有容器都在运行（`docker compose ps`）
- [ ] 可以通过服务器 IP 访问管理界面
- [ ] Nacos 控制台可以访问
- [ ] 服务注册正常（在 Nacos 中查看）

## 🎯 总结

**关键点**：

1. ✅ **镜像仓库 IP 不通不影响部署**
   - 镜像已在本地，不会连接远程仓库

2. ✅ **服务间通信不依赖外部 IP**
   - 使用 Docker 容器名称，内部自动解析

3. ⚠️ **只需要知道离线服务器的 IP**
   - 用于外部访问管理界面
   - 部署后通过 `ip addr` 或 `hostname -I` 获取

4. ✅ **默认配置适用于离线环境**
   - 无需修改任何配置
   - 一键部署即可

**最佳实践**：

```bash
# 1. 传输部署包到离线服务器
scp primihub-offline-complete-*.tar.gz user@offline-server:/opt/

# 2. 在离线服务器上解压
tar -xzf primihub-offline-complete-*.tar.gz
cd primihub-offline-complete-*/

# 3. 一键部署（会自动安装 Docker）
bash deploy-offline.sh primihub-images-*.tar

# 4. 获取访问地址
echo "访问地址: http://$(hostname -I | awk '{print $1}'):30811"
```

**完全离线环境部署成功的标志**：

- ✅ 所有容器正常运行
- ✅ 可以通过 IP 访问管理界面
- ✅ 服务间通信正常
- ✅ 没有任何网络连接错误

---

**结论**：当前的离线部署包已经完全适配离线环境，即使镜像仓库 IP (192.168.99.10) 不通也不会影响部署。
