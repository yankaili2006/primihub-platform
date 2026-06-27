<template>
  <div class="scene-app">
    <el-card shadow="never" class="intro">
      <h3>警务数据融合应用</h3>
      <p>面向公安与保险机构的数据协同场景，基于隐私计算实现警务数据与保险机构数据的安全交集融合、同态加密建模与密文联合运算，全过程数据不出域、可用不可见。</p>
      <el-steps :active="5" align-center finish-status="success" class="flow">
        <el-step title="数据交集融合" />
        <el-step title="接口对接 / 密钥创建" />
        <el-step title="模型同态加密" />
        <el-step title="加密联合运算" />
        <el-step title="数据解密 / 日志" />
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
  name: 'PoliceDataFusion',
  data() {
    return {
      features: [
        { title: '警务数据交集数据融合', path: '/policeDataFusion/intersection', icon: 'el-icon-connection' },
        { title: '保险机构接口对接', path: '/policeDataFusion/insuranceApi', icon: 'el-icon-link' },
        { title: '保险机构同态密钥创建', path: '/policeDataFusion/homomorphicKey', icon: 'el-icon-key' },
        { title: '保险机构模型同态加密', path: '/policeDataFusion/modelEncrypt', icon: 'el-icon-lock' },
        { title: '加密模型联合运算', path: '/policeDataFusion/encryptedCompute', icon: 'el-icon-cpu' },
        { title: '保险机构数据解密', path: '/policeDataFusion/dataDecrypt', icon: 'el-icon-unlock' },
        { title: '警务数据对接', path: '/policeDataFusion/policeConnect', icon: 'el-icon-office-building' },
        { title: '模型密文数据安全交换（批量）', path: '/policeDataFusion/batchExchange', icon: 'el-icon-sort' },
        { title: '流程执行日志记录', path: '/policeDataFusion/logRecord', icon: 'el-icon-document' },
        { title: '流程执行日志导出', path: '/policeDataFusion/logExport', icon: 'el-icon-download' }
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
