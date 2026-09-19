<template>
  <!-- 项目联邦分析任务：单一真源在 components/FederatedAnalysis/FaCenter（双胞胎归并，项目上下文经 ?projectId= 注入） -->
  <FaCenter :project-id="$route.query.projectId || null" />
</template>

<script>
import FaCenter from '@/components/FederatedAnalysis/FaCenter'

export default {
  name: 'ProjectFederatedAnalysis',
  components: { FaCenter }
}
</script>
