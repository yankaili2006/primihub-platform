<template>
  <!-- 薄壳：单一真源在 components/FederatedLearning/FlIteration（本页原 mock 实现已废除） -->
  <div class="app-container">
    <FlIteration :project-id="$route.query.projectId || null" />
  </div>
</template>

<script>
import FlIteration from '@/components/FederatedLearning/FlIteration'

export default {
  name: 'FederatedLearningTrainingIteration',
  components: { FlIteration }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
