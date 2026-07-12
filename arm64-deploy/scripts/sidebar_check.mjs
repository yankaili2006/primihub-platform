// 真·无头浏览器验证：登录 admin/123456 → 渲染侧边栏 → 断言菜单项数 → 截图。
// 用法: BASE=http://127.0.0.1:30811 MIN_ITEMS=120 OUT=out/sidebar.png node sidebar_check.mjs
import { chromium } from 'playwright';

const BASE = process.env.BASE || 'http://127.0.0.1:30811';
const USER = process.env.LOGIN_USER || 'admin';
const PASS = process.env.LOGIN_PASS || '123456';
const MIN  = parseInt(process.env.MIN_ITEMS || '120', 10);
const OUT  = process.env.OUT || 'sidebar.png';

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
const ctx = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
const pg = await ctx.newPage();
pg.on('dialog', d => d.dismiss().catch(() => {}));

let rc = 1;
try {
  await pg.goto(BASE + '/#/login', { waitUntil: 'networkidle', timeout: 45000 });
  await pg.waitForTimeout(1500);
  const u = await pg.$('input[type="text"]'); if (u) await u.fill(USER);
  const p = await pg.$('input[type="password"]'); if (p) await p.fill(PASS);
  await pg.waitForTimeout(300);
  const btn = await pg.$('button'); if (btn) await btn.click();
  await pg.waitForTimeout(6000);                       // 等路由生成 + 侧边栏渲染
  console.log('URL after login:', pg.url());

  const items = await pg.$$eval(
    '.el-menu .el-submenu__title span, .el-menu .el-menu-item span, aside .el-submenu__title, aside .el-menu-item',
    els => [...new Set(els.map(e => e.textContent.trim()).filter(Boolean))]
  );
  await pg.screenshot({ path: OUT, fullPage: true });
  console.log(`sidebar menu items = ${items.length} (need >= ${MIN})`);
  console.log('sample:', items.slice(0, 30).join(' | '));

  const loggedIn = !/\/login/.test(pg.url());
  if (!loggedIn) { console.error('✗ 登录后仍停留在 /login'); rc = 2; }
  else if (items.length < MIN) { console.error(`✗ 侧边栏菜单项过少 (${items.length} < ${MIN})`); rc = 3; }
  else { console.log('✅ 侧边栏功能菜单渲染正常'); rc = 0; }
} catch (e) {
  console.error('✗ 浏览器验证异常:', e.message);
  try { await pg.screenshot({ path: OUT, fullPage: true }); } catch {}
  rc = 4;
} finally {
  await browser.close();
}
process.exit(rc);
