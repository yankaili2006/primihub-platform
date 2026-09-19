<template>
  <!-- 薄壳：单一真源在 components/FederatedLearning/FlReport（本页原 mock 实现已废除） -->
  <div class="app-container">
    <FlReport :project-id="$route.query.projectId || null" />
  </div>
</template>

<script>
import FlReport from '@/components/FederatedLearning/FlReport'

export default {
  name: 'FederatedLearningTrainingReport',
  components: { FlReport }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
