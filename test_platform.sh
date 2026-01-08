#!/bin/bash

echo "=== PrimiHub平台功能测试 ==="
echo ""

# 0. 测试登录功能
echo "0. 测试Web登录功能:"
if [ -f "/home/primihub/github/primihub/venv/bin/python" ] && [ -f "/home/primihub/github/primihub-platform/scripts/test_login_123456.py" ]; then
    echo "   运行自动化登录测试..."
    /home/primihub/github/primihub/venv/bin/python /home/primihub/github/primihub-platform/scripts/test_login_123456.py > /tmp/login_test_output.log 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✓ Web登录测试通过 (用户名: admin, 密码: 123456)"
    else
        echo "   ✗ Web登录测试失败 (查看日志: /tmp/login_test_output.log)"
    fi
else
    echo "   ⊘ 跳过自动化登录测试 (Playwright未安装)"
fi
echo ""

# 测试基本API
echo "1. 测试基本API端点:"
echo "   跟踪ID: $(curl -s http://localhost:8090/common/getTrackingID)"
echo "   公钥: $(curl -s http://localhost:8090/common/getValidatePublicKey | python3 -c "import sys, json; data=json.load(sys.stdin); print('获取成功' if data['code']==0 else '失败')")"
echo "   收集列表: $(curl -s http://localhost:8090/common/getCollectList | python3 -c "import sys, json; data=json.load(sys.stdin); print('获取成功' if data['code']==0 else '失败')")"

# 测试机构相关API
echo -e "\n2. 测试机构API:"
echo "   机构首页: $(curl -s http://localhost:8090/organ/getHomepage | python3 -c "import sys, json; data=json.load(sys.stdin); print('成功' if data['code']==0 else '失败')")"

# 测试项目相关API
echo -e "\n3. 测试项目API:"
echo "   项目列表: $(curl -s 'http://localhost:8090/project/getProjectList?pageNum=1&pageSize=10' | python3 -c "import sys, json; data=json.load(sys.stdin); print('成功' if data['code']==0 else '失败: ' + str(data.get('code', '未知')))")"
echo "   项目统计: $(curl -s http://localhost:8090/project/getListStatistics | python3 -c "import sys, json; data=json.load(sys.stdin); print('成功' if data['code']==0 else '失败')")"

# 测试资源相关API
echo -e "\n4. 测试资源API:"
echo "   资源列表: $(curl -s 'http://localhost:8090/resource/getResourceList?pageNum=1&pageSize=10' | python3 -c "import sys, json; data=json.load(sys.stdin); print('成功' if data['code']==0 else '失败')")"

# 测试隐私计算API
echo -e "\n5. 测试隐私计算API:"
echo "   PSI任务列表: $(curl -s 'http://localhost:8090/psi/getPsiTaskList?pageNum=1&pageSize=10' | python3 -c "import sys, json; data=json.load(sys.stdin); print('成功' if data['code']==0 else '失败: ' + str(data.get('code', '未知')))")"
echo "   PIR任务列表: $(curl -s 'http://localhost:8090/pir/getPirTaskList?pageNum=1&pageSize=10' | python3 -c "import sys, json; data=json.load(sys.stdin); print('成功' if data['code']==0 else '失败: ' + str(data.get('code', '未知')))")"

# 测试模型API
echo -e "\n6. 测试模型API:"
echo "   模型列表: $(curl -s 'http://localhost:8090/model/getModelList?pageNum=1&pageSize=10' | python3 -c "import sys, json; data=json.load(sys.stdin); print('成功' if data['code']==0 else '失败')")"

echo -e "\n=== 测试完成 ==="
echo "前端地址: http://localhost:8080"
echo "后端API: http://localhost:8090"
echo "Clash代理: http://127.0.0.1:7890"