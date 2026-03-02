#!/bin/bash
# 节点互联演示脚本

echo "======================================================================"
echo "PrimiHub 节点互联演示"
echo "======================================================================"
echo ""

# 节点配置
NODE0_URL="http://100.64.0.23:30811/prod-api"
NODE1_URL="http://100.64.0.23:30812/prod-api"
NODE2_URL="http://100.64.0.23:30813/prod-api"

NODE0_GATEWAY="http://100.64.0.23:30811"
NODE1_GATEWAY="http://100.64.0.23:30812"
NODE2_GATEWAY="http://100.64.0.23:30813"

echo "步骤1: 查看当前节点0的机构列表"
echo "----------------------------------------------------------------------"
python3 primihub-cli.py --url $NODE0_URL --user admin --password 123456 organs
echo ""

echo "步骤2: 节点0向节点1发起认证请求"
echo "----------------------------------------------------------------------"
echo "命令: python3 primihub-cli.py --url $NODE0_URL auth-request $NODE1_GATEWAY"
python3 primihub-cli.py --url $NODE0_URL --user admin --password 123456 \
  auth-request $NODE1_GATEWAY
echo ""

echo "步骤3: 节点0向节点2发起认证请求"
echo "----------------------------------------------------------------------"
echo "命令: python3 primihub-cli.py --url $NODE0_URL auth-request $NODE2_GATEWAY"
python3 primihub-cli.py --url $NODE0_URL --user admin --password 123456 \
  auth-request $NODE2_GATEWAY
echo ""

echo "步骤4: 在节点1上查看认证请求"
echo "----------------------------------------------------------------------"
python3 primihub-cli.py --url $NODE1_URL --user admin --password 123456 auth-list
echo ""

echo "步骤5: 在节点2上查看认证请求"
echo "----------------------------------------------------------------------"
python3 primihub-cli.py --url $NODE2_URL --user admin --password 123456 auth-list
echo ""

echo "======================================================================"
echo "演示完成"
echo "======================================================================"
echo ""
echo "说明："
echo "1. 如果看到待审核的请求，可以使用以下命令批准："
echo "   python3 primihub-cli.py --url <节点URL> auth-approve <请求ID>"
echo ""
echo "2. 查看所有机构状态："
echo "   python3 primihub-cli.py --url <节点URL> organs"
echo ""
echo "3. 启用/禁用机构："
echo "   python3 primihub-cli.py --url <节点URL> auth-enable <机构ID>"
echo "   python3 primihub-cli.py --url <节点URL> auth-disable <机构ID>"
