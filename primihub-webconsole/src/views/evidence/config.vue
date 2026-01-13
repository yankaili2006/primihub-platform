<template>
  <div class="container">
    <el-card class="config-card">
      <div slot="header" class="card-header">
        <span class="card-title"><i class="el-icon-setting" /> 存证配置</span>
        <el-button type="primary" size="small" @click="saveConfig">保存配置</el-button>
      </div>

      <el-tabs v-model="activeTab" type="border-card">
        <!-- 区块链配置 -->
        <el-tab-pane label="区块链配置" name="blockchain">
          <el-form :model="configForm" label-width="150px">
            <el-divider content-position="left">以太坊配置</el-divider>
            <el-form-item label="启用以太坊">
              <el-switch v-model="configForm.ethereumEnabled" />
            </el-form-item>
            <el-form-item label="节点URL">
              <el-input v-model="configForm.ethereumUrl" placeholder="https://mainnet.infura.io/v3/YOUR-PROJECT-ID" />
            </el-form-item>
            <el-form-item label="合约地址">
              <el-input v-model="configForm.ethereumContract" placeholder="0x..." />
            </el-form-item>
            <el-form-item label="私钥">
              <el-input v-model="configForm.ethereumPrivateKey" type="password" show-password placeholder="0x..." />
            </el-form-item>

            <el-divider content-position="left">Fabric配置</el-divider>
            <el-form-item label="启用Fabric">
              <el-switch v-model="configForm.fabricEnabled" />
            </el-form-item>
            <el-form-item label="通道名称">
              <el-input v-model="configForm.fabricChannel" placeholder="mychannel" />
            </el-form-item>
            <el-form-item label="链码名称">
              <el-input v-model="configForm.fabricChaincode" placeholder="evidence" />
            </el-form-item>

            <el-divider content-position="left">FISCO BCOS配置</el-divider>
            <el-form-item label="启用FISCO">
              <el-switch v-model="configForm.fiscoEnabled" />
            </el-form-item>
            <el-form-item label="节点IP">
              <el-input v-model="configForm.fiscoNodeIp" placeholder="127.0.0.1:20200" />
            </el-form-item>
            <el-form-item label="群组ID">
              <el-input-number v-model="configForm.fiscoGroupId" :min="1" />
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 存证策略 -->
        <el-tab-pane label="存证策略" name="policy">
          <el-form :model="configForm" label-width="180px">
            <el-form-item label="自动上链">
              <el-switch v-model="configForm.autoUpload" active-text="启用" inactive-text="禁用" />
              <div class="form-tip">启用后，存证将自动上传到区块链</div>
            </el-form-item>
            <el-form-item label="默认区块链">
              <el-select v-model="configForm.defaultChain" placeholder="请选择">
                <el-option label="以太坊" value="ETHEREUM" />
                <el-option label="Fabric" value="FABRIC" />
                <el-option label="FISCO BCOS" value="FISCO" />
                <el-option label="本地链" value="LOCAL" />
              </el-select>
            </el-form-item>
            <el-form-item label="存证保留期限">
              <el-input-number v-model="configForm.retentionDays" :min="30" :max="3650" />
              <span style="margin-left: 10px;">天</span>
              <div class="form-tip">存证数据的保留时间，超过后将被归档</div>
            </el-form-item>
            <el-form-item label="启用加密存储">
              <el-switch v-model="configForm.encryptionEnabled" />
              <div class="form-tip">对存证数据进行加密存储</div>
            </el-form-item>
            <el-form-item label="哈希算法">
              <el-select v-model="configForm.hashAlgorithm">
                <el-option label="SHA-256" value="SHA256" />
                <el-option label="SHA-512" value="SHA512" />
                <el-option label="SM3" value="SM3" />
              </el-select>
            </el-form-item>
            <el-form-item label="Gas费用上限">
              <el-input-number v-model="configForm.maxGasLimit" :min="21000" :step="10000" />
              <div class="form-tip">以太坊交易的最大Gas限制</div>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 时间戳配置 -->
        <el-tab-pane label="时间戳配置" name="timestamp">
          <el-form :model="configForm" label-width="180px">
            <el-form-item label="默认TSA服务器">
              <el-input v-model="configForm.defaultTsaServer" placeholder="http://timestamp.server.com" />
            </el-form-item>
            <el-form-item label="备用TSA服务器">
              <el-input v-model="configForm.backupTsaServer" placeholder="http://backup.timestamp.server.com" />
            </el-form-item>
            <el-form-item label="TSA超时时间">
              <el-input-number v-model="configForm.tsaTimeout" :min="5" :max="60" />
              <span style="margin-left: 10px;">秒</span>
            </el-form-item>
            <el-form-item label="自动申请时间戳">
              <el-switch v-model="configForm.autoTimestamp" />
              <div class="form-tip">存证时自动申请时间戳</div>
            </el-form-item>
            <el-form-item label="时间戳策略OID">
              <el-input v-model="configForm.timestampPolicyOid" placeholder="1.2.3.4.5" />
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 通知配置 -->
        <el-tab-pane label="通知配置" name="notification">
          <el-form :model="configForm" label-width="180px">
            <el-form-item label="启用邮件通知">
              <el-switch v-model="configForm.emailNotification" />
            </el-form-item>
            <el-form-item label="通知邮箱">
              <el-input v-model="configForm.notificationEmails" type="textarea" :rows="3" placeholder="多个邮箱用逗号分隔" />
            </el-form-item>
            <el-form-item label="通知事件">
              <el-checkbox-group v-model="configForm.notificationEvents">
                <el-checkbox label="UPLOAD">存证上链</el-checkbox>
                <el-checkbox label="VERIFY">验证成功</el-checkbox>
                <el-checkbox label="FAILED">操作失败</el-checkbox>
                <el-checkbox label="EXPIRE">即将过期</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
          </el-form>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script>
import { getEvidenceConfig, saveEvidenceConfig } from '@/api/evidence'

export default {
  name: 'EvidenceConfig',
  data() {
    return {
      activeTab: 'blockchain',
      configForm: {
        // 区块链配置
        ethereumEnabled: false,
        ethereumUrl: '',
        ethereumContract: '',
        ethereumPrivateKey: '',
        fabricEnabled: false,
        fabricChannel: 'mychannel',
        fabricChaincode: 'evidence',
        fiscoEnabled: false,
        fiscoNodeIp: '',
        fiscoGroupId: 1,
        // 存证策略
        autoUpload: true,
        defaultChain: 'LOCAL',
        retentionDays: 365,
        encryptionEnabled: true,
        hashAlgorithm: 'SHA256',
        maxGasLimit: 100000,
        // 时间戳配置
        defaultTsaServer: '',
        backupTsaServer: '',
        tsaTimeout: 30,
        autoTimestamp: false,
        timestampPolicyOid: '',
        // 通知配置
        emailNotification: false,
        notificationEmails: '',
        notificationEvents: []
      }
    }
  },
  created() {
    this.fetchConfig()
  },
  methods: {
    async fetchConfig() {
      const res = await getEvidenceConfig()
      if (res.code === 0) {
        this.configForm = { ...this.configForm, ...res.result }
      }
    },
    async saveConfig() {
      const res = await saveEvidenceConfig(this.configForm)
      if (res.code === 0) {
        this.$message.success('配置保存成功')
      }
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
      i { margin-right: 8px; }
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
</style>
