<template>
  <!-- 联邦学习中心：单一真源在 components/FederatedLearning/*（原 6-tab mock 双胞胎已废除） -->
  <fl-center />
</template>

<script>
import FlCenter from '@/components/FederatedLearning/FlCenter'

export default {
  name: 'FederatedLearningIndex',
  components: { FlCenter }
}
</script>
