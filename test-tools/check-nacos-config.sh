#!/bin/bash

# =============================================================================
# Nacos 配置检查和自动修复脚本
# =============================================================================
# 功能：
#   1. 检查 Nacos 配置中心是否可访问
#   2. 验证所有租户的必需配置文件是否存在
#   3. 自动创建缺失的 organ_info.json 配置
#   4. 提供详细的配置状态报告
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
log_check()   { echo -e "${CYAN}[CHECK]${NC} $1"; }

# 配置参数
NACOS_HOST="${NACOS_HOST:-localhost}"
NACOS_PORT="${NACOS_PORT:-8848}"
NACOS_URL="http://${NACOS_HOST}:${NACOS_PORT}"
AUTO_FIX="${AUTO_FIX:-true}"

# 租户列表
TENANTS=("demo0" "demo1" "demo2")

# 必需的配置文件列表
REQUIRED_CONFIGS=(
    "base.json"
    "database.yaml"
    "redis.yaml"
    "fusion.yaml"
    "components.json"
    "organ_info.json"
)

# 可选的配置文件
OPTIONAL_CONFIGS=(
    "gateway-router.json"
)

# 统计变量
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
FIXED_CONFIGS=0
VALIDATION_WARNINGS=0

# 是否启用内容验证
VALIDATE_CONTENT="${VALIDATE_CONTENT:-true}"

# =============================================================================
# 辅助函数
# =============================================================================

# 检查 Nacos 是否可访问
check_nacos_available() {
    log_check "检查 Nacos 服务状态..."

    # 尝试访问配置 API 来验证 Nacos 是否可用
    local test_response=$(curl -s "${NACOS_URL}/nacos/v1/cs/configs?dataId=test&group=DEFAULT_GROUP&tenant=demo0" 2>&1)

    if [ $? -ne 0 ]; then
        log_error "Nacos 服务不可访问: ${NACOS_URL}"
        log_info "请确保 Nacos 容器正在运行: docker ps | grep nacos"
        return 1
    fi

    log_success "Nacos 服务正常运行"
    return 0
}

# 检查配置是否存在
check_config_exists() {
    local data_id="$1"
    local group="$2"
    local tenant="$3"

    local response=$(curl -s "${NACOS_URL}/nacos/v1/cs/configs?dataId=${data_id}&group=${group}&tenant=${tenant}")

    if [ "$response" = "config data not exist" ] || [ -z "$response" ]; then
        return 1
    fi

    return 0
}

# 获取配置内容
get_config_content() {
    local data_id="$1"
    local group="$2"
    local tenant="$3"

    curl -s "${NACOS_URL}/nacos/v1/cs/configs?dataId=${data_id}&group=${group}&tenant=${tenant}"
}

# =============================================================================
# 配置内容验证函数
# =============================================================================

