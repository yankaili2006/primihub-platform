<template>
  <div class="app-container">
    <el-page-header content="项目流程审核配置" style="margin-bottom:20px;" @back="$router.go(-1)" />

    <el-alert
      title="配置项目生命周期各阶段的审核流程，包括项目创建、任务发起、结果查看等关键节点的审批规则。"
      type="info" show-icon :closable="false" style="margin-bottom:20px;" />

    <el-row :gutter="20">
      <el-col :span="15">
        <el-card>
          <div slot="header">
            <span>审核流程节点配置</span>
            <el-button style="float:right;" type="primary" size="small" :loading="saving" @click="handleSave">保存配置</el-button>
          </div>

          <el-table :data="flowNodes" border>
            <el-table-column prop="nodeName" label="流程节点" width="180" />
            <el-table-column prop="description" label="说明" min-width="200" show-overflow-tooltip />
            <el-table-column label="是否需要审核" width="120" align="center">
              <template slot-scope="{row}">
                <el-switch v-model="row.requireApproval" />
              </template>
            </el-table-column>
            <el-table-column label="审核人" width="160">
              <template slot-scope="{row}">
                <el-select v-model="row.approverRole" :disabled="!row.requireApproval" size="small" style="width:140px;">
                  <el-option label="项目管理员" value="PROJECT_ADMIN" />
                  <el-option label="系统管理员" value="SYS_ADMIN" />
                  <el-option label="租户管理员" value="TENANT_ADMIN" />
                  <el-option label="指定用户" value="SPECIFIC_USER" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column label="超时时间（h）" width="130" align="center">
              <template slot-scope="{row}">
                <el-input-number
                  v-model="row.timeoutHours"
                  :disabled="!row.requireApproval"
                  :min="1" :max="720"
                  size="small"
                  style="width:100px;"
                />
              </template>
            </el-table-column>
            <el-table-column label="超时策略" width="130">
              <template slot-scope="{row}">
                <el-select v-model="row.timeoutPolicy" :disabled="!row.requireApproval" size="small" style="width:110px;">
                  <el-option label="自动通过" value="AUTO_APPROVE" />
                  <el-option label="自动拒绝" value="AUTO_REJECT" />
                  <el-option label="通知升级" value="ESCALATE" />
                </el-select>
              </template>
            </el-table-column>
          </el-table>
        </el-card>

        <el-card style="margin-top:20px;">
          <div slot="header"><span>通知配置</span></div>
          <el-form :model="notifyForm" label-width="140px">
            <el-form-item label="审核请求通知">
              <el-checkbox-group v-model="notifyForm.requestChannels">
                <el-checkbox label="EMAIL">邮件</el-checkbox>
                <el-checkbox label="SMS">短信</el-checkbox>
                <el-checkbox label="SYSTEM">系统消息</el-checkbox>
                <el-checkbox label="WEBHOOK">Webhook</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            <el-form-item label="审核结果通知">
              <el-checkbox-group v-model="notifyForm.resultChannels">
                <el-checkbox label="EMAIL">邮件</el-checkbox>
                <el-checkbox label="SMS">短信</el-checkbox>
                <el-checkbox label="SYSTEM">系统消息</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            <el-form-item label="超时提醒通知">
              <el-switch v-model="notifyForm.enableTimeoutReminder" />
              <span v-if="notifyForm.enableTimeoutReminder" style="margin-left:8px;color:#999;">
                超时前
                <el-input-number v-model="notifyForm.reminderHours" :min="1" :max="24" size="mini" style="width:60px;margin:0 4px;" />
                小时发送提醒
              </span>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="9">
        <el-card>
          <div slot="header"><span>审核统计（近30天）</span></div>
          <el-descriptions :column="1" border size="small">
            <el-descriptions-item label="待审核">
              <el-badge :value="pendingStats.pending" type="warning">
                <el-tag type="warning" size="small">待处理</el-tag>
              </el-badge>
            </el-descriptions-item>
            <el-descriptions-item label="已通过">{{ pendingStats.approved }}</el-descriptions-item>
            <el-descriptions-item label="已拒绝">{{ pendingStats.rejected }}</el-descriptions-item>
            <el-descriptions-item label="已超时">{{ pendingStats.timeout }}</el-descriptions-item>
            <el-descriptions-item label="平均审核耗时">{{ pendingStats.avgHours }}h</el-descriptions-item>
          </el-descriptions>
          <el-button style="width:100%;margin-top:12px;" @click="$router.push('/setting/approval')">
            查看审批工作流
          </el-button>
        </el-card>

        <el-card style="margin-top:16px;">
          <div slot="header"><span>待审核项目</span></div>
          <div v-if="pendingList.length === 0" style="text-align:center;color:#999;padding:20px;">暂无待审核项目</div>
          <div v-for="item in pendingList" :key="item.id" class="pending-item">
            <div class="pending-name">{{ item.projectName }}</div>
            <div class="pending-info">
              <span>{{ item.applyUser }}</span>
              <el-tag size="mini" type="warning" style="margin-left:8px;">{{ item.nodeType }}</el-tag>
            </div>
            <div class="pending-time">{{ item.applyTime }}</div>
            <div style="margin-top:8px;">
              <el-button type="success" size="mini" @click="handleApprove(item)">通过</el-button>
              <el-button type="danger" size="mini" @click="handleReject(item)">拒绝</el-button>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import request from '@/utils/request'

