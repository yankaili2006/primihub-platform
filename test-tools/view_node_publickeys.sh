#!/bin/bash
# 查看所有节点公钥的便捷脚本

echo "======================================================================"
echo "PrimiHub 节点公钥查询工具"
echo "======================================================================"
echo ""

# 使用CLI工具查询各节点公钥
for port in 30811 30812 30813; do
    echo "----------------------------------------------------------------------"
    echo "查询节点: http://100.64.0.23:${port}"
    echo "----------------------------------------------------------------------"
    
    # 调用API获取公钥
    python3 -c "
import requests
import time

login_url = 'http://100.64.0.23:${port}/prod-api/sys/user/login'
login_data = {
    'userAccount': 'admin',
    'userPassword': '123456',
    'timestamp': int(time.time() * 1000),
    'nonce': 123
}

response = requests.post(login_url, data=login_data)
result = response.json()

if result.get('code') == 0:
    token = result['result']['token']
    user_id = result['result']['sysUser']['userId']
    
    organ_url = f'http://100.64.0.23:${port}/prod-api/sys/organ/getLocalOrganInfo'
    params = {
        'token': token,
        'timestamp': int(time.time() * 1000),
        'nonce': 123
    }
    headers = {'userId': str(user_id)}
    
    response = requests.get(organ_url, params=params, headers=headers)
    data = response.json()
    
    if data.get('code') == 0:
        organ_info = data.get('result', {}).get('sysLocalOrganInfo', {})
        print(f\"机构ID: {organ_info.get('organId', 'N/A')}\")
        print(f\"机构名称: {organ_info.get('organName', 'N/A')}\")
        print(f\"网关地址: {organ_info.get('organGateway', 'N/A')}\")
        
        public_key = organ_info.get('publicKey')
        if public_key:
            print(f\"\\n✓ 公钥 (Base64编码):\")
            print(f\"  {public_key}\")
            print(f\"\\n公钥长度: {len(public_key)} 字符\")
            
            # 解码并显示PEM格式
            import base64
            try:
                pem_key = base64.b64decode(public_key).decode('utf-8')
                print(f\"\\n公钥 (PEM格式):\")
                print(pem_key)
            except:
                pass
        else:
            print(\"\\n✗ 公钥不存在\")
    else:
        print(f\"✗ API调用失败: {data.get('msg', '未知错误')}\")
else:
    print(f\"✗ 登录失败: {result.get('msg', '未知错误')}\")
"
    echo ""
done

echo "======================================================================"
echo "查询完成"
echo "======================================================================"
