# 联邦学习测试工具

本目录包含了PrimiHub平台联邦学习功能的完整测试工具和文档。

## 📁 文件说明

### 核心测试脚本

1. **test_end_to_end_fl.py** ⭐ 推荐使用
   - 端到端联邦学习测试
   - 包含数据准备、训练、结果验证
   - 完整的工作流程

2. **create_fl_project_complete.py**
   - 创建联邦学习项目
   - 配置参与方和资源
   - 设置训练参数

3. **run_fl_training_full.py**
   - 执行联邦学习训练任务
   - 支持多种算法（XGBoost、逻辑回归等）
   - 实时监控训练进度

4. **test_fl_with_real_data.py**
   - 使用真实数据测试联邦学习
   - 数据预处理和特征工程
   - 模型评估和验证

### 文档

- **FEDERATED_LEARNING_COMPLETE_SUMMARY.md** - 联邦学习完整总结
- **FL_TEST_SUMMARY.md** - 联邦学习测试总结
- **END_TO_END_FL_TEST_REPORT.md** - 端到端测试报告
- **JAR_DEPENDENCY_CONFLICT_ANALYSIS.md** - JAR依赖冲突分析
- **DOCKER_OFFLINE_INSTALL_GUIDE.md** - Docker离线安装指南
- **OFFLINE_DEPLOYMENT.md** - 离线部署指南
- **OFFLINE_IP_CONFIG_GUIDE.md** - 离线IP配置指南

---

## 🚀 快速开始

### 环境要求

- Python 3.6+
- requests、pandas、numpy等库
- PrimiHub平台正在运行

### 安装依赖

```bash
pip3 install requests pandas numpy scikit-learn
```

### 基本使用

```bash
cd ~/primihub-platform/tests/federated_learning

# 端到端测试（推荐）
python3 test_end_to_end_fl.py

# 创建联邦学习项目
python3 create_fl_project_complete.py

# 运行训练任务
python3 run_fl_training_full.py

# 使用真实数据测试
python3 test_fl_with_real_data.py
```

---

## 📖 什么是联邦学习

联邦学习（Federated Learning）是一种分布式机器学习技术，允许多个参与方在不共享原始数据的情况下，协作训练机器学习模型。

### 联邦学习的优势

1. **数据隐私**：原始数据不离开本地
2. **数据孤岛突破**：多方协作建模
3. **合规性**：满足数据保护法规要求
4. **模型性能**：利用更多数据提升模型效果

### 支持的算法

- **XGBoost**：梯度提升树
- **逻辑回归**：二分类算法
- **线性回归**：回归预测
- **神经网络**：深度学习模型

---

## 🎯 联邦学习工作流程

```
1. 项目创建
   ↓
2. 数据准备（各参与方）
   ↓
3. 资源注册
   ↓
4. 训练任务配置
   ↓
5. 模型训练（联邦协作）
   ↓
6. 模型聚合
   ↓
7. 结果评估
   ↓
8. 模型部署
```

---

## 📊 测试场景

### 1. 横向联邦学习

多个参与方拥有相同特征的不同样本数据。

**示例**：
- 多家医院协作训练疾病预测模型
- 多家银行协作训练信用评分模型

### 2. 纵向联邦学习

多个参与方拥有不同特征的相同样本数据。

**示例**：
- 银行和电商协作训练用户画像模型
- 医院和保险公司协作训练风险评估模型

---

## 🔧 配置说明

### API端点

```python
BASE_URL = "http://172.20.0.6:8080"
```

### 训练参数

常用训练参数配置：

```python
{
    "taskName": "联邦学习训练任务",
    "algorithm": "xgboost",  # 算法类型
    "projectId": "1",        # 项目ID
    "maxDepth": 3,           # 树深度
    "numRound": 5,           # 训练轮数
    "learningRate": 0.1,     # 学习率
    "objective": "binary:logistic"  # 目标函数
}
```

---

## 📝 任务监控

### 查看训练进度

```python
python3 run_fl_training_full.py --monitor
```

### 实时日志

训练过程中可以查看：
- 每轮训练的损失值
- 模型性能指标
- 各参与方的训练状态

---

## 🔍 故障排查

### 问题：训练任务启动失败

**解决方法**：
1. 检查所有参与方的节点是否在线
2. 验证数据资源是否正确配置
3. 确认训练参数格式正确

### 问题：训练过程中断

**解决方法**：
1. 查看各节点日志
2. 检查网络连接稳定性
3. 验证计算资源是否充足

### 问题：模型性能不佳

**解决方法**：
1. 调整训练参数（学习率、树深度等）
2. 增加训练轮数
3. 检查数据质量和特征工程
4. 验证数据分布是否合理

---

## 📊 性能优化

### 训练加速

1. **调整批量大小**：增大batch size提高训练速度
2. **减少通信轮数**：在保证效果的前提下减少通信
3. **使用GPU**：如果可用，启用GPU加速
4. **数据采样**：对大规模数据进行采样

### 模型优化

1. **特征选择**：去除无关特征
2. **超参数调优**：网格搜索或贝叶斯优化
3. **集成学习**：多模型融合
4. **正则化**：防止过拟合

---

## 🌐 Web界面访问

**访问地址**：
```
http://192.168.99.5:30811
```

**登录信息**：
- 用户名：admin
- 密码：123456

**导航路径**：
```
任务管理 → 联邦学习 → 训练任务
```

---

## 📚 技术参考

### 联邦学习论文

1. **Federated Learning**
   - McMahan et al. (2017). "Communication-Efficient Learning of Deep Networks from Decentralized Data"
   - AISTATS 2017

2. **Secure Aggregation**
   - Bonawitz et al. (2017). "Practical Secure Aggregation for Privacy-Preserving Machine Learning"
   - ACM CCS 2017

3. **Vertical Federated Learning**
   - Yang et al. (2019). "Federated Machine Learning: Concept and Applications"
   - ACM TIST 2019

---

## 💡 最佳实践

1. **数据准备**
   - 确保各方数据格式一致
   - 进行必要的数据清洗和预处理
   - 验证数据质量

2. **参数配置**
   - 从小规模数据开始测试
   - 逐步调整参数
   - 记录每次实验的配置和结果

3. **安全考虑**
   - 启用差分隐私保护
   - 配置合理的隐私预算
   - 监控潜在的隐私泄露

4. **性能监控**
   - 记录每轮训练时间
   - 监控网络通信量
   - 跟踪模型收敛情况

5. **结果验证**
   - 在独立测试集上评估
   - 对比集中式训练结果
   - 进行统计显著性检验

---

## 🤝 贡献

如果你发现问题或有改进建议，欢迎提交Issue或Pull Request。

---

## 📄 许可证

Apache License 2.0

---

**最后更新**: 2026-01-14
**维护者**: PrimiHub Team
