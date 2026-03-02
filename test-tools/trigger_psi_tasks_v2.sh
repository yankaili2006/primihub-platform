#!/bin/bash
################################################################################
# PSI任务触发脚本 - 使用rabbitmqadmin触发待执行的PSI任务
################################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================================================"
echo "PSI任务触发脚本 - 通过RabbitMQ触发待执行任务"
echo "================================================================================"
echo ""

# 1. 查询待执行的PSI任务
echo "[1/5] 查询待执行的PSI任务..."
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
echo "[2/5] 测试RabbitMQ连接..."
QUEUE_CHECK=$(docker exec rabbitmq0 rabbitmqctl list_queues name 2>/dev/null | grep singlTaskChannel.single || echo "")
if [ -z "$QUEUE_CHECK" ]; then
    echo -e "${RED}✗ RabbitMQ队列不存在${NC}"
    exit 1
fi
echo -e "${GREEN}✓ RabbitMQ连接成功${NC}"

# 4. 发送任务消息
echo ""
echo "[3/5] 发送任务消息到RabbitMQ..."
SUCCESS_COUNT=0
FAILED_COUNT=0

# 创建临时Python脚本在application容器中执行
PYTHON_SCRIPT=$(cat <<'EOFPYTHON'
import sys
import json

# 从stdin读取任务数据
tasks = []
for line in sys.stdin:
    parts = line.strip().split('\t')
    if len(parts) >= 5:
        tasks.append({
            'task_id': parts[0],
            'psi_id': int(parts[1]),
            'own_organ': parts[2],
            'other_organ': parts[3],
            'result_name': parts[4]
        })

# 输出为JSON
print(json.dumps(tasks))
EOFPYTHON
)

# 将任务数据转换为JSON
TASKS_JSON=$(echo "$TASKS" | python3 -c "$PYTHON_SCRIPT")

# 为每个任务发送消息
echo "$TASKS" | while IFS=$'\t' read -r TASK_ID PSI_ID OWN_ORGAN OTHER_ORGAN RESULT_NAME; do
    # 构建消息
    MESSAGE="{\"taskId\":\"$TASK_ID\",\"taskType\":2,\"psiId\":$PSI_ID,\"ownOrganId\":\"$OWN_ORGAN\",\"otherOrganId\":\"$OTHER_ORGAN\",\"resultName\":\"$RESULT_NAME\"}"

    # 使用rabbitmqadmin发送消息（如果可用）
    RESULT=$(docker exec rabbitmq0 sh -c "
        rabbitmqadmin publish exchange=singlTaskChannel \
            routing_key='' \
            payload='$MESSAGE' \
            properties='{\"content_type\":\"application/json\",\"delivery_mode\":2}' 2>&1
    " || echo "FAILED")

    if [[ "$RESULT" == *"Message published"* ]] || [[ "$RESULT" != *"FAILED"* ]]; then
        echo -e "${GREEN}✓${NC} PSI任务 $PSI_ID (task_id: $TASK_ID) - 消息已发送"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗${NC} PSI任务 $PSI_ID (task_id: $TASK_ID) - 发送失败"
        ((FAILED_COUNT++))
    fi
done

echo ""
echo "成功: $SUCCESS_COUNT/$TASK_COUNT"
if [ $FAILED_COUNT -gt 0 ]; then
    echo "失败: $FAILED_COUNT/$TASK_COUNT"
fi

# 5. 验证队列状态
echo ""
echo "[4/5] 验证RabbitMQ队列状态..."
docker exec rabbitmq0 rabbitmqctl list_queues name messages consumers 2>/dev/null | grep singlTaskChannel

# 6. 后续步骤
echo ""
echo "[5/5] 后续步骤"
echo "--------------------------------------------------------------------------------"
echo "消息已发送到RabbitMQ队列，节点应该会自动消费并执行任务。"
echo ""
echo "监控任务执行:"
echo "  1. 查看节点日志:"
echo "     docker logs -f node0 2>&1 | grep -i psi"
echo ""
echo "  2. 查看任务状态:"
echo "     docker exec mysql mysql -uprimihub -p'primihub@123' privacy \\"
echo "       -e \"SELECT psi_id, task_id, task_state FROM data_psi_task ORDER BY psi_id DESC LIMIT 10;\""
echo ""
echo "  3. 查看队列消息消费情况:"
echo "     docker exec rabbitmq0 rabbitmqctl list_queues name messages consumers"
echo ""
echo "  4. 如果任务仍未执行，可能的原因:"
echo "     - 消息格式不正确（需要查看application源码确认格式）"
echo "     - 节点服务未正常运行"
echo "     - RabbitMQ消费者未正确配置"
echo ""

exit 0
