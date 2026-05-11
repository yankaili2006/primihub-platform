<template>
  <div class="app-container">
    <el-page-header content="联邦学习日志记录" style="margin-bottom: 20px;" @back="goBack" />

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
        <el-descriptions-item label="日志类型">
          <el-tag :type="getLogTypeTag(detailData.logType)" size="small">{{ detailData.logType }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="记录时间">{{ detailData.createTime }}</el-descriptions-item>
        <el-descriptions-item label="日志内容">
          <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0;">{{ detailData.content }}</pre>
        </el-descriptions-item>
        <el-descriptions-item v-if="detailData.stackTrace" label="堆栈信息">
          <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0; font-size: 12px; color: #f56c6c;">{{ detailData.stackTrace }}</pre>
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
  name: 'FederatedLearningLogRecord',
  data() {
    return {
      loading: false,
      queryForm: {
        taskId: '',
        logType: '',
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
          { logId: 'L001', taskId: 'FL-001', taskName: '联合风控模型训练', logType: 'INFO', content: '任务开始执行，初始化联邦学习环境', createTime: '2024-01-15 10:00:00' },
          { logId: 'L002', taskId: 'FL-001', taskName: '联合风控模型训练', logType: 'INFO', content: '数据加载完成，样本数量: 50000，特征数量: 25', createTime: '2024-01-15 10:01:00' },
          { logId: 'L003', taskId: 'FL-001', taskName: '联合风控模型训练', logType: 'INFO', content: '训练完成，模型精度: 0.89', createTime: '2024-01-15 12:30:00' },
          { logId: 'L004', taskId: 'FL-002', taskName: '用户画像特征学习', logType: 'WARN', content: '参与方响应延迟，正在重试连接', createTime: '2024-01-15 14:05:00' },
          { logId: 'L005', taskId: 'FL-004', taskName: '反欺诈检测模型', logType: 'ERROR', content: '训练失败：数据格式不兼容，请检查数据预处理步骤', createTime: '2024-01-14 09:30:00', stackTrace: 'java.lang.IllegalArgumentException: Data format mismatch\n    at com.primihub.biz.service...' }
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
      this.queryForm = { taskId: '', logType: '', dateRange: [], pageNum: 1, pageSize: 10 }
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
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
