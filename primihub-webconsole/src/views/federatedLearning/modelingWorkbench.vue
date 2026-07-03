<template>
  <div class="app-container">
    <el-page-header content="联邦建模工作台" style="margin-bottom: 20px;" @back="goBack" />

    <el-row :gutter="10" style="margin-bottom: 12px;">
      <el-col :span="6"><el-card shadow="never" body-style="padding:10px 16px;"><div class="ov"><span>工作流总数</span><b>{{ overview.totalWorkflows || 0 }}</b></div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" body-style="padding:10px 16px;"><div class="ov"><span>执行成功</span><b style="color:#67C23A">{{ overview.success || 0 }}</b></div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" body-style="padding:10px 16px;"><div class="ov"><span>草稿</span><b>{{ overview.draft || 0 }}</b></div></el-card></el-col>
      <el-col :span="6"><el-card shadow="never" body-style="padding:10px 16px;"><div class="ov"><span>失败</span><b style="color:#F56C6C">{{ overview.failed || 0 }}</b></div></el-card></el-col>
    </el-row>

    <el-row :gutter="20">
      <el-col :span="6">
        <el-card class="component-panel">
          <div slot="header"><span>组件库</span></div>
          <el-collapse v-model="activeNames">
            <el-collapse-item title="数据处理" name="1">
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'dataLoader')"><i class="el-icon-upload2" /> 数据加载</div>
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'dataPreprocess')"><i class="el-icon-setting" /> 数据预处理</div>
            </el-collapse-item>
            <el-collapse-item title="模型训练" name="2">
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'logisticRegression')"><i class="el-icon-data-line" /> 逻辑回归</div>
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'neuralNetwork')"><i class="el-icon-connection" /> 神经网络</div>
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'xgboost')"><i class="el-icon-data-analysis" /> XGBoost</div>
            </el-collapse-item>
            <el-collapse-item title="模型评估" name="3">
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'evaluation')"><i class="el-icon-pie-chart" /> 模型评估</div>
            </el-collapse-item>
          </el-collapse>
          <div style="margin-top:16px;">
            <div style="font-size:13px;color:#606266;margin-bottom:6px;">已保存工作流</div>
            <el-select v-model="currentWorkflowId" size="mini" placeholder="加载已保存的工作流" clearable style="width:100%;" @change="handleLoad">
              <el-option v-for="w in savedWorkflows" :key="w.workflowId" :label="w.workflowName + '（' + statusLabel(w.status) + '）'" :value="w.workflowId" />
            </el-select>
          </div>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card class="canvas-panel">
          <div slot="header">
            <span>工作流画布</span>
            <el-button style="float: right; padding: 3px 0" type="text" @click="handleClear">清空</el-button>
          </div>
          <div class="canvas" @drop="handleDrop" @dragover.prevent>
            <div v-if="workflow.length === 0" class="canvas-tip">从左侧拖拽组件到此处编排联邦建模工作流</div>
            <div v-for="(node, index) in workflow" :key="index" class="workflow-node" :style="{ left: node.x + 'px', top: node.y + 'px' }">
              <div class="node-header">
                <i :class="node.icon" /> {{ node.label }}
                <i class="el-icon-close" @click="removeNode(index)" />
              </div>
              <div class="node-body">
                <el-form size="mini">
                  <el-form-item v-for="param in node.params" :key="param.name" :label="param.label">
                    <el-input v-model="param.value" :placeholder="param.placeholder" />
                  </el-form-item>
                </el-form>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card class="config-panel">
          <div slot="header"><span>配置</span></div>
          <el-form label-width="100px" size="small">
            <el-form-item label="任务名称"><el-input v-model="taskConfig.name" placeholder="请输入任务名称" /></el-form-item>
            <el-form-item label="参与方">
              <el-select v-model="taskConfig.participants" multiple placeholder="选择参与方" style="width: 100%;">
                <el-option v-for="p in participantList" :key="p.id" :label="p.name" :value="p.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="训练轮次"><el-input-number v-model="taskConfig.rounds" :min="1" :max="1000" /></el-form-item>
            <el-form-item label="学习率"><el-input-number v-model="taskConfig.learningRate" :min="0.001" :max="1" :step="0.001" /></el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="running" @click="handleRun">运行</el-button>
              <el-button @click="handleSave">保存</el-button>
              <el-button v-if="currentWorkflowId" type="danger" plain size="small" @click="handleDelete">删除</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card style="margin-top: 20px;">
          <div slot="header"><span>运行日志</span></div>
          <div class="log-panel">
            <div v-if="logs.length === 0" style="color:#999;">暂无日志，运行后展示真实执行日志</div>
            <div v-for="(log, index) in logs" :key="index" class="log-item">
              <span class="log-time">{{ log.createDate }}</span>
              <span :class="'log-' + (log.logLevel || 'info')">{{ log.logContent }}</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import {
  flWorkbenchOverview, flWorkbenchOptions, flWorkflowList,
  flWorkflowGet, flWorkflowSave, flWorkflowRun, flWorkflowLogs, flWorkflowDelete
} from '@/api/federatedLearning'

