import request from '@/utils/request'

// ===== Server =====
export function findServerPage(params) {
  return request({
    url: '/sys/server/findServerPage',
    method: 'get',
    params
  })
}
export function getServerDetail(serverId) {
  return request({
    url: '/sys/server/getServerDetail',
    method: 'get',
    params: { serverId }
  })
}
export function addServer(data) {
  return request({
    url: '/sys/server/addServer',
    method: 'post',
    type: 'json',
    data
  })
}
export function updateServer(data) {
  return request({
    url: '/sys/server/updateServer',
    method: 'post',
    type: 'json',
    data
  })
}
export function deleteServer(serverId) {
  return request({
    url: '/sys/server/deleteServer',
    method: 'post',
    params: { serverId }
  })
}

// ===== Agent =====
export function findAgentPage(params) {
  return request({
    url: '/sys/server/findAgentPage',
    method: 'get',
    params
  })
}
export function addAgent(data) {
  return request({
    url: '/sys/server/addAgent',
    method: 'post',
    type: 'json',
    data
  })
}
export function updateAgent(data) {
  return request({
    url: '/sys/server/updateAgent',
    method: 'post',
    type: 'json',
    data
  })
}
export function deleteAgent(agentId) {
  return request({
    url: '/sys/server/deleteAgent',
    method: 'post',
    params: { agentId }
  })
}

// ===== Associations: Resource =====
export function bindResource(serverId, resourceId) {
  return request({ url: '/sys/server/bindResource', method: 'post', params: { serverId, resourceId } })
}
export function unbindResource(serverId, resourceId) {
  return request({ url: '/sys/server/unbindResource', method: 'post', params: { serverId, resourceId } })
}

// ===== Associations: Model =====
export function bindModel(serverId, modelId, modelVersion) {
  return request({ url: '/sys/server/bindModel', method: 'post', params: { serverId, modelId, modelVersion } })
}
export function unbindModel(serverId, modelId) {
  return request({ url: '/sys/server/unbindModel', method: 'post', params: { serverId, modelId } })
}

// ===== Associations: Artifact =====
export function bindArtifact(serverId, artifactId) {
  return request({ url: '/sys/server/bindArtifact', method: 'post', params: { serverId, artifactId } })
}
export function unbindArtifact(serverId, artifactId) {
  return request({ url: '/sys/server/unbindArtifact', method: 'post', params: { serverId, artifactId } })
}

// ===== Associations: Node =====
export function bindNode(serverId, nodeId, accessType, isPrimary) {
  return request({ url: '/sys/server/bindNode', method: 'post', params: { serverId, nodeId, accessType, isPrimary } })
}
export function unbindNode(serverId, nodeId) {
  return request({ url: '/sys/server/unbindNode', method: 'post', params: { serverId, nodeId } })
}

// ===== Associations: Agent =====
export function bindAgent(serverId, agentId) {
  return request({ url: '/sys/server/bindAgent', method: 'post', params: { serverId, agentId } })
}
export function unbindAgent(serverId, agentId) {
  return request({ url: '/sys/server/unbindAgent', method: 'post', params: { serverId, agentId } })
}
