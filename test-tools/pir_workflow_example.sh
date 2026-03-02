#!/bin/bash
# PIR 完整工作流程示例
# 演示如何通过 CLI 创建 PIR 项目并执行任务

set -e  # 遇到错误立即退出

echo "=========================================="
echo "PIR 完整工作流程演示"
echo "=========================================="

# 配置参数
PROJECT_NAME="PIR测试项目_$(date +%Y%m%d_%H%M%S)"
TASK_NAME="PIR查询任务_$(date +%Y%m%d_%H%M%S)"

# 机构ID（根据实际环境修改）
ORG1="000000000000000000000000test0001"  # 服务方（数据提供方）
ORG2="000000000000000000000000test0002"  # 查询方（客户端）

# 资源ID（根据实际环境修改）
SERVER_RESOURCE="5"  # 服务方资源ID
QUERY_PARAM="user_12345"  # 查询参数

echo ""
echo "步骤 1: 创建 PIR 项目"
echo "----------------------------------------"
python3 primihub-cli.py pir-create-project "$PROJECT_NAME" \
  --desc "通过CLI创建的PIR项目" \
  --organs "$ORG1,$ORG2"

echo ""
echo "请输入上面创建的项目ID:"
read PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "错误: 项目ID不能为空"
    exit 1
fi

echo ""
echo "步骤 2: 创建 PIR 任务"
echo "----------------------------------------"
python3 primihub-cli.py pir-create "$PROJECT_ID" "$TASK_NAME" \
  --server-organ "$ORG1" \
  --server-resource "$SERVER_RESOURCE" \
  --client-organ "$ORG2" \
  --query-param "$QUERY_PARAM"

echo ""
echo "请输入上面创建的任务ID:"
read TASK_ID

if [ -z "$TASK_ID" ]; then
    echo "错误: 任务ID不能为空"
    exit 1
fi

echo ""
echo "步骤 3: 查看任务详情"
echo "----------------------------------------"
python3 primihub-cli.py pir-task-detail "$TASK_ID"

echo ""
echo "=========================================="
echo "PIR 工作流程完成！"
echo "=========================================="
echo ""
echo "提示:"
echo "  - 项目ID: $PROJECT_ID"
echo "  - 任务ID: $TASK_ID"
echo "  - 查看任务列表: python3 primihub-cli.py pir-tasks"
echo "  - 查看任务详情: python3 primihub-cli.py pir-task-detail $TASK_ID"
echo "  - Web界面: http://localhost:30811"
echo ""
