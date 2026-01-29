<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="联邦建模工作台" style="margin-bottom: 20px;" />

    <el-row :gutter="20">
      <el-col :span="6">
        <el-card class="component-panel">
          <div slot="header"><span>组件库</span></div>
          <el-collapse v-model="activeNames">
            <el-collapse-item title="数据处理" name="1">
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'dataLoader')">
                <i class="el-icon-upload2"></i> 数据加载
              </div>
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'dataPreprocess')">
                <i class="el-icon-setting"></i> 数据预处理
              </div>
            </el-collapse-item>
            <el-collapse-item title="模型训练" name="2">
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'logisticRegression')">
                <i class="el-icon-data-line"></i> 逻辑回归
              </div>
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'neuralNetwork')">
                <i class="el-icon-connection"></i> 神经网络
              </div>
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'xgboost')">
                <i class="el-icon-data-analysis"></i> XGBoost
              </div>
            </el-collapse-item>
            <el-collapse-item title="模型评估" name="3">
              <div class="component-item" draggable="true" @dragstart="handleDragStart($event, 'evaluation')">
                <i class="el-icon-pie-chart"></i> 模型评估
              </div>
            </el-collapse-item>
          </el-collapse>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card class="canvas-panel">
          <div slot="header">
            <span>工作流画布</span>
            <el-button style="float: right; padding: 3px 0" type="text" @click="handleClear">清空</el-button>
          </div>
          <div class="canvas" @drop="handleDrop" @dragover.prevent>
            <div v-for="(node, index) in workflow" :key="index" class="workflow-node" :style="{ left: node.x + 'px', top: node.y + 'px' }">
              <div class="node-header">
                <i :class="node.icon"></i> {{ node.label }}
                <i class="el-icon-close" @click="removeNode(index)"></i>
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
            <el-form-item label="任务名称">
              <el-input v-model="taskConfig.name" placeholder="请输入任务名称" />
            </el-form-item>
            <el-form-item label="参与方">
              <el-select v-model="taskConfig.participants" multiple placeholder="选择参与方" style="width: 100%;">
                <el-option label="参与方A" value="partyA" />
                <el-option label="参与方B" value="partyB" />
                <el-option label="参与方C" value="partyC" />
              </el-select>
            </el-form-item>
            <el-form-item label="训练轮次">
              <el-input-number v-model="taskConfig.rounds" :min="1" :max="1000" />
            </el-form-item>
            <el-form-item label="学习率">
              <el-input-number v-model="taskConfig.learningRate" :min="0.001" :max="1" :step="0.001" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="running" @click="handleRun">运行</el-button>
              <el-button @click="handleSave">保存</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card style="margin-top: 20px;">
          <div slot="header"><span>运行日志</span></div>
          <div class="log-panel">
            <div v-for="(log, index) in logs" :key="index" class="log-item">
              <span class="log-time">{{ log.time }}</span>
              <span :class="'log-' + log.level">{{ log.message }}</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
export default {
  name: 'FederatedModelingWorkbench',
  data() {
    return {
      activeNames: ['1', '2', '3'],
      running: false,
      workflow: [],
      taskConfig: {
        name: '',
        participants: [],
        rounds: 100,
        learningRate: 0.01
      },
      logs: [],
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
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleDragStart(event, type) {
      event.dataTransfer.setData('componentType', type)
    },
    handleDrop(event) {
      event.preventDefault()
      const type = event.dataTransfer.getData('componentType')
      const component = this.componentTypes[type]
      if (component) {
        this.workflow.push({
          type,
          label: component.label,
          icon: component.icon,
          params: JSON.parse(JSON.stringify(component.params)),
          x: event.offsetX - 50,
          y: event.offsetY - 30
        })
      }
    },
    removeNode(index) {
      this.workflow.splice(index, 1)
    },
    handleClear() {
      this.$confirm('确定清空工作流?', '提示', { type: 'warning' }).then(() => {
        this.workflow = []
      })
    },
    handleRun() {
      if (this.workflow.length === 0) {
        this.$message.warning('请先添加组件到工作流')
        return
      }
      if (!this.taskConfig.name) {
        this.$message.warning('请输入任务名称')
        return
      }
      this.running = true
      this.logs = []
      this.addLog('info', '开始执行联邦建模任务...')
      setTimeout(() => {
        this.addLog('success', '数据加载完成')
      }, 1000)
      setTimeout(() => {
        this.addLog('success', '模型训练中... (1/100)')
      }, 2000)
      setTimeout(() => {
        this.addLog('success', '模型训练完成')
        this.addLog('success', '任务执行成功')
        this.running = false
      }, 4000)
    },
    handleSave() {
      this.$message.success('工作流已保存')
    },
    addLog(level, message) {
      this.logs.push({
        time: new Date().toLocaleTimeString(),
        level,
        message
      })
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.component-panel, .canvas-panel, .config-panel { height: 600px; overflow-y: auto; }
.component-item {
  padding: 10px;
  margin: 5px 0;
  background: #f0f2f5;
  border-radius: 4px;
  cursor: move;
  transition: all 0.3s;
}
.component-item:hover { background: #e6e8eb; }
.canvas {
  position: relative;
  height: 500px;
  background: #fafafa;
  border: 2px dashed #ddd;
  border-radius: 4px;
}
.workflow-node {
  position: absolute;
  width: 200px;
  background: white;
  border: 1px solid #ddd;
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.node-header {
  padding: 8px;
  background: #409EFF;
  color: white;
  border-radius: 4px 4px 0 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.node-header .el-icon-close {
  cursor: pointer;
}
.node-body { padding: 10px; }
.log-panel {
  height: 200px;
  overflow-y: auto;
  background: #f5f5f5;
  padding: 10px;
  border-radius: 4px;
  font-family: monospace;
  font-size: 12px;
}
.log-item { margin: 5px 0; }
.log-time { color: #999; margin-right: 10px; }
.log-info { color: #409EFF; }
.log-success { color: #67C23A; }
.log-error { color: #F56C6C; }
</style>
