<template>
  <div class="app-container">
    <el-page-header content="保险机构同态密钥创建" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>密钥生成配置</span></div>
      <el-form ref="keyForm" :model="keyForm" label-width="140px">
        <el-form-item label="加密方案">
          <el-select v-model="keyForm.scheme" placeholder="请选择加密方案" style="width: 300px;">
            <el-option label="BFV (整数运算)" value="BFV" />
            <el-option label="CKKS (浮点运算)" value="CKKS" />
            <el-option label="BGV (整数运算)" value="BGV" />
          </el-select>
        </el-form-item>
        <el-form-item label="多项式模数度">
          <el-select v-model="keyForm.polyModulusDegree" placeholder="请选择多项式模数度" style="width: 300px;">
            <el-option label="2048 (低安全级别)" :value="2048" />
            <el-option label="4096 (中安全级别)" :value="4096" />
            <el-option label="8192 (高安全级别)" :value="8192" />
            <el-option label="16384 (最高安全级别)" :value="16384" />
          </el-select>
        </el-form-item>
        <el-form-item label="系数模数位数">
          <el-input-number v-model="keyForm.coeffModulusBits" :min="20" :max="60" />
          <span style="margin-left: 10px; color: #909399;">位</span>
        </el-form-item>
        <el-form-item label="关联机构">
          <el-select v-model="keyForm.organization" placeholder="请选择机构" style="width: 300px;">
            <el-option label="平安保险" value="平安保险" />
            <el-option label="中国人寿" value="中国人寿" />
            <el-option label="太平洋保险" value="太平洋保险" />
          </el-select>
        </el-form-item>
        <el-form-item label="密钥有效期">
          <el-date-picker v-model="keyForm.validUntil" type="date" placeholder="选择有效期" style="width: 300px;" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="generating" @click="handleGenerate">生成密钥对</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>已生成的密钥列表</span></div>
      <el-table :data="keyList" border>
        <el-table-column prop="keyId" label="密钥ID" width="120" />
        <el-table-column prop="organization" label="关联机构" width="120" />
        <el-table-column prop="scheme" label="加密方案" width="100" />
        <el-table-column prop="polyModulusDegree" label="模数度" width="100" />
        <el-table-column prop="publicKeyHash" label="公钥指纹" width="180" />
        <el-table-column prop="createTime" label="创建时间" width="160" />
        <el-table-column prop="validUntil" label="有效期至" width="120" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'active' ? 'success' : 'info'" size="small">
              {{ scope.row.status === 'active' ? '有效' : '已过期' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleExportPublic(scope.row)">导出公钥</el-button>
            <el-button size="mini" type="text" style="color: #F56C6C;" @click="handleRevoke(scope.row)">撤销</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { generatePoliceKey, getPoliceKeyList } from '@/api/scene'
export default {
  name: 'HomomorphicKeyManagement',
  data() {
    return {
      generating: false,
      keyForm: {
        scheme: 'CKKS',
        polyModulusDegree: 8192,
        coeffModulusBits: 40,
        organization: '',
        validUntil: ''
      },
      keyList: []
    }
  },
  mounted() {
    this.fetchKeyList()
  },
  methods: {
    goBack() { this.$router.go(-1) },
    async fetchKeyList() {
      try {
        const res = await getPoliceKeyList()
        if (res.code === 0) this.keyList = res.result || []
      } catch (e) { console.error(e) }
    },
    async handleGenerate() {
      if (!this.keyForm.organization) return this.$message.warning('请选择关联机构')
      this.generating = true
      try {
        const res = await generatePoliceKey(this.keyForm)
        if (res.code === 0) {
          this.$message.success('密钥对生成成功')
          this.fetchKeyList()
        }
      } catch (e) {
        this.$message.error('生成失败')
      } finally {
        this.generating = false
      }
    },
    handleExportPublic(row) {
      this.$message.success(`正在导出 ${row.organization} 的公钥`)
    },
    handleRevoke(row) {
      this.$confirm(`确定撤销密钥 ${row.keyId}?`, '提示', { type: 'warning' }).then(() => {
        row.status = 'expired'
        this.$message.success('密钥已撤销')
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
