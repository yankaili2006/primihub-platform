#!/bin/bash

###############################################################################
# PrimiHub 自动部署脚本
# 功能: 自动部署所有 PrimiHub 组件
# 用法: ./deploy.sh [--mode MODE] [--skip-python]
# MODE: minimal (默认) | full
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认参数
DEPLOY_MODE="minimal"
SKIP_PYTHON=false
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
PRIMIHUB_DIR=""
PRIMIHUB_META_DIR=""

# PID文件目录
PID_DIR="/tmp/primihub"
mkdir -p "$PID_DIR"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --mode)
            DEPLOY_MODE="$2"
            shift 2
            ;;
        --skip-python)
            SKIP_PYTHON=true
            shift
            ;;
        --primihub-dir)
            PRIMIHUB_DIR="$2"
            shift 2
            ;;
        --meta-dir)
            PRIMIHUB_META_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --mode MODE         部署模式: minimal (默认) 或 full"
            echo "  --skip-python       跳过 Python 环境配置"
            echo "  --primihub-dir DIR  primihub 计算节点目录"
            echo "  --meta-dir DIR      primihub-meta 目录"
            echo "  -h, --help          显示帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 打印函数
# 磁盘空间检查
check_disk_space() {
    local avail=$(df / | tail -1 | awk '{print $4}')
    local avail_gb=$((avail / 1024 / 1024))
    print_step "磁盘空间检查: ${avail_gb}GB 可用"
    if [ "$avail_gb" -lt 10 ]; then
        print_warn "磁盘空间不足 10GB，部署可能失败"
        print_info "建议: qm resize <VMID> scsi0 30G 后 growpart + resize2fs"
    fi
}

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

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error_exit() {
    print_error "$1"
    exit 1
}

# 自动检测primihub目录
detect_primihub_dirs() {
    print_step "检测 PrimiHub 相关目录"

    # 检测 primihub 目录
    if [ -z "$PRIMIHUB_DIR" ]; then
        if [ -d "$HOME/github/primihub" ]; then
            PRIMIHUB_DIR="$HOME/github/primihub"
        elif [ -d "/opt/primihub" ]; then
            PRIMIHUB_DIR="/opt/primihub"
        elif [ -d "./primihub" ]; then
            PRIMIHUB_DIR="$(cd ./primihub && pwd)"
        fi
    fi

    if [ -n "$PRIMIHUB_DIR" ] && [ -d "$PRIMIHUB_DIR" ]; then
        print_success "primihub 目录: $PRIMIHUB_DIR"
    else
        print_warn "未找到 primihub 目录，将跳过计算节点部署"
    fi

    # 检测 primihub-meta 目录
    if [ -z "$PRIMIHUB_META_DIR" ]; then
        if [ -d "$HOME/github/primihub-meta" ]; then
            PRIMIHUB_META_DIR="$HOME/github/primihub-meta"
        elif [ -d "/opt/primihub-meta" ]; then
            PRIMIHUB_META_DIR="/opt/primihub-meta"
        elif [ -d "./primihub-meta" ]; then
            PRIMIHUB_META_DIR="$(cd ./primihub-meta && pwd)"
        fi
    fi

    if [ -n "$PRIMIHUB_META_DIR" ] && [ -d "$PRIMIHUB_META_DIR" ]; then
        print_success "primihub-meta 目录: $PRIMIHUB_META_DIR"
    else
        print_warn "未找到 primihub-meta 目录，将跳过 Meta Service 部署"
    fi
}

# 配置Python环境
setup_python_env() {
    if [ "$SKIP_PYTHON" = true ] || [ -z "$PRIMIHUB_DIR" ]; then
        return 0
    fi

    print_header "配置 Python 环境"

    cd "$PRIMIHUB_DIR"

    print_step "检查虚拟环境"
    if [ ! -d "venv" ]; then
        print_info "创建虚拟环境..."
        python3 -m venv venv || error_exit "创建虚拟环境失败"
        print_success "虚拟环境已创建"
    else
        print_info "虚拟环境已存在"
    fi

    print_step "安装 Python 依赖"

    source venv/bin/activate

    # 检查torch版本
    local torch_version=$(python -c "import torch; print(torch.__version__)" 2>/dev/null || echo "")

    if [[ "$torch_version" == "2.6.0"* ]]; then
        print_success "torch 2.6.0 已安装，跳过"
    else
        print_info "安装 PyTorch 2.6.0+cpu..."
        pip install --no-cache-dir \
            torch==2.6.0+cpu \
            torchvision==0.21.0+cpu \
            --index-url https://download.pytorch.org/whl/cpu \
            || error_exit "PyTorch 安装失败"
        print_success "PyTorch 已安装"
    fi

    # 安装其他依赖
    print_info "安装其他 Python 依赖..."
    pip install --no-cache-dir \
        loguru \
        scikit-learn \
        phe \
        opacus \
        numpy \
        pandas \
        grpcio \
        protobuf \
        || error_exit "Python 依赖安装失败"

    # 验证安装
    print_step "验证 Python 依赖"
    python -c "
import torch, sklearn, loguru, phe, opacus
print('✓ 所有依赖已安装')
print(f'  torch: {torch.__version__}')
print(f'  sklearn: {sklearn.__version__}')
print(f'  torch.nn.RMSNorm: {hasattr(torch.nn, \"RMSNorm\")}')
" || error_exit "Python 依赖验证失败"

    deactivate
    print_success "Python 环境配置完成"
}

