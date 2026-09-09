<template>
  <div class="agent-hub-container">
    <div class="page-header">
      <h2>智能体</h2>
      <p class="sub-title">基于平台已登记的数据资源与模型产物（农业、水利）构建的可交互智能体，点击卡片跳转到 agent.primihub.com 对应技能。</p>
    </div>
    <el-row :gutter="20">
      <el-col v-for="agent in agents" :key="agent.id" :xs="24" :sm="12" :md="8" :lg="8" :xl="6">
        <el-card class="agent-card" shadow="hover" @click.native="openAgent(agent)">
          <div class="agent-card-header">
            <i :class="agent.icon" class="agent-icon" />
            <div class="agent-title">
              <span class="agent-name">{{ agent.name }}</span>
              <el-tag size="mini" :type="agent.tagType">{{ agent.category }}</el-tag>
            </div>
          </div>
          <p class="agent-desc">{{ agent.desc }}</p>
          <div class="agent-backing">
            <span class="backing-label">数据/模型支撑：</span>
            <el-tag v-for="b in agent.backing" :key="b" size="mini" type="info" class="backing-tag">{{ b }}</el-tag>
          </div>
          <div class="agent-footer">
            <el-button type="primary" size="small" icon="el-icon-position" @click.stop="openAgent(agent)">打开智能体</el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
// 智能体清单：与 agent.primihub.com /api/skills 实际路由对齐（2026-09-09 实测）。
// 每个 url 均为可匿名访问的技能 Web UI；backing 标注平台内真实登记的资源/产物。
const AGENT_BASE = 'https://agent.primihub.com'

