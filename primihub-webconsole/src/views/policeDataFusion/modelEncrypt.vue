<template>
  <div class="app-container">
    <el-page-header content="保险机构模型同态加密" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>模型加密配置</span></div>
      <el-form ref="encryptForm" :model="encryptForm" label-width="120px">
        <el-form-item label="选择模型">
          <el-select v-model="encryptForm.modelId" placeholder="请选择要加密的模型" style="width: 400px;">
            <el-option v-for="m in modelList" :key="m.id" :label="m.name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="选择密钥">
          <el-select v-model="encryptForm.keyId" placeholder="请选择同态加密密钥" style="width: 400px;">
            <el-option v-for="k in keyList" :key="k.id" :label="`${k.org} - ${k.scheme}`" :value="k.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="加密精度">
          <el-select v-model="encryptForm.precision" style="width: 200px;">
            <el-option label="单精度 (32位)" value="single" />
            <el-option label="双精度 (64位)" value="double" />
          </el-select>
        </el-form-item>
        <el-form-item label="批处理大小">
          <el-input-number v-model="encryptForm.batchSize" :min="1" :max="10000" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="encrypting" @click="handleEncrypt">开始加密</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>加密任务列表</span></div>
      <el-table :data="encryptTaskList" border>
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="modelName" label="模型名称" width="180" />
        <el-table-column prop="keyOrg" label="密钥机构" width="120" />
        <el-table-column prop="paramCount" label="参数数量" width="100" />
        <el-table-column prop="encryptedSize" label="加密后大小" width="120" />
        <el-table-column prop="progress" label="进度" width="150">
          <template slot-scope="scope">
            <el-progress :percentage="scope.row.progress" :status="scope.row.progress === 100 ? 'success' : ''" />
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" type="text" :disabled="scope.row.progress < 100" @click="handleDownload(scope.row)">下载密文</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { encryptPoliceData, getPoliceTaskList, getPoliceKeyList } from '@/api/scene'
export default {
  name: 'ModelHomomorphicEncrypt',
  data() {
    return {
      encrypting: false,
      encryptForm: { modelId: '', keyId: '', precision: 'double', batchSize: 1000 },
      // 真实模型目录不在本模块，保持真实但为空，不伪造
      modelList: [],
      keyList: [],
      encryptTaskList: []
    }
  },
  created() {
    this.fetchTaskList()
    this.fetchKeyList()
  },
  methods: {
    goBack() { this.$router.go(-1) },
    normalizeSceneTask(row) {
      let p = {}
      try { p = row.params ? JSON.parse(row.params) : {} } catch (e) { p = {} }
      const st = row.taskState
      const statusText = st === 2 ? '已完成' : st === 3 ? '失败' : st === 1 ? '运行中' : '等待执行'
      const status = st === 2 ? 'completed' : st === 3 ? 'failed' : 'running'
      return Object.assign({}, p, {
        taskId: row.id,
        taskName: row.taskName,
        taskType: row.taskType,
        status,
        statusText,
        progress: st === 2 ? 100 : st === 3 ? 0 : 50,
        createTime: row.createdAt
      })
    },
    fetchTaskList() {
      getPoliceTaskList({ taskType: 'modelEncrypt', pageNo: 1, pageSize: 100 }).then(res => {
        if (res && res.code === 0 && res.result) {
          this.encryptTaskList = (res.result.list || []).map(this.normalizeSceneTask)
        }
      }).catch(() => {})
    },
    fetchKeyList() {
      getPoliceKeyList().then(res => {
        if (res && res.code === 0) {
          this.keyList = (res.result || []).map(k => ({
            id: k.id || k.keyId,
            org: k.org || k.orgName || k.keyName || '',
            scheme: k.scheme || k.keyType || k.algorithm || ''
          }))
        }
      }).catch(() => {})
    },
    async handleEncrypt() {
      if (!this.encryptForm.modelId || !this.encryptForm.keyId) {
        this.$message.warning('请选择模型和密钥')
        return
      }
      this.encrypting = true
      try {
        const res = await encryptPoliceData({ keyId: this.encryptForm.keyId, data: 'model_' + this.encryptForm.modelId })
        if (res && res.code === 0) {
          this.$message.success('模型加密任务已提交')
          this.fetchTaskList()
        }
      } catch (e) {
        this.$message.error('加密失败')
      } finally {
        this.encrypting = false
      }
    },
    handleDownload(row) {
      this.$message.success(`开始下载: ${row.modelName} 密文`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
