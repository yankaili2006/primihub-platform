<template>
  <div class="federated-query-page">
    <FederatedQueryNav />
    <QueryBase page-title="批量联邦求交" default-algorithm="DH" default-mode="batch" />
  </div>
</template>

<script>
import QueryBase from '../templates/QueryBase'
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default { components: { QueryBase, FederatedQueryNav }}
</script>