# 验证 organ_info.json 配置
validate_organ_info() {
    local tenant="$1"
    local content="$2"
    local issues=()

    # 检查 JSON 格式
    if ! echo "$content" | python3 -m json.tool &>/dev/null; then
        issues+=("JSON 格式错误")
        echo "${issues[@]}"
        return 1
    fi

    # 检查必需字段
    local organ_id=$(echo "$content" | grep -o '"organId"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    local organ_name=$(echo "$content" | grep -o '"organName"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    local organ_gateway=$(echo "$content" | grep -o '"organGateway"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

    [ -z "$organ_id" ] && issues+=("缺少 organId 字段")
    [ -z "$organ_name" ] && issues+=("缺少 organName 字段")
    [ -z "$organ_gateway" ] && issues+=("缺少 organGateway 字段")

    # 验证 organId 长度（应为 32 位）
    if [ -n "$organ_id" ] && [ ${#organ_id} -ne 32 ]; then
        issues+=("organId 长度应为 32 位，当前为 ${#organ_id} 位")
    fi

    # 验证 organGateway 格式（应为 http:// 或 https:// 开头）
    if [ -n "$organ_gateway" ] && ! echo "$organ_gateway" | grep -qE '^https?://'; then
        issues+=("organGateway 格式错误，应以 http:// 或 https:// 开头")
    fi

    # 验证端口号是否与租户匹配
    local expected_port=""
    case "$tenant" in
        demo0) expected_port="30811" ;;
        demo1) expected_port="30812" ;;
        demo2) expected_port="30813" ;;
    esac

    if [ -n "$organ_gateway" ] && [ -n "$expected_port" ]; then
        if ! echo "$organ_gateway" | grep -q ":${expected_port}"; then
            issues+=("端口号建议使用 ${expected_port}（当前租户：${tenant}）")
        fi
    fi

    if [ ${#issues[@]} -gt 0 ]; then
        echo "${issues[@]}"
        return 1
    fi

    return 0
}

# 验证 database.yaml 配置
validate_database_config() {
    local tenant="$1"
    local content="$2"
    local issues=()

    # 检查数据库名称是否与租户匹配
    local expected_db=""
    case "$tenant" in
        demo0) expected_db="privacy1" ;;
        demo1) expected_db="privacy2" ;;
        demo2) expected_db="privacy3" ;;
    esac

    if ! echo "$content" | grep -q "/${expected_db}?"; then
        issues+=("数据库名称应为 ${expected_db}（当前租户：${tenant}）")
    fi

    # 检查必需字段
    echo "$content" | grep -q "driver-class-name:" || issues+=("缺少 driver-class-name 配置")
    echo "$content" | grep -q "username:" || issues+=("缺少 username 配置")
    echo "$content" | grep -q "password:" || issues+=("缺少 password 配置")
    echo "$content" | grep -q "url:" || issues+=("缺少 url 配置")

    # 检查连接池配置
    echo "$content" | grep -q "initial-size:" || issues+=("缺少 initial-size 配置")
    echo "$content" | grep -q "max-active:" || issues+=("缺少 max-active 配置")

    if [ ${#issues[@]} -gt 0 ]; then
        echo "${issues[@]}"
        return 1
    fi

    return 0
}

# 验证 redis.yaml 配置
validate_redis_config() {
    local tenant="$1"
    local content="$2"
    local issues=()

    # 检查 Redis 数据库编号是否与租户匹配
    local expected_db=""
    case "$tenant" in
        demo0) expected_db="0" ;;
        demo1) expected_db="1" ;;
        demo2) expected_db="2" ;;
    esac

    if ! echo "$content" | grep -q "database:[[:space:]]*${expected_db}"; then
        issues+=("Redis database 应为 ${expected_db}（当前租户：${tenant}）")
    fi

    # 检查必需字段
    echo "$content" | grep -q "hostName:" || issues+=("缺少 hostName 配置")
    echo "$content" | grep -q "port:" || issues+=("缺少 port 配置")
    echo "$content" | grep -q "password:" || issues+=("缺少 password 配置")

    # 检查连接池配置
    echo "$content" | grep -q "maxTotal:" || issues+=("缺少 maxTotal 配置")

    if [ ${#issues[@]} -gt 0 ]; then
        echo "${issues[@]}"
        return 1
    fi

    return 0
}

# 验证 fusion.yaml 配置
validate_fusion_config() {
    local tenant="$1"
    local content="$2"
    local issues=()

    # 检查融合数据库名称是否与租户匹配
    local expected_db=""
    case "$tenant" in
        demo0) expected_db="fusion1" ;;
        demo1) expected_db="fusion2" ;;
        demo2) expected_db="fusion3" ;;
    esac

    if ! echo "$content" | grep -q "/${expected_db}?"; then
        issues+=("融合数据库名称应为 ${expected_db}（当前租户：${tenant}）")
    fi

    # 检查必需字段
    echo "$content" | grep -q "driver-class-name:" || issues+=("缺少 driver-class-name 配置")
    echo "$content" | grep -q "username:" || issues+=("缺少 username 配置")
    echo "$content" | grep -q "password:" || issues+=("缺少 password 配置")
    echo "$content" | grep -q "url:" || issues+=("缺少 url 配置")

    if [ ${#issues[@]} -gt 0 ]; then
        echo "${issues[@]}"
        return 1
    fi

    return 0
}

# 验证 base.json 配置
validate_base_config() {
    local tenant="$1"
    local content="$2"
    local issues=()

    # 检查 JSON 格式
    if ! echo "$content" | python3 -m json.tool &>/dev/null; then
        issues+=("JSON 格式错误")
        echo "${issues[@]}"
        return 1
    fi

    # 检查关键字段
    echo "$content" | grep -q '"tokenValidateUriBlackList"' || issues+=("缺少 tokenValidateUriBlackList 配置")
    echo "$content" | grep -q '"adminUserIds"' || issues+=("缺少 adminUserIds 配置")
    echo "$content" | grep -q '"lokiConfig"' || issues+=("缺少 lokiConfig 配置")
    echo "$content" | grep -q '"grpcClient"' || issues+=("缺少 grpcClient 配置")

    # 检查 Loki 地址格式
    if echo "$content" | grep -q '"address"[[:space:]]*:[[:space:]]*"YOUR_HOST_IP'; then
        issues+=("Loki 地址未配置，仍为占位符 YOUR_HOST_IP")
    fi

    if [ ${#issues[@]} -gt 0 ]; then
        echo "${issues[@]}"
        return 1
    fi

    return 0
}

# 验证 components.json 配置
validate_components_config() {
    local tenant="$1"
    local content="$2"
    local issues=()

    # 检查 JSON 格式
    if ! echo "$content" | python3 -m json.tool &>/dev/null; then
        issues+=("JSON 格式错误")
        echo "${issues[@]}"
        return 1
    fi

    # 检查是否包含模型组件
    echo "$content" | grep -q '"model_components"' || issues+=("缺少 model_components 配置")

    if [ ${#issues[@]} -gt 0 ]; then
        echo "${issues[@]}"
        return 1
    fi

    return 0
}

# 验证配置内容
validate_config_content() {
    local tenant="$1"
    local config_name="$2"

    if [ "$VALIDATE_CONTENT" != "true" ]; then
        return 0
    fi

    # 获取配置内容
    local content=$(get_config_content "$config_name" "DEFAULT_GROUP" "$tenant")

    if [ -z "$content" ] || [ "$content" = "config data not exist" ]; then
        return 0  # 配置不存在，由 check_config_exists 处理
    fi

    local validation_result=""
    local validation_status=0

    # 根据配置类型调用相应的验证函数
    case "$config_name" in
        "organ_info.json")
            validation_result=$(validate_organ_info "$tenant" "$content")
            validation_status=$?
            ;;
        "database.yaml")
            validation_result=$(validate_database_config "$tenant" "$content")
            validation_status=$?
            ;;
        "redis.yaml")
            validation_result=$(validate_redis_config "$tenant" "$content")
            validation_status=$?
            ;;
        "fusion.yaml")
            validation_result=$(validate_fusion_config "$tenant" "$content")
            validation_status=$?
            ;;
        "base.json")
            validation_result=$(validate_base_config "$tenant" "$content")
            validation_status=$?
            ;;
        "components.json")
            validation_result=$(validate_components_config "$tenant" "$content")
            validation_status=$?
            ;;
        *)
            return 0  # 未知配置类型，跳过验证
            ;;
    esac

    if [ $validation_status -ne 0 ]; then
        echo -e "      ${YELLOW}⚠${NC} 配置验证警告: ${validation_result}"
        VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
        return 1
    fi

    return 0
}

