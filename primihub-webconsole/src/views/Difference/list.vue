<template>
  <div class="container">
    <div class="search-area">
      <el-form :model="query" :inline="true" @keyup.enter.native="search">
        <el-form-item>
          <el-select v-model="query.organId" placeholder="请选择参与机构" clearable @clear="handleClear('organId')">
            <el-option
              v-for="item in organList"
              :key="item.globalId"
              :label="item.globalName"
              :value="item.globalId"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="query.taskName" placeholder="请输入任务名称" clearable @clear="handleClear('taskName')" />
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
            @change="handleDateChange"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="search">查询</el-button>
          <el-button icon="el-icon-refresh-right" @click="reset" />
          <el-button type="success" icon="el-icon-download" @click="handleExportLog">导出日志</el-button>
        </el-form-item>
      </el-form>
    </div>
    <div class="organ-container">
      <el-button class="add-button" icon="el-icon-circle-plus-outline" type="primary" @click="toTaskPage">联邦求差</el-button>
      <div class="organ">
        <el-table
          :data="allDataDifferenceTask"
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
            label="参与机构"
            align="center"
          >
            <template slot-scope="{row}">
              <el-tooltip :content="row.otherOrganName" placement="top"><span>{{ row.otherOrganName }}</span></el-tooltip>
            </template>
          </el-table-column>
          <el-table-column
            prop="differenceDirection"
            label="求差方向"
            align="center"
          >
            <template slot-scope="{row}">
              {{ row.differenceDirection === 0 ? '本机构 - 对方' : '对方 - 本机构' }}
            </template>
          </el-table-column>
          <el-table-column
            prop="tag"
            label="实现方法"
            align="center"
          >
            <template slot-scope="{row}">
              {{ row.tag | tagFilter }}
            </template>
          </el-table-column>
          <el-table-column label="发起时间" prop="createDate" min-width="120px">
            <template slot-scope="{row}">
              <span>{{ row.createDate.split(' ')[0] }}</span><br>
              <span>{{ row.createDate.split(' ')[1] }}</span><br>
            </template>
          </el-table-column>
          <el-table-column label="任务耗时">
            <template slot-scope="{row}">
              {{ row.consuming | timeFilter }}
            </template>
          </el-table-column>
          <el-table-column label="任务状态" prop="taskState">
            <template slot-scope="{row}">
              <i :class="statusStyle(row.taskState)" />
              <span>{{ row.taskState | taskStatusFilter }}</span>
              <span v-if="row.taskState === 2"> <i class="el-icon-loading" /></span>
            </template>
          </el-table-column>
          <el-table-column label="操作" fixed="right" min-width="120px" align="center">
            <template slot-scope="{row}">
              <p class="tool-buttons">
                <el-link type="primary" @click="toTaskDetailPage(row.taskId)">查看</el-link>
                <el-link v-if="row.taskState === 2" type="warning" @click="cancelTask(row)">取消</el-link>
                <el-link type="danger" :disabled="row.taskState === 2" @click="delDifferenceTask(row)">删除</el-link>
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
import { getAvailableOrganList } from '@/api/center'
import { getDifferenceTaskList, delDifferenceTask, cancelDifferenceTask, exportDifferenceLog } from '@/api/difference'
import Pagination from '@/components/Pagination'

