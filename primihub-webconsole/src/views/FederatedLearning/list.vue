<template>
  <div class="container">
    <div class="search-area">
      <el-form :model="query" :inline="true" @keyup.enter.native="search">
        <el-form-item>
          <el-input v-model="query.taskName" placeholder="请输入任务名称" clearable @clear="handleClear('taskName')" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="query.taskType" placeholder="请选择任务类型" clearable @clear="handleClear('taskType')">
            <el-option
              v-for="item in taskTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="query.algorithmType" placeholder="请选择算法类型" clearable @clear="handleClear('algorithmType')">
            <el-option
              v-for="item in algorithmTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="query.taskState" placeholder="请选择任务状态" clearable @clear="handleClear('taskState')">
            <el-option
              v-for="item in statusOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker
            v-model="query.createDate"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="yyyy-MM-dd HH:mm:ss"
            :default-time="['00:00:00', '23:59:59']"
            :picker-options="datePickerOptions"
            @change="handleDateChange"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="search">查询</el-button>
          <el-button icon="el-icon-refresh-right" @click="reset" />
          <el-button type="success" icon="el-icon-download" :loading="exporting" @click="handleExportLog">导出日志</el-button>
        </el-form-item>
      </el-form>
    </div>
    <div class="organ-container">
      <el-button class="add-button" icon="el-icon-circle-plus-outline" type="primary" @click="toTaskPage">创建联邦学习任务</el-button>
      <el-button type="primary" icon="el-icon-folder-opened" @click="toModelList">模型管理</el-button>
      <div class="organ">
        <el-table
          :data="taskList"
          class="table-list"
        >
          <el-table-column
            type="index"
            align="center"
            label="序号"
            width="50"
          />
          <el-table-column label="任务名称" min-width="120px">
            <template slot-scope="{row}">
              <el-tooltip :content="row.taskName" placement="top">
                <el-link type="primary" @click="toTaskDetailPage(row.taskId)">{{ row.taskName }}</el-link>
              </el-tooltip>
            </template>
          </el-table-column>
          <el-table-column
            label="任务类型"
            align="center"
            width="100"
          >
            <template slot-scope="{row}">
              <el-tag :type="row.taskType === 1 ? 'success' : 'primary'">
                {{ row.taskType === 1 ? '建模' : '预测' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column
            label="算法类型"
            align="center"
            width="120"
          >
            <template slot-scope="{row}">
              {{ row.algorithmType | algorithmTypeFilter }}
            </template>
          </el-table-column>
          <el-table-column
            label="联邦类型"
            align="center"
            width="100"
          >
            <template slot-scope="{row}">
              {{ row.federatedType === 1 ? '横向' : '纵向' }}
            </template>
          </el-table-column>
          <el-table-column
            label="训练进度"
            align="center"
            width="120"
          >
            <template slot-scope="{row}">
              <span v-if="row.taskType === 1 && row.taskState === 2">
                {{ row.currentRound || 0 }}/{{ row.totalRounds || 0 }}
              </span>
              <span v-else>-</span>
            </template>
          </el-table-column>
          <el-table-column
            label="准确率"
            align="center"
            width="100"
          >
            <template slot-scope="{row}">
              <span v-if="row.accuracy !== null && row.accuracy !== undefined">
                {{ (row.accuracy * 100).toFixed(2) }}%
              </span>
              <span v-else>-</span>
            </template>
          </el-table-column>
          <el-table-column label="创建时间" prop="createDate" min-width="120px">
            <template slot-scope="{row}">
              <span>{{ row.createDate ? row.createDate.split(' ')[0] : '' }}</span><br>
              <span>{{ row.createDate ? row.createDate.split(' ')[1] : '' }}</span>
            </template>
          </el-table-column>
          <el-table-column label="任务状态" prop="taskState" width="100">
            <template slot-scope="{row}">
              <i :class="statusStyle(row.taskState)" />
              <span>{{ row.taskState | taskStatusFilter }}</span>
              <span v-if="row.taskState === 2"> <i class="el-icon-loading" /></span>
            </template>
          </el-table-column>
          <el-table-column label="操作" fixed="right" min-width="180px" align="center">
            <template slot-scope="{row}">
              <p class="tool-buttons">
                <el-link type="primary" @click="toTaskDetailPage(row.taskId)">查看</el-link>
                <el-link v-if="row.taskType === 1 && row.taskState === 1" type="success" @click="downloadModel(row)">下载模型</el-link>
                <el-link v-if="row.taskType === 2 && row.taskState === 1" type="success" @click="downloadResult(row)">下载结果</el-link>
                <el-link v-if="row.taskState === 2" type="warning" @click="cancelTask(row)">取消</el-link>
                <el-link type="danger" :disabled="row.taskState === 2" @click="deleteTask(row)">删除</el-link>
              </p>
            </template>
          </el-table-column>
        </el-table>
        <pagination v-show="totalPage>1" :limit.sync="pageSize" :page-count="totalPage" :page.sync="pageNo" :total="total" @pagination="handlePagination" />
      </div>
    </div>
  </div>
</template>

<script>
import { getTaskList, deleteTask, cancelTask, downloadModel, downloadResult, exportFederatedLearningLog } from '@/api/federatedLearning'
import Pagination from '@/components/Pagination'
import { dateRangePickerOptions } from '@/utils/dateShortcuts'

export default {
  name: 'FederatedLearningList',
  components: {
    Pagination
  },
  filters: {
    algorithmTypeFilter(type) {
      const typeMap = {
        1: '线性回归',
        2: '逻辑回归',
        3: 'XGBoost'
      }
      return typeMap[type] || '未知'
    }
  },
  data() {
    return {
      query: {
        taskName: '',
        taskType: '',
        algorithmType: '',
        taskState: '',
        createDate: []
      },
      taskList: [],
      pageSize: 10,
      totalPage: 0,
      total: 0,
      pageNo: 1,
      timer: null,
      taskTypeOptions: [
        { label: '建模', value: 1 },
        { label: '预测', value: 2 }
      ],
      algorithmTypeOptions: [
        { label: '线性回归', value: 1 },
        { label: '逻辑回归', value: 2 },
        { label: 'XGBoost', value: 3 }
      ],
      statusOptions: [
        { label: '运行中', value: 2 },
        { label: '成功', value: 1 },
        { label: '失败', value: 3 },
        { label: '已取消', value: 4 }
      ],
      datePickerOptions: dateRangePickerOptions,
      exporting: false
    }
  },
  created() {
    this.getTaskList()
    this.timer = window.setInterval(() => {
      setTimeout(this.getTaskList(), 0)
    }, 3000)
  },
  destroyed() {
    clearInterval(this.timer)
  },
  methods: {
    handleDateChange(val) {
      if (!val) {
        this.query.createDate = []
        this.getTaskList()
      }
    },
    handleClear(name) {
      this.query[name] = ''
      this.getTaskList()
    },
    reset() {
      for (const key in this.query) {
        if (key === 'createDate') {
          this.query[key] = []
        } else {
          this.query[key] = ''
        }
      }
      this.pageNo = 1
      this.getTaskList()
    },
    toTaskPage() {
      this.$router.push({ name: 'FederatedModelingWorkbench' })
    },
    toModelList() {
      this.$router.push({ name: 'ModelList' })
    },
    toTaskDetailPage(id) {
      this.$message.info('联邦学习任务详情页面开发中...')
      // this.$router.push({ name: 'FederatedLearningDetail', params: { id } })
    },
    statusStyle(state) {
      return state === 0 ? 'state-default' : state === 1 ? 'state-end' : state === 2 ? 'state-running' : state === 4 ? 'state-default' : 'state-error'
    },
    deleteTask(row) {
      if (row.taskState === 2) return
      this.$confirm('此操作将永久删除该任务, 是否继续?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteTask({ taskId: row.taskId }).then(res => {
          if (res.code === 0) {
            const posIndex = this.taskList.findIndex(item => item.taskId === row.taskId)
            if (posIndex !== -1) {
              this.taskList.splice(posIndex, 1)
            }
            this.$message({
              message: '删除成功',
              type: 'success',
              duration: 1000
            })
            clearInterval(this.timer)
          }
        })
      }).catch(e => { console.error('取消删除', e) })
    },
    async cancelTask(row) {
      const res = await cancelTask({ taskId: row.taskId })
      if (res.code === 0) {
        const posIndex = this.taskList.findIndex(item => item.taskId === row.taskId)
        this.taskList[posIndex].taskState = 4
        this.$notify({
          message: '取消成功',
          type: 'success',
          duration: 1000
        })
      }
    },
    downloadModel(row) {
      downloadModel({ modelId: row.modelId }).then(response => {
        const blob = new Blob([response], { type: 'application/octet-stream' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `model_${row.taskId}_${new Date().getTime()}.pkl`
        link.click()
        window.URL.revokeObjectURL(url)
        this.$message.success('下载成功')
      }).catch(e => {
        console.error('下载失败', e)
        this.$message.error('下载失败')
      })
    },
    downloadResult(row) {
      downloadResult({ taskId: row.taskId }).then(response => {
        const blob = new Blob([response], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `prediction_result_${row.taskId}_${new Date().getTime()}.xlsx`
        link.click()
        window.URL.revokeObjectURL(url)
        this.$message.success('下载成功')
      }).catch(e => {
        console.error('下载失败', e)
        this.$message.error('下载失败')
      })
    },
    getTaskList() {
      let params = {
        pageNo: this.pageNo,
        pageSize: this.pageSize
      }
      if (this.query.createDate && this.query.createDate.length > 0) {
        params = {
          ...params,
          startDate: this.query.createDate[0],
          endDate: this.query.createDate[1]
        }
      }
      if (this.query.taskName !== '') {
        params.taskName = this.query.taskName
      }
      if (this.query.taskType !== '') {
        params.taskType = this.query.taskType
      }
      if (this.query.algorithmType !== '') {
        params.algorithmType = this.query.algorithmType
      }
      if (this.query.taskState !== '') {
        params.taskState = this.query.taskState
      }

      getTaskList(params).then(res => {
        const { data, totalPage, total } = res.result || { data: [], totalPage: 0, total: 0 }
        this.totalPage = totalPage
        this.total = total
        this.taskList = data
        const result = this.taskList.filter(item => item.taskState === 2)
        if (result.length === 0) {
          clearInterval(this.timer)
        }
      }).catch(error => {
        console.log(error)
        clearInterval(this.timer)
      })
    },
    handlePagination(data) {
      this.pageNo = data.page
      this.getTaskList()
    },
    async search() {
      this.pageNo = 1
      await this.getTaskList()
    },
    handleExportLog() {
      const params = {
        taskName: this.query.taskName || '',
        status: this.query.taskState !== '' ? this.query.taskState : null,
        startTime: this.query.createDate && this.query.createDate.length > 0 ? this.query.createDate[0] : '',
        endTime: this.query.createDate && this.query.createDate.length > 0 ? this.query.createDate[1] : ''
      }
      exportFederatedLearningLog(params).then(response => {
        const blob = new Blob([response], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `联邦学习任务日志_${new Date().getTime()}.xlsx`
        link.click()
        window.URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      }).catch(e => {
        console.error('导出失败', e)
        this.$message.error('导出失败')
      })
    }
  }
}
</script>

<style lang="scss" scoped>
::v-deep .el-input--suffix .el-input__inner{
  padding-right: 0;
}
.el-date-editor--datetimerange.el-input, .el-date-editor--datetimerange.el-input__inner{
  width: 360px;
  padding: 3px 5px;
}
.search-area {
  padding: 48px 40px 20px 40px;
  background-color: #fff;
  display: flex;
  flex-wrap: wrap;
  border-radius: 12px;
}
.el-table{
  cursor: pointer;
  margin-top: 24px;
}
.organ-container{
  border-radius: 12px;
  padding: 25px 40px;
  background-color: #fff;
  margin-top: 20px;
}
.pagination-container{
  padding-left:0;
  padding-right: 0;
}
.state-default,.state-running,.state-error,.state-end{
  width: 6px;
  height: 6px;
  border-radius: 50%;
  display: inline-block;
  vertical-align: middle;
  margin-right: 5px;
}
.state-default{
  background-color: #909399;
}
.state-end{
  background-color: #67C23A;
}
.state-running{
  background-color: #1677FF;
}
.state-error{
  background-color: #F56C6C;
}
.tool-buttons{
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
  .el-link{
    margin: 2px 5px;
  }
}
</style>
