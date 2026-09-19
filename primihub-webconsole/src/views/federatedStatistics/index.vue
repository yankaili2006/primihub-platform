<template>
  <!-- 联邦统计主页：单一真源在 components/FederatedStatistics/FsCenter（双胞胎归并，无项目上下文=全量视图） -->
  <FsCenter />
</template>

<script>
import FsCenter from '@/components/FederatedStatistics/FsCenter'

export default {
  name: 'FederatedStatisticsIndex',
  components: { FsCenter }
}
</script>
