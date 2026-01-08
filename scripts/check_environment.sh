#!/bin/bash

###############################################################################
# PrimiHub 环境检查脚本
# 功能: 检查服务器环境是否满足 PrimiHub 部署要求
# 用法: ./check_environment.sh
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 结果统计
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# 打印函数
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_check() {
    echo -e "${YELLOW}检查: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASS_COUNT++))
}

print_fail() {
    echo -e "${RED}✗ $1${NC}"
    ((FAIL_COUNT++))
}

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARN_COUNT++))
}

print_info() {
    echo -e "  $1"
}

# 检查命令是否存在
check_command() {
    local cmd=$1
    local name=$2
    local required=$3
    local min_version=$4

    print_check "检查 $name"

    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        print_pass "$name 已安装"
        print_info "版本: $version"

        if [ -n "$min_version" ]; then
            print_info "最低要求: $min_version"
        fi
        return 0
    else
        if [ "$required" = "true" ]; then
            print_fail "$name 未安装 (必需)"
            print_info "安装命令: 参见文档"
        else
            print_warn "$name 未安装 (可选)"
        fi
        return 1
    fi
}

# 检查磁盘空间
check_disk_space() {
    print_check "检查磁盘空间"

    local available=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    local used_percent=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    print_info "根分区可用空间: ${available}GB"
    print_info "使用率: ${used_percent}%"

    if [ "$available" -ge 10 ]; then
        print_pass "磁盘空间充足 (≥10GB可用)"
    elif [ "$available" -ge 5 ]; then
        print_warn "磁盘空间较少 (${available}GB), 建议至少10GB"
    else
        print_fail "磁盘空间不足 (${available}GB), 需要至少10GB"
    fi
}

# 检查内存
check_memory() {
    print_check "检查内存"

    local total_mem=$(free -g | awk '/^Mem:/{print $2}')
    local available_mem=$(free -g | awk '/^Mem:/{print $7}')

    print_info "总内存: ${total_mem}GB"
    print_info "可用内存: ${available_mem}GB"

    if [ "$total_mem" -ge 8 ]; then
        print_pass "内存充足 (≥8GB)"
    elif [ "$total_mem" -ge 4 ]; then
        print_warn "内存较少 (${total_mem}GB), 建议至少8GB用于生产环境"
    else
        print_fail "内存不足 (${total_mem}GB), 需要至少4GB"
    fi
}

# 检查端口占用
check_port() {
    local port=$1
    local name=$2

    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        print_warn "端口 $port ($name) 已被占用"
        print_info "$(netstat -tuln | grep ":$port ")"
        return 1
    else
        print_pass "端口 $port ($name) 可用"
        return 0
    fi
}

check_ports() {
    print_check "检查端口可用性"

    check_port 8080 "前端"
    check_port 8090 "后端"
    check_port 7977 "Meta Service 0"
    check_port 7978 "Meta Service 1"
    check_port 7979 "Meta Service 2"
    check_port 50050 "计算节点 0"
    check_port 50051 "计算节点 1"
    check_port 50052 "计算节点 2"
}

# 检查Python环境
check_python_env() {
    print_check "检查 Python 环境"

    if command -v python3 &> /dev/null; then
        local py_version=$(python3 --version 2>&1 | awk '{print $2}')
        local py_major=$(echo $py_version | cut -d. -f1)
        local py_minor=$(echo $py_version | cut -d. -f2)

        print_info "Python 版本: $py_version"

        if [ "$py_major" -eq 3 ] && [ "$py_minor" -ge 10 ] && [ "$py_minor" -le 12 ]; then
            print_pass "Python 版本符合要求 (3.10-3.12)"
        else
            print_warn "Python 版本 $py_version, 推荐 3.10-3.12"
        fi

        # 检查关键Python包
        print_info "\n检查 Python 包:"

        for pkg in torch sklearn loguru phe opacus numpy pandas; do
            if python3 -c "import $pkg" 2>/dev/null; then
                local ver=$(python3 -c "import $pkg; print($pkg.__version__)" 2>/dev/null || echo "unknown")
                print_info "  ✓ $pkg ($ver)"
            else
                print_info "  ✗ $pkg (未安装)"
            fi
        done

    else
        print_fail "Python3 未安装"
    fi
}

