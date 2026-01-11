#!/usr/bin/env python3
"""
生成联邦学习LR训练数据
两个机构各有一部分用户数据，包含特征和标签
"""
import csv
import random

# 设置随机种子
random.seed(42)

# 机构1的数据（用户1-50）
org1_data = []
for i in range(1, 51):
    age = random.randint(18, 65)
    income = random.randint(30000, 150000)
    credit_score = random.randint(300, 850)

    # 简单的逻辑：年龄>30, 收入>60000, 信用分>600 则更可能为1
    prob = 0.1
    if age > 30:
        prob += 0.2
    if income > 60000:
        prob += 0.3
    if credit_score > 600:
        prob += 0.3

    label = 1 if random.random() < prob else 0

    org1_data.append({
        'user_id': f'U{i:03d}',
        'age': age,
        'income': income,
        'credit_score': credit_score,
        'label': label
    })

# 机构2的数据（用户51-100）
org2_data = []
for i in range(51, 101):
    age = random.randint(18, 65)
    income = random.randint(30000, 150000)
    credit_score = random.randint(300, 850)

    prob = 0.1
    if age > 30:
        prob += 0.2
    if income > 60000:
        prob += 0.3
    if credit_score > 600:
        prob += 0.3

    label = 1 if random.random() < prob else 0

    org2_data.append({
        'user_id': f'U{i:03d}',
        'age': age,
        'income': income,
        'credit_score': credit_score,
        'label': label
    })

# 保存机构1的数据
with open('/tmp/org1_lr_data.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['user_id', 'age', 'income', 'credit_score', 'label'])
    writer.writeheader()
    writer.writerows(org1_data)

# 保存机构2的数据
with open('/tmp/org2_lr_data.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['user_id', 'age', 'income', 'credit_score', 'label'])
    writer.writeheader()
    writer.writerows(org2_data)

print("✅ 数据生成成功！")
print(f"机构1数据: /tmp/org1_lr_data.csv ({len(org1_data)} 条记录)")
print(f"机构2数据: /tmp/org2_lr_data.csv ({len(org2_data)} 条记录)")
print(f"\n数据集概览:")
print(f"  机构1 - 标签1: {sum(1 for d in org1_data if d['label']==1)}, 标签0: {sum(1 for d in org1_data if d['label']==0)}")
print(f"  机构2 - 标签1: {sum(1 for d in org2_data if d['label']==1)}, 标签0: {sum(1 for d in org2_data if d['label']==0)}")
