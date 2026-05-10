<template>
  <el-card class="algorithm-selector">
    <el-row :gutter="20">
      <el-col :span="8">
        <div class="section-title">算法选择</div>
        <el-radio-group v-model="algorithm" @change="onChange">
          <el-radio-button label="DH">
            <div class="algo-option"><strong>DH</strong><br><small>Diffie-Hellman</small></div>
          </el-radio-button>
          <el-radio-button label="OT">
            <div class="algo-option"><strong>OT</strong><br><small>不经意传输</small></div>
          </el-radio-button>
          <el-radio-button label="HE">
            <div class="algo-option"><strong>HE</strong><br><small>全同态加密</small></div>
          </el-radio-button>
        </el-radio-group>
      </el-col>
      <el-col :span="8">
        <div class="section-title">模式选择</div>
        <el-radio-group v-model="mode" @change="onChange">
          <el-radio-button label="batch">
            <div class="algo-option"><strong>批量查询</strong><br><small>大规模数据</small></div>
          </el-radio-button>
          <el-radio-button label="realtime">
            <div class="algo-option"><strong>实时查询</strong><br><small>高频低延迟</small></div>
          </el-radio-button>
        </el-radio-group>
      </el-col>
      <el-col :span="8">
        <div class="section-title">算法说明</div>
        <el-tag :type="algorithm === 'DH' ? 'success' : algorithm === 'OT' ? 'warning' : 'danger'" size="small">
          {{ algorithm === 'DH' ? '性能优先' : algorithm === 'OT' ? '安全均衡' : '最高安全' }}
        </el-tag>
        <p class="algo-desc">{{ descriptions[algorithm] }}</p>
      </el-col>
    </el-row>
  </el-card>
</template>

<script>
export default {
  props: {
    value: { type: Object, default: () => ({ algorithm: 'DH', mode: 'batch' }) }
  },
  data() {
    return {
      algorithm: this.value.algorithm || 'DH',
      mode: this.value.mode || 'batch',
      descriptions: {
        DH: '基于Diffie-Hellman密钥交换协议，计算速度快。',
        OT: '基于不经意传输协议，保护查询方隐私。',
        HE: '基于全同态加密，数据全程加密计算。'
      }
    }
  },
  methods: {
    onChange() {
      this.$emit('input', { algorithm: this.algorithm, mode: this.mode })
    }
  }
}
</script>

<style scoped>
.algorithm-selector { margin-bottom: 20px; }
.section-title { font-weight: bold; margin-bottom: 10px; color: #606266; }
.algo-option { padding: 5px 0; }
.algo-desc { margin-top: 8px; font-size: 13px; color: #909399; }
.el-radio-button { margin-right: 10px; margin-bottom: 10px; }
</style>
