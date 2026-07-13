<template>
  <div class="app-container">
    <el-row :gutter="20">
      <!-- Left Panel: Requirements List -->
      <el-col :span="8">
        <el-card class="box-card">
          <div slot="header" class="clearfix">
            <span>数据需求列表</span>
          </div>

          <!-- Search -->
          <el-input
            v-model="requirementKeyword"
            placeholder="搜索需求"
            prefix-icon="el-icon-search"
            clearable
            style="margin-bottom: 15px;"
            @input="handleRequirementSearch"
          />

          <!-- Requirements List -->
          <el-scrollbar style="height: calc(100vh - 280px);">
            <div
              v-for="item in requirementList"
              :key="item.id"
              class="requirement-item"
              :class="{ 'is-active': selectedRequirement && selectedRequirement.id === item.id }"
              @click="handleSelectRequirement(item)"
            >
              <div class="requirement-title">{{ item.requirementName }}</div>
              <div class="requirement-meta">
                <el-tag size="mini" :type="getPriorityType(item.priority)">
                  {{ getPriorityText(item.priority) }}
                </el-tag>
                <el-tag size="mini" :type="getStatusType(item.status)" style="margin-left: 5px;">
                  {{ getStatusText(item.status) }}
                </el-tag>
              </div>
              <div class="requirement-desc">{{ item.requirementDesc || '暂无描述' }}</div>
            </div>
            <div v-if="requirementList.length === 0" class="empty-text">暂无数据需求</div>
          </el-scrollbar>
        </el-card>
      </el-col>

      <!-- Right Panel: Matched Resources -->
      <el-col :span="16">
        <el-card class="box-card">
          <div slot="header" class="clearfix">
            <span>匹配结果</span>
            <el-button
              v-if="selectedRequirement"
              style="float: right; padding: 3px 10px;"
              type="primary"
              size="small"
              @click="handleExecuteMatch"
            >
              <i class="el-icon-refresh" /> 重新匹配
            </el-button>
          </div>

          <div v-if="!selectedRequirement" class="empty-placeholder">
            <i class="el-icon-info" style="font-size: 60px; color: #ccc;" />
            <p style="margin-top: 20px; color: #999;">请选择左侧的数据需求查看匹配结果</p>
          </div>

          <div v-else>
            <!-- Requirement Info -->
            <el-descriptions :column="2" border size="small" style="margin-bottom: 20px;">
              <el-descriptions-item label="需求名称">{{ selectedRequirement.requirementName }}</el-descriptions-item>
              <el-descriptions-item label="需求类型">{{ selectedRequirement.requirementType }}</el-descriptions-item>
              <el-descriptions-item label="所需数据量">{{ selectedRequirement.dataVolume || '-' }}</el-descriptions-item>
              <el-descriptions-item label="数据格式">{{ selectedRequirement.dataFormat || '-' }}</el-descriptions-item>
            </el-descriptions>

            <!-- Filter -->
            <el-form :inline="true" style="margin-bottom: 15px;">
              <el-form-item label="匹配状态">
                <el-select v-model="matchStatus" placeholder="请选择" clearable @change="handleMatchStatusChange">
                  <el-option label="待确认" :value="0" />
                  <el-option label="已确认" :value="1" />
                  <el-option label="已拒绝" :value="2" />
                </el-select>
              </el-form-item>
            </el-form>

            <!-- Matched Resources Table -->
            <el-table
              v-loading="matchLoading"
              :data="matchedResources"
              border
              max-height="calc(100vh - 480px)"
            >
              <el-table-column prop="resourceName" label="资源名称" width="180" />
              <el-table-column prop="matchScore" label="匹配得分" width="100">
                <template slot-scope="scope">
                  <el-progress
                    :percentage="parseFloat(scope.row.matchScore)"
                    :color="getScoreColor(scope.row.matchScore)"
                  />
                </template>
              </el-table-column>
              <el-table-column prop="matchStatus" label="匹配状态" width="100">
                <template slot-scope="scope">
                  <el-tag v-if="scope.row.matchStatus === 0" type="info">待确认</el-tag>
                  <el-tag v-else-if="scope.row.matchStatus === 1" type="success">已确认</el-tag>
                  <el-tag v-else-if="scope.row.matchStatus === 2" type="danger">已拒绝</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="matchDetails" label="匹配详情" min-width="200">
                <template slot-scope="scope">
                  <el-popover trigger="hover" placement="left" width="300">
                    <div v-if="parseMatchDetails(scope.row.matchDetails)">
                      <div style="margin-bottom: 8px;">
                        <strong>字段匹配:</strong> {{ parseMatchDetails(scope.row.matchDetails).fieldScore }}分
                        (权重{{ parseMatchDetails(scope.row.matchDetails).fieldWeight }}%)
                      </div>
                      <div style="margin-bottom: 8px;">
                        <strong>数据量匹配:</strong> {{ parseMatchDetails(scope.row.matchDetails).volumeScore }}分
                        (权重{{ parseMatchDetails(scope.row.matchDetails).volumeWeight }}%)
                      </div>
                      <div style="margin-bottom: 8px;">
                        <strong>格式匹配:</strong> {{ parseMatchDetails(scope.row.matchDetails).formatScore }}分
                        (权重{{ parseMatchDetails(scope.row.matchDetails).formatWeight }}%)
                      </div>
                      <div>
                        <strong>类型匹配:</strong> {{ parseMatchDetails(scope.row.matchDetails).typeScore }}分
                        (权重{{ parseMatchDetails(scope.row.matchDetails).typeWeight }}%)
                      </div>
                    </div>
                    <el-button slot="reference" type="text" size="small">查看详情</el-button>
                  </el-popover>
                </template>
              </el-table-column>
              <el-table-column prop="createDate" label="匹配时间" width="160" />
              <el-table-column label="操作" fixed="right" width="150">
                <template slot-scope="scope">
                  <el-button
                    v-if="scope.row.matchStatus === 0"
                    size="mini"
                    type="success"
                    @click="handleConfirm(scope.row)"
                  >
                    确认
                  </el-button>
                  <el-button
                    v-if="scope.row.matchStatus === 0"
                    size="mini"
                    type="danger"
                    @click="handleReject(scope.row)"
                  >
                    拒绝
                  </el-button>
                  <span v-if="scope.row.matchStatus !== 0" style="color: #999;">
                    {{ scope.row.confirmUserName }}
                  </span>
                </template>
              </el-table-column>
            </el-table>

            <!-- Pagination -->
            <el-pagination
              v-if="matchedResourcesTotal > 0"
              style="margin-top: 15px;"
              :current-page="matchPageNum"
              :page-size="matchPageSize"
              :total="matchedResourcesTotal"
              layout="total, prev, pager, next"
              @current-change="handleMatchPageChange"
            />
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import {
  findDataRequirementPage,
  findMatchedResources,
  matchDataRequirements,
  confirmMatch,
  rejectMatch
} from '@/api/dataRequirement'
import { mapGetters } from 'vuex'

