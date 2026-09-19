<template>
  <!-- 联邦查询记录：单一真源在 components/FederatedQuery/FqCenter（模块上下文=全量视图，含算法导航） -->
  <FqCenter />
</template>

<script>
import FqCenter from '@/components/FederatedQuery/FqCenter'

export default {
  name: 'FederatedQueryRecord',
  components: { FqCenter }
}
</script>
