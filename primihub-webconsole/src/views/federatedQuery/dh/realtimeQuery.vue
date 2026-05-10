<template>
  <div class="federated-query-page">
    <FederatedQueryNav />
    <QueryBase pageTitle="DHRealtime联邦查询" defaultAlgorithm="DH" defaultMode="realtime" />
  </div>
</template>

<script>
import QueryBase from '../templates/QueryBase'
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default { components: { QueryBase, FederatedQueryNav } }
</script>
