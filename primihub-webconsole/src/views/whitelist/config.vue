<template>
  <div class="container">
    <el-card class="config-card">
      <div slot="header" class="card-header">
        <span>白名单配置</span>
        <el-button v-if="hasEditPermission" type="primary" size="small" @click="handleSave">保存配置</el-button>
      </div>
      <el-form ref="configForm" :model="configForm" label-width="180px" :rules="rules">
        <el-form-item label="启用白名单功能" prop="enableWhitelist">
          <el-switch
            v-model="configForm.enableWhitelist"
            active-text="启用"
            inactive-text="禁用"
          />
          <div class="form-tip">启用后，只有白名单中的IP/域名/用户才能访问系统</div>
        </el-form-item>

        <el-form-item label="默认策略" prop="defaultPolicy">
          <el-radio-group v-model="configForm.defaultPolicy">
            <el-radio label="ALLOW">允许</el-radio>
            <el-radio label="DENY">拒绝</el-radio>
          </el-radio-group>
          <div class="form-tip">当未匹配到白名单规则时的默认行为</div>
        </el-form-item>

        <el-form-item label="记录访问日志" prop="enableAccessLog">
          <el-switch
            v-model="configForm.enableAccessLog"
            active-text="启用"
            inactive-text="禁用"
          />
          <div class="form-tip">启用后，将记录所有访问尝试的日志</div>
        </el-form-item>

        <el-form-item label="日志保留天数" prop="logRetentionDays">
          <el-input-number
            v-model="configForm.logRetentionDays"
            :min="1"
            :max="365"
            label="日志保留天数"
          />
          <span style="margin-left: 10px;">天</span>
          <div class="form-tip">访问日志的保留时间，超过该时间的日志将被自动清理</div>
        </el-form-item>

        <el-form-item label="IP匹配模式" prop="ipMatchMode">
          <el-radio-group v-model="configForm.ipMatchMode">
            <el-radio label="EXACT">精确匹配</el-radio>
            <el-radio label="CIDR">CIDR匹配</el-radio>
            <el-radio label="RANGE">范围匹配</el-radio>
          </el-radio-group>
          <div class="form-tip">
            精确匹配：完全匹配IP地址<br>
            CIDR匹配：支持CIDR表示法（如192.168.1.0/24）<br>
            范围匹配：支持IP范围（如192.168.1.1-192.168.1.255）
          </div>
        </el-form-item>

        <el-form-item label="最大失败尝试次数" prop="maxFailedAttempts">
          <el-input-number
            v-model="configForm.maxFailedAttempts"
            :min="0"
            :max="100"
            label="最大失败尝试次数"
          />
          <span style="margin-left: 10px;">次</span>
          <div class="form-tip">超过此次数后将触发告警，0表示不限制</div>
        </el-form-item>

        <el-form-item label="锁定时长" prop="lockDuration">
          <el-input-number
            v-model="configForm.lockDuration"
            :min="0"
            :max="1440"
            label="锁定时长"
          />
          <span style="margin-left: 10px;">分钟</span>
          <div class="form-tip">失败尝试次数超过上限后的锁定时长，0表示不锁定</div>
        </el-form-item>

        <el-form-item label="告警通知" prop="enableAlert">
          <el-switch
            v-model="configForm.enableAlert"
            active-text="启用"
            inactive-text="禁用"
          />
          <div class="form-tip">启用后，当检测到异常访问时将发送告警通知</div>
        </el-form-item>

        <el-form-item v-if="configForm.enableAlert" label="告警邮箱" prop="alertEmails">
          <el-input
            v-model="configForm.alertEmails"
            type="textarea"
            :rows="3"
            placeholder="请输入告警邮箱，多个邮箱用逗号分隔"
          />
        </el-form-item>

        <el-form-item label="白名单缓存时间" prop="cacheTime">
          <el-input-number
            v-model="configForm.cacheTime"
            :min="0"
            :max="3600"
            label="缓存时间"
          />
          <span style="margin-left: 10px;">秒</span>
          <div class="form-tip">白名单规则的缓存时间，0表示不缓存</div>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="config-card" style="margin-top: 20px;">
      <div slot="header" class="card-header">
        <span>配置历史</span>
      </div>
      <el-table :data="historyList" class="history-table">
        <el-table-column align="center" label="配置项" prop="configKey" width="200" />
        <el-table-column align="left" label="配置值" prop="configValue" />
        <el-table-column align="center" label="修改时间" prop="updateTime" width="180" />
        <el-table-column align="center" label="修改人" prop="updateUser" width="120" />
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getWhitelistConfigList, saveWhitelistConfig } from '@/api/whitelist'
import { mapGetters } from 'vuex'

export default {
  name: 'WhitelistConfig',
  data() {
    return {
      configForm: {
        enableWhitelist: false,
        defaultPolicy: 'DENY',
        enableAccessLog: true,
        logRetentionDays: 30,
        ipMatchMode: 'EXACT',
        maxFailedAttempts: 5,
        lockDuration: 30,
        enableAlert: false,
        alertEmails: '',
        cacheTime: 300
      },
      historyList: [],
      rules: {
        logRetentionDays: [
          { required: true, message: '请输入日志保留天数', trigger: 'blur' }
        ],
        maxFailedAttempts: [
          { required: true, message: '请输入最大失败尝试次数', trigger: 'blur' }
        ],
        lockDuration: [
          { required: true, message: '请输入锁定时长', trigger: 'blur' }
        ],
        alertEmails: [
          { pattern: /^(\w+@\w+\.\w+)(,\w+@\w+\.\w+)*$/, message: '请输入正确的邮箱格式', trigger: 'blur' }
        ]
      }
    }
  },
  computed: {
    hasEditPermission() {
      return this.buttonPermissionList.includes('WhitelistConfigEdit')
    },
    ...mapGetters([
      'buttonPermissionList'
    ])
  },
  created() {
    this.fetchData()
  },
  methods: {
    async fetchData() {
      try {
        const res = await getWhitelistConfigList()
        if (res.code === 0) {
          const configList = res.result?.configList || []
          const historyList = res.result?.historyList || []

          // 将配置列表转换为表单数据
          configList.forEach(item => {
            const key = item.configKey
            let value = item.configValue

            // 根据类型转换值
            if (key.startsWith('enable')) {
              value = value === 'true' || value === true
            } else if (['logRetentionDays', 'maxFailedAttempts', 'lockDuration', 'cacheTime'].includes(key)) {
              value = parseInt(value) || 0
            }

            if (this.configForm.hasOwnProperty(key)) {
              this.configForm[key] = value
            }
          })

          this.historyList = historyList
        }
      } catch (error) {
        console.error('获取配置失败:', error)
      }
    },
    async handleSave() {
      this.$refs['configForm'].validate(async valid => {
        if (valid) {
          try {
            // 将配置表单转换为配置列表
            const configList = Object.keys(this.configForm).map(key => ({
              configKey: key,
              configValue: String(this.configForm[key]),
              configType: typeof this.configForm[key]
            }))

            const res = await saveWhitelistConfig({ configList })
            if (res.code === 0) {
              this.$message({
                type: 'success',
                message: '保存成功'
              })
              this.fetchData()
            }
          } catch (error) {
            console.error('保存配置失败:', error)
          }
        }
      })
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
    font-weight: bold;
  }
}
.form-tip {
  font-size: 12px;
  color: #909399;
  line-height: 1.5;
  margin-top: 5px;
}
.history-table {
  width: 100%;
}
::v-deep .el-table th{
  background: #fafafa;
}
</style>
