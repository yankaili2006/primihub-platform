<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="联邦学习模型预览" style="margin-bottom: 20px;" />

    <el-card>
      <div slot="header"><span>模型列表</span></div>
      <el-table :data="modelList" border>
        <el-table-column prop="modelId" label="模型ID" width="150" />
        <el-table-column prop="modelName" label="模型名称" width="200" />
        <el-table-column prop="modelType" label="模型类型" width="120" />
        <el-table-column prop="accuracy" label="准确率" width="100">
          <template slot-scope="scope">{{ scope.row.accuracy }}%</template>
        </el-table-column>
        <el-table-column prop="participants" label="参与方数量" width="120" />
        <el-table-column prop="createTime" label="创建时间" width="180" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ scope.row.statusText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handlePreview(scope.row)">预览</el-button>
            <el-button size="mini" type="text" @click="handleDownload(scope.row)">下载</el-button>
            <el-button size="mini" type="text" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog title="模型详情" :visible.sync="dialogVisible" width="60%">
      <el-descriptions :column="2" border v-if="currentModel">
        <el-descriptions-item label="模型ID">{{ currentModel.modelId }}</el-descriptions-item>
        <el-descriptions-item label="模型名称">{{ currentModel.modelName }}</el-descriptions-item>
        <el-descriptions-item label="模型类型">{{ currentModel.modelType }}</el-descriptions-item>
        <el-descriptions-item label="准确率">{{ currentModel.accuracy }}%</el-descriptions-item>
        <el-descriptions-item label="参与方数量">{{ currentModel.participants }}</el-descriptions-item>
        <el-descriptions-item label="训练轮次">{{ currentModel.rounds }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ currentModel.createTime }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ currentModel.statusText }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'FederatedModelPreview',
  data() {
    return {
      dialogVisible: false,
      currentModel: null,
      modelList: [
        { modelId: 'FL-M-001', modelName: '逻辑回归模型', modelType: 'LR', accuracy: 92.5, participants: 3, rounds: 100, status: 'trained', statusText: '已训练', createTime: '2024-01-15 10:30:00' },
        { modelId: 'FL-M-002', modelName: '神经网络模型', modelType: 'NN', accuracy: 95.8, participants: 5, rounds: 200, status: 'trained', statusText: '已训练', createTime: '2024-01-14 14:20:00' },
        { modelId: 'FL-M-003', modelName: 'XGBoost模型', modelType: 'XGB', accuracy: 94.2, participants: 4, rounds: 150, status: 'training', statusText: '训练中', createTime: '2024-01-16 09:15:00' }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    getStatusType(status) {
      const types = { trained: 'success', training: 'warning', failed: 'danger' }
      return types[status] || 'info'
    },
    handlePreview(row) {
      this.currentModel = row
      this.dialogVisible = true
    },
    handleDownload(row) {
      this.$message.success(`开始下载模型: ${row.modelName}`)
    },
    handleDelete(row) {
      this.$confirm(`确定删除模型 ${row.modelName}?`, '提示', { type: 'warning' }).then(() => {
        this.$message.success('删除成功')
      })
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
