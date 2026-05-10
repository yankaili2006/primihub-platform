<template>
  <div class="tool-page">
    <FederatedQueryNav />
    <el-card>
      <div slot="header"><span>编解码工具</span></div>
      <el-form :model="form" label-width="140px" size="small">
        <el-form-item label="启用">
          <el-switch v-model="form.enabled" />
        </el-form-item>
        <el-form-item label="参数配置">
          <el-input v-model="form.params" type="textarea" :rows="4" placeholder="请输入配置参数(JSON格式)" />
        </el-form-item>
        <el-form-item label="测试">
          <el-input v-model="form.testInput" placeholder="输入测试数据" />
          <el-button type="primary" size="mini" style="margin-left:10px" @click="testTool">测试</el-button>
        </el-form-item>
        <el-form-item label="测试结果">
          <el-input :value="testResult" type="textarea" :rows="3" readonly />
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
export default {
  components: { FederatedQueryNav },
  data() {
    return {
      form: { enabled: false, params: '{}', testInput: '' },
      testResult: ''
    }
  },
  methods: {
    testTool() { this.testResult = '测试完成: ' + this.form.testInput },
    saveConfig() { this.$message.success('配置已保存') }
  }
}
</script>
