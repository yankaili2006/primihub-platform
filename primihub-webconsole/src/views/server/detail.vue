<template>
  <div class="app-container" v-loading="loading">
    <el-card class="box-card">
      <div slot="header">
        <span>服务器详情</span>
        <el-button style="float: right;" size="mini" @click="$router.back()">返回</el-button>
      </div>
      <el-descriptions :column="3" border>
        <el-descriptions-item label="ID">{{ server.serverId }}</el-descriptions-item>
        <el-descriptions-item label="名称">{{ server.serverName }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusTag(server.serverStatus)">{{ statusText(server.serverStatus) }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="IP">{{ server.serverIp }}</el-descriptions-item>
        <el-descriptions-item label="端口">{{ server.serverPort }}</el-descriptions-item>
        <el-descriptions-item label="类型">{{ server.serverType }}</el-descriptions-item>
        <el-descriptions-item label="CPU">{{ server.cpuCores }}</el-descriptions-item>
        <el-descriptions-item label="内存(GB)">{{ server.memoryGb }}</el-descriptions-item>
        <el-descriptions-item label="存储(GB)">{{ server.storageGb }}</el-descriptions-item>
        <el-descriptions-item label="描述" :span="3">{{ server.serverDesc }}</el-descriptions-item>
        <el-descriptions-item label="定位URL" :span="3">{{ server.serverUrl }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <el-card class="box-card" style="margin-top: 16px;">
      <el-tabs v-model="activeTab">
        <!-- 数据资源 -->
        <el-tab-pane label="数据资源" name="resource">
          <el-button type="primary" size="mini" icon="el-icon-plus" @click="openBind('resource')">关联数据资源</el-button>
          <el-table :data="server.resources || []" border style="margin-top: 10px;">
            <el-table-column label="资源ID" prop="resourceId" width="90" align="center" />
            <el-table-column label="资源名称" prop="resourceName" min-width="160" />
            <el-table-column label="描述" prop="resourceDesc" min-width="160" show-overflow-tooltip />
            <el-table-column label="定位URI" prop="uri" min-width="220" show-overflow-tooltip />
            <el-table-column label="操作" width="100" align="center">
              <template slot-scope="{ row }">
                <el-button type="text" class="danger-text" @click="doUnbind('resource', row)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 模型 -->
        <el-tab-pane label="模型" name="model">
          <el-button type="primary" size="mini" icon="el-icon-plus" @click="openBind('model')">关联模型</el-button>
          <el-table :data="server.models || []" border style="margin-top: 10px;">
            <el-table-column label="模型ID" prop="modelId" width="90" align="center" />
            <el-table-column label="模型名称" prop="modelName" min-width="160" />
            <el-table-column label="版本" prop="modelVersion" width="120" />
            <el-table-column label="定位URI" prop="uri" min-width="220" show-overflow-tooltip />
            <el-table-column label="操作" width="100" align="center">
              <template slot-scope="{ row }">
                <el-button type="text" class="danger-text" @click="doUnbind('model', row)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 模型产物 -->
        <el-tab-pane label="模型产物" name="artifact">
          <el-button type="primary" size="mini" icon="el-icon-plus" @click="openBind('artifact')">关联模型产物</el-button>
          <el-table :data="server.artifacts || []" border style="margin-top: 10px;">
            <el-table-column label="产物ID" prop="artifactId" width="90" align="center" />
            <el-table-column label="产物名称" prop="artifactName" min-width="160" />
            <el-table-column label="定位URI" prop="uri" min-width="220" show-overflow-tooltip />
            <el-table-column label="操作" width="100" align="center">
              <template slot-scope="{ row }">
                <el-button type="text" class="danger-text" @click="doUnbind('artifact', row)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 节点 -->
        <el-tab-pane label="节点" name="node">
          <el-button type="primary" size="mini" icon="el-icon-plus" @click="openBind('node')">关联节点</el-button>
          <el-table :data="server.nodes || []" border style="margin-top: 10px;">
            <el-table-column label="节点ID" prop="nodeId" width="90" align="center" />
            <el-table-column label="节点名称" prop="nodeName" min-width="140" />
            <el-table-column label="接入类型" prop="accessType" width="130" />
            <el-table-column label="主节点" width="80" align="center">
              <template slot-scope="{ row }">{{ row.isPrimary === 1 ? '是' : '否' }}</template>
            </el-table-column>
            <el-table-column label="定位URI" prop="uri" min-width="220" show-overflow-tooltip />
            <el-table-column label="操作" width="100" align="center">
              <template slot-scope="{ row }">
                <el-button type="text" class="danger-text" @click="doUnbind('node', row)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 智能体 -->
        <el-tab-pane label="智能体" name="agent">
          <el-button type="primary" size="mini" icon="el-icon-plus" @click="openBind('agent')">关联智能体</el-button>
          <el-table :data="server.agents || []" border style="margin-top: 10px;">
            <el-table-column label="智能体ID" prop="agentId" width="90" align="center" />
            <el-table-column label="名称" prop="agentName" min-width="140" />
            <el-table-column label="类型" prop="agentType" width="130" />
            <el-table-column label="定位URI" prop="uri" min-width="220" show-overflow-tooltip />
            <el-table-column label="操作" width="100" align="center">
              <template slot-scope="{ row }">
                <el-button type="text" class="danger-text" @click="doUnbind('agent', row)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 关联弹窗 -->
    <el-dialog :title="bindTitle" :visible.sync="bindDialog" width="460px">
      <el-form label-width="100px">
        <el-form-item v-if="bindKind === 'agent'" label="智能体">
          <el-select v-model="bindForm.id" placeholder="选择智能体" style="width: 100%;" filterable>
            <el-option v-for="a in agentOptions" :key="a.agentId" :label="a.agentName + ' (#' + a.agentId + ')'" :value="a.agentId" />
          </el-select>
        </el-form-item>
        <el-form-item v-else :label="idLabel">
          <el-input-number v-model="bindForm.id" :min="1" controls-position="right" style="width: 100%;" />
        </el-form-item>
        <el-form-item v-if="bindKind === 'model'" label="模型版本">
          <el-input v-model="bindForm.modelVersion" placeholder="可选" />
        </el-form-item>
        <template v-if="bindKind === 'node'">
          <el-form-item label="接入类型">
            <el-select v-model="bindForm.accessType" placeholder="可选" clearable style="width: 100%;">
              <el-option label="project" value="project" />
              <el-option label="compute" value="compute" />
              <el-option label="data_exchange" value="data_exchange" />
            </el-select>
          </el-form-item>
          <el-form-item label="设为主节点">
            <el-switch v-model="bindForm.isPrimary" :active-value="1" :inactive-value="0" />
          </el-form-item>
        </template>
      </el-form>
      <div slot="footer">
        <el-button @click="bindDialog = false">取消</el-button>
        <el-button type="primary" :loading="binding" @click="doBind">确定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  getServerDetail, findAgentPage,
  bindResource, unbindResource, bindModel, unbindModel,
  bindArtifact, unbindArtifact, bindNode, unbindNode, bindAgent, unbindAgent
} from '@/api/server'

export default {
  name: 'ServerDetail',
  data() {
    return {
      loading: false,
      serverId: Number(this.$route.params.serverId),
      server: {},
      activeTab: 'resource',
      bindDialog: false,
      binding: false,
      bindKind: 'resource',
      bindForm: { id: undefined, modelVersion: '', accessType: '', isPrimary: 0 },
      agentOptions: []
    }
  },
  computed: {
    bindTitle() {
      return { resource: '关联数据资源', model: '关联模型', artifact: '关联模型产物', node: '关联节点', agent: '关联智能体' }[this.bindKind]
    },
    idLabel() {
      return { resource: '数据资源ID', model: '模型ID', artifact: '产物ID', node: '节点ID' }[this.bindKind] || 'ID'
    }
  },
  created() {
    this.loadDetail()
  },
  methods: {
    statusText(s) {
      return { 0: '离线', 1: '在线', 2: '维护中' }[s] || '未知'
    },
    statusTag(s) {
      return { 0: 'info', 1: 'success', 2: 'warning' }[s] || 'info'
    },
    loadDetail() {
      this.loading = true
      getServerDetail(this.serverId)
        .then(res => {
          this.server = res.data || {}
        })
        .finally(() => {
          this.loading = false
        })
    },
    openBind(kind) {
      this.bindKind = kind
      this.bindForm = { id: undefined, modelVersion: '', accessType: '', isPrimary: 0 }
      this.bindDialog = true
      if (kind === 'agent') {
        findAgentPage({ pageNo: 1, pageSize: 100 }).then(res => {
          const d = res.data || {}
          this.agentOptions = d.list || []
        })
      }
    },
    doBind() {
      if (!this.bindForm.id) {
        this.$message.warning('请填写/选择要关联的对象')
        return
      }
      this.binding = true
      const id = this.bindForm.id
      let p
      switch (this.bindKind) {
        case 'resource': p = bindResource(this.serverId, id); break
        case 'model': p = bindModel(this.serverId, id, this.bindForm.modelVersion); break
        case 'artifact': p = bindArtifact(this.serverId, id); break
        case 'node': p = bindNode(this.serverId, id, this.bindForm.accessType, this.bindForm.isPrimary); break
        case 'agent': p = bindAgent(this.serverId, id); break
      }
      p.then(() => {
        this.$message.success('关联成功')
        this.bindDialog = false
        this.loadDetail()
      }).finally(() => {
        this.binding = false
      })
    },
    doUnbind(kind, row) {
      const map = {
        resource: () => unbindResource(this.serverId, row.resourceId),
        model: () => unbindModel(this.serverId, row.modelId),
        artifact: () => unbindArtifact(this.serverId, row.artifactId),
        node: () => unbindNode(this.serverId, row.nodeId),
        agent: () => unbindAgent(this.serverId, row.agentId)
      }
      this.$confirm('确认移除该关联？', '提示', { type: 'warning' })
        .then(() => map[kind]())
        .then(() => {
          this.$message.success('已移除')
          this.loadDetail()
        })
        .catch(() => {})
    }
  }
}
</script>

<style scoped>
.danger-text {
  color: #f56c6c;
}
</style>
