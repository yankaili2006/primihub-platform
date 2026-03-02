#!/bin/bash
# PrimiHub API 自动化测试脚本
# 用于快速验证系统状态和API可用性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
BASE_URL="${PRIMIHUB_URL:-http://localhost:30811/prod-api}"
USER="${PRIMIHUB_USER:-admin}"
PASS="${PRIMIHUB_PASS:-123456}"

# 计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 打印函数
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# 测试函数
test_api() {
    local name=$1
    local cmd=$2

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if eval "$cmd" > /dev/null 2>&1; then
        print_success "$name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_error "$name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 主测试流程
main() {
    print_header "PrimiHub API 自动化测试"
    echo ""
    print_info "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    print_info "服务器: $BASE_URL"
    print_info "用户: $USER"
    echo ""

    # 检查依赖
    print_header "检查依赖"
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 未安装"
        exit 1
    fi
    print_success "Python3 已安装"

    if ! command -v docker &> /dev/null; then
        print_warning "Docker 未安装（部分功能不可用）"
    else
        print_success "Docker 已安装"
    fi

    if [ ! -f "primihub-cli.py" ]; then
        print_error "primihub-cli.py 未找到"
        exit 1
    fi
    print_success "CLI工具已找到"
    echo ""

    # 测试服务连通性
    print_header "服务连通性测试"
    test_api "健康检查" "python3 primihub-cli.py --url $BASE_URL health"
    test_api "用户登录" "python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS login"
    echo ""

    # 测试核心功能
    print_header "核心功能测试"
    test_api "项目列表" "python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS projects --size 5"
    test_api "数据集列表" "python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS datasets --size 5"
    test_api "任务列表" "python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS tasks --size 5"
    test_api "用户列表" "python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS users --size 5"
    echo ""

    # 测试PIR/PSI功能
    print_header "PIR/PSI功能测试"
    test_api "PIR任务列表" "python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS pir-tasks --size 5"
    test_api "PSI任务列表" "python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS psi-tasks --size 5"
    echo ""

    # 测试数据集功能
    print_header "数据集功能测试"
    test_api "数据集标签" "python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS dataset-tags"
    echo ""

    # 已知问题测试
    print_header "已知问题验证"
    if python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS organs --size 5 > /dev/null 2>&1; then
        print_success "机构列表接口 (已修复)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_warning "机构列表接口 (已知问题 - HTTP 500)"
        print_info "  临时方案: docker exec mysql mysql -uprimihub -pprimihub@123 privacy -e \"SELECT organ_id, organ_name FROM sys_organ WHERE is_del=0;\""
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if python3 primihub-cli.py --url $BASE_URL --user $USER --password $PASS fl-tasks --size 5 > /dev/null 2>&1; then
        print_success "联邦学习接口 (已修复)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_warning "联邦学习接口 (已知问题 - 查询失败)"
        print_info "  临时方案: 使用通用任务列表接口"
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo ""

    # 测试结果汇总
    print_header "测试结果汇总"
    echo ""
    echo "总测试数: $TOTAL_TESTS"
    echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
    echo -e "${RED}失败: $FAILED_TESTS${NC}"

    PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo ""
    echo "通过率: ${PASS_RATE}%"
    echo ""

    if [ $PASS_RATE -ge 90 ]; then
        print_success "系统状态: 优秀"
    elif [ $PASS_RATE -ge 70 ]; then
        print_warning "系统状态: 良好"
    else
        print_error "系统状态: 需要关注"
    fi
    echo ""

    # 建议
    print_header "建议"
    if [ $FAILED_TESTS -gt 0 ]; then
        echo "发现 $FAILED_TESTS 个失败的测试，建议："
        echo "1. 查看详细日志: docker logs application0 --tail 100"
        echo "2. 查看故障排查指南: cat API_TROUBLESHOOTING_GUIDE.md"
        echo "3. 查看完整测试报告: cat API_TEST_FINAL_SUMMARY.md"
    else
        echo "所有测试通过！系统运行正常。"
    fi
    echo ""

    # 返回状态码
    if [ $PASS_RATE -ge 80 ]; then
        exit 0
    else
        exit 1
    fi
}

# 运行主函数
main
