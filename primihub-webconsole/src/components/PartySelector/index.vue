<template>
  <div class="party-selector">
    <div class="party-list">
      <div v-for="(party, index) in parties" :key="index" class="party-item">
        <el-row :gutter="10">
          <el-col :span="6">
            <el-select v-model="party.organId" placeholder="选择机构" filterable @change="onChange">
              <el-option v-for="org in organs" :key="org.id" :label="org.name" :value="org.id" />
            </el-select>
          </el-col>
          <el-col :span="6">
            <el-select v-model="party.resourceId" placeholder="选择数据源" filterable @change="onChange">
              <el-option v-for="res in resources" :key="res.id" :label="res.name" :value="res.id" />
            </el-select>
          </el-col>
          <el-col :span="10">
            <el-select v-model="party.fields" multiple placeholder="选择字段" filterable collapse-tags @change="onChange">
              <el-option v-for="f in fields" :key="f" :label="f" :value="f" />
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
export default {
  props: {
    value: { type: Array, default: () => [] }
  },
  data() {
    return {
      parties: this.value.length ? JSON.parse(JSON.stringify(this.value)) : [],
      organs: [{ id: 'organ_1', name: '机构A' }, { id: 'organ_2', name: '机构B' }],
      resources: [{ id: 1, name: '用户数据表' }, { id: 2, name: '交易记录表' }],
      fields: ['id', 'name', 'age', 'phone', 'address', 'amount']
    }
  },
  methods: {
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
