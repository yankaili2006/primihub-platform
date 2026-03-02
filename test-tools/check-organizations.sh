#!/bin/bash

# =============================================================================
# PrimiHub 机构状态检查脚本
# =============================================================================
# 功能：
#   1. 检查机构配置状态
#   2. 验证机构连通性
#   3. 检查机构数据库配置
#   4. 测试机构 API 可访问性
#   5. 验证机构间协作关系
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# 获取主机 IP
HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$HOST_IP" ] && HOST_IP="localhost"

# 机构配置
declare -A ORG_PORTS=([0]="30811" [1]="30812" [2]="30813")
declare -A ORG_NAMES=([0]="机构0" [1]="机构1" [2]="机构2")
declare -A ORG_DBS=([0]="privacy1" [1]="privacy2" [2]="privacy3")

# 统计变量
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              PrimiHub 机构状态检查工具                           ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${BLUE}主机地址:${NC} $HOST_IP"
echo -e "${BLUE}检查时间:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# =============================================================================
# 工具函数
# =============================================================================

check_pass() {
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
    echo -e "  ${GREEN}✓${NC} $1"
}

check_fail() {
    ((TOTAL_CHECKS++))
    ((FAILED_CHECKS++))
    echo -e "  ${RED}✗${NC} $1"
}

# =============================================================================
# 检查容器状态
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. 检查机构容器状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for i in 0 1 2; do
    echo "${ORG_NAMES[$i]}:"

    # 检查 Gateway
    if docker ps --filter "name=gateway${i}" --filter "status=running" -q | grep -q .; then
        check_pass "Gateway${i} 运行中"
    else
        check_fail "Gateway${i} 未运行"
    fi

    # 检查 Application
    if docker ps --filter "name=application${i}" --filter "status=running" -q | grep -q .; then
        check_pass "Application${i} 运行中"
    else
        check_fail "Application${i} 未运行"
    fi

    # 检查 Nginx
    if docker ps --filter "name=manage-web${i}" --filter "status=running" -q | grep -q .; then
        check_pass "Nginx${i} 运行中"
    else
        check_fail "Nginx${i} 未运行"
    fi

    echo ""
done

# =============================================================================
# 检查端口可访问性
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. 检查机构端口可访问性"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for i in 0 1 2; do
    port=${ORG_PORTS[$i]}

    if curl -s -o /dev/null -w "%{http_code}" "http://${HOST_IP}:${port}" | grep -qE "^(200|302)"; then
        check_pass "${ORG_NAMES[$i]} (端口 ${port}) 可访问"
    else
        check_fail "${ORG_NAMES[$i]} (端口 ${port}) 不可访问"
    fi
done

echo ""

# =============================================================================
# 检查 API 健康端点
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. 检查机构 API 健康端点"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for i in 0 1 2; do
    port=${ORG_PORTS[$i]}

    if curl -s -o /dev/null -w "%{http_code}" "http://${HOST_IP}:${port}/healthConnection" | grep -q "200"; then
        check_pass "${ORG_NAMES[$i]} API 健康"
    else
        check_fail "${ORG_NAMES[$i]} API 不健康"
    fi
done

echo ""

# =============================================================================
# 检查数据库配置
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. 检查机构数据库配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查 MySQL 容器
if ! docker ps --filter "name=^mysql$" --filter "status=running" -q | grep -q .; then
    check_fail "MySQL 容器未运行，跳过数据库检查"
else
    for i in 0 1 2; do
        db=${ORG_DBS[$i]}

        if docker exec mysql mysql -uroot -proot -e "USE $db" 2>/dev/null; then
            check_pass "${ORG_NAMES[$i]} 数据库 ($db) 存在"
        else
            check_fail "${ORG_NAMES[$i]} 数据库 ($db) 不存在"
        fi
    done
fi

echo ""

