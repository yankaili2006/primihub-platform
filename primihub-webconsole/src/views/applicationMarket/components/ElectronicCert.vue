<template>
  <div class="scene-app">
    <el-card shadow="never" class="intro">
      <h3>电子证件比对应用</h3>
      <p>面向证件核验场景，将电子证件与现场证件分别做特征转换后进行特征数据的隐私比对，比对在密文域完成、原始证件信息不泄露，支撑身份核验、人证一致性校验等业务。</p>
      <el-steps :active="4" align-center finish-status="success" class="flow">
        <el-step title="电子证件特征转换" />
        <el-step title="现场证件特征转换" />
        <el-step title="特征数据隐私比对" />
        <el-step title="密文安全交换 / 日志" />
      </el-steps>
    </el-card>

    <el-card shadow="never" class="entries">
      <div slot="header"><span>功能入口</span></div>
      <el-row :gutter="16">
        <el-col v-for="f in features" :key="f.path" :span="6">
          <div class="entry" @click="go(f.path)">
            <i :class="f.icon" />
            <span>{{ f.title }}</span>
          </div>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script>
export default {
  name: 'ElectronicCert',
  data() {
    return {
      features: [
        { title: '电子证件特征转换', path: '/electronicCert/featureConvert', icon: 'el-icon-postcard' },
        { title: '现场证件特征转换', path: '/electronicCert/onSiteConvert', icon: 'el-icon-camera' },
        { title: '特征数据隐私比对', path: '/electronicCert/privacyCompare', icon: 'el-icon-s-check' },
        { title: '警务数据对接', path: '/electronicCert/policeConnect', icon: 'el-icon-office-building' },
        { title: '使用机构数据接入', path: '/electronicCert/orgDataImport', icon: 'el-icon-upload2' },
        { title: '使用机构数据导出', path: '/electronicCert/orgDataExport', icon: 'el-icon-download' },
        { title: '特征密文数据安全交换（批量）', path: '/electronicCert/batchExchange', icon: 'el-icon-sort' },
        { title: '特征密文数据安全交换（实时）', path: '/electronicCert/realTimeExchange', icon: 'el-icon-refresh' },
        { title: '流程执行日志记录', path: '/electronicCert/logRecord', icon: 'el-icon-document' },
        { title: '流程执行日志导出', path: '/electronicCert/logExport', icon: 'el-icon-folder-opened' }
      ]
    }
  },
  methods: {
    go(path) { this.$router.push(path) }
  }
}
</script>

<style lang="scss" scoped>
.scene-app { max-width: 1100px; margin: 0 auto; }
.intro { margin-bottom: 16px; h3 { margin: 0 0 8px; font-size: 20px; } p { color: #5e6d82; line-height: 1.7; } .flow { margin-top: 20px; } }
.entries .entry {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  height: 92px; margin-bottom: 16px; border: 1px solid #ebeef5; border-radius: 8px;
  cursor: pointer; transition: all .2s; text-align: center; padding: 8px;
  i { font-size: 26px; color: #409eff; margin-bottom: 8px; }
  span { font-size: 13px; color: #303133; }
}
.entries .entry:hover { border-color: #409eff; box-shadow: 0 2px 12px rgba(64,158,255,.2); transform: translateY(-2px); }
</style>
