<template>
  <!-- 联邦分析主页：单一真源在 components/FederatedAnalysis/FaCenter（双胞胎归并，无项目上下文=全量视图） -->
  <FaCenter />
</template>

<script>
import FaCenter from '@/components/FederatedAnalysis/FaCenter'

export default {
  name: 'FederatedAnalysisIndex',
  components: { FaCenter }
}
</script>
