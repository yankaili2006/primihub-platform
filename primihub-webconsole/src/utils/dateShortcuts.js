/**
 * 日期快捷选项 - 用于 el-date-picker 的 picker-options
 * 统一全平台日期选择体验
 */

const getNow = () => new Date()
const getDayStart = (offset = 0) => {
  const d = new Date()
  d.setDate(d.getDate() + offset)
  d.setHours(0, 0, 0, 0)
  return d
}
const getDayEnd = (offset = 0) => {
  const d = new Date()
  d.setDate(d.getDate() + offset)
  d.setHours(23, 59, 59, 999)
  return d
}

export const dateRangeShortcuts = [
  { text: '今天', onClick(picker) { picker.$emit('pick', [getDayStart(), getDayEnd()]) } },
  { text: '昨天', onClick(picker) { picker.$emit('pick', [getDayStart(-1), getDayEnd(-1)]) } },
  { text: '最近7天', onClick(picker) { picker.$emit('pick', [getDayStart(-6), getDayEnd()]) } },
  { text: '最近30天', onClick(picker) { picker.$emit('pick', [getDayStart(-29), getDayEnd()]) } },
  { text: '本月', onClick(picker) { const d = new Date(); picker.$emit('pick', [new Date(d.getFullYear(), d.getMonth(), 1), getDayEnd()]) } },
  { text: '最近90天', onClick(picker) { picker.$emit('pick', [getDayStart(-89), getDayEnd()]) } }
]

export const dateRangePickerOptions = { shortcuts: dateRangeShortcuts }
