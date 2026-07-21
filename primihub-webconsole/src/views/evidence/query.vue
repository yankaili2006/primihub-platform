<template>
  <div class="container">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper primary">
              <i class="el-icon-document" />
            </div>
            <div class="stats-info">
              <div class="stats-label">总存证数</div>
              <div class="stats-value">{{ statistics.totalEvidence || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper success">
              <i class="el-icon-circle-plus" />
            </div>
            <div class="stats-info">
              <div class="stats-label">今日新增</div>
              <div class="stats-value">{{ statistics.todayNew || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper warning">
              <i class="el-icon-circle-check" />
            </div>
            <div class="stats-info">
              <div class="stats-label">验证通过率</div>
              <div class="stats-value">{{ statistics.verifyRate || 0 }}%</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper info">
              <i class="el-icon-s-cooperation" />
            </div>
            <div class="stats-info">
              <div class="stats-label">上链存证</div>
              <div class="stats-value">{{ statistics.onChain || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选条件 -->
    <el-card class="filter-card" shadow="never">
      <div class="filter-bar">
        <el-input
          v-model="searchForm.keyword"
          placeholder="存证ID/哈希值/原文哈希"
          style="width: 250px; margin-right: 10px;"
          clearable
          @clear="handleSearch"
        />
        <el-select
          v-model="searchForm.evidenceType"
          placeholder="存证类型"
          style="width: 150px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="文件存证" value="FILE" />
          <el-option label="数据存证" value="DATA" />
          <el-option label="交易存证" value="TRANSACTION" />
          <el-option label="合约存证" value="CONTRACT" />
        </el-select>
        <el-select
          v-model="searchForm.chainType"
          placeholder="区块链类型"
          style="width: 150px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="以太坊" value="ETHEREUM" />
          <el-option label="Fabric" value="FABRIC" />
          <el-option label="FISCO BCOS" value="FISCO" />
          <el-option label="本地链" value="LOCAL" />
        </el-select>
        <el-select
          v-model="searchForm.status"
          placeholder="状态"
          style="width: 120px; margin-right: 10px;"
          clearable
          @change="handleSearch"
        >
          <el-option label="待上链" value="PENDING" />
          <el-option label="已上链" value="CONFIRMED" />
          <el-option label="验证通过" value="VERIFIED" />
          <el-option label="验证失败" value="FAILED" />
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

    <!-- 存证列表 -->
    <el-card class="table-card" shadow="never">
      <div slot="header" class="card-header">
        <span class="card-title"><i class="el-icon-tickets" /> 存证列表</span>
        <div class="card-actions">
          <el-button type="success" icon="el-icon-plus" size="small" @click="openCreateDialog">创建存证</el-button>
          <el-button type="primary" icon="el-icon-upload" size="small" @click="openVerifyDialog">验证存证</el-button>
        </div>
      </div>

      <el-table
        v-loading="loading"
        :data="list"
        class="evidence-table"
        stripe
      >
        <el-table-column align="center" label="序号" width="70" type="index" />
        <el-table-column align="left" label="存证ID" prop="evidenceId" width="180" show-overflow-tooltip>
          <template slot-scope="scope">
            <el-link type="primary" @click="viewDetail(scope.row)">{{ scope.row.evidenceId }}</el-link>
          </template>
        </el-table-column>
        <el-table-column align="left" label="存证哈希" prop="evidenceHash" min-width="200" show-overflow-tooltip>
          <template slot-scope="scope">
            <span class="hash-text">{{ scope.row.evidenceHash }}</span>
            <el-button type="text" icon="el-icon-document-copy" size="mini" @click="copyToClipboard(scope.row.evidenceHash)" />
          </template>
        </el-table-column>
        <el-table-column align="center" label="存证类型" prop="evidenceType" width="120">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.evidenceType === 'FILE'" type="primary" size="small">文件存证</el-tag>
            <el-tag v-else-if="scope.row.evidenceType === 'DATA'" type="success" size="small">数据存证</el-tag>
            <el-tag v-else-if="scope.row.evidenceType === 'TRANSACTION'" type="warning" size="small">交易存证</el-tag>
            <el-tag v-else-if="scope.row.evidenceType === 'CONTRACT'" type="info" size="small">合约存证</el-tag>
            <el-tag v-else size="small">{{ scope.row.evidenceType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="区块链" prop="chainType" width="120">
          <template slot-scope="scope">
            <span class="chain-badge">{{ scope.row.chainType || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column align="center" label="区块高度" prop="blockHeight" width="120" />
        <el-table-column align="center" label="状态" prop="status" width="110">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.status === 'PENDING'" type="info" size="small">待上链</el-tag>
            <el-tag v-else-if="scope.row.status === 'CONFIRMED'" type="success" size="small">已上链</el-tag>
            <el-tag v-else-if="scope.row.status === 'VERIFIED'" type="success" size="small" effect="dark">已验证</el-tag>
            <el-tag v-else-if="scope.row.status === 'FAILED'" type="danger" size="small">失败</el-tag>
            <el-tag v-else size="small">{{ scope.row.status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column align="center" label="存证时间" prop="createTime" width="180" />
        <el-table-column align="center" label="操作" fixed="right" width="180">
          <template slot-scope="scope">
            <el-button type="text" size="small" @click="viewDetail(scope.row)"><i class="el-icon-view" />详情</el-button>
            <el-button type="text" size="small" @click="quickVerify(scope.row)"><i class="el-icon-circle-check" />验证</el-button>
            <el-button type="text" size="small" @click="downloadCert(scope.row)"><i class="el-icon-download" />下载</el-button>
          </template>
        </el-table-column>
      </el-table>
      <pagination v-show="pageCount>0" :limit.sync="pageSize" :page-count="pageCount" :page.sync="pageNum" :total="itemTotalCount" @pagination="handlePagination" />
    </el-card>

    <!-- 创建存证弹窗 -->
    <el-dialog :visible.sync="createDialogVisible" title="创建存证" width="600px" top="20vh">
      <el-form ref="createForm" :model="createForm" :rules="createRules" label-width="100px">
        <el-form-item label="存证类型" prop="evidenceType">
          <el-select v-model="createForm.evidenceType" placeholder="请选择存证类型" style="width: 100%;">
            <el-option label="文件存证" value="FILE" />
            <el-option label="数据存证" value="DATA" />
            <el-option label="交易存证" value="TRANSACTION" />
            <el-option label="合约存证" value="CONTRACT" />
          </el-select>
        </el-form-item>
        <el-form-item label="存证数据" prop="data">
          <el-input v-model="createForm.data" type="textarea" :rows="4" placeholder="请输入存证内容或上传文件哈希" />
        </el-form-item>
        <el-form-item label="区块链" prop="chainType">
          <el-select v-model="createForm.chainType" placeholder="请选择区块链" style="width: 100%;">
            <el-option label="Fabric" value="FABRIC" />
            <el-option label="以太坊" value="ETHEREUM" />
            <el-option label="FISCO BCOS" value="FISCO" />
            <el-option label="本地链" value="LOCAL" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="createForm.remark" type="textarea" :rows="2" placeholder="可选" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="createDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="creating" @click="submitCreate">提交存证</el-button>
      </div>
    </el-dialog>

    <!-- 存证详情弹窗 -->
    <el-dialog :visible.sync="detailVisible" title="存证详情" width="800px" top="5vh">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="存证ID">{{ detailInfo.evidenceId }}</el-descriptions-item>
        <el-descriptions-item label="存证类型">
          <el-tag v-if="detailInfo.evidenceType === 'FILE'" type="primary" size="small">文件存证</el-tag>
          <el-tag v-else-if="detailInfo.evidenceType === 'DATA'" type="success" size="small">数据存证</el-tag>
          <el-tag v-else size="small">{{ detailInfo.evidenceType }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="存证哈希" :span="2">
          <span class="hash-text">{{ detailInfo.evidenceHash }}</span>
          <el-button type="text" icon="el-icon-document-copy" size="mini" @click="copyToClipboard(detailInfo.evidenceHash)" />
        </el-descriptions-item>
        <el-descriptions-item label="原文哈希" :span="2">
          <span class="hash-text">{{ detailInfo.originalHash || '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="区块链类型">{{ detailInfo.chainType || '-' }}</el-descriptions-item>
        <el-descriptions-item label="交易哈希">
          <span class="hash-text">{{ detailInfo.txHash || '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="区块高度">{{ detailInfo.blockHeight || '-' }}</el-descriptions-item>
        <el-descriptions-item label="区块哈希">
          <span class="hash-text">{{ detailInfo.blockHash || '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="状态" :span="2">
          <el-tag v-if="detailInfo.status === 'CONFIRMED'" type="success">已上链</el-tag>
          <el-tag v-else-if="detailInfo.status === 'VERIFIED'" type="success" effect="dark">已验证</el-tag>
          <el-tag v-else-if="detailInfo.status === 'PENDING'" type="info">待上链</el-tag>
          <el-tag v-else type="danger">{{ detailInfo.status }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="文件名称">{{ detailInfo.fileName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="文件大小">{{ detailInfo.fileSize || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建者">{{ detailInfo.creator || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detailInfo.createTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="上链时间">{{ detailInfo.chainTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="验证时间">{{ detailInfo.verifyTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detailInfo.remark || '-' }}</el-descriptions-item>
      </el-descriptions>

      <!-- 区块链浏览器链接 -->
      <div v-if="detailInfo.txHash" class="chain-explorer" style="margin-top: 20px;">
        <el-alert
          title="区块链浏览器"
          type="info"
          :closable="false"
        >
          <template slot="default">
            <el-link :href="getExplorerUrl(detailInfo)" target="_blank" type="primary">
              在区块链浏览器中查看 <i class="el-icon-top-right" />
            </el-link>
          </template>
        </el-alert>
      </div>

      <div slot="footer">
        <el-button @click="detailVisible = false">关 闭</el-button>
        <el-button type="primary" @click="quickVerify(detailInfo)">验证存证</el-button>
        <el-button type="success" @click="downloadCert(detailInfo)">下载证书</el-button>
      </div>
    </el-dialog>

    <!-- 验证存证弹窗 -->
    <el-dialog :visible.sync="verifyDialogVisible" title="验证存证" width="600px">
      <el-form ref="verifyForm" :model="verifyForm" :rules="verifyRules" label-width="120px">
        <el-alert
          title="验证说明"
          type="info"
          description="上传文件或输入哈希值进行存证验证，系统将对比区块链上的存证记录。"
          :closable="false"
          style="margin-bottom: 20px;"
        />
        <el-form-item label="验证方式">
          <el-radio-group v-model="verifyType">
            <el-radio label="FILE">文件验证</el-radio>
            <el-radio label="HASH">哈希验证</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="verifyType === 'FILE'" label="上传文件" prop="file">
          <el-upload
            ref="upload"
            action="#"
            :auto-upload="false"
            :limit="1"
            :on-change="handleFileChange"
            :file-list="fileList"
          >
            <el-button slot="trigger" size="small" type="primary">选择文件</el-button>
            <div slot="tip" class="el-upload__tip">支持任意格式文件，系统将自动计算文件哈希值</div>
          </el-upload>
        </el-form-item>
        <el-form-item v-if="verifyType === 'HASH'" label="存证哈希" prop="hash">
          <el-input
            v-model="verifyForm.hash"
            type="textarea"
            :rows="3"
            placeholder="请输入存证哈希值"
          />
        </el-form-item>
        <el-form-item label="区块链类型" prop="chainType">
          <el-select v-model="verifyForm.chainType" placeholder="请选择区块链" style="width: 100%;">
            <el-option label="以太坊" value="ETHEREUM" />
            <el-option label="Fabric" value="FABRIC" />
            <el-option label="FISCO BCOS" value="FISCO" />
            <el-option label="本地链" value="LOCAL" />
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="verifyDialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="verifying" @click="submitVerify">开始验证</el-button>
      </div>
    </el-dialog>

    <!-- 验证结果弹窗 -->
    <el-dialog :visible.sync="verifyResultVisible" title="验证结果" width="600px">
      <el-result
        :icon="verifyResult.success ? 'success' : 'error'"
        :title="verifyResult.success ? '验证通过' : '验证失败'"
        :sub-title="verifyResult.message"
      >
        <template slot="extra">
          <div v-if="verifyResult.success" class="verify-details">
            <p><strong>存证ID：</strong>{{ verifyResult.evidenceId }}</p>
            <p><strong>区块高度：</strong>{{ verifyResult.blockHeight }}</p>
            <p><strong>上链时间：</strong>{{ verifyResult.chainTime }}</p>
            <p><strong>交易哈希：</strong><span class="hash-text">{{ verifyResult.txHash }}</span></p>
          </div>
          <el-button type="primary" @click="verifyResultVisible = false">确 定</el-button>
        </template>
      </el-result>
    </el-dialog>
  </div>
</template>

<script>
import { getEvidencePage, getEvidenceDetail, verifyEvidence, getEvidenceStatistics, createEvidence } from '@/api/evidence'
import Pagination from '@/components/Pagination'

export default {
  name: 'EvidenceQuery',
  components: { Pagination },
  data() {
    return {
      statistics: {},
      list: [],
      searchForm: {
        keyword: '',
        evidenceType: '',
        chainType: '',
        status: ''
      },
      dateRange: [],
      loading: false,
      detailVisible: false,
      detailInfo: {},
      createDialogVisible: false,
      createForm: { evidenceType: 'DATA', data: '', chainType: 'FABRIC', remark: '' },
      createRules: {
        evidenceType: [{ required: true, message: '请选择存证类型', trigger: 'change' }],
        data: [{ required: true, message: '请输入存证数据', trigger: 'blur' }],
        chainType: [{ required: true, message: '请选择区块链', trigger: 'change' }]
      },
      creating: false,
      verifyDialogVisible: false,
      verifyType: 'FILE',
      verifyForm: {
        file: null,
        hash: '',
        chainType: 'LOCAL'
      },
      verifyRules: {
        hash: [{ required: true, message: '请输入哈希值', trigger: 'blur' }],
        chainType: [{ required: true, message: '请选择区块链类型', trigger: 'change' }]
      },
      fileList: [],
      verifying: false,
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
        evidenceType: this.searchForm.evidenceType,
        chainType: this.searchForm.chainType,
        status: this.searchForm.status,
        startTime: this.dateRange && this.dateRange.length > 0 ? this.dateRange[0] : '',
        endTime: this.dateRange && this.dateRange.length > 1 ? this.dateRange[1] : ''
      }
      getEvidencePage(params).then((res) => {
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
      getEvidenceStatistics().then((res) => {
        if (res.code === 0) {
          this.statistics = res.result || {}
        }
      })
    },
    handleSearch() {
      this.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.searchForm = {
        keyword: '',
        evidenceType: '',
        chainType: '',
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
    async viewDetail(row) {
      const res = await getEvidenceDetail({ evidenceId: row.evidenceId })
      if (res.code === 0) {
        this.detailInfo = res.result || {}
        this.detailVisible = true
      }
    },
    openCreateDialog() {
      this.createForm = { evidenceType: 'DATA', data: '', chainType: 'FABRIC', remark: '' }
      this.createDialogVisible = true
    },
    async submitCreate() {
      this.$refs.createForm.validate(async valid => {
        if (!valid) return
        this.creating = true
        try {
          const res = await createEvidence(this.createForm)
          if (res.code === 0) {
            this.$message.success('存证创建成功')
            this.createDialogVisible = false
            this.fetchData()
            this.fetchStatistics()
          } else {
            this.$message.error(res.message || '创建失败')
          }
        } catch (e) { this.$message.error('请求异常') }
        this.creating = false
      })
    },
    openVerifyDialog() {
      this.verifyType = 'FILE'
      this.verifyForm = {
        file: null,
        hash: '',
        chainType: 'LOCAL'
      }
      this.fileList = []
      this.verifyDialogVisible = true
    },
    handleFileChange(file) {
      this.verifyForm.file = file.raw
      this.fileList = [file]
    },
    async submitVerify() {
      if (this.verifyType === 'HASH') {
        this.$refs.verifyForm.validate(async(valid) => {
          if (valid) {
            await this.performVerify()
          }
        })
      } else {
        if (!this.verifyForm.file) {
          this.$message.warning('请选择要验证的文件')
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
        formData.append('hash', this.verifyForm.hash)
      }
      formData.append('chainType', this.verifyForm.chainType)
      formData.append('verifyType', this.verifyType)

      const res = await verifyEvidence(formData)
      this.verifying = false

      if (res.code === 0) {
        this.verifyResult = res.result || {}
        this.verifyDialogVisible = false
        this.verifyResultVisible = true
      }
    },
    quickVerify(row) {
      this.verifyForm = {
        hash: row.evidenceHash,
        chainType: row.chainType || 'LOCAL'
      }
      this.verifyType = 'HASH'
      this.verifyDialogVisible = true
    },
    downloadCert(row) {
      this.$message.info('正在下载证书...')
      const certContent = row.certContent || row.certificate || JSON.stringify(row, null, 2)
      const blob = new Blob([certContent], { type: 'application/octet-stream' })
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `evidence_cert_${row.id || Date.now()}.cert`
      link.click()
      window.URL.revokeObjectURL(url)
    },
    copyToClipboard(text) {
      const textarea = document.createElement('textarea')
      textarea.value = text
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
      this.$message.success('已复制到剪贴板')
    },
    getExplorerUrl(detail) {
      // TODO: 根据不同区块链类型返回不同的浏览器URL
      const baseUrls = {
        ETHEREUM: 'https://etherscan.io/tx/',
        FABRIC: '#',
        FISCO: '#',
        LOCAL: '#'
      }
      return (baseUrls[detail.chainType] || '#') + detail.txHash
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
      &.info {
        background: linear-gradient(135deg, #30cfd0 0%, #330867 100%);
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

.evidence-table {
  margin-top: 20px;
  .hash-text {
    font-family: 'Courier New', monospace;
    font-size: 12px;
    color: #606266;
  }
  .chain-badge {
    display: inline-block;
    padding: 2px 8px;
    background: #ecf5ff;
    color: #409eff;
    border-radius: 3px;
    font-size: 12px;
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

::v-deep .el-descriptions-item__label {
  font-weight: bold;
}
</style>
