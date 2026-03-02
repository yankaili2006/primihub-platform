#!/bin/bash
# 查询数据库中的用户列表
# 用于在API登录不可用时直接查询数据库

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              查询 PrimiHub 用户列表                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 数据库配置
MYSQL_USER="primihub"
MYSQL_PASS="primihub@123"

# 查询所有数据库的用户
for db in privacy1 privacy2 privacy3; do
    echo -e "${YELLOW}=== 数据库: $db ===${NC}"

    # 检查是否有用户表
    table_exists=$(docker exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} $db \
        -e "SHOW TABLES LIKE 'sys_user';" 2>/dev/null | grep -c "sys_user")

    if [ "$table_exists" -eq 0 ]; then
        echo -e "${RED}  ✗ 该数据库不包含 sys_user 表${NC}"
        echo ""
        continue
    fi

    # 查询用户总数
    total=$(docker exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} $db \
        -sN -e "SELECT COUNT(*) FROM sys_user WHERE is_del=0;" 2>/dev/null)

    echo -e "${GREEN}  ✓ 找到 $total 个用户${NC}"
    echo ""

    # 查询并显示用户列表
    docker exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} $db \
        -e "SELECT
            user_id AS '用户ID',
            user_account AS '账号',
            user_name AS '用户名',
            role_id_list AS '角色ID',
            CASE
                WHEN is_forbid = 0 THEN '正常'
                ELSE '禁用'
            END AS '状态',
            DATE_FORMAT(c_time, '%Y-%m-%d %H:%i:%s') AS '创建时间'
        FROM sys_user
        WHERE is_del = 0
        ORDER BY user_id;" 2>/dev/null | grep -v "Using a password"

    echo ""
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "说明:"
echo "  - 用户ID: 系统内部用户唯一标识"
echo "  - 账号: 登录账号"
echo "  - 用户名: 显示名称"
echo "  - 角色ID: 用户角色标识（1=管理员）"
echo "  - 状态: 正常/禁用"
echo ""
echo "重置密码:"
echo "  bash manage-organization.sh reset-password 30811"
echo ""
