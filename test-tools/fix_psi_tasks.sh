#!/bin/bash
# ============================================================================
# PSI任务修复脚本
# 功能: 为缺失data_task记录的PSI任务创建补偿记录并尝试触发执行
# ============================================================================

set -e

echo "============================================================================"
echo "PSI任务修复脚本"
echo "============================================================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查缺失的任务
echo "[1/5] 检查缺失data_task记录的PSI任务..."
MISSING_COUNT=$(docker exec mysql mysql -uprimihub -p'primihub@123' privacy -sN -e "
SELECT COUNT(*)
FROM data_psi_task dpt
LEFT JOIN data_task dt ON dpt.task_id = dt.task_id_name
WHERE dt.task_id_name IS NULL
AND dpt.task_state = 0;
" 2>/dev/null)

echo -e "${GREEN}✓${NC} 发现 ${YELLOW}${MISSING_COUNT}${NC} 个PSI任务缺失data_task记录"
echo ""

if [ "$MISSING_COUNT" -eq 0 ]; then
    echo "没有需要修复的任务，退出"
    exit 0
fi

# 显示缺失的任务详情
echo "缺失data_task记录的PSI任务:"
docker exec mysql mysql -uprimihub -p'primihub@123' privacy -t -e "
SELECT
    dpt.psi_id AS 'PSI ID',
    dpt.task_id AS 'Task ID',
    dp.own_organ_id AS 'Organ ID',
    dpt.create_date AS '创建时间'
FROM data_psi_task dpt
JOIN data_psi dp ON dpt.psi_id = dp.id
LEFT JOIN data_task dt ON dpt.task_id = dt.task_id_name
WHERE dt.task_id_name IS NULL
AND dpt.task_state = 0
ORDER BY dpt.psi_id;
" 2>/dev/null

echo ""
read -p "是否继续修复这些任务? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ] && [ "$CONFIRM" != "y" ]; then
    echo "操作已取消"
    exit 0
fi

# 2. 创建data_task记录
echo ""
echo "[2/5] 创建data_task记录..."
docker exec mysql mysql -uprimihub -p'primihub@123' privacy -e "
INSERT INTO data_task (
    task_id_name,
    task_name,
    task_desc,
    task_state,
    task_type,
    task_start_time,
    task_user_id,
    is_cooperation,
    is_del
)
SELECT
    dpt.task_id AS task_id_name,
    CONCAT('PSI_补偿_', dpt.psi_id) AS task_name,
    'PSI任务补偿创建 - 自动修复' AS task_desc,
    0 AS task_state,
    2 AS task_type,
    UNIX_TIMESTAMP(NOW()) * 1000 AS task_start_time,
    1 AS task_user_id,
    0 AS is_cooperation,
    0 AS is_del
FROM data_psi_task dpt
LEFT JOIN data_task dt ON dpt.task_id = dt.task_id_name
WHERE dt.task_id_name IS NULL
AND dpt.task_state = 0;
" 2>/dev/null

echo -e "${GREEN}✓${NC} data_task记录创建完成"

# 3. 验证创建结果
echo ""
echo "[3/5] 验证创建结果..."
REMAINING_COUNT=$(docker exec mysql mysql -uprimihub -p'primihub@123' privacy -sN -e "
SELECT COUNT(*)
FROM data_psi_task dpt
LEFT JOIN data_task dt ON dpt.task_id = dt.task_id_name
WHERE dt.task_id_name IS NULL
AND dpt.task_state = 0;
" 2>/dev/null)

if [ "$REMAINING_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} 所有PSI任务现在都有data_task记录"
else
    echo -e "${RED}✗${NC} 仍有 ${REMAINING_COUNT} 个任务缺失data_task记录"
fi

# 4. 重启application服务以触发任务执行
echo ""
echo "[4/5] 重启application服务以触发任务执行..."
read -p "是否重启application0服务? (yes/no): " RESTART_CONFIRM

if [ "$RESTART_CONFIRM" = "yes" ] || [ "$RESTART_CONFIRM" = "y" ]; then
    echo "正在重启application0..."
    docker restart application0
    echo -e "${GREEN}✓${NC} application0已重启"

    echo "等待服务启动..."
    sleep 10

    # 检查健康状态
    for i in {1..30}; do
        if docker exec application0 curl -s http://localhost:8080/actuator/health | grep -q '"status":"UP"'; then
            echo -e "${GREEN}✓${NC} application0服务已就绪"
            break
        fi
        echo "等待服务启动... ($i/30)"
        sleep 2
    done
else
    echo -e "${YELLOW}⚠${NC} 跳过服务重启"
    echo "注意: 任务可能不会自动执行，需要手动重启服务或等待定时任务触发"
fi

# 5. 显示最终状态
echo ""
echo "[5/5] 最终状态"
echo "============================================================================"
docker exec mysql mysql -uprimihub -p'primihub@123' privacy -t -e "
SELECT
    dpt.psi_id AS 'PSI ID',
    dpt.task_id AS 'Task ID',
    dpt.task_state AS 'PSI State',
    dt.task_state AS 'Task State',
    dt.task_name AS 'Task Name',
    dt.create_date AS '创建时间'
FROM data_psi_task dpt
LEFT JOIN data_task dt ON dpt.task_id = dt.task_id_name
WHERE dpt.psi_id >= 20
ORDER BY dpt.psi_id;
" 2>/dev/null

echo ""
echo "============================================================================"
echo "修复完成!"
echo "============================================================================"
echo ""
echo "后续监控:"
echo "  1. 查看任务状态: docker exec mysql mysql -uprimihub -p'primihub@123' privacy -e 'SELECT * FROM data_task WHERE task_type=2 ORDER BY task_id DESC LIMIT 10;'"
echo "  2. 查看应用日志: docker logs -f application0"
echo "  3. 查看RabbitMQ队列: docker exec rabbitmq0 rabbitmqctl list_queues"
echo ""
