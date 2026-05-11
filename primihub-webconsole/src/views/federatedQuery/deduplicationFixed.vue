<template>
  <div class="app-container">
    <el-page-header content="联邦查询去重计费（固定时间范围）" style="margin-bottom: 20px;" @back="goBack" />
    <el-card>
      <div slot="header"><span>去重计费配置</span></div>
      <el-form ref="configForm" :model="configForm" :rules="rules" label-width="160px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="固定时间窗口" prop="timeWindow">
              <el-select v-model="configForm.timeWindow" placeholder="选择时间窗口" style="width: 100%;">
                <el-option label="1小时" value="1h" /><el-option label="6小时" value="6h" />
                <el-option label="12小时" value="12h" /><el-option label="24小时" value="24h" />
                <el-option label="7天" value="7d" /><el-option label="30天" value="30d" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="去重后单价" prop="pricePerUnique">
              <el-input-number v-model="configForm.pricePerUnique" :min="0" :step="0.01" :precision="2" />
              <span style="margin-left: 10px;">元/条</span>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="重复查询折扣" prop="duplicateDiscount">
              <el-input-number v-model="configForm.duplicateDiscount" :min="0" :max="100" />
              <span style="margin-left: 10px;">%</span>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="最低收费" prop="minCharge">
              <el-input-number v-model="configForm.minCharge" :min="0" :step="0.01" :precision="2" />
              <span style="margin-left: 10px;">元</span>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item>
          <el-button type="primary" :loading="saving" @click="handleSaveConfig">保存配置</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
    <el-card style="margin-top: 20px;">
      <div slot="header">
        <span>查询记录</span>
        <el-button style="float: right; padding: 3px 0" type="text" :loading="exporting" @click="handleExport">导出</el-button>
      </div>
      <el-table v-loading="recordsLoading" :data="queryRecords" border :empty-text="recordsLoading ? '加载中...' : '暂无查询记录'">
        <el-table-column prop="queryId" label="查询ID" width="150" />
        <el-table-column prop="userId" label="用户ID" width="120" />
        <el-table-column prop="timeWindow" label="时间窗口" width="120" />
        <el-table-column prop="totalQueries" label="总查询数" width="100" />
        <el-table-column prop="uniqueQueries" label="去重后" width="100"><template slot-scope="scope"><span style="color: #409EFF; font-weight: bold;">{{ scope.row.uniqueQueries }}</span></template></el-table-column>
        <el-table-column prop="duplicateQueries" label="重复数" width="100"><template slot-scope="scope"><span style="color: #909399;">{{ scope.row.duplicateQueries }}</span></template></el-table-column>
        <el-table-column prop="deduplicationRate" label="去重率" width="100"><template slot-scope="scope">{{ scope.row.deduplicationRate }}%</template></el-table-column>
        <el-table-column prop="originalFee" label="原费用(元)" width="100" />
        <el-table-column prop="actualFee" label="实际费用(元)" width="120"><template slot-scope="scope"><span style="color: #67C23A; font-weight: bold;">{{ scope.row.actualFee }}</span></template></el-table-column>
        <el-table-column prop="saved" label="节省(元)" width="100"><template slot-scope="scope"><span style="color: #E6A23C;">-{{ scope.row.saved }}</span></template></el-table-column>
        <el-table-column prop="queryTime" label="查询时间" width="180" />
      </el-table>
    </el-card>
    <el-card style="margin-top: 20px;">
      <div slot="header"><span>去重统计</span></div>
      <el-row :gutter="20">
        <el-col :span="6"><div class="stat-card"><div class="stat-value">{{ statistics.totalQueries }}</div><div class="stat-label">总查询数</div></div></el-col>
        <el-col :span="6"><div class="stat-card"><div class="stat-value">{{ statistics.uniqueQueries }}</div><div class="stat-label">去重后查询数</div></div></el-col>
        <el-col :span="6"><div class="stat-card"><div class="stat-value">{{ statistics.deduplicationRate }}%</div><div class="stat-label">平均去重率</div></div></el-col>
        <el-col :span="6"><div class="stat-card"><div class="stat-value">¥{{ statistics.totalSaved }}</div><div class="stat-label">累计节省</div></div></el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script>
import { createBillingRule, updateBillingRule, getBillingRecordList, getBillingStatistics, exportBillingRecords } from '@/api/federatedBilling'

export default {
  name: 'FederatedQueryDeduplicationFixed',
  data() {
    return {
      saving: false, exporting: false, recordsLoading: false, ruleId: null,
      configForm: { timeWindow: '24h', pricePerUnique: 0.1, duplicateDiscount: 50, minCharge: 0.5 },
      rules: {
        timeWindow: [{ required: true, message: '请选择时间窗口' }],
        pricePerUnique: [{ required: true, message: '请输入去重后单价' }],
        minCharge: [{ required: true, message: '请输入最低收费' }]
      },
      queryRecords: [],
      statistics: { totalQueries: 0, uniqueQueries: 0, deduplicationRate: 0, totalSaved: 0 }
    }
  },
  created() { this.fetchRecords(); this.fetchStats() },
  methods: {
    goBack() { this.$router.go(-1) },
    async handleSaveConfig() {
      this.saving = true
      try {
        const payload = { ruleName: '固定窗口去重_' + Date.now(), billingType: 'fixed_dedup', pricePerUnique: this.configForm.pricePerUnique, minCharge: this.configForm.minCharge, dedupTimeWindow: this.configForm.timeWindow, repeatDiscount: this.configForm.duplicateDiscount, isActive: 1 }
        const res = this.ruleId ? await updateBillingRule({ id: this.ruleId, ...payload }) : await createBillingRule(payload)
        if (res.code === 0) { if (!this.ruleId) this.ruleId = res.result?.ruleId; this.$message.success('配置已保存') } else { this.$message.error(res.message || '保存失败') }
      } catch (e) { this.$message.error('请求异常') }
      this.saving = false
    },
    handleReset() { this.configForm = { timeWindow: '24h', pricePerUnique: 0.1, duplicateDiscount: 50, minCharge: 0.5 } },
    async handleExport() {
      this.exporting = true
      try {
        const res = await exportBillingRecords({ billingType: 'fixed_dedup' })
        const blob = new Blob([res], { type: 'text/csv' }); const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a'); link.href = url; link.download = `billing_dedup_fixed_${Date.now()}.csv`
        link.click(); window.URL.revokeObjectURL(url); this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    },
    async fetchRecords() {
      this.recordsLoading = true
      try { const res = await getBillingRecordList({ pageNum: 1, pageSize: 100 }); if (res.code === 0) this.queryRecords = res.result?.list || [] } catch (e) { console.error(e) }
      this.recordsLoading = false
    },
    async fetchStats() {
      try { const res = await getBillingStatistics({ groupBy: 'dedup_fixed' }); if (res.code === 0) this.statistics = res.result || { totalQueries: 0, uniqueQueries: 0, deduplicationRate: 0, totalSaved: 0 } } catch (e) { console.error(e) }
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.stat-card { padding: 20px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; border-radius: 8px; text-align: center; }
.stat-value { font-size: 32px; font-weight: bold; margin-bottom: 10px; }
.stat-label { font-size: 14px; opacity: 0.9; }
</style>
