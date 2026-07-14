<template>
  <div class="monitor-container">
    <!-- 整体监控统计卡片 -->
    <el-skeleton :loading="statsLoading" animated :count="4" style="display:flex;gap:20px;">
      <template slot="template">
        <el-card class="stats-card" shadow="hover" style="flex:1;">
          <el-skeleton-item variant="text" style="width:60%;height:40px;margin:0 auto;" />
        </el-card>
      </template>
    </el-skeleton>
    <el-row v-show="!statsLoading" :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper primary"><i class="el-icon-monitor" /></div>
            <div class="stats-info">
              <div class="stats-label">系统健康度</div>
              <div class="stats-value">{{ statistics.systemHealth || 0 }}%</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper success"><i class="el-icon-circle-check" /></div>
            <div class="stats-info">
              <div class="stats-label">正常服务</div>
              <div class="stats-value">{{ statistics.normalServices || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper warning"><i class="el-icon-warning" /></div>
            <div class="stats-info">
              <div class="stats-label">今日告警</div>
              <div class="stats-value">{{ statistics.todayAlerts || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stats-card" shadow="hover">
          <div class="stats-content">
            <div class="stats-icon-wrapper danger"><i class="el-icon-bell" /></div>
            <div class="stats-info">
              <div class="stats-label">未处理告警</div>
              <div class="stats-value">{{ statistics.pendingAlerts || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 监控主面板 -->
    <el-card class="monitor-card">
      <el-tabs v-model="activeTab" type="border-card">
        <!-- 操作系统监控 -->
        <el-tab-pane label="操作系统监控" name="os">
          <el-row :gutter="20">
            <!-- CPU监控 -->
            <el-col :span="8">
              <div class="monitor-section">
                <div class="section-header">
                  <span class="section-title"><i class="el-icon-cpu" /> CPU监控</span>
                  <el-tag :type="cpuData.status === 'NORMAL' ? 'success' : 'danger'" size="mini">
                    {{ cpuData.status === 'NORMAL' ? '正常' : '异常' }}
                  </el-tag>
                </div>
                <div class="metric-display">
                  <div class="metric-value">{{ cpuData.usage || 0 }}%</div>
                  <div class="metric-label">当前使用率</div>
                </div>
                <el-progress
                  :percentage="cpuData.usage || 0"
                  :color="getProgressColor(cpuData.usage)"
                  :stroke-width="10"
                />
                <div class="metric-details">
                  <p><span>核心数：</span>{{ cpuData.cores || 0 }}</p>
                  <p><span>系统占用：</span>{{ cpuData.systemUsage || 0 }}%</p>
                  <p><span>用户占用：</span>{{ cpuData.userUsage || 0 }}%</p>
                  <p><span>空闲率：</span>{{ cpuData.idle || 0 }}%</p>
                </div>
                <div class="alert-config-btn">
                  <el-button type="text" size="small" @click="openAlertConfig('CPU')">
                    <i class="el-icon-setting" /> 告警配置
                  </el-button>
                </div>
              </div>
            </el-col>

            <!-- 内存监控 -->
            <el-col :span="8">
              <div class="monitor-section">
                <div class="section-header">
                  <span class="section-title"><i class="el-icon-files" /> 内存监控</span>
                  <el-tag :type="memoryData.status === 'NORMAL' ? 'success' : 'danger'" size="mini">
                    {{ memoryData.status === 'NORMAL' ? '正常' : '异常' }}
                  </el-tag>
                </div>
                <div class="metric-display">
                  <div class="metric-value">{{ memoryData.usage || 0 }}%</div>
                  <div class="metric-label">当前使用率</div>
                </div>
                <el-progress
                  :percentage="memoryData.usage || 0"
                  :color="getProgressColor(memoryData.usage)"
                  :stroke-width="10"
                />
                <div class="metric-details">
                  <p><span>总内存：</span>{{ memoryData.total || '0 GB' }}</p>
                  <p><span>已使用：</span>{{ memoryData.used || '0 GB' }}</p>
                  <p><span>空闲：</span>{{ memoryData.free || '0 GB' }}</p>
                  <p><span>缓存：</span>{{ memoryData.cached || '0 GB' }}</p>
                </div>
                <div class="alert-config-btn">
                  <el-button type="text" size="small" @click="openAlertConfig('MEMORY')">
                    <i class="el-icon-setting" /> 告警配置
                  </el-button>
                </div>
              </div>
            </el-col>

            <!-- 磁盘监控 -->
            <el-col :span="8">
              <div class="monitor-section">
                <div class="section-header">
                  <span class="section-title"><i class="el-icon-folder-opened" /> 磁盘监控</span>
                  <el-tag :type="diskData.status === 'NORMAL' ? 'success' : 'danger'" size="mini">
                    {{ diskData.status === 'NORMAL' ? '正常' : '异常' }}
                  </el-tag>
                </div>
                <div class="metric-display">
                  <div class="metric-value">{{ diskData.usage || 0 }}%</div>
                  <div class="metric-label">当前使用率</div>
                </div>
                <el-progress
                  :percentage="diskData.usage || 0"
                  :color="getProgressColor(diskData.usage)"
                  :stroke-width="10"
                />
                <div class="metric-details">
                  <p><span>总容量：</span>{{ diskData.total || '0 GB' }}</p>
                  <p><span>已使用：</span>{{ diskData.used || '0 GB' }}</p>
                  <p><span>可用：</span>{{ diskData.free || '0 GB' }}</p>
                  <p><span>IO等待：</span>{{ diskData.ioWait || 0 }}%</p>
                </div>
                <div class="alert-config-btn">
                  <el-button type="text" size="small" @click="openAlertConfig('DISK')">
                    <i class="el-icon-setting" /> 告警配置
                  </el-button>
                </div>
              </div>
            </el-col>
          </el-row>

          <!-- 历史趋势图 -->
          <el-card class="chart-card" shadow="never" style="margin-top: 20px;">
            <div slot="header" class="chart-header">
              <span><i class="el-icon-data-line" /> 历史趋势（最近24小时）</span>
              <el-radio-group v-model="osChartType" size="small">
                <el-radio-button label="CPU">CPU</el-radio-button>
                <el-radio-button label="MEMORY">内存</el-radio-button>
                <el-radio-button label="DISK">磁盘</el-radio-button>
              </el-radio-group>
            </div>
            <div class="chart-placeholder">
              <i class="el-icon-data-line" style="font-size: 48px; color: #409eff;"></i>
              <p style="color: #606266; margin-top: 10px; font-weight: bold;">监控趋势图</p>
              <p style="color: #909399; margin-top: 4px; font-size: 13px;">选择上方监控维度查看历史趋势</p>
              <el-button size="small" style="margin-top: 12px;" @click="refreshMonitorData">刷新数据</el-button>
            </div>
          </el-card>
        </el-tab-pane>

        <!-- 数据库监控 -->
        <el-tab-pane label="数据库监控" name="database">
          <el-row :gutter="20">
            <!-- 数据库状态 -->
            <el-col :span="12">
              <div class="monitor-section">
                <div class="section-header">
                  <span class="section-title"><i class="el-icon-coin" /> 数据库状态</span>
                  <el-tag :type="databaseData.status === 'NORMAL' ? 'success' : 'danger'" size="mini">
                    {{ databaseData.status === 'NORMAL' ? '正常' : '异常' }}
                  </el-tag>
                </div>
                <div class="db-metrics">
                  <el-row :gutter="10">
                    <el-col :span="12">
                      <div class="db-metric-item">
                        <div class="db-metric-label">连接数</div>
                        <div class="db-metric-value">{{ databaseData.connections || 0 }}</div>
                        <el-progress
                          :percentage="databaseData.connectionUsage || 0"
                          :stroke-width="6"
                          :show-text="false"
                        />
                      </div>
                    </el-col>
                    <el-col :span="12">
                      <div class="db-metric-item">
                        <div class="db-metric-label">QPS</div>
                        <div class="db-metric-value">{{ databaseData.qps || 0 }}</div>
                        <el-progress
                          :percentage="Math.min((databaseData.qps / 1000) * 100, 100)"
                          :stroke-width="6"
                          :show-text="false"
                          color="#67c23a"
                        />
                      </div>
                    </el-col>
                    <el-col :span="12">
                      <div class="db-metric-item">
                        <div class="db-metric-label">慢查询</div>
                        <div class="db-metric-value" style="color: #e6a23c;">{{ databaseData.slowQueries || 0 }}</div>
                      </div>
                    </el-col>
                    <el-col :span="12">
                      <div class="db-metric-item">
                        <div class="db-metric-label">锁等待</div>
                        <div class="db-metric-value" style="color: #f56c6c;">{{ databaseData.lockWaits || 0 }}</div>
                      </div>
                    </el-col>
                  </el-row>
                </div>
                <div class="metric-details" style="margin-top: 15px;">
                  <p><span>数据库版本：</span>{{ databaseData.version || 'MySQL 5.7' }}</p>
                  <p><span>运行时间：</span>{{ databaseData.uptime || '0天' }}</p>
                  <p><span>数据大小：</span>{{ databaseData.dataSize || '0 GB' }}</p>
                  <p><span>索引大小：</span>{{ databaseData.indexSize || '0 GB' }}</p>
                </div>
                <div class="alert-config-btn">
                  <el-button type="text" size="small" @click="openAlertConfig('DATABASE')">
                    <i class="el-icon-setting" /> 告警配置
                  </el-button>
                </div>
              </div>
            </el-col>

            <!-- 数据库性能指标 -->
            <el-col :span="12">
              <div class="monitor-section">
                <div class="section-header">
                  <span class="section-title"><i class="el-icon-data-analysis" /> 性能指标</span>
                </div>
                <el-table :data="databaseMetrics" size="small" stripe>
                  <el-table-column label="指标名称" prop="name" />
                  <el-table-column label="当前值" prop="currentValue" align="center" />
                  <el-table-column label="阈值" prop="threshold" align="center" />
                  <el-table-column label="状态" align="center" width="80">
                    <template slot-scope="scope">
                      <el-tag
                        :type="scope.row.status === 'NORMAL' ? 'success' : 'warning'"
                        size="mini"
                      >
                        {{ scope.row.status === 'NORMAL' ? '正常' : '警告' }}
                      </el-tag>
                    </template>
                  </el-table-column>
                </el-table>
              </div>

              <!-- 慢查询列表 -->
              <div class="monitor-section" style="margin-top: 20px;">
                <div class="section-header">
                  <span class="section-title"><i class="el-icon-warning-outline" /> 最近慢查询</span>
                </div>
                <el-table :data="slowQueryList" size="small" stripe max-height="200">
                  <el-table-column label="查询时间" prop="queryTime" width="180" />
                  <el-table-column label="耗时(秒)" prop="duration" width="100" align="center" />
                  <el-table-column label="SQL语句" prop="sql" show-overflow-tooltip />
                </el-table>
              </div>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- 中间件监控 -->
        <el-tab-pane label="中间件监控" name="middleware">
          <el-row :gutter="20">
            <!-- JVM监控 -->
            <el-col :span="12">
              <div class="monitor-section">
                <div class="section-header">
                  <span class="section-title"><i class="el-icon-guide" /> JVM监控</span>
                  <el-tag :type="jvmData.status === 'NORMAL' ? 'success' : 'danger'" size="mini">
                    {{ jvmData.status === 'NORMAL' ? '正常' : '异常' }}
                  </el-tag>
                </div>
                <div class="jvm-metrics">
                  <el-row :gutter="10">
                    <el-col :span="12">
                      <div class="jvm-metric-card">
                        <div class="jvm-metric-title">堆内存</div>
                        <div class="jvm-metric-value">{{ jvmData.heapUsage || 0 }}%</div>
                        <el-progress
                          :percentage="jvmData.heapUsage || 0"
                          :color="getProgressColor(jvmData.heapUsage)"
                          :stroke-width="8"
                        />
                        <div class="jvm-metric-detail">
                          {{ jvmData.heapUsed || '0 MB' }} / {{ jvmData.heapMax || '0 MB' }}
                        </div>
                      </div>
                    </el-col>
                    <el-col :span="12">
                      <div class="jvm-metric-card">
                        <div class="jvm-metric-title">非堆内存</div>
                        <div class="jvm-metric-value">{{ jvmData.nonHeapUsage || 0 }}%</div>
                        <el-progress
                          :percentage="jvmData.nonHeapUsage || 0"
                          :color="getProgressColor(jvmData.nonHeapUsage)"
                          :stroke-width="8"
                        />
                        <div class="jvm-metric-detail">
                          {{ jvmData.nonHeapUsed || '0 MB' }} / {{ jvmData.nonHeapMax || '0 MB' }}
                        </div>
                      </div>
                    </el-col>
                  </el-row>
                </div>
                <div class="metric-details" style="margin-top: 15px;">
                  <p><span>JVM版本：</span>{{ jvmData.version || 'Java 1.8' }}</p>
                  <p><span>运行时间：</span>{{ jvmData.uptime || '0天' }}</p>
                  <p><span>线程数：</span>{{ jvmData.threadCount || 0 }}</p>
                  <p><span>类加载数：</span>{{ jvmData.classCount || 0 }}</p>
                </div>
                <div class="gc-info" style="margin-top: 15px;">
                  <el-divider content-position="left">GC信息</el-divider>
                  <p><span>Young GC次数：</span>{{ jvmData.youngGcCount || 0 }}</p>
                  <p><span>Young GC时间：</span>{{ jvmData.youngGcTime || '0ms' }}</p>
                  <p><span>Full GC次数：</span>{{ jvmData.fullGcCount || 0 }}</p>
                  <p><span>Full GC时间：</span>{{ jvmData.fullGcTime || '0ms' }}</p>
                </div>
                <div class="alert-config-btn">
                  <el-button type="text" size="small" @click="openAlertConfig('JVM')">
                    <i class="el-icon-setting" /> 告警配置
                  </el-button>
                </div>
              </div>
            </el-col>

            <!-- Redis监控 -->
            <el-col :span="12">
              <div class="monitor-section">
                <div class="section-header">
                  <span class="section-title"><i class="el-icon-box" /> Redis监控</span>
                  <el-tag :type="redisData.status === 'NORMAL' ? 'success' : 'danger'" size="mini">
                    {{ redisData.status === 'NORMAL' ? '正常' : '异常' }}
                  </el-tag>
                </div>
                <div class="redis-metrics">
                  <el-row :gutter="10">
                    <el-col :span="8">
                      <div class="redis-metric-item">
                        <div class="redis-icon"><i class="el-icon-key" /></div>
                        <div class="redis-value">{{ redisData.keys || 0 }}</div>
                        <div class="redis-label">总键数</div>
                      </div>
                    </el-col>
                    <el-col :span="8">
                      <div class="redis-metric-item">
                        <div class="redis-icon"><i class="el-icon-connection" /></div>
                        <div class="redis-value">{{ redisData.connectedClients || 0 }}</div>
                        <div class="redis-label">连接数</div>
                      </div>
                    </el-col>
                    <el-col :span="8">
                      <div class="redis-metric-item">
                        <div class="redis-icon"><i class="el-icon-s-data" /></div>
                        <div class="redis-value">{{ redisData.usedMemory || '0 MB' }}</div>
                        <div class="redis-label">内存使用</div>
                      </div>
                    </el-col>
                  </el-row>
                </div>
                <div class="metric-details" style="margin-top: 15px;">
                  <p><span>Redis版本：</span>{{ redisData.version || 'Redis 6.0' }}</p>
                  <p><span>运行模式：</span>{{ redisData.mode || 'standalone' }}</p>
                  <p><span>运行时间：</span>{{ redisData.uptime || '0天' }}</p>
                  <p><span>命中率：</span>{{ redisData.hitRate || 0 }}%</p>
                </div>
                <div class="redis-ops" style="margin-top: 15px;">
                  <el-divider content-position="left">操作统计</el-divider>
                  <el-row :gutter="10">
                    <el-col :span="12">
                      <p><span>总命令数：</span>{{ redisData.totalCommands || 0 }}</p>
                      <p><span>每秒操作数：</span>{{ redisData.opsPerSec || 0 }}</p>
                    </el-col>
                    <el-col :span="12">
                      <p><span>输入流量：</span>{{ redisData.inputKbps || '0 KB/s' }}</p>
                      <p><span>输出流量：</span>{{ redisData.outputKbps || '0 KB/s' }}</p>
                    </el-col>
                  </el-row>
                </div>
                <div class="alert-config-btn">
                  <el-button type="text" size="small" @click="openAlertConfig('REDIS')">
                    <i class="el-icon-setting" /> 告警配置
                  </el-button>
                </div>
              </div>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- 告警历史 -->
        <el-tab-pane label="告警历史" name="alerts">
          <div class="filter-bar" style="margin-bottom: 15px;">
            <el-select v-model="alertFilter.type" placeholder="告警类型" style="width: 150px; margin-right: 10px;" clearable>
              <el-option label="CPU" value="CPU" />
              <el-option label="内存" value="MEMORY" />
              <el-option label="磁盘" value="DISK" />
              <el-option label="数据库" value="DATABASE" />
              <el-option label="JVM" value="JVM" />
              <el-option label="Redis" value="REDIS" />
            </el-select>
            <el-select v-model="alertFilter.level" placeholder="告警级别" style="width: 120px; margin-right: 10px;" clearable>
              <el-option label="严重" value="CRITICAL" />
              <el-option label="警告" value="WARNING" />
              <el-option label="信息" value="INFO" />
            </el-select>
            <el-select v-model="alertFilter.status" placeholder="处理状态" style="width: 120px; margin-right: 10px;" clearable>
              <el-option label="待处理" value="PENDING" />
              <el-option label="已处理" value="HANDLED" />
              <el-option label="已忽略" value="IGNORED" />
            </el-select>
            <el-date-picker
              v-model="alertDateRange"
              type="datetimerange"
              range-separator="至"
              start-placeholder="开始时间"
              end-placeholder="结束时间"
              style="width: 380px; margin-right: 10px;"
            />
            <el-button type="primary" icon="el-icon-search" @click="fetchAlertHistory">搜索</el-button>
            <el-button icon="el-icon-refresh" @click="resetAlertFilter">重置</el-button>
          </div>

          <el-table :data="alertHistoryList" stripe>
            <el-table-column label="告警时间" prop="alertTime" width="180" />
            <el-table-column label="告警类型" prop="type" width="100">
              <template slot-scope="scope">
                <el-tag size="small">{{ scope.row.type }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="告警级别" prop="level" width="100" align="center">
              <template slot-scope="scope">
                <el-tag
                  :type="scope.row.level === 'CRITICAL' ? 'danger' : scope.row.level === 'WARNING' ? 'warning' : 'info'"
                  size="small"
                >
                  {{ scope.row.level === 'CRITICAL' ? '严重' : scope.row.level === 'WARNING' ? '警告' : '信息' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="告警内容" prop="message" show-overflow-tooltip />
            <el-table-column label="告警值" prop="value" width="100" align="center" />
            <el-table-column label="处理状态" prop="status" width="100" align="center">
              <template slot-scope="scope">
                <el-tag
                  :type="scope.row.status === 'PENDING' ? 'danger' : scope.row.status === 'HANDLED' ? 'success' : 'info'"
                  size="small"
                >
                  {{ scope.row.status === 'PENDING' ? '待处理' : scope.row.status === 'HANDLED' ? '已处理' : '已忽略' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="处理人" prop="handler" width="100" />
            <el-table-column label="操作" width="150" fixed="right">
              <template slot-scope="scope">
                <el-button v-if="scope.row.status === 'PENDING'" type="text" size="small" @click="handleAlertItem(scope.row)">
                  处理
                </el-button>
                <el-button type="text" size="small" @click="viewAlertDetail(scope.row)">详情</el-button>
              </template>
            </el-table-column>
          </el-table>
          <pagination v-show="alertPageCount>0" :limit.sync="alertPageSize" :page-count="alertPageCount" :page.sync="alertPageNum" :total="alertItemTotal" @pagination="handleAlertPagination" />
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 告警配置弹窗 -->
    <el-dialog :visible.sync="alertConfigVisible" :title="`${currentAlertType}告警配置`" width="600px">
      <el-form :model="alertConfigForm" label-width="120px">
        <el-form-item label="启用告警">
          <el-switch v-model="alertConfigForm.enabled" />
        </el-form-item>
        <el-form-item label="告警阈值">
          <el-input-number v-model="alertConfigForm.threshold" :min="0" :max="100" style="width: 100%;" />
          <span style="margin-left: 10px;">%</span>
        </el-form-item>
        <el-form-item label="持续时间">
          <el-input-number v-model="alertConfigForm.duration" :min="1" :max="60" style="width: 100%;" />
          <span style="margin-left: 10px;">分钟（超过阈值持续该时间才告警）</span>
        </el-form-item>
        <el-form-item label="告警级别">
          <el-select v-model="alertConfigForm.level" style="width: 100%;">
            <el-option label="信息" value="INFO" />
            <el-option label="警告" value="WARNING" />
            <el-option label="严重" value="CRITICAL" />
          </el-select>
        </el-form-item>
        <el-form-item label="告警方式">
          <el-checkbox-group v-model="alertConfigForm.notifyMethods">
            <el-checkbox label="EMAIL">邮件</el-checkbox>
            <el-checkbox label="SMS">短信</el-checkbox>
            <el-checkbox label="WEBHOOK">WebHook</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="通知对象">
          <el-input v-model="alertConfigForm.notifyTargets" type="textarea" :rows="3" placeholder="多个邮箱/手机号用逗号分隔" />
        </el-form-item>
        <el-form-item label="静默期">
          <el-input-number v-model="alertConfigForm.silencePeriod" :min="5" :max="1440" style="width: 100%;" />
          <span style="margin-left: 10px;">分钟（同类告警静默期内不重复发送）</span>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="alertConfigVisible = false">取 消</el-button>
        <el-button type="primary" @click="saveAlertConfiguration">保 存</el-button>
      </div>
    </el-dialog>

    <!-- 告警处理弹窗 -->
    <el-dialog :visible.sync="handleAlertVisible" title="处理告警" width="500px">
      <el-form :model="handleAlertForm" label-width="100px">
        <el-form-item label="处理方式">
          <el-radio-group v-model="handleAlertForm.action">
            <el-radio label="HANDLED">已处理</el-radio>
            <el-radio label="IGNORED">忽略</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="处理备注">
          <el-input v-model="handleAlertForm.remark" type="textarea" :rows="4" placeholder="请输入处理说明" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="handleAlertVisible = false">取 消</el-button>
        <el-button type="primary" @click="submitHandleAlert">确 定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  getSystemMonitor,
  getCpuMonitor,
  getMemoryMonitor,
  getDiskMonitor,
  getDatabaseMonitor,
  getJvmMonitor,
  getRedisMonitor,
  getMonitorStatistics,
  getAlertConfig,
  saveAlertConfig,
  getAlertHistory,
  handleAlert
} from '@/api/monitor'
import Pagination from '@/components/Pagination'

export default {
  name: 'MonitorIndex',
  components: { Pagination },
  data() {
    return {
      activeTab: 'os',
      osChartType: 'CPU',
      statistics: {},
      statsLoading: true,
      cpuData: {},
      memoryData: {},
      diskData: {},
      databaseData: {},
      databaseMetrics: [],
      slowQueryList: [],
      jvmData: {},
      redisData: {},
      alertFilter: {
        type: '',
        level: '',
        status: ''
      },
      alertDateRange: [],
      alertHistoryList: [],
      alertPageSize: 10,
      alertPageCount: 0,
      alertPageNum: 1,
      alertItemTotal: 0,
      alertConfigVisible: false,
      currentAlertType: '',
      alertConfigForm: {
        enabled: true,
        threshold: 80,
        duration: 5,
        level: 'WARNING',
        notifyMethods: ['EMAIL'],
        notifyTargets: '',
        silencePeriod: 30
      },
      handleAlertVisible: false,
      handleAlertForm: {
        action: 'HANDLED',
        remark: ''
      },
      currentAlertItem: null,
      refreshTimer: null
    }
  },
  created() {
    const nameToTab = { MonitorOs: 'os', MonitorDatabase: 'database', MonitorMiddleware: 'middleware', MonitorAlerts: 'alerts' }
    const tab = this.$route?.query?.tab || nameToTab[this.$route?.name]
    if (tab && ['os', 'database', 'middleware', 'alerts'].includes(tab)) this.activeTab = tab
    this.fetchStatistics()
    this.fetchMonitorData()
    this.fetchAlertHistory()
    this.startAutoRefresh()
  },
  beforeDestroy() {
    this.stopAutoRefresh()
  },
  methods: {
    refreshMonitorData() {
      this.$message.info('正在刷新...')
      this.fetchMonitorData()
    },
    async fetchStatistics() {
      this.statsLoading = true
      const res = await getMonitorStatistics()
      if (res && res.code === 0) {
        this.statistics = res.result || {}
      } else {
        this.statistics = {
          systemHealth: 95, normalServices: 12, todayAlerts: 3, pendingAlerts: 1
        }
      }
      this.statsLoading = false
    },
    async fetchMonitorData() {
      // TODO: 调用实际接口获取监控数据
      // CPU监控
      const cpuRes = await getCpuMonitor()
      this.cpuData = cpuRes?.result || {
        usage: 45,
        status: 'NORMAL',
        cores: 8,
        systemUsage: 15,
        userUsage: 30,
        idle: 55
      }

      // 内存监控
      const memoryRes = await getMemoryMonitor()
      this.memoryData = memoryRes?.result || {
        usage: 68,
        status: 'NORMAL',
        total: '16 GB',
        used: '10.9 GB',
        free: '5.1 GB',
        cached: '2.5 GB'
      }

      // 磁盘监控
      const diskRes = await getDiskMonitor()
      this.diskData = diskRes?.result || {
        usage: 72,
        status: 'NORMAL',
        total: '500 GB',
        used: '360 GB',
        free: '140 GB',
        ioWait: 2
      }

      // 数据库监控
      const dbRes = await getDatabaseMonitor()
      this.databaseData = dbRes?.result || {
        status: 'NORMAL',
        connections: 45,
        connectionUsage: 45,
        qps: 320,
        slowQueries: 5,
        lockWaits: 2,
        version: 'MySQL 5.7.35',
        uptime: '15天',
        dataSize: '8.5 GB',
        indexSize: '2.3 GB'
      }

      this.databaseMetrics = [
        { name: '查询缓存命中率', currentValue: '85%', threshold: '> 70%', status: 'NORMAL' },
        { name: 'InnoDB缓冲池使用率', currentValue: '92%', threshold: '> 80%', status: 'NORMAL' },
        { name: '临时表使用率', currentValue: '15%', threshold: '< 20%', status: 'NORMAL' },
        { name: '表锁定率', currentValue: '3%', threshold: '< 5%', status: 'NORMAL' }
      ]

      this.slowQueryList = [
        { queryTime: '2026-01-09 14:25:30', duration: 2.5, sql: 'SELECT * FROM large_table WHERE...' },
        { queryTime: '2026-01-09 13:18:22', duration: 1.8, sql: 'UPDATE users SET status = 1 WHERE...' }
      ]

      // JVM监控
      const jvmRes = await getJvmMonitor()
      this.jvmData = jvmRes?.result || {
        status: 'NORMAL',
        heapUsage: 65,
        heapUsed: '1024 MB',
        heapMax: '1600 MB',
        nonHeapUsage: 45,
        nonHeapUsed: '180 MB',
        nonHeapMax: '400 MB',
        version: 'Java 1.8.0_282',
        uptime: '5天',
        threadCount: 128,
        classCount: 8562,
        youngGcCount: 245,
        youngGcTime: '1250ms',
        fullGcCount: 3,
        fullGcTime: '450ms'
      }

      // Redis监控
      const redisRes = await getRedisMonitor()
      this.redisData = redisRes?.result || {
        status: 'NORMAL',
        keys: 15623,
        connectedClients: 28,
        usedMemory: '256 MB',
        version: 'Redis 6.0.10',
        mode: 'standalone',
        uptime: '20天',
        hitRate: 95.6,
        totalCommands: 25683421,
        opsPerSec: 1520,
        inputKbps: '180 KB/s',
        outputKbps: '320 KB/s'
      }
    },
    async fetchAlertHistory() {
      // TODO: 调用实际接口获取告警历史
      const params = {
        pageSize: this.alertPageSize,
        pageNum: this.alertPageNum,
        type: this.alertFilter.type,
        level: this.alertFilter.level,
        status: this.alertFilter.status,
        startTime: this.alertDateRange && this.alertDateRange.length > 0 ? this.alertDateRange[0] : '',
        endTime: this.alertDateRange && this.alertDateRange.length > 1 ? this.alertDateRange[1] : ''
      }
      const res = await getAlertHistory(params)
      if (res && res.code === 0) {
        this.alertHistoryList = res.result?.list || []
        this.alertPageCount = res.result?.pageParam?.pageCount || 0
        this.alertItemTotal = res.result?.pageParam?.itemTotalCount || 0
      } else {
        // 模拟数据
        this.alertHistoryList = [
          { id: 1, alertTime: '2026-01-09 14:30:25', type: 'CPU', level: 'WARNING', message: 'CPU使用率超过阈值', value: '85%', status: 'PENDING', handler: '' },
          { id: 2, alertTime: '2026-01-09 12:15:10', type: 'MEMORY', level: 'CRITICAL', message: '内存使用率过高', value: '92%', status: 'HANDLED', handler: 'admin' },
          { id: 3, alertTime: '2026-01-09 10:45:33', type: 'DATABASE', level: 'WARNING', message: '慢查询数量增加', value: '15', status: 'HANDLED', handler: 'admin' }
        ]
        this.alertPageCount = 1
        this.alertItemTotal = 3
      }
    },
    resetAlertFilter() {
      this.alertFilter = {
        type: '',
        level: '',
        status: ''
      }
      this.alertDateRange = []
      this.alertPageNum = 1
      this.fetchAlertHistory()
    },
    handleAlertPagination(data) {
      this.alertPageNum = data.page
      this.fetchAlertHistory()
    },
    openAlertConfig(type) {
      this.currentAlertType = type
      this.alertConfigVisible = true
      // TODO: 加载该类型的告警配置
      this.loadAlertConfig(type)
    },
    async loadAlertConfig(type) {
      const res = await getAlertConfig({ type })
      if (res && res.code === 0) {
        const configs = Array.isArray(res.result) ? res.result : []
        const config = configs.find(item => item.monitorType === type || item.type === type) || res.result || {}
        this.alertConfigForm = this.normalizeAlertConfig(config)
      }
    },
    async saveAlertConfiguration() {
      const data = {
        id: this.alertConfigForm.id,
        type: this.currentAlertType,
        monitorType: this.currentAlertType,
        threshold: this.alertConfigForm.threshold,
        duration: this.alertConfigForm.duration,
        alertLevel: this.alertLevelToValue(this.alertConfigForm.level),
        notifyMethod: (this.alertConfigForm.notifyMethods || []).join(','),
        notifyTarget: this.alertConfigForm.notifyTargets || '',
        isEnabled: this.alertConfigForm.enabled ? 1 : 0
      }
      try {
        const res = await saveAlertConfig(data)
        if (res && res.code === 0) {
          this.$message.success('告警配置保存成功')
          this.alertConfigVisible = false
        } else {
          this.$message.error((res && res.msg) || '告警配置保存失败')
        }
      } catch (e) {
        this.$message.error('告警配置保存失败，请稍后重试')
      }
    },
    normalizeAlertConfig(config) {
      const defaults = {
        enabled: true,
        threshold: 80,
        duration: 5,
        level: 'WARNING',
        notifyMethods: ['EMAIL'],
        notifyTargets: '',
        silencePeriod: 30
      }
      if (!config || !Object.keys(config).length) return defaults
      return {
        ...defaults,
        id: config.id,
        enabled: config.enabled !== undefined ? !!config.enabled : config.isEnabled !== 0,
        threshold: config.threshold !== undefined ? Number(config.threshold) : defaults.threshold,
        duration: config.duration !== undefined ? Number(config.duration) : defaults.duration,
        level: config.level || this.alertLevelToName(config.alertLevel),
        notifyMethods: Array.isArray(config.notifyMethods)
          ? config.notifyMethods
          : (config.notifyMethod ? config.notifyMethod.split(',').filter(Boolean) : defaults.notifyMethods),
        notifyTargets: config.notifyTargets || config.notifyTarget || '',
        silencePeriod: config.silencePeriod !== undefined ? Number(config.silencePeriod) : defaults.silencePeriod
      }
    },
    alertLevelToValue(level) {
      const levelMap = { INFO: 0, WARNING: 1, CRITICAL: 2 }
      return levelMap[level] !== undefined ? levelMap[level] : 1
    },
    alertLevelToName(level) {
      const levelMap = { 0: 'INFO', 1: 'WARNING', 2: 'CRITICAL' }
      return levelMap[level] || 'WARNING'
    },
    handleAlertItem(row) {
      this.currentAlertItem = row
      this.handleAlertForm = {
        action: 'HANDLED',
        remark: ''
      }
      this.handleAlertVisible = true
    },
    async submitHandleAlert() {
      // TODO: 调用实际接口处理告警
      const data = {
        alertId: this.currentAlertItem.id,
        ...this.handleAlertForm
      }
      const res = await handleAlert(data)
      if (res && res.code === 0) {
        this.$message.success('告警处理成功')
        this.handleAlertVisible = false
        this.fetchAlertHistory()
      }
    },
    viewAlertDetail(row) {
      this.$message.info('告警详情功能开发中...')
      // TODO: 实现告警详情查看
    },
    getProgressColor(percentage) {
      if (percentage < 60) return '#67c23a'
      if (percentage < 80) return '#e6a23c'
      return '#f56c6c'
    },
    startAutoRefresh() {
      // 每30秒自动刷新监控数据
      this.refreshTimer = setInterval(() => {
        this.fetchMonitorData()
        this.fetchStatistics()
      }, 30000)
    },
    stopAutoRefresh() {
      if (this.refreshTimer) {
        clearInterval(this.refreshTimer)
        this.refreshTimer = null
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.monitor-container {
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
      &.danger {
        background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%);
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

.monitor-card {
  ::v-deep .el-tabs--border-card {
    border: none;
    box-shadow: none;
  }
}

.monitor-section {
  background: #fff;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
  margin-bottom: 20px;

  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    padding-bottom: 10px;
    border-bottom: 1px solid #ebeef5;
    .section-title {
      font-size: 16px;
      font-weight: bold;
      color: #303133;
      i {
        margin-right: 8px;
        color: #409eff;
      }
    }
  }

  .metric-display {
    text-align: center;
    margin-bottom: 15px;
    .metric-value {
      font-size: 36px;
      font-weight: bold;
      color: #409eff;
      margin-bottom: 5px;
    }
    .metric-label {
      font-size: 14px;
      color: #909399;
    }
  }

  .metric-details {
    margin-top: 15px;
    p {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      font-size: 14px;
      color: #606266;
      span {
        color: #909399;
      }
    }
  }

  .alert-config-btn {
    margin-top: 15px;
    text-align: center;
  }
}

.db-metrics {
  .db-metric-item {
    background: #f5f7fa;
    padding: 15px;
    border-radius: 6px;
    text-align: center;
    margin-bottom: 10px;
    .db-metric-label {
      font-size: 13px;
      color: #909399;
      margin-bottom: 8px;
    }
    .db-metric-value {
      font-size: 24px;
      font-weight: bold;
      color: #303133;
      margin-bottom: 8px;
    }
  }
}

.jvm-metrics {
  .jvm-metric-card {
    background: #f5f7fa;
    padding: 15px;
    border-radius: 6px;
    margin-bottom: 10px;
    .jvm-metric-title {
      font-size: 14px;
      color: #909399;
      margin-bottom: 10px;
    }
    .jvm-metric-value {
      font-size: 28px;
      font-weight: bold;
      color: #409eff;
      margin-bottom: 10px;
      text-align: center;
    }
    .jvm-metric-detail {
      font-size: 12px;
      color: #606266;
      text-align: center;
      margin-top: 5px;
    }
  }
}

.gc-info {
  p {
    display: flex;
    justify-content: space-between;
    padding: 5px 0;
    font-size: 13px;
    color: #606266;
    span {
      color: #909399;
    }
  }
}

.redis-metrics {
  .redis-metric-item {
    text-align: center;
    padding: 15px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 8px;
    color: #fff;
    .redis-icon {
      font-size: 32px;
      margin-bottom: 10px;
    }
    .redis-value {
      font-size: 24px;
      font-weight: bold;
      margin-bottom: 5px;
    }
    .redis-label {
      font-size: 13px;
      opacity: 0.9;
    }
  }
}

.redis-ops {
  p {
    display: flex;
    justify-content: space-between;
    padding: 5px 0;
    font-size: 13px;
    color: #606266;
    span {
      color: #909399;
    }
  }
}

.chart-card {
  .chart-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .chart-placeholder {
    height: 300px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: #fafafa;
    border-radius: 4px;
  }
}

.filter-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

::v-deep .el-table th {
  background: #fafafa;
}

::v-deep .el-divider__text {
  font-size: 13px;
  color: #606266;
}
</style>
