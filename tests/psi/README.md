# PSI（隐私集合求交）测试工具

本目录包含了PrimiHub平台PSI功能的完整测试工具和文档。

## 📁 文件说明

### 核心测试脚本

1. **test_psi_realtime.py** ⭐ 推荐使用
   - 实时PSI测试管理工具（统一入口）
   - 支持所有PSI算法：DH、ECDH、OT、HE
   - 自动创建任务、实时监控、结果获取
   - 完整的命令行界面

2. **create_psi_dh.py**
   - 创建基于DH（密钥交换）算法的PSI任务
   - 适用于大规模数据集
   - 高计算效率

3. **create_psi_ot.py**
   - 创建基于OT（不经意传输）算法的PSI任务
   - 使用KKRT协议
   - 保护查询方隐私

4. **create_psi_he.py**
   - 创建基于HE（全同态加密）算法的PSI任务
   - 使用BC22协议
   - 提供最强隐私保护

5. **check_psi_tasks.py**
   - 查询PSI任务状态
   - 显示任务执行进度

### 文档

- **PSI_TASKS_SUMMARY.md** - PSI任务创建总结和算法对比

---

## 🚀 快速开始

### 环境要求

- Python 3.6+
- requests库：`pip3 install requests`
- PrimiHub平台正在运行

### 使用实时测试工具（推荐）

```bash
cd ~/primihub-platform/tests/psi

# 测试DH密钥交换算法
python3 test_psi_realtime.py dh

# 测试ECDH椭圆曲线算法
python3 test_psi_realtime.py ecdh

# 测试OT不经意传输算法
python3 test_psi_realtime.py ot

# 测试HE全同态加密算法
python3 test_psi_realtime.py he

# 批量测试所有算法
python3 test_psi_realtime.py all

# 监控特定任务
python3 test_psi_realtime.py monitor <task_id>
```

### 使用单独脚本

```bash
# 创建DH算法任务
python3 create_psi_dh.py

# 创建OT算法任务
python3 create_psi_ot.py

# 创建HE算法任务
python3 create_psi_he.py

# 查看任务状态
python3 check_psi_tasks.py
```

---

## 📊 支持的算法

| 算法 | psiTag | 特点 | 适用场景 |
|------|--------|------|---------|
| **DH** | 0 | 密钥交换，高效 | 大规模数据集 |
| **ECDH** | 1 | 椭圆曲线，安全性高 | 中等规模，需要更高安全性 |
| **OT (KKRT)** | 2 | 不经意传输，保护查询隐私 | 查询隐私敏感场景 |
| **HE (BC22)** | 3 | 全同态加密，最强隐私 | 极高隐私要求 |

---

## 🔧 配置说明

### API端点配置

默认配置（可在脚本中修改）：

```python
BASE_URL = "http://172.20.0.6:8080"
```

如果你的PrimiHub平台部署在其他地址，需要修改此配置。

### 测试数据

默认使用以下测试资源：

- **发起方**：机构A (test0001) - 资源ID: 3
- **协作方**：机构B (test0002) - 资源ID: 4
- **匹配字段**：user_id

---

## 📖 详细功能说明

### 1. 实时任务监控

`test_psi_realtime.py` 提供自动任务监控功能：

- **自动轮询**：每5秒检查一次任务状态
- **实时更新**：显示任务进度和状态变化
- **超时控制**：默认300秒超时（可配置）
- **结果获取**：任务完成后自动显示结果信息

### 2. 批量测试

一次性创建所有算法的PSI任务：

```bash
python3 test_psi_realtime.py all
```

输出示例：
```
🚀 批量创建所有PSI算法任务
================================================================================
测试算法: DH密钥交换
✅ DH密钥交换 - 任务ID: 123
────────────────────────────────────────────────────────────────────────────────
测试算法: ECDH椭圆曲线
✅ ECDH椭圆曲线 - 任务ID: 124
...
```

### 3. 任务状态查询

查询现有PSI任务的执行状态：

