/**
 * 测试脚本：模拟无痕模式下访问联邦分析菜单
 * 使用 Puppeteer 无头浏览器模拟用户登录和访问
 */

const puppeteer = require('puppeteer');

// 配置参数
const CONFIG = {
  baseUrl: process.env.BASE_URL || 'http://localhost:8080',
  username: process.env.TEST_USERNAME || 'admin',
  password: process.env.TEST_PASSWORD || 'admin123',
  headless: process.env.HEADLESS !== 'false', // 默认无头模式
  slowMo: parseInt(process.env.SLOW_MO) || 0, // 减慢操作速度（毫秒）
};

async function testFederatedAnalysisAccess() {
  console.log('🚀 开始测试联邦分析菜单访问...\n');
  console.log('配置信息:');
  console.log(`  - 基础URL: ${CONFIG.baseUrl}`);
  console.log(`  - 用户名: ${CONFIG.username}`);
  console.log(`  - 无头模式: ${CONFIG.headless}`);
  console.log('');

  let browser;
  let testResults = {
    login: false,
    routeGeneration: false,
    menuAccess: false,
    apiCall: false,
    errors: []
  };

  try {
    // 启动浏览器（无痕模式）
    console.log('📱 启动无头浏览器（无痕模式）...');
    browser = await puppeteer.launch({
      headless: CONFIG.headless,
      slowMo: CONFIG.slowMo,
      args: [
        '--incognito', // 无痕模式
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-web-security',
        '--disable-features=IsolateOrigins,site-per-process'
      ]
    });

    // 创建无痕上下文
    const context = await browser.createIncognitoBrowserContext();
    const page = await context.newPage();

    // 设置视口
    await page.setViewport({ width: 1920, height: 1080 });

    // 监听控制台输出
    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('未匹配到路由') || text.includes('权限') || text.includes('路由')) {
        console.log(`  [浏览器控制台] ${text}`);
      }
    });

    // 监听页面错误
    page.on('pageerror', error => {
      console.error(`  [页面错误] ${error.message}`);
      testResults.errors.push(error.message);
    });

    // 监听网络请求
    const apiCalls = [];
    page.on('response', async response => {
      const url = response.url();
      if (url.includes('/api/') || url.includes('/dev-api/')) {
        const status = response.status();
        apiCalls.push({ url, status });

        if (url.includes('federatedAnalysis') || url.includes('getPermission') || url.includes('getAuthList')) {
          console.log(`  [API请求] ${status} ${url}`);

          // 如果是权限相关接口，打印响应
          if (url.includes('getPermission') || url.includes('getAuthList')) {
            try {
              const data = await response.json();
              console.log(`  [API响应] ${JSON.stringify(data).substring(0, 200)}...`);
            } catch (e) {
              // 忽略非JSON响应
            }
          }
        }
      }
    });

    // 步骤1: 访问登录页
    console.log('\n📝 步骤1: 访问登录页...');
    await page.goto(`${CONFIG.baseUrl}/login`, {
      waitUntil: 'networkidle2',
      timeout: 30000
    });
    console.log('  ✓ 登录页加载完成');

    // 等待登录表单加载
    await page.waitForSelector('input[type="text"], input[placeholder*="用户名"], input[placeholder*="账号"]', { timeout: 10000 });

    // 步骤2: 输入用户名和密码
    console.log('\n📝 步骤2: 输入登录凭证...');

    // 尝试多种选择器来找到用户名输入框
    const usernameSelectors = [
      'input[placeholder*="用户名"]',
      'input[placeholder*="账号"]',
      'input[type="text"]',
      '.el-input__inner[type="text"]'
    ];

    let usernameInput = null;
    for (const selector of usernameSelectors) {
      try {
        usernameInput = await page.$(selector);
        if (usernameInput) {
          await page.type(selector, CONFIG.username);
          console.log(`  ✓ 用户名已输入 (使用选择器: ${selector})`);
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!usernameInput) {
      throw new Error('无法找到用户名输入框');
    }

    // 尝试多种选择器来找到密码输入框
    const passwordSelectors = [
      'input[placeholder*="密码"]',
      'input[type="password"]',
      '.el-input__inner[type="password"]'
    ];

    let passwordInput = null;
    for (const selector of passwordSelectors) {
      try {
        passwordInput = await page.$(selector);
        if (passwordInput) {
          await page.type(selector, CONFIG.password);
          console.log(`  ✓ 密码已输入 (使用选择器: ${selector})`);
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!passwordInput) {
      throw new Error('无法找到密码输入框');
    }

    // 步骤3: 点击登录按钮
    console.log('\n📝 步骤3: 点击登录按钮...');

    const loginButtonSelectors = [
      'button[type="submit"]',
      'button.el-button--primary',
      'button:contains("登录")',
      '.login-button'
    ];

    let loginClicked = false;
    for (const selector of loginButtonSelectors) {
      try {
        const button = await page.$(selector);
        if (button) {
          await button.click();
          console.log(`  ✓ 登录按钮已点击 (使用选择器: ${selector})`);
          loginClicked = true;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!loginClicked) {
      throw new Error('无法找到登录按钮');
    }

    // 等待登录完成（等待跳转或等待特定元素）
    console.log('  ⏳ 等待登录完成...');
    await page.waitForNavigation({
      waitUntil: 'networkidle2',
      timeout: 30000
    }).catch(() => {
      console.log('  ⚠️  导航超时，继续检查登录状态...');
    });

    // 检查是否登录成功
    await page.waitForTimeout(2000);
    const currentUrl = page.url();

    if (currentUrl.includes('/login')) {
      // 检查是否有错误提示
      const errorMsg = await page.evaluate(() => {
        const msgEl = document.querySelector('.el-message__content');
        return msgEl ? msgEl.textContent : null;
      });

      if (errorMsg) {
        throw new Error(`登录失败: ${errorMsg}`);
      }
      throw new Error('登录失败: 仍在登录页面');
    }

    console.log(`  ✓ 登录成功，当前URL: ${currentUrl}`);
    testResults.login = true;

    // 步骤4: 检查localStorage中的权限数据
    console.log('\n📝 步骤4: 检查权限数据...');
    const permissionData = await page.evaluate(() => {
      const perKey = 'primihubPer';
      const data = localStorage.getItem(perKey);
      return data ? JSON.parse(data) : null;
    });

    if (permissionData && permissionData.length > 0) {
      console.log(`  ✓ 权限数据已加载，共 ${permissionData.length} 条权限`);

      // 查找联邦分析相关权限
      const federatedAnalysisPerms = permissionData.filter(p =>
        p.authCode && p.authCode.includes('FederatedAnalysis')
      );

      if (federatedAnalysisPerms.length > 0) {
        console.log(`  ✓ 找到联邦分析权限，共 ${federatedAnalysisPerms.length} 条:`);
        federatedAnalysisPerms.forEach(p => {
          console.log(`    - ${p.authCode}: ${p.authName || 'N/A'}`);
        });
      } else {
        console.log('  ⚠️  未找到联邦分析相关权限');
      }
    } else {
      console.log('  ⚠️  权限数据为空或未加载');
    }

    // 步骤5: 检查路由是否已生成
    console.log('\n📝 步骤5: 检查动态路由...');
    const routeInfo = await page.evaluate(() => {
      // 尝试访问Vue实例
      const app = document.querySelector('#app').__vue__;
      if (app && app.$router) {
        const routes = app.$router.options.routes || [];
        const addedRoutes = app.$router.getRoutes ? app.$router.getRoutes() : [];
        return {
          totalRoutes: routes.length,
          addedRoutesCount: addedRoutes.length,
          hasFederatedAnalysis: routes.some(r => r.path === '/federatedAnalysis') ||
                                addedRoutes.some(r => r.path === '/federatedAnalysis')
        };
      }
      return null;
    });

    if (routeInfo) {
      console.log(`  ✓ 路由信息:`);
      console.log(`    - 基础路由数: ${routeInfo.totalRoutes}`);
      console.log(`    - 总路由数: ${routeInfo.addedRoutesCount}`);
      console.log(`    - 包含联邦分析路由: ${routeInfo.hasFederatedAnalysis ? '是' : '否'}`);
      testResults.routeGeneration = routeInfo.hasFederatedAnalysis;
    } else {
      console.log('  ⚠️  无法获取路由信息');
    }

    // 步骤6: 尝试访问联邦分析菜单
    console.log('\n📝 步骤6: 访问联邦分析菜单...');

    // 方法1: 直接导航到URL
    console.log('  方法1: 直接导航到 /federatedAnalysis/index');
    await page.goto(`${CONFIG.baseUrl}/#/federatedAnalysis/index`, {
      waitUntil: 'networkidle2',
      timeout: 30000
    });

    await page.waitForTimeout(2000);

    // 检查是否显示"暂无权限"
    const hasNoPermissionMsg = await page.evaluate(() => {
      const messages = Array.from(document.querySelectorAll('.el-message__content'));
      return messages.some(el => el.textContent.includes('暂无权限'));
    });

    if (hasNoPermissionMsg) {
      console.log('  ❌ 显示"暂无权限"提示');
      testResults.menuAccess = false;
    } else {
      const finalUrl = page.url();
      console.log(`  当前URL: ${finalUrl}`);

      if (finalUrl.includes('/federatedAnalysis')) {
        console.log('  ✓ 成功访问联邦分析页面');
        testResults.menuAccess = true;

        // 检查页面内容
        const pageContent = await page.evaluate(() => {
          return {
            title: document.title,
            hasContent: document.querySelector('.app-container') !== null ||
                       document.querySelector('.page-container') !== null
          };
        });

        console.log(`  页面标题: ${pageContent.title}`);
        console.log(`  页面内容已加载: ${pageContent.hasContent ? '是' : '否'}`);
      } else if (finalUrl.includes('/404') || finalUrl === `${CONFIG.baseUrl}/` || finalUrl === `${CONFIG.baseUrl}/#/`) {
        console.log('  ❌ 被重定向到首页或404页面');
        testResults.menuAccess = false;
      } else {
        console.log('  ⚠️  未知状态');
      }
    }

    // 步骤7: 尝试调用联邦分析API
    console.log('\n📝 步骤7: 测试联邦分析API调用...');
    const apiTestResult = await page.evaluate(async () => {
      try {
        // 获取token
        const tokenKey = Object.keys(document.cookie)
          .map(key => key.trim())
          .find(key => key.includes('primihub_token'));

        const token = tokenKey ? document.cookie
          .split('; ')
          .find(row => row.startsWith(tokenKey))
          ?.split('=')[1] : null;

        if (!token) {
          return { success: false, error: 'Token not found' };
        }

        // 调用联邦分析列表API
        const response = await fetch('/dev-api/data/federatedAnalysis/list?pageNum=1&pageSize=10', {
          method: 'GET',
          headers: {
            'token': token,
            'Content-Type': 'application/json'
          }
        });

        const data = await response.json();
        return {
          success: response.ok,
          status: response.status,
          code: data.code,
          message: data.msg || data.message,
          hasData: !!data.result
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });

    if (apiTestResult.success) {
      console.log(`  ✓ API调用成功`);
      console.log(`    - HTTP状态: ${apiTestResult.status}`);
      console.log(`    - 响应码: ${apiTestResult.code}`);
      console.log(`    - 有数据: ${apiTestResult.hasData ? '是' : '否'}`);
      testResults.apiCall = true;
    } else {
      console.log(`  ❌ API调用失败`);
      console.log(`    - 错误: ${apiTestResult.error || apiTestResult.message}`);
      testResults.apiCall = false;
    }

    // 截图保存
    const screenshotPath = '/tmp/federated_analysis_test.png';
    await page.screenshot({ path: screenshotPath, fullPage: true });
    console.log(`\n📸 截图已保存: ${screenshotPath}`);

  } catch (error) {
    console.error(`\n❌ 测试过程中发生错误: ${error.message}`);
    testResults.errors.push(error.message);

    // 尝试截图
    if (browser) {
      try {
        const pages = await browser.pages();
        if (pages.length > 0) {
          await pages[0].screenshot({ path: '/tmp/error_screenshot.png', fullPage: true });
          console.log('📸 错误截图已保存: /tmp/error_screenshot.png');
        }
      } catch (e) {
        // 忽略截图错误
      }
    }
  } finally {
    // 关闭浏览器
    if (browser) {
      await browser.close();
      console.log('\n🔒 浏览器已关闭');
    }
  }

  // 输出测试结果
  console.log('\n' + '='.repeat(60));
  console.log('📊 测试结果汇总');
  console.log('='.repeat(60));
  console.log(`✅ 登录: ${testResults.login ? '成功' : '失败'}`);
  console.log(`✅ 路由生成: ${testResults.routeGeneration ? '成功' : '失败'}`);
  console.log(`✅ 菜单访问: ${testResults.menuAccess ? '成功' : '失败'}`);
  console.log(`✅ API调用: ${testResults.apiCall ? '成功' : '失败'}`);

  if (testResults.errors.length > 0) {
    console.log(`\n❌ 错误列表 (${testResults.errors.length}):`);
    testResults.errors.forEach((err, idx) => {
      console.log(`  ${idx + 1}. ${err}`);
    });
  }

  const allPassed = testResults.login && testResults.routeGeneration &&
                    testResults.menuAccess && testResults.apiCall;

  console.log('\n' + '='.repeat(60));
  if (allPassed) {
    console.log('🎉 所有测试通过！');
    process.exit(0);
  } else {
    console.log('⚠️  部分测试失败，请检查上述错误信息');
    process.exit(1);
  }
}

// 运行测试
testFederatedAnalysisAccess().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
