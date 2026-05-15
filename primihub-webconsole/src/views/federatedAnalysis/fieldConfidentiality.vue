<template>
  <div class="container">
    <el-card>
      <div slot="header"><span>字段保密属性配置</span></div>
      <el-form ref="form" :model="form" label-width="140px" size="small" :rules="rules">
        <el-alert title="配置查询结果中各个字段的保密属性，控制哪些字段可以明文返回、哪些需要脱敏处理" type="info" :closable="false" show-icon style="margin-bottom:20px" />
        <el-form-item label="数据源" required>
          <el-select v-model="form.dataSource" placeholder="请选择数据源" style="width:300px" @change="loadFields">
            <el-option v-for="ds in dataSources" :key="ds.id" :label="ds.name" :value="ds.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="字段保密属性">
          <el-table :data="form.fields" stripe max-height="400">
            <el-table-column label="字段名" prop="name" width="200" />
            <el-table-column label="数据类型" prop="type" width="120" />
            <el-table-column label="保密等级" width="160">
              <template slot-scope="scope">
                <el-select v-model="scope.row.level" placeholder="选择等级" style="width:130px">
                  <el-option label="非保密" value="PUBLIC" />
                  <el-option label="低保密" value="LOW" />
                  <el-option label="中保密" value="MEDIUM" />
                  <el-option label="高保密" value="HIGH" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column label="脱敏方式" width="160">
              <template slot-scope="scope">
                <el-select v-if="scope.row.level !== 'PUBLIC'" v-model="scope.row.maskType" placeholder="选择脱敏方式" style="width:130px">
                  <el-option label="部分隐藏" value="PARTIAL" />
                  <el-option label="完全隐藏" value="FULL" />
                  <el-option label="哈希脱敏" value="HASH" />
                  <el-option label="差分隐私" value="DP" />
                </el-select>
                <span v-else style="color:#999">无需脱敏</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="120">
              <template slot-scope="scope">
                <el-button type="text" size="small" @click="removeField(scope.$index)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
          <el-button type="text" icon="el-icon-plus" style="margin-top:10px" @click="addField">添加字段</el-button>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="saving" @click="saveConfig">保存配置</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'FieldConfidentiality',
  data() {
    return {
      form: { dataSource: '', fields: [] },
      dataSources: [
        { id: 1, name: 'MySQL-fusion0' },
        { id: 2, name: 'MySQL-fusion1' },
        { id: 3, name: 'MySQL-fusion2' }
      ],
      saving: false,
      rules: { dataSource: [{ required: true, message: '请选择数据源', trigger: 'change' }] }
    }
  },
  methods: {
    loadFields() {
      this.form.fields = [
        { name: 'id', type: 'INT64', level: 'PUBLIC', maskType: '' },
        { name: 'name', type: 'STRING', level: 'MEDIUM', maskType: 'PARTIAL' },
        { name: 'phone', type: 'STRING', level: 'HIGH', maskType: 'PARTIAL' },
        { name: 'id_card', type: 'STRING', level: 'HIGH', maskType: 'PARTIAL' },
        { name: 'address', type: 'STRING', level: 'MEDIUM', maskType: 'PARTIAL' },
        { name: 'income', type: 'DOUBLE', level: 'MEDIUM', maskType: 'HASH' },
        { name: 'score', type: 'INT64', level: 'LOW', maskType: 'DP' }
      ]
    },
    addField() {
      this.form.fields.push({ name: '', type: 'STRING', level: 'PUBLIC', maskType: '' })
    },
    removeField(index) {
      this.form.fields.splice(index, 1)
    },
    saveConfig() {
      this.$refs.form.validate(valid => {
        if (!valid) return
        this.saving = true
        setTimeout(() => {
          this.saving = false
          this.$message.success('字段保密属性配置已保存')
        }, 1000)
      })
    },
    handleReset() {
      this.form.dataSource = ''
      this.form.fields = []
    }
  }
}
</script>
