# 执行按钮无响应问题修复

## 问题描述

在"项目管理 > 项目详情 > 创建任务"页面，点击执行按钮后没有任何响应，用户无法运行任务。

## 根本原因分析

通过代码审查发现以下问题：

### 1. 缺少错误处理机制

**文件**: `src/components/TaskCanvas/index.vue`

#### 问题1: `run()` 方法缺少错误捕获

原代码（第813-849行）：
```javascript
async run() {
  this.isDraft = 1
  await this.saveFn()
  this.checkRunValidated()
  if (!this.modelRunValidated) {
    this.isDraft = 0
    return
  }
  runTaskModel({ modelId: this.currentModelId }).then(res => {
    // 处理响应...
  })
  // ❌ 缺少 .catch() 处理网络错误或API异常
}
```

**问题**：
- 如果 `saveFn()` 抛出异常，整个方法会静默失败
- 如果 `runTaskModel()` API调用失败（网络错误、超时等），Promise被拒绝但没有被捕获
- 用户看不到任何错误提示，按钮看起来"没有响应"

#### 问题2: `saveFn()` 方法错误处理不完善

原代码（第1087-1204行）：
```javascript
async saveFn() {
  // ... 准备数据
  const res = await saveModelAndComponent(this.saveParams)
  if (res.code === 0) {
    this.currentModelId = res.result.modelId
    // ...
  } else {
    this.$message({
      message: res.msg,
      type: 'error'
    })
    // ❌ 显示错误但不抛出异常，调用者无法知道保存失败
  }
  this.isClear = false
}
```

**问题**：
- 保存失败时只显示错误消息，但不抛出异常
- 调用者（`run()` 方法）无法知道保存是否成功
- 如果保存失败，任务仍会尝试执行，导致更多错误

## 修复方案

### 修复1: 为 `run()` 方法添加完整的错误处理

**文件**: `src/components/TaskCanvas/index.vue` (第813-865行)

```javascript
async run() {
  console.log('TaskCanvas: run method called')
  try {
    // 运行前触发保存
    this.isDraft = 1
    console.log('TaskCanvas: calling saveFn before run')
    await this.saveFn()
    console.log('TaskCanvas: saveFn completed, modelId:', this.currentModelId)
    this.checkRunValidated()
    if (!this.modelRunValidated) {
      console.log('TaskCanvas: validation failed, aborting run')
      this.isDraft = 0
      return
    }
    console.log('TaskCanvas: validation passed, calling runTaskModel API')
    runTaskModel({ modelId: this.currentModelId }).then(res => {
      console.log('TaskCanvas: runTaskModel response:', res)
      if (res.code !== 0) {
        if (res.code === 1007) {
          this.dialogVisible = true
          this.runTaskErrorMessage = res.msg
        } else {
          this.$message({
            message: res.msg,
            type: 'error'
          })
        }
        return
      } else {
        this.currentTaskId = res.result.taskId
        this.modelStartRun = true
        this.$notify.closeAll()
        this.$notify({
          message: '开始运行',
          type: 'info',
          duration: 5000
        })
        setTimeout(() => {
          this.toModelDetail(this.currentTaskId)
        }, 1000)
      }
    }).catch(err => {
      // ✅ 新增：捕获API调用错误
      console.error('运行任务失败:', err)
      this.$message({
        message: err.message || '运行任务失败，请稍后重试',
        type: 'error'
      })
      this.isDraft = 0
    })
  } catch (error) {
    // ✅ 新增：捕获整个方法的异常
    console.error('运行任务异常:', error)
    this.$message({
      message: error.message || '运行任务异常，请检查网络连接或稍后重试',
      type: 'error'
    })
    this.isDraft = 0
  }
},
```

**改进点**：
1. 添加外层 `try-catch` 捕获 `saveFn()` 和其他同步代码的异常
2. 为 `runTaskModel()` 添加 `.catch()` 处理API调用失败
3. 错误发生时重置 `isDraft` 状态
4. 添加详细的 `console.log` 用于调试
5. 向用户显示友好的错误提示

### 修复2: 改进 `saveFn()` 的错误处理

**文件**: `src/components/TaskCanvas/index.vue` (第1187-1215行)

