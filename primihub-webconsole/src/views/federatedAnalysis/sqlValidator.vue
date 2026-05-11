<template>
  <div class="container">
    <el-page-header content="SQL 校验工具" style="margin-bottom: 20px;" @back="$router.push({name:'FederatedAnalysisIndex'})" />
    <el-alert title="SQL 校验工具用于验证联邦分析 SQL 语法是否正确，支持 SQL 格式化与函数快速查询。" type="info" :closable="false" show-icon style="margin-bottom: 20px;" />

    <el-row :gutter="20">
      <el-col :span="14">
        <el-card>
          <div slot="header">
            <span>SQL 编辑器</span>
            <el-dropdown style="float: right;" @command="loadSample">
              <el-button size="mini">示例 SQL <i class="el-icon-arrow-down el-icon--right" /></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item command="simple">简单查询</el-dropdown-item>
                <el-dropdown-item command="join">多表 JOIN</el-dropdown-item>
                <el-dropdown-item command="agg">聚合查询</el-dropdown-item>
                <el-dropdown-item command="complex">复杂查询</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </div>
          <el-input
            ref="sqlEditor"
            v-model="sqlInput"
            type="textarea"
            :rows="12"
            placeholder="请输入 SQL 语句&#10;例如: SELECT id, name, age FROM user WHERE age > 18"
            style="font-family: 'Courier New', monospace; font-size: 14px;"
          />
          <div style="margin-top: 16px; display: flex; gap: 8px; flex-wrap: wrap;">
            <el-button type="primary" :loading="validating" @click="handleValidate" icon="el-icon-check">验证 SQL</el-button>
            <el-button :loading="formatting" @click="handleFormat" icon="el-icon-sort">格式化</el-button>
            <el-button @click="copySql" icon="el-icon-document-copy">复制</el-button>
            <el-button @click="sqlInput = ''" icon="el-icon-delete" style="margin-left: auto;">清空</el-button>
          </div>
          <div style="margin-top: 8px;">
            <span style="font-size: 12px; color: #909399;">字符数: {{ sqlInput.length }} | 行数: {{ sqlInput.split('\n').length }}</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="10">
        <el-card>
          <div slot="header"><span>校验结果</span></div>
          <div v-if="!result" style="color: #999; text-align: center; padding: 60px 0;">
            <i class="el-icon-edit-outline" style="font-size: 48px; color: #dcdfe6;" /><br>
            <span style="margin-top: 12px; display: block;">输入 SQL 后点击"验证 SQL"查看结果</span>
            <span style="font-size: 12px; color: #c0c4cc;">或从示例 SQL 下拉菜单快速开始</span>
          </div>
          <div v-else>
            <el-alert :title="result.valid ? 'SQL 校验通过' : 'SQL 校验失败'" :type="result.valid ? 'success' : 'error'" :description="result.message" :closable="false" show-icon />
            <div v-if="result.valid" style="margin-top: 16px;">
              <el-descriptions :column="1" border size="small">
                <el-descriptions-item label="重写后 SQL">
                  <div style="position:relative;">
                    <pre style="white-space: pre-wrap; margin: 0; font-size: 12px; background: #f5f7fa; padding: 8px; border-radius: 4px; max-height: 200px; overflow-y: auto;">{{ result.rewrittenSql || '-' }}</pre>
                    <el-button v-if="result.rewrittenSql" size="mini" style="position:absolute;top:4px;right:4px;" @click="copyText(result.rewrittenSql)">复制</el-button>
                  </div>
                </el-descriptions-item>
                <el-descriptions-item label="涉及表数量"><el-tag size="small">{{ result.tableCount || 0 }}</el-tag></el-descriptions-item>
                <el-descriptions-item label="涉及字段数量"><el-tag size="small">{{ result.columnCount || 0 }}</el-tag></el-descriptions-item>
              </el-descriptions>
            </div>
            <div v-else style="margin-top: 16px;">
              <el-descriptions :column="1" border size="small">
                <el-descriptions-item label="错误位置">
                  <el-tag size="small" type="danger">第 {{ result.errorLine || '-' }} 行, 第 {{ result.errorColumn || '-' }} 列</el-tag>
                </el-descriptions-item>
                <el-descriptions-item label="错误详情">
                  <pre style="white-space: pre-wrap; margin: 0; color: #f56c6c; background: #fef0f0; padding: 8px; border-radius: 4px;">{{ result.detail || result.message }}</pre>
                </el-descriptions-item>
              </el-descriptions>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top: 20px;">
      <div slot="header">
        <span>SQL 函数参考</span>
        <el-input v-model="funcSearch" placeholder="搜索函数..." prefix-icon="el-icon-search" size="mini" style="width: 200px; float: right;" />
      </div>
      <el-table :data="filteredFunctions" v-loading="funcLoading" stripe @sort-change="handleSortChange">
        <el-table-column prop="name" label="函数名" width="200" sortable="custom" />
        <el-table-column prop="category" label="分类" width="120">
          <template slot-scope="scope">
            <el-tag size="small" :type="getCategoryType(scope.row.category)">{{ scope.row.category }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="说明" min-width="300" />
        <el-table-column prop="syntax" label="语法" min-width="280">
          <template slot-scope="scope">
            <code style="background: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-size: 12px;">{{ scope.row.syntax }}</code>
            <el-button type="text" size="mini" style="margin-left: 4px;" @click="copyText(scope.row.syntax)"><i class="el-icon-document-copy" /></el-button>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="scope">
            <el-button type="text" size="mini" @click="insertToEditor(scope.row.syntax)">插入</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { validateSql, formatSql, getSqlFunctions } from '@/api/federatedAnalysis'

const SAMPLES = {
  simple: 'SELECT id, name, age\nFROM user\nWHERE age > 18\nORDER BY age DESC',
  join: 'SELECT u.id, u.name, o.order_no, o.amount\nFROM user u\nJOIN orders o ON u.id = o.user_id\nWHERE o.create_date >= \'2024-01-01\'',
  agg: 'SELECT department,\n       COUNT(*) AS emp_count,\n       AVG(salary) AS avg_salary,\n       MAX(salary) AS max_salary\nFROM employee\nGROUP BY department\nHAVING COUNT(*) > 5',
  complex: 'WITH ranked AS (\n  SELECT id, name, score,\n         ROW_NUMBER() OVER (PARTITION BY class_id ORDER BY score DESC) AS rnk\n  FROM student_score\n)\nSELECT r.id, r.name, r.score, c.class_name\nFROM ranked r\nJOIN class c ON r.class_id = c.id\nWHERE r.rnk <= 10\nORDER BY c.class_name, r.rnk'
}

export default {
  name: 'SqlValidator',
  data() {
    return {
      sqlInput: '', result: null, validating: false, formatting: false,
      functions: [], funcLoading: false, funcSearch: '',
      sortProp: '', sortOrder: ''
    }
  },
  computed: {
    filteredFunctions() {
      let list = this.functions
      if (this.funcSearch) {
        const kw = this.funcSearch.toLowerCase()
        list = list.filter(f => (f.name || '').toLowerCase().includes(kw) || (f.description || '').toLowerCase().includes(kw) || (f.category || '').toLowerCase().includes(kw))
      }
      if (this.sortProp) {
        list = [...list].sort((a, b) => {
          const va = (a[this.sortProp] || '').toString()
          const vb = (b[this.sortProp] || '').toString()
          return this.sortOrder === 'ascending' ? va.localeCompare(vb) : vb.localeCompare(va)
        })
      }
      return list
    }
  },
  created() { this.loadFunctions() },
  methods: {
    getCategoryType(cat) {
      return { '聚合': 'primary', '字符串': 'success', '数学': 'warning', '日期': 'info', '条件': 'danger' }[cat] || ''
    },
    loadSample(cmd) { this.sqlInput = SAMPLES[cmd] || ''; this.result = null },
    async handleValidate() {
      if (!this.sqlInput.trim()) { this.$message.warning('请输入 SQL'); return }
      this.validating = true
      try {
        const res = await validateSql({ sql: this.sqlInput, dataResources: [] })
        this.result = res.code === 0 ? res.result : { valid: false, message: res.message || '校验失败' }
      } catch (e) { this.result = { valid: false, message: '请求异常: ' + e.message } }
      this.validating = false
    },
    async handleFormat() {
      if (!this.sqlInput.trim()) { this.$message.warning('请输入 SQL'); return }
      this.formatting = true
      try {
        const res = await formatSql({ sql: this.sqlInput })
        if (res.code === 0 && res.result && res.result.formattedSql) {
          this.sqlInput = res.result.formattedSql; this.$message.success('格式化成功')
        } else { this.$message.warning('格式化失败') }
      } catch (e) { this.$message.error('请求异常: ' + e.message) }
      this.formatting = false
    },
    copySql() {
      if (!this.sqlInput) { this.$message.warning('没有可复制的内容'); return }
      this.copyText(this.sqlInput)
    },
    copyText(text) {
      const ta = document.createElement('textarea')
      ta.value = text; document.body.appendChild(ta); ta.select()
      document.execCommand('copy'); document.body.removeChild(ta)
      this.$message.success('已复制到剪贴板')
    },
    insertToEditor(syntax) {
      this.sqlInput += (this.sqlInput ? '\n' : '') + syntax
      this.$message.success('已插入到编辑器')
    },
    handleSortChange({ prop, order }) { this.sortProp = prop; this.sortOrder = order },
    async loadFunctions() {
      this.funcLoading = true
      try {
        const res = await getSqlFunctions()
        if (res.code === 0) this.functions = res.result || []
      } catch (e) { console.error(e) }
      this.funcLoading = false
    }
  }
}
</script>

<style lang="scss" scoped>
.container { overflow: hidden; background: #fff; padding: 36px; border-radius: 8px; }
</style>
