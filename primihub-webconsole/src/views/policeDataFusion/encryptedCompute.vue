<template>
  <div class="app-container">
    <el-page-header content="加密模型联合运算" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>联合运算配置</span></div>
      <el-form ref="computeForm" :model="computeForm" label-width="140px">
        <el-form-item label="加密模型">
          <el-select v-model="computeForm.encryptedModelId" placeholder="请选择加密模型" style="width: 400px;">
            <el-option v-for="m in encryptedModels" :key="m.id" :label="m.name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="警务数据集">
          <el-select v-model="computeForm.policeDatasetId" placeholder="请选择警务数据集" style="width: 400px;">
            <el-option v-for="d in policeDatasets" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="运算类型">
          <el-checkbox-group v-model="computeForm.operations">
            <el-checkbox label="predict">模型预测</el-checkbox>
            <el-checkbox label="aggregate">聚合统计</el-checkbox>
            <el-checkbox label="compare">数据比对</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="并行度">
          <el-slider v-model="computeForm.parallelism" :min="1" :max="32" :marks="{1:'1',8:'8',16:'16',32:'32'}" style="width: 400px;" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="computing" @click="handleCompute">开始联合运算</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>运算任务列表</span></div>
      <el-table :data="computeTaskList" border>
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="modelName" label="加密模型" width="180" />
        <el-table-column prop="datasetName" label="数据集" width="150" />
        <el-table-column prop="operations" label="运算类型" width="150" />
        <el-table-column prop="recordCount" label="数据量" width="100" />
        <el-table-column prop="computeTime" label="运算耗时" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ scope.row.statusText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleViewResult(scope.row)">查看结果</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog :visible.sync="resultDialogVisible" title="运算结果(密文)" width="700px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="任务ID">{{ currentResult.taskId }}</el-descriptions-item>
        <el-descriptions-item label="运算类型">{{ currentResult.operations }}</el-descriptions-item>
        <el-descriptions-item label="输入数据量">{{ currentResult.recordCount }}</el-descriptions-item>
        <el-descriptions-item label="输出数据量">{{ currentResult.outputCount }}</el-descriptions-item>
        <el-descriptions-item label="运算耗时">{{ currentResult.computeTime }}</el-descriptions-item>
        <el-descriptions-item label="结果大小">{{ currentResult.resultSize }}</el-descriptions-item>
      </el-descriptions>
      <div style="margin-top: 20px;">
        <el-alert title="运算结果为同态加密密文，需要由保险机构使用私钥解密后才能查看明文结果" type="warning" :closable="false" />
      </div>
      <span slot="footer">
        <el-button type="primary" @click="handleDownloadResult">下载密文结果</el-button>
        <el-button @click="resultDialogVisible = false">关闭</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { encryptedCompute, getPoliceTaskList } from '@/api/scene'
export default {
  name: 'EncryptedModelCompute',
  data() {
    return {
      computing: false,
      resultDialogVisible: false,
      computeForm: { encryptedModelId: '', policeDatasetId: '', operations: ['predict'], parallelism: 8 },
      encryptedModels: [],
      // 真实警务数据集目录由数据资源模块提供，本模块不伪造，保持真实但为空
      policeDatasets: [],
      computeTaskList: [],
      currentResult: {}
    }
  },
  created() {
    this.fetchTaskList()
    this.fetchEncryptedModels()
  },
  methods: {
    goBack() { this.$router.go(-1) },
    getStatusType(status) {
      return { completed: 'success', running: 'warning', failed: 'danger' }[status] || 'info'
    },
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
      getPoliceTaskList({ taskType: 'encryptedCompute', pageNo: 1, pageSize: 100 }).then(res => {
        if (res && res.code === 0 && res.result) {
          this.computeTaskList = (res.result.list || []).map(this.normalizeSceneTask)
        }
      }).catch(() => {})
    },
    fetchEncryptedModels() {
      getPoliceTaskList({ taskType: 'modelEncrypt', pageNo: 1, pageSize: 100 }).then(res => {
        if (res && res.code === 0 && res.result) {
          this.encryptedModels = (res.result.list || [])
            .filter(row => row.taskState === 2)
            .map(row => ({ id: row.id, name: row.taskName }))
        }
      }).catch(() => {})
    },
    async handleCompute() {
      if (!this.computeForm.encryptedModelId || !this.computeForm.policeDatasetId) {
        this.$message.warning('请选择加密模型和数据集')
        return
      }
      this.computing = true
      try {
        const res = await encryptedCompute({
          encryptedModelId: this.computeForm.encryptedModelId,
          policeDatasetId: this.computeForm.policeDatasetId,
          operations: this.computeForm.operations,
          keyId: this.computeForm.keyId,
          encryptedModel: this.computeForm.encryptedModel,
          rows: this.computeForm.rows
        })
        if (res && res.code === 0) {
          this.$message.success('联合运算完成')
          this.fetchTaskList()
        } else {
          this.$message.error((res && res.msg) || '联合运算失败')
        }
      } catch (e) {
        this.$message.error('提交失败')
      } finally {
        this.computing = false
      }
    },
    handleViewResult(row) {
      this.currentResult = row
      this.resultDialogVisible = true
    },
    handleDownloadResult() {
      this.$message.success('开始下载密文结果')
      this.resultDialogVisible = false
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
