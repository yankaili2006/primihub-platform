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
import { createPoliceTask } from "@/api/scene"
export default {
  name: 'EncryptedModelCompute',
  data() {
    return {
      computing: false,
      resultDialogVisible: false,
      computeForm: { encryptedModelId: '', policeDatasetId: '', operations: ['predict'], parallelism: 8 },
      encryptedModels: [
        { id: 'EM001', name: '车险欺诈检测模型(加密)' },
        { id: 'EM002', name: '理赔风险评估模型(加密)' }
      ],
      policeDatasets: [
        { id: 'PD001', name: '交通事故记录数据集' },
        { id: 'PD002', name: '驾驶员信息数据集' },
        { id: 'PD003', name: '车辆登记信息数据集' }
      ],
      computeTaskList: [
        { taskId: 'EC-001', modelName: '车险欺诈检测模型', datasetName: '交通事故记录', operations: '模型预测', recordCount: 15000, computeTime: '12min', status: 'completed', statusText: '已完成', createTime: '2024-01-15 11:00:00', outputCount: 15000, resultSize: '850 MB' },
        { taskId: 'EC-002', modelName: '理赔风险评估模型', datasetName: '驾驶员信息', operations: '聚合统计', recordCount: 8000, computeTime: '计算中', status: 'running', statusText: '运行中', createTime: '2024-01-15 14:30:00', outputCount: '-', resultSize: '-' }
      ],
      currentResult: {}
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    getStatusType(status) {
      return { completed: 'success', running: 'warning', failed: 'danger' }[status] || 'info'
    },
    async handleCompute() {
      if (!this.computeForm.encryptedModelId || !this.computeForm.policeDatasetId) {
        this.$message.warning('请选择加密模型和数据集')
        return
      }
      this.computing = true
      try {
        const res = await createPoliceTask({ taskType: 'encryptedCompute', params: this.computeForm })
        if (res.code === 0) {
          this.$message.success('联合运算任务已提交')
          this.computeTaskList.unshift({
            taskId: `EC-${Date.now()}`,
            modelName: '加密模型',
            datasetName: '警务数据集',
            status: 'running',
            statusText: '运行中',
            createTime: new Date().toLocaleString()
          })
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
