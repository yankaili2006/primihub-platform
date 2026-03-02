#!/bin/bash
# 完整建立三节点互联

echo "======================================================================"
echo "建立完整的三节点互联 (Full Mesh)"
echo "======================================================================"
echo ""

echo "目标: 每个节点都要与其他两个节点建立双向连接"
echo "  - 节点30811 ↔ 节点30812"
echo "  - 节点30811 ↔ 节点30813"
echo "  - 节点30812 ↔ 节点30813"
echo ""

# 节点配置
NODE0_URL="http://100.64.0.23:30811/prod-api"
NODE1_URL="http://100.64.0.23:30812/prod-api"
NODE2_URL="http://100.64.0.23:30813/prod-api"

NODE0_GATEWAY="http://100.64.0.23:30811"
NODE1_GATEWAY="http://100.64.0.23:30812"
NODE2_GATEWAY="http://100.64.0.23:30813"

echo "======================================================================"
echo "步骤1: 检查当前连接状态"
echo "======================================================================"
python3 -c "
import requests

nodes = ['30811', '30812', '30813']
for port in nodes:
    url = f'http://100.64.0.23:{port}/prod-api/sys/organ/getOrganList'
    response = requests.get(url, params={'token': 'test', 'pageNo': 1, 'pageSize': 100}, timeout=5)
    result = response.json()

    if result.get('code') == 0:
        organs = result.get('result', {}).get('data', [])
        enabled = [o for o in organs if o.get('enable') == 1]
        print(f'节点{port}: {len(enabled)}/{len(organs)} 个连接已启用')
"
echo ""

echo "======================================================================"
echo "步骤2: 节点30812向节点30811发起认证请求"
echo "======================================================================"
python3 primihub-cli.py --url $NODE1_URL --user admin --password 123456 \
  auth-request $NODE0_GATEWAY
echo ""

echo "======================================================================"
echo "步骤3: 节点30813向节点30811发起认证请求"
echo "======================================================================"
python3 primihub-cli.py --url $NODE2_URL --user admin --password 123456 \
  auth-request $NODE0_GATEWAY
echo ""

echo "======================================================================"
echo "步骤4: 在节点30811上查看待审核的请求"
echo "======================================================================"
python3 primihub-cli.py --url $NODE0_URL --user admin --password 123456 auth-list
echo ""

echo "======================================================================"
echo "步骤5: 获取待审核请求的ID并批准"
echo "======================================================================"
echo "正在获取待审核请求..."

# 获取待审核的请求ID
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
    else:
        print('没有待审核的请求')

    # 找到enable=0的已批准请求
    disabled = [o for o in organs if o.get('examineState') == 1 and o.get('enable') == 0]
    if disabled:
        print(f'找到 {len(disabled)} 个已批准但未启用的机构:')
        for organ in disabled:
            print(f\"  ID={organ.get('id')}: {organ.get('organName')} ({organ.get('organGateway')})\")
" > /tmp/pending_requests.txt

cat /tmp/pending_requests.txt
echo ""

echo "======================================================================"
echo "步骤6: 批准并启用所有待处理的请求"
echo "======================================================================"
echo "注意: 如果请求已经存在，可能会显示为已批准状态"
echo "      我们需要手动启用这些连接"
echo ""

echo "======================================================================"
echo "步骤7: 验证最终连接状态"
echo "======================================================================"
python3 -c "
import requests

nodes = {
    '30811': 'http://100.64.0.23:30811',
    '30812': 'http://100.64.0.23:30812',
    '30813': 'http://100.64.0.23:30813'
}

print('连接矩阵:')
print('-' * 80)

for port, gateway in nodes.items():
    url = f'{gateway}/prod-api/sys/organ/getOrganList'
    response = requests.get(url, params={'token': 'test', 'pageNo': 1, 'pageSize': 100}, timeout=5)
    result = response.json()

    if result.get('code') == 0:
        organs = result.get('result', {}).get('data', [])
        print(f'节点{port}:')

        for organ in organs:
            remote_gateway = organ.get('organGateway', '')
            if remote_gateway and remote_gateway != gateway:
                remote_port = remote_gateway.split(':')[-1].split('/')[0]
                enable = organ.get('enable')
                node_state = organ.get('nodeState')

                status = '✓' if (enable == 1 and node_state == 1) else '✗'
                print(f\"  {status} → 节点{remote_port}: enable={enable}, node_state={node_state}\")
        print()

print('=' * 80)
print('如果看到 ✗ 标记，说明连接未完全建立')
print('请使用以下命令手动启用:')
print('  python3 primihub-cli.py --url <节点URL> auth-enable <机构ID>')
"

echo ""
echo "======================================================================"
echo "完成"
echo "======================================================================"