export default {
  name: 'FederatedModelingWorkbench',
  data() {
    return {
      activeNames: ['1', '2', '3'],
      running: false,
      workflow: [],
      taskConfig: { name: '', participants: [], rounds: 100, learningRate: 0.01 },
      logs: [],
      overview: {},
      participantList: [],
      datasetList: [],
      savedWorkflows: [],
      currentWorkflowId: '',
      componentTypes: {
        dataLoader: { label: '数据加载', icon: 'el-icon-upload2', params: [{ name: 'path', label: '数据路径', value: '', placeholder: '输入数据路径' }] },
        dataPreprocess: { label: '数据预处理', icon: 'el-icon-setting', params: [{ name: 'method', label: '预处理方法', value: '', placeholder: '标准化/归一化' }] },
        logisticRegression: { label: '逻辑回归', icon: 'el-icon-data-line', params: [{ name: 'penalty', label: '正则化', value: 'l2', placeholder: 'l1/l2' }] },
        neuralNetwork: { label: '神经网络', icon: 'el-icon-connection', params: [{ name: 'layers', label: '隐藏层', value: '64,32', placeholder: '64,32,16' }] },
        xgboost: { label: 'XGBoost', icon: 'el-icon-data-analysis', params: [{ name: 'depth', label: '树深度', value: '6', placeholder: '树的最大深度' }] },
        evaluation: { label: '模型评估', icon: 'el-icon-pie-chart', params: [{ name: 'metrics', label: '评估指标', value: 'accuracy', placeholder: 'accuracy/auc' }] }
      }
    }
  },
  mounted() {
    this.loadOverview()
    this.loadOptions()
    this.loadWorkflows()
  },
  methods: {
    goBack() { this.$router.go(-1) },
    statusLabel(s) { return { 0: '草稿', 1: '运行中', 2: '成功', 3: '失败' }[s] || '草稿' },
    async loadOverview() {
      try { const res = await flWorkbenchOverview(); if (res.code === 0) this.overview = res.result || {} } catch (e) { console.error(e) }
    },
    async loadOptions() {
      try { const res = await flWorkbenchOptions({}); if (res.code === 0 && res.result) { this.participantList = res.result.participants || []; this.datasetList = res.result.datasets || [] } } catch (e) { console.error(e) }
    },
    async loadWorkflows() {
      try { const res = await flWorkflowList({ pageNo: 1, pageSize: 50 }); if (res.code === 0 && res.result) this.savedWorkflows = res.result.list || [] } catch (e) { console.error(e) }
    },
    async handleLoad(workflowId) {
      if (!workflowId) return
      try {
        const res = await flWorkflowGet(workflowId)
        if (res.code === 0 && res.result) {
          const w = res.result
          this.taskConfig = { name: w.workflowName, participants: this.parseArr(w.participants), rounds: w.rounds || 100, learningRate: w.learningRate || 0.01 }
          this.workflow = this.parseArr(w.nodes)
          const lg = await flWorkflowLogs(workflowId)
          this.logs = (lg.code === 0 && lg.result) ? lg.result : []
        }
      } catch (e) { console.error(e) }
    },
    parseArr(v) { if (!v) return []; if (Array.isArray(v)) return v; try { return JSON.parse(v) } catch (e) { return [] } },
    handleDragStart(event, type) { event.dataTransfer.setData('componentType', type) },
    handleDrop(event) {
      event.preventDefault()
      const type = event.dataTransfer.getData('componentType')
      const component = this.componentTypes[type]
      if (component) {
        this.workflow.push({ type, label: component.label, icon: component.icon, params: JSON.parse(JSON.stringify(component.params)), x: event.offsetX - 50, y: event.offsetY - 30 })
      }
    },
    removeNode(index) { this.workflow.splice(index, 1) },
    handleClear() { this.$confirm('确定清空工作流?', '提示', { type: 'warning' }).then(() => { this.workflow = [] }).catch(() => {}) },
    payload() {
      return {
        workflowId: this.currentWorkflowId || undefined,
        workflowName: this.taskConfig.name,
        participants: this.taskConfig.participants,
        rounds: this.taskConfig.rounds,
        learningRate: this.taskConfig.learningRate,
        nodes: this.workflow
      }
    },
    async handleSave() {
      if (!this.taskConfig.name) { this.$message.warning('请输入任务名称'); return }
      try {
        const res = await flWorkflowSave(this.payload())
        if (res.code === 0) {
          this.currentWorkflowId = res.result.workflowId
          this.$message.success('工作流已保存')
          this.loadWorkflows(); this.loadOverview()
        } else { this.$message.error(res.msg || '保存失败') }
      } catch (e) { this.$message.error('保存失败') }
    },
    async handleRun() {
      if (this.workflow.length === 0) { this.$message.warning('请先添加组件到工作流'); return }
      if (!this.taskConfig.name) { this.$message.warning('请输入任务名称'); return }
      this.running = true
      try {
        const res = await flWorkflowRun(this.payload())
        if (res.code === 0 && res.result) {
          this.currentWorkflowId = res.result.workflowId
          this.logs = res.result.logs || []
          this.$message.success('任务执行成功')
          this.loadWorkflows(); this.loadOverview()
        } else { this.$message.error(res.msg || '执行失败') }
      } catch (e) { this.$message.error('执行失败') } finally { this.running = false }
    },
    async handleDelete() {
      if (!this.currentWorkflowId) return
      this.$confirm('确定删除该工作流?', '提示', { type: 'warning' }).then(async() => {
        const res = await flWorkflowDelete(this.currentWorkflowId)
        if (res.code === 0) {
          this.$message.success('已删除')
          this.currentWorkflowId = ''; this.workflow = []; this.logs = []
          this.taskConfig = { name: '', participants: [], rounds: 100, learningRate: 0.01 }
          this.loadWorkflows(); this.loadOverview()
        } else { this.$message.error(res.msg || '删除失败') }
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.ov { display:flex; justify-content:space-between; align-items:center; }
.ov b { font-size: 20px; }
.component-panel, .canvas-panel, .config-panel { height: 600px; overflow-y: auto; }
.component-item { padding: 10px; margin: 5px 0; background: #f0f2f5; border-radius: 4px; cursor: move; transition: all 0.3s; }
.component-item:hover { background: #e6e8eb; }
.canvas { position: relative; height: 500px; background: #fafafa; border: 2px dashed #ddd; border-radius: 4px; }
.canvas-tip { position:absolute; top:50%; left:50%; transform:translate(-50%,-50%); color:#bbb; }
.workflow-node { position: absolute; width: 200px; background: white; border: 1px solid #ddd; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.node-header { padding: 8px; background: #409EFF; color: white; border-radius: 4px 4px 0 0; display: flex; justify-content: space-between; align-items: center; }
.node-header .el-icon-close { cursor: pointer; }
.node-body { padding: 10px; }
.log-panel { height: 200px; overflow-y: auto; background: #f5f5f5; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px; }
.log-item { margin: 5px 0; }
.log-time { color: #999; margin-right: 10px; }
.log-info { color: #409EFF; }
.log-success { color: #67C23A; }
.log-warning { color: #E6A23C; }
.log-error { color: #F56C6C; }
</style>
