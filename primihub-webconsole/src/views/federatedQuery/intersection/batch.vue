<template>
  <div class="intersection-page">
    <FederatedQueryNav />
    <el-card>
      <div slot="header"><span>批量联邦求交</span></div>
      <AlgorithmSelector v-model="algorithmConfig" />
      <el-form :model="form" label-width="120px">
        <el-form-item label="任务名称" required>
          <el-input v-model="form.taskName" placeholder="请输入任务名称" />
        </el-form-item>
        <PartySelector v-model="form.parties" />
        <AdvancedConfigPanel v-model="form.advancedConfig" />
        <el-form-item>
          <el-button type="primary" @click="submitQuery" :loading="loading">提交求交</el-button>
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
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default {
  components: { AlgorithmSelector, PartySelector, AdvancedConfigPanel, FederatedQueryNav },
  data() {
    return {
      algorithmConfig: { algorithm: 'DH', mode: 'batch' },
      form: { taskName: '', parties: [], advancedConfig: {} },
      loading: false
    }
  },
  methods: {
    async submitQuery() {
      if (!this.form.taskName) return this.$message.warning('请输入任务名称')
      this.loading = true
      try {
        await this.$message.success('提交成功')
        this.$router.push('/PSI/list')
      } catch (e) { this.$message.error('提交失败')
      } finally { this.loading = false }
    }
  }
}
</script>
