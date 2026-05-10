<template>
  <div class="federated-query-page">
    <FederatedQueryNav />
    <QueryBase pageTitle="OTRealtime联邦查询" defaultAlgorithm="OT" defaultMode="realtime" />
  </div>
</template>

<script>
import QueryBase from '../templates/QueryBase'
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default { components: { QueryBase, FederatedQueryNav } }
</script>
