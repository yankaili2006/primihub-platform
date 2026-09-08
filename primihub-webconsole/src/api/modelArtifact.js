import request from '@/utils/request'

// 保存/编辑模型产物(带artifactId为编辑)
export function saveModelArtifact(data) {
  return request({
    url: '/data/artifact/saveModelArtifact',
    method: 'post',
    type: 'json',
    data
  })
}

// 模型产物列表
export function getModelArtifactList(params) {
  return request({
    url: '/data/artifact/getModelArtifactList',
    method: 'get',
    params
  })
}

// 模型产物详情
export function getModelArtifact(artifactId) {
  return request({
    url: '/data/artifact/getModelArtifact',
    method: 'get',
    params: {
      artifactId
    }
  })
}

// 删除模型产物(软删除)
export function delModelArtifact(artifactId) {
  return request({
    url: '/data/artifact/delModelArtifact',
    method: 'get',
    params: {
      artifactId
    }
  })
}
