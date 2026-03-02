#!/bin/bash
# PrimiHub 登录诊断和修复工具
# 诊断登录失败的原因并提供修复建议

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# 数据库配置
MYSQL_USER="primihub"
MYSQL_PASS="primihub@123"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              PrimiHub 登录诊断工具                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 诊断函数
check_service() {
    local service=$1
    echo -e "${CYAN}▸ 检查 $service 服务...${NC}"

    if docker compose ps $service | grep -q "Up"; then
        echo -e "${GREEN}  ✓ $service 服务运行正常${NC}"
        return 0
    else
        echo -e "${RED}  ✗ $service 服务未运行${NC}"
        return 1
    fi
}

check_database() {
    local db=$1
    echo -e "${CYAN}▸ 检查数据库 $db...${NC}"

    local exists=$(docker exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} \
        -e "SHOW DATABASES LIKE '$db';" 2>/dev/null | grep -c "$db")

    if [ "$exists" -eq 1 ]; then
        echo -e "${GREEN}  ✓ 数据库 $db 存在${NC}"
        return 0
    else
        echo -e "${RED}  ✗ 数据库 $db 不存在${NC}"
        return 1
    fi
}

check_users() {
    local db=$1
    echo -e "${CYAN}▸ 检查 $db 用户表...${NC}"

    local count=$(docker exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} $db \
        -sN -e "SELECT COUNT(*) FROM sys_user WHERE is_del=0;" 2>/dev/null)

    if [ "$count" -gt 0 ]; then
        echo -e "${GREEN}  ✓ 找到 $count 个用户${NC}"

        # 显示用户列表
        docker exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} $db \
            -e "SELECT user_id, user_account, user_name FROM sys_user WHERE is_del=0 LIMIT 5;" \
            2>/dev/null | grep -v "Using a password" | sed 's/^/    /'

        return 0
    else
        echo -e "${RED}  ✗ 没有找到用户${NC}"
        return 1
    fi
}

check_organs() {
    local db=$1
    echo -e "${CYAN}▸ 检查 $db 机构表...${NC}"

    local count=$(docker exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} $db \
        -sN -e "SELECT COUNT(*) FROM sys_organ WHERE is_del=0;" 2>/dev/null)

    if [ "$count" -gt 0 ]; then
        echo -e "${GREEN}  ✓ 找到 $count 个机构${NC}"

        # 显示机构列表
        docker exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} $db \
            -e "SELECT id, organ_id, organ_name FROM sys_organ WHERE is_del=0 LIMIT 5;" \
            2>/dev/null | grep -v "Using a password" | sed 's/^/    /'

        return 0
    else
        echo -e "${RED}  ✗ 没有找到机构 (这是登录失败的主要原因！)${NC}"
        return 1
    fi
}

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                     1. 服务状态检查${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

service_ok=0
check_service "mysql" && ((service_ok++))
check_service "application0" && ((service_ok++))
check_service "gateway0" && ((service_ok++))
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                     2. 数据库检查${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

db_ok=0
check_database "privacy1" && ((db_ok++))
check_database "privacy2" && ((db_ok++))
check_database "privacy3" && ((db_ok++))
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                     3. 用户数据检查${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

users_ok=0
check_users "privacy1" && ((users_ok++))
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                     4. 机构数据检查 (关键!)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

organs_ok=0
check_organs "privacy1" && ((organs_ok++))
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                     诊断结果${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# 显示诊断结果
echo "服务状态: $([ $service_ok -eq 3 ] && echo -e "${GREEN}✓ 正常${NC}" || echo -e "${RED}✗ 异常${NC}")"
echo "数据库状态: $([ $db_ok -eq 3 ] && echo -e "${GREEN}✓ 正常${NC}" || echo -e "${RED}✗ 异常${NC}")"
echo "用户数据: $([ $users_ok -eq 1 ] && echo -e "${GREEN}✓ 正常${NC}" || echo -e "${RED}✗ 异常${NC}")"
echo "机构数据: $([ $organs_ok -eq 1 ] && echo -e "${GREEN}✓ 正常${NC}" || echo -e "${RED}✗ 异常 (登录失败的主要原因)${NC}")"
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                     修复建议${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

if [ $organs_ok -eq 0 ]; then
    echo -e "${RED}【问题】机构数据为空，这会导致登录失败！${NC}"
    echo ""
    echo -e "${GREEN}【解决方案】执行机构配置脚本：${NC}"
    echo "  bash setup-organizations.sh"
    echo ""
    echo "此脚本将会："
    echo "  1. 自动注册3个机构"
    echo "  2. 配置机构资源"
    echo "  3. 建立机构关联关系"
    echo ""
    read -p "是否现在执行机构配置? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}正在配置机构...${NC}"
        bash setup-organizations.sh
        echo ""
        echo -e "${GREEN}配置完成！现在可以尝试登录了。${NC}"
    fi
elif [ $users_ok -eq 0 ]; then
    echo -e "${RED}【问题】用户数据为空！${NC}"
    echo ""
    echo -e "${GREEN}【解决方案】需要初始化数据库：${NC}"
    echo "  请检查初始SQL脚本是否正确执行"
elif [ $service_ok -lt 3 ]; then
    echo -e "${RED}【问题】服务未正常运行！${NC}"
    echo ""
    echo -e "${GREEN}【解决方案】${NC}"
    echo "  1. 检查服务状态: docker compose ps"
    echo "  2. 启动服务: docker compose up -d"
    echo "  3. 查看日志: docker logs <服务名>"
else
    echo -e "${GREEN}✓ 所有检查通过，登录应该可以正常工作！${NC}"
    echo ""
    echo "测试登录:"
    echo "  python3 test-user-api.py"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
