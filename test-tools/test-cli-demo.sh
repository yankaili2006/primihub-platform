#!/bin/bash
# PrimiHub CLI 演示脚本
# 演示如何使用 primihub-cli.py 测试 API 接口

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         PrimiHub CLI 演示脚本                                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 服务器地址
SERVERS=(
    "http://10.12.0.12:30811:机构0"
    "http://10.12.0.12:30812:机构1"
    "http://10.12.0.12:30813:机构2"
)

# 测试单个服务器
test_server() {
    local url=$1
    local name=$2

    echo -e "\n${YELLOW}=== 测试 $name ($url) ===${NC}"

    echo -e "\n${GREEN}1. 健康检查${NC}"
    python3 primihub-cli.py --url "$url" health || true

    echo -e "\n${GREEN}2. 登录测试${NC}"
    python3 primihub-cli.py --url "$url" login || true

    echo -e "\n${GREEN}3. 查看机构列表（前3个）${NC}"
    python3 primihub-cli.py --url "$url" organs --size 3 || true

    echo -e "\n${GREEN}4. 查看项目列表（前3个）${NC}"
    python3 primihub-cli.py --url "$url" projects --size 3 || true

    echo ""
    echo "按 Enter 继续..."
    read -r
}

# 主函数
main() {
    echo "本脚本将演示 PrimiHub CLI 工具的基本使用方法"
    echo ""

    # 检查 CLI 工具是否存在
    if [ ! -f "primihub-cli.py" ]; then
        echo -e "${YELLOW}错误: 找不到 primihub-cli.py${NC}"
        echo "请确保在正确的目录中运行此脚本"
        exit 1
    fi

    # 检查 Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}错误: 未找到 python3${NC}"
        exit 1
    fi

    # 检查 requests 库
    if ! python3 -c "import requests" 2>/dev/null; then
        echo -e "${YELLOW}警告: 未安装 requests 库${NC}"
        echo "正在安装..."
        pip3 install requests
    fi

    echo ""
    echo "选择测试模式:"
    echo "  1) 完整测试（测试所有3个机构）"
    echo "  2) 快速测试（仅测试机构0）"
    echo "  3) 全接口测试（运行 test-all）"
    echo "  4) 自定义服务器地址"
    echo ""
    read -p "请选择 [1-4]: " choice

    case $choice in
        1)
            echo -e "\n${BLUE}开始完整测试...${NC}"
            for server_info in "${SERVERS[@]}"; do
                IFS=':' read -r url name <<< "$server_info"
                test_server "$url" "$name"
            done
            ;;
        2)
            echo -e "\n${BLUE}开始快速测试...${NC}"
            test_server "http://10.12.0.12:30811" "机构0"
            ;;
        3)
            echo -e "\n${BLUE}运行全接口测试...${NC}"
            python3 primihub-cli.py test-all
            ;;
        4)
            read -p "请输入服务器地址 (例如: http://10.12.0.12:30811): " custom_url
            read -p "请输入服务器名称 (例如: 测试服务器): " custom_name
            test_server "$custom_url" "$custom_name"
            ;;
        *)
            echo -e "${YELLOW}无效选择${NC}"
            exit 1
            ;;
    esac

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         测试完成！                                               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "更多使用方法请参考: PRIMIHUB_CLI_README.md"
}

# 运行主函数
main
