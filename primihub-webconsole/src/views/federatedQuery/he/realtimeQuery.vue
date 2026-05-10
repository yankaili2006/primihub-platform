<template>
  <div class="federated-query-page">
    <FederatedQueryNav />
    <QueryBase pageTitle="HERealtime联邦查询" defaultAlgorithm="HE" defaultMode="realtime" />
  </div>
</template>

<script>
import QueryBase from '../templates/QueryBase'
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default { components: { QueryBase, FederatedQueryNav } }
</script>
