#!/bin/bash

# 修复离线部署问题
# 覆盖: Nacos配置推送、磁盘空间、容器重启、数据库修复

set -e

echo "=========================================="
echo "   修复离线部署配置"
echo "=========================================="
echo ""

# 0. 检查磁盘空间
DISK_AVAIL=$(df / | tail -1 | awk '{print $4}')
DISK_AVAIL_GB=$((DISK_AVAIL / 1024 / 1024))
echo "步骤0: 检查磁盘空间..."
echo "  可用: ${DISK_AVAIL_GB}GB"
if [ "$DISK_AVAIL_GB" -lt 10 ]; then
    echo "  ⚠️ 磁盘空间不足 10GB，部署可能失败"
    echo "  建议扩容: qm resize <VMID> scsi0 30G"
    echo "  然后: growpart /dev/sda 1 && resize2fs /dev/sda1"
fi
echo ""

cd "$(dirname "$0")"

# 1. 停止服务
echo "步骤1: 停止所有服务..."
docker-compose down
echo ""

# 2. 获取主机IP
HOST_IP=$(hostname -I | awk '{print $1}')
echo "步骤2: 检测到主机IP: $HOST_IP"
echo ""

# 3. 备份nacos配置
echo "步骤3: 备份nacos配置文件..."
if [ ! -f "data/initsql/nacos_config.sql.bak" ]; then
    cp data/initsql/nacos_config.sql data/initsql/nacos_config.sql.bak
    echo "✓ 已备份为 nacos_config.sql.bak"
else
    echo "✓ 备份文件已存在"
fi
echo ""

# 4. 替换IP地址
echo "步骤4: 更新Loki地址配置..."
# 先尝试从备份恢复
if [ -f "data/initsql/nacos_config.sql.bak" ]; then
    cp data/initsql/nacos_config.sql.bak data/initsql/nacos_config.sql
    echo "✓ 从备份恢复配置文件"
fi

# 替换所有可能的IP地址
sed -i "s/192\.168\.99\.5:3100/${HOST_IP}:3100/g" data/initsql/nacos_config.sql
sed -i "s/YOUR_HOST_IP/${HOST_IP}/g" data/initsql/nacos_config.sql

REPLACED=$(grep -c "${HOST_IP}:3100" data/initsql/nacos_config.sql || true)
echo "✓ 已更新 $REPLACED 处Loki地址为: ${HOST_IP}:3100"
echo ""

# 5. 清理MySQL数据
echo "步骤5: 清理MySQL数据目录..."
if [ -d "data/mysql" ]; then
    mv data/mysql data/mysql.bak.$(date +%Y%m%d_%H%M%S)
    echo "✓ MySQL数据已备份并清理"
else
    echo "✓ MySQL数据目录不存在，跳过"
fi
echo ""

# 6. 检查镜像
echo "步骤6: 检查所需镜像..."
MISSING=0
for img in primihub-meta primihub-node nacos-server rabbitmq redis mysql loki; do
    if ! docker images | grep -q "$img"; then
        echo "⚠ 缺少镜像: $img"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "❌ 缺少必需的镜像，请先导入离线镜像包:"
    echo "   bash import-images.sh primihub-images-*.tar"
    exit 1
fi
echo "✓ 所有必需镜像已就绪"
echo ""

# 7. 启动服务
echo "步骤7: 启动服务..."
docker-compose up -d
echo ""

# 8. 等待服务就绪
echo "步骤8: 等待服务就绪..."
echo "等待MySQL启动(约30秒)..."
sleep 30

# 检查MySQL
docker exec mysql mysqladmin ping -h localhost -uprimihub -pprimihub@123 &>/dev/null && \
    echo "✓ MySQL已就绪" || echo "⚠ MySQL仍在启动中"

echo ""
echo "等待Nacos启动(约30秒)..."
sleep 30

# 检查Nacos
curl -s http://localhost:8848/nacos &>/dev/null && \
    echo "✓ Nacos已就绪" || echo "⚠ Nacos仍在启动中"