# 获取组织信息
get_organ_info_from_db() {
    local tenant="$1"
    local db_name=""

    case "$tenant" in
        demo0) db_name="privacy1" ;;
        demo1) db_name="privacy2" ;;
        demo2) db_name="privacy3" ;;
    esac

    # 尝试从数据库获取组织信息
    local organ_data=$(docker exec mysql mysql -uprimihub -pprimihub@123 -N -e \
        "SELECT organ_id, organ_name, organ_gateway FROM ${db_name}.sys_organ WHERE enable=1 LIMIT 1;" 2>/dev/null)

    if [ -n "$organ_data" ]; then
        echo "$organ_data"
        return 0
    fi

    return 1
}

# 创建 organ_info.json 配置
create_organ_info_config() {
    local tenant="$1"
    local port=""

    case "$tenant" in
        demo0) port="30811" ;;
        demo1) port="30812" ;;
        demo2) port="30813" ;;
    esac

    log_info "为 ${tenant} 创建 organ_info.json 配置..."

    # 尝试从数据库获取组织信息
    local organ_data=$(get_organ_info_from_db "$tenant")

    local organ_id="000000000000000000000000test0001"
    local organ_name="API测试机构"
    local organ_gateway="http://100.64.0.23:${port}"

    if [ -n "$organ_data" ]; then
        organ_id=$(echo "$organ_data" | awk '{print $1}')
        organ_name=$(echo "$organ_data" | awk '{print $2}')
        organ_gateway=$(echo "$organ_data" | awk '{print $3}')
        log_info "从数据库获取到组织信息: ${organ_name}"
    else
        log_warn "无法从数据库获取组织信息，使用默认值"
    fi

    # 创建 JSON 配置
    local config_content=$(cat <<EOF
{
  "organId": "${organ_id}",
  "organName": "${organ_name}",
  "organGateway": "${organ_gateway}"
}
EOF
)

    # 上传到 Nacos
    local response=$(curl -s -X POST "${NACOS_URL}/nacos/v1/cs/configs" \
        -d "dataId=organ_info.json" \
        -d "group=DEFAULT_GROUP" \
        -d "tenant=${tenant}" \
        -d "type=json" \
        -d "content=${config_content}")

    if [ "$response" = "true" ]; then
        log_success "成功创建 ${tenant}/organ_info.json"
        FIXED_CONFIGS=$((FIXED_CONFIGS + 1))
        return 0
    else
        log_error "创建 ${tenant}/organ_info.json 失败"
        return 1
    fi
}