```javascript
// dataSet component in the second
this.checkOrder()
console.log('saveParams', modelComponents)
this.$emit('saveParams', this.saveParams.param)
try {
  const res = await saveModelAndComponent(this.saveParams)
  if (res.code === 0) {
    this.currentModelId = res.result.modelId
    if (this.isCopy) {
      this.$route.query.modelId = this.currentModelId
    }
  } else {
    this.$message({
      message: res.msg,
      type: 'error'
    })
    // ✅ 新增：抛出异常让调用者知道保存失败
    throw new Error(res.msg || '保存失败')
  }
} catch (error) {
  // ✅ 新增：捕获并重新抛出异常
  console.error('保存模型失败:', error)
  this.$message({
    message: error.message || '保存模型失败，请检查网络连接或稍后重试',
    type: 'error'
  })
  throw error
} finally {
  // ✅ 改进：使用 finally 确保状态总是被重置
  this.isClear = false
}
```

**改进点**：
1. 添加 `try-catch-finally` 块
2. 保存失败时抛出异常，让调用者能够感知
3. 使用 `finally` 确保 `isClear` 状态总是被重置
4. 添加错误日志和用户提示

### 修复3: 添加调试日志

**文件**: `src/components/TaskCanvas/ToolBar/index.vue` (第72-75行)

```javascript
// 运行
runFn() {
  console.log('ToolBar: runFn clicked, emitting run event')
  this.$emit('run')
},
```

**改进点**：
- 添加日志确认按钮点击事件被触发
- 帮助诊断事件绑定问题

## 测试步骤

### 1. 正常流程测试

1. 启动前端开发服务器
2. 打开浏览器开发者工具（F12）
3. 导航到：项目管理 > 项目详情 > 创建任务
4. 配置任务参数（选择数据集、模型等）
5. 点击执行按钮
6. **预期结果**：
   - 控制台显示日志：`ToolBar: runFn clicked, emitting run event`
   - 控制台显示日志：`TaskCanvas: run method called`
   - 控制台显示日志：`TaskCanvas: calling saveFn before run`
   - 控制台显示日志：`TaskCanvas: saveFn completed, modelId: xxx`
   - 控制台显示日志：`TaskCanvas: validation passed, calling runTaskModel API`
   - 控制台显示日志：`TaskCanvas: runTaskModel response: {...}`
   - 页面显示通知："开始运行"
   - 自动跳转到任务详情页

### 2. 验证失败场景测试

#### 场景A: 画布为空
1. 创建新任务但不添加任何组件
2. 点击执行按钮
3. **预期结果**：显示错误提示"当前画布为空，无法运行，请绘制"

#### 场景B: 缺少必填参数
1. 创建任务但不选择数据集
2. 点击执行按钮
3. **预期结果**：
   - 控制台显示：`TaskCanvas: validation failed, aborting run`
   - 显示错误提示："请选择发起方数据集"或类似验证错误

#### 场景C: 网络错误
1. 打开浏览器开发者工具 > Network 标签
2. 启用"Offline"模式模拟网络断开
3. 配置好任务后点击执行按钮
4. **预期结果**：
   - 控制台显示错误日志：`运行任务失败: ...`
   - 显示错误提示："运行任务失败，请稍后重试"或"运行任务异常，请检查网络连接或稍后重试"

#### 场景D: API返回错误
1. 配置任务时选择不可用的资源
2. 点击执行按钮
3. **预期结果**：
   - 如果是1007错误：显示对话框"数据资源不可用"
   - 其他错误：显示错误消息

### 3. 浏览器兼容性测试

在以下浏览器中测试：
- Chrome/Edge (最新版本)
- Firefox (最新版本)
- Safari (如果在Mac上)

## 回滚方案

如果修复导致新问题，可以通过以下命令回滚：

```bash
cd /mnt/data1/github/primihub-platform/primihub-webconsole
git checkout HEAD -- src/components/TaskCanvas/index.vue
git checkout HEAD -- src/components/TaskCanvas/ToolBar/index.vue
```

## 后续优化建议

1. **移除调试日志**：在生产环境中，可以使用条件编译移除 `console.log`
2. **统一错误处理**：考虑创建全局错误处理器
3. **添加单元测试**：为 `run()` 和 `saveFn()` 方法添加单元测试
4. **改进用户体验**：
   - 添加加载状态指示器
   - 在按钮上显示禁用状态（运行中时）
   - 添加重试机制

## 相关文件

- `src/components/TaskCanvas/index.vue` - 主要修复文件
- `src/components/TaskCanvas/ToolBar/index.vue` - 添加调试日志
- `src/api/model.js` - API定义（未修改）
- `src/utils/request.js` - 请求拦截器（未修改）

## 修复日期

2026-03-08
