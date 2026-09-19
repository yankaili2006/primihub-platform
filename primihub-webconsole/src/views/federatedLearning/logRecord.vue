<template>
  <!-- 薄壳：单一真源在 components/FederatedLearning/FlLogs（本页原 mock 实现已废除） -->
  <div class="app-container">
    <FlLogs :project-id="$route.query.projectId || null" />
  </div>
</template>

<script>
import FlLogs from '@/components/FederatedLearning/FlLogs'

export default {
  name: 'FederatedLearningLogRecord',
  components: { FlLogs }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
