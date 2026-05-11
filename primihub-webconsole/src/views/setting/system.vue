<template>
  <div class="container">
    <el-card class="config-card">
      <div slot="header" class="card-header">
        <span class="card-title"><i class="el-icon-setting" /> 系统配置</span>
        <el-button type="primary" size="small" @click="saveAllConfig">保存所有配置</el-button>
      </div>

      <el-tabs v-model="activeTab" type="border-card">
        <!-- 网络地址设置 -->
        <el-tab-pane label="网络地址设置" name="network">
          <el-form ref="networkForm" :model="networkConfig" :rules="networkRules" label-width="180px">
            <el-divider content-position="left">基础网络配置</el-divider>
            <el-form-item label="平台域名">
              <el-input v-model="networkConfig.platformDomain" placeholder="https://platform.example.com" />
              <div class="form-tip">平台对外访问的主域名</div>
            </el-form-item>
            <el-form-item label="API网关地址">
              <el-input v-model="networkConfig.apiGateway" placeholder="https://api.example.com" />
              <div class="form-tip">API网关地址，用于对外提供接口服务</div>
            </el-form-item>
            <el-form-item label="WebSocket地址">
              <el-input v-model="networkConfig.websocketUrl" placeholder="wss://ws.example.com" />
              <div class="form-tip">WebSocket服务地址，用于实时通信</div>
            </el-form-item>
            <el-form-item label="文件服务器地址">
              <el-input v-model="networkConfig.fileServerUrl" placeholder="https://files.example.com" />
              <div class="form-tip">文件上传下载服务地址</div>
            </el-form-item>

            <el-divider content-position="left">网络代理配置</el-divider>
            <el-form-item label="启用HTTP代理">
              <el-switch v-model="networkConfig.enableProxy" />
            </el-form-item>
            <el-form-item v-if="networkConfig.enableProxy" label="代理服务器地址">
              <el-input v-model="networkConfig.proxyHost" placeholder="proxy.example.com" />
            </el-form-item>
            <el-form-item v-if="networkConfig.enableProxy" label="代理端口">
              <el-input-number v-model="networkConfig.proxyPort" :min="1" :max="65535" />
            </el-form-item>
            <el-form-item v-if="networkConfig.enableProxy" label="代理用户名">
              <el-input v-model="networkConfig.proxyUsername" placeholder="可选" />
            </el-form-item>
            <el-form-item v-if="networkConfig.enableProxy" label="代理密码">
              <el-input v-model="networkConfig.proxyPassword" type="password" show-password placeholder="可选" />
            </el-form-item>

            <el-divider content-position="left">其他网络配置</el-divider>
            <el-form-item label="允许跨域">
              <el-switch v-model="networkConfig.enableCors" />
              <div class="form-tip">是否允许跨域请求</div>
            </el-form-item>
            <el-form-item label="允许的跨域域名">
              <el-input v-model="networkConfig.corsOrigins" type="textarea" :rows="3" placeholder="多个域名用逗号分隔，如：https://example1.com,https://example2.com" />
            </el-form-item>
            <el-form-item label="请求超时时间">
              <el-input-number v-model="networkConfig.requestTimeout" :min="5" :max="300" />
              <span style="margin-left: 10px;">秒</span>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="saveNetworkConfiguration">保存网络配置</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 时间配置 -->
        <el-tab-pane label="时间配置" name="time">
          <el-form :model="timeConfig" label-width="180px">
            <el-divider content-position="left">时区设置</el-divider>
            <el-form-item label="系统时区">
              <el-select v-model="timeConfig.timezone" placeholder="请选择时区" style="width: 100%;">
                <el-option label="北京时间 (UTC+8)" value="Asia/Shanghai" />
                <el-option label="东京时间 (UTC+9)" value="Asia/Tokyo" />
                <el-option label="纽约时间 (UTC-5)" value="America/New_York" />
                <el-option label="伦敦时间 (UTC+0)" value="Europe/London" />
                <el-option label="巴黎时间 (UTC+1)" value="Europe/Paris" />
              </el-select>
              <div class="form-tip">系统默认时区，影响日志和任务调度时间显示</div>
            </el-form-item>
            <el-form-item label="当前服务器时间">
              <el-input v-model="timeConfig.currentTime" :disabled="true" />
            </el-form-item>

            <el-divider content-position="left">时间格式</el-divider>
            <el-form-item label="日期格式">
              <el-select v-model="timeConfig.dateFormat" placeholder="请选择日期格式">
                <el-option label="YYYY-MM-DD" value="YYYY-MM-DD" />
                <el-option label="YYYY/MM/DD" value="YYYY/MM/DD" />
                <el-option label="DD-MM-YYYY" value="DD-MM-YYYY" />
                <el-option label="MM/DD/YYYY" value="MM/DD/YYYY" />
              </el-select>
            </el-form-item>
            <el-form-item label="时间格式">
              <el-select v-model="timeConfig.timeFormat" placeholder="请选择时间格式">
                <el-option label="24小时制 (HH:mm:ss)" value="HH:mm:ss" />
                <el-option label="12小时制 (hh:mm:ss A)" value="hh:mm:ss A" />
              </el-select>
            </el-form-item>

            <el-divider content-position="left">时间同步</el-divider>
            <el-form-item label="启用NTP同步">
              <el-switch v-model="timeConfig.enableNtp" />
              <div class="form-tip">启用后系统将自动与NTP服务器同步时间</div>
            </el-form-item>
            <el-form-item v-if="timeConfig.enableNtp" label="NTP服务器">
              <el-input v-model="timeConfig.ntpServer" placeholder="ntp.aliyun.com" />
            </el-form-item>
            <el-form-item v-if="timeConfig.enableNtp" label="同步间隔">
              <el-input-number v-model="timeConfig.syncInterval" :min="1" :max="24" />
              <span style="margin-left: 10px;">小时</span>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="saveTimeConfiguration">保存时间配置</el-button>
              <el-button v-if="timeConfig.enableNtp" @click="syncTimeNow">立即同步时间</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 登录限制 -->
        <el-tab-pane label="登录限制" name="loginRestriction">
          <el-form :model="loginRestriction" label-width="180px">
            <el-divider content-position="left">首次登录设置</el-divider>
            <el-form-item label="强制首次修改密码">
              <el-switch v-model="loginRestriction.forceChangePasswordOnFirstLogin" />
              <div class="form-tip">用户首次登录时必须修改初始密码</div>
            </el-form-item>
            <el-form-item v-if="loginRestriction.forceChangePasswordOnFirstLogin" label="密码复杂度要求">
              <el-checkbox-group v-model="loginRestriction.passwordComplexity">
                <el-checkbox label="LENGTH">最少8位</el-checkbox>
                <el-checkbox label="UPPERCASE">包含大写字母</el-checkbox>
                <el-checkbox label="LOWERCASE">包含小写字母</el-checkbox>
                <el-checkbox label="NUMBER">包含数字</el-checkbox>
                <el-checkbox label="SPECIAL">包含特殊字符</el-checkbox>
              </el-checkbox-group>
            </el-form-item>

            <el-divider content-position="left">登录错误限制</el-divider>
            <el-form-item label="启用登录失败锁定">
              <el-switch v-model="loginRestriction.enableFailedLock" />
              <div class="form-tip">连续登录失败达到次数后锁定账户</div>
            </el-form-item>
            <el-form-item v-if="loginRestriction.enableFailedLock" label="最大失败次数">
              <el-input-number v-model="loginRestriction.maxFailedAttempts" :min="3" :max="10" />
              <span style="margin-left: 10px;">次</span>
              <div class="form-tip">连续登录失败多少次后锁定账户</div>
            </el-form-item>
            <el-form-item v-if="loginRestriction.enableFailedLock" label="锁定时长">
              <el-input-number v-model="loginRestriction.lockDuration" :min="5" :max="1440" />
              <span style="margin-left: 10px;">分钟</span>
              <div class="form-tip">账户锁定后多久自动解锁</div>
            </el-form-item>
            <el-form-item v-if="loginRestriction.enableFailedLock" label="失败计数重置时间">
              <el-input-number v-model="loginRestriction.failedResetTime" :min="10" :max="120" />
              <span style="margin-left: 10px;">分钟</span>
              <div class="form-tip">登录失败计数在多久后重置</div>
            </el-form-item>

            <el-divider content-position="left">其他登录限制</el-divider>
            <el-form-item label="启用验证码">
              <el-switch v-model="loginRestriction.enableCaptcha" />
              <div class="form-tip">登录时要求输入图形验证码</div>
            </el-form-item>
            <el-form-item label="启用双因素认证">
              <el-switch v-model="loginRestriction.enable2FA" />
              <div class="form-tip">登录时需要短信或邮箱验证码</div>
            </el-form-item>
            <el-form-item label="会话超时时间">
              <el-input-number v-model="loginRestriction.sessionTimeout" :min="30" :max="1440" />
              <span style="margin-left: 10px;">分钟</span>
              <div class="form-tip">用户无操作后自动退出登录的时间</div>
            </el-form-item>
            <el-form-item label="允许同时登录数">
              <el-input-number v-model="loginRestriction.maxConcurrentLogin" :min="1" :max="10" />
              <span style="margin-left: 10px;">个设备</span>
              <div class="form-tip">同一账户允许同时登录的设备数量</div>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="saveLoginRestrictionConfig">保存登录限制配置</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 平台个性化设置 -->
        <el-tab-pane label="平台个性化" name="personalization">
          <el-form :model="personalizationConfig" label-width="180px">
            <el-divider content-position="left">平台基本信息</el-divider>
            <el-form-item label="平台名称">
              <el-input v-model="personalizationConfig.platformName" placeholder="请输入平台名称" />
            </el-form-item>
            <el-form-item label="平台简称">
              <el-input v-model="personalizationConfig.platformShortName" placeholder="请输入平台简称" />
            </el-form-item>
            <el-form-item label="平台描述">
              <el-input v-model="personalizationConfig.platformDescription" type="textarea" :rows="3" placeholder="请输入平台描述" />
            </el-form-item>
            <el-form-item label="版权信息">
              <el-input v-model="personalizationConfig.copyright" placeholder="Copyright © 2026 YourCompany. All rights reserved." />
            </el-form-item>
            <el-form-item label="ICP备案号">
              <el-input v-model="personalizationConfig.icpNumber" placeholder="京ICP备12345678号" />
            </el-form-item>

            <el-divider content-position="left">主题配置</el-divider>
            <el-form-item label="主题色">
              <el-color-picker v-model="personalizationConfig.themeColor" />
              <span style="margin-left: 10px;">{{ personalizationConfig.themeColor }}</span>
            </el-form-item>
            <el-form-item label="侧边栏主题">
              <el-radio-group v-model="personalizationConfig.sidebarTheme">
                <el-radio label="dark">深色</el-radio>
                <el-radio label="light">浅色</el-radio>
              </el-radio-group>
            </el-form-item>
            <el-form-item label="默认语言">
              <el-select v-model="personalizationConfig.defaultLanguage">
                <el-option label="简体中文" value="zh_CN" />
                <el-option label="English" value="en_US" />
              </el-select>
            </el-form-item>

            <el-divider content-position="left">功能开关</el-divider>
            <el-form-item label="启用用户注册">
              <el-switch v-model="personalizationConfig.enableRegister" />
              <div class="form-tip">是否允许用户自主注册</div>
            </el-form-item>
            <el-form-item label="启用找回密码">
              <el-switch v-model="personalizationConfig.enableForgotPassword" />
              <div class="form-tip">是否允许用户通过邮箱找回密码</div>
            </el-form-item>
            <el-form-item label="启用用户反馈">
              <el-switch v-model="personalizationConfig.enableFeedback" />
            </el-form-item>
            <el-form-item label="启用操作日志">
              <el-switch v-model="personalizationConfig.enableOperationLog" />
              <div class="form-tip">记录用户的所有操作行为</div>
            </el-form-item>

            <el-divider content-position="left">页面配置</el-divider>
            <el-form-item label="每页显示数量">
              <el-select v-model="personalizationConfig.defaultPageSize">
                <el-option :label="10" :value="10" />
                <el-option :label="20" :value="20" />
                <el-option :label="50" :value="50" />
                <el-option :label="100" :value="100" />
              </el-select>
            </el-form-item>
            <el-form-item label="表格固定表头">
              <el-switch v-model="personalizationConfig.tableFixedHeader" />
            </el-form-item>
            <el-form-item label="数据自动刷新">
              <el-switch v-model="personalizationConfig.autoRefresh" />
            </el-form-item>
            <el-form-item v-if="personalizationConfig.autoRefresh" label="刷新间隔">
              <el-input-number v-model="personalizationConfig.refreshInterval" :min="10" :max="300" />
              <span style="margin-left: 10px;">秒</span>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="savePersonalizationConfiguration">保存个性化配置</el-button>
              <el-button @click="resetPersonalization">恢复默认</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 平台FTP设置 -->
        <el-tab-pane label="FTP设置" name="ftp">
          <el-form :model="ftpConfig" label-width="180px">
            <el-alert
              title="FTP配置说明"
              type="info"
              description="FTP用于文件上传、下载和同步。配置前请确保FTP服务器已正确部署并可访问。"
              :closable="false"
              style="margin-bottom: 20px;"
            />

            <el-divider content-position="left">FTP服务器配置</el-divider>
            <el-form-item label="启用FTP">
              <el-switch v-model="ftpConfig.enableFtp" />
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="FTP服务器地址">
              <el-input v-model="ftpConfig.ftpHost" placeholder="ftp.example.com" />
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="FTP端口">
              <el-input-number v-model="ftpConfig.ftpPort" :min="1" :max="65535" />
              <span style="margin-left: 10px;">默认：21</span>
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="FTP用户名">
              <el-input v-model="ftpConfig.ftpUsername" placeholder="请输入FTP用户名" />
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="FTP密码">
              <el-input v-model="ftpConfig.ftpPassword" type="password" show-password placeholder="请输入FTP密码" />
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="FTP模式">
              <el-radio-group v-model="ftpConfig.ftpMode">
                <el-radio label="ACTIVE">主动模式</el-radio>
                <el-radio label="PASSIVE">被动模式</el-radio>
              </el-radio-group>
            </el-form-item>

            <el-divider content-position="left">FTP路径配置</el-divider>
            <el-form-item v-if="ftpConfig.enableFtp" label="根目录">
              <el-input v-model="ftpConfig.ftpRootPath" placeholder="/data" />
              <div class="form-tip">FTP服务器上的根目录路径</div>
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="上传目录">
              <el-input v-model="ftpConfig.ftpUploadPath" placeholder="/upload" />
              <div class="form-tip">文件上传的默认目录</div>
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="下载目录">
              <el-input v-model="ftpConfig.ftpDownloadPath" placeholder="/download" />
              <div class="form-tip">文件下载的默认目录</div>
            </el-form-item>

            <el-divider content-position="left">高级配置</el-divider>
            <el-form-item v-if="ftpConfig.enableFtp" label="启用SSL/TLS">
              <el-switch v-model="ftpConfig.enableFtps" />
              <div class="form-tip">使用FTPS加密传输</div>
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="连接超时时间">
              <el-input-number v-model="ftpConfig.ftpTimeout" :min="5" :max="60" />
              <span style="margin-left: 10px;">秒</span>
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="最大连接数">
              <el-input-number v-model="ftpConfig.ftpMaxConnections" :min="1" :max="100" />
            </el-form-item>
            <el-form-item v-if="ftpConfig.enableFtp" label="文件传输编码">
              <el-select v-model="ftpConfig.ftpEncoding">
                <el-option label="UTF-8" value="UTF-8" />
                <el-option label="GBK" value="GBK" />
                <el-option label="ISO-8859-1" value="ISO-8859-1" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="saveFtpConfiguration">保存FTP配置</el-button>
              <el-button v-if="ftpConfig.enableFtp" :loading="testingFtp" @click="testFtpConn">测试连接</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script>
