<template>
  <div v-loading="loading" class="app-container">
    <div class="header">
      <h2>可信空间详情</h2>
      <el-button type="primary" plain size="small" @click="goBack">返回列表</el-button>
    </div>
    <div class="detail">
      <el-descriptions title="空间信息" :column="3" label-class-name="detail-title">
        <el-descriptions-item label="空间ID">{{ space.spaceId }}</el-descriptions-item>
        <el-descriptions-item label="空间名称">
          <el-tag size="mini" :type="spaceTagType(space.spaceName)">{{ space.spaceName }}</el-tag>
          <el-tag v-if="isDefault" size="mini" type="info" class="default-tag">缺省</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="编码">{{ space.spaceCode }}</el-descriptions-item>
        <el-descriptions-item label="所属机构">{{ space.organName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag v-if="space.status === 1" type="success" size="mini">启用</el-tag>
          <el-tag v-else type="danger" size="mini">停用</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="资源数">{{ space.resourceCount }}</el-descriptions-item>
        <el-descriptions-item label="描述" :span="3">{{ space.spaceDesc || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ space.createDate }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ space.updateDate }}</el-descriptions-item>
      </el-descriptions>
    </div>

    <div class="resources">
      <div class="toolbar">
        <h3>空间内资源</h3>
        <div>
          <el-input
            v-model="query.resourceName"
            size="small"
            placeholder="按资源名称搜索"
            clearable
            style="width: 220px; margin-right: 10px;"
            @clear="search"
            @keyup.enter.native="search"
          />
          <el-button size="small" icon="el-icon-search" @click="search">搜索</el-button>
          <el-button v-if="hasAssignPermission && space.status === 1" size="small" type="primary" icon="el-icon-plus" @click="pickerVisible = true">划入资源</el-button>
        </div>
      </div>
      <p v-if="isDefault" class="hint">缺省空间包含所有未归入其它空间的资源；要调整归属请在目标空间「划入资源」。</p>
      <el-table v-loading="listLoading" :data="resourceList" border empty-text="暂无资源">
        <el-table-column prop="resourceId" label="资源ID" width="90">
          <template slot-scope="{row}">
            <el-link type="primary" @click="toResourceDetail(row.resourceId)">{{ row.resourceId }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="resourceName" label="资源名称" min-width="160" />
        <el-table-column prop="tags" label="标签" min-width="120">
          <template slot-scope="{row}">
            <el-tag v-for="tag in row.tags" :key="tag.tagId" type="success" size="mini" class="tag">{{ tag.tagName }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="数据信息" min-width="150">
          <template slot-scope="{row}">
            特征量：{{ row.fileColumns }}<br>
            样本量：{{ row.fileRows }}
          </template>
        </el-table-column>
        <el-table-column prop="resourceKind" label="形态" align="center" width="90">
          <template slot-scope="{row}">
            <el-tag v-if="row.resourceKind === 1" type="warning" size="mini">图像/blob</el-tag>
            <el-tag v-else-if="row.resourceKind === 2" type="info" size="mini">模型产物</el-tag>
            <el-tag v-else size="mini">表格</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="resourceSource" label="资源类型" align="center" width="100">
          <template slot-scope="{row}">{{ row.resourceSource | sourceFilter }}</template>
        </el-table-column>
        <el-table-column prop="resourceAuthType" label="可见性" align="center" width="90">
          <template slot-scope="{row}">{{ row.resourceAuthType | authTypeFilter }}</template>
        </el-table-column>
        <el-table-column prop="resourceState" label="状态" align="center" width="80">
          <template slot-scope="{row}">
            <el-tag v-if="row.resourceState === 0" type="success" size="mini">在线</el-tag>
            <el-tag v-else type="info" size="mini">下线</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="上传者" min-width="150">
          <template slot-scope="{row}">{{ row.userName }}<br>{{ row.createDate }}</template>
        </el-table-column>
        <el-table-column v-if="hasRemovePermission && !isDefault" label="操作" fixed="right" width="100" align="center">
          <template slot-scope="{row}">
            <el-button type="text" class="danger-text" @click="handleRemove(row)">移出空间</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>1" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNo" :total="total" @pagination="handlePagination" />
    </div>

    <ResourcePickerDialog
      :visible.sync="pickerVisible"
      :space-id="spaceId"
      :title="`划入资源到「${space.spaceName || ''}」`"
      @submit="handleAssign"
    />
  </div>
</template>

<script>
import { getTrustedSpaceDetail, getTrustedSpaceResources, assignTrustedSpaceResources, removeTrustedSpaceResources } from '@/api/trustedSpace'
import { spaceTagType } from '@/const/trustedSpace'
import Pagination from '@/components/Pagination'
import ResourcePickerDialog from './components/ResourcePickerDialog'
import { mapGetters } from 'vuex'

export default {
  name: 'TrustedSpaceDetail',
  components: { Pagination, ResourcePickerDialog },
  data() {
    return {
      spaceId: Number(this.$route.params.id),
      space: {},
      loading: false,
      listLoading: false,
      resourceList: [],
      query: { resourceName: '' },
      total: 0,
      pageCount: 0,
      pageNo: 1,
      pageSize: 10,
      pickerVisible: false
    }
  },
  computed: {
    isDefault() {
      return this.space.isDefault === 1
    },
    hasAssignPermission() {
      return this.buttonPermissionList.includes('TrustedSpaceAssign')
    },
    hasRemovePermission() {
      return this.buttonPermissionList.includes('TrustedSpaceRemove')
    },
    ...mapGetters(['buttonPermissionList'])
  },
  async created() {
    await this.fetchSpace()
    await this.fetchResources()
  },
  methods: {
    spaceTagType,
    async fetchSpace() {
      this.loading = true
      try {
        const res = await getTrustedSpaceDetail({ spaceId: this.spaceId })
        if (res.code === 0) this.space = res.result || {}
      } finally {
        this.loading = false
      }
    },
    async fetchResources() {
      this.listLoading = true
      try {
        const res = await getTrustedSpaceResources({
          spaceId: this.spaceId,
          pageNo: this.pageNo,
          pageSize: this.pageSize,
          resourceName: this.query.resourceName
        })
        if (res.code === 0) {
          const { data, total, totalPage } = res.result
          this.resourceList = data || []
          this.total = total || 0
          this.pageCount = totalPage || 0
        }
      } finally {
        this.listLoading = false
      }
    },
    search() {
      this.pageNo = 1
      this.fetchResources()
    },
    handlePagination(data) {
      this.pageNo = data.page
      this.pageSize = data.limit
      this.fetchResources()
    },
    async refreshAll() {
      await this.fetchSpace()
      await this.fetchResources()
    },
    async handleAssign(resourceIds) {
      if (!resourceIds || !resourceIds.length) return
      const res = await assignTrustedSpaceResources({ spaceId: this.spaceId, resourceIds })
      if (res && res.code === 0) {
        const n = res.result && res.result.affected
        this.$message({ type: 'success', message: `已划入 ${n == null ? resourceIds.length : n} 个资源` })
        this.pickerVisible = false
        this.pageNo = 1
        this.refreshAll()
      }
    },
    handleRemove(row) {
      this.$confirm(`将资源「${row.resourceName}」移出本空间（回到缺省空间）?`, '提示', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(async() => {
        const res = await removeTrustedSpaceResources({ spaceId: this.spaceId, resourceIds: [row.resourceId] })
        if (res && res.code === 0) {
          this.$message({ type: 'success', message: '已移出' })
          this.refreshAll()
        }
      }).catch(() => {})
    },
    toResourceDetail(id) {
      this.$router.push({ name: 'ResourceDetail', params: { id }})
    },
    goBack() {
      this.$router.push({ name: 'TrustedSpaceList' })
    }
  }
}
</script>

<style lang="scss" scoped>
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  h2 { margin: 0; }
}
.detail {
  margin-top: 16px;
  padding: 16px;
  background: #fff;
  border-radius: 4px;
}
.resources {
  margin-top: 16px;
  padding: 16px;
  background: #fff;
  border-radius: 4px;
  .toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
    h3 { margin: 0; }
  }
  .hint {
    color: #909399;
    font-size: 12px;
    margin: 0 0 10px;
  }
}
.tag { margin-right: 4px; }
.default-tag { margin-left: 6px; }
.danger-text { color: #f56c6c; }
</style>
