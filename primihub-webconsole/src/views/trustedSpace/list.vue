<template>
  <div class="container">
    <div class="filter-bar">
      <el-input
        v-model="searchForm.spaceName"
        placeholder="请输入空间名称"
        style="width: 220px; margin-right: 10px;"
        clearable
        @clear="handleSearch"
        @keyup.enter.native="handleSearch"
      />
      <el-select
        v-model="searchForm.status"
        placeholder="请选择状态"
        style="width: 150px; margin-right: 10px;"
        clearable
        @change="handleSearch"
      >
        <el-option label="启用" :value="1" />
        <el-option label="停用" :value="0" />
      </el-select>
      <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
      <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
    </div>
    <el-button v-if="hasAddPermission" type="primary" icon="el-icon-plus" @click="openAdd">新建空间</el-button>
    <div class="main">
      <el-table v-loading="loading" :data="list" class="table-list">
        <el-table-column align="left" label="ID" prop="spaceId" width="90" />
        <el-table-column align="left" label="空间名称" prop="spaceName" min-width="160">
          <template slot-scope="{row}">
            <el-link v-if="hasDetailPermission" type="primary" @click="toDetail(row)">{{ row.spaceName }}</el-link>
            <span v-else>{{ row.spaceName }}</span>
            <el-tag v-if="row.isDefault === 1" size="mini" type="info" class="default-tag">缺省</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="left" label="编码" prop="spaceCode" min-width="140" show-overflow-tooltip />
        <el-table-column align="left" label="描述" prop="spaceDesc" min-width="200" show-overflow-tooltip />
        <el-table-column align="left" label="所属机构" prop="organName" min-width="140" show-overflow-tooltip />
        <el-table-column align="center" label="资源数" prop="resourceCount" width="90" />
        <el-table-column align="center" label="状态" prop="status" width="90">
          <template slot-scope="{row}">
            <el-tag v-if="row.status === 1" type="success" size="mini">启用</el-tag>
            <el-tag v-else type="danger" size="mini">停用</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="创建时间" prop="createDate" width="170" />
        <el-table-column align="center" label="操作" fixed="right" width="200">
          <template slot-scope="{row}">
            <el-button v-if="hasDetailPermission" type="text" @click="toDetail(row)">详情</el-button>
            <el-button v-if="hasEditPermission" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasDeletePermission && row.isDefault !== 1" type="text" class="danger-text" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="total>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNo" :total="total" @pagination="handlePagination" />
    </div>

    <el-dialog :visible.sync="dialogVisible" custom-class="space-dialog" :title="dialogTitle" :before-close="closeDialog">
      <el-form ref="spaceForm" :model="spaceForm" label-width="100px" :rules="rules" label-position="right">
        <el-form-item label="空间名称" prop="spaceName">
          <el-input v-model="spaceForm.spaceName" placeholder="如：水利 / 新能源车 / 农业" maxlength="128" show-word-limit />
        </el-form-item>
        <el-form-item label="空间编码" prop="spaceCode">
          <el-input
            v-model="spaceForm.spaceCode"
            :disabled="dialogFlag === 'edit' && spaceForm.isDefault === 1"
            placeholder="字母/数字/_/-，留空自动生成；与 pcloud 领域规则对齐时填 water/nev/agri"
            maxlength="64"
          />
        </el-form-item>
        <el-form-item label="描述" prop="spaceDesc">
          <el-input v-model="spaceForm.spaceDesc" type="textarea" :rows="3" placeholder="请输入描述信息" maxlength="512" show-word-limit />
        </el-form-item>
        <el-form-item label="排序" prop="sortIndex">
          <el-input-number v-model="spaceForm.sortIndex" :min="0" :max="9999" controls-position="right" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="spaceForm.status" :disabled="dialogFlag === 'edit' && spaceForm.isDefault === 1">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">停用</el-radio>
          </el-radio-group>
          <span v-if="dialogFlag === 'edit' && spaceForm.isDefault === 1" class="form-hint">缺省空间不可停用、不可改编码</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="closeDialog">取 消</el-button>
          <el-button type="primary" :loading="submitting" @click="submitDialog">确 定</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { getTrustedSpacePage, saveTrustedSpace, updateTrustedSpace, deleteTrustedSpace } from '@/api/trustedSpace'
import { SPACE_CODE_PATTERN } from '@/const/trustedSpace'
import Pagination from '@/components/Pagination'
import { mapGetters } from 'vuex'

const emptyForm = () => ({ spaceId: '', spaceName: '', spaceCode: '', spaceDesc: '', sortIndex: 100, status: 1, isDefault: 0 })

