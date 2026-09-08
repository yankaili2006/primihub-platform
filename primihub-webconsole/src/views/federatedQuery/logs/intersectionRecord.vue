<script>
// 联邦求交任务与联邦查询共用 federated_query_task——记录页直接复用已接真数据的
// queryRecord（任务列表/状态标签/搜索/运行中轮询/结果下载），避免再养一个空壳
import QueryRecord from './queryRecord.vue'

export default {
  name: 'FederatedQueryLogIntersectionRecord',
  extends: QueryRecord
}
</script>
