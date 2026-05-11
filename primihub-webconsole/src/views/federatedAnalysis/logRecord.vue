<template>
  <div class="app-container">
    <el-page-header content="联邦分析日志记录" style="margin-bottom: 20px;" @back="goBack" />

    <el-form :inline="true" :model="queryForm" class="demo-form-inline">
      <el-form-item label="任务ID">
        <el-input v-model="queryForm.taskId" placeholder="请输入任务ID" clearable style="width: 150px;" />
      </el-form-item>
      <el-form-item label="日志类型">
        <el-select v-model="queryForm.logType" placeholder="请选择" clearable style="width: 120px;">
          <el-option label="INFO" value="INFO" />
          <el-option label="WARN" value="WARN" />
          <el-option label="ERROR" value="ERROR" />
          <el-option label="DEBUG" value="DEBUG" />
        </el-select>
      </el-form-item>
      <el-form-item label="数据源类型">
        <el-select v-model="queryForm.sourceType" placeholder="请选择" clearable style="width: 140px;">
          <el-option label="关系型数据库" value="RDBMS" />
          <el-option label="大数据平台" value="BIGDATA" />
          <el-option label="公有云平台" value="CLOUD" />
        </el-select>
      </el-form-item>
      <el-form-item label="时间范围">
        <el-date-picker v-model="queryForm.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width: 340px;" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <el-table v-loading="loading" :data="logData" border empty-text="暂无日志记录">
      <el-table-column type="selection" width="50" />
      <el-table-column prop="logId" label="日志ID" width="100" />
      <el-table-column prop="taskId" label="任务ID" width="100" />
      <el-table-column prop="taskName" label="任务名称" width="180" />
      <el-table-column prop="sourceType" label="数据源类型" width="120">
        <template slot-scope="scope">
          {{ getSourceTypeLabel(scope.row.sourceType) }}
        </template>
      </el-table-column>
      <el-table-column prop="logType" label="日志类型" width="100">
        <template slot-scope="scope">
          <el-tag :type="getLogTypeTag(scope.row.logType)" size="small">{{ scope.row.logType }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="content" label="日志内容" min-width="300" show-overflow-tooltip />
      <el-table-column prop="createTime" label="记录时间" width="160" />
      <el-table-column label="操作" width="100" fixed="right">
        <template slot-scope="scope">
          <el-button size="mini" type="text" @click="handleViewDetail(scope.row)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination style="margin-top: 15px;" :current-page="queryForm.pageNum" :page-sizes="[10, 20, 50]" :page-size="queryForm.pageSize" :total="total" layout="total, sizes, prev, pager, next" @size-change="handleSizeChange" @current-change="handleCurrentChange" />

    <!-- Detail Dialog -->
    <el-dialog title="日志详情" :visible.sync="detailDialogVisible" width="50%">
      <el-descriptions :column="1" border>
        <el-descriptions-item label="日志ID">{{ detailData.logId }}</el-descriptions-item>
        <el-descriptions-item label="任务ID">{{ detailData.taskId }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ detailData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="数据源类型">{{ getSourceTypeLabel(detailData.sourceType) }}</el-descriptions-item>
        <el-descriptions-item label="日志类型">
          <el-tag :type="getLogTypeTag(detailData.logType)" size="small">{{ detailData.logType }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="记录时间">{{ detailData.createTime }}</el-descriptions-item>
        <el-descriptions-item label="日志内容">
          <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0;">{{ detailData.content }}</pre>
        </el-descriptions-item>
      </el-descriptions>
      <span slot="footer" class="dialog-footer">
        <el-button @click="detailDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'FederatedAnalysisLogRecord',
  data() {
    return {
      loading: false,
      queryForm: {
        taskId: '',
        logType: '',
        sourceType: '',
        dateRange: [],
        pageNum: 1,
        pageSize: 10
      },
      logData: [],
      total: 0,
      detailDialogVisible: false,
      detailData: {}
    }
  },
  mounted() {
    this.fetchData()
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    fetchData() {
      this.loading = true
      setTimeout(() => {
        this.logData = [
          { logId: 'FAL001', taskId: 'FA-DB001', taskName: '用户行为联邦分析', sourceType: 'RDBMS', logType: 'INFO', content: '开始连接MySQL数据库，执行联邦分析任务', createTime: '2024-01-15 10:00:00' },
          { logId: 'FAL002', taskId: 'FA-DB001', taskName: '用户行为联邦分析', sourceType: 'RDBMS', logType: 'INFO', content: '数据查询完成，返回记录数: 50000', createTime: '2024-01-15 10:01:00' },
          { logId: 'FAL003', taskId: 'FA-BD001', taskName: '大规模用户画像分析', sourceType: 'BIGDATA', logType: 'INFO', content: '连接Hadoop集群成功，开始MapReduce任务', createTime: '2024-01-15 09:00:00' },
          { logId: 'FAL004', taskId: 'FA-CL001', taskName: '跨云数据联邦分析', sourceType: 'CLOUD', logType: 'WARN', content: '阿里云OSS连接延迟，正在重试', createTime: '2024-01-15 10:05:00' },
          { logId: 'FAL005', taskId: 'FA-DB002', taskName: '交易数据关联分析', sourceType: 'RDBMS', logType: 'ERROR', content: '数据库连接超时，请检查网络配置', createTime: '2024-01-15 14:30:00' }
        ]
        this.total = 5
        this.loading = false
      }, 500)
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = { taskId: '', logType: '', sourceType: '', dateRange: [], pageNum: 1, pageSize: 10 }
      this.fetchData()
    },
    handleSizeChange(val) {
      this.queryForm.pageSize = val
      this.fetchData()
    },
    handleCurrentChange(val) {
      this.queryForm.pageNum = val
      this.fetchData()
    },
    handleViewDetail(row) {
      this.detailData = { ...row }
      this.detailDialogVisible = true
    },
    getLogTypeTag(type) {
      const map = { 'INFO': 'info', 'WARN': 'warning', 'ERROR': 'danger', 'DEBUG': '' }
      return map[type] || 'info'
    },
    getSourceTypeLabel(type) {
      const map = { 'RDBMS': '关系型数据库', 'BIGDATA': '大数据平台', 'CLOUD': '公有云平台' }
      return map[type] || type
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
