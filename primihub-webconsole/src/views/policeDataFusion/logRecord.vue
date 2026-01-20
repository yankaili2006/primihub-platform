<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="流程执行日志记录" style="margin-bottom: 20px;" />

    <el-card>
      <div slot="header"><span>日志查询</span></div>
      <el-form :inline="true" :model="queryForm">
        <el-form-item label="流程类型">
          <el-select v-model="queryForm.processType" placeholder="全部" clearable style="width: 180px;">
            <el-option label="数据融合" value="fusion" />
            <el-option label="密钥生成" value="keygen" />
            <el-option label="模型加密" value="encrypt" />
            <el-option label="联合运算" value="compute" />
            <el-option label="数据解密" value="decrypt" />
            <el-option label="数据交换" value="exchange" />
          </el-select>
        </el-form-item>
        <el-form-item label="日志级别">
          <el-select v-model="queryForm.logLevel" placeholder="全部" clearable style="width: 120px;">
            <el-option label="INFO" value="INFO" />
            <el-option label="WARN" value="WARN" />
            <el-option label="ERROR" value="ERROR" />
            <el-option label="DEBUG" value="DEBUG" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker v-model="queryForm.dateRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width: 360px;" />
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
  name: 'PoliceDataFusionLogRecord',
  data() {
    return {
      detailDialogVisible: false,
      currentLog: {},
      queryForm: { processType: '', logLevel: '', dateRange: [] },
      logList: [
        { logId: 'LOG001', processType: '数据融合', taskId: 'PDI-001', level: 'INFO', message: '数据融合任务开始执行，警务数据量: 15000, 保险数据量: 28000', operator: 'admin', createTime: '2024-01-15 10:30:00', detail: '任务配置:\n- 交集字段: 身份证号\n- 加密算法: 同态加密\n- 并行度: 8' },
        { logId: 'LOG002', processType: '数据融合', taskId: 'PDI-001', level: 'INFO', message: '数据预处理完成，开始执行隐私求交', operator: 'admin', createTime: '2024-01-15 10:31:15', detail: '预处理耗时: 75s\n数据清洗: 移除无效记录 23 条' },
        { logId: 'LOG003', processType: '密钥生成', taskId: 'HK-001', level: 'INFO', message: '同态加密密钥对生成成功', operator: 'admin', createTime: '2024-01-15 09:00:00', detail: '加密方案: CKKS\n多项式模数度: 8192\n安全级别: 128-bit' },
        { logId: 'LOG004', processType: '模型加密', taskId: 'ME-001', level: 'WARN', message: '模型参数量较大，加密过程可能耗时较长', operator: 'admin', createTime: '2024-01-15 10:05:00', detail: '模型参数量: 125000\n预计加密时间: 15-20分钟' },
        { logId: 'LOG005', processType: '联合运算', taskId: 'EC-001', level: 'INFO', message: '联合运算完成，输出密文结果', operator: 'admin', createTime: '2024-01-15 11:12:00', detail: '运算类型: 模型预测\n输入数据量: 15000\n输出数据量: 15000\n运算耗时: 12min' },
        { logId: 'LOG006', processType: '数据交换', taskId: 'EX-001', level: 'ERROR', message: '数据传输中断，尝试重连', operator: 'system', createTime: '2024-01-15 10:25:30', detail: '错误代码: CONNECTION_TIMEOUT\n目标机构: 平安保险\n已传输: 1.2GB / 2.5GB\n重试次数: 3' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    getLevelType(level) {
      return { INFO: 'success', WARN: 'warning', ERROR: 'danger', DEBUG: 'info' }[level] || 'info'
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
