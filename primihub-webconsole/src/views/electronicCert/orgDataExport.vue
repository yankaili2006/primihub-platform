<template>
  <div class="app-container">
    <el-page-header content="使用机构数据导出" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>导出配置</span></div>
      <el-form ref="exportForm" :model="exportForm" label-width="120px">
        <el-form-item label="选择机构">
          <el-select v-model="exportForm.orgId" placeholder="请选择机构" style="width: 300px;">
            <el-option v-for="o in orgList" :key="o.id" :label="o.name" :value="o.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据类型">
          <el-checkbox-group v-model="exportForm.dataTypes">
            <el-checkbox label="verifyResult">验证结果</el-checkbox>
            <el-checkbox label="compareResult">比对结果</el-checkbox>
            <el-checkbox label="statistics">统计数据</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker v-model="exportForm.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="导出格式">
          <el-select v-model="exportForm.format" style="width: 200px;">
            <el-option label="Excel (.xlsx)" value="EXCEL" />
            <el-option label="CSV (.csv)" value="CSV" />
            <el-option label="JSON (.json)" value="JSON" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据脱敏">
          <el-switch v-model="exportForm.desensitize" active-text="启用" inactive-text="禁用" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="exporting" @click="handleExport">开始导出</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>导出历史</span></div>
      <el-table :data="exportHistory" border>
        <el-table-column prop="exportId" label="导出ID" width="120" />
        <el-table-column prop="orgName" label="机构名称" width="150" />
        <el-table-column prop="dataTypes" label="数据类型" width="180" />
        <el-table-column prop="recordCount" label="记录数" width="100" />
        <el-table-column prop="fileSize" label="文件大小" width="100" />
        <el-table-column prop="format" label="格式" width="80" />
        <el-table-column prop="createTime" label="导出时间" width="160" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'completed' ? 'success' : 'warning'" size="small">
              {{ scope.row.status === 'completed' ? '已完成' : '导出中' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100">
          <template slot-scope="scope">
            <el-button size="mini" type="primary" :disabled="scope.row.status !== 'completed'" @click="handleDownload(scope.row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { exportSceneData } from '@/api/scene'

export default {
  name: 'OrgDataExport',
  data() {
    return {
      exporting: false,
      exportForm: {
        orgId: '',
        dataTypes: ['verifyResult', 'compareResult'],
        dateRange: [],
        format: 'EXCEL',
        desensitize: true
      },
      orgList: [
        { id: 'ORG001', name: '工商银行' },
        { id: 'ORG002', name: '平安保险' },
        { id: 'ORG003', name: '市民政局' }
      ],
      exportHistory: [
        { exportId: 'EXP001', orgName: '工商银行', dataTypes: '验证结果, 比对结果', recordCount: 25800, fileSize: '3.2 MB', format: 'EXCEL', createTime: '2024-01-15 16:00:00', status: 'completed' },
        { exportId: 'EXP002', orgName: '平安保险', dataTypes: '统计数据', recordCount: 1200, fileSize: '256 KB', format: 'CSV', createTime: '2024-01-15 14:30:00', status: 'completed' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    // 缺陷整改 T2：改为真实提交数据导出任务（原 setTimeout 假成功、不调后端）
    handleExport() {
      if (!this.exportForm.orgId) {
        this.$message.warning('请选择机构')
        return
      }
      this.exporting = true
      const org = this.orgList.find(o => o.id === this.exportForm.orgId)
      const data = {
        taskName: `机构数据导出-${org ? org.name : this.exportForm.orgId}`,
        action: 'export',
        orgId: this.exportForm.orgId,
        dataTypes: this.exportForm.dataTypes,
        startDate: this.exportForm.dateRange && this.exportForm.dateRange[0] ? this.exportForm.dateRange[0] : '',
        endDate: this.exportForm.dateRange && this.exportForm.dateRange[1] ? this.exportForm.dateRange[1] : '',
        format: this.exportForm.format,
        desensitize: this.exportForm.desensitize
      }
      exportSceneData(data).then(res => {
        if (res && res.code === 0) {
          this.$message.success('导出任务已提交')
          this.exportHistory.unshift({
            exportId: (res.result && (res.result.taskId || res.result.id)) || `EXP${Date.now()}`,
            orgName: org ? org.name : this.exportForm.orgId,
            dataTypes: this.exportForm.dataTypes.map(t => ({ verifyResult: '验证结果', compareResult: '比对结果', statistics: '统计数据' }[t])).join(', '),
            recordCount: '-',
            fileSize: '-',
            format: this.exportForm.format,
            createTime: new Date().toLocaleString(),
            status: 'processing'
          })
        } else {
          this.$message.error((res && res.msg) || '导出失败')
        }
      }).catch(() => {
        this.$message.error('导出失败')
      }).finally(() => {
        this.exporting = false
      })
    },
    handleDownload(row) {
      this.$message.success(`开始下载: ${row.exportId}`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
