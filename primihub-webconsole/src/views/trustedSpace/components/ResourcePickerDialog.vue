<template>
  <el-dialog
    :visible="visible"
    :title="title"
    width="900px"
    :before-close="close"
    append-to-body
  >
    <div class="search">
      <el-input
        v-model="resourceName"
        size="small"
        placeholder="按资源名称搜索本机构资源"
        clearable
        style="width: 260px; margin-right: 10px;"
        @clear="search"
        @keyup.enter.native="search"
      />
      <el-button size="small" icon="el-icon-search" @click="search">搜索</el-button>
      <span class="selected-hint">已选 {{ selected.length }} 个</span>
    </div>
    <el-table
      ref="table"
      v-loading="loading"
      :data="list"
      row-key="resourceId"
      border
      max-height="420"
      empty-text="暂无资源"
      @selection-change="handleSelectionChange"
    >
      <el-table-column type="selection" width="50" reserve-selection :selectable="selectable" />
      <el-table-column prop="resourceId" label="资源ID" width="90" />
      <el-table-column prop="resourceName" label="资源名称" min-width="180" />
      <el-table-column prop="tags" label="标签" min-width="120">
        <template slot-scope="{row}">
          <el-tag v-for="tag in row.tags" :key="tag.tagId" type="success" size="mini" class="tag">{{ tag.tagName }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="fileRows" label="样本量" width="90" />
      <el-table-column prop="trustedSpaceName" label="当前空间" width="120" align="center">
        <template slot-scope="{row}">
          <el-tag size="mini" :type="spaceTagType(row.trustedSpaceName)">{{ row.trustedSpaceName || DEFAULT_SPACE_NAME }}</el-tag>
        </template>
      </el-table-column>
    </el-table>
    <span slot="footer" class="dialog-footer">
      <pagination
        v-show="pageCount>1"
        small
        :limit.sync="pageSize"
        :page.sync="pageNo"
        :page-count="pageCount"
        :total="total"
        layout="total, prev, pager, next"
        @pagination="handlePagination"
      />
      <div class="buttons">
        <el-button size="medium" @click="close">取 消</el-button>
        <el-button size="medium" type="primary" :disabled="!selected.length" @click="submit">确 定</el-button>
      </div>
    </span>
  </el-dialog>
</template>

<script>
import { getResourceList } from '@/api/resource'
import { spaceTagType, DEFAULT_SPACE_NAME } from '@/const/trustedSpace'
import Pagination from '@/components/Pagination'

/**
 * 本机构资源多选弹窗（划入可信空间用）。列出 /data/resource/getdataresourcelist 的全部本地资源，
 * 已属于目标空间的行不可选；跨页勾选靠 reserve-selection 保留。
 */
export default {
  name: 'TrustedSpaceResourcePickerDialog',
  components: { Pagination },
  props: {
    visible: { type: Boolean, default: false },
    spaceId: { type: Number, default: 0 },
    title: { type: String, default: '选择资源' }
  },
  data() {
    return {
      DEFAULT_SPACE_NAME,
      list: [],
      loading: false,
      resourceName: '',
      selected: [],
      total: 0,
      pageCount: 0,
      pageNo: 1,
      pageSize: 10
    }
  },
  watch: {
    visible(val) {
      if (val) {
        this.pageNo = 1
        this.resourceName = ''
        this.selected = []
        this.$nextTick(() => this.$refs.table && this.$refs.table.clearSelection())
        this.fetchData()
      }
    }
  },
  methods: {
    spaceTagType,
    selectable(row) {
      return row.trustedSpace !== this.spaceId
    },
    async fetchData() {
      this.loading = true
      try {
        const res = await getResourceList({
          pageNo: this.pageNo,
          pageSize: this.pageSize,
          resourceName: this.resourceName,
          derivation: 0
        })
        if (res.code === 0) {
          const { data, total, totalPage } = res.result
          this.list = data || []
          this.total = total || 0
          this.pageCount = totalPage || 0
        }
      } finally {
        this.loading = false
      }
    },
    search() {
      this.pageNo = 1
      this.fetchData()
    },
    handlePagination(data) {
      this.pageNo = data.page
      this.fetchData()
    },
    handleSelectionChange(rows) {
      this.selected = rows
    },
    close() {
      this.$emit('update:visible', false)
    },
    submit() {
      this.$emit('submit', this.selected.map(r => r.resourceId))
    }
  }
}
</script>

<style lang="scss" scoped>
.search {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
  .selected-hint {
    margin-left: auto;
    color: #909399;
    font-size: 12px;
  }
}
.tag { margin-right: 4px; }
.dialog-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
