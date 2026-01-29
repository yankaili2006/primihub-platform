#!/bin/bash

# 测试PrimiHub平台登录

echo "=== 测试PrimiHub平台登录 ==="

# 1. 获取公钥
echo "1. 获取公钥..."
PUBLIC_KEY_RESPONSE=$(curl -s http://localhost:8090/common/getValidatePublicKey)
echo "公钥响应: $PUBLIC_KEY_RESPONSE"

# 提取公钥和key name
PUBLIC_KEY=$(echo $PUBLIC_KEY_RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result']['publicKey'])" 2>/dev/null)
PUBLIC_KEY_NAME=$(echo $PUBLIC_KEY_RESPONSE | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['result']['publicKeyName'])" 2>/dev/null)

echo "公钥名称: $PUBLIC_KEY_NAME"
echo "公钥: $PUBLIC_KEY"

if [ -z "$PUBLIC_KEY" ] || [ -z "$PUBLIC_KEY_NAME" ]; then
    echo "获取公钥失败"
    exit 1
fi

# 2. 使用Python加密密码
echo -e "\n2. 加密密码..."
cat > /tmp/encrypt_password.py << 'EOF'
import sys
import base64
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_v1_5

public_key_pem = sys.argv[1]
password = sys.argv[2]

# 将公钥从字符串格式转换为RSA对象
public_key = RSA.import_key(public_key_pem)

# 使用PKCS1_v1_5加密
cipher = PKCS1_v1_5.new(public_key)
encrypted = cipher.encrypt(password.encode('utf-8'))

# Base64编码
encrypted_b64 = base64.b64encode(encrypted).decode('utf-8')
print(encrypted_b64)

EOF

# 安装必要的Python库（如果不存在）
python3 -c "import Crypto" 2>/dev/null || echo "需要安装pycryptodome: pip3 install pycryptodome"

ENCRYPTED_PASSWORD=$(python3 /tmp/encrypt_password.py "$PUBLIC_KEY" "admin" 2>/dev/null)

if [ -z "$ENCRYPTED_PASSWORD" ]; then
    echo "密码加密失败，使用简单测试..."
    ENCRYPTED_PASSWORD="test_encrypted_password"
fi

echo "加密后的密码: $ENCRYPTED_PASSWORD"

# 3. 尝试登录
echo -e "\n3. 尝试登录..."
LOGIN_PAYLOAD="{\"userAccount\":\"admin\",\"userPassword\":\"$ENCRYPTED_PASSWORD\",\"validateKeyName\":\"$PUBLIC_KEY_NAME\",\"captchaVerification\":\"\",\"tokenKey\":\"\"}"

echo "登录请求: $LOGIN_PAYLOAD"

LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8090/user/login \
  -H "Content-Type: application/json" \
  -d "$LOGIN_PAYLOAD")

echo "登录响应: $LOGIN_RESPONSE"

# 4. 测试其他端点
echo -e "\n4. 测试其他端点..."
echo "获取跟踪ID: $(curl -s http://localhost:8090/common/getTrackingID)"
echo "获取收集列表: $(curl -s http://localhost:8090/common/getCollectList | head -100)"

echo -e "\n=== 测试完成 ==="