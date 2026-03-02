#!/bin/bash

# 为三个节点生成并配置公钥

echo "======================================================================"
echo "为各节点生成RSA密钥对并更新Nacos配置"
echo "======================================================================"

# 节点配置
declare -A nodes
nodes[demo0]="550e8400-e29b-41d4-a716-446655440000|API测试机构|http://100.64.0.23:30811|30811"
nodes[demo1]="550e8400-e29b-41d4-a716-446655440001|API测试机构|http://100.64.0.23:30812|30812"
nodes[demo2]="550e8400-e29b-41d4-a716-446655440002|API测试机构|http://100.64.0.23:30813|30813"

for tenant in demo0 demo1 demo2; do
    IFS='|' read -r organ_id organ_name gateway port <<< "${nodes[$tenant]}"
    
    echo ""
    echo "----------------------------------------------------------------------"
    echo "节点: $tenant (端口 $port)"
    echo "----------------------------------------------------------------------"
    
    # 生成RSA密钥对
    openssl genrsa -out /tmp/${tenant}_private.pem 1024 2>/dev/null
    openssl rsa -in /tmp/${tenant}_private.pem -pubout -out /tmp/${tenant}_public.pem 2>/dev/null
    
    # Base64编码
    private_key=$(cat /tmp/${tenant}_private.pem | base64 -w 0)
    public_key=$(cat /tmp/${tenant}_public.pem | base64 -w 0)
    
    echo "机构ID: $organ_id"
    echo "公钥 (前80字符): ${public_key:0:80}..."
    echo "公钥长度: ${#public_key} 字符"
    
    # 构建JSON配置
    config=$(cat <<JSON
{
  "organId": "$organ_id",
  "organName": "$organ_name",
  "organGateway": "$gateway",
  "gatewayAddress": "$gateway",
  "publicKey": "$public_key",
  "privateKey": "$private_key"
}
JSON
)
    
    # 更新Nacos配置
    result=$(docker exec nacos-server curl -s -X POST \
        "http://localhost:8848/nacos/v1/cs/configs" \
        -d "dataId=organ_info.json" \
        -d "group=DEFAULT_GROUP" \
        -d "tenant=$tenant" \
        -d "type=json" \
        --data-urlencode "content=$config")
    
    if [ "$result" = "true" ]; then
        echo "✓ Nacos配置更新成功"
    else
        echo "✗ Nacos配置更新失败: $result"
    fi
    
    # 清理临时文件
    rm -f /tmp/${tenant}_private.pem /tmp/${tenant}_public.pem
done

echo ""
echo "======================================================================"
echo "密钥生成和配置完成"
echo "======================================================================"
