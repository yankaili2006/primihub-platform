/**
 * 在浏览器Console中运行此脚本，自动登录并获取Token
 * 使用方法：
 * 1. 访问 http://172.20.0.12:8080
 * 2. 按 F12 打开开发者工具
 * 3. 切换到 Console 标签
 * 4. 复制粘贴此脚本并回车
 * 5. 等待几秒，token会显示在控制台
 */

(async function() {
    console.log('='.repeat(70));
    console.log('  PrimiHub 自动登录获取Token');
    console.log('='.repeat(70));

    const config = {
        username: 'admin',
        password: '123456',
        baseUrl: window.location.origin || 'http://172.20.0.12:8080'
    };

    console.log('\n配置信息:');
    console.log('  用户名:', config.username);
    console.log('  节点地址:', config.baseUrl);

    try {
        // 步骤1: 获取公钥
        console.log('\n▶ 步骤1: 获取公钥...');

        const timestamp = Date.now();
        const nonce = timestamp % 1000 + 1;

        const pubkeyResponse = await fetch(
            `${config.baseUrl}/sys/user/getPubKey?timestamp=${timestamp}&nonce=${nonce}`
        );

        const pubkeyData = await pubkeyResponse.json();

        if (pubkeyData.code !== 0) {
            console.error('❌ 获取公钥失败:', pubkeyData.msg);
            return;
        }

        const publicKey = pubkeyData.result.pubKey;
        const validateKeyName = pubkeyData.result.validateKeyName;

        console.log('✅ 获取公钥成功');
        console.log('   validateKeyName:', validateKeyName);

        // 步骤2: 使用JSEncrypt加密密码（需要页面已加载JSEncrypt库）
        console.log('\n▶ 步骤2: 加密密码...');

        // 检查是否有JSEncrypt
        if (typeof JSEncrypt === 'undefined') {
            console.warn('⚠️  JSEncrypt未加载，尝试加载...');

            // 动态加载JSEncrypt
            await new Promise((resolve, reject) => {
                const script = document.createElement('script');
                script.src = 'https://cdn.jsdelivr.net/npm/jsencrypt@3.3.2/bin/jsencrypt.min.js';
                script.onload = resolve;
                script.onerror = reject;
                document.head.appendChild(script);
            });

            console.log('✅ JSEncrypt加载成功');
        }

        const encrypt = new JSEncrypt();
        encrypt.setPublicKey(`-----BEGIN PUBLIC KEY-----\n${publicKey}\n-----END PUBLIC KEY-----`);
        const encryptedPassword = encrypt.encrypt(config.password);

        if (!encryptedPassword) {
            console.error('❌ 密码加密失败');
            return;
        }

        console.log('✅ 密码加密成功');

        // 步骤3: 登录
        console.log('\n▶ 步骤3: 发送登录请求...');

        const loginTimestamp = Date.now();
        const loginNonce = loginTimestamp % 1000 + 1;

        const loginData = new URLSearchParams({
            userAccount: config.username,
            userPassword: encryptedPassword,
            validateKeyName: validateKeyName,
            timestamp: loginTimestamp,
            nonce: loginNonce
        });

        const loginResponse = await fetch(`${config.baseUrl}/sys/user/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: loginData
        });

        const loginResult = await loginResponse.json();

        if (loginResult.code !== 0) {
            console.error('❌ 登录失败:', loginResult.msg);
            console.error('响应:', loginResult);
            return;
        }

        const token = loginResult.result.token;
        const userId = loginResult.result.userId;
        const userName = loginResult.result.userName;

        console.log('✅ 登录成功!');
        console.log('   用户名:', userName);
        console.log('   用户ID:', userId);

        // 显示Token
        console.log('\n' + '='.repeat(70));
        console.log('  Token获取成功');
        console.log('='.repeat(70));
        console.log('\n✅ 完整Token:');
        console.log(token);

        console.log('\n【使用方法】');
        console.log('1. 复制上面的token');
        console.log('2. SSH连接到服务器');
        console.log('3. 运行命令：');
        console.log(`   cd /home/primihub/primihub-platform/primihub-test-framework/tests`);
        console.log(`   python3 get_token.py save node0 "${token}"`);
        console.log('\n或直接用于创建资源：');
        console.log('   python3 create_resources_interactive.py');
        console.log('   # 粘贴token');

        console.log('\n' + '='.repeat(70));

        // 复制到剪贴板（可能需要用户交互）
        try {
            await navigator.clipboard.writeText(token);
            console.log('\n✅ Token已复制到剪贴板！');
        } catch (e) {
            console.log('\n⚠️  无法自动复制到剪贴板，请手动复制上面的token');
        }

    } catch (error) {
        console.error('\n❌ 发生错误:', error);
        console.error(error.stack);
    }
})();
