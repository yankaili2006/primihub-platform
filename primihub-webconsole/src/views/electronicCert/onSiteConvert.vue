<template>
  <div class="app-container">
    <el-page-header content="现场证件特征转换" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>现场采集配置</span></div>
      <el-form ref="onSiteForm" :model="onSiteForm" label-width="120px">
        <el-form-item label="采集设备">
          <el-select v-model="onSiteForm.deviceId" placeholder="请选择采集设备" style="width: 300px;">
            <el-option v-for="d in deviceList" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="采集类型">
          <el-checkbox-group v-model="onSiteForm.captureTypes">
            <el-checkbox label="face">人脸图像</el-checkbox>
            <el-checkbox label="fingerprint">指纹图像</el-checkbox>
            <el-checkbox label="iris">虹膜图像</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="图像质量">
          <el-slider v-model="onSiteForm.qualityThreshold" :min="60" :max="100" :marks="{60:'60%',80:'80%',100:'100%'}" style="width: 300px;" />
        </el-form-item>
        <el-form-item label="活体检测">
          <el-switch v-model="onSiteForm.livenessDetection" active-text="开启" inactive-text="关闭" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="capturing" @click="handleCapture">开始采集</el-button>
          <el-button @click="handleBatchImport">批量导入</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>采集记录</span></div>
      <el-table :data="captureRecords" border>
        <el-table-column prop="recordId" label="记录ID" width="120" />
        <el-table-column prop="deviceName" label="设备名称" width="150" />
        <el-table-column prop="captureType" label="采集类型" width="120" />
        <el-table-column prop="qualityScore" label="质量评分" width="100">
          <template slot-scope="scope">
            <el-progress :percentage="scope.row.qualityScore" :status="scope.row.qualityScore >= 80 ? 'success' : 'warning'" />
          </template>
        </el-table-column>
        <el-table-column prop="livenessResult" label="活体检测" width="100">
          <template slot-scope="scope">
            <el-tag :type="scope.row.livenessResult ? 'success' : 'danger'" size="small">
              {{ scope.row.livenessResult ? '通过' : '未通过' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="featureStatus" label="特征状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="scope.row.featureStatus === 'extracted' ? 'success' : 'info'" size="small">
              {{ scope.row.featureStatus === 'extracted' ? '已提取' : '待提取' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="captureTime" label="采集时间" width="160" />
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handlePreview(scope.row)">预览</el-button>
            <el-button size="mini" type="text" @click="handleExtract(scope.row)">提取特征</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { convertFeatureOnSite } from '@/api/scene'
export default {
  name: 'OnSiteCertFeatureConvert',
  data() {
    return {
      capturing: false,
      onSiteForm: {
        deviceId: '',
        captureTypes: ['face'],
        qualityThreshold: 80,
        livenessDetection: true
      },
      deviceList: [
        { id: 'DEV001', name: '人脸采集仪-A区' },
        { id: 'DEV002', name: '人脸采集仪-B区' },
        { id: 'DEV003', name: '指纹采集仪-大厅' }
      ],
      captureRecords: [
        { recordId: 'CAP001', deviceName: '人脸采集仪-A区', captureType: '人脸图像', qualityScore: 92, livenessResult: true, featureStatus: 'extracted', captureTime: '2024-01-15 10:30:00' },
        { recordId: 'CAP002', deviceName: '指纹采集仪-大厅', captureType: '指纹图像', qualityScore: 85, livenessResult: true, featureStatus: 'extracted', captureTime: '2024-01-15 10:28:00' },
        { recordId: 'CAP003', deviceName: '人脸采集仪-B区', captureType: '人脸图像', qualityScore: 68, livenessResult: false, featureStatus: 'pending', captureTime: '2024-01-15 10:25:00' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleCapture() {
      if (!this.onSiteForm.deviceId) {
        this.$message.warning('请选择采集设备')
        return
      }
      this.capturing = true
      setTimeout(() => {
        this.capturing = false
        const device = this.deviceList.find(d => d.id === this.onSiteForm.deviceId)
        this.captureRecords.unshift({
          recordId: `CAP${Date.now()}`,
          deviceName: device.name,
          captureType: this.onSiteForm.captureTypes.map(t => ({ face: '人脸图像', fingerprint: '指纹图像', iris: '虹膜图像' }[t])).join(', '),
          qualityScore: Math.floor(Math.random() * 30) + 70,
          livenessResult: Math.random() > 0.2,
          featureStatus: 'pending',
          captureTime: new Date().toLocaleString()
        })
        this.$message.success('采集完成')
      }, 2000)
    },
    handleBatchImport() {
      this.$message.info('打开批量导入对话框')
    },
    handlePreview(row) {
      this.$message.info(`预览记录: ${row.recordId}`)
    },
    async handleExtract(row) {
      // #216 现场证件特征转换: 调后端真实确定性 SHA-256 令牌化
      try {
        const res = await convertFeatureOnSite({
          rows: [{ recordId: row.recordId, deviceName: row.deviceName, captureType: row.captureType, qualityScore: row.qualityScore }],
          featureFields: ['recordId', 'captureType'],
          salt: 'onsite'
        })
        if (res && res.code === 0) {
          row.featureStatus = 'extracted'
          row.featureToken = (res.result && res.result.tokens && res.result.tokens[0]) || ''
          this.$message.success('特征转换完成(SHA-256令牌化)')
        } else {
          this.$message.error((res && res.msg) || '特征转换失败')
        }
      } catch (e) {
        this.$message.error('请求失败')
      }
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
