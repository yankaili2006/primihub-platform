import Vue from 'vue'
import Router from 'vue-router'

Vue.use(Router)

/* Layout */
import Layout from '@/layout'

/**
 * constantRoutes
 * a base page that does not have permission requirements
 * all roles can be accessed
 */
export const constantRoutes = [
  {
    path: '/login',
    component: () => import('@/views/login/index'),
    hidden: true,
    meta: { title: '登录页' }
  },
  {
    path: '/auth',
    component: () => import('@/views/auth/index'),
    hidden: true,
    meta: { title: '授权页' }
  },
  {
    path: '/register',
    component: () => import('@/views/register/index'),
    hidden: true,
    meta: { title: '注册页' }
  },
  {
    path: '/forgotPwd',
    component: () => import('@/views/forgotPwd'),
    hidden: true,
    meta: { title: '忘记密码' }
  },
  {
    path: '/updatePwd',
    component: () => import('@/views/updatePwd'),
    hidden: true,
    name: '更新密码',
    meta: { title: '更新密码' }
  },
  {
    path: '/404',
    component: () => import('@/views/404'),
    hidden: true,
    meta: { title: 'not found' }
  },
  {
    path: '/applicationIndex',
    name: 'applicationIndex',
    hidden: true,
    component: () => import('@/views/applicationMarket'),
    meta: { title: '应用市场' }
  },
  {
    path: '/bigModel',
    name: 'BigModel',
    hidden: true,
    component: () => import('@/views/bigModel/index'),
    meta: { title: 'DataItem隐私计算大模型' }
  },
  {
    path: '/applicationIndex/detail/:name',
    name: 'ApplicationDetail',
    hidden: true,
    component: () => import('@/views/applicationMarket/detail'),
    meta: { title: '应用详情' }
  },
  {
    path: '/applicationIndex/application/:name',
    name: 'Application',
    hidden: true,
    component: () => import('@/views/applicationMarket/application'),
    meta: { title: '应用页' }
  },
  {
    path: '/map',
    component: Layout,
    name: 'Map',
    hidden: true,
    redirect: '/map/index',
    meta: { title: '地图' },
    children: [
      {
        path: 'index',
        name: 'mapIndex',
        meta: { title: '地图', breadcrumb: false },
        component: () => import('@/views/map/index')
      }
    ]
  },
  {
    path: '/',
    component: Layout,
    redirect: '/project/list'
  }
]

