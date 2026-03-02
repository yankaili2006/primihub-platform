#!/bin/bash
################################################################################
# PSI任务触发脚本 - 使用rabbitmqadmin触发待执行的PSI任务
#
# 功能: 查询所有待执行的PSI任务，并通过RabbitMQ消息队列触发执行
# 使用方法: ./trigger_psi_tasks_final.sh
################################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================================================"
echo "PSI任务触发脚本 - 通过RabbitMQ触发待执行任务"
echo "================================================================================"
echo ""

# 1. 查询待执行的PSI任务
echo -e "${BLUE}[1/5] 查询待执行的PSI任务...${NC}"
QUERY="SELECT dt.task_id_name, dpt.psi_id, dp.own_organ_id, dp.other_organ_id, dp.result_name
       FROM data_task dt
       JOIN data_psi_task dpt ON dt.task_id_name = dpt.task_id
       JOIN data_psi dp ON dpt.psi_id = dp.id
       WHERE dt.task_state = 0 AND dt.task_type = 2
       ORDER BY dpt.psi_id"

TASKS=$(docker exec mysql mysql -uprimihub -p'primihub@123' privacy -N -e "$QUERY" 2>/dev/null)

if [ -z "$TASKS" ]; then
    echo -e "${GREEN}✓ 没有待执行的PSI任务${NC}"
    exit 0
fi

TASK_COUNT=$(echo "$TASKS" | wc -l)
echo -e "${GREEN}✓ 发现 $TASK_COUNT 个待执行的PSI任务${NC}"
echo ""
printf "%-10s %-25s %-40s\n" "PSI ID" "Task ID" "Own Organ ID"
echo "--------------------------------------------------------------------------------"
echo "$TASKS" | awk '{printf "%-10s %-25s %-40s\n", $2, $1, $3}'
echo ""

# 2. 确认是否继续
read -p "是否触发这 $TASK_COUNT 个任务的执行? (yes/no): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy][Ee][Ss]$|^[Yy]$ ]]; then
    echo "操作已取消"
    exit 0
fi

# 3. 测试RabbitMQ连接
echo ""
echo -e "${BLUE}[2/5] 测试RabbitMQ连接...${NC}"
QUEUE_CHECK=$(docker exec rabbitmq0 rabbitmqctl list_queues name 2>/dev/null | grep singlTaskChannel.single || echo "")
if [ -z "$QUEUE_CHECK" ]; then
    echo -e "${RED}✗ RabbitMQ队列不存在${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RabbitMQ连接成功，队列存在${NC}"

# 4. 发送任务消息
echo ""
echo -e "${BLUE}[3/5] 发送任务消息到RabbitMQ...${NC}"
SUCCESS_COUNT=0
FAILED_COUNT=0

echo "$TASKS" | while IFS=$'\t' read -r TASK_ID PSI_ID OWN_ORGAN OTHER_ORGAN RESULT_NAME; do
    # 构建消息 (JSON格式)
    MESSAGE="{\"taskId\":\"$TASK_ID\",\"taskType\":2,\"psiId\":$PSI_ID,\"ownOrganId\":\"$OWN_ORGAN\",\"otherOrganId\":\"$OTHER_ORGAN\",\"resultName\":\"$RESULT_NAME\"}"

    # 使用rabbitmqadmin发送消息
    RESULT=$(docker exec rabbitmq0 rabbitmqadmin publish \
        exchange=singlTaskChannel \
        routing_key="" \
        payload="$MESSAGE" \
        properties='{"content_type":"application/json","delivery_mode":2}' 2>&1 || echo "FAILED")

    if [[ "$RESULT" == *"Message published"* ]]; then
        echo -e "${GREEN}✓${NC} PSI任务 $PSI_ID (task_id: $TASK_ID) - 消息已发送"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗${NC} PSI任务 $PSI_ID (task_id: $TASK_ID) - 发送失败: $RESULT"
        ((FAILED_COUNT++))
    fi
done

echo ""
echo "成功: $SUCCESS_COUNT/$TASK_COUNT"
if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "${RED}失败: $FAILED_COUNT/$TASK_COUNT${NC}"
fi

# 5. 验证队列状态
echo ""
echo -e "${BLUE}[4/5] 验证RabbitMQ队列状态...${NC}"
echo "当前队列状态:"
docker exec rabbitmq0 rabbitmqctl list_queues name messages consumers 2>/dev/null | grep -E "singlTaskChannel|seatunnel"

# 6. 后续步骤
echo ""
echo -e "${BLUE}[5/5] 后续步骤${NC}"
echo "--------------------------------------------------------------------------------"
echo "消息已发送到RabbitMQ队列，节点应该会自动消费并执行任务。"
echo ""
echo -e "${YELLOW}监控任务执行:${NC}"
echo "  1. 实时查看节点日志 (查找PSI执行记录):"
echo "     docker logs -f node0 2>&1 | grep -i psi"
echo ""
echo "  2. 查看任务状态变化:"
echo "     watch -n 2 'docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e \"SELECT psi_id, task_state, update_date FROM data_psi_task ORDER BY psi_id DESC LIMIT 10;\" 2>/dev/null'"
echo ""
echo "  3. 查看队列消息消费情况:"
echo "     watch -n 2 'docker exec rabbitmq0 rabbitmqctl list_queues name messages consumers 2>/dev/null'"
echo ""
echo -e "${YELLOW}如果任务仍未执行，可能的原因:${NC}"
echo "  - 消息格式与系统期望不匹配（需要查看application源码）"
echo "  - 节点服务未正常运行或无法连接到application"
echo "  - RabbitMQ消费者配置有问题"
echo "  - 需要重启application服务以重新建立消息监听"
echo ""
echo -e "${YELLOW}建议尝试:${NC}"
echo "  docker restart application0 application1 application2"
echo ""

exit 0
