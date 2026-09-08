<template>
  <div v-loading="loading" class="app-container">
    <h2>模型产物详情</h2>
    <div class="detail">
      <el-descriptions title="基本信息" :column="2" label-class-name="detail-title">
        <el-descriptions-item label="产物ID">{{ artifact.artifactId }}</el-descriptions-item>
        <el-descriptions-item label="模型名称">{{ artifact.modelName }}</el-descriptions-item>
        <el-descriptions-item label="产物类型">{{ artifact.modelKind }}</el-descriptions-item>
        <el-descriptions-item label="框架">{{ artifact.framework }}</el-descriptions-item>
        <el-descriptions-item label="格式">{{ artifact.format }}</el-descriptions-item>
        <el-descriptions-item label="版本">{{ artifact.version }}</el-descriptions-item>
        <el-descriptions-item label="上传者">{{ artifact.userName }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ artifact.createDate }}</el-descriptions-item>
        <el-descriptions-item label="机构ID">{{ artifact.organId }}</el-descriptions-item>
        <el-descriptions-item label="用户ID">{{ artifact.userId }}</el-descriptions-item>
      </el-descriptions>
    </div>
    <div class="detail">
      <el-descriptions title="文件信息" :column="1" label-class-name="detail-title">
        <el-descriptions-item label="文件ID">{{ artifact.fileId }}</el-descriptions-item>
        <el-descriptions-item label="文件地址">{{ artifact.url }}</el-descriptions-item>
        <el-descriptions-item label="对象存储Key">{{ artifact.objectKey }}</el-descriptions-item>
        <el-descriptions-item label="校验值">{{ artifact.checksum }}</el-descriptions-item>
      </el-descriptions>
    </div>
    <div class="detail">
      <h3>元数据</h3>
      <pre class="metadata">{{ metadataText }}</pre>
    </div>
  </div>
</template>

<script>
import { getModelArtifact } from '@/api/modelArtifact'

export default {
  data() {
    return {
      loading: false,
      artifactId: this.$route.params.id,
      artifact: {}
    }
  },
  computed: {
    metadataText() {
      const metadata = this.artifact.metadata
      if (!metadata) {
        return '无'
      }
      try {
        return JSON.stringify(JSON.parse(metadata), null, 2)
      } catch (e) {
        return metadata
      }
    }
  },
  async created() {
    await this.fetchData()
  },
  methods: {
    async fetchData() {
      this.loading = true
      const res = await getModelArtifact(this.artifactId)
      if (res.code === 0 && res.result) {
        this.artifact = res.result
      }
      this.loading = false
    }
  }
}
</script>

<style lang="scss" scoped>
@import "~@/styles/variables.module.scss";
::v-deep .el-descriptions__title, h3{
  font-size: 18px;
  border-left: 3px solid $mainColor;
  padding-left: 10px;
}
::v-deep .el-descriptions__body{
  color: rgba(0,0,0,.85);
}
.detail {
  padding: 20px 0 20px 20px;
  border-top: 1px solid #f0f0f0;
}
.metadata{
  margin: 10px 0 0;
  padding: 10px;
  background: #fafafa;
  border: 1px solid #EBEEF5;
  border-radius: 4px;
  font-size: 12px;
  color: #606266;
  white-space: pre-wrap;
  word-break: break-all;
}
</style>
