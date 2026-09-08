<template>
  <div class="federated-query-page">
    <FederatedQueryNav />
    <QueryBase page-title="求交去重" default-algorithm="DH" default-mode="batch" variant="dedup" />
  </div>
</template>

<script>
import QueryBase from '../templates/QueryBase'
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default { components: { QueryBase, FederatedQueryNav }}
</script>
