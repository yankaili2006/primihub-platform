#!/bin/bash

# Primihub Service 项目构建脚本
# 用于构建 primihub-service 项目（包含 Java 和 Python 模块）

set -e  # 遇到错误立即退出

echo "开始构建 primihub-service 项目..."

# 检查并构建 Java Maven 模块
build_java_modules() {
    echo "=== 构建 Java Maven 模块 ==="
    
    # 检查 Maven 是否安装
    if ! command -v mvn &> /dev/null; then
        echo "错误: Maven 未安装，请先安装 Maven"
        exit 1
    fi

    # 检查 Java 版本
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    echo "当前 Java 版本: $JAVA_VERSION"

    # 执行 Maven 构建
    echo "执行 Maven clean package..."
    mvn clean package -DskipTests

    echo "Java 模块构建完成!"
    echo "构建产物位于:"
    find . -name "*.jar" -type f

    # 显示构建结果
    echo ""
    echo "=== Java 构建结果 ==="
    ls -la application/target/ 2>/dev/null || echo "application/target/ 目录不存在"
    ls -la gateway/target/ 2>/dev/null || echo "gateway/target/ 目录不存在"
    ls -la biz/target/ 2>/dev/null || echo "biz/target/ 目录不存在"
}

# 检查并构建 Python Flask 模块
build_python_modules() {
    echo ""
    echo "=== 构建 Python Flask 模块 ==="
    
    local python_dir="yfl/fl"
    
    if [ ! -d "$python_dir" ]; then
        echo "Python 项目目录 $python_dir 不存在，跳过 Python 构建"
        return 0
    fi

    # 检查 Python 是否安装
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        echo "警告: Python 未安装，跳过 Python 构建"
        return 0
    fi

    # 检查 pip 是否安装
    if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
        echo "警告: pip 未安装，跳过 Python 依赖安装"
        return 0
    fi

    # 获取 Python 版本
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        echo "当前 Python 版本: $PYTHON_VERSION"
        PYTHON_CMD="python3"
        PIP_CMD="pip3"
    elif command -v python &> /dev/null; then
        PYTHON_VERSION=$(python --version 2>&1)
        echo "当前 Python 版本: $PYTHON_VERSION"
        PYTHON_CMD="python"
        PIP_CMD="pip"
    fi

    # 进入 Python 项目目录
    cd "$python_dir"
    
    # 检查 requirements.txt 是否存在
    if [ ! -f "requirements.txt" ]; then
        echo "requirements.txt 不存在，跳过 Python 依赖安装"
        cd - > /dev/null
        return 0
    fi

    # 安装 Python 依赖
    echo "安装 Python 依赖..."
    $PIP_CMD install -r requirements.txt

    echo "Python 依赖安装完成!"

    # 返回原目录
    cd - > /dev/null
}

# 主构建流程
main() {
    echo "项目结构检测:"
    echo "- Java Maven 模块: application/, biz/, gateway/"
    echo "- Python Flask 模块: yfl/fl/"
    echo ""

    # 构建 Java 模块
    build_java_modules
    
    # 构建 Python 模块
    build_python_modules

    echo ""
    echo "=== 构建总结 ==="
    echo "✅ Java Maven 模块构建完成"
    echo "✅ Python 依赖安装完成"
    echo ""
    echo "所有模块构建成功完成！"
}

# 执行主函数
main
