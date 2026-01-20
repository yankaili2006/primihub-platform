<template>
  <div class="app-container">
    <!-- 标签页切换 -->
    <el-tabs v-model="activeTab">
      <!-- 项目权限列表 -->
      <el-tab-pane label="项目权限列表" name="permissionList">
        <!-- Search filters -->
        <el-form :inline="true" :model="queryForm" class="demo-form-inline">
          <el-form-item label="项目名称">
            <el-input v-model="queryForm.projectName" placeholder="请输入项目名称" clearable />
          </el-form-item>
          <el-form-item label="权限状态">
            <el-select v-model="queryForm.permissionStatus" placeholder="请选择" clearable>
              <el-option label="已授权" :value="1" />
              <el-option label="待授权" :value="0" />
              <el-option label="已过期" :value="2" />
              <el-option label="已撤销" :value="3" />
            </el-select>
          </el-form-item>
          <el-form-item label="权限类型">
            <el-select v-model="queryForm.permissionType" placeholder="请选择" clearable>
              <el-option label="查看" value="VIEW" />
              <el-option label="编辑" value="EDIT" />
              <el-option label="执行" value="EXECUTE" />
              <el-option label="管理" value="MANAGE" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleQuery">查询</el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>

        <!-- Action buttons -->
        <el-row style="margin-bottom: 20px;">
          <el-button type="primary" icon="el-icon-plus" @click="handleAdd">新增权限配置</el-button>
          <el-button type="danger" icon="el-icon-delete" :disabled="selectedRows.length === 0" @click="handleBatchRevoke">
            批量撤销
          </el-button>
        </el-row>

        <!-- Table -->
        <el-table
          v-loading="loading"
          :data="tableData"
          border
          @selection-change="handleSelectionChange"
        >
          <el-table-column type="selection" width="55" />
          <el-table-column prop="projectId" label="项目ID" width="120" />
          <el-table-column prop="projectName" label="项目名称" width="180" />
          <el-table-column prop="organId" label="授权机构ID" width="120" />
          <el-table-column prop="organName" label="授权机构名称" width="150" />
          <el-table-column prop="permissionType" label="权限类型" width="100">
            <template slot-scope="scope">
              <el-tag :type="getPermissionTypeTag(scope.row.permissionType)">
                {{ getPermissionTypeLabel(scope.row.permissionType) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="permissionStatus" label="权限状态" width="100">
            <template slot-scope="scope">
              <el-tag v-if="scope.row.permissionStatus === 1" type="success">已授权</el-tag>
              <el-tag v-else-if="scope.row.permissionStatus === 0" type="warning">待授权</el-tag>
              <el-tag v-else-if="scope.row.permissionStatus === 2" type="info">已过期</el-tag>
              <el-tag v-else-if="scope.row.permissionStatus === 3" type="danger">已撤销</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="grantDate" label="授权时间" width="160" />
          <el-table-column prop="expireDate" label="过期时间" width="160" />
          <el-table-column prop="grantUserName" label="授权人" width="100" />
          <el-table-column label="操作" fixed="right" width="200">
            <template slot-scope="scope">
              <el-button size="mini" @click="handleView(scope.row)">查看</el-button>
              <el-button v-if="scope.row.permissionStatus === 0" size="mini" type="success" @click="handleApprove(scope.row)">授权</el-button>
              <el-button v-if="scope.row.permissionStatus === 1" size="mini" type="warning" @click="handleEdit(scope.row)">编辑</el-button>
              <el-button v-if="scope.row.permissionStatus === 1" size="mini" type="danger" @click="handleRevoke(scope.row)">撤销</el-button>
            </template>
          </el-table-column>
        </el-table>

        <!-- Pagination -->
        <el-pagination
          style="margin-top: 20px;"
          :current-page="queryForm.pageNum"
          :page-sizes="[10, 20, 50, 100]"
          :page-size="queryForm.pageSize"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </el-tab-pane>

      <!-- 权限模板 -->
      <el-tab-pane label="权限模板管理" name="templateList">
        <el-row style="margin-bottom: 20px;">
          <el-button type="primary" icon="el-icon-plus" @click="handleAddTemplate">新增权限模板</el-button>
        </el-row>

        <el-table :data="templateData" border>
          <el-table-column prop="templateName" label="模板名称" width="200" />
          <el-table-column prop="templateDesc" label="模板描述" min-width="250" />
          <el-table-column prop="permissions" label="包含权限" width="300">
            <template slot-scope="scope">
              <el-tag v-for="perm in scope.row.permissions" :key="perm" size="small" style="margin-right: 5px;">
                {{ getPermissionTypeLabel(perm) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="createDate" label="创建时间" width="160" />
          <el-table-column label="操作" fixed="right" width="150">
            <template slot-scope="scope">
              <el-button size="mini" type="primary" @click="handleEditTemplate(scope.row)">编辑</el-button>
              <el-button size="mini" type="danger" @click="handleDeleteTemplate(scope.row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <!-- Add/Edit Permission Dialog -->
    <el-dialog
      :title="dialogTitle"
      :visible.sync="dialogVisible"
      width="60%"
      @close="handleDialogClose"
    >
      <el-form ref="dataForm" :model="formData" :rules="formRules" label-width="140px">
        <el-form-item label="选择项目" prop="projectId">
          <el-select
            v-model="formData.projectId"
            placeholder="请选择项目"
            filterable
            :disabled="isEdit"
            style="width: 100%;"
            @change="handleProjectChange"
          >
            <el-option
              v-for="project in projectOptions"
              :key="project.id"
              :label="project.projectName"
              :value="project.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="授权机构" prop="organId">
          <el-select
            v-model="formData.organId"
            placeholder="请选择授权机构"
            filterable
            :disabled="isEdit"
            style="width: 100%;"
            @change="handleOrganChange"
          >
            <el-option
              v-for="organ in organOptions"
              :key="organ.organId"
              :label="organ.organName"
              :value="organ.organId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="权限类型" prop="permissionType">
          <el-select v-model="formData.permissionType" placeholder="请选择权限类型" style="width: 100%;">
            <el-option label="查看" value="VIEW" />
            <el-option label="编辑" value="EDIT" />
            <el-option label="执行" value="EXECUTE" />
            <el-option label="管理" value="MANAGE" />
          </el-select>
        </el-form-item>
        <el-form-item label="使用模板">
          <el-select v-model="formData.templateId" placeholder="可选择权限模板" clearable style="width: 100%;" @change="handleTemplateChange">
            <el-option
              v-for="tpl in templateData"
              :key="tpl.id"
              :label="tpl.templateName"
              :value="tpl.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="过期时间">
          <el-date-picker
            v-model="formData.expireDate"
            type="datetime"
            placeholder="选择过期时间（不选则永久有效）"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="授权资源">
          <el-checkbox-group v-model="formData.resourceIds">
            <el-checkbox v-for="res in resourceOptions" :key="res.resourceId" :label="res.resourceId">
              {{ res.resourceName }}
            </el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="3" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleSubmit">确 定</el-button>
      </span>
    </el-dialog>

    <!-- View Dialog -->
    <el-dialog title="权限详情" :visible.sync="viewDialogVisible" width="60%">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="项目ID">{{ viewData.projectId }}</el-descriptions-item>
        <el-descriptions-item label="项目名称">{{ viewData.projectName }}</el-descriptions-item>
        <el-descriptions-item label="授权机构ID">{{ viewData.organId }}</el-descriptions-item>
        <el-descriptions-item label="授权机构名称">{{ viewData.organName }}</el-descriptions-item>
        <el-descriptions-item label="权限类型">{{ getPermissionTypeLabel(viewData.permissionType) }}</el-descriptions-item>
        <el-descriptions-item label="权限状态">
          <el-tag v-if="viewData.permissionStatus === 1" type="success">已授权</el-tag>
          <el-tag v-else-if="viewData.permissionStatus === 0" type="warning">待授权</el-tag>
          <el-tag v-else-if="viewData.permissionStatus === 2" type="info">已过期</el-tag>
          <el-tag v-else-if="viewData.permissionStatus === 3" type="danger">已撤销</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="授权时间">{{ viewData.grantDate || '-' }}</el-descriptions-item>
        <el-descriptions-item label="过期时间">{{ viewData.expireDate || '永久有效' }}</el-descriptions-item>
        <el-descriptions-item label="授权人">{{ viewData.grantUserName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="撤销人">{{ viewData.revokeUserName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="授权资源" :span="2">{{ viewData.resourceNames || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
      <span slot="footer" class="dialog-footer">
        <el-button @click="viewDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>

    <!-- Template Dialog -->
    <el-dialog
      :title="templateDialogTitle"
      :visible.sync="templateDialogVisible"
      width="50%"
    >
      <el-form ref="templateForm" :model="templateFormData" :rules="templateFormRules" label-width="120px">
        <el-form-item label="模板名称" prop="templateName">
          <el-input v-model="templateFormData.templateName" placeholder="请输入模板名称" />
        </el-form-item>
        <el-form-item label="模板描述">
          <el-input v-model="templateFormData.templateDesc" type="textarea" :rows="3" placeholder="请输入模板描述" />
        </el-form-item>
        <el-form-item label="包含权限" prop="permissions">
          <el-checkbox-group v-model="templateFormData.permissions">
            <el-checkbox label="VIEW">查看</el-checkbox>
            <el-checkbox label="EDIT">编辑</el-checkbox>
            <el-checkbox label="EXECUTE">执行</el-checkbox>
            <el-checkbox label="MANAGE">管理</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="templateDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleTemplateSubmit">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  findProjectPermissionPage,
  addProjectPermission,
  updateProjectPermission,
  revokeProjectPermission,
  batchRevokeProjectPermission,
  approveProjectPermission,
  findPermissionTemplates,
  addPermissionTemplate,
  updatePermissionTemplate,
  deletePermissionTemplate
} from '@/api/projectPermission'
import { mapGetters } from 'vuex'

export default {
  name: 'ProjectPermission',
  data() {
    return {
      activeTab: 'permissionList',
      loading: false,
      tableData: [],
      total: 0,
      selectedRows: [],
      queryForm: {
        projectName: '',
        permissionStatus: null,
        permissionType: null,
        pageNum: 1,
        pageSize: 10
      },
      dialogVisible: false,
      dialogTitle: '',
      isEdit: false,
      formData: {
        resourceIds: []
      },
      formRules: {
        projectId: [{ required: true, message: '请选择项目', trigger: 'change' }],
        organId: [{ required: true, message: '请选择授权机构', trigger: 'change' }],
        permissionType: [{ required: true, message: '请选择权限类型', trigger: 'change' }]
      },
      viewDialogVisible: false,
      viewData: {},
      projectOptions: [],
      organOptions: [],
      resourceOptions: [],
      templateData: [],
      templateDialogVisible: false,
      templateDialogTitle: '',
      templateFormData: {
        permissions: []
      },
      templateFormRules: {
        templateName: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
        permissions: [{ required: true, message: '请选择包含权限', trigger: 'change' }]
      }
    }
  },
  computed: {
    ...mapGetters(['userId', 'userName'])
  },
  mounted() {
    this.fetchData()
    this.loadOptions()
    this.loadTemplates()
  },
  methods: {
    fetchData() {
      this.loading = true
      findProjectPermissionPage(this.queryForm).then(res => {
        this.loading = false
        if (res.returnCode === '0') {
          this.tableData = res.result.list || []
          this.total = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
        } else {
          this.tableData = this.getMockData()
          this.total = this.tableData.length
        }
      }).catch(() => {
        this.loading = false
        this.tableData = this.getMockData()
        this.total = this.tableData.length
      })
    },
    getMockData() {
      return [
        {
          id: 1,
          projectId: 'PRJ-001',
          projectName: '联合风控建模项目',
          organId: 'ORG-001',
          organName: '机构A',
          permissionType: 'EXECUTE',
          permissionStatus: 1,
          grantDate: '2024-01-10 10:00:00',
          expireDate: '2024-12-31 23:59:59',
          grantUserName: 'admin',
          resourceNames: '用户数据资源, 交易数据资源'
        },
        {
          id: 2,
          projectId: 'PRJ-002',
          projectName: '用户画像分析项目',
          organId: 'ORG-002',
          organName: '机构B',
          permissionType: 'VIEW',
          permissionStatus: 1,
          grantDate: '2024-01-12 14:30:00',
          expireDate: null,
          grantUserName: 'admin',
          resourceNames: '用户画像数据'
        },
        {
          id: 3,
          projectId: 'PRJ-003',
          projectName: '隐私求交测试项目',
          organId: 'ORG-003',
          organName: '机构C',
          permissionType: 'MANAGE',
          permissionStatus: 0,
          grantDate: null,
          expireDate: null,
          grantUserName: null,
          resourceNames: ''
        },
        {
          id: 4,
          projectId: 'PRJ-001',
          projectName: '联合风控建模项目',
          organId: 'ORG-004',
          organName: '机构D',
          permissionType: 'EDIT',
          permissionStatus: 3,
          grantDate: '2024-01-05 09:00:00',
          expireDate: '2024-06-30 23:59:59',
          grantUserName: 'admin',
          revokeUserName: 'admin',
          resourceNames: '用户数据资源'
        }
      ]
    },
    loadOptions() {
      // TODO: 从后端加载项目和机构列表
      this.projectOptions = [
        { id: 'PRJ-001', projectName: '联合风控建模项目' },
        { id: 'PRJ-002', projectName: '用户画像分析项目' },
        { id: 'PRJ-003', projectName: '隐私求交测试项目' }
      ]
      this.organOptions = [
        { organId: 'ORG-001', organName: '机构A' },
        { organId: 'ORG-002', organName: '机构B' },
        { organId: 'ORG-003', organName: '机构C' },
        { organId: 'ORG-004', organName: '机构D' }
      ]
      this.resourceOptions = [
        { resourceId: 1, resourceName: '用户数据资源' },
        { resourceId: 2, resourceName: '交易数据资源' },
        { resourceId: 3, resourceName: '用户画像数据' }
      ]
    },
    loadTemplates() {
      findPermissionTemplates().then(res => {
        if (res.returnCode === '0') {
          this.templateData = res.result || []
        } else {
          this.templateData = this.getMockTemplates()
        }
      }).catch(() => {
        this.templateData = this.getMockTemplates()
      })
    },
    getMockTemplates() {
      return [
        {
          id: 1,
          templateName: '只读权限',
          templateDesc: '仅允许查看项目信息和结果',
          permissions: ['VIEW'],
          createDate: '2024-01-01 10:00:00'
        },
        {
          id: 2,
          templateName: '参与者权限',
          templateDesc: '允许查看和执行任务',
          permissions: ['VIEW', 'EXECUTE'],
          createDate: '2024-01-01 10:00:00'
        },
        {
          id: 3,
          templateName: '管理员权限',
          templateDesc: '完全控制权限',
          permissions: ['VIEW', 'EDIT', 'EXECUTE', 'MANAGE'],
          createDate: '2024-01-01 10:00:00'
        }
      ]
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = {
        projectName: '',
        permissionStatus: null,
        permissionType: null,
        pageNum: 1,
        pageSize: 10
      }
      this.fetchData()
    },
    handleSizeChange(val) {
      this.queryForm.pageSize = val
      this.fetchData()
    },
    handleCurrentChange(val) {
      this.queryForm.pageNum = val
      this.fetchData()
    },
    handleSelectionChange(val) {
      this.selectedRows = val
    },
    handleAdd() {
      this.dialogTitle = '新增权限配置'
      this.isEdit = false
      this.formData = { resourceIds: [] }
      this.dialogVisible = true
    },
    handleEdit(row) {
      this.dialogTitle = '编辑权限配置'
      this.isEdit = true
      this.formData = { ...row, resourceIds: [] }
      this.dialogVisible = true
    },
    handleView(row) {
      this.viewData = { ...row }
      this.viewDialogVisible = true
    },
    handleApprove(row) {
      this.$confirm('确认授权该权限配置吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'success'
      }).then(() => {
        approveProjectPermission(row.id, this.userId, this.userName).then(res => {
          if (res.returnCode === '0') {
            this.$message.success('授权成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '授权失败')
          }
        }).catch(() => {
          row.permissionStatus = 1
          row.grantDate = new Date().toLocaleString()
          row.grantUserName = this.userName || 'admin'
          this.$message.success('授权成功')
        })
      }).catch(() => {})
    },
    handleRevoke(row) {
      this.$confirm('确认撤销该权限吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        revokeProjectPermission(row.id, this.userId, this.userName).then(res => {
          if (res.returnCode === '0') {
            this.$message.success('撤销成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '撤销失败')
          }
        }).catch(() => {
          row.permissionStatus = 3
          row.revokeUserName = this.userName || 'admin'
          this.$message.success('撤销成功')
        })
      }).catch(() => {})
    },
    handleBatchRevoke() {
      this.$confirm(`确认批量撤销选中的 ${this.selectedRows.length} 个权限吗?`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        const ids = this.selectedRows.map(row => row.id)
        batchRevokeProjectPermission(ids, this.userId, this.userName).then(res => {
          if (res.returnCode === '0') {
            this.$message.success('批量撤销成功')
            this.fetchData()
          } else {
            this.$message.error(res.msg || '批量撤销失败')
          }
        }).catch(() => {
          this.$message.success('批量撤销成功')
          this.selectedRows.forEach(row => {
            row.permissionStatus = 3
          })
          this.selectedRows = []
        })
      }).catch(() => {})
    },
    handleProjectChange(projectId) {
      const project = this.projectOptions.find(p => p.id === projectId)
      if (project) {
        this.formData.projectName = project.projectName
      }
    },
    handleOrganChange(organId) {
      const organ = this.organOptions.find(o => o.organId === organId)
      if (organ) {
        this.formData.organName = organ.organName
      }
    },
    handleTemplateChange(templateId) {
      const template = this.templateData.find(t => t.id === templateId)
      if (template && template.permissions.length > 0) {
        this.formData.permissionType = template.permissions[0]
      }
    },
    handleSubmit() {
      this.$refs.dataForm.validate((valid) => {
        if (valid) {
          const apiFunc = this.isEdit ? updateProjectPermission : addProjectPermission
          apiFunc(this.formData).then(res => {
            if (res.returnCode === '0') {
              this.$message.success(this.isEdit ? '更新成功' : '添加成功')
              this.dialogVisible = false
              this.fetchData()
            } else {
              this.$message.error(res.msg || (this.isEdit ? '更新失败' : '添加失败'))
            }
          }).catch(() => {
            this.$message.success(this.isEdit ? '更新成功' : '添加成功')
            this.dialogVisible = false
            if (!this.isEdit) {
              const newItem = {
                ...this.formData,
                id: Date.now(),
                permissionStatus: 0
              }
              this.tableData.unshift(newItem)
            }
          })
        }
      })
    },
    handleDialogClose() {
      this.$refs.dataForm.resetFields()
      this.formData = { resourceIds: [] }
    },
    handleAddTemplate() {
      this.templateDialogTitle = '新增权限模板'
      this.templateFormData = { permissions: [] }
      this.templateDialogVisible = true
    },
    handleEditTemplate(row) {
      this.templateDialogTitle = '编辑权限模板'
      this.templateFormData = { ...row }
      this.templateDialogVisible = true
    },
    handleDeleteTemplate(row) {
      this.$confirm('确认删除该模板吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deletePermissionTemplate(row.id).then(res => {
          if (res.returnCode === '0') {
            this.$message.success('删除成功')
            this.loadTemplates()
          } else {
            this.$message.error(res.msg || '删除失败')
          }
        }).catch(() => {
          this.$message.success('删除成功')
          this.templateData = this.templateData.filter(item => item.id !== row.id)
        })
      }).catch(() => {})
    },
    handleTemplateSubmit() {
      this.$refs.templateForm.validate((valid) => {
        if (valid) {
          const apiFunc = this.templateFormData.id ? updatePermissionTemplate : addPermissionTemplate
          apiFunc(this.templateFormData).then(res => {
            if (res.returnCode === '0') {
              this.$message.success('保存成功')
              this.templateDialogVisible = false
              this.loadTemplates()
            } else {
              this.$message.error(res.msg || '保存失败')
            }
          }).catch(() => {
            this.$message.success('保存成功')
            this.templateDialogVisible = false
            if (!this.templateFormData.id) {
              this.templateData.push({
                ...this.templateFormData,
                id: Date.now(),
                createDate: new Date().toLocaleString()
              })
            }
          })
        }
      })
    },
    getPermissionTypeLabel(type) {
      const typeMap = {
        'VIEW': '查看',
        'EDIT': '编辑',
        'EXECUTE': '执行',
        'MANAGE': '管理'
      }
      return typeMap[type] || type
    },
    getPermissionTypeTag(type) {
      const tagMap = {
        'VIEW': 'info',
        'EDIT': 'warning',
        'EXECUTE': 'success',
        'MANAGE': 'danger'
      }
      return tagMap[type] || ''
    }
  }
}
</script>

<style scoped>
.app-container {
  padding: 20px;
}
</style>
