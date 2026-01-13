# gRPC连接问题修复指南

生成时间: 2026-01-11 20:00
修复状态: ✅ 源代码已修改

## 🎯 问题总结

**根本原因**: primihub-node的gRPC C++客户端缺少必要的channel参数，导致无法与Meta服务的Java gRPC服务器完成HTTP/2协商。

**修复方法**: 在`grpc_impl.cc`中添加gRPC channel参数配置。

## ✅ 已完成的修改

### 修改文件
`~/github/primihub/src/primihub/service/dataset/meta_service/grpc_impl.cc`

### 修改内容
```cpp
// 修改前 (第16-17行)
grpc::ChannelArguments channel_args;
// channel_args.SetMaxReceiveMessageSize(128*1024*1024);

// 修改后 (第16-26行)
grpc::ChannelArguments channel_args;

// Set channel arguments to improve compatibility with grpc-spring-boot-starter
channel_args.SetMaxReceiveMessageSize(128*1024*1024);
channel_args.SetMaxSendMessageSize(128*1024*1024);
channel_args.SetInt(GRPC_ARG_KEEPALIVE_TIME_MS, 30000);
channel_args.SetInt(GRPC_ARG_KEEPALIVE_TIMEOUT_MS, 10000);
channel_args.SetInt(GRPC_ARG_KEEPALIVE_PERMIT_WITHOUT_CALLS, 1);
channel_args.SetInt(GRPC_ARG_HTTP2_MAX_PINGS_WITHOUT_DATA, 0);
channel_args.SetInt(GRPC_ARG_HTTP2_BDP_PROBE, 1);
```

### 修改说明

| 参数 | 值 | 说明 |
|------|-----|------|
| `MaxReceiveMessageSize` | 128MB | 最大接收消息大小 |
| `MaxSendMessageSize` | 128MB | 最大发送消息大小 |
| `KEEPALIVE_TIME_MS` | 30秒 | Keep-alive间隔 |
| `KEEPALIVE_TIMEOUT_MS` | 10秒 | Keep-alive超时 |
| `KEEPALIVE_PERMIT_WITHOUT_CALLS` | 1 | 允许无调用时keep-alive |
| `HTTP2_MAX_PINGS_WITHOUT_DATA` | 0 | 允许无限ping |
| `HTTP2_BDP_PROBE` | 1 | 启用带宽延迟探测 |

## 📋 编译和部署步骤

### 方法1: 完整重新编译（推荐）

```bash
# 1. 进入源代码目录
cd ~/github/primihub

# 2. 验证修改
git diff src/primihub/service/dataset/meta_service/grpc_impl.cc

# 3. 运行预构建脚本
bash pre_build.sh

# 4. 编译项目（使用Bazel）
make release mysql=y

# 5. 检查编译结果
ls -lh bazel-bin/node

# 6. 构建Docker镜像
bash build_docker.sh FULL 1.8.0-grpc-fix 192.168.99.10/primihub/primihub-node

# 预计时间: 30-60分钟
```

### 方法2: 快速Docker构建

```bash
cd ~/github/primihub

# 使用本地构建脚本（更快）
bash build_local.sh 1.8.0-grpc-fix 192.168.99.10/primihub/primihub-node
```

### 方法3: 仅编译Node二进制

```bash
cd ~/github/primihub

# 仅编译node组件
bazel build //node:node --compilation_mode=opt

# 复制到容器（如果已有运行的容器）
docker cp bazel-bin/primihub-node primihub-node2:/app/primihub-node.new
docker exec primihub-node2 sh -c "mv /app/primihub-node /app/primihub-node.old && mv /app/primihub-node.new /app/primihub-node"
docker restart primihub-node2
```

## 🚀 部署步骤

### 步骤1: 停止现有容器

```bash
cd /home/primihub/github/primihub-deploy/docker-all-in-one

# 停止所有node容器
docker stop primihub-node0 primihub-node1 primihub-node2
```

### 步骤2: 更新镜像标签

编辑 `docker-compose.yml`:

```yaml
services:
  primihub-node2:
    image: 192.168.99.10/primihub/primihub-node:1.8.0-grpc-fix  # 更新这里
    # ... 其他配置不变
```

### 步骤3: 启动容器

```bash
# 启动node2
docker-compose up -d primihub-node2

# 检查日志
docker logs -f primihub-node2
```

### 步骤4: 验证修复

```bash
# 查看日志，应该不再有 "failed to connect" 错误
docker logs primihub-node2 2>&1 | grep -E "Meta|meta"

# 应该看到类似：
# I20260111 20:10:02 📃 Load default datasets from config
# (没有错误日志)
```

## 🧪 测试修复效果

### 测试1: 检查Node日志

