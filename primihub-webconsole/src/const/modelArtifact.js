// 模型产物类型选项(create页支持自定义输入,不限于此列表)
export const MODEL_KIND_OPTIONS = [
  {
    label: 'vision_weights',
    value: 'vision_weights'
  },
  {
    label: 'llm_config',
    value: 'llm_config'
  },
  {
    label: 'rule_pack',
    value: 'rule_pack'
  },
  {
    label: 'sklearn',
    value: 'sklearn'
  },
  {
    label: 'other',
    value: 'other'
  }
]

// 模型产物文件允许上传的后缀
export const MODEL_ARTIFACT_FILE_SUFFIXS = ['pt', 'pth', 'onnx', 'json', 'zip', 'tar', 'gz', 'bin']
