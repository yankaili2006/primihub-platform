#!/bin/bash
################################################################################
# PrimiHub 测试框架 - 主初始化脚本
# PrimiHub Test Framework - Main Initialization Script
#
# 功能: 编排整个初始化流程，提供统一的入口点
# Features: Orchestrate the entire initialization process
#
# 使用方式:
#   ./main_init.sh                        # 全量初始化
#   ./main_init.sh --skip-env-check       # 跳过环境检查
#   ./main_init.sh --only-db              # 仅初始化数据库
#   ./main_init.sh --with-test-data       # 包含测试数据
#   ./main_init.sh --clean                # 清除现有数据（谨慎使用）
#   ./main_init.sh --help                 # 显示帮助信息
################################################################################

set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 默认选项
SKIP_ENV_CHECK=false
SKIP_SERVICE_CHECK=false
ONLY_DB=false
WITH_TEST_DATA=false
CLEAN_DATA=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_step() {
    echo -e "\n${GREEN}▶${NC} ${BLUE}$1${NC}"
}

################################################################################
# 进度显示
################################################################################
show_progress() {
    local current=$1
    local total=$2
    local message=$3

    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))

    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %d%% - %s" $percent "$message"
}

clear_progress() {
    printf "\r%80s\r" " "
}

################################################################################
# 帮助信息
################################################################################
show_help() {
    cat << EOF
PrimiHub 测试框架初始化脚本

使用方式:
  $0 [选项]

选项:
  --skip-env-check      跳过环境检查
  --skip-service-check  跳过服务检查
  --only-db             仅初始化数据库
  --with-test-data      初始化测试数据
  --clean               清除现有数据（谨慎使用）
  --help, -h            显示此帮助信息

示例:
  $0                          # 全量初始化
  $0 --with-test-data         # 初始化并生成测试数据
  $0 --only-db --clean        # 清除并重新初始化数据库

EOF
}

################################################################################
# 解析命令行参数
################################################################################
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-env-check)
                SKIP_ENV_CHECK=true
                shift
                ;;
            --skip-service-check)
                SKIP_SERVICE_CHECK=true
                shift
                ;;
            --only-db)
                ONLY_DB=true
                shift
                ;;
            --with-test-data)
                WITH_TEST_DATA=true
                shift
                ;;
            --clean)
                CLEAN_DATA=true
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
# 加载配置
################################################################################
load_configuration() {
    print_step "加载配置文件..."

    local config_file="${SCRIPT_DIR}/config/env.conf"

    if [ ! -f "$config_file" ]; then
        print_error "配置文件不存在: $config_file"
        exit 1
    fi

    source "$config_file"

    # 覆盖命令行参数
    if [ "$CLEAN_DATA" = true ]; then
        export CLEAN_EXISTING_DATA=true
    fi

    if [ "$WITH_TEST_DATA" = true ]; then
        export INIT_TEST_DATA=true
    fi

    print_success "配置加载成功"
}

################################################################################
# 创建必要的目录
################################################################################
create_directories() {
    print_step "创建必要的目录..."

    mkdir -p "${PROJECT_ROOT}/logs"
    mkdir -p "${PROJECT_ROOT}/backups"

    print_success "目录创建成功"
}

################################################################################
# 执行模块
################################################################################
execute_module() {
    local module_script="$1"
    local module_name="$2"

    if [ ! -f "$module_script" ]; then
        print_warn "模块脚本不存在: $module_script，跳过"
        return 0
    fi

    if [ ! -x "$module_script" ]; then
        chmod +x "$module_script"
    fi

    print_step "执行模块: $module_name"

    if bash "$module_script"; then
        print_success "$module_name 执行成功"
        return 0
    else
        print_error "$module_name 执行失败"
        return 1
    fi
}

################################################################################
# 错误处理
################################################################################
handle_error() {
    local line=$1
    print_error "脚本执行失败，错误发生在第 $line 行"
    print_info "查看日志文件获取更多信息: ${PROJECT_ROOT}/logs/"
    exit 1
}

trap 'handle_error $LINENO' ERR

################################################################################
# 主函数
################################################################################
main() {
    clear

    print_header "PrimiHub 测试框架初始化"

    print_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # 解析命令行参数
    parse_arguments "$@"

    # 加载配置
    load_configuration

    # 创建目录
    create_directories

    local total_steps=5
    local current_step=0

    # 模块列表
    declare -A modules=(
        ["01_env_check.sh"]="环境检查"
        ["02_service_check.sh"]="服务检查"
        ["03_db_init.sh"]="数据库初始化"
        ["04_data_seed.sh"]="测试数据初始化"
        ["05_health_check.sh"]="健康检查"
    )

    # 如果只初始化数据库
    if [ "$ONLY_DB" = true ]; then
        print_info "模式: 仅初始化数据库"
        execute_module "${SCRIPT_DIR}/modules/03_db_init.sh" "数据库初始化"

        if [ "$WITH_TEST_DATA" = true ]; then
            execute_module "${SCRIPT_DIR}/modules/04_data_seed.sh" "测试数据初始化"
        fi

        print_header "初始化完成"
        exit 0
    fi

    # 全量初始化
    print_info "模式: 全量初始化"
    echo ""

    # 1. 环境检查
    ((current_step++))
    if [ "$SKIP_ENV_CHECK" = false ] && [ -f "${SCRIPT_DIR}/modules/01_env_check.sh" ]; then
        show_progress $current_step $total_steps "环境检查"
        execute_module "${SCRIPT_DIR}/modules/01_env_check.sh" "环境检查"
        clear_progress
    else
        print_warn "跳过环境检查"
    fi

    # 2. 服务检查
    ((current_step++))
    if [ "$SKIP_SERVICE_CHECK" = false ] && [ -f "${SCRIPT_DIR}/modules/02_service_check.sh" ]; then
        show_progress $current_step $total_steps "服务检查"
        execute_module "${SCRIPT_DIR}/modules/02_service_check.sh" "服务检查"
        clear_progress
    else
        print_warn "跳过服务检查"
    fi

    # 3. 数据库初始化
    ((current_step++))
    show_progress $current_step $total_steps "数据库初始化"
    execute_module "${SCRIPT_DIR}/modules/03_db_init.sh" "数据库初始化"
    clear_progress

    # 4. 测试数据初始化
    ((current_step++))
    if [ "$WITH_TEST_DATA" = true ] && [ -f "${SCRIPT_DIR}/modules/04_data_seed.sh" ]; then
        show_progress $current_step $total_steps "测试数据初始化"
        execute_module "${SCRIPT_DIR}/modules/04_data_seed.sh" "测试数据初始化"
        clear_progress
    else
        print_info "跳过测试数据初始化"
    fi

    # 5. 健康检查
    ((current_step++))
    if [ -f "${SCRIPT_DIR}/modules/05_health_check.sh" ]; then
        show_progress $current_step $total_steps "健康检查"
        execute_module "${SCRIPT_DIR}/modules/05_health_check.sh" "健康检查"
        clear_progress
    fi

    echo ""
    print_header "初始化完成"

    print_success "所有步骤执行成功"
    print_info "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"

    echo ""
    print_info "下一步操作:"
    print_info "  1. 查看日志: ls -lh ${PROJECT_ROOT}/logs/"
    print_info "  2. 运行测试: cd ${PROJECT_ROOT}/../tests && ./run_tests.sh --all"
    echo ""
}

# 执行主函数
main "$@"
