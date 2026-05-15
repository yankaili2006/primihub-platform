<template>
  <div class="app-container">
    <el-page-header content="SQL 格式化工具" style="margin-bottom: 20px;" @back="$router.back()" />

    <el-alert
      title="SQL 格式化工具：粘贴原始 SQL 后点击格式化按钮，可自动对 SQL 进行美化排版（关键字大写、换行缩进）。工具完全本地运行，不会上传 SQL 内容。"
      type="info"
      :closable="false"
      show-icon
      style="margin-bottom: 20px;"
    />

    <el-card style="margin-bottom: 16px;">
      <div slot="header"><span>格式化设置</span></div>
      <el-form :inline="true" size="small">
        <el-form-item label="缩进空格数">
          <el-radio-group v-model="settings.indentSize">
            <el-radio-button :label="2">2 空格</el-radio-button>
            <el-radio-button :label="4">4 空格</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="关键字大写">
          <el-switch v-model="settings.uppercaseKeywords" active-text="是" inactive-text="否" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-sort" @click="handleFormat">格式化</el-button>
          <el-button icon="el-icon-refresh" @click="handleClear">清空</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-row :gutter="20">
      <el-col :span="12">
        <el-card>
          <div slot="header">
            <span>原始 SQL</span>
            <span style="float:right; font-size:12px; color:#909399;">{{ rawSql.length }} 字符</span>
          </div>
          <el-input
            v-model="rawSql"
            type="textarea"
            :rows="20"
            placeholder="请粘贴需要格式化的 SQL 语句..."
            style="font-family: 'Courier New', monospace; font-size: 13px;"
          />
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card>
          <div slot="header">
            <span>格式化结果</span>
            <el-button size="mini" style="float:right;" icon="el-icon-document-copy" @click="copyResult">复制结果</el-button>
          </div>
          <el-input
            v-model="formattedSql"
            type="textarea"
            :rows="20"
            readonly
            placeholder="格式化结果将显示在此处..."
            style="font-family: 'Courier New', monospace; font-size: 13px; background: #fafafa;"
          />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
const SQL_KEYWORDS = [
  'SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'NOT', 'IN', 'EXISTS',
  'JOIN', 'INNER', 'LEFT', 'RIGHT', 'FULL', 'OUTER', 'CROSS',
  'ON', 'AS', 'GROUP', 'BY', 'HAVING', 'ORDER', 'LIMIT', 'OFFSET',
  'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE',
  'CREATE', 'TABLE', 'DROP', 'ALTER', 'INDEX',
  'UNION', 'ALL', 'DISTINCT', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END',
  'WITH', 'OVER', 'PARTITION', 'ROW_NUMBER', 'RANK', 'DENSE_RANK',
  'COUNT', 'SUM', 'AVG', 'MAX', 'MIN', 'STDDEV',
  'NULL', 'IS', 'BETWEEN', 'LIKE', 'ASC', 'DESC',
  'TRUE', 'FALSE', 'CAST', 'COALESCE', 'IF', 'IFNULL',
  'DATE_FORMAT', 'DATEDIFF', 'DATE_ADD', 'DATE_SUB', 'NOW', 'CURDATE',
  'YEAR', 'MONTH', 'DAY', 'HOUR', 'MINUTE', 'SECOND',
  'CONCAT', 'SUBSTRING', 'TRIM', 'UPPER', 'LOWER', 'LENGTH', 'REPLACE',
  'ROUND', 'CEIL', 'FLOOR', 'ABS', 'SQRT', 'POW', 'LOG', 'MOD',
  'UNIX_TIMESTAMP', 'FROM_UNIXTIME', 'EXTRACT', 'TIMESTAMP'
]

const NEWLINE_BEFORE_KEYWORDS = [
  'SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'GROUP BY', 'HAVING',
  'ORDER BY', 'LIMIT', 'UNION', 'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN',
  'FULL JOIN', 'CROSS JOIN', 'JOIN', 'ON', 'SET', 'VALUES'
]

export default {
  name: 'FASqlFormatter',
  data() {
    return {
      rawSql: '',
      formattedSql: '',
      settings: {
        indentSize: 2,
        uppercaseKeywords: true
      }
    }
  },
  methods: {
    handleFormat() {
      if (!this.rawSql.trim()) {
        this.$message.warning('请输入需要格式化的 SQL')
        return
      }
      try {
        this.formattedSql = this.formatSql(this.rawSql)
        this.$message.success('格式化完成')
      } catch (e) {
        this.$message.error('格式化失败，请检查 SQL 语法')
      }
    },
    formatSql(sql) {
      const indent = ' '.repeat(this.settings.indentSize)

      // 清理多余空白
      let result = sql.replace(/\s+/g, ' ').trim()

      // 关键字大写处理
      if (this.settings.uppercaseKeywords) {
        SQL_KEYWORDS.forEach(kw => {
          const regex = new RegExp('\\b' + kw + '\\b', 'gi')
          result = result.replace(regex, kw)
        })
      }

      // 在主要关键词前添加换行
      const newlineKeywords = [
        'SELECT', 'FROM', 'WHERE', 'GROUP BY', 'HAVING', 'ORDER BY',
        'LIMIT', 'UNION ALL', 'UNION',
        'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'FULL JOIN', 'CROSS JOIN', 'JOIN',
        'ON', 'SET', 'VALUES', 'INSERT INTO', 'UPDATE', 'DELETE FROM'
      ]

      newlineKeywords.forEach(kw => {
        const regex = new RegExp('\\s+' + kw.replace(/\s/g, '\\s+') + '\\s+', 'gi')
        result = result.replace(regex, match => '\n' + kw.toUpperCase() + ' ')
      })

      // 在 AND / OR 前换行并缩进
      result = result.replace(/\s+AND\s+/gi, '\n' + indent + 'AND ')
      result = result.replace(/\s+OR\s+/gi, '\n' + indent + 'OR ')

      // SELECT 字段列表：每个逗号后换行缩进
      const selectMatch = result.match(/SELECT\s+([\s\S]+?)\s+FROM/i)
      if (selectMatch) {
        const fields = selectMatch[1]
        const formattedFields = fields
          .split(/,\s*/)
          .map((f, i) => (i === 0 ? f.trim() : indent + f.trim()))
          .join(',\n')
        result = result.replace(selectMatch[1], '\n' + indent + formattedFields + '\n')
      }

      // 清理行首多余空白并规范缩进
      result = result
        .split('\n')
        .map(line => line.trim())
        .filter(line => line.length > 0)
        .join('\n')

      return result
    },
    handleClear() {
      this.rawSql = ''
      this.formattedSql = ''
    },
    copyResult() {
      if (!this.formattedSql) {
        this.$message.warning('暂无格式化结果可复制')
        return
      }
      navigator.clipboard.writeText(this.formattedSql).then(() => {
        this.$message.success('已复制格式化结果到剪贴板')
      }).catch(() => {
        this.$message.error('复制失败，请手动复制')
      })
    }
  }
}
</script>

<style scoped>
.app-container { padding: 20px; }
</style>
