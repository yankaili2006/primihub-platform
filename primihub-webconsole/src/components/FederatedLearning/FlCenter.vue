<template>
  <div class="app-container">
    <el-tabs v-model="activeTab" type="card">
      <el-tab-pane label="联邦学习任务" name="tasks" />
      <el-tab-pane label="建模工作台" name="workbench" />
      <el-tab-pane label="参数调优" name="tuning" />
      <el-tab-pane label="训练迭代" name="iteration" />
      <el-tab-pane label="训练报告" name="report" />
      <el-tab-pane label="日志记录" name="logs" />
    </el-tabs>

    <fl-task-list v-show="activeTab === 'tasks'" :project-id="projectId" />

    <!-- 真实工作台在独立页面（modelingWorkbench，真后端），这里只做入口不摆假表单 -->
    <div v-show="activeTab === 'workbench'">
      <el-card>
        <div slot="header"><span>联邦建模工作台</span></div>
        <p style="color: #606266;">
          联邦建模工作台（数据集选择 / 特征配置 / 模型配置 / 工作流编排）已有独立的真实页面，
          请在其中完成建模配置并发起训练。
        </p>
        <el-button type="primary" icon="el-icon-right" @click="$router.push('/FederatedLearning/modelingWorkbench')">前往联邦建模工作台</el-button>
      </el-card>
    </div>

    <!-- 惰性挂载：切到对应 tab 才初始化，避免一进页面 5 组请求齐发 -->
    <fl-tuning v-if="visited.tuning" v-show="activeTab === 'tuning'" :project-id="projectId" />
    <fl-iteration v-if="visited.iteration" v-show="activeTab === 'iteration'" :project-id="projectId" />
    <fl-report v-if="visited.report" v-show="activeTab === 'report'" :project-id="projectId" />
    <fl-logs v-if="visited.logs" v-show="activeTab === 'logs'" :project-id="projectId" />
  </div>
</template>

<script>
import FlTaskList from './FlTaskList'
import FlTuning from './FlTuning'
import FlIteration from './FlIteration'
import FlReport from './FlReport'
import FlLogs from './FlLogs'

export default {
  name: 'FlCenter',
  components: { FlTaskList, FlTuning, FlIteration, FlReport, FlLogs },
  props: {
    projectId: { type: [String, Number], default: null }
  },
  data() {
    return {
      activeTab: 'tasks',
      visited: { tuning: false, iteration: false, report: false, logs: false }
    }
  },
  watch: {
    activeTab(val) {
      if (val in this.visited) this.visited[val] = true
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