```bash
docker logs primihub-node2 2>&1 | tail -50

# ✅ 成功标志: 无 "failed to connect to all addresses" 错误
# ✅ 成功标志: 看到 "PutMeta to node: [...] rpc succeeded"
```

### 测试2: 测试资源创建API

```bash
cd /home/primihub/primihub-platform/primihub-test-framework/tests

# 使用之前的token测试
python3 test_with_new_token.py

# 期望结果:
# ✅ "code": 0
# ✅ "msg": "成功"
# ✅ "result": {"resourceId": 123}
```

### 测试3: 查询资源列表

```python
# 应该能看到刚创建的资源
python3 << 'EOF'
import requests
TOKEN = "SU2026011119425868F77BF514722324D1A684973415FB86"
BASE_URL = "http://100.64.0.23:30811/prod-api"

response = requests.get(
    f"{BASE_URL}/data/resource/getDerivationResourceList",
    params={'pageNo': 1, 'pageSize': 10, 'token': TOKEN},
    headers={'userId': '1'}
)
print(response.json())
EOF
```

## 📊 预期结果

### 修复前
```
W20260111 18:33:02 grpc_impl.cc:53] PutMeta to Node [:primihub-meta2:9099:0:] rpc failed. 14: failed to connect to all addresses
E20260111 18:33:02 service.cc:90] Put Meta data to meta service failed
```

### 修复后
```
I20260111 20:10:02 service.cc:176] 📃 Load default datasets from config
I20260111 20:10:02 service.cc:185] Successfully registered dataset to meta service
V20260111 20:10:02 grpc_impl.cc:49] PutMeta to node: [:primihub-meta2:9099:0:] rpc succeeded
```

## ⚠️ 注意事项

### 1. 编译环境要求

```bash
# 必需的依赖
- Bazel (已安装)
- GCC/G++ 7.0+
- Python 3.8
- MySQL开发库

# 检查依赖
bazel version
gcc --version
python3 --version
```

### 2. 磁盘空间

编译需要大约**10GB**磁盘空间：
```bash
# 检查可用空间
df -h ~/github/primihub
```

### 3. 编译时间

- **首次编译**: 30-60分钟
- **增量编译**: 5-10分钟

### 4. Docker镜像大小

新镜像大小约**1.5GB**

### 5. 回滚方案

如果修复后仍有问题：

```bash
# 恢复原始代码
cd ~/github/primihub
git checkout src/primihub/service/dataset/meta_service/grpc_impl.cc

# 或使用原镜像
docker-compose.yml 中改回:
  image: registry.cn-beijing.aliyuncs.com/primihub/primihub-node:1.7.0
```

## 🔧 编译问题排查

### 问题1: Bazel编译失败

```bash
# 清理Bazel缓存
bazel clean --expunge

# 重新编译
make release mysql=y
```

### 问题2: 依赖下载慢

```bash
# 设置代理
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890

# 或使用国内镜像
bash pre_build.sh
```

### 问题3: Python版本不匹配

```bash
# 确保使用Python 3.8
python3 --version  # 应该显示 3.8.x

# 如果不是，可能需要:
update-alternatives --config python3
```

## 📝 相关文档

- **根因分析**: `根因分析-gRPC连接失败.md`
- **源代码分析**: `源代码分析完成报告.md`
- **完整调查**: `最终完整分析报告.md`
- **Patch文件**: `grpc_channel_fix.patch`

## 🎯 下一步

### 短期（修复后立即）

1. ✅ 验证gRPC连接正常
2. ✅ 测试资源创建API
3. ✅ 创建测试资源

### 中期（1-2天）

1. 提交Pull Request到primihub官方仓库
2. 更新所有node容器（node0, node1, node2）
3. 完整的系统测试

### 长期（根据需要）

1. 监控gRPC连接稳定性
2. 考虑升级到更新版本
3. 优化其他gRPC参数

## 📞 技术支持

如果修复后仍有问题：

1. **检查日志**:
   ```bash
   docker logs primihub-node2 2>&1 | grep -E "Error|error|failed"
   docker logs primihub-meta2 2>&1 | grep -i grpc
   ```

2. **联系官方**:
   - GitHub Issue: https://github.com/primihub/primihub/issues
   - 附上修复尝试和日志

3. **回滚方案**: 使用原始镜像，通过Web界面创建资源

---

## ✅ 总结

**修复内容**: 在gRPC C++客户端添加了7个关键channel参数

**预期效果**: Node能够成功连接到Meta服务，资源创建API正常工作

**下一步**: 编译新镜像并部署测试

**时间估计**: 编译30-60分钟 + 部署5分钟

---

**修复完成时间**: 2026-01-11 20:00
**修改文件数**: 1个
**新增代码行**: 8行
**预计解决问题**: gRPC连接失败 (错误码14)