# 检查单个配置
check_single_config() {
    local tenant="$1"
    local config_name="$2"
    local is_required="$3"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if check_config_exists "$config_name" "DEFAULT_GROUP" "$tenant"; then
        echo -e "    ${GREEN}✓${NC} ${config_name}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))

        # 验证配置内容
        validate_config_content "$tenant" "$config_name"

        return 0
    else
        if [ "$is_required" = "true" ]; then
            echo -e "    ${RED}✗${NC} ${config_name} ${RED}(缺失)${NC}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))

            # 自动修复 organ_info.json
            if [ "$config_name" = "organ_info.json" ] && [ "$AUTO_FIX" = "true" ]; then
                echo -e "    ${YELLOW}↻${NC} 正在自动创建..."
                if create_organ_info_config "$tenant"; then
                    echo -e "    ${GREEN}✓${NC} ${config_name} ${GREEN}(已修复)${NC}"
                    PASSED_CHECKS=$((PASSED_CHECKS + 1))
                    FAILED_CHECKS=$((FAILED_CHECKS - 1))
                    return 0
                fi
            fi
            return 1
        else
            echo -e "    ${YELLOW}○${NC} ${config_name} ${YELLOW}(可选，未配置)${NC}"
            return 0
        fi
    fi
}

# 检查租户配置
check_tenant_configs() {
    local tenant="$1"

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  租户: ${tenant}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local tenant_failed=0

    # 检查必需配置
    echo -e "  ${CYAN}必需配置:${NC}"
    for config in "${REQUIRED_CONFIGS[@]}"; do
        if ! check_single_config "$tenant" "$config" "true"; then
            tenant_failed=$((tenant_failed + 1))
        fi
    done

    # 检查可选配置
    echo -e "  ${CYAN}可选配置:${NC}"
    for config in "${OPTIONAL_CONFIGS[@]}"; do
        check_single_config "$tenant" "$config" "false"
    done

    if [ $tenant_failed -eq 0 ]; then
        echo -e "  ${GREEN}状态: ✓ 所有必需配置完整${NC}"
    else
        echo -e "  ${RED}状态: ✗ 缺少 ${tenant_failed} 个必需配置${NC}"
    fi
}

# 显示配置详情
show_config_details() {
    local tenant="$1"
    local config_name="$2"

    log_info "获取 ${tenant}/${config_name} 配置内容..."

    local content=$(curl -s "${NACOS_URL}/nacos/v1/cs/configs?dataId=${config_name}&group=DEFAULT_GROUP&tenant=${tenant}")

    if [ "$content" != "config data not exist" ] && [ -n "$content" ]; then
        echo "$content" | head -20
        local lines=$(echo "$content" | wc -l)
        if [ $lines -gt 20 ]; then
            echo "... (共 $lines 行，仅显示前 20 行)"
        fi
    else
        log_warn "配置不存在"
    fi
}

