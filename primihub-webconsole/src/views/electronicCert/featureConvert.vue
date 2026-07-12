<template>
  <div class="app-container">
    <el-page-header content="电子证件特征转换" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>特征转换配置</span></div>
      <el-form ref="convertForm" :model="convertForm" :rules="formRules" label-width="120px">
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
import { convertFeature } from '@/api/scene'
export default {
  name: 'ElectronicCertFeatureConvert',
  data() {
    return {
      converting: false,
      fileList: [],
      formRules: {
        certType: [{ required: true, message: '请选择证件类型', trigger: 'change' }],
        featureTypes: [{ required: true, message: '请至少选择一项特征', trigger: 'change' }],
        algorithm: [{ required: true, message: '请选择算法', trigger: 'change' }]
      },
      convertForm: {
        certType: 'idCard',
        featureTypes: ['photo'],
        algorithm: 'ArcFace'
      },
      taskList: []
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
    async handleConvert() {
      this.converting = true
      try {
        const res = await convertFeature(this.convertForm)
        if (res.code === 0) {
          this.$message.success('特征转换完成')
          this.taskList.unshift({
            taskId: `FC-${Date.now()}`,
            certType: { idCard: '身份证' }[this.convertForm.certType] || this.convertForm.certType,
            featureTypes: this.convertForm.featureTypes.join(', '),
            algorithm: this.convertForm.algorithm,
            inputCount: this.fileList.length || 0,
            status: 'completed',
            statusText: '已完成',
            createTime: new Date().toLocaleString()
          })
        }
      } catch (e) {
        this.$message.error('特征转换失败')
      } finally {
        this.converting = false
      }
    },
    handleView(row) { this.$message.info(`查看任务: ${row.taskId}`) },
    handleDownload(row) { this.$message.success(`开始下载: ${row.taskId}`) }
  }
}
</script>
