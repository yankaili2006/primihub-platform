<template>
  <div class="federated-query-page">
    <AlgorithmSelector v-model="algorithmConfig" />

    <el-card class="query-form">
      <div slot="header"><span>{{ pageTitle }}</span></div>
      <el-form ref="queryForm" :model="form" :rules="rules" label-width="120px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="form.taskName" placeholder="请输入任务名称" maxlength="64" show-word-limit />
        </el-form-item>

        <PartySelector v-model="form.parties" />

        <AdvancedConfigPanel v-model="form.advancedConfig" />

        <el-form-item>
          <el-button type="primary" :loading="loading" @click="submitQuery">提交查询</el-button>
          <el-button @click="$router.back()">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import AlgorithmSelector from '@/components/AlgorithmSelector'
import PartySelector from '@/components/PartySelector'
import AdvancedConfigPanel from '@/components/AdvancedConfigPanel'
import { createFederatedQuery, runFederatedQuery } from '@/api/federatedQuery'

export default {
  components: { AlgorithmSelector, PartySelector, AdvancedConfigPanel },
  props: {
    pageTitle: { type: String, default: '联邦查询' },
    defaultAlgorithm: { type: String, default: 'DH' },
    defaultMode: { type: String, default: 'batch' },
    queryType: { type: String, default: 'psi' },
    variant: { type: String, default: '' }
  },
  data() {
    return {
      algorithmConfig: { algorithm: this.defaultAlgorithm, mode: this.defaultMode },
      form: { taskName: '', parties: [], advancedConfig: {}},
      loading: false,
      rules: {
        taskName: [
          { required: true, message: '请输入任务名称', trigger: 'blur' },
          { max: 64, message: '任务名称不能超过64个字符', trigger: 'blur' }
        ]
      }
    }
  },
  methods: {
    async submitQuery() {
      this.$refs.queryForm.validate(async valid => {
        if (!valid) return
        this.loading = true
        try {
          const res = await createFederatedQuery({
            ...this.form,
            algorithm: this.algorithmConfig.algorithm,
            mode: this.algorithmConfig.mode,
            queryType: this.queryType,
            ...(this.variant ? { variant: this.variant } : {})
          })
          const taskId = res?.result?.taskId
          if (taskId) {
            // 创建即自动触发执行（后端异步跑，状态在查询记录页轮询）；失败不阻塞跳转
            runFederatedQuery({ taskId }).catch(() => {})
          }
          this.$message.success('提交成功，任务已开始执行')
          // 路由表没有 /federatedQuery/list，死路由会被守卫弹回登录页——跳查询记录页
          this.$router.push('/federatedQuery/logs/queryRecord')
        } catch (e) {
          this.$message.error(e.response?.data?.message || '提交失败，请检查网络或参数')
        } finally {
          this.loading = false
        }
      })
    }
  }
}
</script>
