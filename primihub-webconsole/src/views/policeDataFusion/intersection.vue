<template>
  <div class="app-container">
    <el-page-header content="警务数据交集数据融合" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header"><span>数据源配置</span></div>
      <el-form ref="configForm" :model="configForm" label-width="120px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="警务数据源">
              <el-select v-model="configForm.policeDataSource" placeholder="请选择警务数据源" style="width: 100%;">
                <el-option v-for="item in policeDataSources" :key="item.id" :label="item.name" :value="item.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="保险数据源">
              <el-select v-model="configForm.insuranceDataSource" placeholder="请选择保险数据源" style="width: 100%;">
                <el-option v-for="item in insuranceDataSources" :key="item.id" :label="item.name" :value="item.id" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="交集字段">
              <el-select v-model="configForm.intersectField" placeholder="请选择交集字段" style="width: 100%;">
                <el-option label="身份证号" value="idCard" />
                <el-option label="手机号" value="phone" />
                <el-option label="姓名+身份证号" value="nameAndIdCard" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="加密算法">
              <el-select v-model="configForm.encryptAlgorithm" placeholder="请选择加密算法" style="width: 100%;">
                <el-option label="RSA" value="RSA" />
                <el-option label="AES" value="AES" />
                <el-option label="同态加密" value="HE" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item>
          <el-button type="primary" :loading="computing" @click="handleCompute">开始融合计算</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>融合任务列表</span></div>
      <el-table :data="taskList" border>
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="taskName" label="任务名称" width="200" />
        <el-table-column prop="policeDataCount" label="警务数据量" width="120" />
        <el-table-column prop="insuranceDataCount" label="保险数据量" width="120" />
        <el-table-column prop="intersectCount" label="交集数量" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ scope.row.statusText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="150">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleView(scope.row)">查看</el-button>
            <el-button size="mini" type="text" @click="handleDownload(scope.row)">下载</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { createPoliceTask, getPoliceTaskList } from '@/api/scene'
export default {
  name: 'PoliceDataIntersection',
  data() {
    return {
      computing: false,
      configForm: {
        policeDataSource: '',
        insuranceDataSource: '',
        intersectField: 'idCard',
        encryptAlgorithm: 'HE'
      },
      policeDataSources: [
        { id: 'PD001', name: '省级公安数据中心' },
        { id: 'PD002', name: '市级公安数据中心' },
        { id: 'PD003', name: '车辆管理数据库' }
      ],
      insuranceDataSources: [
        { id: 'INS001', name: '人寿保险数据库' },
        { id: 'INS002', name: '财产保险数据库' },
        { id: 'INS003', name: '车辆保险数据库' }
      ],
      taskList: []
    }
  },
  mounted() {
    this.fetchTaskList()
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    getStatusType(status) {
      const types = { completed: 'success', running: 'warning', failed: 'danger' }
      return types[status] || 'info'
    },
    async fetchTaskList() {
      try {
        const res = await getPoliceTaskList({ taskType: 'intersection' })
        if (res.code === 0) this.taskList = res.result.list || []
      } catch (e) { console.error('获取任务列表失败', e) }
    },
    async handleCompute() {
      if (!this.configForm.policeDataSource || !this.configForm.insuranceDataSource) {
        return this.$message.warning('请选择数据源')
      }
      this.computing = true
      try {
        const res = await createPoliceTask({
          taskType: 'intersection',
          taskName: '警务数据融合',
          params: this.configForm
        })
        if (res.code === 0) {
          this.$message.success('融合计算任务已提交')
          this.fetchTaskList()
        }
      } catch (e) {
        this.$message.error('提交失败')
      } finally {
        this.computing = false
      }
    },
    handleReset() {
      this.configForm = { policeDataSource: '', insuranceDataSource: '', intersectField: 'idCard', encryptAlgorithm: 'HE' }
    },
    handleView(row) {
      this.$message.info(`查看任务: ${row.taskId}`)
    },
    handleDownload(row) {
      this.$message.success(`开始下载任务结果: ${row.taskId}`)
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
