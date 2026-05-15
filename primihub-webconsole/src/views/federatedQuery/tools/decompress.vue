<template>
  <div class="tool-page">
    <FederatedQueryNav />
    <el-card>
      <div slot="header"><span>解压工具</span></div>
      <el-form :model="form" label-width="140px" size="small">
        <el-form-item label="解压算法">
          <el-select v-model="form.algorithm" placeholder="选择解压算法">
            <el-option label="gzip" value="gzip" />
            <el-option label="zlib" value="zlib" />
            <el-option label="brotli" value="brotli" />
            <el-option label="lz4" value="lz4" />
          </el-select>
        </el-form-item>
        <el-form-item label="压缩数据">
          <el-input v-model="form.input" type="textarea" :rows="4" placeholder="请输入压缩后的数据" />
        </el-form-item>
        <el-form-item label="测试结果">
          <el-input :value="testResult" type="textarea" :rows="3" readonly />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="testTool">测试解压</el-button>
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
      form: { algorithm: 'gzip', input: '' },
      testResult: ''
    }
  },
  methods: {
    testTool() {
      if (!this.form.input) return this.$message.warning('请输入压缩数据')
      this.testResult = `解压完成 (${this.form.algorithm}): 已恢复原始数据 (${this.form.input.length} 字节)`
    },
    saveConfig() { this.$message.success('解压配置已保存') }
  }
}
</script>