export default {
  name: 'DifferenceDirectory',
  components: {
    Pagination
  },
  filters: {
    tagFilter(state) {
      const stateMap = {
        0: 'ECDH',
        1: 'KKRT',
        2: 'TEE'
      }
      return stateMap[state]
    }
  },
  data() {
    return {
      query: {
        organId: '',
        taskName: '',
        taskState: '',
        createDate: []
      },
      allDataDifferenceTask: [],
      organList: [],
      pageSize: 10,
      totalPage: 0,
      total: 0,
      pageNo: 1,
      timer: null,
      statusOptions: [
        {
          label: '运行中',
          value: 2
        }, {
          label: '成功',
          value: 1
        },
        {
          label: '失败',
          value: 3
        },
        {
          label: '已取消',
          value: 4
        }
      ]
    }
  },
  async created() {
    this.getDifferenceTaskList()
    await this.getAvailableOrganList()
    this.timer = window.setInterval(() => {
      setTimeout(this.getDifferenceTaskList(), 0)
    }, 3000)
  },
  destroyed() {
    clearInterval(this.timer)
  },
  methods: {
    handleDateChange(val) {
      if (!val) {
        this.query.createDate = []
        this.getDifferenceTaskList()
      }
    },
    handleClear(name) {
      this.query[name] = ''
      this.getDifferenceTaskList()
    },
    reset() {
      for (const key in this.query) {
        this.query[key] = ''
      }
      this.pageNo = 1
      this.getDifferenceTaskList()
    },
    toTaskPage() {
      this.$message.info('联邦求差任务创建页面开发中...')
      // this.$router.push({ name: 'DifferenceTask' })
    },
    toTaskDetailPage(id) {
      this.$message.info('联邦求差任务详情页面开发中...')
      // this.$router.push({ name: 'DifferenceDetail', params: { id } })
    },
    async getAvailableOrganList() {
      const { result } = await getAvailableOrganList()
      this.organList = result
    },
    statusStyle(state) {
      return state === 0 ? 'state-default' : state === 1 ? 'state-end' : state === 2 ? 'state-running' : state === 4 ? 'state-default' : 'state-error'
    },
    delDifferenceTask(row) {
      if (row.taskState === 2) return
      this.$confirm('此操作将永久删除该任务, 是否继续?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        delDifferenceTask({ taskId: row.taskId }).then(res => {
          if (res.code === 0) {
            const posIndex = this.allDataDifferenceTask.findIndex(item => item.taskId === row.taskId)
            if (posIndex !== -1) {
              this.allDataDifferenceTask.splice(posIndex, 1)
            }
            this.$message({
              message: '删除成功',
              type: 'success',
              duration: 1000
            })
            clearInterval(this.timer)
          }
        })
      }).catch(() => {})
    },
    async cancelTask(row) {
      const res = await cancelDifferenceTask({ taskId: row.taskId })
      if (res.code === 0) {
        const posIndex = this.allDataDifferenceTask.findIndex(item => item.taskId === row.taskId)
        this.allDataDifferenceTask[posIndex].taskState = 4
        this.$notify({
          message: '取消成功',
          type: 'success',
          duration: 1000
        })
      }
    },
    getDifferenceTaskList() {
      let params = {
        pageNo: this.pageNo,
        pageSize: this.pageSize
      }
      if (this.query.createDate && this.query.createDate.length > 0) {
        const startDate = this.query.createDate.length > 0 ? this.query.createDate[0] : ''
        const endDate = this.query.createDate.length > 0 ? this.query.createDate[1] : ''
        params = {
          ...params,
          startDate: startDate,
          endDate: endDate
        }
      }
      if (this.query.organId !== '') {
        params = {
          ...params,
          organId: this.query.organId
        }
      }
      if (this.query.taskState !== '') {
        params = {
          ...params,
          taskState: this.query.taskState
        }
      }
      if (this.query.taskName !== '') {
        params = {
          ...params,
          taskName: this.query.taskName
        }
      }
      getDifferenceTaskList(params).then(res => {
        const { data, totalPage, total } = res.result || { data: [], totalPage: 0, total: 0 }
        this.totalPage = totalPage
        this.total = total
        this.allDataDifferenceTask = data
        const result = this.allDataDifferenceTask.filter(item => item.taskState === 2)
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
      this.getDifferenceTaskList()
    },
    async search() {
      this.pageNo = 1
      await this.getDifferenceTaskList()
    },
    handleExportLog() {
      const params = {
        taskName: this.query.taskName || '',
        status: this.query.taskState !== '' ? this.query.taskState : null,
        startTime: this.query.createDate && this.query.createDate.length > 0 ? this.query.createDate[0] : '',
        endTime: this.query.createDate && this.query.createDate.length > 0 ? this.query.createDate[1] : ''
      }
      exportDifferenceLog(params).then(response => {
        const blob = new Blob([response], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `联邦求差任务日志_${new Date().getTime()}.xlsx`
        link.click()
        window.URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      }).catch(() => {
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
  .el-link{
    margin: 0 5px;
  }
}
</style>
