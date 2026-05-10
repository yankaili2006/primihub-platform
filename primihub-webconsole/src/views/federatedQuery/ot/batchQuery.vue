<template>
  <div class="federated-query-page">
    <FederatedQueryNav />
    <QueryBase pageTitle="OTBatch联邦查询" defaultAlgorithm="OT" defaultMode="batch" />
  </div>
</template>

<script>
import QueryBase from '../templates/QueryBase'
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default { components: { QueryBase, FederatedQueryNav } }
</script>
