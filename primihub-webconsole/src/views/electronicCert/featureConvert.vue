<template>
  <div class="app-container">
    <el-page-header content="电子证件特征转换" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>特征转换配置</span></div>
      <el-form ref="convertForm" :model="convertForm" label-width="120px">
        <el-form-item label="证件类型">
          <el-select v-model="convertForm.certType" placeholder="请选择证件类型" style="width: 300px;">
            <el-option label="身份证" value="idCard" />
            <el-option label="护照" value="passport" />
            <el-option label="驾驶证" value="driverLicense" />
            <el-option label="社保卡" value="socialCard" />
          </el-select>
        </el-form-item>
        <el-form-item label="特征类型">
          <el-checkbox-group v-model="convertForm.featureTypes">
            <el-checkbox label="photo">人脸特征</el-checkbox>
            <el-checkbox label="fingerprint">指纹特征</el-checkbox>
            <el-checkbox label="text">文字信息</el-checkbox>
            <el-checkbox label="barcode">条码信息</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="特征算法">
          <el-select v-model="convertForm.algorithm" placeholder="请选择算法" style="width: 300px;">
            <el-option label="ArcFace (人脸识别)" value="ArcFace" />
            <el-option label="FaceNet (人脸识别)" value="FaceNet" />
            <el-option label="FingerCode (指纹识别)" value="FingerCode" />
          </el-select>
        </el-form-item>
        <el-form-item label="上传证件图片">
          <el-upload :auto-upload="false" :on-change="handleFileChange" :file-list="fileList" list-type="picture-card" action="" accept="image/*">
            <i class="el-icon-plus" />
          </el-upload>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="converting" @click="handleConvert">开始特征转换</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>转换任务列表</span></div>
      <el-table :data="taskList" border>
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="certType" label="证件类型" width="100" />
        <el-table-column prop="featureTypes" label="特征类型" width="180" />
        <el-table-column prop="algorithm" label="算法" width="120" />
        <el-table-column prop="inputCount" label="输入数量" width="100" />
        <el-table-column prop="successCount" label="成功数量" width="100" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ scope.row.statusText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleView(scope.row)">查看</el-button>
            <el-button size="mini" type="text" @click="handleDownload(scope.row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'ElectronicCertFeatureConvert',
  data() {
    return {
      converting: false,
      fileList: [],
      convertForm: {
        certType: 'idCard',
        featureTypes: ['photo', 'text'],
        algorithm: 'ArcFace'
      },
      taskList: [
        { taskId: 'FC-001', certType: '身份证', featureTypes: '人脸特征, 文字信息', algorithm: 'ArcFace', inputCount: 1000, successCount: 998, status: 'completed', statusText: '已完成', createTime: '2024-01-15 10:00:00' },
        { taskId: 'FC-002', certType: '驾驶证', featureTypes: '人脸特征', algorithm: 'FaceNet', inputCount: 500, successCount: 450, status: 'running', statusText: '处理中', createTime: '2024-01-15 14:30:00' }
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
    handleConvert() {
      this.converting = true
      setTimeout(() => {
        this.converting = false
        this.taskList.unshift({
          taskId: `FC-${Date.now()}`,
          certType: { idCard: '身份证', passport: '护照', driverLicense: '驾驶证', socialCard: '社保卡' }[this.convertForm.certType],
          featureTypes: this.convertForm.featureTypes.map(t => ({ photo: '人脸特征', fingerprint: '指纹特征', text: '文字信息', barcode: '条码信息' }[t])).join(', '),
          algorithm: this.convertForm.algorithm,
          inputCount: this.fileList.length || Math.floor(Math.random() * 500) + 100,
          successCount: 0,
          status: 'completed',
          statusText: '已完成',
          createTime: new Date().toLocaleString()
        })
        this.taskList[0].successCount = this.taskList[0].inputCount - Math.floor(Math.random() * 5)
        this.$message.success('特征转换完成')
      }, 2000)
    },
    handleView(row) { this.$message.info(`查看任务: ${row.taskId}`) },
    handleDownload(row) { this.$message.success(`开始下载: ${row.taskId}`) }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
