<template>
  <div v-loading="loading" class="app-container">
    <h2><span v-if="isEditPage">编辑</span><span v-else>新建</span>模型产物</h2>
    <el-form
      ref="dataForm"
      :model="dataForm"
      :rules="dataRules"
      label-width="120px"
    >
      <el-form-item label="模型名称" prop="modelName">
        <div class="item-wrap-normal">
          <el-input
            v-model="dataForm.modelName"
            maxlength="50"
            show-word-limit
          />
        </div>
      </el-form-item>
      <el-form-item label="产物类型" prop="modelKind">
        <div class="item-wrap-normal">
          <el-select
            v-model="dataForm.modelKind"
            class="full-width"
            filterable
            allow-create
            default-first-option
            placeholder="请选择或输入产物类型"
          >
            <el-option
              v-for="item in modelKindOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </div>
      </el-form-item>
      <el-form-item label="框架" prop="framework">
        <div class="item-wrap-normal">
          <el-input v-model="dataForm.framework" placeholder="如 pytorch / sklearn" />
        </div>
      </el-form-item>
      <el-form-item label="格式" prop="format">
        <div class="item-wrap-normal">
          <el-input v-model="dataForm.format" placeholder="如 pt / onnx / json" />
        </div>
      </el-form-item>
      <el-form-item label="版本" prop="version">
        <div class="item-wrap-normal">
          <el-input v-model="dataForm.version" placeholder="如 1.0.0" />
        </div>
      </el-form-item>
      <el-form-item label="校验值" prop="checksum">
        <div class="item-wrap-normal">
          <el-input v-model="dataForm.checksum" placeholder="文件校验值(如 sha256)" />
        </div>
      </el-form-item>
      <el-form-item label="元数据" prop="metadata">
        <div class="item-wrap-normal">
          <el-input
            v-model="dataForm.metadata"
            type="textarea"
            :rows="4"
            placeholder="JSON格式,如 {&quot;classes&quot;: 10}"
          />
        </div>
      </el-form-item>
      <el-form-item label="产物文件">
        <upload :max-size="fileMaxSize" :file-suffix="fileSuffixs" :show-tips="true" :single="true" @success="handleUploadSuccess" />
        <p v-if="isEditPage && dataForm.fileId" class="tips">已关联文件ID：{{ dataForm.fileId }}，重新上传将替换</p>
      </el-form-item>
      <el-form-item>
        <el-button
          type="primary"
          @click="submitForm"
        >
          保存
        </el-button>
        <el-button @click="goBack">取消</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script>
import { saveModelArtifact, getModelArtifact } from '@/api/modelArtifact'
import Upload from '@/components/Upload'
import { MODEL_KIND_OPTIONS, MODEL_ARTIFACT_FILE_SUFFIXS } from '@/const/modelArtifact'

export default {
  components: {
    Upload
  },
  data() {
    const metadataValidate = (rule, value, callback) => {
      if (!value) {
        callback()
        return
      }
      try {
        JSON.parse(value)
        callback()
      } catch (e) {
        callback(new Error('元数据需为合法的JSON'))
      }
    }
    return {
      isEditPage: false,
      loading: false,
      artifactId: '',
      modelKindOptions: MODEL_KIND_OPTIONS,
      fileSuffixs: MODEL_ARTIFACT_FILE_SUFFIXS,
      fileMaxSize: 1024 * 1024 * 1024, // file limit 1024MB
      dataForm: {
        modelName: '',
        modelKind: '',
        framework: '',
        format: '',
        version: '',
        checksum: '',
        metadata: '',
        fileId: ''
      },
      dataRules: {
        modelName: [
          { required: true, message: '请输入模型名称', trigger: 'blur' }
        ],
        modelKind: [
          { required: true, message: '请选择或输入产物类型', trigger: 'change' }
        ],
        metadata: [
          { trigger: 'blur', validator: metadataValidate }
        ]
      }
    }
  },
  async created() {
    this.isEditPage = this.$route.name === 'ModelArtifactEdit'
    this.artifactId = this.$route.params.id
    if (this.isEditPage) {
      await this.getDetail()
    }
  },
  methods: {
    async getDetail() {
      this.loading = true
      const res = await getModelArtifact(this.artifactId)
      if (res.code === 0 && res.result) {
        const { modelName, modelKind, framework, format, version, checksum, metadata, fileId } = res.result
        this.dataForm.modelName = modelName
        this.dataForm.modelKind = modelKind
        this.dataForm.framework = framework
        this.dataForm.format = format
        this.dataForm.version = version
        this.dataForm.checksum = checksum
        this.dataForm.metadata = metadata
        this.dataForm.fileId = fileId
      }
      this.loading = false
    },
    handleUploadSuccess({ fileId }) {
      this.dataForm.fileId = fileId
    },
    submitForm() {
      this.$refs['dataForm'].validate(async(valid) => {
        if (valid) {
          const params = { ...this.dataForm }
          if (this.isEditPage) {
            params.artifactId = this.artifactId
          }
          this.loading = true
          saveModelArtifact(params).then(res => {
            this.loading = false
            if (res.code === 0) {
              this.$message.success('保存成功')
              this.goBack()
            } else {
              this.$message({
                message: res.msg,
                type: 'error'
              })
            }
          }).catch(err => {
            this.loading = false
            console.log(err)
          })
        } else {
          console.log('error submit!!')
          return false
        }
      })
    },
    goBack() {
      this.$router.replace({
        name: 'ModelArtifactList'
      })
    }
  }
}
</script>
<style lang="scss" scoped>
.item-wrap-normal {
  width: 660px;
}
.full-width{
  width: 100%;
}
.tips{
  font-size: 12px;
  color: #999;
  line-height: 1;
}
</style>
