<template>
  <!-- 项目联邦统计任务：单一真源在 components/FederatedStatistics/FsCenter（双胞胎归并，项目上下文经 ?projectId= 注入） -->
  <FsCenter :project-id="$route.query.projectId || null" />
</template>

<script>
import FsCenter from '@/components/FederatedStatistics/FsCenter'

export default {
  name: 'ProjectFederatedStatistics',
  components: { FsCenter }
}
</script>
