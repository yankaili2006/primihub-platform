<template>
  <div class="app-container">
    <el-page-header content="联邦查询去重计费（滚动时间范围）" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>滚动去重计费配置</span></div>
      <el-form ref="configForm" :model="configForm" label-width="160px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="滚动窗口大小">
              <el-input-number v-model="configForm.windowSize" :min="1" :max="168" />
              <span style="margin-left: 10px;">小时</span>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="滚动步长">
              <el-input-number v-model="configForm.slideInterval" :min="1" :max="24" />
              <span style="margin-left: 10px;">小时</span>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="去重后单价">
              <el-input-number v-model="configForm.pricePerUnique" :min="0" :step="0.01" :precision="2" />
              <span style="margin-left: 10px;">元/条</span>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="窗口内重复折扣">
              <el-input-number v-model="configForm.duplicateDiscount" :min="0" :max="100" />
              <span style="margin-left: 10px;">%</span>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="自动清理过期数据">
              <el-switch v-model="configForm.autoCleanup" />
            </el-form-item>
          </el-col>
          <el-col v-if="configForm.autoCleanup" :span="12">
            <el-form-item label="保留天数">
              <el-input-number v-model="configForm.retentionDays" :min="1" :max="365" />
              <span style="margin-left: 10px;">天</span>
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
        <span>滚动窗口查询记录</span>
        <el-button style="float: right; padding: 3px 0" type="text" @click="handleExport">导出</el-button>
      </div>
      <el-table :data="queryRecords" border>
        <el-table-column prop="queryId" label="查询ID" width="150" />
        <el-table-column prop="userId" label="用户ID" width="120" />
        <el-table-column prop="windowInfo" label="窗口信息" width="180">
          <template slot-scope="scope">
            <el-tooltip :content="scope.row.windowDetail" placement="top">
              <span>{{ scope.row.windowInfo }}</span>
            </el-tooltip>
          </template>
        </el-table-column>
        <el-table-column prop="totalQueries" label="总查询数" width="100" />
        <el-table-column prop="uniqueQueries" label="去重后" width="100">
          <template slot-scope="scope">
            <span style="color: #409EFF; font-weight: bold;">{{ scope.row.uniqueQueries }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="crossWindowDuplicates" label="跨窗口重复" width="120">
          <template slot-scope="scope">
            <span style="color: #E6A23C;">{{ scope.row.crossWindowDuplicates }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="deduplicationRate" label="去重率" width="100">
          <template slot-scope="scope">{{ scope.row.deduplicationRate }}%</template>
        </el-table-column>
        <el-table-column prop="actualFee" label="实际费用(元)" width="120">
          <template slot-scope="scope">
            <span style="color: #67C23A; font-weight: bold;">{{ scope.row.actualFee }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="queryTime" label="查询时间" width="180" />
      </el-table>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>滚动窗口统计</span></div>
      <el-row :gutter="20">
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">{{ statistics.activeWindows }}</div>
            <div class="stat-label">活跃窗口数</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">{{ statistics.avgDeduplicationRate }}%</div>
            <div class="stat-label">平均去重率</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">{{ statistics.crossWindowHitRate }}%</div>
            <div class="stat-label">跨窗口命中率</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-card">
            <div class="stat-value">¥{{ statistics.totalSaved }}</div>
            <div class="stat-label">累计节省</div>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>窗口时间线</span></div>
      <div class="timeline-container">
        <div v-for="(window, index) in windowTimeline" :key="index" class="timeline-item">
          <div class="timeline-marker" />
          <div class="timeline-content">
            <div class="timeline-time">{{ window.time }}</div>
            <div class="timeline-info">
              窗口 {{ window.windowId }}: {{ window.queries }} 条查询, 去重后 {{ window.unique }} 条
            </div>
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'FederatedQueryDeduplicationRolling',
  data() {
    return {
      configForm: {
        windowSize: 24,
        slideInterval: 1,
        pricePerUnique: 0.1,
        duplicateDiscount: 60,
        autoCleanup: true,
        retentionDays: 30
      },
      queryRecords: [
        { queryId: 'FQ-R-001', userId: 'U001', windowInfo: '24h滚动窗口', windowDetail: '窗口: 2024-01-14 10:00 - 2024-01-15 10:00', totalQueries: 1000, uniqueQueries: 580, crossWindowDuplicates: 420, deduplicationRate: 42, actualFee: 74.4, queryTime: '2024-01-15 10:30:00' },
        { queryId: 'FQ-R-002', userId: 'U002', windowInfo: '24h滚动窗口', windowDetail: '窗口: 2024-01-14 11:00 - 2024-01-15 11:00', totalQueries: 500, uniqueQueries: 350, crossWindowDuplicates: 150, deduplicationRate: 30, actualFee: 41.0, queryTime: '2024-01-15 11:20:00' },
        { queryId: 'FQ-R-003', userId: 'U003', windowInfo: '24h滚动窗口', windowDetail: '窗口: 2024-01-14 14:00 - 2024-01-15 14:00', totalQueries: 2000, uniqueQueries: 1100, crossWindowDuplicates: 900, deduplicationRate: 45, actualFee: 146.0, queryTime: '2024-01-15 14:15:00' }
      ],
      statistics: {
        activeWindows: 24,
        avgDeduplicationRate: 38.5,
        crossWindowHitRate: 42.3,
        totalSaved: 580.0
      },
      windowTimeline: [
        { windowId: 'W-001', time: '10:00-11:00', queries: 150, unique: 120 },
        { windowId: 'W-002', time: '11:00-12:00', queries: 180, unique: 135 },
        { windowId: 'W-003', time: '12:00-13:00', queries: 200, unique: 145 },
        { windowId: 'W-004', time: '13:00-14:00', queries: 220, unique: 160 },
        { windowId: 'W-005', time: '14:00-15:00', queries: 190, unique: 140 }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handleSaveConfig() {
      this.$message.success('配置已保存')
    },
    handleReset() {
      this.configForm = { windowSize: 24, slideInterval: 1, pricePerUnique: 0.1, duplicateDiscount: 60, autoCleanup: true, retentionDays: 30 }
    },
    handleExport() {
      this.$message.success('导出成功')
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.stat-card {
  padding: 20px;
  background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
  color: white;
  border-radius: 8px;
  text-align: center;
}
.stat-value { font-size: 32px; font-weight: bold; margin-bottom: 10px; }
.stat-label { font-size: 14px; opacity: 0.9; }
.timeline-container { padding: 20px; }
.timeline-item {
  display: flex;
  margin-bottom: 20px;
  position: relative;
}
.timeline-marker {
  width: 12px;
  height: 12px;
  background: #409EFF;
  border-radius: 50%;
  margin-right: 15px;
  margin-top: 5px;
  flex-shrink: 0;
}
.timeline-content {
  flex: 1;
  padding: 10px;
  background: #f5f7fa;
  border-radius: 4px;
}
.timeline-time {
  font-weight: bold;
  color: #409EFF;
  margin-bottom: 5px;
}
.timeline-info { color: #606266; }
</style>
