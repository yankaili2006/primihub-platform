#!/bin/bash
# PVE VM 创建脚本 - 用于 PrimiHub 离线部署测试
# 用法: bash create-vm.sh <VMID> <IP_LAST_OCTET> [TEMPLATE_ID]

set -e
VMID=${1:-106}
IP_LAST=${2:-106}
TEMPLATE=${3:-9010}
NAME="test-offline-v${VMID}"
SSH_KEY="/tmp/vm${VMID}_sshkey"
DISK="/dev/pve/vm-${VMID}-disk-0"

echo "🚀 创建 VM $VMID (IP: 192.168.99.$IP_LAST)"

# 清理旧 VM
qm stop $VMID --skiplock 2>/dev/null || true
qm destroy $VMID --purge 2>/dev/null || true
sleep 2

# 准备 SSH key
cat > $SSH_KEY << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHGuxjBWA5U7ybrediBXR+2e3sQt1VvdtXmHaDzTvP7u liyankai@primihub.com
EOF

# 克隆并配置
echo "  → 克隆模板 $TEMPLATE..."
qm clone $TEMPLATE $VMID --name $NAME --full 1 2>&1 | tail -1

echo "  → 配置 VM..."
qm set $VMID --cores 4 --memory 8192 \
  --ipconfig0 ip=192.168.99.$IP_LAST/24,gw=192.168.99.1 \
  --ciuser root --cipassword 1qazmko0

# ⚠️ 关键步骤：使用 virt-customize 注入 SSH 密钥
# cloud-init 的 --sshkey 参数在部分 Ubuntu 模板中不生效
echo "  → 注入 SSH 密钥（virt-customize）..."
qm stop $VMID --skiplock 2>/dev/null || true
sleep 2
virt-customize -a $DISK --ssh-inject "root:file:$SSH_KEY" 2>&1 | tail -3

echo "  → 启动 VM..."
qm start $VMID

# 等待 SSH
echo "  → 等待 SSH 就绪..."
for i in $(seq 1 30); do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 root@192.168.99.$IP_LAST "hostname" 2>/dev/null; then
    echo "✅ VM $VMID 就绪 (192.168.99.$IP_LAST)"
    exit 0
  fi
  sleep 4
done

echo "❌ VM $VMID SSH 超时"
exit 1
