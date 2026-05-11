<template>
  <div class="app-container">
    <el-page-header content="联邦查询计费（按次数）" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>计费配置</span></div>
      <el-form ref="configForm" :model="configForm" label-width="140px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="单次查询费用">
              <el-input-number v-model="configForm.pricePerQuery" :min="0" :step="0.01" :precision="2" />
              <span style="margin-left: 10px;">元/次</span>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="最低消费">
              <el-input-number v-model="configForm.minCharge" :min="0" :step="0.01" :precision="2" />
              <span style="margin-left: 10px;">元</span>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="批量折扣">
              <el-switch v-model="configForm.enableDiscount" />
            </el-form-item>
          </el-col>
          <el-col v-if="configForm.enableDiscount" :span="12">
            <el-form-item label="折扣阈值">
              <el-input-number v-model="configForm.discountThreshold" :min="1" />
              <span style="margin-left: 10px;">次</span>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item>
          <el-button type="primary" @click="handleSaveConfig">保存配置</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header">
        <span>查询记录</span>
        <el-button style="float: right; padding: 3px 0" type="text" @click="handleExport">导出</el-button>
      </div>
      <el-form :inline="true" size="small">
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
        </el-form-item>
      </el-form>
      <el-table :data="queryRecords" border>
        <el-table-column prop="queryId" label="查询ID" width="150" />
        <el-table-column prop="userId" label="用户ID" width="120" />
        <el-table-column prop="queryType" label="查询类型" width="120" />
        <el-table-column prop="queryCount" label="查询次数" width="100" />
        <el-table-column prop="unitPrice" label="单价(元)" width="100" />
        <el-table-column prop="totalFee" label="总费用(元)" width="120">
          <template slot-scope="scope">
            <span style="color: #F56C6C; font-weight: bold;">{{ scope.row.totalFee }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="queryTime" label="查询时间" width="180" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ scope.row.statusText }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        style="margin-top: 20px; text-align: right;"
        :current-page="currentPage"
        :page-size="10"
        layout="total, prev, pager, next"
        :total="total"
        @current-change="handlePageChange"
      />
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>费用统计</span></div>
      <el-row :gutter="20">
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">{{ statistics.totalQueries }}</div>
            <div class="stat-label">总查询次数</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">¥{{ statistics.totalFee }}</div>
            <div class="stat-label">总费用</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">¥{{ statistics.avgFee }}</div>
            <div class="stat-label">平均费用</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">{{ statistics.todayQueries }}</div>
            <div class="stat-label">今日查询</div>
          </div>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script>
import { createBillingRule, updateBillingRule, getBillingRecordList, getBillingStatistics, exportBillingRecords } from '@/api/federatedBilling'

export default {
  name: 'FederatedQueryBillingByCount',
  data() {
    return {
      configForm: {
        pricePerQuery: 0.5,
        minCharge: 1.0,
        enableDiscount: false,
        discountThreshold: 100
      },
      dateRange: [],
      currentPage: 1,
      total: 0,
      queryRecords: [],
      statistics: {
        totalQueries: 0, totalFee: 0, avgFee: 0, todayQueries: 0
      },
      ruleId: null
    }
  },
  created() {
    this.fetchRecords()
    this.fetchStats()
  },
  methods: {
    goBack() { this.$router.go(-1) },
    getStatusType(status) {
      const types = { completed: 'success', processing: 'warning', failed: 'danger' }
      return types[status] || 'info'
    },
    async handleSaveConfig() {
      try {
        const payload = {
          ruleName: '按次数计费_' + Date.now(),
          billingType: 'by_count',
          pricePerQuery: this.configForm.pricePerQuery,
          minCharge: this.configForm.minCharge,
          enableDiscount: this.configForm.enableDiscount ? 1 : 0,
          discountThreshold: this.configForm.enableDiscount ? this.configForm.discountThreshold : 0,
          isActive: 1
        }
        const res = this.ruleId
          ? await updateBillingRule({ id: this.ruleId, ...payload })
          : await createBillingRule(payload)
        if (res.code === 0) {
          if (!this.ruleId) this.ruleId = res.result?.ruleId
          this.$message.success('配置已保存')
        } else {
          this.$message.error(res.message || '保存失败')
        }
      } catch (e) { this.$message.error('请求异常') }
    },
    handleReset() {
      this.configForm = { pricePerQuery: 0.5, minCharge: 1.0, enableDiscount: false, discountThreshold: 100 }
    },
    async handleQuery() {
      this.currentPage = 1
      await this.fetchRecords()
    },
    async handleExport() {
      try {
        const res = await exportBillingRecords({ startTime: this.dateRange?.[0] || '', endTime: this.dateRange?.[1] || '' })
        const blob = new Blob([res], { type: 'text/csv' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url; link.download = `billing_records_${Date.now()}.csv`
        link.click(); window.URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败') }
    },
    handlePageChange(page) { this.currentPage = page; this.fetchRecords() },
    async fetchRecords() {
      try {
        const params = {
          pageNum: this.currentPage, pageSize: 10,
          startTime: this.dateRange?.[0] || '', endTime: this.dateRange?.[1] || ''
        }
        const res = await getBillingRecordList(params)
        if (res.code === 0) {
          this.queryRecords = res.result?.list || []
          this.total = res.result?.total || 0
        }
      } catch (e) { console.error(e) }
    },
    async fetchStats() {
      try {
        const res = await getBillingStatistics()
        if (res.code === 0) this.statistics = res.result || { totalQueries: 0, totalFee: 0, avgFee: 0, todayQueries: 0 }
      } catch (e) { console.error(e) }
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.stat-card {
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 8px;
  text-align: center;
}
.stat-value { font-size: 32px; font-weight: bold; margin-bottom: 10px; }
.stat-label { font-size: 14px; opacity: 0.9; }
</style>
