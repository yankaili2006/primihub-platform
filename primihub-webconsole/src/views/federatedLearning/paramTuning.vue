<template>
  <!-- 薄壳：单一真源在 components/FederatedLearning/FlTuning（本页原 mock 实现已废除） -->
  <div class="app-container">
    <FlTuning :project-id="$route.query.projectId || null" />
  </div>
</template>

<script>
import FlTuning from '@/components/FederatedLearning/FlTuning'

export default {
  name: 'FederatedLearningParamTuning',
  components: { FlTuning }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
