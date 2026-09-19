<template>
  <!-- 项目联邦学习任务 = 联邦学习中心的项目上下文视图（?projectId= 过滤），
       功能单一真源在 components/FederatedLearning/*，本页只注入上下文。 -->
  <fl-center :project-id="$route.query.projectId || null" />
</template>

<script>
import FlCenter from '@/components/FederatedLearning/FlCenter'

export default {
  name: 'ProjectFederatedLearning',
  components: { FlCenter }
}
</script>
