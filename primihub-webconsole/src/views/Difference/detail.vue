<template>
  <div class="container">
    <el-page-header content="联邦求差任务详情" style="margin-bottom: 20px;" @back="$router.push({name:'DifferenceList'})" />
    <el-card v-loading="loading">
      <el-steps :active="stepActive" align-center finish-status="success" style="margin-bottom: 32px;">
        <el-step title="提交任务" icon="el-icon-upload" />
        <el-step :title="runningTitle" icon="el-icon-loading" />
        <el-step :title="resultTitle" icon="el-icon-document" />
      </el-steps>
      <el-alert v-if="taskData.taskState === 1" title="任务已完成" type="success" :closable="false" show-icon style="margin-bottom: 20px;" />
      <el-alert v-if="taskData.taskState === 3" title="任务失败" type="error" :closable="false" show-icon style="margin-bottom: 20px;" />
      <el-alert v-if="taskData.taskState === 4" title="任务已取消" type="info" :closable="false" show-icon style="margin-bottom: 20px;" />
      <el-alert v-if="taskData.taskState === 2" title="任务运行中" type="warning" :closable="false" show-icon style="margin-bottom: 20px;" />

      <el-descriptions :column="2" border style="margin-bottom: 24px;" title="基础信息">
        <el-descriptions-item label="任务名称">{{ taskData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="任务ID"><code>{{ taskData.taskId }}</code></el-descriptions-item>
        <el-descriptions-item label="结果名称">{{ taskData.resultName }}</el-descriptions-item>
        <el-descriptions-item label="求差方向">
          <el-tag :type="taskData.differenceDirection === 0 ? 'primary' : 'warning'" size="small">
            {{ taskData.differenceDirection === 0 ? '本机构 - 对方' : '对方 - 本机构' }}
          </el-tag>
        </el-descriptions-item>
      </el-descriptions>
      <el-descriptions :column="2" border style="margin-bottom: 24px;" title="数据配置">
        <el-descriptions-item label="发起方">{{ taskData.ownOrganName }}</el-descriptions-item>
        <el-descriptions-item label="协作方">{{ taskData.otherOrganName }}</el-descriptions-item>
        <el-descriptions-item label="发起方资源">
          <el-link type="primary" @click="toResourceDetail(taskData.ownResourceId)">{{ taskData.ownResourceName }}</el-link>
        </el-descriptions-item>
        <el-descriptions-item label="协作方资源">
          <el-link type="primary" @click="toResourceDetail(taskData.otherResourceId)">{{ taskData.otherResourceName }}</el-link>
        </el-descriptions-item>
        <el-descriptions-item label="发起方关联键">{{ taskData.ownKeyword }}</el-descriptions-item>
        <el-descriptions-item label="协作方关联键">{{ taskData.otherKeyword }}</el-descriptions-item>
      </el-descriptions>
      <el-descriptions :column="2" border style="margin-bottom: 24px;" title="实现方法">
        <el-descriptions-item label="实现方法">
          <el-tag size="small">{{ taskData.tag | tagFilter }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item v-if="taskData.tag === 2" label="可信计算节点">{{ taskData.teeOrganName }}</el-descriptions-item>
      </el-descriptions>
      <el-descriptions :column="2" border title="执行详情">
        <el-descriptions-item label="发起时间">{{ taskData.createDate }}</el-descriptions-item>
        <el-descriptions-item label="任务耗时">{{ taskData.consuming | timeFilter }}</el-descriptions-item>
        <el-descriptions-item label="任务状态">
          <el-tag :type="statusType" :effect="taskData.taskState === 2 ? 'dark' : 'light'">
            <i v-if="taskData.taskState === 2" class="el-icon-loading" />
            {{ taskData.taskState | taskStatusFilter }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item v-if="taskData.taskState === 1" label="操作">
          <el-button type="primary" size="small" icon="el-icon-download" @click="handleDownloadResult">下载结果</el-button>
        </el-descriptions-item>
      </el-descriptions>
    </el-card>
  </div>
</template>

<script>
import { getDifferenceTaskDetails, downloadDifferenceTask } from '@/api/difference'

export default {
  name: 'DifferenceDetail',
  filters: {
    tagFilter(state) { return { 0: 'ECDH', 1: 'KKRT', 2: 'TEE' }[state] || '未知' }
  },
  data() {
    return {
      loading: false, taskData: {}, taskId: this.$route.params.id, timer: null
    }
  },
  computed: {
    statusType() { return { 0: 'info', 1: 'success', 2: 'warning', 3: 'danger', 4: 'info' }[this.taskData.taskState] || 'info' },
    stepActive() {
      const s = this.taskData.taskState
      if (s === 1) return 3
      if (s === 2) return 1
      if (s === 3 || s === 4) return 3
      return 0
    },
    runningTitle() { return this.taskData.taskState === 2 ? '任务运行中' : '任务运行' },
    resultTitle() {
      if (this.taskData.taskState === 1) return '运行成功'
      if (this.taskData.taskState === 3) return '运行失败'
      if (this.taskData.taskState === 4) return '任务取消'
      return '等待结果'
    }
  },
  created() {
    this.fetchData()
    this.timer = setInterval(() => this.fetchData(), 3000)
  },
  destroyed() { clearInterval(this.timer) },
  methods: {
    async fetchData() {
      this.loading = true
      try {
        const res = await getDifferenceTaskDetails({ taskId: this.taskId })
        if (res.code === 0) {
          this.taskData = res.result
          if ([1, 3, 4].includes(this.taskData.taskState)) clearInterval(this.timer)
        } else { clearInterval(this.timer) }
      } catch (e) { clearInterval(this.timer) }
      this.loading = false
    },
    async handleDownloadResult() {
      try {
        const res = await downloadDifferenceTask({ taskId: this.taskId })
        const blob = new Blob([res])
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url; link.download = `求差结果_${this.taskData.taskName}_${Date.now()}.csv`
        link.click(); window.URL.revokeObjectURL(url)
        this.$message.success('下载成功')
      } catch (e) { this.$message.error('下载失败') }
    },
    toResourceDetail(id) { this.$router.push({ name: 'ResourceDetail', params: { id } }) }
  }
}
</script>

<style lang="scss" scoped>
.container { overflow: hidden; background: #fff; padding: 36px; border-radius: 8px; }
code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-size: 12px; }
</style>