# 9. 初始化缺失的数据库表
echo "步骤9: 初始化缺失的数据库表..."
INIT_SQL="init-privacy-db-tables.sql"
if [ -f "$INIT_SQL" ]; then
    MYSQL_PASS="${MYSQL_PASS:-root}"
    echo "应用数据库表初始化..."
    docker exec -i mysql mysql -uroot -p"$MYSQL_PASS" privacy < "$INIT_SQL" 2>/dev/null && \
        echo "✓ 数据库表初始化完成" || echo "⚠ 数据库表初始化失败，可手动执行: docker exec -i mysql mysql -uroot -proot privacy < $INIT_SQL"
else
    echo "⚠ 未找到数据库初始化SQL ($INIT_SQL)，跳过"
fi
echo ""

# 10. 安装 Python3 和算法脚本
echo "步骤10: 安装 Python3 和算法脚本..."
SETUP_SCRIPT="setup-python-algorithms.sh"
if [ -f "$SETUP_SCRIPT" ]; then
    bash "$SETUP_SCRIPT" 2>&1 | tail -5
    echo "✓ Python算法脚本安装完成"
else
    echo "⚠ 未找到安装脚本 ($SETUP_SCRIPT)，跳过"
    echo "  手动安装: docker exec application0 yum install -y python3"
fi
echo ""

# 11. 重启应用容器使配置生效
echo "步骤11: 重启应用容器..."
for container in application0 application1 application2 gateway0 gateway1 gateway2; do
    docker restart "$container" 2>/dev/null && echo "✓ $container 已重启" || echo "⚠ $container 重启失败"
done

echo "等待应用启动(约60秒)..."
sleep 40
for container in application0 application1 application2; do
    HEALTH=$(docker exec "$container" sh -c "curl -s http://127.0.0.1:8080/actuator/health" 2>/dev/null || echo "unhealthy")
    echo "  $container: $HEALTH"
done
echo ""

# 12. 修复缺失的前端权限
echo "步骤12: 修复缺失的前端路由权限..."
FIX_SQL="../fix_missing_auth_entries.sql"
if [ -f "$FIX_SQL" ]; then
    echo "应用权限修复SQL..."
    # 查找privacy数据库的用户和密码
    MYSQL_USER="${MYSQL_USER:-root}"
    MYSQL_PASS="${MYSQL_PASS:-1qazmko0}"
    docker exec -i mysql mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" privacy < "$FIX_SQL" 2>/dev/null && \
        echo "✓ 权限修复完成" || echo "⚠ 权限修复失败，可手动执行: docker exec -i mysql mysql -uroot privacy < $FIX_SQL"
else
    echo "⚠ 未找到权限修复SQL ($FIX_SQL)，跳过"
    echo "  如需修复请手动执行: docker exec -i mysql mysql -uroot privacy < fix_missing_auth_entries.sql"
fi
echo ""

echo ""
echo "=========================================="
echo "   修复完成"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  机构1: http://${HOST_IP}:30811"
echo "  机构2: http://${HOST_IP}:30812"
echo "  机构3: http://${HOST_IP}:30813"
echo ""
echo "查看服务状态: docker-compose ps"
echo "查看日志: docker-compose logs -f"
echo "健康检查: bash health_check.sh"
echo ""

echo "📋 后续步骤:"
echo "  所有用户需要重新登录以使权限生效（清除浏览器缓存或退出重新登录）"
echo ""

# 13. 执行验证测试
echo "步骤13: 执行自动化验证..."
cd "$(dirname "$0")/.."
if [ -f "deploy_verify.py" ]; then
    echo "运行快速验证（路由+API）..."
    python3 deploy_verify.py --base "http://${HOST_IP}:30811" 2>&1 | tail -15
    echo "✓ 验证完成"
    echo ""
    echo "完整验证（含交互测试）: python3 deploy_verify.py --full --base http://${HOST_IP}:30811"
else
    echo "⚠ 未找到 deploy_verify.py，跳过验证"
fi
echo ""
