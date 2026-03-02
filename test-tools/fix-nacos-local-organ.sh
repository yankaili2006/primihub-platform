#!/bin/bash

echo "================================"
echo "修复Nacos本地机构配置"
echo "================================"
echo

# Update demo0 (node0)
echo "更新 demo0 配置..."
docker exec mysql mysql -uroot -proot nacos_config -e "UPDATE config_info SET content = '{\"organId\": \"550e8400-e29b-41d4-a716-446655440000\", \"organName\": \"API测试机构\", \"organGateway\": \"http://100.64.0.23:30811\", \"gatewayAddress\": \"http://100.64.0.23:30811\", \"publicKey\": \"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtest\"}' WHERE data_id = 'organ_info.json' AND tenant_id = 'demo0';" 2>&1 | grep -v Warning

# Update demo1 (node1)
echo "更新 demo1 配置..."
docker exec mysql mysql -uroot -proot nacos_config -e "UPDATE config_info SET content = '{\"organId\": \"550e8400-e29b-41d4-a716-446655440001\", \"organName\": \"API测试机构\", \"organGateway\": \"http://100.64.0.23:30812\", \"gatewayAddress\": \"http://100.64.0.23:30812\", \"publicKey\": \"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtest\"}' WHERE data_id = 'organ_info.json' AND tenant_id = 'demo1';" 2>&1 | grep -v Warning

# Update demo2 (node2)
echo "更新 demo2 配置..."
docker exec mysql mysql -uroot -proot nacos_config -e "UPDATE config_info SET content = '{\"organId\": \"550e8400-e29b-41d4-a716-446655440002\", \"organName\": \"API测试机构\", \"organGateway\": \"http://100.64.0.23:30813\", \"gatewayAddress\": \"http://100.64.0.23:30813\", \"publicKey\": \"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtest\"}' WHERE data_id = 'organ_info.json' AND tenant_id = 'demo2';" 2>&1 | grep -v Warning

echo
echo "验证配置更新..."
docker exec mysql mysql -uroot -proot nacos_config -e "SELECT tenant_id, SUBSTRING(content, 1, 100) as content_preview FROM config_info WHERE data_id='organ_info.json';" 2>&1 | grep -v Warning

echo
echo "✅ Nacos配置已更新"
echo
echo "注意: 需要重启application服务才能生效"
echo "运行: docker restart application0 application1 application2"
