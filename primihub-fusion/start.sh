#!/bin/bash

# PrimiHub Fusion 启动脚本
# 用于启动 primihub-fusion 应用

set -e  # 遇到错误立即退出

# 默认配置
DEFAULT_PORT=8099
DEFAULT_JAR_PATTERN="fusion-api-*.jar"
APP_NAME="primihub-fusion"

# 显示使用说明
usage() {
    echo "使用方法: $0 [选项]"
    echo "选项:"
    echo "  -p, --port PORT          指定服务端口 (默认: $DEFAULT_PORT)"
    echo "  -j, --jar JAR_FILE       指定要运行的 JAR 文件"
    echo "  -b, --build              构建项目后再启动"
    echo "  -d, --daemon             以守护进程方式运行"
    echo "  -h, --help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                         # 使用默认配置启动"
    echo "  $0 -p 8080                 # 在端口 8080 启动"
    echo "  $0 -b                      # 构建项目后启动"
    echo "  $0 -d                      # 以守护进程方式运行"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -j|--jar)
                JAR_FILE="$2"
                shift 2
                ;;
            -b|--build)
                BUILD=true
                shift
                ;;
            -d|--daemon)
                DAEMON=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "错误: 未知选项 $1"
                usage
                exit 1
                ;;
        esac
    done
}

# 检查 Java 是否安装
check_java() {
    if ! command -v java &> /dev/null; then
        echo "错误: Java 未安装，请先安装 Java 1.8+"
        exit 1
    fi
    
    # 检查 Java 版本
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    echo "当前 Java 版本: $JAVA_VERSION"
    
    # 验证 Java 版本是否 >= 1.8
    if [[ "$JAVA_VERSION" < "1.8" ]]; then
        echo "错误: Java 版本需要 1.8 或更高版本"
        exit 1
    fi
}

# 构建项目
build_project() {
    echo "开始构建项目..."
    
    # 检查 Maven 是否安装
    if ! command -v mvn &> /dev/null; then
        echo "错误: Maven 未安装，请先安装 Maven"
        exit 1
    fi
    
    # 执行 Maven 构建
    mvn clean package -DskipTests
    
    if [[ $? -eq 0 ]]; then
        echo "构建成功!"
    else
        echo "错误: 构建失败"
        exit 1
    fi
}

# 查找 JAR 文件
find_jar() {
    local jar_pattern="${1:-$DEFAULT_JAR_PATTERN}"
    local jar_file=$(find fusion-api/target -name "$jar_pattern" -type f 2>/dev/null | head -n 1)
    
    if [[ -z "$jar_file" ]]; then
        echo "错误: 未找到 JAR 文件，请先运行构建命令"
        echo "提示: 运行 ./build.sh 或使用 -b 选项自动构建"
        exit 1
    fi
    
    echo "$jar_file"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        echo "错误: 端口 $port 已被占用"
        exit 1
    fi
}

# 启动应用
start_application() {
    local jar_file=$1
    local port=$2
    local daemon=$3
    
    echo "启动 $APP_NAME 应用..."
    echo "JAR 文件: $jar_file"
    echo "服务端口: $port"
    
    # 检查端口是否被占用
    check_port $port
    
    # 准备启动命令
    local java_cmd="java -jar -Dfile.encoding=UTF-8 -Dserver.port=$port $jar_file"
    
    if [[ "$daemon" == "true" ]]; then
        echo "以守护进程方式运行..."
        nohup $java_cmd > fusion.log 2>&1 &
        local pid=$!
        echo "应用已启动，PID: $pid"
        echo "日志文件: fusion.log"
    else
        echo "启动命令: $java_cmd"
        echo "按 Ctrl+C 停止应用"
        echo ""
        $java_cmd
    fi
}

# 主函数
main() {
    # 设置默认值
    PORT="${PORT:-$DEFAULT_PORT}"
    BUILD=${BUILD:-false}
    DAEMON=${DAEMON:-false}
    
    # 解析参数
    parse_args "$@"
    
    echo "=== PrimiHub Fusion 启动脚本 ==="
    echo ""
    
    # 检查 Java
    check_java
    
    # 如果需要构建，先构建项目
    if [[ "$BUILD" == "true" ]]; then
        build_project
    fi
    
    # 查找或指定 JAR 文件
    if [[ -z "$JAR_FILE" ]]; then
        JAR_FILE=$(find_jar)
    else
        if [[ ! -f "$JAR_FILE" ]]; then
            echo "错误: 指定的 JAR 文件不存在: $JAR_FILE"
            exit 1
        fi
    fi
    
    echo "使用 JAR 文件: $JAR_FILE"
    
    # 启动应用
    start_application "$JAR_FILE" "$PORT" "$DAEMON"
}

# 执行主函数
main "$@"
