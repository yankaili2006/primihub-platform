<template>
  <div v-loading="listLoading" class="container">
    <div class="search-area">
      <el-button type="primary" class="upload-button" @click="toCreatePage"> <i class="el-icon-plus" /> 添加模型产物</el-button>
      <el-form :model="query" :inline="true" @keyup.enter.native="search">
        <el-form-item label="模型名称">
          <el-input v-model="query.modelName" size="small" placeholder="请输入模型名称" clearable />
        </el-form-item>
        <el-form-item label="产物类型">
          <el-select v-model="query.modelKind" size="small" placeholder="请选择" clearable>
            <el-option
              v-for="item in modelKindOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" size="small" @click="search">查询</el-button>
          <el-button icon="el-icon-refresh-right" size="small" @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>
    <div class="artifact-list">
      <el-table
        :data="artifactList"
        empty-text="暂无数据"
        border
      >
        <el-table-column
          prop="artifactId"
          label="产物ID"
          align="center"
        >
          <template slot-scope="{row}">
            <el-link type="primary" @click="toDetailPage(row.artifactId)">{{ row.artifactId }}</el-link>
          </template>
        </el-table-column>
        <el-table-column
          prop="modelName"
          label="模型名称"
          min-width="120"
        />
        <el-table-column
          prop="modelKind"
          label="产物类型"
          align="center"
        />
        <el-table-column
          prop="framework"
          label="框架"
          align="center"
        />
        <el-table-column
          prop="format"
          label="格式"
          align="center"
        />
        <el-table-column
          prop="version"
          label="版本"
          align="center"
        />
        <el-table-column
          prop="checksum"
          label="校验值"
          min-width="120"
          show-overflow-tooltip
        />
        <el-table-column
          label="上传者"
          min-width="160"
        >
          <template slot-scope="{row}">
            {{ row.userName }} <br>
            {{ row.createDate }}
          </template>
        </el-table-column>
        <el-table-column
          label="操作"
          fixed="right"
          width="160"
          align="center"
        >
          <template slot-scope="{row}">
            <el-button type="text" @click="toDetailPage(row.artifactId)">详情</el-button>
            <el-button type="text" @click="toEditPage(row.artifactId)">编辑</el-button>
            <el-button type="text" @click="handleDelete(row.artifactId)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>1" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNo" :total="total" @pagination="handlePagination" />
    </div>
  </div>
</template>

<script>
import { getModelArtifactList, delModelArtifact } from '@/api/modelArtifact'
import Pagination from '@/components/Pagination'
import { MODEL_KIND_OPTIONS } from '@/const/modelArtifact'

export default {
  components: { Pagination },
  data() {
    return {
      listLoading: false,
      query: {
        modelName: '',
        modelKind: ''
      },
      modelKindOptions: MODEL_KIND_OPTIONS,
      artifactList: [],
      total: 0,
      pageCount: 0,
      pageNo: 1,
      pageSize: 10
    }
  },
  created() {
    this.fetchData()
  },
  methods: {
    search() {
      this.pageNo = 1
      this.fetchData()
    },
    reset() {
      this.query.modelName = ''
      this.query.modelKind = ''
      this.pageNo = 1
      this.fetchData()
    },
    toCreatePage() {
      this.$router.push({
        name: 'ModelArtifactCreate'
      })
    },
    toEditPage(id) {
      this.$router.push({
        name: 'ModelArtifactEdit',
        params: { id }
      })
    },
    toDetailPage(id) {
      this.$router.push({
        name: 'ModelArtifactDetail',
        params: { id }
      })
    },
    handleDelete(artifactId) {
      this.$confirm('此操作将删除该模型产物, 是否继续?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        const res = await delModelArtifact(artifactId)
        if (res.code === 0) {
          this.$message({
            message: '删除成功',
            type: 'success'
          })
          this.fetchData()
        } else {
          this.$message({
            message: res.msg,
            type: 'error'
          })
        }
      }).catch(() => {})
    },
    async fetchData() {
      this.listLoading = true
      const { modelName, modelKind } = this.query
      const params = {
        pageNo: this.pageNo,
        pageSize: this.pageSize,
        modelName,
        modelKind
      }
      const res = await getModelArtifactList(params)
      if (res.code === 0) {
        const { data, total } = res.result
        this.artifactList = data || []
        this.total = total
        this.pageCount = Math.ceil(total / this.pageSize)
      }
      this.listLoading = false
    },
    handlePagination(data) {
      this.pageNo = data.page
      this.fetchData()
    }
  }
}
</script>
<style lang="scss" scoped>
@import "~@/styles/resource.scss";
.artifact-list {
  margin-top: 20px;
  border-top: 1px solid #eee;
  background-color: #fff;
  padding: 30px;
}
</style>