export default {
  name: 'ProjectApprovalConfig',
  data() {
    return {
      saving: false,
      flowNodes: [
        { nodeKey: 'CREATE', nodeName: '项目创建', description: '新建项目时触发，需审核项目合规性', requireApproval: true, approverRole: 'TENANT_ADMIN', timeoutHours: 24, timeoutPolicy: 'ESCALATE' },
        { nodeKey: 'ADD_MEMBER', nodeName: '成员加入', description: '添加项目参与方成员时触发', requireApproval: false, approverRole: 'PROJECT_ADMIN', timeoutHours: 48, timeoutPolicy: 'AUTO_REJECT' },
        { nodeKey: 'DATA_APPLY', nodeName: '数据申请', description: '申请使用合作方数据集时触发', requireApproval: true, approverRole: 'PROJECT_ADMIN', timeoutHours: 72, timeoutPolicy: 'AUTO_REJECT' },
        { nodeKey: 'TASK_START', nodeName: '任务发起', description: '发起联邦学习/查询任务时触发', requireApproval: false, approverRole: 'PROJECT_ADMIN', timeoutHours: 4, timeoutPolicy: 'ESCALATE' },
        { nodeKey: 'RESULT_VIEW', nodeName: '结果查看', description: '查看敏感计算结果时触发', requireApproval: true, approverRole: 'PROJECT_ADMIN', timeoutHours: 12, timeoutPolicy: 'AUTO_REJECT' },
        { nodeKey: 'RESULT_EXPORT', nodeName: '结果导出', description: '导出计算结果时触发', requireApproval: true, approverRole: 'TENANT_ADMIN', timeoutHours: 24, timeoutPolicy: 'AUTO_REJECT' },
        { nodeKey: 'ARCHIVE', nodeName: '项目归档', description: '归档/关闭项目时触发', requireApproval: false, approverRole: 'PROJECT_ADMIN', timeoutHours: 48, timeoutPolicy: 'AUTO_APPROVE' }
      ],
      notifyForm: {
        requestChannels: ['SYSTEM', 'EMAIL'],
        resultChannels: ['SYSTEM'],
        enableTimeoutReminder: true,
        reminderHours: 4
      },
      pendingStats: { pending: 3, approved: 42, rejected: 7, timeout: 2, avgHours: 6.5 },
      pendingList: [
        { id: 1, projectName: '联邦风控建模项目', applyUser: '张三', nodeType: '数据申请', applyTime: '2026-05-14 09:15:00' },
        { id: 2, projectName: '医疗数据联合分析', applyUser: '李四', nodeType: '结果导出', applyTime: '2026-05-14 11:30:00' }
      ]
    }
  },
  created() { this.fetchConfig() },
  methods: {
    async fetchConfig() {
      try {
        const res = await request({ url: '/project/approvalConfig/get', method: 'get' })
        if (res.code === 0 && res.result?.nodes) this.flowNodes = res.result.nodes
      } catch (e) { console.error(e) }
    },
    async handleSave() {
      this.saving = true
      try {
        const res = await request({ url: '/project/approvalConfig/save', method: 'post', type: 'json', data: { nodes: this.flowNodes, notify: this.notifyForm } })
        if (res.code === 0) { this.$message.success('审核配置已保存') } else { this.$message.error(res.message || '保存失败') }
      } catch (e) { this.$message.error('请求异常') } finally { this.saving = false }
    },
    async handleApprove(item) {
      try {
        await this.$confirm(`确认通过「${item.projectName}」的${item.nodeType}申请？`, '确认审核')
        const res = await request({ url: '/project/approval/approve', method: 'post', data: { id: item.id } })
        if (res.code === 0) { this.$message.success('已通过'); this.pendingList = this.pendingList.filter(p => p.id !== item.id) } else this.$message.error(res.message || '操作失败')
      } catch (e) { if (e !== 'cancel') this.$message.error('操作失败') }
    },
    async handleReject(item) {
      try {
        await this.$confirm(`确认拒绝「${item.projectName}」的${item.nodeType}申请？`, '确认拒绝', { type: 'warning' })
        const res = await request({ url: '/project/approval/reject', method: 'post', data: { id: item.id } })
        if (res.code === 0) { this.$message.success('已拒绝'); this.pendingList = this.pendingList.filter(p => p.id !== item.id) } else this.$message.error(res.message || '操作失败')
      } catch (e) { if (e !== 'cancel') this.$message.error('操作失败') }
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.pending-item { padding: 12px; border: 1px solid #ebeef5; border-radius: 4px; margin-bottom: 12px; }
.pending-item:last-child { margin-bottom: 0; }
.pending-name { font-weight: 600; font-size: 14px; }
.pending-info { font-size: 13px; color: #606266; margin-top: 4px; }
.pending-time { font-size: 12px; color: #909399; margin-top: 2px; }
</style>
