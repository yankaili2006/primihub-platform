# 联邦学习自动化工具集

本目录包含实现联邦学习100%自动化的相关脚本、数据和日志。

## 📁 目录结构

```
automation/
├── scripts/          # 自动化脚本
├── data/            # 示例训练数据
├── logs/            # 执行日志
└── README.md        # 本文件
```

## 🔧 脚本说明

### scripts/generate_lr_data.py

自动生成联邦学习LR模型的训练数据。

**功能**:
- 生成带标签的用户特征数据
- 支持多机构数据分布
- 自动计算正负样本比例

**使用方法**:
```bash
python3 automation/scripts/generate_lr_data.py
```

**输出**:
- `org1_lr_data.csv` - 机构1的训练数据（50条）
- `org2_lr_data.csv` - 机构2的训练数据（50条）

**数据格式**:
```csv
user_id,age,income,credit_score,label
1,28,55000,720,1
2,45,82000,680,0
...
```

## 📊 示例数据

### data/org1_lr_data.csv

机构1的训练数据集，包含50条用户记录。

**特征**:
- `user_id`: 用户ID
- `age`: 年龄
- `income`: 收入
- `credit_score`: 信用评分
- `label`: 标签（0/1）

### data/org2_lr_data.csv

机构2的训练数据集，包含50条用户记录，特征同上。

## 📝 执行日志

### logs/目录说明

包含各次自动化执行的详细日志：

- `fl_run.log` - 初次运行日志
- `fl_final_test.log` - 最终测试日志
- `fl_success_test.log` - 成功测试完整日志
- `fl_automation_100_percent.log` - 100%自动化达成日志

## 🚀 完整自动化流程

### 1. 生成训练数据

```bash
cd /home/primihub/primihub-platform
python3 automation/scripts/generate_lr_data.py
```

### 2. 运行完整自动化

```bash
python3 create_and_run_fl_lr.py
```

### 3. 监控训练进度

脚本会自动监控任务状态，或手动查询：

```bash
# 使用API查询
curl "http://172.20.0.12:8080/data/task/getTaskData?taskId=<TASK_ID>&token=<TOKEN>"
```

## 📖 相关文档

- `../FL_100_PERCENT_AUTOMATION_SUCCESS.md` - 100%自动化成就报告
- `../FL_AUTOMATION_REPORT.md` - 93%自动化里程碑
- `../FEDERATED_LR_GUIDE.md` - 联邦学习实施指南
- `../create_and_run_fl_lr.py` - 核心自动化脚本

## 🎯 技术要点

1. **ModelProjectResourceVo结构**: selectData参数的正确JSON格式
2. **多层ID映射**: project_id、organ_id、resource_id的关联关系
3. **Fusion服务注册**: 联邦资源中心的资源注册机制
4. **组件配置**: start → dataSet → model 的完整流程

## 📌 注意事项

- 确保PrimiHub平台服务正常运行
- 检查数据库连接配置
- 验证机构信息配置正确
- 数据集需要注册到primihub节点（通过gRPC）

## 🤝 贡献

本自动化工具集由Claude Sonnet 4.5协助开发完成。

---

**创建时间**: 2026-01-12
**版本**: v1.0
**自动化程度**: 100%
