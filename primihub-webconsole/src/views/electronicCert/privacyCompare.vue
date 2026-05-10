<template>
  <div class="app-container">
    <el-page-header content="特征数据隐私比对" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>比对配置</span></div>
      <el-form ref="compareForm" :model="compareForm" label-width="140px">
        <el-form-item label="电子证件特征库">
          <el-select v-model="compareForm.electronicFeatureId" placeholder="请选择电子证件特征库" style="width: 400px;">
            <el-option v-for="f in electronicFeatures" :key="f.id" :label="f.name" :value="f.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="现场采集特征">
          <el-select v-model="compareForm.onSiteFeatureId" placeholder="请选择现场采集特征" style="width: 400px;">
            <el-option v-for="f in onSiteFeatures" :key="f.id" :label="f.name" :value="f.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="比对模式">
          <el-radio-group v-model="compareForm.compareMode">
            <el-radio label="1:1">1:1 身份验证</el-radio>
            <el-radio label="1:N">1:N 身份识别</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="隐私保护协议">
          <el-select v-model="compareForm.privacyProtocol" placeholder="请选择协议" style="width: 300px;">
            <el-option label="安全多方计算 (MPC)" value="MPC" />
            <el-option label="同态加密 (HE)" value="HE" />
            <el-option label="差分隐私 (DP)" value="DP" />
          </el-select>
        </el-form-item>
        <el-form-item label="相似度阈值">
          <el-slider v-model="compareForm.threshold" :min="0.5" :max="1" :step="0.01" :format-tooltip="val => (val * 100).toFixed(0) + '%'" style="width: 400px;" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="comparing" @click="handleCompare">开始隐私比对</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>比对结果</span></div>
      <el-table :data="compareResults" border>
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="compareMode" label="比对模式" width="100" />
        <el-table-column prop="protocol" label="隐私协议" width="100" />
        <el-table-column prop="totalCount" label="比对数量" width="100" />
        <el-table-column prop="matchCount" label="匹配数量" width="100" />
        <el-table-column prop="matchRate" label="匹配率" width="100">
          <template slot-scope="scope">
            <el-progress :percentage="scope.row.matchRate" :status="scope.row.matchRate >= 90 ? 'success' : 'warning'" />
          </template>
        </el-table-column>
        <el-table-column prop="avgSimilarity" label="平均相似度" width="120" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ scope.row.statusText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleViewDetail(scope.row)">详情</el-button>
            <el-button size="mini" type="text" @click="handleExport(scope.row)">导出</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { compareFeature } from '@/api/scene'
export default {
  name: 'FeaturePrivacyCompare',
  data() {
    return {
      comparing: false,
      compareForm: {
        compareMode: '1:1',
        electronicFeatureId: '',
        onSiteFeatureId: '',
        privacyProtocol: 'MPC',
        similarityThreshold: 0.85
      },
      electronicFeatureLibraries: [
        { id: 'EF001', name: '电子身份证特征库-2024' },
        { id: 'EF002', name: '电子驾驶证特征库-2024' }
      ],
      onSiteFeatureLibraries: [
        { id: 'OF001', name: '现场采集-A区-20240115' },
        { id: 'OF002', name: '现场采集-B区-20240115' }
      ],
      compareResults: []
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    getStatusType(status) {
      return { completed: 'success', running: 'warning', failed: 'danger' }[status] || 'info'
    },
    async handleCompare() {
      if (!this.compareForm.electronicFeatureId || !this.compareForm.onSiteFeatureId) {
        return this.$message.warning('请选择特征库')
      }
      this.comparing = true
      try {
        const res = await compareFeature(this.compareForm)
        if (res.code === 0) {
          this.$message.success('隐私比对完成')
          this.compareResults.unshift({
            taskId: `CMP${Date.now()}`,
            compareMode: this.compareForm.compareMode,
            protocol: this.compareForm.privacyProtocol,
            matchRate: Math.round((res.result.similarity || 0) * 100),
            status: 'completed',
            statusText: '已完成',
            createTime: new Date().toLocaleString()
          })
        }
      } catch (e) {
        this.$message.error('比对失败')
      } finally {
        this.comparing = false
      }
    },
    handleViewDetail(row) { this.$message.info(`查看详情: ${row.taskId}`) },
    handleExport(row) { this.$message.success(`导出结果: ${row.taskId}`) }
  }
}
  },
  methods: {
    goBack() { this.$router.go(-1) },
    getStatusType(status) {
      return { completed: 'success', running: 'warning', failed: 'danger' }[status] || 'info'
    },
    handleCompare() {
      if (!this.compareForm.electronicFeatureId || !this.compareForm.onSiteFeatureId) {
        this.$message.warning('请选择特征库')
        return
      }
      this.comparing = true
      setTimeout(() => {
        this.comparing = false
        const matchRate = Math.floor(Math.random() * 15) + 85
        this.compareResults.unshift({
          taskId: `CMP${Date.now()}`,
          compareMode: this.compareForm.compareMode,
          protocol: this.compareForm.privacyProtocol,
          totalCount: Math.floor(Math.random() * 500) + 500,
          matchCount: 0,
          matchRate: matchRate,
          avgSimilarity: (Math.random() * 0.1 + 0.85).toFixed(3),
          status: 'completed',
          statusText: '已完成',
          createTime: new Date().toLocaleString()
        })
        this.compareResults[0].matchCount = Math.floor(this.compareResults[0].totalCount * matchRate / 100)
        this.$message.success('隐私比对完成')
      }, 3000)
    },
    handleViewDetail(row) {
      this.$message.info(`查看详情: ${row.taskId}`)
    },
    handleExport(row) {
      this.$message.success(`导出结果: ${row.taskId}`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
