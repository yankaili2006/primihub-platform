# PIR功能启用指南

## 快速诊断

PIR（隐私信息检索）功能无法使用的原因：**Fusion服务中没有注册资源**

## 验证问题

运行以下脚本确认问题：

```python
python3 << 'EOF'
import requests
import time

BASE_URL = "http://172.20.0.5:8080"  # Fusion服务地址

response = requests.post(
    f"{BASE_URL}/fusionResource/getResourceList",
    json={"globalId": "000000000000000000000000demo0org0001", "pageNo": 1, "pageSize": 10}
)

result = response.json()
count = result.get('result', {}).get('total', 0)
print(f"Fusion服务中的资源数量: {count}")

if count == 0:
    print("❌ 问题确认：Fusion服务中没有资源")
    print("✅ 解决方法：需要创建并注册资源到Fusion服务")
else:
    print(f"✅ Fusion服务中有 {count} 个资源")
EOF
```

## 解决方案

### 方法1: Web控制台创建资源（推荐）

1. **访问Web控制台**
   ```bash
   # 查找Web服务端口
   docker ps | grep manage-web

   # 通常是 http://IP:30811 或 http://IP:30812
   ```

2. **登录系统**
   - 用户名: `admin`
   - 密码: `123456`

3. **创建资源**
   - 进入"资源管理"菜单
   - 点击"创建资源"/"新建资源"
   - 选择上传CSV文件或配置数据库连接
   - 填写资源信息并保存

4. **系统自动同步**
   资源创建后自动注册到Fusion服务

### 方法2: 准备测试数据

如果需要测试数据，创建以下CSV文件：

```bash
cat > /tmp/pir_test_data.csv << 'EOF'
user_id,name,age,city
U001,张三,25,北京
U002,李四,30,上海
U003,王五,28,广州
U004,赵六,35,深圳
U005,钱七,27,杭州
EOF
```

通过Web控制台上传此文件。

### 方法3: 手动API调用（高级）

如果无法访问Web控制台，可以直接调用API：

```bash
cd /home/primihub/github/primihub-deploy/docker-all-in-one
python3 register_fusion_resource.py
```

`register_fusion_resource.py` 内容：

```python
#!/usr/bin/env python3
"""
手动注册资源到Fusion服务
"""
import requests
import time
import json

GATEWAY_URL = "http://172.20.0.6:8080"

# 登录
response = requests.post(f"{GATEWAY_URL}/sys/user/login", data={
    "userAccount": "admin",
    "userPassword": "123456",
    "timestamp": int(time.time() * 1000),
    "nonce": 123
})

result = response.json()
token = result['result']['token']
user_id = result['result']['sysUser']['userId']

print(f"✅ 登录成功 - 用户ID: {user_id}")

# TODO: 需要通过Web控制台或完整的资源注册流程创建资源
# 直接调用Fusion API需要完整的资源数据结构

print("\n推荐使用Web控制台创建资源，系统会自动同步到Fusion服务")
```

## 验证PIR功能

资源创建后，验证PIR功能：

```bash
cd /home/primihub/github/primihub-deploy/docker-all-in-one

# 1. 检查Fusion资源（应该不为空）
python3 << 'EOF'
import requests
response = requests.post(
    "http://172.20.0.5:8080/fusionResource/getResourceList",
    json={"globalId": "000000000000000000000000demo0org0001", "pageNo": 1, "pageSize": 10}
)
result = response.json()
resources = result.get('result', {}).get('data', [])
print(f"找到 {len(resources)} 个资源")
for r in resources:
    print(f"  - {r.get('resourceId')}: {r.get('resourceName')}")
EOF

# 2. 创建PIR任务（使用新资源ID）
# 修改 create_pir_dh.py 中的 resource_id 为实际资源ID
python3 create_pir_dh.py
```

## 常见问题

### Q1: 找不到Web控制台地址？
```bash
# 查看所有Web服务
docker ps | grep -E "manage-web|30811|30812|30813"

# 输出示例：
# manage-web0 -> 0.0.0.0:30811->80/tcp
# manage-web1 -> 0.0.0.0:30812->80/tcp
```

访问 `http://YOUR_IP:30811`

### Q2: 登录后找不到"资源管理"菜单？
- 检查用户权限
- 尝试使用admin账户
- 查看左侧导航栏或顶部菜单

### Q3: 创建资源后PIR仍然报错？
```bash
# 检查资源是否同步到Fusion
python3 << 'EOF'
import requests
response = requests.post(
    "http://172.20.0.5:8080/fusionResource/getResourceList",
    json={"globalId": "000000000000000000000000demo0org0001", "pageNo": 1, "pageSize": 10}
)
print(response.json())
EOF

# 如果仍为空，可能需要重启application服务
docker restart application0 application1 application2
```

### Q4: 为什么PSI可以用但PIR不行？
PSI和PIR使用不同的资源管理方式：
- **PSI**: 直接使用本地数据库（privacy1.data_resource）
- **PIR**: 必须使用Fusion服务（fusion1.fusion_resource）

这是系统设计差异，PIR需要更严格的资源验证机制。

## 技术支持

如果按照以上步骤仍无法解决问题，请查看详细调查报告：
- `PIR_CONFIGURATION_INVESTIGATION_REPORT.md`

或联系技术支持。

---

**文档版本**: 1.0
**更新日期**: 2026-01-14
**适用版本**: PrimiHub Platform 1.8.0
