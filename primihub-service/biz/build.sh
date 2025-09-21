#!/bin/bash

# PrimiHub Service Biz 模块构建脚本
# 用于构建 primihub-service/biz 模块（业务逻辑库模块）

# 注意: 不使用 set -e，因为我们需要自定义错误处理

echo "开始构建 primihub-service/biz 模块..."

# 检查 Maven 是否安装
check_maven() {
    if ! command -v mvn &> /dev/null; then
        echo "错误: Maven 未安装，请先安装 Maven"
        exit 1
    fi
    echo "✅ Maven 已安装"
}

# 检查 Java 版本
check_java() {
    if ! command -v java &> /dev/null; then
        echo "错误: Java 未安装，请先安装 Java"
        exit 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    echo "✅ 当前 Java 版本: $JAVA_VERSION"
    
    # 检查 Java 版本是否满足要求 (至少 Java 8)
    if [[ "$JAVA_VERSION" < "1.8" ]]; then
        echo "错误: Java 版本需要 1.8 或更高版本"
        exit 1
    fi
}

# 检查 protoc 是否安装（用于 protobuf 编译）
check_protoc() {
    if ! command -v protoc &> /dev/null; then
        echo "⚠️  警告: protoc 未安装，protobuf 编译可能失败"
        echo "建议安装 protoc: brew install protobuf (macOS) 或 apt-get install protobuf-compiler (Ubuntu)"
        return 1
    fi
    
    PROTOC_VERSION=$(protoc --version 2>&1)
    echo "✅ $PROTOC_VERSION"
    return 0
}

# 执行 Maven 构建
build_with_maven() {
    echo ""
    echo "=== 执行 Maven 构建 ==="
    
    # 检查 pom.xml 是否存在
    if [ ! -f "pom.xml" ]; then
        echo "错误: pom.xml 文件不存在"
        exit 1
    fi
    
    echo "执行 Maven clean install..."
    mvn clean install -DskipTests
    
    # 检查构建是否成功
    if [ $? -eq 0 ]; then
        echo "✅ Maven 构建完成"
    else
        echo ""
        echo "⚠️  Maven 构建失败，可能的原因:"
        echo "1. 依赖问题: 检查网络连接和 Maven 仓库配置"
        echo "2. protobuf 编译失败: 确保 protoc 已正确安装"
        echo "3. 其他编译错误: 查看详细错误信息"
        echo ""
        echo "建议解决方案:"
        echo "1. 检查并安装 protoc: brew install protobuf 或 apt-get install protobuf-compiler"
        echo "2. 尝试从项目根目录构建: cd ../.. && ./build.sh"
        echo "3. 查看详细错误信息: mvn clean install -DskipTests -X"
        exit 1
    fi
}

# 检查构建结果
check_build_result() {
    echo ""
    echo "=== 检查构建结果 ==="
    
    local target_dir="target"
    
    if [ ! -d "$target_dir" ]; then
        echo "错误: target 目录不存在，构建可能失败"
        exit 1
    fi
    
    # 查找生成的 jar 文件
    local jar_files=$(find "$target_dir" -name "*.jar" -type f)
    
    if [ -z "$jar_files" ]; then
        echo "错误: 未找到生成的 jar 文件"
        exit 1
    fi
    
    echo "✅ 构建产物:"
    echo "$jar_files"
    
    # 显示主要 jar 文件信息
    local main_jar=$(find "$target_dir" -name "*biz*.jar" -type f | head -n 1)
    if [ -n "$main_jar" ]; then
        echo ""
        echo "主库 jar 文件: $main_jar"
        echo "文件大小: $(du -h "$main_jar" | cut -f1)"
    fi
    
    # 检查 protobuf 生成的文件
    local generated_sources_dir="target/generated-sources"
    if [ -d "$generated_sources_dir" ]; then
        echo ""
        echo "✅ Protobuf 生成文件:"
        find "$generated_sources_dir" -name "*.java" -type f | head -5
        echo "... (更多文件生成)"
    fi
}

# 显示构建配置信息
show_build_info() {
    echo ""
    echo "=== 构建配置信息 ==="
    echo "项目名称: $(mvn help:evaluate -Dexpression=project.name -q -DforceStdout 2>/dev/null || echo 'primihub-service-biz')"
    echo "项目版本: $(mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null || echo '未知')"
    echo "打包方式: $(mvn help:evaluate -Dexpression=project.packaging -q -DforceStdout 2>/dev/null || echo 'jar')"
    echo "模块类型: 业务逻辑库模块"
    
    # 获取依赖信息
    echo "主要依赖: Spring Boot, MyBatis, gRPC, Protobuf, Redis, MySQL"
}

# 清理临时文件（可选）
cleanup() {
    echo ""
    echo "=== 清理临时文件 ==="
    
    # 清理 Maven 临时文件（可选，根据需要开启）
    # mvn clean
    
    echo "✅ 清理完成"
}

# 主构建流程
main() {
    echo "Biz 模块信息:"
    echo "- 模块类型: Java 业务逻辑库"
    echo "- 构建工具: Maven"
    echo "- 特殊功能: Protobuf/gRPC 代码生成"
    echo "- 目标: 生成库 jar 包并安装到本地仓库"
    echo ""
    
    # 检查环境
    check_maven
    check_java
    check_protoc
    
    # 显示构建信息
    show_build_info
    
    # 执行构建
    build_with_maven
    
    # 检查构建结果
    check_build_result
    
    # 清理（可选）
    # cleanup
    
    echo ""
    echo "=== 构建总结 ==="
    echo "✅ primihub-service/biz 模块构建成功完成！"
    echo "✅ 构建产物已生成到 target/ 目录"
    echo "✅ 库已安装到本地 Maven 仓库"
    echo ""
    echo "此模块作为库模块，主要用于:"
    echo "1. 为 application 模块提供业务逻辑支持"
    echo "2. 包含数据库访问、gRPC 服务等核心功能"
    echo "3. 提供 Protobuf 消息定义和 gRPC 服务实现"
}

# 执行主函数
main "$@"
