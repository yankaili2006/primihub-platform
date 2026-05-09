# PrimiHub 任务创建和执行工具

这个工具允许你通过 API 创建和执行 PrimiHub 联邦学习任务。

## 功能特性

- ✅ 创建任务配置
- ✅ 保存任务到项目
- ✅ 执行任务
- ✅ 监控任务状态
- ✅ 支持完整的任务配置（通过 JSON 文件）

## 安装依赖

```bash
pip3 install requests
```

## 使用方法

### 1. 设置环境变量（可选）

```bash
export PRIMIHUB_BASE_URL="http://100.64.0.23:30811/prod-api"
export PRIMIHUB_TOKEN="your_token_here"
export PRIMIHUB_USER_ID="your_user_id_here"
```

### 2. 获取认证信息

首先需要登录系统获取 token 和 user_id：

```bash
# 方法1: 从浏览器开发者工具获取
# 1. 打开 http://100.64.0.23:30811
# 2. 登录系统
# 3. 按 F12 打开开发者工具
# 4. 切换到 Network 标签
# 5. 刷新页面，查看任意 API 请求的 Headers
# 6. 找到 token 和 userId 字段

# 方法2: 从 localStorage 获取
# 在浏览器控制台执行:
# localStorage.getItem('token')
# JSON.parse(localStorage.getItem('userInfo')).userId
```

### 3. 创建并执行任务

#### 方式 A: 使用简化配置（快速测试）

```bash
python3 create-and-run-task.py \
  --base-url http://100.64.0.23:30811/prod-api \
  --token YOUR_TOKEN \
  --user-id YOUR_USER_ID \
  --project-id 7 \
  --task-name "测试任务" \
  --run
```

#### 方式 B: 使用完整配置文件（推荐）

```bash
# 1. 准备任务配置文件（参考 task-config-example.json）
# 2. 执行任务
python3 create-and-run-task.py \
  --base-url http://100.64.0.23:30811/prod-api \
  --token YOUR_TOKEN \
  --user-id YOUR_USER_ID \
  --project-id 7 \
  --task-name "PSI任务" \
  --config task-config-example.json \
  --run
```

### 4. 仅保存任务（不执行）

```bash
python3 create-and-run-task.py \
  --base-url http://100.64.0.23:30811/prod-api \
  --token YOUR_TOKEN \
  --user-id YOUR_USER_ID \
  --project-id 7 \
  --task-name "待执行任务" \
  --config task-config.json
```

### 5. 执行已保存的任务

```bash
python3 create-and-run-task.py \
  --base-url http://100.64.0.23:30811/prod-api \
  --token YOUR_TOKEN \
  --model-id MODEL_ID \
  --run-only
```

### 6. 监控任务状态

```bash
python3 create-and-run-task.py \
  --base-url http://100.64.0.23:30811/prod-api \
  --token YOUR_TOKEN \
  --task-id TASK_ID \
  --monitor
```

## 任务配置文件格式

任务配置文件是一个 JSON 文件，包含以下主要部分：

```json
{
  "modelComponents": [
    {
      "frontComponentId": "唯一ID",
      "componentCode": "组件代码",
      "componentName": "组件名称",
      "coordinateX": 100,
      "coordinateY": 100,
      "width": 180,
      "height": 40,
      "shape": "dag-node",
      "componentValues": [
        {"key": "参数名", "val": "参数值"}
      ],
      "input": ["输入节点ID"],
      "output": ["输出节点ID"]
    }
  ],
  "modelPointComponents": [
    {
      "frontComponentId": "连线ID",
      "shape": "edge",
      "input": {"cell": "起始节点ID", "port": "output"},
      "output": {"cell": "目标节点ID", "port": "input"}
    }
  ]
}
```

### 常用组件类型

| 组件代码 | 组件名称 | 说明 |
|---------|---------|------|
| start | 开始 | 任务起始节点 |
| dataSet | 数据集 | 数据源选择 |
| model | 模型 | 模型配置 |
| dataAlign | 数据对齐 | PSI 隐私求交 |

