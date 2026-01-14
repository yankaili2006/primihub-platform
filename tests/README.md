# PrimiHub 隐私计算测试工具集

本目录包含了PrimiHub平台的完整测试工具和文档，涵盖PSI、PIR和联邦学习三大核心功能。

## 📁 目录结构

```
tests/
├── psi/                          # PSI（隐私集合求交）测试
│   ├── test_psi_realtime.py     # ⭐ 实时PSI测试工具（推荐）
│   ├── create_psi_dh.py          # DH算法PSI任务创建
│   ├── create_psi_ot.py          # OT算法PSI任务创建
│   ├── create_psi_he.py          # HE算法PSI任务创建
│   ├── check_psi_tasks.py        # PSI任务状态查询
│   ├── README.md                 # PSI测试工具文档
│   └── PSI_TASKS_SUMMARY.md      # PSI任务总结
│
├── pir/                          # PIR（隐私信息检索）测试
│   ├── create_pir_dh.py          # PIR任务创建
│   ├── create_resource_and_test_pir.py  # 端到端PIR测试
│   ├── create_db_resource_and_test_pir.py  # 数据库PIR测试
│   ├── README.md                 # PIR测试工具文档
│   └── PIR_*.md                  # PIR相关文档
│
└── federated_learning/           # 联邦学习测试
    ├── test_end_to_end_fl.py     # ⭐ 端到端联邦学习测试（推荐）
    ├── create_fl_project_complete.py  # 创建联邦学习项目
    ├── run_fl_training_full.py   # 运行联邦学习训练
    ├── test_fl_with_real_data.py # 真实数据测试
    ├── README.md                 # 联邦学习测试工具文档
    └── *.md                      # 联邦学习相关文档
```

---

## 🚀 快速开始

### 环境准备

1. **安装Python依赖**

```bash
pip3 install requests pandas numpy scikit-learn
```

2. **确认PrimiHub平台运行**

```bash
# 检查平台状态
curl http://172.20.0.6:8080/sys/health
```

3. **配置API端点**

如果你的PrimiHub平台部署在其他地址，需要修改各脚本中的 `BASE_URL` 配置。

---

## 📖 核心功能

### 1. PSI（隐私集合求交）

在不泄露各方数据的前提下，计算多方数据的交集。

**快速测试**：
```bash
cd ~/primihub-platform/tests/psi
python3 test_psi_realtime.py dh
```

**支持的算法**：
- **DH**：密钥交换算法，高效
- **ECDH**：椭圆曲线算法，安全性高
- **OT (KKRT)**：不经意传输，保护查询隐私
- **HE (BC22)**：全同态加密，最强隐私

[详细文档](psi/README.md)

---

### 2. PIR（隐私信息检索）

允许用户从数据库检索信息而不泄露查询内容。

**快速测试**：
```bash
cd ~/primihub-platform/tests/pir
python3 create_resource_and_test_pir.py
```

**应用场景**：
- 医疗记录查询
- 金融数据检索
- 位置服务
- 广告匹配

[详细文档](pir/README.md)

---

### 3. 联邦学习

多方协作训练机器学习模型而不共享原始数据。

**快速测试**：
```bash
cd ~/primihub-platform/tests/federated_learning
python3 test_end_to_end_fl.py
```

**支持的算法**：
- XGBoost
- 逻辑回归
- 线性回归
- 神经网络

[详细文档](federated_learning/README.md)

---

## 🎯 使用场景

### 金融行业

1. **反欺诈检测**
   - 使用PSI进行黑名单匹配
   - 联邦学习训练风控模型
   - PIR查询用户信用记录

2. **联合风控**
   - 多家银行协作建模
   - 保护客户隐私
   - 提升风控效果

### 医疗健康

1. **疾病预测**
   - 多家医院联邦学习
   - PIR隐私病历查询
   - PSI计算共同患者

2. **药物研发**
   - 联合分析临床数据
   - 保护患者隐私
   - 加速研发进程

### 政务数据

1. **跨部门协作**
   - PSI数据对齐
   - 联邦分析政务数据
   - PIR隐私查询

2. **数据开放共享**
   - 在隐私保护前提下共享
   - 满足合规要求
   - 提升数据价值

---

## 🔧 配置说明

### 默认配置

所有测试脚本默认配置：

```python
# API端点
BASE_URL = "http://172.20.0.6:8080"

# 登录信息
USER_ACCOUNT = "admin"
USER_PASSWORD = "123456"

# 测试机构
ORGAN_ID_A = "000000000000000000000000test0001"
ORGAN_ID_B = "000000000000000000000000test0002"
```

