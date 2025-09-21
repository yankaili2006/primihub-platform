#!/bin/bash

# PrimiHub Service Application 模块构建脚本
# 用于构建 primihub-service/application 模块

# 注意: 不使用 set -e，因为我们需要自定义错误处理

echo "开始构建 primihub-service/application 模块..."

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

# 执行 Maven 构建
build_with_maven() {
    echo ""
    echo "=== 执行 Maven 构建 ==="
    
    # 检查 pom.xml 是否存在
    if [ ! -f "pom.xml" ]; then
        echo "错误: pom.xml 文件不存在"
        exit 1
    fi
    
    echo "执行 Maven clean package..."
    mvn clean package -DskipTests
    
    # 检查构建是否成功
    if [ $? -eq 0 ]; then
        echo "✅ Maven 构建完成"
    else
        echo ""
        echo "⚠️  Maven 构建失败，可能的原因:"
        echo "1. 依赖模块未构建: application 模块依赖于 biz 模块"
        echo "2. 需要先构建整个项目或构建依赖模块"
        echo ""
        echo "建议解决方案:"
        echo "1. 从项目根目录构建整个项目: cd ../.. && ./build.sh"
        echo "2. 或者先构建 biz 模块: cd ../biz && mvn clean install -DskipTests"
        echo "3. 然后重新运行此构建脚本"
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
    local main_jar=$(find "$target_dir" -name "*application*.jar" -type f | head -n 1)
    if [ -n "$main_jar" ]; then
        echo ""
        echo "主应用 jar 文件: $main_jar"
        echo "文件大小: $(du -h "$main_jar" | cut -f1)"
    fi
}

# 显示构建配置信息
show_build_info() {
    echo ""
    echo "=== 构建配置信息 ==="
    echo "项目名称: $(mvn help:evaluate -Dexpression=project.name -q -DforceStdout 2>/dev/null || echo '未知')"
    echo "项目版本: $(mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null || echo '未知')"
    echo "打包方式: $(mvn help:evaluate -Dexpression=project.packaging -q -DforceStdout 2>/dev/null || echo '未知')"
    
    # 获取主类信息
    local main_class=$(mvn help:evaluate -Dexpression=start-class -q -DforceStdout 2>/dev/null || \
                      mvn help:evaluate -Dexpression=spring-boot.run.main-class -q -DforceStdout 2>/dev/null || \
                      echo '未知')
    echo "主类: $main_class"
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
    echo "应用模块信息:"
    echo "- 模块类型: Spring Boot 应用"
    echo "- 构建工具: Maven"
    echo "- 目标: 生成可执行 jar 包"
    echo ""
    
    # 检查环境
    check_maven
    check_java
    
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
    echo "✅ primihub-service/application 模块构建成功完成！"
    echo "✅ 构建产物已生成到 target/ 目录"
    echo ""
    echo "可以使用以下命令运行应用:"
    echo "java -jar target/application-*.jar"
}

# 执行主函数
main "$@"
