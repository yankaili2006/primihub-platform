<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="特征密文数据安全交换（批量）" style="margin-bottom: 20px;" />

    <el-card>
      <div slot="header"><span>批量交换配置</span></div>
      <el-form ref="exchangeForm" :model="exchangeForm" label-width="120px">
        <el-form-item label="交换方向">
          <el-radio-group v-model="exchangeForm.direction">
            <el-radio label="send">发送</el-radio>
            <el-radio label="receive">接收</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="目标机构">
          <el-select v-model="exchangeForm.targetOrg" placeholder="请选择目标机构" style="width: 300px;">
            <el-option v-for="o in orgList" :key="o.id" :label="o.name" :value="o.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="特征类型">
          <el-checkbox-group v-model="exchangeForm.featureTypes">
            <el-checkbox label="face">人脸特征密文</el-checkbox>
            <el-checkbox label="fingerprint">指纹特征密文</el-checkbox>
            <el-checkbox label="compare">比对结果密文</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="选择文件" v-if="exchangeForm.direction === 'send'">
          <el-upload :auto-upload="false" :on-change="handleFileChange" :file-list="fileList" multiple action="">
            <el-button size="small" type="primary">选择文件</el-button>
            <div slot="tip" class="el-upload__tip">支持批量上传多个密文文件</div>
          </el-upload>
        </el-form-item>
        <el-form-item label="传输加密">
          <el-switch v-model="exchangeForm.enableTLS" active-text="TLS 1.3" />
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
        <el-table-column prop="direction" label="方向" width="80" />
        <el-table-column prop="targetOrg" label="目标机构" width="120" />
        <el-table-column prop="featureTypes" label="特征类型" width="180" />
        <el-table-column prop="fileCount" label="文件数" width="80" />
        <el-table-column prop="totalSize" label="数据量" width="100" />
        <el-table-column prop="progress" label="进度" width="150">
          <template slot-scope="scope">
            <el-progress :percentage="scope.row.progress" :status="scope.row.progress === 100 ? 'success' : ''" />
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
export default {
  name: 'FeatureCipherBatchExchange',
  data() {
    return {
      exchanging: false,
      fileList: [],
      exchangeForm: {
        direction: 'send',
        targetOrg: '',
        featureTypes: ['face', 'compare'],
        enableTLS: true
      },
      orgList: [
        { id: 'ORG001', name: '工商银行' },
        { id: 'ORG002', name: '平安保险' },
        { id: 'ORG003', name: '市民政局' }
      ],
      exchangeTaskList: [
        { taskId: 'BEX001', direction: '发送', targetOrg: '工商银行', featureTypes: '人脸特征, 比对结果', fileCount: 12, totalSize: '1.5 GB', progress: 100, createTime: '2024-01-15 10:00:00' },
        { taskId: 'BEX002', direction: '接收', targetOrg: '平安保险', featureTypes: '人脸特征', fileCount: 8, totalSize: '980 MB', progress: 75, createTime: '2024-01-15 14:30:00' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleFileChange(file, fileList) {
      this.fileList = fileList
    },
    handleExchange() {
      if (!this.exchangeForm.targetOrg) {
        this.$message.warning('请选择目标机构')
        return
      }
      this.exchanging = true
      const org = this.orgList.find(o => o.id === this.exchangeForm.targetOrg)
      const newTask = {
        taskId: `BEX${Date.now()}`,
        direction: this.exchangeForm.direction === 'send' ? '发送' : '接收',
        targetOrg: org.name,
        featureTypes: this.exchangeForm.featureTypes.map(t => ({ face: '人脸特征', fingerprint: '指纹特征', compare: '比对结果' }[t])).join(', '),
        fileCount: this.fileList.length || Math.floor(Math.random() * 10) + 5,
        totalSize: `${(Math.random() * 2 + 0.5).toFixed(1)} GB`,
        progress: 0,
        createTime: new Date().toLocaleString()
      }
      this.exchangeTaskList.unshift(newTask)
      const timer = setInterval(() => {
        if (newTask.progress < 100) {
          newTask.progress += 10
        } else {
          clearInterval(timer)
          this.exchanging = false
          this.$message.success('批量交换完成')
        }
      }, 500)
    },
    handleViewLog(row) {
      this.$message.info(`查看日志: ${row.taskId}`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
