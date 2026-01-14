# PrimiHub 隐私计算测试工具 - 快速开始指南

## 🎯 一键测试所有功能

最简单的方式是使用快速测试脚本：

```bash
cd ~/primihub-platform/tests
python3 quick_test.py
```

这个脚本会自动测试：
1. ✅ PSI（隐私集合求交）- DH算法
2. ✅ PIR（隐私信息检索）- DH算法
3. ✅ 联邦学习 - 项目创建

---

## 📖 分功能测试

### 1. PSI - 隐私集合求交

#### 测试DH算法（推荐首次测试）

```bash
cd ~/primihub-platform/tests/psi
python3 test_psi_realtime.py dh
```

**预期输出**：
```
================================================================================
🔐 Diffie-Hellman 密钥交换
================================================================================
算法类型: DH密钥交换
算法特点: 经典的密钥协商协议，计算效率高
主要特性: 高效, 大规模数据, 低通信开销
================================================================================

【步骤1】创建PSI任务...
✅ 任务创建成功!
  任务ID: 123
  算法: DH密钥交换

【步骤2】实时监控任务执行...
================================================================================
🔄 开始实时监控任务 (ID: 123)
================================================================================
[14:30:00] 任务状态: ⏳ 待执行 (0)
[14:30:05] 任务状态: 🔄 执行中 (1)
[14:30:15] 任务状态: ✅ 成功 (2)

================================================================================
🎉 任务执行成功!
================================================================================
总耗时: 15秒
```

#### 测试所有PSI算法

```bash
cd ~/primihub-platform/tests/psi
python3 test_psi_realtime.py all
```

这将创建4个PSI任务（DH、ECDH、OT、HE），并显示所有任务ID。

#### 查看已创建的PSI任务状态

```bash
cd ~/primihub-platform/tests/psi
python3 check_psi_tasks.py
```

---

### 2. PIR - 隐私信息检索

#### 端到端PIR测试（推荐）

```bash
cd ~/primihub-platform/tests/pir
python3 create_resource_and_test_pir.py
```

这个脚本会：
1. 创建测试数据资源
2. 注册资源到PrimiHub
3. 创建PIR任务
4. 查询结果

#### 基于数据库的PIR测试

```bash
cd ~/primihub-platform/tests/pir
python3 create_db_resource_and_test_pir.py
```

---

### 3. 联邦学习

#### 端到端联邦学习测试（推荐）

```bash
cd ~/primihub-platform/tests/federated_learning
python3 test_end_to_end_fl.py
```

这个脚本会：
1. 准备训练数据
2. 创建联邦学习项目
3. 配置训练参数
4. 启动训练任务
5. 监控训练进度
6. 获取训练结果

#### 分步骤测试

**步骤1：创建联邦学习项目**
```bash
cd ~/primihub-platform/tests/federated_learning
python3 create_fl_project_complete.py
```

**步骤2：运行训练任务**
```bash
cd ~/primihub-platform/tests/federated_learning
python3 run_fl_training_full.py
```

**步骤3：使用真实数据测试**
```bash
cd ~/primihub-platform/tests/federated_learning
python3 test_fl_with_real_data.py
```

---

## 🔧 常见问题解决

### 问题1：连接失败

```
❌ 登录失败，请检查配置
```

**解决方法**：

1. 检查PrimiHub是否运行：
```bash
curl http://172.20.0.6:8080/sys/health
```

2. 如果平台在其他地址，修改BASE_URL：
```bash
# 编辑脚本文件
vim psi/test_psi_realtime.py

# 修改这一行
BASE_URL = "http://你的IP:端口"
```

### 问题2：测试资源不存在

```
❌ 创建任务失败: 资源不存在
```

**解决方法**：

使用Web界面创建测试资源，或运行资源创建脚本：
```bash
cd ~/primihub-platform/tests/pir
python3 create_resource_and_test_pir.py
```

### 问题3：任务一直待执行

**解决方法**：

1. 检查节点状态：
```bash
# 查看Web界面
http://192.168.99.5:30811
# 导航：系统管理 → 节点管理
```

2. 查看任务日志：
```bash
# 通过Web界面查看详细日志
```

---

## 📊 性能基准测试

### PSI性能对比

在10万条记录的测试中：

| 算法 | 执行时间 | 通信量 | 隐私级别 |
|------|---------|--------|---------|
| DH | ~5秒 | 低 | ⭐⭐⭐ |
| ECDH | ~8秒 | 低 | ⭐⭐⭐⭐ |
| OT | ~15秒 | 中 | ⭐⭐⭐⭐ |
| HE | ~30秒 | 高 | ⭐⭐⭐⭐⭐ |

### 联邦学习性能

XGBoost训练（1000样本，10特征）：

- **训练轮数**: 5轮
- **每轮时间**: ~10秒
- **总时间**: ~50秒

---

## 🌐 Web界面操作

### 访问Web界面

```
URL: http://192.168.99.5:30811
用户名: admin
密码: 123456
```

### 查看PSI任务

1. 登录Web界面
2. 点击 **数据管理** → **PSI求交**
3. 查看任务列表和执行状态

### 查看联邦学习任务

1. 登录Web界面
2. 点击 **任务管理** → **联邦学习**
3. 查看训练任务和模型结果

---

## 💡 下一步

完成快速测试后，你可以：

1. **深入学习**：阅读各功能的详细文档
   - [PSI文档](psi/README.md)
   - [PIR文档](pir/README.md)
   - [联邦学习文档](federated_learning/README.md)

2. **自定义测试**：修改脚本参数，测试不同场景

3. **集成应用**：将PrimiHub集成到你的应用中

4. **性能调优**：优化参数，提升执行效率

---

## 📞 获取帮助

- **文档**: [完整文档](README.md)
- **问题反馈**: GitHub Issues
- **技术支持**: contact@primihub.com

---

**最后更新**: 2026-01-14
**版本**: 1.0.0
