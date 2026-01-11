<template>
  <div class="container">
    <el-row :gutter="20">
      <!-- API密钥管理 -->
      <el-col :span="12">
        <el-card>
          <div slot="header"><i class="el-icon-key" /> API密钥管理</div>
          <el-descriptions :column="1" border>
            <el-descriptions-item label="API Key">
              <span class="api-key">{{ apiKey }}</span>
              <el-button type="text" icon="el-icon-document-copy" @click="copyKey" />
            </el-descriptions-item>
            <el-descriptions-item label="Secret Key">
              <span class="api-key">{{ secretKey }}</span>
              <el-button type="text" icon="el-icon-document-copy" @click="copySecret" />
            </el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ keyInfo.createTime }}</el-descriptions-item>
            <el-descriptions-item label="过期时间">{{ keyInfo.expiryTime }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag v-if="keyInfo.status === 'ACTIVE'" type="success">激活</el-tag>
              <el-tag v-else type="danger">已禁用</el-tag>
            </el-descriptions-item>
          </el-descriptions>
          <div style="margin-top: 20px;">
            <el-button type="primary" @click="regenerateKey">重新生成密钥</el-button>
            <el-button type="danger" @click="revokeKey">撤销密钥</el-button>
          </div>
        </el-card>

        <!-- API测试 -->
        <el-card style="margin-top: 20px;">
          <div slot="header"><i class="el-icon-cpu" /> API测试</div>
          <el-form :model="testForm" label-width="100px">
            <el-form-item label="接口地址">
              <el-input v-model="testForm.apiUrl" placeholder="/api/evidence/query" />
            </el-form-item>
            <el-form-item label="请求方法">
              <el-select v-model="testForm.method" style="width: 100%;">
                <el-option label="GET" value="GET" />
                <el-option label="POST" value="POST" />
              </el-select>
            </el-form-item>
            <el-form-item label="请求参数">
              <el-input v-model="testForm.params" type="textarea" :rows="4" placeholder='{"key":"value"}' />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="testing" @click="testApi">发送请求</el-button>
            </el-form-item>
          </el-form>
          <div v-if="testResult" class="test-result">
            <el-divider content-position="left">响应结果</el-divider>
            <pre>{{ testResult }}</pre>
          </div>
        </el-card>
      </el-col>

      <!-- API文档 + 调用日志 -->
      <el-col :span="12">
        <el-card>
          <div slot="header"><i class="el-icon-document" /> API文档</div>
          <el-collapse v-model="activeApis" accordion>
            <el-collapse-item v-for="api in apiList" :key="api.id" :name="api.id">
              <template slot="title">
                <el-tag :type="api.method === 'GET' ? 'success' : 'primary'" size="small" style="margin-right: 10px;">{{ api.method }}</el-tag>
                <span>{{ api.path }}</span>
              </template>
              <div class="api-detail">
                <p><strong>描述：</strong>{{ api.description }}</p>
                <p><strong>请求参数：</strong></p>
                <pre>{{ api.params }}</pre>
                <p><strong>响应示例：</strong></p>
                <pre>{{ api.response }}</pre>
              </div>
            </el-collapse-item>
          </el-collapse>
        </el-card>

        <el-card style="margin-top: 20px;">
          <div slot="header"><i class="el-icon-notebook-2" /> 调用日志</div>
          <el-table :data="callLogs" size="small">
            <el-table-column label="时间" prop="callTime" width="150" />
            <el-table-column label="接口" prop="apiPath" show-overflow-tooltip />
            <el-table-column label="状态" width="80">
              <template slot-scope="scope">
                <el-tag v-if="scope.row.status === 'SUCCESS'" type="success" size="mini">成功</el-tag>
                <el-tag v-else type="danger" size="mini">失败</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import { getApiKey, regenerateApiKey, testApiConnection, getApiList, getApiCallLog } from '@/api/evidence'

export default {
  name: 'EvidenceApi',
  data() {
    return {
      apiKey: '',
      secretKey: '',
      keyInfo: {},
      testForm: { apiUrl: '/api/evidence/query', method: 'GET', params: '' },
      testing: false,
      testResult: null,
      activeApis: '',
      apiList: [],
      callLogs: []
    }
  },
  created() {
    this.fetchApiKey()
    this.fetchApiList()
    this.fetchCallLogs()
  },
  methods: {
    async fetchApiKey() {
      const res = await getApiKey()
      if (res.code === 0) {
        this.apiKey = res.result.apiKey
        this.secretKey = res.result.secretKey
        this.keyInfo = res.result
      }
    },
    async fetchApiList() {
      const res = await getApiList()
      if (res.code === 0) {
        this.apiList = res.result || []
      }
    },
    async fetchCallLogs() {
      const res = await getApiCallLog({ pageSize: 10 })
      if (res.code === 0) {
        this.callLogs = res.result?.list || []
      }
    },
    async regenerateKey() {
      this.$confirm('重新生成密钥后，旧密钥将失效，是否继续？', '警告', { type: 'warning' }).then(async() => {
        const res = await regenerateApiKey()
        if (res.code === 0) {
          this.$message.success('密钥已重新生成')
          this.fetchApiKey()
        }
      })
    },
    revokeKey() {
      this.$message.info('撤销功能开发中...')
    },
    async testApi() {
      this.testing = true
      const res = await testApiConnection(this.testForm)
      this.testing = false
      if (res.code === 0) {
        this.testResult = JSON.stringify(res.result, null, 2)
      }
    },
    copyKey() {
      navigator.clipboard.writeText(this.apiKey)
      this.$message.success('已复制到剪贴板')
    },
    copySecret() {
      navigator.clipboard.writeText(this.secretKey)
      this.$message.success('已复制到剪贴板')
    }
  }
}
</script>

<style lang="scss" scoped>
.container { padding: 20px; background-color: #f0f2f5; }
.api-key { font-family: 'Courier New', monospace; font-size: 14px; color: #409eff; }
.test-result, .api-detail { pre { background: #f5f7fa; padding: 15px; border-radius: 4px; font-size: 12px; } }
</style>
