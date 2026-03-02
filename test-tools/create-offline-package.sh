#!/bin/bash
# 创建完整的离线部署工具包

echo "=========================================="
echo "  创建离线部署工具包"
echo "=========================================="
echo ""

PACKAGE_NAME="primihub-offline-toolkit-$(date +%Y%m%d_%H%M%S)"
PACKAGE_DIR="/tmp/$PACKAGE_NAME"

# 创建打包目录
mkdir -p "$PACKAGE_DIR"

echo "1. 复制核心脚本..."
cp deploy-offline.sh "$PACKAGE_DIR/"
cp import-images.sh "$PACKAGE_DIR/"
cp export-images.sh "$PACKAGE_DIR/"
cp health_check.sh "$PACKAGE_DIR/"
echo "✓ 核心脚本已复制"

echo ""
echo "2. 复制修复工具..."
cp fix-offline-deploy.sh "$PACKAGE_DIR/"
cp fix-mysql-connection.sh "$PACKAGE_DIR/"
cp fix-healthcheck.sh "$PACKAGE_DIR/"
cp diagnose-nacos.sh "$PACKAGE_DIR/"
cp verify-nacos-db.sh "$PACKAGE_DIR/"
echo "✓ 修复工具已复制"

echo ""
echo "3. 复制配置文件..."
cp docker-compose.yaml "$PACKAGE_DIR/"
cp .env "$PACKAGE_DIR/"
cp -r config "$PACKAGE_DIR/"
cp -r data/env "$PACKAGE_DIR/data/"
cp -r data/initsql "$PACKAGE_DIR/data/"
echo "✓ 配置文件已复制"

echo ""
echo "4. 复制文档..."
cp *.md "$PACKAGE_DIR/" 2>/dev/null
echo "✓ 文档已复制"

echo ""
echo "5. 创建README..."
cat > "$PACKAGE_DIR/README_FIRST.txt" << 'EOFREADME'
========================================
PrimiHub 离线部署工具包
========================================

📦 本工具包包含：
- 离线部署脚本
- 故障修复工具
- 诊断工具
- 完整文档

⚠️ 重要：还需要镜像文件
- primihub-images-*.tar (2.4GB)
- 需单独复制到本目录

🚀 快速开始：

1. 确保镜像文件在本目录
   ls -lh primihub-images-*.tar

2. 执行部署
   bash deploy-offline.sh

📚 详细文档：
- OFFLINE_DEPLOYMENT_PACKAGE.md - 完整工具包说明
- OFFLINE_DEPLOY_README.md - 部署指南
- OFFLINE_FIX_GUIDE.md - 故障修复

🆘 如果遇到问题：

问题1: Nacos显示"no DataSource set"
解决: bash fix-mysql-connection.sh

问题2: MySQL报"Access denied"
解决: bash fix-healthcheck.sh

问题3: 需要完全重新部署
解决: bash deploy-offline.sh

========================================
更新时间: 2026-01-14
版本: v1.1.0
========================================
EOFREADME

echo "✓ README已创建"

echo ""
echo "6. 创建快速安装说明..."
cat > "$PACKAGE_DIR/QUICK_INSTALL.sh" << 'EOFINSTALL'
#!/bin/bash
# 离线环境快速安装脚本

echo "=========================================="
echo "  PrimiHub 离线环境快速安装"
echo "=========================================="
echo ""

# 检查镜像文件
if ! ls primihub-images-*.tar &>/dev/null; then
    echo "❌ 错误：找不到镜像文件 primihub-images-*.tar"
    echo "请将镜像文件复制到本目录后再运行"
    exit 1
fi

echo "✓ 找到镜像文件"
echo ""

# 检查Docker
if ! command -v docker &>/dev/null; then
    echo "❌ 错误：Docker未安装"
    echo "请先安装Docker"
    exit 1
fi

echo "✓ Docker已安装"
echo ""

# 检查docker-compose
if ! command -v docker-compose &>/dev/null; then
    echo "❌ 错误：docker-compose未安装"
    echo "请先安装docker-compose"
    exit 1
fi

echo "✓ docker-compose已安装"
echo ""

# 开始部署
echo "=========================================="
echo "  开始部署"
echo "=========================================="
echo ""

bash deploy-offline.sh

echo ""
echo "=========================================="
echo "  安装完成"
echo "=========================================="
echo ""
EOFINSTALL
chmod +x "$PACKAGE_DIR/QUICK_INSTALL.sh"
echo "✓ 快速安装脚本已创建"

echo ""
echo "7. 设置权限..."
chmod +x "$PACKAGE_DIR"/*.sh
echo "✓ 权限已设置"

echo ""
echo "8. 打包..."
cd /tmp
tar czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"
PACKAGE_SIZE=$(du -h "${PACKAGE_NAME}.tar.gz" | cut -f1)

echo "✓ 打包完成"

echo ""
echo "=========================================="
echo "  工具包创建完成"
echo "=========================================="
echo ""
echo "工具包位置: /tmp/${PACKAGE_NAME}.tar.gz"
echo "工具包大小: $PACKAGE_SIZE"
echo ""
echo "包含文件:"
echo "  - 核心脚本: 5个"
echo "  - 修复工具: 5个"
echo "  - 配置文件: 完整"
echo "  - 文档: 完整"
echo ""
echo "⚠️ 注意事项:"
echo "1. 还需要单独复制镜像文件:"
echo "   primihub-images-*.tar (2.4GB)"
echo ""
echo "2. 传输到离线环境后解压:"
echo "   tar xzf ${PACKAGE_NAME}.tar.gz"
echo "   cd $PACKAGE_NAME"
echo ""
echo "3. 复制镜像文件到解压目录:"
echo "   cp /path/to/primihub-images-*.tar ."
echo ""
echo "4. 运行快速安装:"
echo "   bash QUICK_INSTALL.sh"
echo ""
echo "或查看 README_FIRST.txt 了解详细说明"
echo ""

# 清理临时目录
rm -rf "$PACKAGE_DIR"
echo "✓ 临时文件已清理"
echo ""
