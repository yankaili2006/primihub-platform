<template>
  <el-card class="advanced-config">
    <div slot="header">
      <span>高级配置</span>
      <el-switch v-model="expanded" active-text="展开" inactive-text="收起" style="float:right" />
    </div>
    <div v-show="expanded">
      <el-form :model="config" label-width="140px" size="small">
        <el-form-item label="Payload分块">
          <el-switch v-model="config.payloadChunk" />
          <el-input-number v-if="config.payloadChunk" v-model="config.chunkSize" :min="64" :max="10240" style="margin-left:10px">
            <template slot="append">KB</template>
          </el-input-number>
        </el-form-item>
        <el-form-item label="指定输出字段">
          <el-input v-model="config.outputFields" placeholder="多个字段用逗号分隔，留空为全部" />
        </el-form-item>
        <el-form-item label="去重">
          <el-switch v-model="config.dedup" />
          <el-select v-if="config.dedup" v-model="config.dedupMethod" style="margin-left:10px;width:120px">
            <el-option label="精确去重" value="exact" />
            <el-option label="模糊去重" value="fuzzy" />
          </el-select>
        </el-form-item>
        <el-form-item label="分桶">
          <el-switch v-model="config.bucket" />
          <el-input-number v-if="config.bucket" v-model="config.bucketCount" :min="2" :max="100" style="margin-left:10px">
            <template slot="append">桶</template>
          </el-input-number>
        </el-form-item>
        <el-form-item label="编码">
          <el-select v-model="config.codec" style="width:200px">
            <el-option label="不编码" value="none" />
            <el-option label="Base64" value="base64" />
            <el-option label="GZip" value="gzip" />
            <el-option label="Snappy" value="snappy" />
          </el-select>
        </el-form-item>
      </el-form>
    </div>
  </el-card>
</template>

<script>
export default {
  props: {
    value: { type: Object, default: () => ({}) }
  },
  data() {
    return {
      expanded: false,
      config: {
        payloadChunk: false, chunkSize: 1024,
        outputFields: '', dedup: false, dedupMethod: 'exact',
        bucket: false, bucketCount: 10, codec: 'none',
        ...this.value
      }
    }
  },
  watch: {
    config: { handler() { this.$emit('input', { ...this.config }) }, deep: true }
  }
}
</script>
