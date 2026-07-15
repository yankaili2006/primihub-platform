import request from '@/utils/request'
export function getWorkflowList() { return request({ url: '/approvalWorkflow/getList', method: 'get' }) }
export function saveWorkflow(data) { return request({ url: '/approvalWorkflow/save', method: 'post', data }) }
export function deleteWorkflow(params) { return request({ url: '/approvalWorkflow/delete', method: 'get', params }) }