import {
  getNetworkConfig,
  saveNetworkConfig,
  getTimeConfig,
  saveTimeConfig,
  getLoginRestriction,
  saveLoginRestriction,
  getPersonalizationConfig,
  savePersonalizationConfig,
  getFtpConfig,
  saveFtpConfig,
  testFtpConnection
} from '@/api/systemConfig'

export default {
  name: 'SystemConfig',
  data() {
    return {
      activeTab: 'network',
      networkRules: {
        platformDomain: [{ pattern: /^https?:\/\/.+/, message: '请输入正确URL，以 http:// 或 https:// 开头', trigger: 'blur' }],
        apiGateway: [{ pattern: /^https?:\/\/.+/, message: '请输入正确URL', trigger: 'blur' }],
        websocketUrl: [{ pattern: /^wss?:\/\/.+/, message: '请输入正确WebSocket地址，以 ws:// 或 wss:// 开头', trigger: 'blur' }],
        fileServerUrl: [{ pattern: /^https?:\/\/.+/, message: '请输入正确URL', trigger: 'blur' }]
      },
      networkConfig: {
        platformDomain: '',
        apiGateway: '',
        websocketUrl: '',
        fileServerUrl: '',
        enableProxy: false,
        proxyHost: '',
        proxyPort: 8080,
        proxyUsername: '',
        proxyPassword: '',
        enableCors: false,
        corsOrigins: '',
        requestTimeout: 30
      },
      timeConfig: {
        timezone: 'Asia/Shanghai',
        currentTime: '',
        dateFormat: 'YYYY-MM-DD',
        timeFormat: 'HH:mm:ss',
        enableNtp: false,
        ntpServer: 'ntp.aliyun.com',
        syncInterval: 6
      },
      loginRestriction: {
        forceChangePasswordOnFirstLogin: false,
        passwordComplexity: ['LENGTH', 'UPPERCASE', 'NUMBER'],
        enableFailedLock: true,
        maxFailedAttempts: 5,
        lockDuration: 30,
        failedResetTime: 30,
        enableCaptcha: true,
        enable2FA: false,
        sessionTimeout: 120,
        maxConcurrentLogin: 3
      },
      personalizationConfig: {
        platformName: 'DataItem隐私计算平台',
        platformShortName: 'DataItem',
        platformDescription: '基于隐私保护的分布式计算平台',
        copyright: 'Copyright © 2026 海会科技. All rights reserved.',
        icpNumber: '',
        themeColor: '#409EFF',
        sidebarTheme: 'dark',
        defaultLanguage: 'zh_CN',
        enableRegister: true,
        enableForgotPassword: true,
        enableFeedback: true,
        enableOperationLog: true,
        defaultPageSize: 10,
        tableFixedHeader: true,
        autoRefresh: false,
        refreshInterval: 30
      },
      ftpConfig: {
        enableFtp: false,
        ftpHost: '',
        ftpPort: 21,
        ftpUsername: '',
        ftpPassword: '',
        ftpMode: 'PASSIVE',
        ftpRootPath: '/data',
        ftpUploadPath: '/upload',
        ftpDownloadPath: '/download',
        enableFtps: false,
        ftpTimeout: 30,
        ftpMaxConnections: 10,
        ftpEncoding: 'UTF-8'
      },
      testingFtp: false
    }
  },
  created() {
    this.fetchAllConfig()
    this.updateCurrentTime()
    setInterval(this.updateCurrentTime, 1000)
  },
  methods: {
    async fetchAllConfig() {
      // TODO: 调用实际接口获取所有配置
      await this.fetchNetworkConfig()
      await this.fetchTimeConfig()
      await this.fetchLoginRestrictionConfig()
      await this.fetchPersonalizationConfig()
      await this.fetchFtpConfig()
    },
    async fetchNetworkConfig() {
      const res = await getNetworkConfig()
      if (res && res.code === 0) {
        this.networkConfig = { ...this.networkConfig, ...res.result }
      }
    },
    async fetchTimeConfig() {
      const res = await getTimeConfig()
      if (res && res.code === 0) {
        this.timeConfig = { ...this.timeConfig, ...res.result }
      }
    },
    async fetchLoginRestrictionConfig() {
      const res = await getLoginRestriction()
      if (res && res.code === 0) {
        this.loginRestriction = { ...this.loginRestriction, ...res.result }
      }
    },
    async fetchPersonalizationConfig() {
      const res = await getPersonalizationConfig()
      if (res && res.code === 0) {
        this.personalizationConfig = { ...this.personalizationConfig, ...res.result }
      }
    },
    async fetchFtpConfig() {
      const res = await getFtpConfig()
      if (res && res.code === 0) {
        this.ftpConfig = { ...this.ftpConfig, ...res.result }
      }
    },
    async saveNetworkConfiguration() {
      // TODO: 调用实际接口保存配置
      const res = await saveNetworkConfig(this.networkConfig)
      if (res && res.code === 0) {
        this.$message.success('网络配置保存成功')
      }
    },
    async saveTimeConfiguration() {
      // TODO: 调用实际接口保存配置
      const res = await saveTimeConfig(this.timeConfig)
      if (res && res.code === 0) {
        this.$message.success('时间配置保存成功')
      }
    },
    async saveLoginRestrictionConfig() {
      // TODO: 调用实际接口保存配置
      const res = await saveLoginRestriction(this.loginRestriction)
      if (res && res.code === 0) {
        this.$message.success('登录限制配置保存成功')
      }
    },
    async savePersonalizationConfiguration() {
      // TODO: 调用实际接口保存配置
      const res = await savePersonalizationConfig(this.personalizationConfig)
      if (res && res.code === 0) {
        this.$message.success('个性化配置保存成功')
      }
    },
    async saveFtpConfiguration() {
      // TODO: 调用实际接口保存配置
      const res = await saveFtpConfig(this.ftpConfig)
      if (res && res.code === 0) {
        this.$message.success('FTP配置保存成功')
      }
    },
    async saveAllConfig() {
      // TODO: 保存所有配置
      await this.saveNetworkConfiguration()
      await this.saveTimeConfiguration()
      await this.saveLoginRestrictionConfig()
      await this.savePersonalizationConfiguration()
      await this.saveFtpConfiguration()
      this.$message.success('所有配置保存成功')
    },
    syncTimeNow() {
      // TODO: 调用实际接口立即同步时间
      this.$message.success('时间同步请求已发送')
    },
    resetPersonalization() {
      this.$confirm('确定要恢复默认个性化配置吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        // TODO: 恢复默认配置
        this.$message.success('已恢复默认配置')
      })
    },
    async testFtpConn() {
      this.testingFtp = true
      // TODO: 调用实际接口测试FTP连接
      const res = await testFtpConnection(this.ftpConfig)
      this.testingFtp = false
      if (res && res.code === 0) {
        this.$message.success('FTP连接测试成功')
      } else {
        this.$message.error('FTP连接测试失败：' + (res?.message || '未知错误'))
      }
    },
    updateCurrentTime() {
      const now = new Date()
      this.timeConfig.currentTime = now.toLocaleString('zh-CN', { hour12: false })
    }
  }
}
</script>

<style lang="scss" scoped>
.container {
  padding: 20px;
  background-color: #f0f2f5;
}

.config-card {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    .card-title {
      font-size: 16px;
      font-weight: bold;
      i {
        margin-right: 8px;
      }
    }
  }
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 5px;
}

::v-deep .el-tabs--border-card {
  border: none;
  box-shadow: none;
}

::v-deep .el-divider__text {
  font-size: 14px;
  font-weight: bold;
  color: #303133;
}
</style>
