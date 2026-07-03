const BRAND = "primihub"  // primihub | haihui

const brands = {
  primihub: {
    name: "PrimiHub",
    company: "PrimiHub",
    platformName: "PrimiHub隐私计算平台",
    shortName: "PrimiHub",
    footer: "PrimiHub V1.6.0",
    copyright: "Copyright © 2026 PrimiHub. All rights reserved.",
    modelName: "PrimiHub隐私计算大模型",
    assistantAlt: "PrimiHub",
    assistantText: "PrimiHub小助手",
    appName: "PrimiHub隐私计算平台",
  },
  haihui: {
    name: "海会科技",
    company: "海会科技",
    platformName: "DataItem隐私计算平台",
    shortName: "DataItem",
    footer: "海会科技 V1.6.0",
    copyright: "Copyright © 2026 海会科技. All rights reserved.",
    modelName: "DataItem隐私计算大模型",
    assistantAlt: "海会科技",
    assistantText: "海会科技小助手",
    appName: "DataItem隐私计算平台",
  },
}

export const brand = brands[BRAND] || brands.primihub
export default brand