### 修改配置

如果需要修改配置，可以：

1. **直接编辑脚本**（适合临时修改）
2. **使用环境变量**（适合批量修改）
3. **使用配置文件**（适合长期使用）

---

## 📊 测试矩阵

| 功能 | 基础测试 | 性能测试 | 压力测试 | 文档 |
|------|---------|---------|---------|------|
| **PSI - DH** | ✅ | ✅ | ⏳ | ✅ |
| **PSI - ECDH** | ✅ | ⏳ | ⏳ | ✅ |
| **PSI - OT** | ✅ | ⏳ | ⏳ | ✅ |
| **PSI - HE** | ✅ | ⏳ | ⏳ | ✅ |
| **PIR - DH** | ✅ | ⏳ | ⏳ | ✅ |
| **联邦学习 - XGBoost** | ✅ | ✅ | ⏳ | ✅ |
| **联邦学习 - LR** | ✅ | ⏳ | ⏳ | ✅ |

说明：
- ✅ 已完成
- ⏳ 进行中
- ❌ 未开始

---

## 🔍 常见问题

### Q1: 如何选择合适的PSI算法？

**A**: 根据场景选择：
- **大规模数据**：选择DH或ECDH
- **查询隐私敏感**：选择OT
- **极高隐私要求**：选择HE
- **平衡性能和隐私**：选择ECDH

### Q2: 联邦学习训练慢怎么办？

**A**: 可以尝试：
1. 减少训练轮数
2. 增大批量大小
3. 使用数据采样
4. 启用GPU加速
5. 优化网络连接

### Q3: PIR任务执行失败？

**A**: 检查：
1. 查询关键字是否存在
2. 数据资源配置是否正确
3. 节点间网络连接
4. 查看详细错误日志

### Q4: 如何查看详细日志？

**A**:
1. Web界面查看任务日志
2. 检查节点日志文件
3. 使用 `-v` 参数运行脚本

---

## 💡 最佳实践

### 1. 测试策略

- **从简单开始**：先测试基础功能，再测试复杂场景
- **小数据集验证**：用小数据集快速验证，再扩展到大规模
- **渐进式部署**：开发环境 → 测试环境 → 生产环境

### 2. 性能优化

- **批量处理**：一次性创建多个任务
- **并行执行**：充分利用计算资源
- **缓存结果**：避免重复计算

### 3. 安全考虑

- **最小权限**：只授予必要的权限
- **审计日志**：记录所有操作
- **定期review**：定期检查安全配置

### 4. 监控告警

- **实时监控**：监控任务执行状态
- **异常告警**：及时发现和处理异常
- **性能分析**：定期分析性能瓶颈

---

## 🌐 Web界面

**访问地址**：
```
http://192.168.99.5:30811
```

**登录信息**：
- 用户名：admin
- 密码：123456

**主要功能**：
- 任务管理
- 资源管理
- 结果查看
- 日志查询

---

## 📚 学习资源

### 官方文档

- [PrimiHub 官网](https://www.primihub.com)
- [GitHub 仓库](https://github.com/primihub/primihub)
- [API 文档](https://docs.primihub.com)

### 技术论文

- 联邦学习论文集
- 多方安全计算论文
- 隐私保护机器学习

### 社区资源

- 技术论坛
- 开发者社区
- 问题反馈渠道

---

## 🤝 贡献指南

我们欢迎各种形式的贡献：

1. **报告Bug**：提交Issue描述问题
2. **功能建议**：提出新功能需求
3. **代码贡献**：提交Pull Request
4. **文档改进**：完善文档和示例
5. **测试用例**：添加新的测试场景

### 贡献流程

1. Fork本仓库
2. 创建特性分支
3. 提交代码
4. 创建Pull Request
5. Code Review
6. 合并代码

---

## 📞 联系我们

如有问题或建议，请通过以下方式联系：

- **GitHub Issues**: [提交问题](https://github.com/primihub/primihub/issues)
- **邮件**: contact@primihub.com
- **社区论坛**: https://community.primihub.com

---

## 📄 许可证

本项目采用 Apache License 2.0 许可证。

---

## 🎉 致谢

感谢所有为PrimiHub项目做出贡献的开发者和用户！

---

**最后更新**: 2026-01-14
**维护者**: PrimiHub Team
**版本**: 1.0.0
