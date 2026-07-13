<template>
  <div class="app-container">
    <el-page-header content="使用机构数据接入" style="margin-bottom: 20px;" @back="goBack" />

    <el-card>
      <div slot="header">
        <span>机构管理</span>
        <el-button style="float: right;" size="mini" type="primary" @click="handleAddOrg">新增机构</el-button>
      </div>
      <el-table :data="orgList" border>
        <el-table-column prop="orgId" label="机构ID" width="100" />
        <el-table-column prop="orgName" label="机构名称" width="180" />
        <el-table-column prop="orgType" label="机构类型" width="120" />
        <el-table-column prop="contactPerson" label="联系人" width="100" />
        <el-table-column prop="contactPhone" label="联系电话" width="140" />
        <el-table-column prop="apiKey" label="API Key" width="180" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'active' ? 'success' : 'info'" size="small">
              {{ scope.row.status === 'active' ? '已启用' : '已禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleConfig(scope.row)">配置</el-button>
            <el-button size="mini" type="text" @click="handleToggle(scope.row)">{{ scope.row.status === 'active' ? '禁用' : '启用' }}</el-button>
            <el-button size="mini" type="text" style="color: #F56C6C;" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card style="margin-top: 20px;">
      <div slot="header"><span>数据接入记录</span></div>
      <el-table :data="accessRecords" border>
        <el-table-column prop="recordId" label="记录ID" width="120" />
        <el-table-column prop="orgName" label="机构名称" width="150" />
        <el-table-column prop="dataType" label="数据类型" width="120" />
        <el-table-column prop="recordCount" label="数据量" width="100" />
        <el-table-column prop="accessTime" label="接入时间" width="160" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === 'success' ? 'success' : 'danger'" size="small">
              {{ scope.row.status === 'success' ? '成功' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleViewLog(scope.row)">日志</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog :visible.sync="dialogVisible" :title="dialogTitle" width="600px">
      <el-form ref="orgForm" :model="orgForm" label-width="100px">
        <el-form-item label="机构名称">
          <el-input v-model="orgForm.orgName" placeholder="请输入机构名称" />
        </el-form-item>
        <el-form-item label="机构类型">
          <el-select v-model="orgForm.orgType" placeholder="请选择机构类型" style="width: 100%;">
            <el-option label="银行" value="银行" />
            <el-option label="保险公司" value="保险公司" />
            <el-option label="政府机关" value="政府机关" />
            <el-option label="企业" value="企业" />
          </el-select>
        </el-form-item>
        <el-form-item label="联系人">
          <el-input v-model="orgForm.contactPerson" placeholder="请输入联系人" />
        </el-form-item>
        <el-form-item label="联系电话">
          <el-input v-model="orgForm.contactPhone" placeholder="请输入联系电话" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { importSceneData } from '@/api/scene'

export default {
  name: 'OrgDataImport',
  data() {
    return {
      dialogVisible: false,
      dialogTitle: '新增机构',
      orgForm: { orgName: '', orgType: '', contactPerson: '', contactPhone: '' },
      orgList: [
        { orgId: 'ORG001', orgName: '工商银行', orgType: '银行', contactPerson: '张经理', contactPhone: '13800138001', apiKey: 'ak_icbc_***', status: 'active' },
        { orgId: 'ORG002', orgName: '平安保险', orgType: '保险公司', contactPerson: '李经理', contactPhone: '13800138002', apiKey: 'ak_pingan_***', status: 'active' },
        { orgId: 'ORG003', orgName: '市民政局', orgType: '政府机关', contactPerson: '王主任', contactPhone: '13800138003', apiKey: 'ak_mzj_***', status: 'disabled' }
      ],
      accessRecords: [
        { recordId: 'ACC001', orgName: '工商银行', dataType: '身份验证请求', recordCount: 1250, accessTime: '2024-01-15 10:30:00', status: 'success' },
        { recordId: 'ACC002', orgName: '平安保险', dataType: '证件比对请求', recordCount: 850, accessTime: '2024-01-15 10:25:00', status: 'success' },
        { recordId: 'ACC003', orgName: '工商银行', dataType: '身份验证请求', recordCount: 0, accessTime: '2024-01-15 09:00:00', status: 'failed' }
      ]
    }
  },
  methods: {
    goBack() { this.$router.go(-1) },
    handleAddOrg() {
      this.dialogTitle = '新增机构'
      this.orgForm = { orgName: '', orgType: '', contactPerson: '', contactPhone: '' }
      this.dialogVisible = true
    },
    handleConfig(row) {
      this.$message.info(`配置机构: ${row.orgName}`)
    },
    handleToggle(row) {
      row.status = row.status === 'active' ? 'disabled' : 'active'
      this.$message.success(`机构已${row.status === 'active' ? '启用' : '禁用'}`)
    },
    handleDelete(row) {
      this.$confirm(`确定删除机构 ${row.orgName}?`, '提示', { type: 'warning' }).then(() => {
        this.orgList = this.orgList.filter(o => o.orgId !== row.orgId)
        this.$message.success('删除成功')
      }).catch(() => {})
    },
    handleViewLog(row) {
      this.$message.info(`查看日志: ${row.recordId}`)
    },
    // 缺陷整改 T2：新增机构改为真实提交后端（原仅本地 unshift、不落库）
    handleSave() {
      if (!this.orgForm.orgName) {
        this.$message.warning('请输入机构名称')
        return
      }
      const data = {
        taskName: `机构数据接入-${this.orgForm.orgName}`,
        action: 'orgImport',
        ...this.orgForm
      }
      importSceneData(data).then(res => {
        if (res && res.code === 0) {
          if (this.dialogTitle === '新增机构') {
            this.orgList.unshift({
              orgId: (res.result && (res.result.taskId || res.result.id)) || `ORG${Date.now()}`,
              ...this.orgForm,
              apiKey: `ak_${Date.now()}_***`,
              status: 'active'
            })
          }
          this.dialogVisible = false
          this.$message.success('保存成功')
        } else {
          this.$message.error((res && res.msg) || '保存失败')
        }
      }).catch(() => {
        this.$message.error('保存失败')
      })
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