### 模型类型

| 类型值 | 模型名称 |
|-------|---------|
| 1 | PSI (隐私求交) |
| 3 | 逻辑回归 (LR) |
| 4 | XGBoost |
| 5 | 线性回归 |

## 从 Web UI 导出任务配置

如果你已经在 Web UI 中创建了任务，可以通过以下方式导出配置：

1. 打开浏览器开发者工具（F12）
2. 切换到 Console 标签
3. 在任务编辑页面，执行以下代码：

```javascript
// 获取当前任务配置
const canvas = document.querySelector('#flowContainer').__x6_graph__
const data = canvas.toJSON()
console.log(JSON.stringify(data, null, 2))
```

4. 复制输出的 JSON，保存为配置文件

## API 端点说明

工具使用以下 API 端点：

| 端点 | 方法 | 说明 |
|-----|------|------|
| /data/project/getProjectDetails | GET | 获取项目详情 |
| /data/model/getModelComponent | GET | 获取可用组件 |
| /data/model/saveModelAndComponent | POST | 保存任务配置 |
| /data/model/runTaskModel | GET | 执行任务 |
| /data/model/getTaskModelComponent | GET | 获取任务状态 |

## 示例输出

```
📋 获取项目详情 (ID: 7)...
✓ 项目名称: 测试项目

💾 保存任务配置...
✓ 任务配置已保存 (Model ID: 123)

▶️  执行任务 (Model ID: 123)...
✓ 任务已开始执行 (Task ID: 456)

⏳ 监控任务执行状态...
  状态: 运行中 | 已用时: 5秒
  状态: 运行中 | 已用时: 10秒
  状态: 成功 | 已用时: 15秒
✅ 任务执行成功！
```

## 故障排查

### 问题1: 认证失败

**错误**: `登录失效，请重新登录`

**解决**:
1. 确认 token 和 user_id 是否正确
2. 检查 token 是否过期（重新登录获取新 token）
3. 确认 API 基础 URL 是否正确

### 问题2: 项目不存在

**错误**: `项目不存在`

**解决**:
1. 确认项目 ID 是否正确
2. 检查用户是否有权限访问该项目

### 问题3: 数据资源不可用

**错误**: `数据资源不可用`

**解决**:
1. 检查任务配置中的资源 ID 是否正确
2. 确认资源是否已审批通过
3. 检查资源所属机构是否在线

### 问题4: 验证失败

**错误**: `请选择发起方数据集` 等验证错误

**解决**:
1. 检查任务配置是否完整
2. 确认必填字段都已填写
3. 参考 Web UI 中的任务配置

## 高级用法

### 批量创建任务

```bash
#!/bin/bash
# 批量创建多个任务

for i in {1..5}; do
  python3 create-and-run-task.py \
    --base-url http://100.64.0.23:30811/prod-api \
    --token $PRIMIHUB_TOKEN \
    --user-id $PRIMIHUB_USER_ID \
    --project-id 7 \
    --task-name "批量任务-$i" \
    --config task-config.json \
    --run

  echo "等待 10 秒后创建下一个任务..."
  sleep 10
done
```

### 定时执行任务

```bash
# 使用 cron 定时执行任务
# 编辑 crontab: crontab -e
# 添加以下行（每天凌晨 2 点执行）:

0 2 * * * cd /path/to/skills && python3 create-and-run-task.py --base-url http://100.64.0.23:30811/prod-api --token TOKEN --user-id USER_ID --project-id 7 --task-name "定时任务-$(date +\%Y\%m\%d)" --config task-config.json --run >> /var/log/primihub-task.log 2>&1
```

## 作为 Claude Code Skill 使用

如果你在 Claude Code 中使用，可以直接调用：

```bash
/create-task --project-id 7 --task-name "测试任务" --run
```

## 相关文档

- [PrimiHub 官方文档](https://docs.primihub.com)
- [API 接口文档](http://100.64.0.23:30811/doc.html)
- [任务配置示例](./task-config-example.json)

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