# 启动后端服务
start_backend() {
    print_header "启动后端服务"

    cd "$BASE_DIR/primihub-service/application"

    local jar_file="target/application.jar"
    if [ ! -f "$jar_file" ]; then
        error_exit "未找到 $jar_file，请先运行编译脚本"
    fi

    print_step "启动 Spring Boot 应用"

    # 停止旧进程
    if [ -f "$PID_DIR/backend.pid" ]; then
        local old_pid=$(cat "$PID_DIR/backend.pid")
        if kill -0 "$old_pid" 2>/dev/null; then
            print_info "停止旧进程 (PID: $old_pid)..."
            kill "$old_pid"
            sleep 2
        fi
    fi

    # 启动新进程
    nohup java -jar "$jar_file" \
        --spring.profiles.active=simple \
        --spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration \
        --server.port=8090 \
        > /tmp/primihub-backend.log 2>&1 &

    local pid=$!
    echo $pid > "$PID_DIR/backend.pid"

    # 等待启动
    print_info "等待服务启动..."
    local max_wait=30
    local count=0

    while [ $count -lt $max_wait ]; do
        if curl -s http://localhost:8090/actuator/health > /dev/null 2>&1; then
            print_success "后端服务已启动 (PID: $pid)"
            print_info "访问地址: http://localhost:8090"
            print_info "API 文档: http://localhost:8090/doc.html"
            return 0
        fi
        sleep 1
        ((count++))
    done

    error_exit "后端服务启动超时"
}

# 启动前端服务
start_frontend() {
    print_header "启动前端服务"

    cd "$BASE_DIR/primihub-webconsole"

    if [ ! -d "node_modules" ]; then
        error_exit "node_modules 不存在，请先运行编译脚本"
    fi

    print_step "启动 Vue.js 开发服务器"

    # 停止旧进程
    if [ -f "$PID_DIR/frontend.pid" ]; then
        local old_pid=$(cat "$PID_DIR/frontend.pid")
        if kill -0 "$old_pid" 2>/dev/null; then
            print_info "停止旧进程 (PID: $old_pid)..."
            kill "$old_pid"
            sleep 2
        fi
    fi

    # 启动新进程
    nohup npm run serve > /tmp/primihub-frontend.log 2>&1 &

    local pid=$!
    echo $pid > "$PID_DIR/frontend.pid"

    # 等待启动
    print_info "等待服务启动..."
    local max_wait=60
    local count=0

    while [ $count -lt $max_wait ]; do
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            print_success "前端服务已启动 (PID: $pid)"
            print_info "访问地址: http://localhost:8080"
            print_info "默认账号: admin / admin"
            return 0
        fi
        sleep 1
        ((count++))
    done

    print_warn "前端服务可能仍在启动中"
    print_info "查看日志: tail -f /tmp/primihub-frontend.log"
}

# 启动Meta Service
start_meta_service() {
    if [ -z "$PRIMIHUB_META_DIR" ]; then
        print_warn "跳过 Meta Service (目录未找到)"
        return 0
    fi

    print_header "启动 Meta Service"

    cd "$PRIMIHUB_META_DIR"

    local jar_file="fusion-simple.jar"
    if [ ! -f "$jar_file" ]; then
        print_warn "未找到 $jar_file，跳过 Meta Service"
        return 0
    fi

    # 启动3个Meta Service节点
    for i in 0 1 2; do
        local http_port=$((7977 + i))
        local grpc_port=$((9090 + i))
        local pid_file="$PID_DIR/meta$i.pid"

        print_step "启动 Meta Service 节点 $i"

        # 停止旧进程
        if [ -f "$pid_file" ]; then
            local old_pid=$(cat "$pid_file")
            if kill -0 "$old_pid" 2>/dev/null; then
                print_info "停止旧进程 (PID: $old_pid)..."
                kill "$old_pid"
            fi
        fi

        # 启动新进程
        nohup java -jar "$jar_file" \
            --server.port=$http_port \
            --grpc.server.port=$grpc_port \
            > "/tmp/primihub-meta$i.log" 2>&1 &

        local pid=$!
        echo $pid > "$pid_file"

        # 等待启动
        sleep 3
        if curl -s "http://localhost:$http_port/health" > /dev/null 2>&1; then
            print_success "Meta Service 节点 $i 已启动 (PID: $pid, HTTP: $http_port, gRPC: $grpc_port)"
        else
            print_warn "Meta Service 节点 $i 可能启动失败"
        fi
    done
}

