<template>
  <div class="federated-query-page">
    <FederatedQueryNav />
    <QueryBase pageTitle="DHBatch联邦查询" defaultAlgorithm="DH" defaultMode="batch" />
  </div>
</template>

<script>
import QueryBase from '../templates/QueryBase'
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default { components: { QueryBase, FederatedQueryNav } }
</script>
