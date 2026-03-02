#!/bin/bash
# PSI 完整工作流程示例
# 演示如何通过 CLI 创建 PSI 项目并执行任务

set -e  # 遇到错误立即退出

echo "=========================================="
echo "PSI 完整工作流程演示"
echo "=========================================="

# 配置参数
PROJECT_NAME="PSI测试项目_$(date +%Y%m%d_%H%M%S)"
TASK_NAME="PSI求交任务_$(date +%Y%m%d_%H%M%S)"

# 机构ID（根据实际环境修改）
ORG1="000000000000000000000000test0001"  # 发起方
ORG2="000000000000000000000000test0002"  # 协作方

# 资源ID和匹配字段（根据实际环境修改）
RESOURCE1="3"           # 发起方资源ID
KEYWORD1="user_id"      # 发起方匹配字段
RESOURCE2="4"           # 协作方资源ID
KEYWORD2="user_id"      # 协作方匹配字段

# PSI 算法选择
# 0=DH, 1=ECDH, 2=KKRT, 3=BC22
ALGORITHM=0

echo ""
echo "步骤 1: 创建 PSI 项目"
echo "----------------------------------------"
python3 primihub-cli.py psi-create-project "$PROJECT_NAME" \
  --desc "通过CLI创建的PSI项目" \
  --organs "$ORG1,$ORG2"

echo ""
echo "请输入上面创建的项目ID:"
read PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "错误: 项目ID不能为空"
    exit 1
fi

echo ""
echo "步骤 2: 创建 PSI 任务"
echo "----------------------------------------"
echo "使用算法: DH (Diffie-Hellman)"
python3 primihub-cli.py psi-create "$PROJECT_ID" "$TASK_NAME" \
  --own-organ "$ORG1" \
  --own-resource "$RESOURCE1" \
  --own-keyword "$KEYWORD1" \
  --other-organ "$ORG2" \
  --other-resource "$RESOURCE2" \
  --other-keyword "$KEYWORD2" \
  --algorithm $ALGORITHM

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
python3 primihub-cli.py psi-task-detail "$TASK_ID"

echo ""
echo "=========================================="
echo "PSI 工作流程完成！"
echo "=========================================="
echo ""
echo "提示:"
echo "  - 项目ID: $PROJECT_ID"
echo "  - 任务ID: $TASK_ID"
echo "  - 查看任务列表: python3 primihub-cli.py psi-tasks"
echo "  - 查看任务详情: python3 primihub-cli.py psi-task-detail $TASK_ID"
echo "  - Web界面: http://localhost:30811"
echo ""
echo "算法说明:"
echo "  0 = DH (Diffie-Hellman) - 适合小规模数据"
echo "  1 = ECDH (椭圆曲线DH) - 适合中等规模数据"
echo "  2 = KKRT (不经意传输) - 适合大规模数据"
echo "  3 = BC22 (不经意传输) - 适合超大规模数据"
echo ""
