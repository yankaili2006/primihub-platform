<template>
  <div class="federated-query-page">
    <FederatedQueryNav />
    <QueryBase page-title="实时联邦求交" default-algorithm="DH" default-mode="realtime" />
  </div>
</template>

<script>
import QueryBase from '../templates/QueryBase'
import FederatedQueryNav from '@/components/FederatedQueryNav'
export default { components: { QueryBase, FederatedQueryNav }}
</script>
