<template>
  <div class="container">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="8">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper primary">
              <i class="el-icon-time" />
            </div>
            <div class="stats-info">
              <div class="stats-label">总时间戳数</div>
              <div class="stats-value">{{ statistics.totalTimestamps || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper success">
              <i class="el-icon-circle-check" />
            </div>
            <div class="stats-info">
              <div class="stats-label">验证有效</div>
              <div class="stats-value">{{ statistics.validTimestamps || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper warning">
              <i class="el-icon-date" />
            </div>
            <div class="stats-info">
              <div class="stats-label">今日申请</div>
              <div class="stats-value">{{ statistics.todayApply || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 操作按钮区 -->
    <div class="action-bar">
      <el-button type="primary" icon="el-icon-plus" @click="openApplyDialog">申请时间戳</el-button>
      <el-button type="success" icon="el-icon-upload2" @click="openVerifyDialog">验证时间戳</el-button>
      <el-button type="info" icon="el-icon-download" @click="batchDownload">批量下载</el-button>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card" shadow="never">
      <div class="filter-bar">
        <el-input
          v-model="searchForm.keyword"
          placeholder="时间戳ID/哈希值/文件名"
          style="width: 250px; margin-right: 10px;"
          clearable
          @clear="handleSearch"
        />
        <el-select
          v-model="searchForm.timestampType"
          placeholder="时间戳类型"
          style="width: 150px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="RFC3161" value="RFC3161" />
          <el-option label="区块链" value="BLOCKCHAIN" />
          <el-option label="可信" value="TRUSTED" />
        </el-select>
        <el-select
          v-model="searchForm.status"
          placeholder="状态"
          style="width: 120px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="有效" value="VALID" />
          <el-option label="已过期" value="EXPIRED" />
          <el-option label="已撤销" value="REVOKED" />
        </el-select>
        <el-date-picker
          v-model="dateRange"
          type="datetimerange"
          range-separator="至"
          start-placeholder="开始时间"
          end-placeholder="结束时间"
          style="width: 380px; margin-right: 10px;"
          value-format="yyyy-MM-dd HH:mm:ss"
          @change="handleSearch"
        />
        <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
        <el-button icon="el-icon-refresh" @click="handleReset">重置</el-button>
      </div>
    </el-card>

    <!-- 时间戳列表 -->
    <el-card class="table-card" shadow="never">
      <div slot="header" class="card-header">
        <span class="card-title"><i class="el-icon-time" /> 时间戳列表</span>
      </div>

      <el-table
        v-loading="loading"
        :data="list"
        class="timestamp-table"
        stripe
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column align="center" label="序号" width="70" type="index" />
        <el-table-column align="left" label="时间戳ID" prop="timestampId" width="180">
          <template slot-scope="scope">
            <el-link type="primary" @click="viewDetail(scope.row)">{{ scope.row.timestampId }}</el-link>
          </template>
        </el-table-column>
        <el-table-column align="left" label="文件名/数据" prop="fileName" min-width="200" show-overflow-tooltip />
        <el-table-column align="left" label="数据哈希" prop="dataHash" width="200" show-overflow-tooltip>
          <template slot-scope="scope">
            <span class="hash-text">{{ scope.row.dataHash }}</span>
          </template>
        </el-table-column>
        <el-table-column align="center" label="时间戳类型" prop="timestampType" width="120">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.timestampType === 'RFC3161'" type="primary" size="small">RFC3161</el-tag>
            <el-tag v-else-if="scope.row.timestampType === 'BLOCKCHAIN'" type="success" size="small">区块链</el-tag>
            <el-tag v-else-if="scope.row.timestampType === 'TRUSTED'" type="warning" size="small">可信</el-tag>
            <el-tag v-else size="small">{{ scope.row.timestampType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="时间戳服务" prop="tsaServer" width="150" show-overflow-tooltip />
        <el-table-column align="center" label="状态" prop="status" width="100">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.status === 'VALID'" type="success" size="small">有效</el-tag>
            <el-tag v-else-if="scope.row.status === 'EXPIRED'" type="info" size="small">已过期</el-tag>
            <el-tag v-else-if="scope.row.status === 'REVOKED'" type="danger" size="small">已撤销</el-tag>
            <el-tag v-else size="small">{{ scope.row.status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="申请时间" prop="createTime" width="180" />
        <el-table-column align="center" label="操作" fixed="right" width="200">
          <template slot-scope="scope">
            <el-button type="text" size="small" @click="viewDetail(scope.row)"><i class="el-icon-view" />详情</el-button>
            <el-button type="text" size="small" @click="quickVerify(scope.row)"><i class="el-icon-circle-check" />验证</el-button>
            <el-button type="text" size="small" @click="downloadTimestamp(scope.row)"><i class="el-icon-download" />下载</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </el-card>

    <!-- 申请时间戳弹窗 -->
    <el-dialog :visible.sync="applyDialogVisible" title="申请时间戳" width="600px">
      <el-form ref="applyForm" :model="applyForm" :rules="applyRules" label-width="120px">
        <el-alert
          title="时间戳说明"
          type="info"
          description="时间戳用于证明数据在某一时刻的存在性和完整性，具有法律效力。"
          :closable="false"
          style="margin-bottom: 20px;"
        />
        <el-form-item label="申请方式">
          <el-radio-group v-model="applyType">
            <el-radio label="FILE">文件时间戳</el-radio>
            <el-radio label="DATA">数据时间戳</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="applyType === 'FILE'" label="上传文件" prop="file">
          <el-upload
            ref="uploadApply"
            action="#"
            :auto-upload="false"
            :limit="1"
            :on-change="handleApplyFileChange"
            :file-list="applyFileList"
          >
            <el-button slot="trigger" size="small" type="primary">选择文件</el-button>
            <div slot="tip" class="el-upload__tip">文件大小不超过100MB</div>
          </el-upload>
        </el-form-item>
        <el-form-item v-if="applyType === 'DATA'" label="数据内容" prop="data">
          <el-input
            v-model="applyForm.data"
            type="textarea"
            :rows="5"
            placeholder="请输入要打时间戳的数据内容"
          />
        </el-form-item>
        <el-form-item label="时间戳类型" prop="timestampType">
          <el-select v-model="applyForm.timestampType" placeholder="请选择时间戳类型" style="width: 100%;">
            <el-option label="RFC3161标准时间戳" value="RFC3161" />
            <el-option label="区块链时间戳" value="BLOCKCHAIN" />
            <el-option label="可信时间戳" value="TRUSTED" />
          </el-select>
        </el-form-item>
        <el-form-item label="TSA服务器" prop="tsaServer">
          <el-select v-model="applyForm.tsaServer" placeholder="请选择时间戳服务器" style="width: 100%;">
            <el-option label="默认TSA服务器" value="DEFAULT" />
            <el-option label="国家授时中心" value="NTSC" />
            <el-option label="自定义服务器" value="CUSTOM" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="applyForm.tsaServer === 'CUSTOM'" label="服务器地址" prop="customTsaUrl">
          <el-input v-model="applyForm.customTsaUrl" placeholder="请输入TSA服务器URL" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input
            v-model="applyForm.remark"
            type="textarea"
            :rows="2"
            placeholder="请输入备注信息（可选）"
            maxlength="200"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="applyDialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="applying" @click="submitApply">提交申请</el-button>
      </div>
    </el-dialog>

    <!-- 验证时间戳弹窗 -->
    <el-dialog :visible.sync="verifyDialogVisible" title="验证时间戳" width="600px">
      <el-form ref="verifyForm" :model="verifyForm" :rules="verifyRules" label-width="120px">
        <el-alert
          title="验证说明"
          type="info"
          description="上传时间戳文件进行验证，或输入时间戳ID查询验证结果。"
          :closable="false"
          style="margin-bottom: 20px;"
        />
        <el-form-item label="验证方式">
          <el-radio-group v-model="verifyType">
            <el-radio label="FILE">上传时间戳文件</el-radio>
            <el-radio label="ID">输入时间戳ID</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="verifyType === 'FILE'" label="时间戳文件" prop="file">
          <el-upload
            ref="uploadVerify"
            action="#"
            :auto-upload="false"
            :limit="1"
            :on-change="handleVerifyFileChange"
            :file-list="verifyFileList"
            accept=".tsr,.tst"
          >
            <el-button slot="trigger" size="small" type="primary">选择文件</el-button>
            <div slot="tip" class="el-upload__tip">支持.tsr、.tst格式的时间戳文件</div>
          </el-upload>
        </el-form-item>
        <el-form-item v-if="verifyType === 'ID'" label="时间戳ID" prop="timestampId">
          <el-input v-model="verifyForm.timestampId" placeholder="请输入时间戳ID" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="verifyDialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="verifying" @click="submitVerify">开始验证</el-button>
      </div>
    </el-dialog>

    <!-- 时间戳详情弹窗 -->
    <el-dialog :visible.sync="detailVisible" title="时间戳详情" width="800px" top="5vh">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="时间戳ID">{{ detailInfo.timestampId }}</el-descriptions-item>
        <el-descriptions-item label="时间戳类型">
          <el-tag v-if="detailInfo.timestampType === 'RFC3161'" type="primary" size="small">RFC3161</el-tag>
          <el-tag v-else-if="detailInfo.timestampType === 'BLOCKCHAIN'" type="success" size="small">区块链</el-tag>
          <el-tag v-else size="small">{{ detailInfo.timestampType }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="文件名称">{{ detailInfo.fileName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="文件大小">{{ detailInfo.fileSize || '-' }}</el-descriptions-item>
        <el-descriptions-item label="数据哈希" :span="2">
          <span class="hash-text">{{ detailInfo.dataHash }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="TSA服务器">{{ detailInfo.tsaServer || '-' }}</el-descriptions-item>
        <el-descriptions-item label="签名算法">{{ detailInfo.signAlgorithm || 'SHA-256' }}</el-descriptions-item>
        <el-descriptions-item label="序列号">{{ detailInfo.serialNumber || '-' }}</el-descriptions-item>
        <el-descriptions-item label="策略OID">{{ detailInfo.policyOid || '-' }}</el-descriptions-item>
        <el-descriptions-item label="状态" :span="2">
          <el-tag v-if="detailInfo.status === 'VALID'" type="success">有效</el-tag>
          <el-tag v-else-if="detailInfo.status === 'EXPIRED'" type="info">已过期</el-tag>
          <el-tag v-else type="danger">{{ detailInfo.status }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="申请者">{{ detailInfo.applicant || '-' }}</el-descriptions-item>
        <el-descriptions-item label="申请时间">{{ detailInfo.createTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="生效时间">{{ detailInfo.effectiveTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="过期时间">{{ detailInfo.expiryTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="验证次数">{{ detailInfo.verifyCount || 0 }}</el-descriptions-item>
        <el-descriptions-item label="最后验证">{{ detailInfo.lastVerifyTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detailInfo.remark || '-' }}</el-descriptions-item>
      </el-descriptions>

      <div v-if="detailInfo.certificate" style="margin-top: 20px;">
        <el-divider content-position="left">证书信息</el-divider>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="颁发者">{{ (detailInfo.certificate && detailInfo.certificate.issuer) || '-' }}</el-descriptions-item>
          <el-descriptions-item label="主体">{{ (detailInfo.certificate && detailInfo.certificate.subject) || '-' }}</el-descriptions-item>
          <el-descriptions-item label="证书序列号" :span="2">{{ (detailInfo.certificate && detailInfo.certificate.serialNumber) || '-' }}</el-descriptions-item>
        </el-descriptions>
      </div>

      <div slot="footer">
        <el-button @click="detailVisible = false">关 闭</el-button>
        <el-button type="primary" @click="quickVerify(detailInfo)">验证时间戳</el-button>
        <el-button type="success" @click="downloadTimestamp(detailInfo)">下载时间戳</el-button>
      </div>
    </el-dialog>

    <!-- 验证结果弹窗 -->
    <el-dialog :visible.sync="verifyResultVisible" title="验证结果" width="600px">
      <el-result
        :icon="verifyResult.valid ? 'success' : 'error'"
        :title="verifyResult.valid ? '验证通过' : '验证失败'"
        :sub-title="verifyResult.message"
      >
        <template slot="extra">
          <div v-if="verifyResult.valid" class="verify-details">
            <p><strong>时间戳时间：</strong>{{ verifyResult.timestampTime }}</p>
            <p><strong>TSA服务器：</strong>{{ verifyResult.tsaServer }}</p>
            <p><strong>数据哈希：</strong><span class="hash-text">{{ verifyResult.dataHash }}</span></p>
            <p><strong>签名有效性：</strong><el-tag type="success" size="small">有效</el-tag></p>
          </div>
          <el-button type="primary" @click="verifyResultVisible = false">确 定</el-button>
        </template>
      </el-result>
    </el-dialog>
  </div>
</template>

<script>
import { getTimestampPage, applyTimestamp, verifyTimestamp, getTimestampDetail } from '@/api/evidence'
import Pagination from '@/components/Pagination'

export default {
  name: 'EvidenceTimestamp',
  components: { Pagination },
  data() {
    return {
      statistics: {},
      list: [],
      selectedRows: [],
      searchForm: {
        keyword: '',
        timestampType: '',
        status: ''
      },
      dateRange: [],
      loading: false,
      applyDialogVisible: false,
      applyType: 'FILE',
      applyForm: {
        file: null,
        data: '',
        timestampType: 'RFC3161',
        tsaServer: 'DEFAULT',
        customTsaUrl: '',
        remark: ''
      },
      applyRules: {
        timestampType: [{ required: true, message: '请选择时间戳类型', trigger: 'change' }],
        tsaServer: [{ required: true, message: '请选择TSA服务器', trigger: 'change' }]
      },
      applyFileList: [],
      applying: false,
      verifyDialogVisible: false,
      verifyType: 'FILE',
      verifyForm: {
        file: null,
        timestampId: ''
      },
      verifyRules: {
        timestampId: [{ required: true, message: '请输入时间戳ID', trigger: 'blur' }]
      },
      verifyFileList: [],
      verifying: false,
      detailVisible: false,
      detailInfo: {},
      verifyResultVisible: false,
      verifyResult: {},
      itemTotalCount: 0,
      pageSize: 10,
      pageCount: 0,
      pageNum: 1
    }
  },
  created() {
    this.fetchData()
    this.fetchStatistics()
  },
  methods: {
    fetchData() {
      this.loading = true
      const params = {
        pageSize: this.pageSize,
        pageNum: this.pageNum,
        keyword: this.searchForm.keyword,
        timestampType: this.searchForm.timestampType,
        status: this.searchForm.status,
        startTime: this.dateRange && this.dateRange.length > 0 ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange.length > 1 ? this.dateRange[1] : ''
      }
      getTimestampPage(params).then((res) => {
        if (res.code === 0) {
          const { list, pageParam } = res.result
          this.list = list || []
          this.pageCount = Number(pageParam?.pageCount || 0)
          this.pageNum = Number(pageParam?.pageNum || 1)
          this.itemTotalCount = Number(pageParam?.itemTotalCount || 0)
        }
      }).finally(() => {
        this.loading = false
      })
    },
    fetchStatistics() {
      // TODO: 调用统计接口
      this.statistics = {
        totalTimestamps: 156,
        validTimestamps: 142,
        todayApply: 8
      }
    },
    handleSearch() {
      this.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.searchForm = {
        keyword: '',
        timestampType: '',
        status: ''
      }
      this.dateRange = []
      this.pageNum = 1
      this.fetchData()
    },
    handlePagination(data) {
      this.pageNum = data.page
      this.fetchData()
    },
    handleSelectionChange(rows) {
      this.selectedRows = rows
    },
    openApplyDialog() {
      this.applyType = 'FILE'
      this.applyForm = {
        file: null,
        data: '',
        timestampType: 'RFC3161',
        tsaServer: 'DEFAULT',
        customTsaUrl: '',
        remark: ''
      }
      this.applyFileList = []
      this.applyDialogVisible = true
    },
    handleApplyFileChange(file) {
      this.applyForm.file = file.raw
      this.applyFileList = [file]
    },
    async submitApply() {
      this.$refs.applyForm.validate(async(valid) => {
        if (valid) {
          if (this.applyType === 'FILE' && !this.applyForm.file) {
            this.$message.warning('请选择文件')
            return
          }
          if (this.applyType === 'DATA' && !this.applyForm.data) {
            this.$message.warning('请输入数据内容')
            return
          }

          this.applying = true
          const formData = new FormData()
          if (this.applyType === 'FILE') {
            formData.append('file', this.applyForm.file)
          } else {
            formData.append('data', this.applyForm.data)
          }
          formData.append('timestampType', this.applyForm.timestampType)
          formData.append('tsaServer', this.applyForm.tsaServer)
          if (this.applyForm.customTsaUrl) {
            formData.append('customTsaUrl', this.applyForm.customTsaUrl)
          }
          formData.append('remark', this.applyForm.remark)

          const res = await applyTimestamp(formData)
          this.applying = false

          if (res.code === 0) {
            this.$message.success('时间戳申请成功')
            this.applyDialogVisible = false
            this.fetchData()
            this.fetchStatistics()
          }
        }
      })
    },
    openVerifyDialog() {
      this.verifyType = 'FILE'
      this.verifyForm = {
        file: null,
        timestampId: ''
      }
      this.verifyFileList = []
      this.verifyDialogVisible = true
    },
    handleVerifyFileChange(file) {
      this.verifyForm.file = file.raw
      this.verifyFileList = [file]
    },
    async submitVerify() {
      if (this.verifyType === 'ID') {
        this.$refs.verifyForm.validate(async(valid) => {
          if (valid) {
            await this.performVerify()
          }
        })
      } else {
        if (!this.verifyForm.file) {
          this.$message.warning('请选择时间戳文件')
          return
        }
        await this.performVerify()
      }
    },
    async performVerify() {
      this.verifying = true
      const formData = new FormData()
      if (this.verifyType === 'FILE') {
        formData.append('file', this.verifyForm.file)
      } else {
        formData.append('timestampId', this.verifyForm.timestampId)
      }
      formData.append('verifyType', this.verifyType)

      const res = await verifyTimestamp(formData)
      this.verifying = false

      if (res.code === 0) {
        this.verifyResult = res.result || {}
        this.verifyDialogVisible = false
        this.verifyResultVisible = true
      }
    },
    quickVerify(row) {
      this.verifyForm = {
        timestampId: row.timestampId
      }
      this.verifyType = 'ID'
      this.verifyDialogVisible = true
    },
    async viewDetail(row) {
      const res = await getTimestampDetail({ timestampId: row.timestampId })
      if (res.code === 0) {
        this.detailInfo = res.result || {}
        this.detailVisible = true
      }
    },
    downloadTimestamp(row) {
      // TODO: 实现下载功能
      this.$message.info('下载功能开发中...')
    },
    batchDownload() {
      if (this.selectedRows.length === 0) {
        this.$message.warning('请选择要下载的时间戳')
        return
      }
      // TODO: 实现批量下载
      this.$message.info('批量下载功能开发中...')
    }
  }
}
</script>

<style lang="scss" scoped>
.container {
  padding: 20px;
  background-color: #f0f2f5;
}

.stats-row {
  margin-bottom: 20px;
}

.stats-card {
  .stats-content {
    display: flex;
    align-items: center;
    .stats-icon-wrapper {
      width: 60px;
      height: 60px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 15px;
      i {
        font-size: 32px;
        color: #fff;
      }
      &.primary {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      }
      &.success {
        background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
      }
      &.warning {
        background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
      }
    }
    .stats-info {
      flex: 1;
      .stats-label {
        font-size: 14px;
        color: #909399;
        margin-bottom: 8px;
      }
      .stats-value {
        font-size: 28px;
        font-weight: bold;
        color: #303133;
      }
    }
  }
}

.action-bar {
  margin-bottom: 20px;
}

.filter-card {
  margin-bottom: 20px;
}

.filter-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.table-card {
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

.timestamp-table {
  margin-top: 20px;
  .hash-text {
    font-family: 'Courier New', monospace;
    font-size: 12px;
    color: #606266;
  }
}

.verify-details {
  text-align: left;
  padding: 20px;
  background: #f5f7fa;
  border-radius: 4px;
  p {
    margin: 10px 0;
    line-height: 1.8;
  }
}

::v-deep .el-table th {
  background: #fafafa;
}

::v-deep .el-upload__tip {
  font-size: 12px;
  color: #909399;
  margin-top: 5px;
}
</style>
