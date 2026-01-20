<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="流程执行日志记录" style="margin-bottom: 20px;" />

    <el-card>
      <div slot="header"><span>日志查询</span></div>
      <el-form :inline="true" :model="queryForm">
        <el-form-item label="流程类型">
          <el-select v-model="queryForm.processType" placeholder="全部" clearable style="width: 180px;">
            <el-option label="特征转换" value="featureConvert" />
            <el-option label="现场采集" value="onSiteCapture" />
            <el-option label="隐私比对" value="privacyCompare" />
            <el-option label="数据接入" value="dataImport" />
            <el-option label="数据导出" value="dataExport" />
            <el-option label="数据交换" value="dataExchange" />
          </el-select>
        </el-form-item>
        <el-form-item label="日志级别">
          <el-select v-model="queryForm.logLevel" placeholder="全部" clearable style="width: 120px;">
            <el-option label="INFO" value="INFO" />
            <el-option label="WARN" value="WARN" />
            <el-option label="ERROR" value="ERROR" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker v-model="queryForm.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" style="width: 360px;" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header">
        <span>日志列表</span>
        <span style="float: right; color: #909399;">共 {{ logList.length }} 条记录</span>
      </div>
      <el-table :data="logList" border>
        <el-table-column prop="logId" label="日志ID" width="120" />
        <el-table-column prop="processType" label="流程类型" width="100" />
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="level" label="级别" width="80">
          <template slot-scope="scope">
            <el-tag :type="getLevelType(scope.row.level)" size="small">{{ scope.row.level }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="message" label="日志内容" min-width="300" show-overflow-tooltip />
        <el-table-column prop="operator" label="操作人" width="100" />
        <el-table-column prop="createTime" label="时间" width="160" />
        <el-table-column label="操作" width="80">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleViewDetail(scope.row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top: 20px; text-align: right;" :current-page="1" :page-sizes="[10, 20, 50, 100]" :page-size="20" layout="total, sizes, prev, pager, next, jumper" :total="logList.length" />
    </el-card>

    <el-dialog :visible.sync="detailDialogVisible" title="日志详情" width="700px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="日志ID">{{ currentLog.logId }}</el-descriptions-item>
        <el-descriptions-item label="日志级别">{{ currentLog.level }}</el-descriptions-item>
        <el-descriptions-item label="流程类型">{{ currentLog.processType }}</el-descriptions-item>
        <el-descriptions-item label="任务ID">{{ currentLog.taskId }}</el-descriptions-item>
        <el-descriptions-item label="操作人">{{ currentLog.operator }}</el-descriptions-item>
        <el-descriptions-item label="时间">{{ currentLog.createTime }}</el-descriptions-item>
        <el-descriptions-item label="日志内容" :span="2">{{ currentLog.message }}</el-descriptions-item>
        <el-descriptions-item label="详细信息" :span="2">
          <pre style="margin: 0; white-space: pre-wrap;">{{ currentLog.detail }}</pre>
        </el-descriptions-item>
      </el-descriptions>
      <span slot="footer">
        <el-button @click="detailDialogVisible = false">关闭</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'ElectronicCertLogRecord',
  data() {
    return {
      detailDialogVisible: false,
      currentLog: {},
      queryForm: { processType: '', logLevel: '', dateRange: [] },
      logList: [
        { logId: 'LOG001', processType: '特征转换', taskId: 'FC-001', level: 'INFO', message: '身份证人脸特征提取完成，成功处理 998/1000 条记录', operator: 'admin', createTime: '2024-01-15 10:30:00', detail: '算法: ArcFace\n特征维度: 512\n失败原因: 图像质量不足 2条' },
        { logId: 'LOG002', processType: '隐私比对', taskId: 'CMP001', level: 'INFO', message: '1:1身份验证完成，匹配率 98.5%', operator: 'admin', createTime: '2024-01-15 11:00:00', detail: '总比对数: 1000\n成功匹配: 985\n隐私协议: MPC' },
        { logId: 'LOG003', processType: '数据交换', taskId: 'BEX001', level: 'WARN', message: '网络传输速度低于预期，自动降低并发数', operator: 'system', createTime: '2024-01-15 10:15:00', detail: '原并发数: 50\n调整后: 30\n网络带宽: 85 Mbps' },
        { logId: 'LOG004', processType: '现场采集', taskId: 'CAP003', level: 'ERROR', message: '活体检测未通过，可能为照片攻击', operator: 'admin', createTime: '2024-01-15 10:25:00', detail: '设备: 人脸采集仪-B区\n活体评分: 0.32\n阈值: 0.7' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    getLevelType(level) {
      return { INFO: 'success', WARN: 'warning', ERROR: 'danger' }[level] || 'info'
    },
    handleQuery() {
      this.$message.success('查询完成')
    },
    handleReset() {
      this.queryForm = { processType: '', logLevel: '', dateRange: [] }
    },
    handleViewDetail(row) {
      this.currentLog = row
      this.detailDialogVisible = true
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
