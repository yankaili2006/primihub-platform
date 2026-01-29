#!/bin/bash

###############################################################################
# PrimiHub 自动编译脚本
# 功能: 自动编译 primihub-platform 后端和前端
# 用法: ./build.sh [--skip-tests] [--clean]
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认参数
SKIP_TESTS=false
CLEAN_BUILD=false
BUILD_DIR=$(cd "$(dirname "$0")/.." && pwd)

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --skip-tests    跳过单元测试"
            echo "  --clean         清理后重新编译"
            echo "  -h, --help      显示帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 -h 查看帮助"
            exit 1
            ;;
    esac
done

# 打印函数
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "${YELLOW}[步骤] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "  $1"
}

# 错误处理
error_exit() {
    print_error "$1"
    exit 1
}

# 检查必需命令
check_prerequisites() {
    print_header "检查编译前置条件"

    local missing_deps=0

    for cmd in java mvn node npm git; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd 未安装"
            ((missing_deps++))
        else
            local version=$($cmd --version 2>&1 | head -1)
            print_success "$cmd 已安装: $version"
        fi
    done

    if [ $missing_deps -gt 0 ]; then
        error_exit "缺少必需的编译工具，请先安装"
    fi

    # 检查Java版本
    if ! java -version 2>&1 | grep -qE "version \"(1[7-9]|[2-9][0-9])"; then
        error_exit "Java 版本过低，需要 Java 17 或更高版本"
    fi

    print_success "所有前置条件满足"
}

# 清理构建目录
clean_build() {
    if [ "$CLEAN_BUILD" = true ]; then
        print_header "清理构建目录"

        print_step "清理后端构建文件"
        cd "$BUILD_DIR/primihub-service"
        mvn clean || error_exit "Maven clean 失败"
        print_success "后端构建文件已清理"

        print_step "清理前端构建文件"
        cd "$BUILD_DIR/primihub-webconsole"
        rm -rf dist node_modules || true
        print_success "前端构建文件已清理"
    fi
}

# 编译后端
build_backend() {
    print_header "编译后端服务"

    cd "$BUILD_DIR/primihub-service"

    print_step "开始 Maven 编译"
    print_info "目录: $PWD"
    print_info "跳过测试: $SKIP_TESTS"

    local mvn_opts=""
    if [ "$SKIP_TESTS" = true ]; then
        mvn_opts="-DskipTests"
    fi

    # 编译
    if mvn clean package $mvn_opts; then
        print_success "后端编译成功"
    else
        error_exit "后端编译失败"
    fi

    # 检查编译产物
    local jar_file="application/target/application.jar"
    if [ -f "$jar_file" ]; then
        local jar_size=$(du -h "$jar_file" | cut -f1)
        print_success "找到编译产物: $jar_file ($jar_size)"
    else
        error_exit "未找到编译产物: $jar_file"
    fi
}

# 编译前端
build_frontend() {
    print_header "编译前端应用"

    cd "$BUILD_DIR/primihub-webconsole"

    print_step "安装前端依赖"
    print_info "目录: $PWD"

    # 安装依赖
    if [ ! -d "node_modules" ] || [ "$CLEAN_BUILD" = true ]; then
        print_info "正在安装 npm 依赖..."
        if npm install; then
            print_success "npm 依赖安装成功"
        else
            error_exit "npm 依赖安装失败"
        fi
    else
        print_info "node_modules 已存在，跳过安装"
    fi

    # 编译（可选，开发环境使用 npm run serve）
    # 如果需要生产构建，取消注释以下代码
    # print_step "构建生产版本"
    # if npm run build; then
    #     print_success "前端构建成功"
    #     if [ -d "dist" ]; then
    #         print_success "找到构建产物: dist/"
    #     fi
    # else
    #     error_exit "前端构建失败"
    # fi

    print_success "前端依赖安装完成"
    print_info "使用 'npm run serve' 启动开发服务器"
}

# 生成启动脚本
generate_scripts() {
    print_header "生成启动脚本"

    # 后端启动脚本
    local backend_start="$BUILD_DIR/primihub-service/application/start-simple.sh"
    cat > "$backend_start" << 'EOF'
#!/bin/bash

# PrimiHub 后端启动脚本
# 使用H2数据库的简化配置

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
JAR_FILE="$SCRIPT_DIR/target/application.jar"

if [ ! -f "$JAR_FILE" ]; then
    echo "错误: 未找到 $JAR_FILE"
    echo "请先运行编译脚本"
    exit 1
fi

echo "启动 PrimiHub 后端服务..."
echo "日志: /tmp/primihub-backend.log"
echo ""

java -jar "$JAR_FILE" \
    --spring.profiles.active=simple \
    --spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration \
    --server.port=8090 \
    > /tmp/primihub-backend.log 2>&1 &

PID=$!
echo "后端服务已启动，PID: $PID"
echo "访问地址: http://localhost:8090"
echo "API 文档: http://localhost:8090/doc.html"
echo ""
echo "查看日志: tail -f /tmp/primihub-backend.log"
EOF
    chmod +x "$backend_start"
    print_success "后端启动脚本: $backend_start"

    # 前端启动脚本
    local frontend_start="$BUILD_DIR/primihub-webconsole/start.sh"
    cat > "$frontend_start" << 'EOF'
#!/bin/bash

# PrimiHub 前端启动脚本

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

if [ ! -d "node_modules" ]; then
    echo "错误: node_modules 不存在"
    echo "请先运行编译脚本"
    exit 1
fi

echo "启动 PrimiHub 前端服务..."
echo "日志: /tmp/primihub-frontend.log"
echo ""

npm run serve > /tmp/primihub-frontend.log 2>&1 &

PID=$!
echo "前端服务已启动，PID: $PID"
echo "访问地址: http://localhost:8080"
echo "默认账号: admin / admin"
echo ""
echo "查看日志: tail -f /tmp/primihub-frontend.log"
EOF
    chmod +x "$frontend_start"
    print_success "前端启动脚本: $frontend_start"
}

# 显示编译总结
build_summary() {
    print_header "编译总结"

    echo -e "${GREEN}✓ 编译完成！${NC}"
    echo ""
    echo "编译产物:"
    echo "  后端: primihub-service/application/target/application.jar"
    echo "  前端: primihub-webconsole/ (开发模式)"
    echo ""
    echo "启动脚本:"
    echo "  后端: primihub-service/application/start-simple.sh"
    echo "  前端: primihub-webconsole/start.sh"
    echo ""
    echo "下一步:"
    echo "  1. 运行部署脚本: ./scripts/deploy.sh"
    echo "  2. 或手动启动服务:"
    echo "     cd primihub-service/application && ./start-simple.sh"
    echo "     cd primihub-webconsole && ./start.sh"
    echo ""
}

# 主函数
main() {
    print_header "PrimiHub 自动编译"

    echo "开始时间: $(date)"
    echo "构建目录: $BUILD_DIR"
    echo "跳过测试: $SKIP_TESTS"
    echo "清理构建: $CLEAN_BUILD"
    echo ""

    # 检查前置条件
    check_prerequisites

    # 清理（如果需要）
    clean_build

    # 编译后端
    build_backend

    # 编译前端
    build_frontend

    # 生成启动脚本
    generate_scripts

    # 显示总结
    build_summary

    print_success "编译流程完成！"
}

# 捕获错误
trap 'error_exit "编译过程中发生错误"' ERR

# 运行主函数
main "$@"
