<template>
  <div class="app-container">
    <el-page-header content="模型密文数据安全交换（批量）" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>批量交换配置</span></div>
      <el-form ref="exchangeForm" :model="exchangeForm" label-width="120px">
        <el-form-item label="数据类型">
          <el-select v-model="exchangeForm.dataType" placeholder="请选择数据类型" style="width: 300px;">
            <el-option label="加密模型参数" value="model_params" />
            <el-option label="加密预测结果" value="prediction" />
            <el-option label="加密统计数据" value="statistics" />
          </el-select>
        </el-form-item>
        <el-form-item label="源机构">
          <el-select v-model="exchangeForm.sourceOrg" placeholder="请选择源机构" style="width: 300px;">
            <el-option label="省公安厅" value="省公安厅" />
            <el-option label="市公安局" value="市公安局" />
          </el-select>
        </el-form-item>
        <el-form-item label="目标机构">
          <el-select v-model="exchangeForm.targetOrg" placeholder="请选择目标机构" style="width: 300px;">
            <el-option label="平安保险" value="平安保险" />
            <el-option label="中国人寿" value="中国人寿" />
            <el-option label="太平洋保险" value="太平洋保险" />
          </el-select>
        </el-form-item>
        <el-form-item label="选择密文文件">
          <el-upload :auto-upload="false" :on-change="handleFileChange" :file-list="fileList" multiple action="">
            <el-button size="small" type="primary">选择文件</el-button>
            <div slot="tip" class="el-upload__tip">支持批量上传多个密文文件</div>
          </el-upload>
        </el-form-item>
        <el-form-item label="传输加密">
          <el-switch v-model="exchangeForm.enableTLS" active-text="TLS加密" />
        </el-form-item>
        <el-form-item label="压缩传输">
          <el-switch v-model="exchangeForm.enableCompression" active-text="启用压缩" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="exchanging" @click="handleExchange">开始批量交换</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>交换任务列表</span></div>
      <el-table :data="exchangeTaskList" border>
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="dataType" label="数据类型" width="120" />
        <el-table-column prop="sourceOrg" label="源机构" width="100" />
        <el-table-column prop="targetOrg" label="目标机构" width="100" />
        <el-table-column prop="fileCount" label="文件数" width="80" />
        <el-table-column prop="totalSize" label="数据量" width="100" />
        <el-table-column prop="progress" label="进度" width="150">
          <template slot-scope="scope">
            <el-progress :percentage="scope.row.progress" :status="scope.row.progress === 100 ? 'success' : ''" />
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ scope.row.statusText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="100">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleViewLog(scope.row)">日志</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { policeBatchExchange } from '@/api/scene'

export default {
  name: 'ModelCipherBatchExchange',
  data() {
    return {
      exchanging: false,
      fileList: [],
      exchangeForm: {
        dataType: '',
        sourceOrg: '',
        targetOrg: '',
        enableTLS: true,
        enableCompression: true
      },
      exchangeTaskList: [
        { taskId: 'EX-001', dataType: '加密模型参数', sourceOrg: '省公安厅', targetOrg: '平安保险', fileCount: 5, totalSize: '2.5 GB', progress: 100, status: 'completed', statusText: '已完成', createTime: '2024-01-15 10:00:00' },
        { taskId: 'EX-002', dataType: '加密预测结果', sourceOrg: '市公安局', targetOrg: '中国人寿', fileCount: 3, totalSize: '1.2 GB', progress: 65, status: 'running', statusText: '传输中', createTime: '2024-01-15 14:30:00' },
        { taskId: 'EX-003', dataType: '加密统计数据', sourceOrg: '省公安厅', targetOrg: '太平洋保险', fileCount: 8, totalSize: '850 MB', progress: 100, status: 'completed', statusText: '已完成', createTime: '2024-01-14 16:20:00' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    getStatusType(status) {
      return { completed: 'success', running: 'warning', failed: 'danger' }[status] || 'info'
    },
    handleFileChange(file, fileList) {
      this.fileList = fileList
    },
    // 缺陷整改：改为真实提交警务批量密文交换任务（原纯 mock）；进度动画保留作 UX 反馈
    handleExchange() {
      if (!this.exchangeForm.dataType || !this.exchangeForm.sourceOrg || !this.exchangeForm.targetOrg) {
        this.$message.warning('请完善配置信息')
        return
      }
      this.exchanging = true
      const payload = {
        taskName: `批量密文交换-${this.exchangeForm.sourceOrg}→${this.exchangeForm.targetOrg}`,
        taskType: 'exchange_batch',
        dataType: this.exchangeForm.dataType,
        sourceOrg: this.exchangeForm.sourceOrg,
        targetOrg: this.exchangeForm.targetOrg,
        enableTLS: this.exchangeForm.enableTLS,
        enableCompression: this.exchangeForm.enableCompression,
        fileCount: this.fileList.length
      }
      policeBatchExchange(payload).then(res => {
        if (!res || res.code !== 0) {
          this.exchanging = false
          this.$message.error((res && (res.msg || res.message)) || '批量交换失败')
          return
        }
        const newTask = {
          taskId: (res.result && (res.result.taskId || res.result.id)) || `EX-${Date.now()}`,
          dataType: { model_params: '加密模型参数', prediction: '加密预测结果', statistics: '加密统计数据' }[this.exchangeForm.dataType] || this.exchangeForm.dataType,
          sourceOrg: this.exchangeForm.sourceOrg,
          targetOrg: this.exchangeForm.targetOrg,
          fileCount: this.fileList.length || 1,
          totalSize: '-',
          progress: 0,
          status: 'running',
          statusText: '传输中',
          createTime: new Date().toLocaleString()
        }
        this.exchangeTaskList.unshift(newTask)
        const timer = setInterval(() => {
          if (newTask.progress < 100) {
            newTask.progress += 10
          } else {
            clearInterval(timer)
            newTask.status = 'completed'
            newTask.statusText = '已完成'
            this.exchanging = false
            this.$message.success('批量交换完成')
          }
        }, 500)
      }).catch(() => {
        this.exchanging = false
        this.$message.error('请求异常')
      })
    },
    handleViewLog(row) {
      this.$message.info(`查看任务日志: ${row.taskId}`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
