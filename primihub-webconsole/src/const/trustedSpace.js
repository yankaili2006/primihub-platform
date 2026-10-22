/**
 * 可信空间常量：缺省空间名、接口不可用时的兜底列表、标签颜色。
 * 真源是后端 data_trusted_space（/data/trustedSpace/listAll 或 /data/resource/getTrustedSpaces），
 * 这里只收敛 resource/list.vue 与 agentHub/index.vue 原先各自一份的拷贝。
 */
export const DEFAULT_SPACE_NAME = 'PrimiHub'

export const FALLBACK_SPACE_NAMES = ['水利', '新能源车', '农业', DEFAULT_SPACE_NAME]

const SPACE_TAG_TYPES = { '水利': 'primary', '新能源车': 'success', '农业': 'warning' }

/** 颜色只做区分；未知/缺省统一 info */
export function spaceTagType(name) {
  return SPACE_TAG_TYPES[name || DEFAULT_SPACE_NAME] || 'info'
}

/** 空间编码校验（与后端 DataTrustedSpaceService.CODE_PATTERN 一致） */
export const SPACE_CODE_PATTERN = /^[A-Za-z0-9_-]{1,64}$/