# =============================================================================
# 检查机构信息配置
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. 检查机构信息配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker ps --filter "name=^mysql$" --filter "status=running" -q | grep -q .; then
    for i in 0 1 2; do
        db=${ORG_DBS[$i]}

        # 获取机构信息
        organ_info=$(docker exec mysql mysql -uroot -proot -N -e \
            "SELECT organ_id, organ_name, organ_gateway FROM $db.sys_organ WHERE is_del=0 LIMIT 1" 2>/dev/null || echo "")

        if [ -n "$organ_info" ]; then
            organ_id=$(echo "$organ_info" | awk '{print $1}')
            organ_name=$(echo "$organ_info" | awk '{print $2}')
            organ_gateway=$(echo "$organ_info" | awk '{print $3}')

            echo "${ORG_NAMES[$i]}:"
            echo "  机构ID: $organ_id"
            echo "  机构名称: $organ_name"
            echo "  机构网关: $organ_gateway"

            # 验证网关地址
            if echo "$organ_gateway" | grep -q "${ORG_PORTS[$i]}"; then
                check_pass "网关地址配置正确"
            else
                check_fail "网关地址配置可能不正确"
            fi
        else
            check_fail "${ORG_NAMES[$i]} 未配置机构信息"
        fi

        echo ""
    done
else
    check_fail "MySQL 未运行，无法检查机构信息"
fi

# =============================================================================
# 检查机构间协作关系
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. 检查机构间协作关系"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker ps --filter "name=^mysql$" --filter "status=running" -q | grep -q .; then
    for i in 0 1 2; do
        db=${ORG_DBS[$i]}

        # 获取协作机构数量
        partner_count=$(docker exec mysql mysql -uroot -proot -N -e \
            "SELECT COUNT(*) FROM $db.sys_organ WHERE is_del=0" 2>/dev/null || echo "0")

        echo "${ORG_NAMES[$i]}:"
        echo "  协作机构数量: $partner_count"

        if [ "$partner_count" -ge 3 ]; then
            check_pass "已配置协作机构"
        else
            check_fail "协作机构配置不完整（应至少有3个机构）"
        fi

        echo ""
    done
else
    check_fail "MySQL 未运行，无法检查协作关系"
fi

# =============================================================================
# 检查跨机构连通性
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. 检查跨机构连通性"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for i in 0 1 2; do
    for j in 0 1 2; do
        if [ $i -ne $j ]; then
            port=${ORG_PORTS[$j]}

            if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 \
                "http://${HOST_IP}:${port}/healthConnection" | grep -q "200"; then
                check_pass "${ORG_NAMES[$i]} -> ${ORG_NAMES[$j]} 连通"
            else
                check_fail "${ORG_NAMES[$i]} -> ${ORG_NAMES[$j]} 不连通"
            fi
        fi
    done
done

echo ""

# =============================================================================
# 检查摘要
# =============================================================================

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    检查摘要                                      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

PASS_RATE=0
if [ $TOTAL_CHECKS -gt 0 ]; then
    PASS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
fi

echo "  总检查项: $TOTAL_CHECKS"
echo -e "  ${GREEN}通过: $PASSED_CHECKS${NC}"
echo -e "  ${RED}失败: $FAILED_CHECKS${NC}"
echo -e "  通过率: ${BLUE}${PASS_RATE}%${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    log_success "所有机构配置正常"
    echo ""
    echo "访问地址:"
    for i in 0 1 2; do
        echo "  ${ORG_NAMES[$i]}: http://${HOST_IP}:${ORG_PORTS[$i]}"
    done
    echo ""
    echo "默认账号: admin / primihub123"
else
    log_error "发现 $FAILED_CHECKS 个问题"
    echo ""
    echo "建议操作:"
    echo "  1. 运行机构配置脚本: ./setup-organizations.sh"
    echo "  2. 查看详细日志: docker compose logs -f"
    echo "  3. 查看故障排查指南: TROUBLESHOOTING.md"
fi

echo ""

# 退出码
if [ $FAILED_CHECKS -gt 0 ]; then
    exit 1
else
    exit 0
fi