```bash
python3 check_psi_tasks.py
```

或使用实时工具监控特定任务：

```bash
python3 test_psi_realtime.py monitor 123
```

---

## 🎯 算法选择建议

### 选择DH算法

- ✅ 数据集规模大（百万级以上）
- ✅ 对计算效率有要求
- ✅ 网络带宽有限
- ✅ 基本的隐私保护需求

### 选择ECDH算法

- ✅ 需要更高的安全性
- ✅ 中等规模数据集
- ✅ 可以接受略高的计算开销

### 选择OT算法

- ✅ 需要保护查询方隐私
- ✅ 有TEE（可信执行环境）支持
- ✅ 对单方隐私保护有特殊要求
- ✅ 批量查询场景

### 选择HE算法

- ✅ 对隐私保护要求极高
- ✅ 可以接受较高的计算开销
- ✅ 需要支持复杂的加密计算
- ✅ 监管合规要求严格

---

## 📝 任务执行流程

```
1. 登录系统
   ↓
2. 创建PSI任务
   ↓
3. 任务进入队列（状态: 0 待执行）
   ↓
4. 任务开始执行（状态: 1 执行中）
   ↓
5. 任务完成（状态: 2 成功 / 3 失败）
   ↓
6. 获取结果
```

### 任务状态码

- **0** - 待执行
- **1** - 执行中
- **2** - 成功
- **3** - 失败

---

## 🔍 故障排查

### 问题：登录失败

```
❌ 登录失败，请检查配置
```

**解决方法**：
1. 检查PrimiHub平台是否正在运行
2. 确认API端点地址正确（BASE_URL）
3. 验证用户名密码（默认：admin/123456）

### 问题：任务创建失败

```
❌ 创建任务失败: 资源不存在
```

**解决方法**：
1. 确认测试资源已创建（资源ID: 3, 4）
2. 检查机构ID是否正确
3. 验证项目ID是否存在

### 问题：任务执行失败

```
❌ 任务执行失败
错误信息: ...
```

**解决方法**：
1. 查看详细错误信息
2. 检查日志文件
3. 验证数据资源的格式和内容
4. 确认节点之间网络连接正常

### 问题：任务一直处于待执行状态

**解决方法**：
1. 检查任务调度器是否正常运行
2. 查看节点日志
3. 确认计算资源是否充足

---

## 🌐 Web界面访问

除了使用命令行工具，还可以通过Web界面查看PSI任务：

**访问地址**：
```
http://192.168.99.5:30811
```

**登录信息**：
- 用户名：admin
- 密码：123456

**导航路径**：
```
数据管理 → PSI求交 → 任务列表
```

---

## 📚 技术参考

### PSI算法论文

1. **DH协议**
   - Diffie, W., & Hellman, M. (1976). "New Directions in Cryptography"
   - IEEE Transactions on Information Theory

2. **KKRT协议**
   - Kolesnikov et al. (2016). "Efficient Batched Oblivious PRF with Applications to PSI"
   - ACM CCS 2016

3. **BC22协议**
   - Branco et al. (2022). "Better Concrete Security for PSI"
   - Cryptology ePrint Archive

### API文档

PSI任务创建API：
```
POST /data/psi/saveDataPsi
```

PSI任务查询API：
```
GET /data/psi/getPsiTaskList
GET /data/task/getTaskData
```

---

## 💡 最佳实践

1. **首次测试**：建议先使用DH算法进行测试，验证环境配置
2. **性能测试**：对比不同算法的执行时间和资源消耗
3. **隐私评估**：根据业务需求选择合适的隐私保护级别
4. **监控告警**：在生产环境中配置任务执行监控和告警
5. **日志记录**：保留详细的执行日志，便于问题排查

---

## 🤝 贡献

如果你发现问题或有改进建议，欢迎提交Issue或Pull Request。

---

## 📄 许可证

Apache License 2.0

---

**最后更新**: 2026-01-14
**维护者**: PrimiHub Team