export default {
  name: 'TrustedSpaceList',
  components: { Pagination },
  data() {
    return {
      list: [],
      loading: false,
      submitting: false,
      searchForm: { spaceName: '', status: '' },
      dialogFlag: '',
      dialogTitle: '',
      dialogVisible: false,
      spaceForm: emptyForm(),
      rules: {
        spaceName: [
          { required: true, message: '请输入空间名称', trigger: 'blur' },
          { min: 1, max: 128, message: '长度在 1 到 128 个字符', trigger: 'blur' }
        ],
        spaceCode: [
          { pattern: SPACE_CODE_PATTERN, message: '仅允许字母、数字、_、-，长度 1-64', trigger: 'blur' }
        ],
        status: [{ required: true, message: '请选择状态', trigger: 'change' }]
      },
      total: 0,
      pageSize: 10,
      pageCount: 0,
      pageNo: 1
    }
  },
  computed: {
    hasAddPermission() {
      return this.buttonPermissionList.includes('TrustedSpaceAdd')
    },
    hasEditPermission() {
      return this.buttonPermissionList.includes('TrustedSpaceEdit')
    },
    hasDeletePermission() {
      return this.buttonPermissionList.includes('TrustedSpaceDelete')
    },
    hasDetailPermission() {
      return this.buttonPermissionList.includes('TrustedSpaceDetail')
    },
    ...mapGetters(['buttonPermissionList'])
  },
  created() {
    this.fetchData()
  },
  methods: {
    async fetchData() {
      this.loading = true
      try {
        const params = {
          pageNo: this.pageNo,
          pageSize: this.pageSize,
          spaceName: this.searchForm.spaceName,
          status: this.searchForm.status === '' ? undefined : this.searchForm.status
        }
        const res = await getTrustedSpacePage(params)
        if (res.code === 0) {
          const { data, total, totalPage } = res.result
          this.list = data || []
          this.total = total || 0
          this.pageCount = totalPage || 0
        }
      } finally {
        this.loading = false
      }
    },
    handleSearch() {
      this.pageNo = 1
      this.fetchData()
    },
    handleReset() {
      this.searchForm = { spaceName: '', status: '' }
      this.pageNo = 1
      this.fetchData()
    },
    handlePagination(data) {
      this.pageNo = data.page
      this.pageSize = data.limit
      this.fetchData()
    },
    toDetail(row) {
      this.$router.push({ name: 'TrustedSpaceDetail', params: { id: row.spaceId }})
    },
    openAdd() {
      this.dialogFlag = 'add'
      this.dialogTitle = '新建可信空间'
      this.spaceForm = emptyForm()
      this.dialogVisible = true
    },
    openEdit(row) {
      this.dialogFlag = 'edit'
      this.dialogTitle = '编辑可信空间'
      this.spaceForm = {
        spaceId: row.spaceId,
        spaceName: row.spaceName,
        spaceCode: row.spaceCode,
        spaceDesc: row.spaceDesc || '',
        sortIndex: row.sortIndex == null ? 100 : row.sortIndex,
        status: row.status,
        isDefault: row.isDefault
      }
      this.dialogVisible = true
    },
    closeDialog() {
      this.dialogVisible = false
      this.$nextTick(() => {
        this.$refs['spaceForm'] && this.$refs['spaceForm'].clearValidate()
        this.spaceForm = emptyForm()
      })
    },
    submitDialog() {
      this.$refs['spaceForm'].validate(async valid => {
        if (!valid) return
        this.submitting = true
        try {
          const f = this.spaceForm
          const payload = {
            spaceName: f.spaceName.trim(),
            spaceCode: f.spaceCode ? f.spaceCode.trim() : '',
            spaceDesc: f.spaceDesc,
            sortIndex: f.sortIndex,
            status: f.status
          }
          let res
          if (this.dialogFlag === 'add') {
            res = await saveTrustedSpace(payload)
          } else {
            res = await updateTrustedSpace({ spaceId: f.spaceId, ...payload })
          }
          if (res && res.code === 0) {
            this.$message({ type: 'success', message: this.dialogFlag === 'add' ? '新建成功' : '更新成功' })
            this.closeDialog()
            this.fetchData()
          }
        } finally {
          this.submitting = false
        }
      })
    },
    handleDelete(row) {
      const hint = row.resourceCount > 0
        ? `空间「${row.spaceName}」下有 ${row.resourceCount} 个资源，删除后它们将回到缺省空间。是否继续?`
        : `确定删除空间「${row.spaceName}」?`
      this.$confirm(hint, '提示', { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' })
        .then(async() => {
          const res = await deleteTrustedSpace({ spaceId: row.spaceId })
          if (res && res.code === 0) {
            const moved = res.result && res.result.movedResources
            this.$message({ type: 'success', message: moved ? `删除成功，${moved} 个资源已回到缺省空间` : '删除成功' })
            this.fetchData()
          }
        })
        .catch(() => {})
    }
  }
}
</script>

<style lang="scss" scoped>
::v-deep .el-table th {
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
.table-list {
  margin-top: 15px;
}
.main {
  background-color: #fff;
  padding: 20px;
  border-radius: 4px;
}
.default-tag {
  margin-left: 6px;
}
.danger-text {
  color: #f56c6c;
}
.form-hint {
  margin-left: 12px;
  color: #909399;
  font-size: 12px;
}
::v-deep .space-dialog {
  min-width: 560px;
}
</style>