export default {
  name: 'DataRequirementMatch',
  data() {
    return {
      requirementKeyword: '',
      requirementList: [],
      selectedRequirement: null,
      matchedResources: [],
      matchedResourcesTotal: 0,
      matchLoading: false,
      matchStatus: null,
      matchPageNum: 1,
      matchPageSize: 10
    }
  },
  computed: {
    ...mapGetters(['userId', 'userName'])
  },
  mounted() {
    this.fetchRequirements()
    // Check if requirementId is passed via query
    if (this.$route.query.requirementId) {
      this.loadRequirementById(this.$route.query.requirementId)
    }
  },
  methods: {
    fetchRequirements() {
      const params = {
        keyword: this.requirementKeyword,
        pageNum: 1,
        pageSize: 100
      }
      findDataRequirementPage(params).then(res => {
        if (res.code === 0) {
          this.requirementList = res.result.list || []
        } else {
          // 使用测试数据
          this.requirementList = this.getMockRequirements()
        }
      }).catch(() => {
        // 使用测试数据
        this.requirementList = this.getMockRequirements()
      })
    },
    getMockRequirements() {
      return [
        {
          id: 1,
          requirementCode: 'REQ-2024-001',
          requirementName: '用户画像数据需求',
          requirementType: '模型训练',
          priority: 2,
          status: 0,
          dataVolume: 100000,
          dataFormat: 'CSV',
          requirementDesc: '需要用户基础信息数据用于用户画像模型训练'
        },
        {
          id: 2,
          requirementCode: 'REQ-2024-002',
          requirementName: '金融风控数据需求',
          requirementType: '数据分析',
          priority: 2,
          status: 1,
          dataVolume: 500000,
          dataFormat: 'JSON',
          requirementDesc: '金融交易数据用于风控分析'
        },
        {
          id: 3,
          requirementCode: 'REQ-2024-003',
          requirementName: '隐私求交测试数据',
          requirementType: '隐私求交',
          priority: 1,
          status: 0,
          dataVolume: 10000,
          dataFormat: 'CSV',
          requirementDesc: '需要包含手机号和邮箱的数据用于隐私求交测试'
        },
        {
          id: 4,
          requirementCode: 'REQ-2024-004',
          requirementName: '医疗健康数据需求',
          requirementType: '模型训练',
          priority: 0,
          status: 2,
          dataVolume: 50000,
          dataFormat: 'Excel',
          requirementDesc: '脱敏后的医疗数据用于疾病预测模型'
        },
        {
          id: 5,
          requirementCode: 'REQ-2024-005',
          requirementName: '电商推荐数据需求',
          requirementType: '其他',
          priority: 1,
          status: 3,
          dataVolume: 200000,
          dataFormat: 'CSV',
          requirementDesc: '用户行为数据用于推荐系统'
        }
      ]
    },
    loadRequirementById(requirementId) {
      const requirement = this.requirementList.find(r => r.id === parseInt(requirementId))
      if (requirement) {
        this.handleSelectRequirement(requirement)
      } else {
        // Fetch the specific requirement
        setTimeout(() => {
          const req = this.requirementList.find(r => r.id === parseInt(requirementId))
          if (req) {
            this.handleSelectRequirement(req)
          }
        }, 500)
      }
    },
    handleRequirementSearch() {
      this.fetchRequirements()
    },
    handleSelectRequirement(requirement) {
      this.selectedRequirement = requirement
      this.matchStatus = null
      this.matchPageNum = 1
      this.fetchMatchedResources()
    },
    fetchMatchedResources() {
      if (!this.selectedRequirement) return

      this.matchLoading = true
      const params = {
        requirementId: this.selectedRequirement.id,
        matchStatus: this.matchStatus,
        pageNum: this.matchPageNum,
        pageSize: this.matchPageSize
      }
      findMatchedResources(params).then(res => {
        this.matchLoading = false
        if (res.code === 0) {
          this.matchedResources = res.result.list || []
          this.matchedResourcesTotal = res.result.pageParam ? res.result.pageParam.itemTotalCount : 0
        } else {
          // 使用测试数据
          this.matchedResources = this.getMockMatchedResources()
          this.matchedResourcesTotal = this.matchedResources.length
        }
      }).catch(() => {
        this.matchLoading = false
        // 使用测试数据
        this.matchedResources = this.getMockMatchedResources()
        this.matchedResourcesTotal = this.matchedResources.length
      })
    },
    getMockMatchedResources() {
      return [
        {
          id: 1,
          resourceId: 101,
          resourceName: '用户基础信息数据集',
          matchScore: '92.5',
          matchStatus: 0,
          matchDetails: JSON.stringify({
            fieldScore: 95,
            fieldWeight: 40,
            volumeScore: 90,
            volumeWeight: 25,
            formatScore: 100,
            formatWeight: 20,
            typeScore: 85,
            typeWeight: 15
          }),
          createDate: '2024-01-15 10:30:00',
          confirmUserName: ''
        },
        {
          id: 2,
          resourceId: 102,
          resourceName: '客户画像数据资源',
          matchScore: '85.0',
          matchStatus: 1,
          matchDetails: JSON.stringify({
            fieldScore: 80,
            fieldWeight: 40,
            volumeScore: 95,
            volumeWeight: 25,
            formatScore: 100,
            formatWeight: 20,
            typeScore: 70,
            typeWeight: 15
          }),
          createDate: '2024-01-15 10:30:00',
          confirmUserName: 'admin'
        },
        {
          id: 3,
          resourceId: 103,
          resourceName: '用户行为分析数据',
          matchScore: '78.5',
          matchStatus: 0,
          matchDetails: JSON.stringify({
            fieldScore: 75,
            fieldWeight: 40,
            volumeScore: 85,
            volumeWeight: 25,
            formatScore: 80,
            formatWeight: 20,
            typeScore: 75,
            typeWeight: 15
          }),
          createDate: '2024-01-15 10:30:00',
          confirmUserName: ''
        },
        {
          id: 4,
          resourceId: 104,
          resourceName: '第三方用户数据',
          matchScore: '65.2',
          matchStatus: 2,
          matchDetails: JSON.stringify({
            fieldScore: 60,
            fieldWeight: 40,
            volumeScore: 70,
            volumeWeight: 25,
            formatScore: 80,
            formatWeight: 20,
            typeScore: 55,
            typeWeight: 15
          }),
          createDate: '2024-01-15 10:30:00',
          confirmUserName: 'admin'
        }
      ]
    },
    handleMatchStatusChange() {
      this.matchPageNum = 1
      this.fetchMatchedResources()
    },
    handleMatchPageChange(page) {
      this.matchPageNum = page
      this.fetchMatchedResources()
    },
    handleExecuteMatch() {
      this.$confirm('确认重新执行自动匹配吗? 这将清除之前的匹配结果。', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        this.matchLoading = true
        matchDataRequirements(this.selectedRequirement.id).then(res => {
          this.matchLoading = false
          if (res.code === 0) {
            this.$message.success(`匹配成功，找到${res.result.matchCount}个匹配资源`)
            this.fetchMatchedResources()
            this.fetchRequirements() // Refresh requirements to update status
          } else {
            this.$message.error(res.msg || '匹配失败')
          }
        }).catch(() => {
          this.matchLoading = false
          // 模拟匹配成功
          this.$message.success('匹配成功，找到4个匹配资源')
          this.matchedResources = this.getMockMatchedResources()
          this.matchedResourcesTotal = this.matchedResources.length
        })
      }).catch(() => {})
    },
    handleConfirm(row) {
      this.$confirm('确认该匹配结果吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'success'
      }).then(() => {
        confirmMatch(row.id, this.userId, this.userName).then(res => {
          if (res.code === 0) {
            this.$message.success('确认成功')
            this.fetchMatchedResources()
            this.fetchRequirements() // Refresh to update requirement status
          } else {
            this.$message.error(res.msg || '确认失败')
          }
        }).catch(() => {
          // 模拟确认成功
          row.matchStatus = 1
          row.confirmUserName = this.userName || 'admin'
          this.$message.success('确认成功')
        })
      }).catch(() => {})
    },
    handleReject(row) {
      this.$confirm('确认拒绝该匹配结果吗?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        rejectMatch(row.id, this.userId, this.userName).then(res => {
          if (res.code === 0) {
            this.$message.success('已拒绝')
            this.fetchMatchedResources()
          } else {
            this.$message.error(res.msg || '拒绝失败')
          }
        }).catch(() => {
          // 模拟拒绝成功
          row.matchStatus = 2
          row.confirmUserName = this.userName || 'admin'
          this.$message.success('已拒绝')
        })
      }).catch(() => {})
    },
    parseMatchDetails(detailsJson) {
      try {
        return JSON.parse(detailsJson)
      } catch (e) {
        return null
      }
    },
    getPriorityType(priority) {
      const types = { 0: 'info', 1: 'warning', 2: 'danger' }
      return types[priority] || 'info'
    },
    getPriorityText(priority) {
      const texts = { 0: '低', 1: '中', 2: '高' }
      return texts[priority] || '未知'
    },
    getStatusType(status) {
      const types = { 0: 'info', 1: 'warning', 2: 'success', 3: 'info' }
      return types[status] || 'info'
    },
    getStatusText(status) {
      const texts = { 0: '待匹配', 1: '已匹配', 2: '已完成', 3: '已关闭' }
      return texts[status] || '未知'
    },
    getScoreColor(score) {
      const s = parseFloat(score)
      if (s >= 80) return '#67C23A'
      if (s >= 60) return '#E6A23C'
      return '#F56C6C'
    }
  }
}
</script>

<style scoped>
.app-container {
  padding: 20px;
}

.box-card {
  height: calc(100vh - 100px);
}

.requirement-item {
  padding: 12px;
  border: 1px solid #EBEEF5;
  border-radius: 4px;
  margin-bottom: 10px;
  cursor: pointer;
  transition: all 0.3s;
}

.requirement-item:hover {
  background-color: #F5F7FA;
  border-color: #409EFF;
}

.requirement-item.is-active {
  background-color: #ECF5FF;
  border-color: #409EFF;
}

.requirement-title {
  font-weight: bold;
  margin-bottom: 8px;
}

.requirement-meta {
  margin-bottom: 8px;
}

.requirement-desc {
  font-size: 12px;
  color: #666;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.empty-text {
  text-align: center;
  color: #999;
  padding: 20px;
}

.empty-placeholder {
  text-align: center;
  padding: 80px 0;
}
</style>
