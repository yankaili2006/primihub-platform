#!/bin/bash
# 权限问题快速修复脚本

echo "=========================================="
echo "PrimiHub Platform 权限问题快速修复"
echo "=========================================="
echo ""

# 获取当前应用进程ID
APP_PID=$(ps aux | grep "application-1.0-SNAPSHOT.jar" | grep -v grep | awk '{print $2}')

if [ -z "$APP_PID" ]; then
    echo "❌ 应用未运行"
else
    echo "✓ 找到应用进程: PID=$APP_PID"
fi

echo ""
echo "选择修复方案："
echo "1. 临时豁免白名单接口权限检查（推荐，快速生效）"
echo "2. 清除Redis权限缓存并重启应用"
echo "3. 使用超级Token测试"
echo "4. 查看当前权限配置"
echo "5. 退出"
echo ""

read -p "请选择 [1-5]: " choice

case $choice in
    1)
        echo ""
        echo "执行方案1: 临时豁免白名单接口权限检查"
        echo "=========================================="

        # 备份原文件
        FILTER_FILE="/home/primihub/github/primihub-platform/primihub-service/gateway/src/main/java/com/primihub/gateway/filter/SysAuthGatewayFilterFactory.java"
        BACKUP_FILE="${FILTER_FILE}.backup.$(date +%Y%m%d%H%M%S)"

        echo "1. 备份原文件到: ${BACKUP_FILE}"
        cp "$FILTER_FILE" "$BACKUP_FILE"

        echo "2. 检查是否已经添加了豁免逻辑..."
        if grep -q "临时豁免白名单" "$FILTER_FILE"; then
            echo "   ✓ 豁免逻辑已存在，跳过修改"
        else
            echo "   添加豁免逻辑..."
            # 这里需要手动编辑，因为已经在前面用Edit工具添加了调试日志
            echo "   ⚠️  请手动在代码中添加豁免逻辑，参考 AUTH_FIX_SOLUTION.md 方案二"
        fi

        echo "3. 重新编译应用..."
        cd /home/primihub/github/primihub-platform/primihub-service/application
        mvn clean package -DskipTests

        if [ $? -eq 0 ]; then
            echo "   ✓ 编译成功"

            if [ ! -z "$APP_PID" ]; then
                echo "4. 停止旧应用 (PID: $APP_PID)..."
                kill $APP_PID
                sleep 3
            fi

            echo "5. 启动新应用..."
            nohup java -jar target/application-1.0-SNAPSHOT.jar --spring.profiles.active=simple > ../backend.log 2>&1 &
            NEW_PID=$!
            echo "   ✓ 应用已启动，PID: $NEW_PID"
            echo "   日志文件: /home/primihub/github/primihub-platform/primihub-service/backend.log"
        else
            echo "   ❌ 编译失败"
            exit 1
        fi
        ;;

    2)
        echo ""
        echo "执行方案2: 清除Redis权限缓存"
        echo "=========================================="

        echo "1. 连接Redis并清除权限缓存..."
        redis-cli DEL sys_auth:bfs_list
        echo "   ✓ 已清除 sys_auth:bfs_list"

        redis-cli DEL sys_user:login_status_1
        echo "   ✓ 已清除 sys_user:login_status_1"

        if [ ! -z "$APP_PID" ]; then
            echo "2. 重启应用..."
            kill $APP_PID
            sleep 3

            cd /home/primihub/github/primihub-platform/primihub-service/application
            nohup java -jar target/application-1.0-SNAPSHOT.jar --spring.profiles.active=simple > ../backend.log 2>&1 &
            NEW_PID=$!
            echo "   ✓ 应用已重启，PID: $NEW_PID"
        fi
        ;;

    3)
        echo ""
        echo "执行方案3: 使用超级Token测试"
        echo "=========================================="
        echo ""
        echo "超级Token: excalibur_forever_ABCDEFGHIJKLMN"
        echo ""
        echo "测试命令示例："
        echo "curl -H 'token: excalibur_forever_ABCDEFGHIJKLMN' \\"
        echo "     'http://localhost:8090/whitelist/findWhitelistPage?pageNum=1&pageSize=10'"
        echo ""

        read -p "是否现在测试白名单接口? [y/N]: " test_now
        if [ "$test_now" = "y" ] || [ "$test_now" = "Y" ]; then
            echo ""
            echo "测试结果："
            curl -s -H 'token: excalibur_forever_ABCDEFGHIJKLMN' \
                 'http://localhost:8090/whitelist/findWhitelistPage?pageNum=1&pageSize=10' | jq .
        fi
        ;;

    4)
        echo ""
        echo "查看当前权限配置"
        echo "=========================================="

        echo ""
        echo "1. Redis中的权限列表（前5条）："
        redis-cli GET sys_auth:bfs_list | jq '.[0:5] | .[] | {authId, authName, authUrl}'

        echo ""
        echo "2. 当前登录用户信息："
        redis-cli HGETALL sys_user:login_status_1 | sed 'N;s/\n/: /'

        echo ""
        echo "3. 检查白名单相关权限："
        WHITELIST_COUNT=$(redis-cli GET sys_auth:bfs_list | jq '[.[] | select(.authUrl | contains("/whitelist"))] | length')
        echo "   白名单相关权限数量: $WHITELIST_COUNT"

        if [ "$WHITELIST_COUNT" = "0" ]; then
            echo "   ❌ 未找到白名单相关权限配置"
        else
            echo "   ✓ 已配置白名单权限"
            redis-cli GET sys_auth:bfs_list | jq '.[] | select(.authUrl | contains("/whitelist"))'
        fi
        ;;

    5)
        echo "退出"
        exit 0
        ;;

    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "✓ 完成"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 查看应用日志: tail -f /home/primihub/github/primihub-platform/primihub-service/backend.log"
echo "2. 测试白名单接口"
echo "3. 查看完整修复方案: cat AUTH_FIX_SOLUTION.md"
echo ""
