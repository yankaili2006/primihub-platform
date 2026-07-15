# E2E 证据截图 — 浏览器新增白名单（三机构）

联机验证目标：VM `primihub-full` @ `192.168.99.130`，webconsole 三机构端口
`30811`/`30812`/`30813`，登录 `admin/123456`。

这三张截图证明经过修复后，**三个机构的白名单页都渲染出「+ 新增白名单」按钮
和「操作」列（编辑/删除）**，即 `WhitelistAdd/Edit/Delete` 按钮权限均已生效：

| 文件 | 端口 | 机构 |
|---|---|---|
| `whitelist-button-org0-30811.png` | 30811 | 机构A |
| `whitelist-button-org1-30812.png` | 30812 | 机构B |
| `whitelist-button-org2-30813.png` | 30813 | org2 |

修复涉及两处：

1. **前端 content-type**：`primihub-webconsole` 的 `src/api/whitelist.js` 为
   addWhitelist/updateWhitelist 补 `type:'json'`（否则 request.js 默认发
   `x-www-form-urlencoded`，后端 `@RequestBody` 拒收 → `code=-1`）。已重构建
   并部署到三个 manage-web 容器。
2. **按钮权限种子**：`sys_auth` 原缺 `auth_type=3` 的
   `WhitelistAdd/WhitelistEdit/WhitelistDelete` 节点，导致按钮 `v-if` 掉、任何人
   都看不到。已在 `fusion0/1/2` 三库补节点（id 9510/9511/9512，父=1112 根=1111）
   并授权给 `role_id=1`（超级管理员），清 redis `sys_auth:bfs_list` 缓存。

复跑（任一机构端口）：

```bash
PRIMIHUB_WEB_URL=http://192.168.99.130:30811 PRIMIHUB_PASS=123456 \
  python3 skill.py browser whitelist add --type IP --value 10.0.0.9 --desc demo
```

截图表格显示「暂无数据」是因为验证后已用 API 清空测试记录。
