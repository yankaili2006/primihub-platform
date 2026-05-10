<template>
  <el-menu :default-active="active" mode="horizontal" @select="onSelect" class="query-nav">
    <el-submenu index="algo">
      <template slot="title">按算法查询</template>
      <el-menu-item index="/federatedQuery/dh/batch">DH批量</el-menu-item>
      <el-menu-item index="/federatedQuery/dh/realtime">DH实时</el-menu-item>
      <el-menu-item index="/federatedQuery/ot/batch">OT批量</el-menu-item>
      <el-menu-item index="/federatedQuery/ot/realtime">OT实时</el-menu-item>
      <el-menu-item index="/federatedQuery/he/batch">HE批量</el-menu-item>
      <el-menu-item index="/federatedQuery/he/realtime">HE实时</el-menu-item>
    </el-submenu>
    <el-submenu index="intersection">
      <template slot="title">联邦求交</template>
      <el-menu-item index="/federatedQuery/intersection/batch">批量求交</el-menu-item>
      <el-menu-item index="/federatedQuery/intersection/realtime">实时求交</el-menu-item>
      <el-menu-item index="/federatedQuery/intersection/dedup">去重</el-menu-item>
      <el-menu-item index="/federatedQuery/intersection/multiColumn">多列联合ID</el-menu-item>
    </el-submenu>
    <el-menu-item index="/Difference/list">联邦求差</el-menu-item>
    <el-menu-item index="/Union/list">联邦求并</el-menu-item>
    <el-submenu index="tools">
      <template slot="title">工具</template>
      <el-menu-item index="/federatedQuery/tools/payloadChunk">Payload分块</el-menu-item>
      <el-menu-item index="/federatedQuery/tools/outputFields">输出字段</el-menu-item>
      <el-menu-item index="/federatedQuery/tools/dedup">查询去重</el-menu-item>
      <el-menu-item index="/federatedQuery/tools/bucket">分桶</el-menu-item>
      <el-menu-item index="/federatedQuery/tools/codec">编解码</el-menu-item>
    </el-submenu>
  </el-menu>
</template>

<script>
export default {
  computed: {
    active() { return this.$route.path }
  },
  methods: {
    onSelect(path) { this.$router.push(path) }
  }
}
</script>

<style scoped>
.query-nav { margin-bottom: 20px; }
</style>
