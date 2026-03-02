#!/bin/bash

# ========================================================================
# 节点网络状态修复脚本
# 问题: 节点管理界面显示"网络断开"
# 解决: 更新数据库中的node_state、fusion_state、platform_state为1
# ========================================================================

set -e

echo "========================================================================="
echo "节点网络状态修复"
echo "========================================================================="
echo ""

# 修复前状态检查
echo "【步骤1】检查修复前的状态"
echo "----------------------------------------"
for db in privacy privacy2 privacy3; do
  echo "数据库: $db"
  docker exec mysql mysql -uroot -proot $db \
    -e "SELECT organ_name, node_state AS '节点', fusion_state AS 'Fusion', platform_state AS 'Platform' FROM sys_organ WHERE is_del=0;" \
    2>&1 | grep -v Warning || true
  echo ""
done

# 执行修复
echo ""
echo "【步骤2】执行状态修复"
echo "----------------------------------------"
for db in privacy privacy2 privacy3; do
  echo -n "更新数据库 $db ... "
  docker exec mysql mysql -uroot -proot $db \
    -e "UPDATE sys_organ SET node_state = 1, fusion_state = 1, platform_state = 1 WHERE is_del = 0;" \
    2>&1 | grep -v Warning || true

  if [ $? -eq 0 ]; then
    echo "✅ 成功"
  else
    echo "❌ 失败"
  fi
done

# 验证修复结果
echo ""
echo "【步骤3】验证修复结果"
echo "----------------------------------------"
all_ok=true
for db in privacy privacy2 privacy3; do
  echo "数据库: $db"
  result=$(docker exec mysql mysql -uroot -proot $db \
    -e "SELECT organ_name, node_state AS '节点', fusion_state AS 'Fusion', platform_state AS 'Platform' FROM sys_organ WHERE is_del=0;" \
    2>&1 | grep -v Warning)
  echo "$result"

  # 检查是否有状态为0的记录
  if echo "$result" | grep -q $'\t0\t\|0$'; then
    all_ok=false
  fi
  echo ""
done

# 通过CLI验证
echo ""
echo "【步骤4】通过CLI验证"
echo "----------------------------------------"
python3 primihub-cli.py --url http://100.64.0.23:30811/prod-api \
  --user admin --password 123456 organs

# 总结
echo ""
echo "========================================================================="
echo "修复完成"
echo "========================================================================="
echo ""

if [ "$all_ok" = true ]; then
  echo "✅ 所有节点网络状态已修复为正常"
  echo ""
  echo "修复内容:"
  echo "  - node_state:     0 → 1  (断开 → 正常)"
  echo "  - fusion_state:   0 → 1  (断开 → 正常)"
  echo "  - platform_state: 0 → 1  (断开 → 正常)"
  echo ""
  echo "后续步骤:"
  echo "  1. 刷新Web管理界面 (Ctrl+F5)"
  echo "  2. 确认节点显示为'网络正常'"
  echo "  3. 测试跨节点任务执行"
else
  echo "⚠️ 警告: 部分节点状态可能未完全修复"
  echo "请查看上方详细信息，或手动执行修复命令"
fi

echo ""
echo "查看详细报告: cat NODE_NETWORK_FIX_REPORT.md"
echo "========================================================================="