export const asyncRoutes = [
  {
    path: '/privateSearch',
    component: Layout,
    name: 'PrivateSearch',
    redirect: '/privateSearch/list',
    meta: { title: '隐匿查询', icon: 'el-icon-search' },
    children: [{
      path: 'list',
      name: 'PrivateSearchList',
      component: () => import('@/views/privateSearch/index'),
      meta: { title: '隐匿查询', breadcrumb: false }
    }, {
      path: 'task',
      name: 'PIRTask',
      hidden: true,
      component: () => import('@/views/privateSearch/task'),
      meta: {
        title: '隐匿查询任务',
        activeMenu: '/privateSearch/list',
        parent: { name: 'PrivateSearchList' }
      }
    }, {
      path: 'detail/:id',
      name: 'PIRDetail',
      component: () => import('@/views/privateSearch/detail'),
      meta: {
        title: '任务详情',
        activeMenu: '/privateSearch/list'
      },
      hidden: true
    }]
  },
  {
    path: '/PSI',
    component: Layout,
    name: 'PSI',
    redirect: '/PSI/list',
    meta: { title: '隐私求交', icon: 'el-icon-lock' },
    children: [
      {
        path: 'task',
        name: 'PSITask',
        component: () => import('@/views/PSI/task'),
        meta: {
          title: '求交任务',
          activeMenu: '/PSI/list'
        },
        hidden: true
      }, {
        path: 'list',
        name: 'PSIList',
        component: () => import('@/views/PSI/list'),
        meta: { title: '隐私求交', breadcrumb: false }
      }, {
        path: 'detail/:id',
        name: 'PSIDetail',
        component: () => import('@/views/PSI/detail'),
        meta: {
          title: '任务详情',
          activeMenu: '/PSI/list'
        },
        hidden: true
      }, {
        path: 'result',
        name: 'PSIResult',
        component: () => import('@/views/PSI/result'),
        meta: {
          title: '求交结果',
          activeMenu: '/PSI/list'
        },
        hidden: true
      }]
  },
  {
    path: '/Difference',
    component: Layout,
    name: 'Difference',
    redirect: '/Difference/list',
    meta: { title: '联邦求差', icon: 'el-icon-minus' },
    children: [
      {
        path: 'list',
        name: 'DifferenceList',
        component: () => import('@/views/Difference/list'),
        meta: { title: '联邦求差', breadcrumb: false }
      },
      {
        path: 'task',
        name: 'DifferenceTask',
        hidden: true,
        component: () => import('@/views/Difference/task'),
        meta: { title: '求差任务', activeMenu: '/Difference/list' }
      },
      {
        path: 'detail/:id',
        name: 'DifferenceDetail',
        hidden: true,
        component: () => import('@/views/Difference/detail'),
        meta: { title: '求差详情', activeMenu: '/Difference/list' }
      }
    ]
  },
  {
    path: '/SingleParty',
    component: Layout,
    name: 'SingleParty',
    redirect: '/SingleParty/list',
    meta: { title: '单方算法', icon: 'el-icon-s-data' },
    children: [
      {
        path: 'list',
        name: 'SinglePartyList',
        component: () => import('@/views/singleParty/list'),
        meta: { title: '单方算法', breadcrumb: false }
      },
      {
        path: 'task',
        name: 'SinglePartyTask',
        hidden: true,
        component: () => import('@/views/singleParty/task'),
        meta: { title: '创建任务', activeMenu: '/SingleParty/list' }
      },
      {
        path: 'detail/:id',
        name: 'SinglePartyDetail',
        hidden: true,
        component: () => import('@/views/singleParty/detail'),
        meta: { title: '任务详情', activeMenu: '/SingleParty/list' }
      },
      {
        path: 'dataStats',
        name: 'SinglePartyDataStats',
        component: () => import('@/views/singleParty/dataStats'),
        meta: { title: '单方数据统计' }
      },
      {
        path: 'dataCleaning',
        name: 'SinglePartyDataCleaning',
        component: () => import('@/views/singleParty/dataCleaning'),
        meta: { title: '单方数据清洗' }
      },
      {
        path: 'dataScaling',
        name: 'SinglePartyDataScaling',
        component: () => import('@/views/singleParty/dataScaling'),
        meta: { title: '单方数据缩放' }
      },
      {
        path: 'featureEncode',
        name: 'SinglePartyFeatureEncode',
        component: () => import('@/views/singleParty/featureEncode'),
        meta: { title: '单方特征编码' }
      },
      {
        path: 'featureBin',
        name: 'SinglePartyFeatureBin',
        component: () => import('@/views/singleParty/featureBin'),
        meta: { title: '单方特征分箱' }
      },
      {
        path: 'featureSelect',
        name: 'SinglePartyFeatureSelect',
        component: () => import('@/views/singleParty/featureSelect'),
        meta: { title: '单方特征筛选' }
      },
      {
        path: 'featureDerive',
        name: 'SinglePartyFeatureDerive',
        component: () => import('@/views/singleParty/featureDerive'),
        meta: { title: '单方特征衍生' }
      },
      {
        path: 'pythonScript',
        name: 'SinglePartyPythonScript',
        component: () => import('@/views/singleParty/pythonScript'),
        meta: { title: '单方Python脚本处理' }
      },
      {
        path: 'sqlProcess',
        name: 'SinglePartySqlProcess',
        component: () => import('@/views/singleParty/sqlProcess'),
        meta: { title: '单方SQL处理' }
      },
      {
        path: 'logRecord',
        name: 'SinglePartyLogRecord',
        component: () => import('@/views/singleParty/logRecord'),
        meta: { title: '单方学习日志记录' }
      },
      {
        path: 'logExport',
        name: 'SinglePartyLogExport',
        component: () => import('@/views/singleParty/logExport'),
        meta: { title: '单方学习日志导出' }
      },
      {
        path: 'lrAlgorithm',
        name: 'SinglePartyLRAlgorithm',
        component: () => import('@/views/singleParty/lrAlgorithm'),
        meta: { title: '单方机器学习LR算法' }
      },
      {
        path: 'xgbAlgorithm',
        name: 'SinglePartyXGBAlgorithm',
        component: () => import('@/views/singleParty/xgbAlgorithm'),
        meta: { title: '单方机器学习XGB算法' }
      }
    ]
  },
  {
    path: '/Union',
    component: Layout,
    name: 'Union',
    redirect: '/Union/list',
    meta: { title: '联邦求并', icon: 'el-icon-plus' },
    children: [
      {
        path: 'list',
        name: 'UnionList',
        component: () => import('@/views/Union/list'),
        meta: { title: '联邦求并', breadcrumb: false }
      },
      {
        path: 'task',
        name: 'UnionTask',
        hidden: true,
        component: () => import('@/views/Union/task'),
        meta: { title: '求并任务', activeMenu: '/Union/list' }
      },
      {
        path: 'detail/:id',
        name: 'UnionDetail',
        hidden: true,
        component: () => import('@/views/Union/detail'),
        meta: { title: '求并详情', activeMenu: '/Union/list' }
      }
    ]
  },
  {
    path: '/FederatedLearning',
    component: Layout,
    name: 'FederatedLearning',
    redirect: '/FederatedLearning/list',
    meta: { title: '联邦学习', icon: 'el-icon-data-analysis' },
    children: [
      {
        path: 'list',
        name: 'FederatedLearningList',
        component: () => import('@/views/FederatedLearning/list'),
        meta: { title: '联邦学习', breadcrumb: false }
      },
      {
        path: 'modelPreview',
        name: 'FederatedModelPreview',
        component: () => import('@/views/federatedLearning/modelPreview'),
        meta: { title: '联邦学习模型预览' }
      },
      {
        path: 'modelImport',
        name: 'FederatedModelImport',
        component: () => import('@/views/federatedLearning/modelImport'),
        meta: { title: '联邦学习模型导入' }
      },
      {
        path: 'modelExport',
        name: 'FederatedModelExport',
        component: () => import('@/views/federatedLearning/modelExport'),
        meta: { title: '联邦学习模型导出' }
      },
      {
        path: 'modelingWorkbench',
        name: 'FederatedModelingWorkbench',
        component: () => import('@/views/federatedLearning/modelingWorkbench'),
        meta: { title: '联邦建模工作台' }
      }
    ]
  },
  {
    path: '/project',
    name: 'Project',
    component: Layout,
    redirect: '/project/list',
    alwaysShow: true,
    meta: { icon: 'el-icon-menu', title: '项目管理' },
    children: [
      {
        path: 'list',
        name: 'ProjectList',
        meta: { icon: 'el-icon-menu', title: '项目列表', breadcrumb: false },
        component: () => import('@/views/project/list')
      },
      {
        path: 'create',
        name: 'ProjectCreate',
        meta: {
          title: '新建项目'
        },
        hidden: true,
        component: () => import('@/views/project/create')
      },
      {
        path: 'detail/:id',
        name: 'ProjectDetail',
        meta: {
          title: '项目详情',
          activeMenu: '/project/list'
        },
        hidden: true,
        component: () => import('@/views/project/detail')
      },
      {
        path: 'detail/:id/createTask',
        name: 'ModelCreate',
        meta: {
          title: '创建任务',
          activeMenu: '/project/list',
          parent: { name: 'ProjectDetail' }
        },
        hidden: true,
        component: () => import('@/views/model/create/index')
      },
      {
        path: 'detail/:id/task/:taskId',
        name: 'ModelTaskDetail',
        meta: {
          title: '任务详情',
          activeMenu: '/project/list',
          parent: { name: 'ProjectDetail' }
        },
        hidden: true,
        component: () => import('@/views/project/taskDetail')
      },
      {
        path: 'permission',
        name: 'ProjectPermission',
        component: () => import('@/views/project/permission'),
        meta: { title: '项目权限配置' }
      },
      {
        path: 'resultSave',
        name: 'ProjectResultSave',
        component: () => import('@/views/project/resultSave'),
        meta: { title: '项目结果保存' }
      },
      {
        path: 'ledgerExport',
        name: 'ProjectLedgerExport',
        component: () => import('@/views/project/ledgerExport'),
        meta: { title: '项目台账导出' }
      },
      {
        path: 'approvalConfig',
        name: 'ProjectApprovalConfig',
        component: () => import('@/views/project/approvalConfig'),
        meta: { title: '项目流程审核配置' }
      },
      {
        path: 'federatedLearning',
        name: 'ProjectFLTasks',
        component: () => import('@/views/project/federatedLearning'),
        meta: { title: '项目联邦学习任务' }
      },
      {
        path: 'federatedAnalysis',
        name: 'ProjectFATasks',
        component: () => import('@/views/project/federatedAnalysis'),
        meta: { title: '项目联邦分析任务' }
      },
      {
        path: 'federatedStatistics',
        name: 'ProjectFSTasks',
        component: () => import('@/views/project/federatedStatistics'),
        meta: { title: '项目联邦统计任务' }
      }
    ]
  },
  {
    path: '/federatedLearning',
    component: Layout,
    name: 'ProjectFederatedLearning',
    redirect: '/federatedLearning/index',
    alwaysShow: true,
    meta: { title: '联邦学习', icon: 'el-icon-data-analysis' },
    children: [
      {
        path: 'index',
        name: 'FederatedLearningIndex',
        component: () => import('@/views/federatedLearning/index'),
        meta: { title: '联邦学习' }
      },
      {
        path: 'dataFusion',
        name: 'FLDataFusion',
        component: () => import('@/views/federatedLearning/dataFusion'),
        meta: { title: '联邦学习-数据融合' }
      },
      {
        path: 'paramTuning',
        name: 'FederatedLearningParamTuning',
        component: () => import('@/views/federatedLearning/paramTuning'),
        meta: { title: '联邦建模参数调优' }
      },
      {
        path: 'trainingIteration',
        name: 'FederatedLearningTrainingIteration',
        component: () => import('@/views/federatedLearning/trainingIteration'),
        meta: { title: '联邦建模训练迭代' }
      },
      {
        path: 'trainingReport',
        name: 'FederatedLearningTrainingReport',
        component: () => import('@/views/federatedLearning/trainingReport'),
        meta: { title: '联邦建模训练报告' }
      },
      {
        path: 'logRecord',
        name: 'FederatedLearningLogRecord',
        component: () => import('@/views/federatedLearning/logRecord'),
        meta: { title: '联邦学习日志记录' }
      },
      {
        path: 'logExport',
        name: 'FederatedLearningLogExport',
        component: () => import('@/views/federatedLearning/logExport'),
        meta: { title: '联邦学习日志导出' }
      },
      {
        path: 'dataMerge',
        name: 'FederatedLearningSinglePartyDataMerge',
        component: () => import('@/views/federatedLearning/dataMerge'),
        meta: { title: '单方数据合并模块' }
      },
      {
        path: 'featureSimilarity',
        name: 'FLFeatureSimilarity',
        component: () => import('@/views/federatedLearning/featureSimilarity'),
        meta: { title: '联邦学习-特征相似度分析' }
      },
      {
        path: 'featureEncodeFL',
        name: 'FLFeatureEncode',
        component: () => import('@/views/federatedLearning/featureEncodeFL'),
        meta: { title: '联邦学习-特征编码' }
      },
      {
        path: 'featureAlign',
        name: 'FLFeatureAlign',
        component: () => import('@/views/federatedLearning/featureAlign'),
        meta: { title: '联邦学习-特征对齐' }
      },
      {
        path: 'featureShare',
        name: 'FLFeatureShare',
        component: () => import('@/views/federatedLearning/featureShare'),
        meta: { title: '联邦学习-特征分享' }
      },
      {
        path: 'featureFill',
        name: 'FLFeatureFill',
        component: () => import('@/views/federatedLearning/featureFill'),
        meta: { title: '联邦学习-特征填充' }
      },
      {
        path: 'sampleExpand',
        name: 'FLSampleExpand',
        component: () => import('@/views/federatedLearning/sampleExpand'),
        meta: { title: '联邦学习-样本列扩展' }
      },
      {
        path: 'sampleWeight',
        name: 'FLSampleWeight',
        component: () => import('@/views/federatedLearning/sampleWeight'),
        meta: { title: '联邦学习-样本加权' }
      },
      {
        path: 'metricModeling',
        name: 'FLMetricModeling',
        component: () => import('@/views/federatedLearning/metricModeling'),
        meta: { title: '联邦学习-指标建模分析' }
      },
      {
        path: 'featureWarehouse',
        name: 'FLFeatureWarehouse',
        component: () => import('@/views/federatedLearning/featureWarehouse'),
        meta: { title: '联邦学习-特征装仓' }
      },
      {
        path: 'dataSplit',
        name: 'FLDataSplit',
        component: () => import('@/views/federatedLearning/dataSplit'),
        meta: { title: '联邦学习-数据分割' }
      },
      {
        path: 'dataTransform',
        name: 'FLDataTransform',
        component: () => import('@/views/federatedLearning/dataTransform'),
        meta: { title: '联邦学习-数据转换' }
      },
      {
        path: 'verticalLinearTrain',
        name: 'FLVerticalLinearTrain',
        component: () => import('@/views/federatedLearning/verticalLinearTrain'),
        meta: { title: '线性回归建模（纵向）' }
      },
      {
        path: 'verticalLogisticTrain',
        name: 'FLVerticalLogisticTrain',
        component: () => import('@/views/federatedLearning/verticalLogisticTrain'),
        meta: { title: '逻辑回归建模（纵向）' }
      },
      {
        path: 'verticalXGBoostTrain',
        name: 'FLVerticalXGBoostTrain',
        component: () => import('@/views/federatedLearning/verticalXGBoostTrain'),
        meta: { title: 'XGBoost建模（纵向）' }
      },
      {
        path: 'verticalLinearPredict',
        name: 'FLVerticalLinearPredict',
        component: () => import('@/views/federatedLearning/verticalLinearPredict'),
        meta: { title: '线性回归预测（纵向）' }
      },
      {
        path: 'verticalLogisticPredict',
        name: 'FLVerticalLogisticPredict',
        component: () => import('@/views/federatedLearning/verticalLogisticPredict'),
        meta: { title: '逻辑回归预测（纵向）' }
      },
      {
        path: 'verticalXGBoostPredict',
        name: 'FLVerticalXGBoostPredict',
        component: () => import('@/views/federatedLearning/verticalXGBoostPredict'),
        meta: { title: 'XGBoost预测（纵向）' }
      }
    ]
  },
  {
    path: '/federatedAnalysis',
    component: Layout,
    name: 'ProjectFederatedAnalysis',
    redirect: '/federatedAnalysis/index',
    alwaysShow: true,
    meta: { title: '联邦分析', icon: 'el-icon-s-data' },
    children: [
      {
        path: 'index',
        name: 'FederatedAnalysisIndex',
        component: () => import('@/views/federatedAnalysis/index'),
        meta: { title: '联邦分析' }
      },
      {
        path: 'sqlValidator',
        name: 'FederatedAnalysisSqlValidator',
        component: () => import('@/views/federatedAnalysis/sqlValidator'),
        meta: { title: 'SQL校验工具' }
      },
      {
        path: 'relationalDB',
        name: 'FederatedAnalysisRelationalDB',
        component: () => import('@/views/federatedAnalysis/relationalDB'),
        meta: { title: '联邦分析对接主流关系型数据库' }
      },
      {
        path: 'bigData',
        name: 'FederatedAnalysisBigData',
        component: () => import('@/views/federatedAnalysis/bigData'),
        meta: { title: '联邦分析对接主流大数据平台' }
      },
      {
        path: 'publicCloud',
        name: 'FederatedAnalysisPublicCloud',
        component: () => import('@/views/federatedAnalysis/publicCloud'),
        meta: { title: '联邦分析对接主流公有云平台' }
      },
      {
        path: 'logRecord',
        name: 'FederatedAnalysisLogRecord',
        component: () => import('@/views/federatedAnalysis/logRecord'),
        meta: { title: '联邦分析日志记录' }
      },
      {
        path: 'logExport',
        name: 'FederatedAnalysisLogExport',
        component: () => import('@/views/federatedAnalysis/logExport'),
        meta: { title: '联邦分析日志导出' }
      },
      {
        path: 'fieldConfidentiality',
        name: 'FederatedAnalysisFieldConfidentiality',
        component: () => import('@/views/federatedAnalysis/fieldConfidentiality'),
        meta: { title: '字段保密属性' }
      },
      {
        path: 'filterOperator',
        name: 'FAFilterOperator',
        component: () => import('@/views/federatedAnalysis/filterOperator'),
        meta: { title: '联邦分析-筛选算子' }
      },
      {
        path: 'joinOperator',
        name: 'FAJoinOperator',
        component: () => import('@/views/federatedAnalysis/joinOperator'),
        meta: { title: '联邦分析-连接算子' }
      },
      {
        path: 'aggregateOperator',
        name: 'FAAggregateOperator',
        component: () => import('@/views/federatedAnalysis/aggregateOperator'),
        meta: { title: '联邦分析-聚合算子' }
      },
      {
        path: 'groupOperator',
        name: 'FAGroupOperator',
        component: () => import('@/views/federatedAnalysis/groupOperator'),
        meta: { title: '联邦分析-分组算子' }
      },
      {
        path: 'sortOperator',
        name: 'FASortOperator',
        component: () => import('@/views/federatedAnalysis/sortOperator'),
        meta: { title: '联邦分析-排序算子' }
      },
      {
        path: 'windowFunction',
        name: 'FAWindowFunction',
        component: () => import('@/views/federatedAnalysis/windowFunction'),
        meta: { title: '联邦分析-窗口函数' }
      },
      {
        path: 'correlatedSubquery',
        name: 'FACorrelatedSubquery',
        component: () => import('@/views/federatedAnalysis/correlatedSubquery'),
        meta: { title: '联邦分析-关联子查询' }
      },
      {
        path: 'nonCorrelatedSubquery',
        name: 'FANonCorrelatedSubquery',
        component: () => import('@/views/federatedAnalysis/nonCorrelatedSubquery'),
        meta: { title: '联邦分析-非关联子查询' }
      },
      {
        path: 'charFunctions',
        name: 'FACharFunctions',
        component: () => import('@/views/federatedAnalysis/charFunctions'),
        meta: { title: '联邦分析-字符类型函数' }
      },
      {
        path: 'dateFunctions',
        name: 'FADateFunctions',
        component: () => import('@/views/federatedAnalysis/dateFunctions'),
        meta: { title: '联邦分析-日期类型函数' }
      },
      {
        path: 'timestampFunctions',
        name: 'FATimestampFunctions',
        component: () => import('@/views/federatedAnalysis/timestampFunctions'),
        meta: { title: '联邦分析-时间戳类型函数' }
      },
      {
        path: 'sqlFormatter',
        name: 'FASqlFormatter',
        component: () => import('@/views/federatedAnalysis/sqlFormatter'),
        meta: { title: '联邦分析-SQL格式化' }
      },
      {
        path: 'floatFunctions',
        name: 'FAFloatFunctions',
        component: () => import('@/views/federatedAnalysis/floatFunctions'),
        meta: { title: '联邦分析-浮点类型函数' }
      }
    ]
  },
  {
    path: '/federatedStatistics',
    component: Layout,
    name: 'ProjectFederatedStatistics',
    redirect: '/federatedStatistics/index',
    alwaysShow: true,
    meta: { title: '联邦统计', icon: 'el-icon-pie-chart' },
    children: [
      {
        path: 'index',
        name: 'FederatedStatisticsIndex',
        component: () => import('@/views/federatedStatistics/index'),
        meta: { title: '联邦统计' }
      },
      {
        path: 'resultStorage',
        name: 'FederatedStatisticsResultStorage',
        component: () => import('@/views/federatedStatistics/resultStorage'),
        meta: { title: '联邦统计结果存储' }
      },
      {
        path: 'resultExport',
        name: 'FederatedStatisticsResultExport',
        component: () => import('@/views/federatedStatistics/resultExport'),
        meta: { title: '联邦统计结果导出' }
      },
      {
        path: 'logRecord',
        name: 'FederatedStatisticsLogRecord',
        component: () => import('@/views/federatedStatistics/logRecord'),
        meta: { title: '联邦统计日志记录' }
      },
      {
        path: 'logExport',
        name: 'FederatedStatisticsLogExport',
        component: () => import('@/views/federatedStatistics/logExport'),
        meta: { title: '联邦统计日志导出' }
      },
      {
        path: 'groupStats',
        name: 'FederatedStatisticsGroupStats',
        component: () => import('@/views/federatedStatistics/groupStats'),
        meta: { title: '联邦统计-分组统计' }
      },
      {
        path: 'conditionStats',
        name: 'FederatedStatisticsConditionStats',
        component: () => import('@/views/federatedStatistics/conditionStats'),
        meta: { title: '联邦统计-条件统计' }
      },
      {
        path: 'ratioStats',
        name: 'FederatedStatisticsRatioStats',
        component: () => import('@/views/federatedStatistics/ratioStats'),
        meta: { title: '联邦统计-占比统计' }
      },
      {
        path: 'tTest',
        name: 'FederatedStatisticsTTest',
        component: () => import('@/views/federatedStatistics/tTest'),
        meta: { title: '联邦统计-T检验' }
      },
      {
        path: 'fTest',
        name: 'FederatedStatisticsFTest',
        component: () => import('@/views/federatedStatistics/fTest'),
        meta: { title: '联邦统计-F检验' }
      },
      {
        path: 'chiSquareTest',
        name: 'FederatedStatisticsChiSquareTest',
        component: () => import('@/views/federatedStatistics/chiSquareTest'),
        meta: { title: '联邦统计-卡方检验' }
      },
      {
        path: 'regressionAnalysis',
        name: 'FederatedStatisticsRegressionAnalysis',
        component: () => import('@/views/federatedStatistics/regressionAnalysis'),
        meta: { title: '联邦统计-回归分析' }
      },
      {
        path: 'correlationAnalysis',
        name: 'FederatedStatisticsCorrelationAnalysis',
        component: () => import('@/views/federatedStatistics/correlationAnalysis'),
        meta: { title: '联邦统计-相关性分析' }
      }
    ]
  },
  {
    path: '/federatedQuery',
    component: Layout,
    name: 'FederatedQuery',
    redirect: '/federatedQuery/dh/batch',
    alwaysShow: true,
    meta: { title: '联邦查询', icon: 'el-icon-search' },
    children: [
      {
        path: 'dh/batch',
        name: 'FederatedQueryDHBatch',
        component: () => import('@/views/federatedQuery/dh/batchQuery'),
        meta: { title: 'DH批量联邦查询' }
      },
      {
        path: 'dh/realtime',
        name: 'FederatedQueryDHRealtime',
        component: () => import('@/views/federatedQuery/dh/realtimeQuery'),
        meta: { title: 'DH实时联邦查询' }
      },
      {
        path: 'ot/batch',
        name: 'FederatedQueryOTBatch',
        component: () => import('@/views/federatedQuery/ot/batchQuery'),
        meta: { title: 'OT批量联邦查询' }
      },
      {
        path: 'ot/realtime',
        name: 'FederatedQueryOTRealtime',
        component: () => import('@/views/federatedQuery/ot/realtimeQuery'),
        meta: { title: 'OT实时联邦查询' }
      },
      {
        path: 'he/batch',
        name: 'FederatedQueryHEBatch',
        component: () => import('@/views/federatedQuery/he/batchQuery'),
        meta: { title: 'HE批量联邦查询' }
      },
      {
        path: 'he/realtime',
        name: 'FederatedQueryHERealtime',
        component: () => import('@/views/federatedQuery/he/realtimeQuery'),
        meta: { title: 'HE实时联邦查询' }
      },
      {
        path: 'intersection/batch',
        name: 'FederatedQueryIntersectionBatch',
        component: () => import('@/views/federatedQuery/intersection/batch'),
        meta: { title: '批量联邦求交' }
      },
      {
        path: 'intersection/realtime',
        name: 'FederatedQueryIntersectionRealtime',
        component: () => import('@/views/federatedQuery/intersection/realtime'),
        meta: { title: '实时联邦求交' }
      },
      {
        path: 'intersection/dedup',
        name: 'FederatedQueryIntersectionDedup',
        component: () => import('@/views/federatedQuery/intersection/dedup'),
        meta: { title: '联邦求交去重' }
      },
      {
        path: 'intersection/multiColumn',
        name: 'FederatedQueryIntersectionMultiColumn',
        component: () => import('@/views/federatedQuery/intersection/multiColumn'),
        meta: { title: '联邦求交多列联合ID' }
      },
      {
        path: 'tools/payloadChunk',
        name: 'FederatedQueryPayloadChunk',
        component: () => import('@/views/federatedQuery/tools/payloadChunk'),
        meta: { title: 'Payload分块' }
      },
      {
        path: 'tools/outputFields',
        name: 'FederatedQueryOutputFields',
        component: () => import('@/views/federatedQuery/tools/outputFields'),
        meta: { title: '输出字段指定' }
      },
      {
        path: 'tools/dedup',
        name: 'FederatedQueryToolsDedup',
        component: () => import('@/views/federatedQuery/tools/dedup'),
        meta: { title: '查询去重' }
      },
      {
        path: 'tools/bucket',
        name: 'FederatedQueryToolsBucket',
        component: () => import('@/views/federatedQuery/tools/bucket'),
        meta: { title: '分桶工具' }
      },
      {
        path: 'tools/codec',
        name: 'FederatedQueryToolsCodec',
        component: () => import('@/views/federatedQuery/tools/codec'),
        meta: { title: '编解码工具' }
      },
      {
        path: 'tools/compress',
        name: 'FederatedQueryToolsCompress',
        component: () => import('@/views/federatedQuery/tools/compress'),
        meta: { title: '压缩工具' }
      },
      {
        path: 'tools/decompress',
        name: 'FederatedQueryToolsDecompress',
        component: () => import('@/views/federatedQuery/tools/decompress'),
        meta: { title: '解压工具' }
      },
      {
        path: 'logs/intersectionRecord',
        name: 'FederatedQueryLogIntersectionRecord',
        component: () => import('@/views/federatedQuery/logs/intersectionRecord'),
        meta: { title: '联邦求交日志' }
      },
      {
        path: 'logs/intersectionExport',
        name: 'FederatedQueryLogIntersectionExport',
        component: () => import('@/views/federatedQuery/logs/intersectionExport'),
        meta: { title: '联邦求交日志导出' }
      },
      {
        path: 'logs/queryRecord',
        name: 'FederatedQueryLogQueryRecord',
        component: () => import('@/views/federatedQuery/logs/queryRecord'),
        meta: { title: '联邦查询日志' }
      },
      {
        path: 'logs/queryExport',
        name: 'FederatedQueryLogQueryExport',
        component: () => import('@/views/federatedQuery/logs/queryExport'),
        meta: { title: '联邦查询日志导出' }
      },
      {
        path: 'billingByCount',
        name: 'FederatedQueryBillingByCount',
        component: () => import('@/views/federatedQuery/billingByCount'),
        meta: { title: '计费配置(按次数)' }
      },
      {
        path: 'billingByHit',
        name: 'FederatedQueryBillingByHit',
        component: () => import('@/views/federatedQuery/billingByHit'),
        meta: { title: '计费配置(按命中)' }
      },
      {
        path: 'deduplicationFixed',
        name: 'FederatedQueryDeduplicationFixed',
        component: () => import('@/views/federatedQuery/deduplicationFixed'),
        meta: { title: '去重计费(固定窗口)' }
      },
      {
        path: 'deduplicationRolling',
        name: 'FederatedQueryDeduplicationRolling',
        component: () => import('@/views/federatedQuery/deduplicationRolling'),
        meta: { title: '去重计费(滚动窗口)' }
      },
      {
        path: 'apiValidation',
        name: 'FederatedQueryApiValidation',
        component: () => import('@/views/federatedQuery/apiValidation'),
        meta: { title: '接口校验' }
      }
    ]
  },
  {
    path: '/policeDataFusion',
    component: Layout,
    name: 'PoliceDataFusion',
    redirect: '/policeDataFusion/intersection',
    alwaysShow: true,
    meta: { title: '警务数据融合', icon: 'el-icon-connection' },
    children: [
      {
        path: 'intersection',
        name: 'PoliceDataIntersection',
        component: () => import('@/views/policeDataFusion/intersection'),
        meta: { title: '警务数据交集数据融合' }
      },
      {
        path: 'insuranceApi',
        name: 'InsuranceApiConnect',
        component: () => import('@/views/policeDataFusion/insuranceApi'),
        meta: { title: '保险机构接口对接' }
      },
      {
        path: 'homomorphicKey',
        name: 'InsuranceHomomorphicKey',
        component: () => import('@/views/policeDataFusion/homomorphicKey'),
        meta: { title: '保险机构同态密钥创建' }
      },
      {
        path: 'modelEncrypt',
        name: 'InsuranceModelEncrypt',
        component: () => import('@/views/policeDataFusion/modelEncrypt'),
        meta: { title: '保险机构模型同态加密' }
      },
      {
        path: 'encryptedCompute',
        name: 'EncryptedModelCompute',
        component: () => import('@/views/policeDataFusion/encryptedCompute'),
        meta: { title: '加密模型联合运算' }
      },
      {
        path: 'dataDecrypt',
        name: 'InsuranceDataDecrypt',
        component: () => import('@/views/policeDataFusion/dataDecrypt'),
        meta: { title: '保险机构数据解密' }
      },
      {
        path: 'policeConnect',
        name: 'PoliceDataConnect',
        component: () => import('@/views/policeDataFusion/policeConnect'),
        meta: { title: '警务数据对接' }
      },
      {
        path: 'batchExchange',
        name: 'ModelCipherBatchExchange',
        component: () => import('@/views/policeDataFusion/batchExchange'),
        meta: { title: '模型密文数据安全交换（批量）' }
      },
      {
        path: 'logRecord',
        name: 'PoliceDataLogRecord',
        component: () => import('@/views/policeDataFusion/logRecord'),
        meta: { title: '流程执行日志记录' }
      },
      {
        path: 'logExport',
        name: 'PoliceDataLogExport',
        component: () => import('@/views/policeDataFusion/logExport'),
        meta: { title: '流程执行日志导出' }
      }
    ]
  },
  {
    path: '/electronicCert',
    component: Layout,
    name: 'ElectronicCertCompare',
    redirect: '/electronicCert/featureConvert',
    alwaysShow: true,
    meta: { title: '电子证件比对', icon: 'el-icon-postcard' },
    children: [
      {
        path: 'featureConvert',
        name: 'ElectronicCertFeatureConvert',
        component: () => import('@/views/electronicCert/featureConvert'),
        meta: { title: '电子证件特征转换' }
      },
      {
        path: 'onSiteConvert',
        name: 'OnSiteCertFeatureConvert',
        component: () => import('@/views/electronicCert/onSiteConvert'),
        meta: { title: '现场证件特征转换' }
      },
      {
        path: 'privacyCompare',
        name: 'FeaturePrivacyCompare',
        component: () => import('@/views/electronicCert/privacyCompare'),
        meta: { title: '特征数据隐私比对' }
      },
      {
        path: 'policeConnect',
        name: 'ElectronicCertPoliceConnect',
        component: () => import('@/views/electronicCert/policeConnect'),
        meta: { title: '警务数据对接' }
      },
      {
        path: 'orgDataImport',
        name: 'OrgDataImport',
        component: () => import('@/views/electronicCert/orgDataImport'),
        meta: { title: '使用机构数据接入' }
      },
      {
        path: 'orgDataExport',
        name: 'OrgDataExport',
        component: () => import('@/views/electronicCert/orgDataExport'),
        meta: { title: '使用机构数据导出' }
      },
      {
        path: 'batchExchange',
        name: 'FeatureCipherBatchExchange',
        component: () => import('@/views/electronicCert/batchExchange'),
        meta: { title: '特征密文数据安全交换（批量）' }
      },
      {
        path: 'realTimeExchange',
        name: 'FeatureCipherRealTimeExchange',
        component: () => import('@/views/electronicCert/realTimeExchange'),
        meta: { title: '特征密文数据安全交换（实时）' }
      },
      {
        path: 'logRecord',
        name: 'ElectronicCertLogRecord',
        component: () => import('@/views/electronicCert/logRecord'),
        meta: { title: '流程执行日志记录' }
      },
      {
        path: 'logExport',
        name: 'ElectronicCertLogExport',
        component: () => import('@/views/electronicCert/logExport'),
        meta: { title: '流程执行日志导出' }
      }
    ]
  },
  {
    path: '/model',
    component: Layout,
    name: 'Model',
    redirect: '/model/list',
    meta: { title: '模型管理', icon: 'el-icon-files' },
    children: [
      {
        path: 'list',
        name: 'ModelList',
        component: () => import('@/views/model/list'),
        meta: { title: '模型管理', breadcrumb: false }
      },
      {
        path: 'detail/:id',
        name: 'ModelDetail',
        meta: {
          title: '模型详情',
          activeMenu: '/model/list'
        },
        hidden: true,
        component: () => import('@/views/model/detail')
      }
    ]
  },
  {
    path: '/reasoning',
    component: Layout,
    name: 'ModelReasoning',
    redirect: '/reasoning/list',
    meta: { title: '服务管理', icon: 'el-icon-aim' },
    children: [
      {
        path: 'list',
        name: 'ModelReasoningList',
        component: () => import('@/views/reasoning/list'),
        meta: { title: '服务管理', breadcrumb: false }
      },
      {
        path: 'task',
        name: 'ModelReasoningTask',
        hidden: true,
        component: () => import('@/views/reasoning/task'),
        meta: {
          title: '模型推理任务',
          activeMenu: '/reasoning/list'
        }
      },
      {
        path: 'detail/:id',
        name: 'ModelReasoningDetail',
        meta: {
          title: '模型推理详情',
          activeMenu: '/reasoning/list'
        },
        hidden: true,
        component: () => import('@/views/reasoning/detail')
      }
    ]
  },
  {
    path: '/resource',
    component: Layout,
    name: 'ResourceMenu',
    redirect: '/resource/list',
    meta: { title: '资源管理', icon: 'el-icon-s-operation' },
    children: [
      {
        path: 'list',
        name: 'ResourceList',
        component: () => import('@/views/resource/list'),
        meta: { title: '我的资源' }
      },
      {
        path: 'unionList',
        name: 'UnionList',
        component: () => import('@/views/resource/unionList'),
        meta: { title: '协作方资源' }
      },
      {
        path: 'availableResources',
        name: 'AvailableResources',
        component: () => import('@/views/resource/availableResources'),
        meta: { title: '可申请的资源' }
      },
      {
        path: 'derivedDataList',
        name: 'DerivedDataList',
        component: () => import('@/views/resource/derivedDataList'),
        meta: { title: '衍生数据资源' }
      },
      {
        path: 'create',
        name: 'ResourceUpload',
        hidden: true,
        component: () => import('@/views/resource/create'),
        meta: { title: '新建资源', activeMenu: '/resource/list' }
      },
      {
        path: 'edit/:id',
        name: 'ResourceEdit',
        hidden: true,
        component: () => import('@/views/resource/create'),
        meta: { title: '编辑资源', activeMenu: '/resource/list' }
      },
      {
        path: 'detail/:id',
        name: 'ResourceDetail',
        meta: {
          title: '资源详情',
          activeMenu: '/resource/list'
        },
        hidden: true,
        component: () => import('@/views/resource/detail')
      },
      {
        path: 'unionResourceDetail/:id',
        name: 'UnionResourceDetail',
        meta: {
          title: '协作方资源详情',
          activeMenu: '/resource/unionList'
        },
        hidden: true,
        component: () => import('@/views/resource/unionResourceDetail')
      },
      {
        path: 'derivedDataResourceDetail/:id',
        name: 'DerivedDataResourceDetail',
        meta: {
          title: '衍生数据资源详情',
          activeMenu: '/resource/derivedDataList'
        },
        hidden: true,
        component: () => import('@/views/resource/derivedDataResourceDetail')
      },
      {
        path: 'requirementList',
        name: 'DataRequirementList',
        component: () => import('@/views/resource/requirementList'),
        meta: { title: '数据需求列表' }
      },
      {
        path: 'requirementConfig',
        name: 'DataRequirementConfig',
        component: () => import('@/views/resource/requirementConfig'),
        meta: { title: '数据需求配置' }
      },
      {
        path: 'requirementMatch',
        name: 'DataRequirementMatch',
        component: () => import('@/views/resource/requirementMatch'),
        meta: { title: '匹配数据需求所需数据' }
      },
      {
        path: 'sharedDatasetList',
        name: 'SharedDatasetList',
        component: () => import('@/views/resource/sharedDatasetList'),
        meta: { title: '共享数据集列表' }
      },
      {
        path: 'authAudit',
        name: 'ResourceAuthAudit',
        component: () => import('@/views/resource/authAudit'),
        meta: { title: '授权审核' }
      },
      {
        path: 'authRecord',
        name: 'ResourceAuthRecord',
        component: () => import('@/views/resource/authRecord'),
        meta: { title: '授权记录' }
      }
    ]
  },
  {
    path: '/setting',
    component: Layout,
    name: 'Setting',
    redirect: '/setting/user',
    meta: { title: '系统设置', icon: 'el-icon-s-tools' },
    children: [
      {
        path: 'user',
        name: 'UserManage',
        component: () => import('@/views/setting/user'),
        meta: { title: '用户管理' }
      },
      {
        path: 'role',
        name: 'RoleManage',
        component: () => import('@/views/setting/role'),
        meta: { title: '角色管理' }
      },
      {
        path: 'center',
        name: 'CenterManage',
        component: () => import('@/views/setting/center'),
        meta: { title: '节点管理' }
      },
      {
        path: 'accessManagement',
        name: 'AccessManagement',
        component: () => import('@/views/setting/accessManagement'),
        meta: { title: '接入方管理' }
      },
      {
        path: 'cooperation',
        name: 'CooperationManagement',
        component: () => import('@/views/setting/cooperation'),
        meta: { title: '合作方管理' }
      },
      {
        path: 'approval',
        name: 'ApprovalWorkflow',
        component: () => import('@/views/setting/approval'),
        meta: { title: '审批工作流' }
      },
      {
        path: 'dataExchange',
        name: 'DataExchangeLog',
        component: () => import('@/views/setting/dataExchange'),
        meta: { title: '数据交换日志' }
      },
      {
        path: 'system',
        name: 'SystemConfig',
        component: () => import('@/views/setting/system'),
        meta: { title: '系统配置' }
      },
      {
        path: 'ui',
        name: 'UISetting',
        component: () => import('@/views/setting/ui'),
        meta: { title: '界面设置' },
        hidden: true
      },
      {
        path: 'cancelCooperation',
        name: 'CancelCooperation',
        component: () => import('@/views/setting/cancelCooperation'),
        meta: { title: '节点取消合作' }
      },
      {
        path: 'organ',
        name: 'OrganManage',
        component: () => import('@/views/setting/organ'),
        meta: { title: '机构管理' }
      }
    ]
  },
  {
    path: '/whitelist',
    component: Layout,
    name: 'Whitelist',
    redirect: '/whitelist/list',
    meta: { title: '白名单管理', icon: 'el-icon-s-check' },
    children: [
      {
        path: 'list',
        name: 'WhitelistList',
        component: () => import('@/views/whitelist/list'),
        meta: { title: '白名单列表' }
      },
      {
        path: 'config',
        name: 'WhitelistConfig',
        component: () => import('@/views/whitelist/config'),
        meta: { title: '白名单配置' }
      },
      {
        path: 'accessLog',
        name: 'WhitelistAccessLog',
        component: () => import('@/views/whitelist/accessLog'),
        meta: { title: '访问日志记录' }
      }
    ]
  },
  {
    path: '/tenant',
    component: Layout,
    name: 'Tenant',
    redirect: '/tenant/list',
    meta: { title: '租户管理', icon: 'el-icon-office-building' },
    children: [
      {
        path: 'list',
        name: 'TenantList',
        component: () => import('@/views/tenant/list'),
        meta: { title: '租户列表' }
      },
      {
        path: 'resource/:id',
        name: 'TenantResource',
        component: () => import('@/views/tenant/resource'),
        meta: {
          title: '资源分配',
          activeMenu: '/tenant/list'
        },
        hidden: true
      },
      {
        path: 'isolationConfig',
        name: 'TenantIsolationConfig',
        component: () => import('@/views/tenant/isolationConfig'),
        meta: { title: '租户间计算流程隔离' }
      },
      {
        path: 'dataIsolation',
        name: 'TenantDataIsolation',
        component: () => import('@/views/tenant/dataIsolation'),
        meta: { title: '租户数据隔离' }
      }
    ]
  },
  {
    path: '/evidence',
    component: Layout,
    name: 'Evidence',
    redirect: '/evidence/query',
    meta: { title: '存证管理', icon: 'el-icon-document-checked' },
    children: [
      {
        path: 'query',
        name: 'EvidenceQuery',
        component: () => import('@/views/evidence/query'),
        meta: { title: '存证查询' }
      },
      {
        path: 'timestamp',
        name: 'EvidenceTimestamp',
        component: () => import('@/views/evidence/timestamp'),
        meta: { title: '时间戳管理' }
      },
      {
        path: 'config',
        name: 'EvidenceConfig',
        component: () => import('@/views/evidence/config'),
        meta: { title: '存证配置' }
      },
      {
        path: 'export',
        name: 'EvidenceExport',
        component: () => import('@/views/evidence/export'),
        meta: { title: '存证加密导出' }
      },
      {
        path: 'api',
        name: 'EvidenceApi',
        component: () => import('@/views/evidence/api'),
        meta: { title: '存证接口对接' }
      }
    ]
  },
  {
    path: '/monitor',
    component: Layout,
    name: 'Monitor',
    redirect: '/monitor/index',
    meta: { title: '监控管理', icon: 'el-icon-data-line' },
    children: [
      {
        path: 'index',
        name: 'MonitorIndex',
        component: () => import('@/views/monitor/index'),
        meta: { title: '监控管理', breadcrumb: false }
      },
      {
        path: 'os',
        name: 'MonitorOs',
        component: () => import('@/views/monitor/index'),
        meta: { title: '操作系统监控', breadcrumb: false }
      },
      {
        path: 'database',
        name: 'MonitorDatabase',
        component: () => import('@/views/monitor/index'),
        meta: { title: '数据库监控', breadcrumb: false }
      },
      {
        path: 'middleware',
        name: 'MonitorMiddleware',
        component: () => import('@/views/monitor/index'),
        meta: { title: '中间件监控', breadcrumb: false }
      },
      {
        path: 'alerts',
        name: 'MonitorAlerts',
        component: () => import('@/views/monitor/index'),
        meta: { title: '告警历史', breadcrumb: false }
      }
    ]
  },
  {
    path: '/api',
    component: Layout,
    name: 'ApiManage',
    redirect: '/api/list',
    meta: { title: '接口管理', icon: 'el-icon-connection' },
    children: [
      {
        path: 'list',
        name: 'ApiList',
        component: () => import('@/views/api/list'),
        meta: { title: '接口列表' }
      },
      {
        path: 'auth',
        name: 'ApiAuth',
        component: () => import('@/views/api/auth'),
        meta: { title: '接口授权' }
      },
      {
        path: 'log',
        name: 'ApiLog',
        component: () => import('@/views/api/log'),
        meta: { title: '接口日志' }
      }
    ]
  },
  {
    path: '/log',
    component: Layout,
    name: 'Log',
    redirect: '/log/index',
    meta: { title: '日志管理', icon: 'el-icon-warning-outline' },
    children: [
      {
        path: 'index',
        name: 'LogList',
        component: () => import('@/views/log/index'),
        meta: { title: '任务日志', breadcrumb: false }
      },
      {
        path: 'operationDefinition',
        name: 'OperationLogDefinition',
        component: () => import('@/views/logManagement/operationDefinition'),
        meta: { title: '操作日志定义' }
      },
      {
        path: 'scheduleDefinition',
        name: 'ScheduleLogDefinition',
        component: () => import('@/views/logManagement/scheduleDefinition'),
        meta: { title: '调度日志定义' }
      },
      {
        path: 'computeDefinition',
        name: 'ComputeLogDefinition',
        component: () => import('@/views/logManagement/computeDefinition'),
        meta: { title: '计算日志定义' }
      },
      {
        path: 'operationLog',
        name: 'OperationLog',
        component: () => import('@/views/logManagement/operationLog'),
        meta: { title: '操作日志记录' }
      },
      {
        path: 'scheduleLog',
        name: 'ScheduleLog',
        component: () => import('@/views/logManagement/scheduleLog'),
        meta: { title: '调度日志记录' }
      },
      {
        path: 'computeLog',
        name: 'ComputeLog',
        component: () => import('@/views/logManagement/computeLog'),
        meta: { title: '计算日志记录' }
      },
      {
        path: 'logExport',
        name: 'LogExport',
        component: () => import('@/views/logManagement/logExport'),
        meta: { title: '日志导出' }
      },
      {
        path: 'detail/:id',
        name: 'LogDetail',
        component: () => import('@/views/log/detail'),
        meta: { title: '日志详情', activeMenu: '/log/index' },
        hidden: true
      }
    ]
  },
  // 404 page must be placed at the end !!!
  { path: '*', redirect: '/404', hidden: true }
]
const createRouter = () => new Router({
  // mode: 'history', // require service support
  scrollBehavior: () => ({ y: 0 }),
  routes: constantRoutes
})

const router = createRouter()

// Detail see: https://github.com/vuejs/vue-router/issues/1234#issuecomment-357941465
export function resetRouter() {
  const newRouter = createRouter()
  router.matcher = newRouter.matcher // reset router
}
// export function selfAddRouter() {
//   const newRouter = createRouter()
//   router.matcher = newRouter.matcher // reset router

// }

export default router
