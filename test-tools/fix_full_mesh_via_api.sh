#!/bin/bash
# 通过API完成三节点完全互联

echo "======================================================================"
echo "通过API修复三节点完全互联"
echo "======================================================================"
echo ""

echo "问题分析:"
echo "  - ID=3的记录存储了错误的公钥（CLI工具bug导致）"
echo "  - 启用时验证失败：合作方建立通信失败"
echo ""
echo "解决方案:"
echo "  1. 通过API标记删除错误的记录"
echo "  2. 使用修复后的CLI重新建立连接"
echo ""

echo "======================================================================"
echo "步骤1: 检查当前连接状态"
echo "======================================================================"
python3 -c "
import requests

nodes = ['30811', '30812', '30813']
problem_records = []

for port in nodes:
    url = f'http://100.64.0.23:{port}/prod-api/sys/organ/getOrganList'
    response = requests.get(url, params={'token': 'test', 'pageNo': 1, 'pageSize': 100}, timeout=5)
    result = response.json()

    if result.get('code') == 0:
        organs = result.get('result', {}).get('data', [])
        for organ in organs:
            if organ.get('enable') == 0 and organ.get('examineState') == 1:
                problem_records.append({
                    'node': port,
                    'id': organ.get('id'),
                    'name': organ.get('organName'),
                    'gateway': organ.get('organGateway')
                })

if problem_records:
    print(f'找到 {len(problem_records)} 个需要处理的记录:')
    for rec in problem_records:
        print(f\"  节点{rec['node']}: ID={rec['id']}, {rec['name']} ({rec['gateway']})\")
else:
    print('没有需要处理的记录')
"
echo ""

echo "======================================================================"
echo "步骤2: 标记删除有问题的记录（通过API）"
echo "======================================================================"
echo "注意: 由于这些记录的公钥不匹配，删除API可能也会失败"
echo "      如果删除失败，我们将直接重新创建正确的连接"
echo ""

# 尝试删除节点30812上的ID=3
echo "[1/2] 尝试删除节点30812上的ID=3..."
python3 -c "
import requests
url = 'http://100.64.0.23:30812/prod-api/sys/organ/deleteOrgan'
response = requests.get(url, params={'id': 3}, timeout=10)
try:
    result = response.json()
    if result and result.get('code') == 0:
        print('  ✓ 删除成功')
    else:
        print(f\"  ✗ 删除失败: {result.get('msg') if result else '无响应'}\")
        print('  → 将通过重新创建连接来覆盖')
except:
    print('  ✗ API响应异常')
    print('  → 将通过重新创建连接来覆盖')
"
echo ""

# 尝试删除节点30813上的ID=3
echo "[2/2] 尝试删除节点30813上的ID=3..."
python3 -c "
import requests
url = 'http://100.64.0.23:30813/prod-api/sys/organ/deleteOrgan'
response = requests.get(url, params={'id': 3}, timeout=10)
try:
    result = response.json()
    if result and result.get('code') == 0:
        print('  ✓ 删除成功')
    else:
        print(f\"  ✗ 删除失败: {result.get('msg') if result else '无响应'}\")
        print('  → 将通过重新创建连接来覆盖')
except:
    print('  ✗ API响应异常')
    print('  → 将通过重新创建连接来覆盖')
"
echo ""

echo "======================================================================"
echo "步骤3: 使用修复后的CLI重新建立连接"
echo "======================================================================"
echo "说明: 修复后的CLI会自动获取远程节点的正确公钥"
echo ""

echo "[1/2] 节点30812 → 节点30811..."
python3 primihub-cli.py --url http://100.64.0.23:30812/prod-api \
  --user admin --password 123456 \
  auth-request http://100.64.0.23:30811
echo ""

echo "[2/2] 节点30813 → 节点30811..."
python3 primihub-cli.py --url http://100.64.0.23:30813/prod-api \
  --user admin --password 123456 \
  auth-request http://100.64.0.23:30811
echo ""

echo "======================================================================"
echo "步骤4: 在节点30811上批准认证请求"
echo "======================================================================"
echo "查看待审核的请求..."
python3 primihub-cli.py --url http://100.64.0.23:30811/prod-api \
  --user admin --password 123456 auth-list
echo ""

echo "======================================================================"
echo "步骤5: 获取待审核请求的ID"
echo "======================================================================"
python3 -c "
import requests

url = 'http://100.64.0.23:30811/prod-api/sys/organ/getOrganList'
response = requests.get(url, params={'token': 'test', 'pageNo': 1, 'pageSize': 100}, timeout=5)
result = response.json()

if result.get('code') == 0:
    organs = result.get('result', {}).get('data', [])
    pending = [o for o in organs if o.get('examineState') == 0]

    if pending:
        print(f'找到 {len(pending)} 个待审核请求:')
        for organ in pending:
            print(f\"  ID={organ.get('id')}: {organ.get('organName')} ({organ.get('organGateway')})\")
            print(f\"    批准命令: python3 primihub-cli.py --url http://100.64.0.23:30811/prod-api --user admin --password 123456 auth-approve {organ.get('id')}\")
    else:
        print('没有待审核的请求')
        print('提示: 如果请求已经存在，它们可能已经被批准但未启用')

        # 检查已批准但未启用的
        disabled = [o for o in organs if o.get('examineState') == 1 and o.get('enable') == 0]
        if disabled:
            print(f'\\n找到 {len(disabled)} 个已批准但未启用的机构:')
            for organ in disabled:
                print(f\"  ID={organ.get('id')}: {organ.get('organName')} ({organ.get('organGateway')})\")
                print(f\"    启用命令: python3 primihub-cli.py --url http://100.64.0.23:30811/prod-api --user admin --password 123456 auth-enable {organ.get('id')}\")
"
echo ""

echo "======================================================================"
echo "步骤6: 验证最终连接状态"
echo "======================================================================"
bash cleanup_and_verify_connections.sh | tail -50

echo ""
echo "======================================================================"
echo "完成"
echo "======================================================================"
echo ""
echo "如果仍有未启用的连接，请手动执行上面显示的命令"
echo ""
