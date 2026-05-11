<template>
  <div class="app-container">
    <el-page-header content="创建单方算法任务" style="margin-bottom: 20px;" @back="goBack" />
    <el-row :gutter="20">
      <el-col :span="16">
        <el-card>
          <div slot="header"><span>任务配置</span></div>
          <el-form ref="form" :model="form" :rules="rules" label-width="120px">
            <el-form-item label="任务名称" prop="taskName">
              <el-input v-model="form.taskName" placeholder="请输入任务名称" maxlength="50" />
            </el-form-item>
            <el-form-item label="算法类型" prop="algorithmType">
              <el-select v-model="form.algorithmType" placeholder="请选择算法类型" style="width: 100%;">
                <el-option v-for="item in algorithmOptions" :key="item.value" :label="item.label" :value="item.value" />
              </el-select>
            </el-form-item>
            <el-form-item label="数据资源" prop="resourceId">
              <el-select v-model="form.resourceId" placeholder="请选择数据资源" style="width: 100%;" filterable>
                <el-option v-for="item in resourceList" :key="item.resourceId" :label="item.resourceName" :value="item.resourceId" />
              </el-select>
            </el-form-item>
            <el-form-item label="特征选择" prop="selectedFeatures">
              <el-select v-model="form.selectedFeatures" multiple placeholder="请选择特征（可选）" style="width: 100%;" :disabled="!form.resourceId">
                <el-option v-for="item in featureList" :key="item" :label="item" :value="item" />
              </el-select>
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="form.remarks" type="textarea" :rows="3" placeholder="选填" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="submitting" @click="handleSubmit">创建并运行</el-button>
              <el-button @click="goBack">取消</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import { createTask } from '@/api/singleParty'
import { getResourceList } from '@/api/fusionResource'

const ALGORITHM_OPTIONS = [
  { value: 1, label: '逻辑回归' },
  { value: 2, label: '决策树' },
  { value: 3, label: '随机森林' },
  { value: 4, label: 'XGBoost' },
  { value: 5, label: '线性回归' },
  { value: 6, label: 'K-Means' }
]

export default {
  name: 'SinglePartyTask',
  data() {
    return {
      form: {
        taskName: '',
        algorithmType: null,
        resourceId: null,
        selectedFeatures: [],
        remarks: ''
      },
      rules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        algorithmType: [{ required: true, message: '请选择算法类型', trigger: 'change' }],
        resourceId: [{ required: true, message: '请选择数据资源', trigger: 'change' }]
      },
      algorithmOptions: ALGORITHM_OPTIONS,
      resourceList: [],
      featureList: [],
      submitting: false
    }
  },
  created() {
    this.fetchResources()
  },
  methods: {
    async fetchResources() {
      try {
        const { code, result } = await getResourceList({ index: 1, pageSize: 100 })
        if (code === 0) {
          this.resourceList = result?.data || []
        }
      } catch (e) {
        console.error('获取资源列表失败', e)
      }
    },
    async handleSubmit() {
      try {
        await this.$refs.form.validate()
      } catch {
        return
      }
      this.submitting = true
      try {
        const { code, msg } = await createTask({
          taskName: this.form.taskName,
          algorithmType: this.form.algorithmType,
          resourceId: this.form.resourceId,
          selectedFeatures: this.form.selectedFeatures?.join(','),
          remarks: this.form.remarks
        })
        if (code === 0) {
          this.$message.success('任务创建成功')
          this.$router.push('/singleParty/list')
        } else {
          this.$message.error(msg || '创建失败')
        }
      } catch (e) {
        this.$message.error('创建失败')
      } finally {
        this.submitting = false
      }
    },
    goBack() {
      this.$router.push('/singleParty/list')
    }
  }
}
</script>