export default {
  name: 'AgentHubList',
  data() {
    return {
      agents: [
        {
          id: 'agriculture-datasets',
          name: '农业数据集智能体',
          category: '农业数据',
          tagType: 'success',
          icon: 'el-icon-collection',
          desc: 'IP102 昆虫 · DeepWeeds 杂草 · PlantDoc 植物病害等公开农业数据集目录浏览与检索。',
          backing: ['病害目录61类(res33)', 'IP102害虫102类(res34)'],
          url: AGENT_BASE + '/api/skills/agriculture-datasets/ui'
        },
        {
          id: 'saai-crop-algorithm',
          name: '作物算法智能体',
          category: '算法',
          tagType: 'primary',
          icon: 'el-icon-cpu',
          desc: '小麦/玉米算法组件——生育期识别、长势评价、水肥建议，含 7 道生产准入闸门与端到端分析管道。',
          backing: ['作物专家模型包', '模型产物登记(data_model_artifact)'],
          url: AGENT_BASE + '/api/skills/saai-crop-algorithm/ui'
        },
        {
          id: 'saai-data-asset',
          name: '农业数据资产智能体',
          category: '农业数据',
          tagType: 'success',
          icon: 'el-icon-coin',
          desc: '遥感数据适配器、田间标签采集、数据字典——13 个数据域标准与 4 类标准接口。',
          backing: ['田间观测记录(Org1 res20)', '13数据域标准'],
          url: AGENT_BASE + '/api/skills/saai-data-asset/ui'
        },
        {
          id: 'eo-learn',
          name: '遥感分析智能体',
          category: '遥感',
          tagType: 'warning',
          icon: 'el-icon-partly-cloudy',
          desc: 'Sentinel Hub eo-learn 地球观测机器学习工作流——NDVI 等遥感特征提取。',
          backing: ['NDVI 引擎', '遥感场景/特征数据域'],
          url: AGENT_BASE + '/api/skills/eo-learn/ui'
        },
        {
          id: 'label-collector',
          name: '田间标注采集智能体',
          category: '采集',
          tagType: 'danger',
          icon: 'el-icon-edit-outline',
          desc: '田间病虫草害标注采集入口——按 FieldLabelV1 契约回传 A-D 级质量标签。',
          backing: ['FieldLabelV1 契约', '病害/害虫类别目录'],
          url: AGENT_BASE + '/label-collector/'
        },
        {
          id: 'saai-imap-benchmark',
          name: 'iMAP 对标智能体',
          category: '分析',
          tagType: 'info',
          icon: 'el-icon-data-line',
          desc: '中国中化 iMAP 模式对标分析——差距评估、定位调整与实施建议。',
          backing: ['SAAI 对标方案'],
          url: AGENT_BASE + '/api/skills/saai-imap-benchmark/ui'
        },
        // ── 水利（2026-09-09）：两张卡片经 fragments embed-proxy 打开 .50 常驻 SkillUI，
        //    计算走 primihub-water-infer 推理服务(.50:9440)，见 pcloud skills/ops/primihub-water-infer
        {
          id: 'primihub-flood-poc',
          name: '超汛限水库智能体',
          category: '水利',
          tagType: 'primary',
          icon: 'el-icon-heavy-rain',
          desc: '双角色隐私计算：水库管理方(Org0)私有水库表 × 测站监测方(Org1)私有测站表 → PSI 只暴露共有测站 → MPC 差值只揭示给水库方 → 超汛限水库清单。',
          backing: ['Org0 私有 flood_A_reservoir_*(res32)', 'Org1 私有 flood_B_station_*(res18)', 'water-infer 推理服务'],
          url: AGENT_BASE + '/api/embed-proxy/primihub-flood-poc'
        },
        {
          id: 'primihub-postgis-poc',
          name: 'PostGIS 空间分析智能体',
          category: '水利',
          tagType: 'primary',
          icon: 'el-icon-map-location',
          desc: 'ST_Transform / ST_Simplify / ST_Intersection 经平台联邦分析数据源 SQL 下推执行——地块 × 泛洪区，返回真实 WKT 几何。',
          backing: ['联邦分析数据源 postgis-poc', 'ST_Transform/Simplify/Intersection 任务', 'water-infer 推理服务'],
          url: AGENT_BASE + '/api/embed-proxy/primihub-postgis-poc'
        },
        // ── 水利 P1 三场景（2026-09-10，真实公开数据：HydroBASINS / OSM 水库 / Open-Meteo 降水 / SPI）
        {
          id: 'water-basin-alert',
          name: '流域级强降水预警智能体',
          category: '水利',
          tagType: 'primary',
          icon: 'el-icon-warning-outline',
          desc: '水库管理方私有台账+警戒阈值 × 监测方私有近 7 日实测降水 → PSI+MPC 差值只揭示水库方 → 按 HydroBASINS 子流域聚合超阈值座数，应急方只见流域计数。',
          backing: ['Org0 私有 water_reservoirs_*(res44)', 'Org2 私有 water_precip_daily_*(res13)', 'PostGIS water_basins_lev5', 'water-infer /v1/basin/alert'],
          url: AGENT_BASE + '/api/embed-proxy/primihub-flood-poc?scene=basin'
        },
        {
          id: 'water-drought-stats',
          name: '干旱指数联邦统计智能体',
          category: '水利',
          tagType: 'primary',
          icon: 'el-icon-sunny',
          desc: '三个区域气象局各持私有 SPI-30 表，MPC 联合算全域平均 SPI 与干旱站数，任何一方看不到别家站级值（与明文对照一致）。',
          backing: ['Org0/1/2 私有 water_drought_party*', 'water-infer /v1/drought/stats (mpc_statistics)'],
          url: AGENT_BASE + '/api/embed-proxy/primihub-flood-poc?scene=drought'
        },
        {
          id: 'water-pir',
          name: '水库档案匿踪查询智能体',
          category: '水利',
          tagType: 'primary',
          icon: 'el-icon-search',
          desc: '应急方按水库编码匿踪查询水库管理方台账（APSI 关键词 PIR），台账仅授权应急方可见，水库方不知道被查的是哪座。',
          backing: ['Org0 auth=3 water_reservoirs_pir_*(res51)', 'water-infer /v1/pir/query'],
          url: AGENT_BASE + '/api/embed-proxy/primihub-flood-poc?scene=pir'
        }
      ]
    }
  },
  methods: {
    openAgent(agent) {
      window.open(agent.url, '_blank', 'noopener')
    }
  }
}
</script>

<style lang="scss" scoped>
.agent-hub-container {
  padding: 20px;
  .page-header {
    margin-bottom: 20px;
    h2 { margin: 0 0 6px; font-size: 20px; }
    .sub-title { margin: 0; color: #909399; font-size: 13px; }
  }
  .agent-card {
    margin-bottom: 20px;
    cursor: pointer;
    .agent-card-header {
      display: flex;
      align-items: center;
      margin-bottom: 10px;
      .agent-icon { font-size: 28px; color: #409EFF; margin-right: 10px; }
      .agent-title {
        display: flex;
        flex-direction: column;
        .agent-name { font-size: 15px; font-weight: 600; margin-bottom: 4px; }
      }
    }
    .agent-desc {
      color: #606266;
      font-size: 13px;
      line-height: 1.6;
      min-height: 62px;
      margin: 0 0 8px;
    }
    .agent-backing {
      min-height: 46px;
      .backing-label { font-size: 12px; color: #909399; }
      .backing-tag { margin: 0 4px 4px 0; }
    }
    .agent-footer { text-align: right; }
  }
}
</style>
