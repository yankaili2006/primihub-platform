<template>
  <div class="app-container">
    <div class="filter-container">
      <el-input
        v-model="query.serverName"
        placeholder="服务器名称"
        clearable
        style="width: 200px;"
        class="filter-item"
        @keyup.enter.native="handleSearch"
      />
      <el-select v-model="query.serverType" placeholder="类型" clearable class="filter-item" style="width: 140px;">
        <el-option label="计算(compute)" value="compute" />
        <el-option label="存储(storage)" value="storage" />
        <el-option label="网关(gateway)" value="gateway" />
        <el-option label="TEE" value="tee" />
      </el-select>
      <el-select v-model="query.serverStatus" placeholder="状态" clearable class="filter-item" style="width: 120px;">
        <el-option label="离线" :value="0" />
        <el-option label="在线" :value="1" />
        <el-option label="维护中" :value="2" />
      </el-select>
      <el-button type="primary" icon="el-icon-search" class="filter-item" @click="handleSearch">查询</el-button>
      <el-button type="primary" icon="el-icon-plus" class="filter-item" @click="handleCreate">新增服务器</el-button>
    </div>

    <el-table v-loading="loading" :data="list" border fit style="width: 100%;">
      <el-table-column label="ID" prop="serverId" width="70" align="center" />
      <el-table-column label="名称" prop="serverName" min-width="140" show-overflow-tooltip />
      <el-table-column label="定位URL" prop="serverUrl" min-width="200" show-overflow-tooltip />
      <el-table-column label="IP" prop="serverIp" width="140" />
      <el-table-column label="端口" prop="serverPort" width="80" align="center" />
      <el-table-column label="类型" prop="serverType" width="110" align="center" />
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="{ row }">
          <el-tag :type="statusTag(row.serverStatus)">{{ statusText(row.serverStatus) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="CPU" prop="cpuCores" width="70" align="center" />
      <el-table-column label="内存(GB)" prop="memoryGb" width="90" align="center" />
      <el-table-column label="创建时间" prop="createDate" width="160" align="center" />
      <el-table-column label="操作" width="220" align="center" fixed="right">
        <template slot-scope="{ row }">
          <el-button type="text" @click="handleDetail(row)">详情/关联</el-button>
          <el-button type="text" @click="handleEdit(row)">编辑</el-button>
          <el-button type="text" class="danger-text" @click="handleDelete(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination
      v-show="total > 0"
      :total="total"
      :page.sync="query.pageNo"
      :limit.sync="query.pageSize"
      @pagination="getList"
    />
  </div>
</template>

<script>
import { findServerPage, deleteServer } from '@/api/server'
import Pagination from '@/components/Pagination'

export default {
  name: 'ServerList',
  components: { Pagination },
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      query: {
        serverName: '',
        serverType: '',
        serverStatus: undefined,
        pageNo: 1,
        pageSize: 10
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    statusText(s) {
      return { 0: '离线', 1: '在线', 2: '维护中' }[s] || '未知'
    },
    statusTag(s) {
      return { 0: 'info', 1: 'success', 2: 'warning' }[s] || 'info'
    },
    getList() {
      this.loading = true
      findServerPage(this.query)
        .then(res => {
          const data = res.data || {}
          this.list = data.list || []
          this.total = data.pageParam ? Number(data.pageParam.itemTotalCount || 0) : 0
        })
        .finally(() => {
          this.loading = false
        })
    },
    handleSearch() {
      this.query.pageNo = 1
      this.getList()
    },
    handleCreate() {
      this.$router.push({ name: 'ServerCreate' })
    },
    handleEdit(row) {
      this.$router.push({ name: 'ServerCreate', query: { serverId: row.serverId } })
    },
    handleDetail(row) {
      this.$router.push({ name: 'ServerDetail', params: { serverId: row.serverId } })
    },
    handleDelete(row) {
      this.$confirm(`确认删除服务器「${row.serverName}」？`, '提示', { type: 'warning' })
        .then(() => deleteServer(row.serverId))
        .then(() => {
          this.$message.success('删除成功')
          this.getList()
        })
        .catch(() => {})
    }
  }
}
</script>

<style scoped>
.filter-container {
  margin-bottom: 16px;
}
.filter-item {
  margin-right: 10px;
}
.danger-text {
  color: #f56c6c;
}
</style>
