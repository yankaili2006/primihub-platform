<template>
  <div class="app-container">
    <el-page-header content="单方数据合并模块" style="margin-bottom: 20px;" @back="goBack" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>数据合并配置</span></div>
          <el-form ref="mergeForm" :model="mergeFormData" :rules="mergeRules" label-width="100px">
            <el-form-item label="合并名称" prop="mergeName">
              <el-input v-model="mergeFormData.mergeName" placeholder="请输入合并任务名称" />
            </el-form-item>
            <el-form-item label="数据源选择" prop="dataSources">
              <el-select v-model="mergeFormData.dataSources" multiple placeholder="请选择数据源" style="width: 100%;">
                <el-option v-for="item in dataSourceList" :key="item.id" :label="item.name" :value="item.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="合并方式">
              <el-radio-group v-model="mergeFormData.mergeType">
                <el-radio label="UNION">纵向合并（Union）</el-radio>
                <el-radio label="JOIN">横向合并（Join）</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item v-if="mergeFormData.mergeType === 'JOIN'" label="关联字段" prop="joinKey">
              <el-select v-model="mergeFormData.joinKey" placeholder="请选择关联字段" style="width: 100%;">
                <el-option v-for="item in keyFieldList" :key="item" :label="item" :value="item" />
              </el-select>
            </el-form-item>
            <el-form-item label="去重处理">
              <el-switch v-model="mergeFormData.deduplication" />
            </el-form-item>
            <el-form-item label="输出格式">
              <el-select v-model="mergeFormData.outputFormat" style="width: 100%;">
                <el-option label="CSV" value="CSV" />
                <el-option label="Parquet" value="PARQUET" />
                <el-option label="数据库表" value="TABLE" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="handlePreview">预览</el-button>
              <el-button type="success" @click="handleMerge">执行合并</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>数据预览</span></div>
          <el-table v-if="previewData.length > 0" :data="previewData" border max-height="350">
            <el-table-column v-for="col in previewColumns" :key="col" :prop="col" :label="col" min-width="100" />
          </el-table>
          <el-empty v-else description="请选择数据源后点击预览" />
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>合并历史</span></div>
      <el-table :data="mergeHistory" border>
        <el-table-column prop="id" label="任务ID" width="100" />
        <el-table-column prop="name" label="任务名称" width="200" />
        <el-table-column prop="mergeType" label="合并方式" width="120">
          <template slot-scope="scope">
            {{ scope.row.mergeType === 'UNION' ? '纵向合并' : '横向合并' }}
          </template>
        </el-table-column>
        <el-table-column prop="sourceCount" label="数据源数" width="100" />
        <el-table-column prop="recordCount" label="结果行数" width="100" />
        <el-table-column prop="createTime" label="创建时间" width="180" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ getStatusLabel(scope.row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" @click="handleViewResult(scope.row)">查看</el-button>
            <el-button size="mini" type="primary" :disabled="scope.row.status !== 'completed'" @click="handleDownloadResult(scope.row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { createFLPreprocess } from '@/api/federatedLearning'

export default {
  name: 'SinglePartyDataMerge',
  data() {
    return {
      mergeFormData: {
        mergeName: '',
        dataSources: [],
        mergeType: 'UNION',
        joinKey: '',
        deduplication: true,
        outputFormat: 'CSV'
      },
      mergeRules: {
        mergeName: [{ required: true, message: '请输入合并任务名称', trigger: 'blur' }],
        dataSources: [{ required: true, message: '请选择数据源', trigger: 'change' }],
        joinKey: [{ required: true, message: '请选择关联字段', trigger: 'change' }]
      },
      dataSourceList: [
        { id: 'DS001', name: '用户基础信息表' },
        { id: 'DS002', name: '交易记录表' },
        { id: 'DS003', name: '风控特征表' },
        { id: 'DS004', name: '信用评分表' }
      ],
      keyFieldList: ['user_id', 'id_card', 'phone', 'email'],
      previewData: [],
      previewColumns: [],
      mergeHistory: [
        { id: 'MG001', name: '用户全量数据合并', mergeType: 'JOIN', sourceCount: 3, recordCount: 85000, createTime: '2024-01-15 14:00:00', status: 'completed' },
        { id: 'MG002', name: '历史交易数据合并', mergeType: 'UNION', sourceCount: 2, recordCount: 250000, createTime: '2024-01-14 10:30:00', status: 'completed' },
        { id: 'MG003', name: '风控特征合并', mergeType: 'JOIN', sourceCount: 4, recordCount: 0, createTime: '2024-01-15 16:00:00', status: 'running' }
      ]
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    handlePreview() {
      if (this.mergeFormData.dataSources.length === 0) {
        this.$message.warning('请选择数据源')
        return
      }
      this.previewColumns = ['user_id', 'name', 'age', 'credit_score', 'transaction_count']
      this.previewData = [
        { user_id: 'U001', name: '张三', age: 28, credit_score: 720, transaction_count: 156 },
        { user_id: 'U002', name: '李四', age: 35, credit_score: 680, transaction_count: 89 },
        { user_id: 'U003', name: '王五', age: 42, credit_score: 750, transaction_count: 234 }
      ]
      this.$message.success('数据预览已生成')
    },
    // 缺陷整改：改为真实提交合并任务（复用 FL 预处理 preprocess，subType=DATA_MERGE）
    handleMerge() {
      this.$refs.mergeForm.validate((valid) => {
        if (!valid) return
        const payload = {
          taskName: this.mergeFormData.mergeName,
          preprocessType: 'DATA_MERGE',
          mergeType: this.mergeFormData.mergeType,
          dataSources: this.mergeFormData.dataSources,
          resourceId: this.mergeFormData.dataSources.join(','),
          joinKey: this.mergeFormData.joinKey,
          deduplication: this.mergeFormData.deduplication,
          outputFormat: this.mergeFormData.outputFormat
        }
        createFLPreprocess(payload).then(res => {
          if (!res || res.code !== 0) {
            this.$message.error((res && (res.message || res.msg)) || '创建失败')
            return
          }
          this.$message.success('数据合并任务已创建')
          this.mergeHistory.unshift({
            id: (res.result && (res.result.taskId || res.result.id)) || `MG${Date.now()}`,
            name: this.mergeFormData.mergeName,
            mergeType: this.mergeFormData.mergeType,
            sourceCount: this.mergeFormData.dataSources.length,
            recordCount: 0,
            createTime: new Date().toLocaleString(),
            status: 'running'
          })
        }).catch(() => this.$message.error('请求异常'))
      })
    },
    handleViewResult(row) {
      this.$message.info(`查看合并结果: ${row.name}`)
    },
    handleDownloadResult(row) {
      this.$message.success(`开始下载: ${row.name}`)
    },
    getStatusType(status) {
      const map = { completed: 'success', running: 'warning', failed: 'danger' }
      return map[status] || 'info'
    },
    getStatusLabel(status) {
      const map = { completed: '已完成', running: '执行中', failed: '失败' }
      return map[status] || status
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
