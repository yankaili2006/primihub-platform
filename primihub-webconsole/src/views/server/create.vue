<template>
  <div class="app-container">
    <el-card>
      <div slot="header">{{ isEdit ? '编辑服务器' : '新增服务器' }}</div>
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" style="max-width: 640px;">
        <el-form-item label="服务器名称" prop="serverName">
          <el-input v-model="form.serverName" placeholder="请输入服务器名称" />
        </el-form-item>
        <el-form-item label="描述" prop="serverDesc">
          <el-input v-model="form.serverDesc" type="textarea" :rows="2" placeholder="可选" />
        </el-form-item>
        <el-form-item label="IP 地址" prop="serverIp">
          <el-input v-model="form.serverIp" placeholder="如 100.64.0.50" />
        </el-form-item>
        <el-form-item label="端口" prop="serverPort">
          <el-input-number v-model="form.serverPort" :min="1" :max="65535" controls-position="right" />
        </el-form-item>
        <el-form-item label="类型" prop="serverType">
          <el-select v-model="form.serverType" placeholder="请选择">
            <el-option label="计算(compute)" value="compute" />
            <el-option label="存储(storage)" value="storage" />
            <el-option label="网关(gateway)" value="gateway" />
            <el-option label="TEE" value="tee" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态" prop="serverStatus">
          <el-select v-model="form.serverStatus" placeholder="请选择">
            <el-option label="离线" :value="0" />
            <el-option label="在线" :value="1" />
            <el-option label="维护中" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="CPU 核数">
          <el-input-number v-model="form.cpuCores" :min="0" :step="1" controls-position="right" />
        </el-form-item>
        <el-form-item label="内存 (GB)">
          <el-input-number v-model="form.memoryGb" :min="0" :step="1" controls-position="right" />
        </el-form-item>
        <el-form-item label="存储 (GB)">
          <el-input-number v-model="form.storageGb" :min="0" :step="1" controls-position="right" />
        </el-form-item>
        <el-form-item label="配置(JSON)">
          <el-input v-model="form.config" type="textarea" :rows="3" placeholder='可选，如 {"gpu":1}' />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="saving" @click="handleSubmit">保存</el-button>
          <el-button @click="$router.back()">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { addServer, updateServer, getServerDetail } from '@/api/server'

export default {
  name: 'ServerCreate',
  data() {
    return {
      saving: false,
      form: {
        serverId: undefined,
        serverName: '',
        serverDesc: '',
        serverIp: '',
        serverPort: 22,
        serverType: 'compute',
        serverStatus: 1,
        cpuCores: undefined,
        memoryGb: undefined,
        storageGb: undefined,
        config: ''
      },
      rules: {
        serverName: [{ required: true, message: '请输入服务器名称', trigger: 'blur' }],
        serverIp: [{ required: true, message: '请输入 IP 地址', trigger: 'blur' }],
        serverType: [{ required: true, message: '请选择类型', trigger: 'change' }],
        serverStatus: [{ required: true, message: '请选择状态', trigger: 'change' }]
      }
    }
  },
  computed: {
    isEdit() {
      return !!this.form.serverId
    }
  },
  created() {
    const id = this.$route.query.serverId
    if (id) {
      getServerDetail(id).then(res => {
        const d = res.result || {}
        Object.keys(this.form).forEach(k => {
          if (d[k] !== undefined && d[k] !== null) this.form[k] = d[k]
        })
        this.form.serverId = Number(id)
      })
    }
  },
  methods: {
    handleSubmit() {
      this.$refs.form.validate(valid => {
        if (!valid) return
        this.saving = true
        const req = this.isEdit ? updateServer : addServer
        req(this.form)
          .then(() => {
            this.$message.success(this.isEdit ? '更新成功' : '创建成功')
            this.$router.push({ name: 'ServerList' })
          })
          .finally(() => {
            this.saving = false
          })
      })
    }
  }
}
</script>
