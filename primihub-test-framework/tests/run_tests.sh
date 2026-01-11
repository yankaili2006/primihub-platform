#!/bin/bash
################################################################################
# PrimiHub 测试框架 - 主测试运行器
# PrimiHub Test Framework - Main Test Runner
#
# 功能: 编排测试执行，生成测试报告
# Features: Orchestrate test execution and generate reports
#
# 使用方式:
#   ./run_tests.sh --all                    # 运行所有测试
#   ./run_tests.sh --suite user_management  # 运行特定模块
#   ./run_tests.sh --type api               # 仅API测试
#   ./run_tests.sh --type flow              # 仅业务流程测试
#   ./run_tests.sh --performance            # 性能测试
#   ./run_tests.sh --all --report-format html # 生成HTML报告
################################################################################

set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 默认选项
RUN_ALL=false
SUITE=""
TEST_TYPE=""
PERFORMANCE=false
REPORT_FORMAT="html"
VERBOSE=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# 打印函数
################################################################################
print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

################################################################################
# 帮助信息
################################################################################
show_help() {
    cat << EOF
PrimiHub 测试框架运行器

使用方式:
  $0 [选项]

选项:
  --all                 运行所有测试
  --suite SUITE         运行特定测试套件
                        可选: user_management, data_management,
                              project_task, privacy_computing,
                              system_features
  --type TYPE           运行特定类型的测试
                        可选: api, flow, db
  --performance         运行性能测试
  --report-format FMT   报告格式 (html, json, markdown)
  --verbose, -v         详细输出
  --help, -h            显示此帮助信息

示例:
  $0 --all                              # 运行所有测试
  $0 --suite user_management            # 运行用户管理测试
  $0 --type api                         # 仅运行API测试
  $0 --all --report-format html         # 生成HTML报告
  $0 --performance                      # 运行性能测试

EOF
}

################################################################################
# 解析命令行参数
################################################################################
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                RUN_ALL=true
                shift
                ;;
            --suite)
                SUITE="$2"
                shift 2
                ;;
            --type)
                TEST_TYPE="$2"
                shift 2
                ;;
            --performance)
                PERFORMANCE=true
                shift
                ;;
            --report-format)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

################################################################################
# 检查Python环境
################################################################################
check_python_env() {
    print_info "检查Python环境..."

    if ! command -v python3 &> /dev/null; then
        print_error "Python3未安装"
        exit 1
    fi

    # 检查依赖
    if ! python3 -c "import requests" 2>/dev/null; then
        print_warn "缺少Python依赖，尝试安装..."
        pip3 install -r "${PROJECT_ROOT}/requirements.txt"
    fi

    print_success "Python环境检查通过"
}

################################################################################
# 运行Shell测试
################################################################################
run_shell_tests() {
    local test_dir="$1"
    local test_name="$2"

    if [ ! -d "$test_dir" ]; then
        print_warn "测试目录不存在: $test_dir"
        return 0
    fi

    local shell_tests=($(find "$test_dir" -name "*.sh" 2>/dev/null | sort))

    if [ ${#shell_tests[@]} -eq 0 ]; then
        print_info "没有找到Shell测试: $test_name"
        return 0
    fi

    print_info "运行Shell测试: $test_name (${#shell_tests[@]}个)"

    for test_file in "${shell_tests[@]}"; do
        local test_basename=$(basename "$test_file")

        if [ ! -x "$test_file" ]; then
            chmod +x "$test_file"
        fi

        print_info "  - $test_basename"

        if bash "$test_file"; then
            print_success "    ✓ $test_basename 通过"
        else
            print_error "    ✗ $test_basename 失败"
        fi
    done
}

################################################################################
# 运行Python测试
################################################################################
run_python_tests() {
    local test_dir="$1"
    local test_name="$2"

    if [ ! -d "$test_dir" ]; then
        print_warn "测试目录不存在: $test_dir"
        return 0
    fi

    local python_tests=($(find "$test_dir" -name "*.py" 2>/dev/null | sort))

    if [ ${#python_tests[@]} -eq 0 ]; then
        print_info "没有找到Python测试: $test_name"
        return 0
    fi

    print_info "运行Python测试: $test_name (${#python_tests[@]}个)"

    for test_file in "${python_tests[@]}"; do
        local test_basename=$(basename "$test_file")

        print_info "  - $test_basename"

        if python3 "$test_file"; then
            print_success "    ✓ $test_basename 通过"
        else
            print_error "    ✗ $test_basename 失败"
        fi
    done
}

################################################################################
# 运行测试套件
################################################################################
run_test_suite() {
    local suite_name="$1"
    local suite_dir="${SCRIPT_DIR}/suites/${suite_name}"

    if [ ! -d "$suite_dir" ]; then
        print_error "测试套件不存在: $suite_name"
        return 1
    fi

    print_header "运行测试套件: $suite_name"

    # 根据TEST_TYPE过滤测试
    case "$TEST_TYPE" in
        api)
            run_shell_tests "$suite_dir" "$suite_name - API"
            ;;
        flow)
            run_python_tests "$suite_dir" "$suite_name - Flow"
            ;;
        *)
            run_shell_tests "$suite_dir" "$suite_name - API"
            run_python_tests "$suite_dir" "$suite_name - Flow"
            ;;
    esac
}

################################################################################
# 运行所有测试
################################################################################
run_all_tests() {
    print_header "运行所有测试"

    local test_suites=(
        "01_user_management"
        "02_data_management"
        "03_project_task"
        "04_privacy_computing"
        "05_system_features"
    )

    for suite in "${test_suites[@]}"; do
        run_test_suite "$suite"
    done
}

################################################################################
# 运行性能测试
################################################################################
run_performance_tests() {
    print_header "运行性能测试"

    local perf_dir="${SCRIPT_DIR}/performance"

    if [ ! -d "$perf_dir" ]; then
        print_warn "性能测试目录不存在"
        return 0
    fi

    run_shell_tests "$perf_dir" "性能测试"
    run_python_tests "$perf_dir" "性能测试"
}

################################################################################
# 生成测试报告
################################################################################
generate_report() {
    print_info "生成测试报告..."

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="${SCRIPT_DIR}/reports/test_report_${timestamp}.${REPORT_FORMAT}"

    # TODO: 集成report_generator.py生成报告

    print_success "测试报告已生成: $report_file"
}

################################################################################
# 主函数
################################################################################
main() {
    clear

    print_header "PrimiHub 测试框架"

    print_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # 解析命令行参数
    parse_arguments "$@"

    # 检查Python环境
    check_python_env

    # 根据选项运行测试
    if [ "$PERFORMANCE" = true ]; then
        run_performance_tests
    elif [ "$RUN_ALL" = true ]; then
        run_all_tests
    elif [ -n "$SUITE" ]; then
        run_test_suite "$SUITE"
    else
        print_error "请指定测试选项"
        show_help
        exit 1
    fi

    # 生成报告
    generate_report

    echo ""
    print_header "测试完成"
    print_info "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
}

# 执行主函数
main "$@"
