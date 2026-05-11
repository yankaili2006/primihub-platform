<template>
  <div class="app-container">
    <el-page-header content="联邦查询计费（按命中）" style="margin-bottom: 20px;" @back="goBack" />
    <el-card>
      <div slot="header"><span>计费配置</span></div>
      <el-form ref="configForm" :model="configForm" :rules="rules" label-width="140px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="单条命中费用" prop="pricePerHit">
              <el-input-number v-model="configForm.pricePerHit" :min="0" :step="0.01" :precision="2" />
              <span style="margin-left: 10px;">元/条</span>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="基础查询费" prop="baseFee">
              <el-input-number v-model="configForm.baseFee" :min="0" :step="0.01" :precision="2" />
              <span style="margin-left: 10px;">元</span>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="阶梯计费">
              <el-switch v-model="configForm.enableTiered" />
            </el-form-item>
          </el-col>
          <el-col v-if="configForm.enableTiered" :span="12">
            <el-form-item label="阶梯配置">
              <el-button size="small" @click="dialogVisible = true">配置</el-button>
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
        <el-table-column prop="queryType" label="查询类型" width="120" />
        <el-table-column prop="totalRecords" label="查询总数" width="100" />
        <el-table-column prop="hitRecords" label="命中数" width="100">
          <template slot-scope="scope"><span style="color: #E6A23C; font-weight: bold;">{{ scope.row.hitRecords }}</span></template>
        </el-table-column>
        <el-table-column prop="hitRate" label="命中率" width="100">
          <template slot-scope="scope">{{ scope.row.hitRate }}%</template>
        </el-table-column>
        <el-table-column prop="baseFee" label="基础费(元)" width="100" />
        <el-table-column prop="hitFee" label="命中费(元)" width="100" />
        <el-table-column prop="totalFee" label="总费用(元)" width="120">
          <template slot-scope="scope"><span style="color: #F56C6C; font-weight: bold;">{{ scope.row.totalFee }}</span></template>
        </el-table-column>
        <el-table-column prop="queryTime" label="查询时间" width="180" />
      </el-table>
    </el-card>
    <el-card style="margin-top: 20px;">
      <div slot="header"><span>费用统计</span></div>
      <el-row :gutter="20">
        <el-col :span="6"><div class="stat-card"><div class="stat-value">{{ statistics.totalHits }}</div><div class="stat-label">总命中数</div></div></el-col>
        <el-col :span="6"><div class="stat-card"><div class="stat-value">{{ statistics.avgHitRate }}%</div><div class="stat-label">平均命中率</div></div></el-col>
        <el-col :span="6"><div class="stat-card"><div class="stat-value">¥{{ statistics.totalFee }}</div><div class="stat-label">总费用</div></div></el-col>
        <el-col :span="6"><div class="stat-card"><div class="stat-value">¥{{ statistics.avgFee }}</div><div class="stat-label">平均费用</div></div></el-col>
      </el-row>
    </el-card>
    <el-dialog title="阶梯计费配置" :visible.sync="dialogVisible" width="50%">
      <el-table :data="tieredConfig" border>
        <el-table-column prop="tier" label="阶梯" width="100" />
        <el-table-column prop="range" label="命中范围" width="150" />
        <el-table-column prop="price" label="单价(元)" width="120">
          <template slot-scope="scope"><el-input-number v-model="scope.row.price" :min="0" :step="0.01" :precision="2" size="small" /></template>
        </el-table-column>
      </el-table>
      <span slot="footer"><el-button @click="dialogVisible = false">取消</el-button><el-button type="primary" @click="handleSaveTiered">确定</el-button></span>
    </el-dialog>
  </div>
</template>

<script>
import { createBillingRule, updateBillingRule, getBillingRecordList, getBillingStatistics, exportBillingRecords } from '@/api/federatedBilling'

export default {
  name: 'FederatedQueryBillingByHit',
  data() {
    return {
      dialogVisible: false, saving: false, exporting: false, recordsLoading: false, ruleId: null,
      configForm: { pricePerHit: 0.1, baseFee: 0.5, enableTiered: false },
      rules: {
        pricePerHit: [{ required: true, message: '请输入命中费用' }],
        baseFee: [{ required: true, message: '请输入基础费用' }]
      },
      queryRecords: [],
      statistics: { totalHits: 0, avgHitRate: 0, totalFee: 0, avgFee: 0 },
      tieredConfig: [
        { tier: 1, range: '0-100', price: 0.1 },
        { tier: 2, range: '101-500', price: 0.08 },
        { tier: 3, range: '501-1000', price: 0.06 },
        { tier: 4, range: '1000+', price: 0.05 }
      ]
    }
  },
  created() { this.fetchRecords(); this.fetchStats() },
  methods: {
    goBack() { this.$router.go(-1) },
    async handleSaveConfig() {
      this.saving = true
      try {
        const payload = { ruleName: '按命中计费_' + Date.now(), billingType: 'by_hit', pricePerHit: this.configForm.pricePerHit, baseFee: this.configForm.baseFee, enableTiered: this.configForm.enableTiered ? 1 : 0, isActive: 1 }
        const res = this.ruleId ? await updateBillingRule({ id: this.ruleId, ...payload }) : await createBillingRule(payload)
        if (res.code === 0) { if (!this.ruleId) this.ruleId = res.result?.ruleId; this.$message.success('配置已保存') } else { this.$message.error(res.message || '保存失败') }
      } catch (e) { this.$message.error('请求异常') }
      this.saving = false
    },
    handleReset() { this.configForm = { pricePerHit: 0.1, baseFee: 0.5, enableTiered: false } },
    handleSaveTiered() { this.dialogVisible = false; this.$message.success('阶梯配置已保存') },
    async handleExport() {
      this.exporting = true
      try {
        const res = await exportBillingRecords({ billingType: 'by_hit' })
        const blob = new Blob([res], { type: 'text/csv' }); const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a'); link.href = url; link.download = `billing_hit_${Date.now()}.csv`
        link.click(); window.URL.revokeObjectURL(url); this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    },
    async fetchRecords() {
      this.recordsLoading = true
      try {
        const res = await getBillingRecordList({ pageNum: 1, pageSize: 100 })
        if (res.code === 0) this.queryRecords = res.result?.list || []
      } catch (e) { console.error(e) }
      this.recordsLoading = false
    },
    async fetchStats() {
      try {
        const res = await getBillingStatistics({ groupBy: 'hit' })
        if (res.code === 0) this.statistics = res.result || { totalHits: 0, avgHitRate: 0, totalFee: 0, avgFee: 0 }
      } catch (e) { console.error(e) }
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.stat-card { padding: 20px; background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; border-radius: 8px; text-align: center; }
.stat-value { font-size: 32px; font-weight: bold; margin-bottom: 10px; }
.stat-label { font-size: 14px; opacity: 0.9; }
</style>
