<template>
  <div class="party-selector">
    <div class="party-list">
      <div v-for="(party, index) in parties" :key="index" class="party-item">
        <el-row :gutter="10">
          <el-col :span="6">
            <el-select v-model="party.organId" placeholder="选择机构" filterable :loading="loading" @change="onOrganChange(party)">
              <el-option v-for="org in organs" :key="org.id" :label="org.name" :value="org.id" />
            </el-select>
          </el-col>
          <el-col :span="6">
            <el-select v-model="party.resourceId" placeholder="选择数据源" filterable :loading="loading" @change="onResourceChange(party)">
              <el-option v-for="res in resourcesFor(party.organId)" :key="res.resourceId" :label="res.resourceName" :value="res.resourceId" />
            </el-select>
          </el-col>
          <el-col :span="10">
            <el-select v-model="party.fields" multiple placeholder="选择字段" filterable collapse-tags @change="onChange">
              <el-option v-for="f in fieldsFor(party.resourceId)" :key="f" :label="f" :value="f" />
            </el-select>
          </el-col>
          <el-col :span="2">
            <el-button type="danger" icon="el-icon-delete" circle size="mini" @click="removeParty(index)" />
          </el-col>
        </el-row>
      </div>
    </div>
    <el-button type="primary" icon="el-icon-plus" size="small" @click="addParty">添加参与方</el-button>
  </div>
</template>

<script>
import { getResourceList } from '@/api/fusionResource'

export default {
  props: {
    value: { type: Array, default: () => [] }
  },
  data() {
    return {
      parties: this.value.length ? JSON.parse(JSON.stringify(this.value)) : [],
      allResources: [],
      loading: false
    }
  },
  computed: {
    organs() {
      const seen = {}
      const list = []
      this.allResources.forEach(r => {
        if (r.organId && !seen[r.organId]) {
          seen[r.organId] = true
          list.push({ id: r.organId, name: r.organName || r.organId })
        }
      })
      return list
    }
  },
  created() {
    this.loadResources()
  },
  methods: {
    async loadResources() {
      this.loading = true
      try {
        const { code, result } = await getResourceList({ pageNo: 1, pageSize: 500 })
        if (code === 0 && result && Array.isArray(result.data)) {
          this.allResources = result.data.filter(r => r.available === undefined || r.available === 0 || r.available === true)
        }
      } catch (e) {
        this.$message.warning('联邦资源目录加载失败，请稍后重试')
      } finally {
        this.loading = false
      }
    },
    resourcesFor(organId) {
      if (!organId) return []
      return this.allResources.filter(r => r.organId === organId)
    },
    fieldsFor(resourceId) {
      if (!resourceId) return []
      const res = this.allResources.find(r => r.resourceId === resourceId)
      if (!res) return []
      // 优先已开放字段，退回全量字段；fieldList 兼容字符串数组/对象数组
      const cols = res.openColumnNameList || res.resourceColumnNameList
      if (cols) return String(cols).split(',').map(s => s.trim()).filter(Boolean)
      if (Array.isArray(res.fieldList)) {
        return res.fieldList.map(f => (typeof f === 'string' ? f : f.fieldName || f.name)).filter(Boolean)
      }
      return []
    },
    onOrganChange(party) {
      party.resourceId = ''
      party.fields = []
      this.onChange()
    },
    onResourceChange(party) {
      party.fields = []
      this.onChange()
    },
    addParty() {
      this.parties.push({ organId: '', resourceId: '', fields: [] })
    },
    removeParty(index) {
      this.parties.splice(index, 1)
      this.onChange()
    },
    onChange() {
      this.$emit('input', JSON.parse(JSON.stringify(this.parties)))
    }
  }
}
</script>

<style scoped>
.party-item { padding: 10px; background: #fafafa; border-radius: 4px; margin-bottom: 10px; }
</style>