# 检查Java环境
check_java_env() {
    print_check "检查 Java 环境"

    if command -v java &> /dev/null; then
        local java_version=$(java -version 2>&1 | head -1 | awk -F '"' '{print $2}')
        print_info "Java 版本: $java_version"

        if java -version 2>&1 | grep -q "version \"17"; then
            print_pass "Java 17 已安装"
        elif java -version 2>&1 | grep -qE "version \"(1[8-9]|[2-9][0-9])"; then
            print_pass "Java 版本 $java_version 可用"
        else
            print_warn "Java 版本较旧: $java_version, 建议使用 Java 17+"
        fi

        # 检查 JAVA_HOME
        if [ -n "$JAVA_HOME" ]; then
            print_info "JAVA_HOME: $JAVA_HOME"
        else
            print_warn "JAVA_HOME 未设置"
        fi
    else
        print_fail "Java 未安装"
    fi
}

# 检查Node.js环境
check_node_env() {
    print_check "检查 Node.js 环境"

    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        local node_major=$(echo $node_version | sed 's/v//' | cut -d. -f1)

        print_info "Node.js 版本: $node_version"

        if [ "$node_major" -ge 16 ]; then
            print_pass "Node.js 版本符合要求 (≥16)"
        else
            print_warn "Node.js 版本较旧: $node_version, 建议 ≥16"
        fi

        if command -v npm &> /dev/null; then
            local npm_version=$(npm --version)
            print_info "npm 版本: $npm_version"
        fi
    else
        print_fail "Node.js 未安装"
    fi
}

# 检查网络连接
check_network() {
    print_check "检查网络连接"

    # 检查是否能访问PyPI
    if curl -s --connect-timeout 5 https://pypi.org > /dev/null; then
        print_pass "可以访问 PyPI (Python 包源)"
    else
        print_warn "无法访问 PyPI, 可能需要配置镜像源"
    fi

    # 检查是否能访问Maven中央仓库
    if curl -s --connect-timeout 5 https://repo.maven.apache.org/maven2/ > /dev/null; then
        print_pass "可以访问 Maven 中央仓库"
    else
        print_warn "无法访问 Maven 中央仓库, 可能需要配置镜像"
    fi
}

# 主函数
main() {
    print_header "PrimiHub 环境检查"

    echo "检查时间: $(date)"
    echo "主机名: $(hostname)"
    echo "操作系统: $(uname -s) $(uname -r)"
    echo ""

    # 系统资源检查
    print_header "1. 系统资源检查"
    check_disk_space
    check_memory
    check_ports

    # 必需软件检查
    print_header "2. 必需软件检查"
    check_command "java" "Java" "true" "17+"
    check_command "python3" "Python3" "true" "3.10-3.12"
    check_command "node" "Node.js" "true" "16+"
    check_command "npm" "npm" "true" ""
    check_command "mvn" "Maven" "true" "3.6+"
    check_command "git" "Git" "true" ""

    # 可选软件检查
    print_header "3. 可选软件检查"
    check_command "docker" "Docker" "false" ""
    check_command "docker-compose" "Docker Compose" "false" ""

    # 详细环境检查
    print_header "4. 详细环境检查"
    check_java_env
    check_python_env
    check_node_env

    # 网络检查
    print_header "5. 网络连接检查"
    check_network

    # 总结
    print_header "检查总结"

    echo -e "${GREEN}通过: $PASS_COUNT${NC}"
    echo -e "${YELLOW}警告: $WARN_COUNT${NC}"
    echo -e "${RED}失败: $FAIL_COUNT${NC}"
    echo ""

    if [ $FAIL_COUNT -eq 0 ]; then
        echo -e "${GREEN}✓ 环境检查通过，可以部署 PrimiHub${NC}"
        exit 0
    else
        echo -e "${RED}✗ 环境检查未通过，请解决上述问题后重试${NC}"
        echo ""
        echo "建议操作:"
        echo "1. 查看 DEPLOYMENT.md 了解详细部署要求"
        echo "2. 安装缺失的软件包"
        echo "3. 配置正确的环境变量"
        echo "4. 重新运行此脚本验证"
        exit 1
    fi
}

# 运行主函数
main "$@"