# 检查计算节点
check_compute_nodes() {
    if [ -z "$PRIMIHUB_DIR" ]; then
        print_warn "跳过计算节点检查 (目录未找到)"
        return 0
    fi

    print_header "检查计算节点"

    local node_count=$(ps aux | grep "bazel-bin/node" | grep -v grep | wc -l)

    if [ $node_count -ge 3 ]; then
        print_success "计算节点已运行 ($node_count 个)"
    else
        print_warn "计算节点未运行或数量不足 ($node_count/3)"
        print_info "请手动启动计算节点或检查 primihub 安装"
    fi
}

# 部署总结
deployment_summary() {
    print_header "部署总结"

    echo -e "${GREEN}✓ 部署完成！${NC}"
    echo ""
    echo "运行中的服务:"
    echo ""

    # 检查后端
    if curl -s http://localhost:8090/actuator/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 后端服务: http://localhost:8090"
    else
        echo -e "  ${RED}✗${NC} 后端服务未运行"
    fi

    # 检查前端
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 前端服务: http://localhost:8080"
    else
        echo -e "  ${YELLOW}⚠${NC} 前端服务可能仍在启动"
    fi

    # 检查Meta Service
    for i in 0 1 2; do
        local port=$((7977 + i))
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} Meta Service $i: http://localhost:$port"
        else
            echo -e "  ${YELLOW}⚠${NC} Meta Service $i 未运行"
        fi
    done

    # 检查计算节点
    local node_count=$(ps aux | grep "bazel-bin/node" | grep -v grep | wc -l)
    if [ $node_count -ge 3 ]; then
        echo -e "  ${GREEN}✓${NC} 计算节点: $node_count 个运行中"
    else
        echo -e "  ${YELLOW}⚠${NC} 计算节点: $node_count 个运行中 (建议3个)"
    fi

    echo ""
    echo "日志文件:"
    echo "  后端: /tmp/primihub-backend.log"
    echo "  前端: /tmp/primihub-frontend.log"
    echo "  Meta: /tmp/primihub-meta{0,1,2}.log"
    echo ""
    echo "PID 文件: $PID_DIR/"
    echo ""
    echo "下一步:"
    echo "  1. 访问前端: http://localhost:8080 (admin/admin)"
    echo "  2. 运行测试: ./scripts/test.sh"
    echo "  3. 查看日志: tail -f /tmp/primihub-*.log"
    echo ""
}

# 主函数
main() {
    print_header "PrimiHub 自动部署"

    echo "开始时间: $(date)"
    echo "部署模式: $DEPLOY_MODE"
    echo "基础目录: $BASE_DIR"
    echo ""

    # 检查磁盘空间
    check_disk_space

    # 检测目录
    detect_primihub_dirs

    # 配置Python环境
    setup_python_env

    # 启动服务
    start_backend
    start_frontend
    start_meta_service

    # 检查计算节点
    check_compute_nodes

    # 显示总结
    deployment_summary

    # 修复缺失的前端路由权限
    print_header "修复前端路由权限"
    FIX_SQL="$BASE_DIR/fix_missing_auth_entries.sql"
    if [ -f "$FIX_SQL" ] && command -v mysql &>/dev/null; then
        print_step "应用权限修复SQL..."
        MYSQL_USER="${MYSQL_USER:-root}"
        MYSQL_PASS="${MYSQL_PASS:-}"
        mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" privacy < "$FIX_SQL" 2>/dev/null && \
            print_success "权限修复完成" || \
            print_warn "权限修复失败，可手动执行: mysql -uroot privacy < $FIX_SQL"
    else
        print_info "跳过权限修复（SQL文件不存在或MySQL客户端未安装）"
    fi

    # 执行自动化验证
    print_header "执行自动化验证"
    if [ -f "$BASE_DIR/deploy_verify.py" ]; then
        print_step "运行快速测试（路由+API）..."
        python3 "$BASE_DIR/deploy_verify.py" 2>&1 | tail -15
        print_success "验证完成"
    else
        print_info "跳过验证（未找到 deploy_verify.py）"
    fi

    print_success "部署流程完成！"
}

# 捕获错误
trap 'error_exit "部署过程中发生错误"' ERR

# 运行主函数
main "$@"