# 生成配置报告
generate_report() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                    Nacos 配置检查报告                            ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  检查项总数: ${TOTAL_CHECKS}"
    echo "  通过检查:   ${GREEN}${PASSED_CHECKS}${NC}"
    echo "  失败检查:   ${RED}${FAILED_CHECKS}${NC}"

    if [ $FIXED_CONFIGS -gt 0 ]; then
        echo "  自动修复:   ${YELLOW}${FIXED_CONFIGS}${NC}"
    fi

    if [ "$VALIDATE_CONTENT" = "true" ] && [ $VALIDATION_WARNINGS -gt 0 ]; then
        echo "  配置警告:   ${YELLOW}${VALIDATION_WARNINGS}${NC}"
    fi

    echo ""

    if [ $FAILED_CHECKS -eq 0 ]; then
        if [ $VALIDATION_WARNINGS -gt 0 ]; then
            log_warn "配置检查通过，但发现 ${VALIDATION_WARNINGS} 个配置警告"
            echo ""
            echo "建议操作:"
            echo "  1. 检查上述配置警告信息"
            echo "  2. 访问 Nacos 配置中心修正配置: ${NACOS_URL}/nacos"
            echo "  3. 重新运行检查: $0"
            return 0
        else
            log_success "所有配置检查通过！"
            return 0
        fi
    else
        log_error "发现 ${FAILED_CHECKS} 个配置问题"
        echo ""
        echo "建议操作:"
        echo "  1. 检查 Nacos 配置中心: ${NACOS_URL}/nacos"
        echo "  2. 手动创建缺失的配置文件"
        echo "  3. 或运行: AUTO_FIX=true $0"
        return 1
    fi
}

# =============================================================================
# 主流程
# =============================================================================

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║              Nacos 配置检查工具                                  ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    log_info "Nacos 地址: ${NACOS_URL}"
    log_info "自动修复: ${AUTO_FIX}"
    log_info "内容验证: ${VALIDATE_CONTENT}"
    echo ""

    # 检查 Nacos 可用性
    if ! check_nacos_available; then
        exit 1
    fi

    # 检查所有租户配置
    for tenant in "${TENANTS[@]}"; do
        check_tenant_configs "$tenant"
    done

    # 生成报告
    generate_report

    exit $?
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-fix)
            AUTO_FIX=false
            shift
            ;;
        --no-validate)
            VALIDATE_CONTENT=false
            shift
            ;;
        --nacos-host)
            NACOS_HOST="$2"
            shift 2
            ;;
        --nacos-port)
            NACOS_PORT="$2"
            shift 2
            ;;
        --show-config)
            if [ -n "$2" ] && [ -n "$3" ]; then
                show_config_details "$2" "$3"
                exit 0
            else
                log_error "用法: $0 --show-config <tenant> <config_name>"
                exit 1
            fi
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --no-fix              禁用自动修复"
            echo "  --no-validate         禁用配置内容验证"
            echo "  --nacos-host HOST     指定 Nacos 主机 (默认: localhost)"
            echo "  --nacos-port PORT     指定 Nacos 端口 (默认: 8848)"
            echo "  --show-config TENANT CONFIG  显示指定配置内容"
            echo "  -h, --help            显示帮助信息"
            echo ""
            echo "环境变量:"
            echo "  NACOS_HOST            Nacos 主机地址"
            echo "  NACOS_PORT            Nacos 端口"
            echo "  AUTO_FIX              是否自动修复 (true/false)"
            echo "  VALIDATE_CONTENT      是否验证配置内容 (true/false)"
            echo ""
            echo "示例:"
            echo "  $0                                    # 检查并自动修复"
            echo "  $0 --no-fix                           # 仅检查，不修复"
            echo "  $0 --no-validate                      # 检查但不验证内容"
            echo "  $0 --show-config demo0 organ_info.json  # 查看配置"
            echo ""
            echo "配置验证功能:"
            echo "  - organ_info.json: 验证字段完整性、organId 长度、端口匹配"
            echo "  - database.yaml: 验证数据库名称与租户匹配"
            echo "  - redis.yaml: 验证 Redis database 编号与租户匹配"
            echo "  - fusion.yaml: 验证融合数据库名称与租户匹配"
            echo "  - base.json: 验证关键字段、Loki 地址配置"
            echo "  - components.json: 验证 JSON 格式和模型组件"
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            echo "使用 -h 或 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 运行主流程
main
