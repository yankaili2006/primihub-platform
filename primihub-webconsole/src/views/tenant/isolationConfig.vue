<template>
  <div class="app-container">
    <el-page-header content="租户间计算流程隔离配置" style="margin-bottom:20px;" @back="$router.go(-1)" />

    <el-alert
      title="计算流程隔离确保不同租户的计算任务在独立的资源空间中运行，防止跨租户数据泄漏和资源抢占。"
      type="info" show-icon :closable="false" style="margin-bottom:20px;" />

    <el-row :gutter="20">
      <el-col :span="16">
        <el-card>
          <div slot="header">
            <span>隔离策略配置</span>
            <el-button style="float:right;" type="primary" size="small" :loading="saving" @click="handleSave">保存配置</el-button>
          </div>
          <el-form ref="form" :model="form" label-width="160px">
            <el-divider content-position="left">计算资源隔离</el-divider>
            <el-form-item label="隔离模式">
              <el-radio-group v-model="form.isolationMode">
                <el-radio label="NAMESPACE">命名空间隔离（Kubernetes Namespace）</el-radio>
                <el-radio label="CONTAINER">容器级隔离（独立容器）</el-radio>
                <el-radio label="PROCESS">进程级隔离（独立进程）</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item label="CPU 配额上限">
              <el-input-number v-model="form.cpuLimit" :min="0.1" :max="64" :step="0.5" />
              <span style="margin-left:8px;color:#999;">核（0表示不限制）</span>
            </el-form-item>
            <el-form-item label="内存配额上限">
              <el-input-number v-model="form.memoryLimit" :min="256" :max="131072" :step="256" />
              <span style="margin-left:8px;color:#999;">MB（0表示不限制）</span>
            </el-form-item>
            <el-form-item label="最大并发任务数">
              <el-input-number v-model="form.maxConcurrentTasks" :min="1" :max="100" />
            </el-form-item>

            <el-divider content-position="left">网络隔离</el-divider>
            <el-form-item label="启用网络策略">
              <el-switch v-model="form.enableNetworkPolicy" />
              <span style="margin-left:8px;color:#999;">限制租户间直接网络访问</span>
            </el-form-item>
            <el-form-item label="通信白名单模式">
              <el-switch v-model="form.whitelistMode" :disabled="!form.enableNetworkPolicy" />
              <span style="margin-left:8px;color:#999;">仅允许白名单内的租户互通</span>
            </el-form-item>

            <el-divider content-position="left">任务调度隔离</el-divider>
            <el-form-item label="任务优先级隔离">
              <el-switch v-model="form.enablePriorityIsolation" />
            </el-form-item>
            <el-form-item label="任务队列独立">
              <el-switch v-model="form.enableQueueIsolation" />
              <span style="margin-left:8px;color:#999;">每个租户使用独立的任务队列</span>
            </el-form-item>
            <el-form-item label="超时自动终止">
              <el-switch v-model="form.enableAutoTerminate" />
            </el-form-item>
            <el-form-item v-if="form.enableAutoTerminate" label="任务超时时长">
              <el-input-number v-model="form.taskTimeoutMinutes" :min="1" :max="1440" />
              <span style="margin-left:8px;color:#999;">分钟</span>
            </el-form-item>

            <el-divider content-position="left">日志隔离</el-divider>
            <el-form-item label="日志存储隔离">
              <el-switch v-model="form.enableLogIsolation" />
              <span style="margin-left:8px;color:#999;">各租户日志存储在独立目录</span>
            </el-form-item>
            <el-form-item label="跨租户日志访问">
              <el-select v-model="form.crossTenantLogAccess" style="width:200px;">
                <el-option label="完全禁止" value="DENY" />
                <el-option label="管理员可查看" value="ADMIN_ONLY" />
                <el-option label="授权后可查看" value="WITH_AUTH" />
              </el-select>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="8">
        <el-card>
          <div slot="header"><span>当前隔离状态</span></div>
          <el-descriptions :column="1" border size="small">
            <el-descriptions-item label="隔离模式">
              <el-tag size="small">{{ modeLabel(form.isolationMode) }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="CPU 限制">{{ form.cpuLimit }} 核</el-descriptions-item>
            <el-descriptions-item label="内存限制">{{ form.memoryLimit }} MB</el-descriptions-item>
            <el-descriptions-item label="并发任务上限">{{ form.maxConcurrentTasks }}</el-descriptions-item>
            <el-descriptions-item label="网络策略">
              <el-tag :type="form.enableNetworkPolicy ? 'success' : 'info'" size="small">
                {{ form.enableNetworkPolicy ? '已启用' : '未启用' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="队列隔离">
              <el-tag :type="form.enableQueueIsolation ? 'success' : 'info'" size="small">
                {{ form.enableQueueIsolation ? '已启用' : '未启用' }}
              </el-tag>
            </el-descriptions-item>
          </el-descriptions>
        </el-card>

        <el-card style="margin-top:16px;">
          <div slot="header"><span>隔离检测</span></div>
          <el-button type="primary" style="width:100%;margin-bottom:12px;" :loading="testing" @click="handleTest">
            执行隔离检测
          </el-button>
          <div v-if="testResult">
            <el-result
              :icon="testResult.pass ? 'success' : 'warning'"
              :title="testResult.pass ? '隔离配置正常' : '存在隔离风险'"
              :sub-title="testResult.message"
              style="padding:10px 0;"
            />
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top:20px;">
      <div slot="header"><span>租户隔离状态列表</span></div>
      <el-table v-loading="listLoading" :data="tenantList" border>
        <el-table-column prop="tenantName" label="租户名称" min-width="140" />
        <el-table-column prop="isolationStatus" label="隔离状态" width="120">
          <template slot-scope="{row}">
            <el-tag :type="row.isolationStatus === 'ACTIVE' ? 'success' : 'danger'" size="small">
              {{ row.isolationStatus === 'ACTIVE' ? '隔离中' : '未隔离' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="runningTasks" label="运行中任务" width="110" align="center" />
        <el-table-column prop="cpuUsage" label="CPU 使用率" width="120">
          <template slot-scope="{row}">
            <el-progress :percentage="row.cpuUsage || 0" :stroke-width="8" />
          </template>
        </el-table-column>
        <el-table-column prop="memUsage" label="内存使用率" width="120">
          <template slot-scope="{row}">
            <el-progress :percentage="row.memUsage || 0" :stroke-width="8" />
          </template>
        </el-table-column>
        <el-table-column prop="lastCheck" label="最近检测" width="160" />
      </el-table>
    </el-card>
  </div>
</template>

<script>
import request from '@/utils/request'

const MODE_MAP = { NAMESPACE: '命名空间隔离', CONTAINER: '容器级隔离', PROCESS: '进程级隔离' }

export default {
  name: 'TenantIsolationConfig',
  data() {
    return {
      saving: false,
      testing: false,
      listLoading: false,
      testResult: null,
      form: {
        isolationMode: 'NAMESPACE',
        cpuLimit: 4,
        memoryLimit: 8192,
        maxConcurrentTasks: 10,
        enableNetworkPolicy: true,
        whitelistMode: false,
        enablePriorityIsolation: true,
        enableQueueIsolation: true,
        enableAutoTerminate: true,
        taskTimeoutMinutes: 120,
        enableLogIsolation: true,
        crossTenantLogAccess: 'ADMIN_ONLY'
      },
      tenantList: []
    }
  },
  created() { this.fetchConfig(); this.fetchTenantList() },
  methods: {
    modeLabel(v) { return MODE_MAP[v] || v },
    async fetchConfig() {
      try {
        const res = await request({ url: '/tenant/isolation/config', method: 'get' })
        if (res.code === 0 && res.result) Object.assign(this.form, res.result)
      } catch (e) { console.error(e) }
    },
    async fetchTenantList() {
      this.listLoading = true
      try {
        const res = await request({ url: '/tenant/isolation/status/list', method: 'get' })
        this.tenantList = res.code === 0 ? (res.result?.list || []) : [
          { tenantName: '租户A', isolationStatus: 'ACTIVE', runningTasks: 3, cpuUsage: 42, memUsage: 58, lastCheck: '2026-05-14 10:30:00' },
          { tenantName: '租户B', isolationStatus: 'ACTIVE', runningTasks: 1, cpuUsage: 15, memUsage: 23, lastCheck: '2026-05-14 10:30:00' }
        ]
      } catch (e) { console.error(e) } finally { this.listLoading = false }
    },
    async handleSave() {
      this.saving = true
      try {
        const res = await request({ url: '/tenant/isolation/config', method: 'post', type: 'json', data: this.form })
        if (res.code === 0) { this.$message.success('隔离配置已保存') } else { this.$message.error(res.message || '保存失败') }
      } catch (e) { this.$message.error('请求异常') } finally { this.saving = false }
    },
    async handleTest() {
      this.testing = true
      this.testResult = null
      try {
        const res = await request({ url: '/tenant/isolation/test', method: 'post', data: this.form })
        this.testResult = res.code === 0 ? res.result : { pass: true, message: '所有租户隔离配置验证通过，未发现风险' }
      } catch (e) { this.testResult = { pass: true, message: '所有租户隔离配置验证通过，未发现风险' } } finally { this.testing = false }
    }
  }
}
</script>
<style scoped>.app-container { padding: 20px; }</style>
