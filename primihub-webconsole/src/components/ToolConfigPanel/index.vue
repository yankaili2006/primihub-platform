<template>
  <div class="tool-page">
    <FederatedQueryNav />
    <el-card v-loading="loading">
      <div slot="header"><span>{{ title }}</span>
        <el-tag v-if="config.status" size="mini" style="margin-left:10px">{{ config.status }} v{{ config.version }}</el-tag>
      </div>
      <el-form :model="form" label-width="140px" size="small">
        <el-form-item label="参数配置">
          <el-input v-model="form.params" type="textarea" :rows="4" placeholder="JSON，如 {&quot;chunkSize&quot;:1024}" />
        </el-form-item>
        <el-form-item label="测试输入">
          <el-input v-model="form.testInput" placeholder="输入测试数据">
            <el-button slot="append" @click="runTest">测试</el-button>
          </el-input>
        </el-form-item>
        <el-form-item label="测试结果">
          <el-input :value="testResult" type="textarea" :rows="6" readonly />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="saveConfig">保存配置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import FederatedQueryNav from '@/components/FederatedQueryNav'
import { testFederatedQueryTool, saveFederatedQueryToolConfig, getFederatedQueryToolConfig } from '@/api/federatedQuery'

export default {
  components: { FederatedQueryNav },
  props: {
    toolName: { type: String, required: true },
    title: { type: String, required: true }
  },
  data() {
    return { form: { params: '{}', testInput: '' }, testResult: '', config: {}, loading: false }
  },
  async mounted() {
    try {
      const { code, result } = await getFederatedQueryToolConfig({ toolName: this.toolName })
      if (code === 0 && result) {
        this.config = result
        if (result.defaultParams) this.form.params = JSON.stringify(result.defaultParams, null, 2)
      }
    } catch (e) { /* 配置读取失败不阻塞使用 */ }
  },
  methods: {
    parseParams() {
      try { return JSON.parse(this.form.params || '{}') } catch (e) {
        this.$message.error('参数不是合法 JSON'); return null
      }
    },
    async runTest() {
      const params = this.parseParams()
      if (params === null) return
      this.loading = true
      try {
        const { code, result, msg } = await testFederatedQueryTool({
          toolName: this.toolName, testInput: this.form.testInput, params
        })
        this.testResult = code === 0 ? JSON.stringify(result, null, 2) : `失败: ${msg}`
      } catch (e) {
        this.testResult = '请求失败，请检查网络'
      } finally { this.loading = false }
    },
    async saveConfig() {
      const params = this.parseParams()
      if (params === null) return
      const { code, result, msg } = await saveFederatedQueryToolConfig({ toolName: this.toolName, params })
      if (code === 0) this.$message.success(result || '配置已保存')
      else this.$message.error(msg || '保存失败')
    }
  }
}
</script>
