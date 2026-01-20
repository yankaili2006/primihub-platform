<template>
  <div class="app-container">
    <el-page-header @back="goBack" content="联邦查询实时接口校验" style="margin-bottom: 20px;" />

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span>接口测试</span></div>
          <el-form ref="testForm" :model="testForm" label-width="120px">
            <el-form-item label="接口地址">
              <el-input v-model="testForm.apiUrl" placeholder="请输入接口地址" />
            </el-form-item>
            <el-form-item label="请求方法">
              <el-select v-model="testForm.method" placeholder="选择请求方法" style="width: 100%;">
                <el-option label="GET" value="GET" />
                <el-option label="POST" value="POST" />
                <el-option label="PUT" value="PUT" />
                <el-option label="DELETE" value="DELETE" />
              </el-select>
            </el-form-item>
            <el-form-item label="请求头">
              <el-input v-model="testForm.headers" type="textarea" :rows="3" placeholder='{"Content-Type": "application/json"}' />
            </el-form-item>
            <el-form-item label="请求体">
              <el-input v-model="testForm.body" type="textarea" :rows="5" placeholder='{"query": "test"}' />
            </el-form-item>
            <el-form-item label="超时时间">
              <el-input-number v-model="testForm.timeout" :min="1" :max="60" />
              <span style="margin-left: 10px;">秒</span>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="testing" @click="handleTest">发送请求</el-button>
              <el-button @click="handleClear">清空</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card style="margin-top: 20px;">
          <div slot="header"><span>快速测试模板</span></div>
          <el-button size="small" @click="loadTemplate('psi')">PSI查询</el-button>
          <el-button size="small" @click="loadTemplate('pir')">PIR查询</el-button>
          <el-button size="small" @click="loadTemplate('fl')">联邦学习</el-button>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card>
          <div slot="header"><span>响应结果</span></div>
          <div v-if="response" class="response-container">
            <el-descriptions :column="1" border size="small">
              <el-descriptions-item label="状态码">
                <el-tag :type="getStatusType(response.status)" size="small">{{ response.status }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="响应时间">{{ response.duration }}ms</el-descriptions-item>
              <el-descriptions-item label="数据大小">{{ response.size }}</el-descriptions-item>
            </el-descriptions>
            <div class="response-body">
              <div class="response-header">响应体:</div>
              <pre>{{ response.body }}</pre>
            </div>
          </div>
          <el-empty v-else description="暂无响应数据" />
        </el-card>

        <el-card style="margin-top: 20px;">
          <div slot="header"><span>校验规则</span></div>
          <el-form size="small">
            <el-form-item label="状态码校验">
              <el-checkbox-group v-model="validationRules.statusCodes">
                <el-checkbox label="200">200 OK</el-checkbox>
                <el-checkbox label="201">201 Created</el-checkbox>
                <el-checkbox label="400">400 Bad Request</el-checkbox>
                <el-checkbox label="401">401 Unauthorized</el-checkbox>
                <el-checkbox label="500">500 Server Error</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            <el-form-item label="响应时间">
              <el-input-number v-model="validationRules.maxDuration" :min="100" :max="10000" :step="100" />
              <span style="margin-left: 10px;">ms</span>
            </el-form-item>
            <el-form-item label="必需字段">
              <el-input v-model="validationRules.requiredFields" placeholder="code,data,message" />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top: 20px;">
      <div slot="header">
        <span>测试历史</span>
        <el-button style="float: right; padding: 3px 0" type="text" @click="handleClearHistory">清空历史</el-button>
      </div>
      <el-table :data="testHistory" border>
        <el-table-column prop="timestamp" label="时间" width="180" />
        <el-table-column prop="method" label="方法" width="80" />
        <el-table-column prop="url" label="接口地址" min-width="200" />
        <el-table-column prop="status" label="状态码" width="100">
          <template slot-scope="scope">
            <el-tag :type="getStatusType(scope.row.status)" size="small">{{ scope.row.status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="duration" label="响应时间" width="120">
          <template slot-scope="scope">{{ scope.row.duration }}ms</template>
        </el-table-column>
        <el-table-column prop="validation" label="校验结果" width="100">
          <template slot-scope="scope">
            <el-tag :type="scope.row.validation === '通过' ? 'success' : 'danger'" size="small">
              {{ scope.row.validation }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleRetest(scope.row)">重测</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'FederatedQueryApiValidation',
  data() {
    return {
      testing: false,
      testForm: {
        apiUrl: '',
        method: 'POST',
        headers: '{"Content-Type": "application/json"}',
        body: '',
        timeout: 10
      },
      response: null,
      validationRules: {
        statusCodes: ['200'],
        maxDuration: 3000,
        requiredFields: 'code,data,message'
      },
      testHistory: [
        { timestamp: '2024-01-15 10:30:00', method: 'POST', url: '/api/psi/query', status: 200, duration: 245, validation: '通过' },
        { timestamp: '2024-01-15 11:20:00', method: 'POST', url: '/api/pir/query', status: 200, duration: 189, validation: '通过' },
        { timestamp: '2024-01-15 14:15:00', method: 'POST', url: '/api/fl/train', status: 500, duration: 5200, validation: '失败' }
      ],
      templates: {
        psi: {
          apiUrl: '/api/psi/query',
          method: 'POST',
          body: '{\n  "datasetId": "dataset001",\n  "queryFields": ["id", "name"],\n  "filters": {}\n}'
        },
        pir: {
          apiUrl: '/api/pir/query',
          method: 'POST',
          body: '{\n  "index": "user_001",\n  "queryType": "single"\n}'
        },
        fl: {
          apiUrl: '/api/fl/train',
          method: 'POST',
          body: '{\n  "modelType": "LR",\n  "participants": ["party1", "party2"],\n  "rounds": 100\n}'
        }
      }
    }
  },
  methods: {
    goBack() {
      this.$router.go(-1)
    },
    getStatusType(status) {
      if (status >= 200 && status < 300) return 'success'
      if (status >= 400 && status < 500) return 'warning'
      if (status >= 500) return 'danger'
      return 'info'
    },
    handleTest() {
      if (!this.testForm.apiUrl) {
        this.$message.warning('请输入接口地址')
        return
      }
      this.testing = true
      const startTime = Date.now()
      setTimeout(() => {
        const duration = Date.now() - startTime + Math.floor(Math.random() * 500)
        const status = Math.random() > 0.1 ? 200 : 500
        this.response = {
          status,
          duration,
          size: '1.2KB',
          body: JSON.stringify({
            code: status === 200 ? 0 : -1,
            message: status === 200 ? '请求成功' : '服务器错误',
            data: status === 200 ? { result: 'success', records: 100 } : null
          }, null, 2)
        }
        const validation = this.validateResponse(this.response)
        this.testHistory.unshift({
          timestamp: new Date().toLocaleString(),
          method: this.testForm.method,
          url: this.testForm.apiUrl,
          status: this.response.status,
          duration: this.response.duration,
          validation: validation ? '通过' : '失败'
        })
        this.testing = false
        this.$message.success('测试完成')
      }, 2000)
    },
    validateResponse(response) {
      if (!this.validationRules.statusCodes.includes(String(response.status))) return false
      if (response.duration > this.validationRules.maxDuration) return false
      return true
    },
    handleClear() {
      this.testForm = { apiUrl: '', method: 'POST', headers: '{"Content-Type": "application/json"}', body: '', timeout: 10 }
      this.response = null
    },
    handleClearHistory() {
      this.$confirm('确定清空测试历史?', '提示', { type: 'warning' }).then(() => {
        this.testHistory = []
        this.$message.success('已清空')
      })
    },
    loadTemplate(type) {
      const template = this.templates[type]
      this.testForm.apiUrl = template.apiUrl
      this.testForm.method = template.method
      this.testForm.body = template.body
      this.$message.success(`已加载${type.toUpperCase()}模板`)
    },
    handleRetest(row) {
      this.testForm.apiUrl = row.url
      this.testForm.method = row.method
      this.handleTest()
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
.response-container { margin-top: 10px; }
.response-body {
  margin-top: 15px;
  background: #f5f7fa;
  border-radius: 4px;
  padding: 15px;
}
.response-header {
  font-weight: bold;
  margin-bottom: 10px;
  color: #606266;
}
.response-body pre {
  margin: 0;
  white-space: pre-wrap;
  word-wrap: break-word;
  font-family: 'Courier New', monospace;
  font-size: 13px;
  color: #303133;
}
</style>
