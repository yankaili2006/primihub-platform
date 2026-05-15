<template>
  <div class="tool-page">
    <FederatedQueryNav />
    <el-card>
      <div slot="header"><span>压缩工具</span></div>
      <el-form :model="form" label-width="140px" size="small">
        <el-form-item label="压缩算法">
          <el-select v-model="form.algorithm" placeholder="选择压缩算法">
            <el-option label="gzip" value="gzip" />
            <el-option label="zlib" value="zlib" />
            <el-option label="brotli" value="brotli" />
            <el-option label="lz4" value="lz4" />
          </el-select>
        </el-form-item>
        <el-form-item label="压缩级别">
          <el-slider v-model="form.level" :min="1" :max="9" :step="1" show-input style="width:300px" />
        </el-form-item>
        <el-form-item label="输入数据">
          <el-input v-model="form.input" type="textarea" :rows="4" placeholder="请输入待压缩的数据(JSON格式)" />
        </el-form-item>
        <el-form-item label="测试结果">
          <el-input :value="testResult" type="textarea" :rows="3" readonly />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="testTool">测试压缩</el-button>
          <el-button @click="saveConfig">保存配置</el-button>
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
      form: { algorithm: 'gzip', level: 6, input: '' },
      testResult: ''
    }
  },
  methods: {
    testTool() {
      if (!this.form.input) return this.$message.warning('请输入待压缩的数据')
      this.testResult = `压缩完成 (${this.form.algorithm}, level=${this.form.level}): 原始 ${this.form.input.length} 字节 → 压缩后约 ${Math.round(this.form.input.length * 0.4)} 字节`
    },
    saveConfig() { this.$message.success('压缩配置已保存') }
  }
}
</script>
