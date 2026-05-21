<template>
  <div class="app-container">
    <el-page-header content="租户数据隔离配置" style="margin-bottom:20px;" @back="$router.go(-1)" />

    <el-alert
      title="数据隔离确保不同租户的数据（数据集、模型、结果文件等）在存储和访问层面完全隔离，防止跨租户数据访问。"
      type="info" show-icon :closable="false" style="margin-bottom:20px;" />

    <el-row :gutter="20">
      <el-col :span="16">
        <el-card>
          <div slot="header">
            <span>数据隔离策略</span>
            <el-button style="float:right;" type="primary" size="small" :loading="saving" @click="handleSave">保存配置</el-button>
          </div>
          <el-form ref="form" :model="form" label-width="160px">
            <el-divider content-position="left">存储隔离</el-divider>
            <el-form-item label="存储隔离方式">
              <el-radio-group v-model="form.storageIsolation">
                <el-radio label="SCHEMA">数据库 Schema 隔离</el-radio>
                <el-radio label="TABLE_PREFIX">表前缀隔离</el-radio>
                <el-radio label="DATABASE">独立数据库隔离</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item label="文件存储隔离">
              <el-switch v-model="form.enableFileIsolation" />
              <span style="margin-left:8px;color:#999;">按租户ID独立目录存储文件</span>
            </el-form-item>
            <el-form-item label="存储配额（GB）">
              <el-input-number v-model="form.storageQuotaGB" :min="1" :max="10240" />
              <span style="margin-left:8px;color:#999;">每租户最大存储空间（0=不限）</span>
            </el-form-item>

            <el-divider content-position="left">访问控制隔离</el-divider>
            <el-form-item label="数据访问鉴权">
              <el-switch v-model="form.enableAccessAuth" />
              <span style="margin-left:8px;color:#999;">所有数据访问请求必须携带租户凭证</span>
            </el-form-item>
            <el-form-item label="数据集可见性">
              <el-select v-model="form.datasetVisibility" style="width:220px;">
                <el-option label="仅本租户可见" value="TENANT_ONLY" />
                <el-option label="授权后跨租户可见" value="WITH_AUTH" />
                <el-option label="平台管理员全局可见" value="ADMIN_GLOBAL" />
              </el-select>
            </el-form-item>
            <el-form-item label="模型共享策略">
              <el-select v-model="form.modelSharePolicy" style="width:220px;">
                <el-option label="禁止跨租户共享" value="DENY" />
                <el-option label="仅导出共享" value="EXPORT_ONLY" />
                <el-option label="显式授权共享" value="EXPLICIT_AUTH" />
              </el-select>
            </el-form-item>

            <el-divider content-position="left">加密隔离</el-divider>
            <el-form-item label="静态数据加密">
              <el-switch v-model="form.enableAtRestEncryption" />
            </el-form-item>
            <el-form-item v-if="form.enableAtRestEncryption" label="加密算法">
              <el-select v-model="form.encryptAlgorithm" style="width:200px;">
                <el-option label="AES-256-GCM" value="AES256GCM" />
                <el-option label="SM4（国密）" value="SM4" />
                <el-option label="ChaCha20-Poly1305" value="CHACHA20" />
              </el-select>
            </el-form-item>
            <el-form-item label="密钥管理">
              <el-select v-model="form.keyManagement" style="width:200px;">
                <el-option label="平台统一管理" value="PLATFORM" />
                <el-option label="租户自持密钥（BYOK）" value="BYOK" />
                <el-option label="外部KMS对接" value="EXTERNAL_KMS" />
              </el-select>
            </el-form-item>

            <el-divider content-position="left">审计</el-divider>
            <el-form-item label="数据访问审计">
              <el-switch v-model="form.enableAudit" />
              <span style="margin-left:8px;color:#999;">记录所有跨租户数据访问尝试</span>
            </el-form-item>
            <el-form-item label="违规访问告警">
              <el-switch v-model="form.enableAlarm" :disabled="!form.enableAudit" />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="8">
        <el-card>
          <div slot="header"><span>隔离健康度</span></div>
          <div style="text-align:center;padding:20px 0;">
            <el-progress type="circle" :percentage="healthScore" :color="healthColor" :width="120" />
            <div style="margin-top:12px;font-size:14px;color:#606266;">{{ healthLabel }}</div>
          </div>
          <el-divider />
          <el-descriptions :column="1" border size="small">
            <el-descriptions-item label="数据集隔离">
              <el-tag type="success" size="small">正常</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="文件存储隔离">
              <el-tag :type="form.enableFileIsolation ? 'success' : 'warning'" size="small">
                {{ form.enableFileIsolation ? '已启用' : '未启用' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="加密状态">
              <el-tag :type="form.enableAtRestEncryption ? 'success' : 'info'" size="small">
                {{ form.enableAtRestEncryption ? '已加密' : '未加密' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="审计状态">
              <el-tag :type="form.enableAudit ? 'success' : 'info'" size="small">
                {{ form.enableAudit ? '审计中' : '未启用' }}
              </el-tag>
            </el-descriptions-item>
          </el-descriptions>
        </el-card>

        <el-card style="margin-top:16px;">
          <div slot="header"><span>存储配额使用情况</span></div>
          <div v-for="t in quotaList" :key="t.tenantId" style="margin-bottom:16px;">
            <div style="display:flex;justify-content:space-between;margin-bottom:4px;">
              <span style="font-size:13px;">{{ t.tenantName }}</span>
              <span style="font-size:12px;color:#999;">{{ t.used }}GB / {{ t.quota }}GB</span>
            </div>
            <el-progress :percentage="Math.round(t.used/t.quota*100)" :stroke-width="10" />
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import request from '@/utils/request'

export default {
  name: 'TenantDataIsolation',
  data() {
    return {
      saving: false,
      form: {
        storageIsolation: 'SCHEMA',
        enableFileIsolation: true,
        storageQuotaGB: 100,
        enableAccessAuth: true,
        datasetVisibility: 'TENANT_ONLY',
        modelSharePolicy: 'EXPLICIT_AUTH',
        enableAtRestEncryption: true,
        encryptAlgorithm: 'AES256GCM',
        keyManagement: 'PLATFORM',
        enableAudit: true,
        enableAlarm: true
      },
      quotaList: [
        { tenantId: 1, tenantName: '租户A', used: 38, quota: 100 },
        { tenantId: 2, tenantName: '租户B', used: 12, quota: 100 },
        { tenantId: 3, tenantName: '租户C', used: 67, quota: 100 }
      ]
    }
  },
  computed: {
    healthScore() {
      let score = 60
      if (this.form.enableFileIsolation) score += 10
      if (this.form.enableAccessAuth) score += 10
      if (this.form.enableAtRestEncryption) score += 10
      if (this.form.enableAudit) score += 10
      return Math.min(score, 100)
    },
    healthColor() {
      if (this.healthScore >= 90) return '#67c23a'
      if (this.healthScore >= 70) return '#e6a23c'
      return '#f56c6c'
    },
    healthLabel() {
      if (this.healthScore >= 90) return '隔离状态优秀'
      if (this.healthScore >= 70) return '隔离状态良好'
      return '存在隔离风险，请检查配置'
    }
  },
  created() { this.fetchConfig() },
  methods: {
    async fetchConfig() {
      try {
        const res = await request({ url: '/tenant/dataIsolation/config', method: 'get' })
        if (res.code === 0 && res.result) Object.assign(this.form, res.result)
      } catch (e) { console.error(e) }
    },
    async handleSave() {
      this.saving = true
      try {
        const res = await request({ url: '/tenant/dataIsolation/config', method: 'post', type: 'json', data: this.form })
        if (res.code === 0) { this.$message.success('数据隔离配置已保存') } else { this.$message.error(res.message || '保存失败') }
      } catch (e) { this.$message.error('请求异常') } finally { this.saving = false }
    }
  }
}
</script>
<style scoped>.app-container { padding: 20px; }</style>
