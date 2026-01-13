<template>
  <div class="container">
    <div class="filter-bar">
      <el-input
        v-model="searchForm.keyword"
        placeholder="请输入IP地址或域名"
        style="width: 250px; margin-right: 10px;"
        clearable
        @clear="handleSearch"
      />
      <el-select
        v-model="searchForm.type"
        placeholder="请选择类型"
        style="width: 150px; margin-right: 10px;"
        clearable
        @change="handleSearch"
      >
        <el-option label="IP地址" value="IP" />
        <el-option label="域名" value="DOMAIN" />
        <el-option label="用户ID" value="USER_ID" />
      </el-select>
      <el-select
        v-model="searchForm.status"
        placeholder="请选择状态"
        style="width: 150px; margin-right: 10px;"
        clearable
        @change="handleSearch"
      >
        <el-option label="启用" :value="1" />
        <el-option label="禁用" :value="0" />
      </el-select>
      <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
      <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
    </div>
    <el-button v-if="hasAddPermission" type="primary" icon="el-icon-plus" @click="addWhitelist">新增白名单</el-button>
    <div class="main">
      <el-table
        :data="list"
        class="table-list"
      >
        <el-table-column align="center" label="序号" width="80" type="index" />
        <el-table-column align="left" label="ID" prop="id" width="80" />
        <el-table-column align="left" label="类型" prop="type" width="120">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.type === 'IP'" type="success">IP地址</el-tag>
            <el-tag v-else-if="scope.row.type === 'DOMAIN'" type="primary">域名</el-tag>
            <el-tag v-else-if="scope.row.type === 'USER_ID'" type="warning">用户ID</el-tag>
            <el-tag v-else type="info">{{ scope.row.type }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="left" label="值" prop="value" min-width="200" />
        <el-table-column align="left" label="描述" prop="description" min-width="200" show-overflow-tooltip />
        <el-table-column align="center" label="状态" prop="status" width="100">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.status === 1" type="success">启用</el-tag>
            <el-tag v-else type="danger">禁用</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="创建时间" prop="createTime" width="180" />
        <el-table-column v-if="hasEditPermission || hasDeletePermission" align="center" label="操作" fixed="right" width="180">
          <template slot-scope="scope">
            <el-button v-if="hasEditPermission" type="text" icon="edit" @click="openEdit(scope.row)"><i class="el-icon-edit" type="primary" />编辑</el-button>
            <el-button v-if="hasDeletePermission" type="text" icon="delete" @click="handleDelete(scope.row)"><i class="el-icon-delete" />删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </div>

    <!-- 新增/编辑白名单弹窗 -->
    <el-dialog :visible.sync="dialogVisible" custom-class="whitelist-dialog" :title="dialogTitle" closable :before-close="closeDialog">
      <el-form ref="whitelistForm" :model="whitelistInfo" label-width="100px" :rules="rules" label-position="right">
        <el-form-item label="类型" prop="type">
          <el-select v-model="whitelistInfo.type" placeholder="请选择类型" style="width: 100%;">
            <el-option label="IP地址" value="IP" />
            <el-option label="域名" value="DOMAIN" />
            <el-option label="用户ID" value="USER_ID" />
          </el-select>
        </el-form-item>
        <el-form-item label="值" prop="value">
          <el-input
            v-model="whitelistInfo.value"
            :placeholder="getValuePlaceholder()"
            maxlength="200"
            show-word-limit
          />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input
            v-model="whitelistInfo.description"
            type="textarea"
            :rows="3"
            placeholder="请输入描述信息"
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="whitelistInfo.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="closeDialog">取 消</el-button>
          <el-button type="primary" @click="enterDialog">确 定</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { getWhitelistPage, addWhitelist, updateWhitelist, deleteWhitelist } from '@/api/whitelist'
import Pagination from '@/components/Pagination'
import { mapGetters } from 'vuex'

export default {
  name: 'WhitelistList',
  components: {
    Pagination
  },
  data() {
    return {
      list: [],
      searchForm: {
        keyword: '',
        type: '',
        status: ''
      },
      dialogFlag: '',
      dialogTitle: '',
      whitelistInfo: {
        id: '',
        type: 'IP',
        value: '',
        description: '',
        status: 1
      },
      dialogVisible: false,
      rules: {
        type: [
          { required: true, message: '请选择类型', trigger: 'change' }
        ],
        value: [
          { required: true, message: '请输入值', trigger: 'blur' },
          { min: 1, max: 200, message: '值长度在1到200个字符之间', trigger: 'blur' }
        ],
        status: [
          { required: true, message: '请选择状态', trigger: 'change' }
        ]
      },
      itemTotalCount: 0,
      pageSize: 10,
      pageCount: 0,
      pageNum: 1
    }
  },
  computed: {
    hasAddPermission() {
      return this.buttonPermissionList.includes('WhitelistAdd')
    },
    hasEditPermission() {
      return this.buttonPermissionList.includes('WhitelistEdit')
    },
    hasDeletePermission() {
      return this.buttonPermissionList.includes('WhitelistDelete')
    },
    ...mapGetters([
      'buttonPermissionList'
    ])
  },
  created() {
    this.fetchData()
  },
  methods: {
    fetchData() {
      const params = {
        pageSize: this.pageSize,
        pageNum: this.pageNum,
        keyword: this.searchForm.keyword,
        type: this.searchForm.type,
        status: this.searchForm.status
      }
      getWhitelistPage(params).then((res) => {
        if (res.code === 0) {
          const { list, pageParam } = res.result
          this.list = list || []
          this.pageCount = Number(pageParam?.pageCount || 0)
          this.pageNum = Number(pageParam?.pageNum || 1)
          this.itemTotalCount = Number(pageParam?.itemTotalCount || 0)
        }
      })
    },
    handleSearch() {
      this.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.searchForm = {
        keyword: '',
        type: '',
        status: ''
      }
      this.pageNum = 1
      this.fetchData()
    },
    handlePagination(data) {
      this.pageNum = data.page
      this.fetchData()
    },
    openEdit(row) {
      this.dialogFlag = 'edit'
      this.dialogTitle = '编辑白名单'
      this.whitelistInfo = {
        id: row.id,
        type: row.type,
        value: row.value,
        description: row.description,
        status: row.status
      }
      this.dialogVisible = true
    },
    addWhitelist() {
      this.dialogTitle = '新增白名单'
      this.dialogVisible = true
      this.dialogFlag = 'add'
      this.whitelistInfo = {
        id: '',
        type: 'IP',
        value: '',
        description: '',
        status: 1
      }
    },
    clearForm() {
      this.$refs['whitelistForm'].resetFields()
      this.whitelistInfo = {
        id: '',
        type: 'IP',
        value: '',
        description: '',
        status: 1
      }
    },
    async handleDelete(row) {
      this.$confirm('此操作将永久删除该白名单, 是否继续?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async() => {
        const res = await deleteWhitelist({ id: row.id })
        if (res.code === 0) {
          this.$message({
            type: 'success',
            message: '删除成功'
          })
          this.fetchData()
        }
      })
    },
    closeDialog() {
      this.dialogVisible = false
      this.clearForm()
    },
    enterDialog() {
      this.$refs['whitelistForm'].validate(async valid => {
        if (valid) {
          const params = {
            id: this.whitelistInfo.id,
            type: this.whitelistInfo.type,
            value: this.whitelistInfo.value,
            description: this.whitelistInfo.description,
            status: this.whitelistInfo.status
          }

          const apiMethod = this.dialogFlag === 'add' ? addWhitelist : updateWhitelist
          const res = await apiMethod(params)
          if (res.code === 0) {
            const message = this.dialogFlag === 'add' ? '添加成功' : '更新成功'
            this.$message({
              type: 'success',
              message: message
            })
            this.closeDialog()
            this.fetchData()
          }
        }
      })
    },
    getValuePlaceholder() {
      const placeholders = {
        'IP': '请输入IP地址，如：192.168.1.1',
        'DOMAIN': '请输入域名，如：example.com',
        'USER_ID': '请输入用户ID'
      }
      return placeholders[this.whitelistInfo.type] || '请输入值'
    }
  }
}
</script>

<style lang="scss" scoped>
::v-deep .el-table th{
  background: #fafafa;
}
.container {
  padding: 20px;
  background-color: #f0f2f5;
}
.filter-bar {
  background-color: #fff;
  padding: 20px;
  margin-bottom: 15px;
  border-radius: 4px;
}
.table-list{
  margin-top: 15px;
}
.main{
  background-color: #fff;
  padding: 20px;
  border-radius: 4px;
}
::v-deep .whitelist-dialog {
  min-width: 500px;
}
</style>
