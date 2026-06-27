#!/bin/sh
# Nginx启动脚本 - 从配置文件读取平台名称并应用
# Nginx Entrypoint Script - Read platform name from config and apply

set -e

# 配置文件路径
PLATFORM_CONFIG="/etc/nginx/conf.d/platform.env"
NGINX_CONFIG="/etc/nginx/conf.d/default.conf"
TEMP_CONFIG="/tmp/default.conf"

# 默认平台名称
DEFAULT_PLATFORM_NAME="PrimiHub"

# 读取配置文件中的平台名称
if [ -f "$PLATFORM_CONFIG" ]; then
    echo "Reading platform configuration from $PLATFORM_CONFIG"
    # 读取PLATFORM_NAME配置项（忽略注释和空行）
    PLATFORM_NAME=$(grep -E "^PLATFORM_NAME=" "$PLATFORM_CONFIG" | cut -d'=' -f2 | tr -d ' ')

    if [ -z "$PLATFORM_NAME" ]; then
        echo "Warning: PLATFORM_NAME not found in config, using default: $DEFAULT_PLATFORM_NAME"
        PLATFORM_NAME="$DEFAULT_PLATFORM_NAME"
    else
        echo "Platform name set to: $PLATFORM_NAME"
    fi
else
    echo "Warning: Config file not found at $PLATFORM_CONFIG, using default: $DEFAULT_PLATFORM_NAME"
    PLATFORM_NAME="$DEFAULT_PLATFORM_NAME"
fi

# 在nginx配置中替换占位符（使用临时文件避免bind mount问题）
if [ -f "$NGINX_CONFIG" ]; then
    echo "Applying platform name to nginx configuration..."
    sed "s/PLATFORM_NAME_PLACEHOLDER/$PLATFORM_NAME/g" "$NGINX_CONFIG" > "$TEMP_CONFIG"
    cat "$TEMP_CONFIG" > "$NGINX_CONFIG"
    rm -f "$TEMP_CONFIG"
    echo "Configuration updated successfully"
else
    echo "Warning: Nginx config not found at $NGINX_CONFIG"
fi

# 启动nginx
echo "Starting nginx..."
exec nginx -g 'daemon off;'
