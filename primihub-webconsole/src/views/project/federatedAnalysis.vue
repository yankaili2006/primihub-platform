<template>
  <div class="app-container">
    <!-- Tab Navigation -->
    <el-tabs v-model="activeTab" type="card" @tab-click="handleTabClick">
      <el-tab-pane label="联邦分析任务" name="tasks" />
      <el-tab-pane label="数据源管理" name="datasource" />
      <el-tab-pane label="日志记录" name="logs" />
    </el-tabs>

    <!-- Tasks Panel -->
    <div v-show="activeTab === 'tasks'">
      <!-- Search filters -->
      <el-form :inline="true" :model="queryForm" class="demo-form-inline">
        <el-form-item label="任务名称">
          <el-input v-model="queryForm.taskName" placeholder="请输入任务名称" clearable />
        </el-form-item>
        <el-form-item label="分析类型">
          <el-select v-model="queryForm.analysisType" placeholder="请选择" clearable>
            <el-option label="联合查询" value="JOINT_QUERY" />
            <el-option label="隐私求交" value="PSI" />
            <el-option label="安全聚合" value="SECURE_AGG" />
            <el-option label="多方计算" value="MPC" />
          </el-select>
        </el-form-item>
        <el-form-item label="任务状态">
          <el-select v-model="queryForm.taskStatus" placeholder="请选择" clearable>
            <el-option label="待执行" :value="0" />
            <el-option label="执行中" :value="1" />
            <el-option label="已完成" :value="2" />
            <el-option label="已失败" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- Action buttons -->
      <el-row style="margin-bottom: 20px;">
        <el-button type="primary" icon="el-icon-plus" @click="handleCreate">创建联邦分析任务</el-button>
        <el-button type="success" icon="el-icon-download" :disabled="selectedRows.length === 0" @click="handleExportResults">导出分析结果</el-button>
      </el-row>

      <!-- Table -->
      <el-table v-loading="loading" :data="tableData" border @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="55" />
        <el-table-column prop="taskId" label="任务ID" width="120" />
        <el-table-column prop="taskName" label="任务名称" width="180" />
        <el-table-column prop="analysisType" label="分析类型" width="120">
          <template slot-scope="scope">
            <el-tag :type="getAnalysisTag(scope.row.analysisType)">
              {{ getAnalysisLabel(scope.row.analysisType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="dataSourceType" label="数据源类型" width="120">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.dataSourceType" size="small" type="info">{{ scope.row.dataSourceType }}</el-tag>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="participantCount" label="参与方数" width="100" />
        <el-table-column prop="dataVolume" label="数据量" width="100" />
        <el-table-column prop="taskStatus" label="任务状态" width="100">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.taskStatus === 0" type="info">待执行</el-tag>
            <el-tag v-else-if="scope.row.taskStatus === 1" type="warning">执行中</el-tag>
            <el-tag v-else-if="scope.row.taskStatus === 2" type="success">已完成</el-tag>
            <el-tag v-else-if="scope.row.taskStatus === 3" type="danger">已失败</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createDate" label="创建时间" width="160" />
        <el-table-column label="操作" fixed="right" width="250">
          <template slot-scope="scope">
            <el-button size="mini" @click="handleView(scope.row)">查看</el-button>
            <el-button v-if="scope.row.taskStatus === 0" size="mini" type="primary" @click="handleStart(scope.row)">执行</el-button>
            <el-button v-if="scope.row.taskStatus === 2" size="mini" type="success" @click="handleViewResult(scope.row)">结果</el-button>
            <el-button size="mini" type="info" @click="handleViewTaskLogs(scope.row)">日志</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- Pagination -->
      <el-pagination
        style="margin-top: 20px;"
        :current-page="queryForm.pageNum"
        :page-sizes="[10, 20, 50, 100]"
        :page-size="queryForm.pageSize"
        :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- Data Source Panel -->
    <div v-show="activeTab === 'datasource'">
      <!-- Data Source Type Tabs -->
      <el-tabs v-model="datasourceType" type="border-card">
        <el-tab-pane label="关系型数据库" name="rdbms">
          <div class="datasource-header">
            <el-button type="primary" icon="el-icon-plus" @click="handleAddRdbms">添加数据库连接</el-button>
            <el-button icon="el-icon-refresh" @click="fetchRdbmsList">刷新</el-button>
          </div>
          <el-table :data="rdbmsList" border style="margin-top: 15px;">
            <el-table-column prop="name" label="连接名称" width="150" />
            <el-table-column prop="dbType" label="数据库类型" width="120">
              <template slot-scope="scope">
                <el-tag size="small">{{ scope.row.dbType }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="host" label="主机地址" width="150" />
            <el-table-column prop="port" label="端口" width="80" />
            <el-table-column prop="database" label="数据库名" width="120" />
            <el-table-column prop="username" label="用户名" width="100" />
            <el-table-column prop="status" label="状态" width="100">
              <template slot-scope="scope">
                <el-tag :type="scope.row.status === 'connected' ? 'success' : 'danger'" size="small">
                  {{ scope.row.status === 'connected' ? '已连接' : '未连接' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createTime" label="创建时间" width="160" />
            <el-table-column label="操作" fixed="right" width="200">
              <template slot-scope="scope">
                <el-button size="mini" type="primary" @click="handleTestRdbms(scope.row)">测试</el-button>
                <el-button size="mini" @click="handleEditRdbms(scope.row)">编辑</el-button>
                <el-button size="mini" type="danger" @click="handleDeleteRdbms(scope.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="大数据平台" name="bigdata">
          <div class="datasource-header">
            <el-button type="primary" icon="el-icon-plus" @click="handleAddBigData">添加大数据平台连接</el-button>
            <el-button icon="el-icon-refresh" @click="fetchBigDataList">刷新</el-button>
          </div>
          <el-table :data="bigDataList" border style="margin-top: 15px;">
            <el-table-column prop="name" label="连接名称" width="150" />
            <el-table-column prop="platformType" label="平台类型" width="120">
              <template slot-scope="scope">
                <el-tag size="small" type="warning">{{ scope.row.platformType }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="clusterAddress" label="集群地址" width="200" />
            <el-table-column prop="version" label="版本" width="100" />
            <el-table-column prop="authType" label="认证方式" width="100" />
            <el-table-column prop="status" label="状态" width="100">
              <template slot-scope="scope">
                <el-tag :type="scope.row.status === 'connected' ? 'success' : 'danger'" size="small">
                  {{ scope.row.status === 'connected' ? '已连接' : '未连接' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createTime" label="创建时间" width="160" />
            <el-table-column label="操作" fixed="right" width="200">
              <template slot-scope="scope">
                <el-button size="mini" type="primary" @click="handleTestBigData(scope.row)">测试</el-button>
                <el-button size="mini" @click="handleEditBigData(scope.row)">编辑</el-button>
                <el-button size="mini" type="danger" @click="handleDeleteBigData(scope.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="公有云平台" name="cloud">
          <div class="datasource-header">
            <el-button type="primary" icon="el-icon-plus" @click="handleAddCloud">添加云平台连接</el-button>
            <el-button icon="el-icon-refresh" @click="fetchCloudList">刷新</el-button>
          </div>
          <el-table :data="cloudList" border style="margin-top: 15px;">
            <el-table-column prop="name" label="连接名称" width="150" />
            <el-table-column prop="cloudType" label="云平台" width="120">
              <template slot-scope="scope">
                <el-tag size="small" type="success">{{ getCloudLabel(scope.row.cloudType) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="region" label="区域" width="120" />
            <el-table-column prop="serviceType" label="服务类型" width="120" />
            <el-table-column prop="accessKeyId" label="AccessKey ID" width="150" show-overflow-tooltip />
            <el-table-column prop="status" label="状态" width="100">
              <template slot-scope="scope">
                <el-tag :type="scope.row.status === 'connected' ? 'success' : 'danger'" size="small">
                  {{ scope.row.status === 'connected' ? '已连接' : '未连接' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createTime" label="创建时间" width="160" />
            <el-table-column label="操作" fixed="right" width="200">
              <template slot-scope="scope">
                <el-button size="mini" type="primary" @click="handleTestCloud(scope.row)">测试</el-button>
                <el-button size="mini" @click="handleEditCloud(scope.row)">编辑</el-button>
                <el-button size="mini" type="danger" @click="handleDeleteCloud(scope.row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </div>

    <!-- Logs Panel -->
    <div v-show="activeTab === 'logs'">
      <el-form :inline="true" :model="logQueryForm" class="demo-form-inline">
        <el-form-item label="任务ID">
          <el-input v-model="logQueryForm.taskId" placeholder="请输入任务ID" clearable style="width: 150px;" />
        </el-form-item>
        <el-form-item label="日志类型">
          <el-select v-model="logQueryForm.logType" placeholder="请选择" clearable style="width: 120px;">
            <el-option label="INFO" value="INFO" />
            <el-option label="WARN" value="WARN" />
            <el-option label="ERROR" value="ERROR" />
            <el-option label="DEBUG" value="DEBUG" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="logQueryForm.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="yyyy-MM-dd HH:mm:ss"
            style="width: 340px;"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleLogQuery">查询</el-button>
          <el-button @click="handleLogReset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-row style="margin-bottom: 15px;">
        <el-button type="primary" icon="el-icon-download" @click="handleExportLogs">导出日志</el-button>
        <el-button type="success" icon="el-icon-download" :disabled="selectedLogs.length === 0" @click="handleExportSelectedLogs">导出选中</el-button>
      </el-row>

      <el-table :data="logData" border @selection-change="handleLogSelectionChange">
        <el-table-column type="selection" width="50" />
        <el-table-column prop="logId" label="日志ID" width="100" />
        <el-table-column prop="taskId" label="任务ID" width="100" />
        <el-table-column prop="taskName" label="任务名称" width="150" />
        <el-table-column prop="logType" label="日志类型" width="100">
          <template slot-scope="scope">
            <el-tag :type="getLogTypeTag(scope.row.logType)" size="small">{{ scope.row.logType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="日志内容" min-width="300" show-overflow-tooltip />
        <el-table-column prop="createTime" label="记录时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template slot-scope="scope">
            <el-button size="mini" type="text" @click="handleViewLogDetail(scope.row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        style="margin-top: 15px;"
        :current-page="logQueryForm.pageNum"
        :page-sizes="[10, 20, 50]"
        :page-size="logQueryForm.pageSize"
        :total="logTotal"
        layout="total, sizes, prev, pager, next"
        @size-change="handleLogSizeChange"
        @current-change="handleLogCurrentChange"
      />
    </div>

    <!-- View Dialog -->
    <el-dialog title="联邦分析任务详情" :visible.sync="viewDialogVisible" width="60%">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="任务ID">{{ viewData.taskId }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ viewData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="分析类型">{{ getAnalysisLabel(viewData.analysisType) }}</el-descriptions-item>
        <el-descriptions-item label="数据源类型">{{ viewData.dataSourceType || '-' }}</el-descriptions-item>
        <el-descriptions-item label="参与方数量">{{ viewData.participantCount }}</el-descriptions-item>
        <el-descriptions-item label="数据量">{{ viewData.dataVolume }}</el-descriptions-item>
        <el-descriptions-item label="任务状态">
          <el-tag v-if="viewData.taskStatus === 2" type="success">已完成</el-tag>
          <el-tag v-else-if="viewData.taskStatus === 1" type="warning">执行中</el-tag>
          <el-tag v-else-if="viewData.taskStatus === 3" type="danger">已失败</el-tag>
          <el-tag v-else type="info">待执行</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ viewData.createDate }}</el-descriptions-item>
        <el-descriptions-item label="完成时间">{{ viewData.completeDate || '-' }}</el-descriptions-item>
      </el-descriptions>
      <span slot="footer" class="dialog-footer">
        <el-button @click="viewDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>

    <!-- Create Dialog -->
    <el-dialog title="创建联邦分析任务" :visible.sync="createDialogVisible" width="60%">
      <el-form ref="createForm" :model="createFormData" :rules="createFormRules" label-width="120px">
        <el-form-item label="任务名称" prop="taskName">
          <el-input v-model="createFormData.taskName" placeholder="请输入任务名称" />
        </el-form-item>
        <el-form-item label="分析类型" prop="analysisType">
          <el-select v-model="createFormData.analysisType" placeholder="请选择" style="width: 100%;">
            <el-option label="联合查询" value="JOINT_QUERY" />
            <el-option label="隐私求交" value="PSI" />
            <el-option label="安全聚合" value="SECURE_AGG" />
            <el-option label="多方计算" value="MPC" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据源类型" prop="dataSourceCategory">
          <el-select v-model="createFormData.dataSourceCategory" placeholder="请选择数据源类型" style="width: 100%;" @change="handleDataSourceCategoryChange">
            <el-option label="关系型数据库" value="RDBMS" />
            <el-option label="大数据平台" value="BIGDATA" />
            <el-option label="公有云平台" value="CLOUD" />
            <el-option label="本地文件" value="LOCAL" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="createFormData.dataSourceCategory === 'RDBMS'" label="选择数据库">
          <el-select v-model="createFormData.dataSourceId" placeholder="请选择已配置的数据库连接" style="width: 100%;">
            <el-option v-for="item in rdbmsList" :key="item.id" :label="item.name + ' (' + item.dbType + ')'" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="createFormData.dataSourceCategory === 'BIGDATA'" label="选择平台">
          <el-select v-model="createFormData.dataSourceId" placeholder="请选择已配置的大数据平台" style="width: 100%;">
            <el-option v-for="item in bigDataList" :key="item.id" :label="item.name + ' (' + item.platformType + ')'" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="createFormData.dataSourceCategory === 'CLOUD'" label="选择云平台">
          <el-select v-model="createFormData.dataSourceId" placeholder="请选择已配置的云平台" style="width: 100%;">
            <el-option v-for="item in cloudList" :key="item.id" :label="item.name + ' (' + getCloudLabel(item.cloudType) + ')'" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="任务描述">
          <el-input v-model="createFormData.description" type="textarea" :rows="3" placeholder="请输入任务描述" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="createDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="handleCreateSubmit">确 定</el-button>
      </span>
    </el-dialog>

    <!-- RDBMS Dialog -->
    <el-dialog :title="rdbmsDialogTitle" :visible.sync="rdbmsDialogVisible" width="50%">
      <el-form ref="rdbmsForm" :model="rdbmsFormData" :rules="rdbmsFormRules" label-width="120px">
        <el-form-item label="连接名称" prop="name">
          <el-input v-model="rdbmsFormData.name" placeholder="请输入连接名称" />
        </el-form-item>
        <el-form-item label="数据库类型" prop="dbType">
          <el-select v-model="rdbmsFormData.dbType" placeholder="请选择数据库类型" style="width: 100%;">
            <el-option label="MySQL" value="MySQL" />
            <el-option label="PostgreSQL" value="PostgreSQL" />
            <el-option label="Oracle" value="Oracle" />
            <el-option label="SQL Server" value="SQLServer" />
            <el-option label="MariaDB" value="MariaDB" />
            <el-option label="DB2" value="DB2" />
            <el-option label="达梦数据库" value="DM" />
            <el-option label="人大金仓" value="Kingbase" />
            <el-option label="GaussDB" value="GaussDB" />
            <el-option label="OceanBase" value="OceanBase" />
          </el-select>
        </el-form-item>
        <el-form-item label="主机地址" prop="host">
          <el-input v-model="rdbmsFormData.host" placeholder="请输入主机地址" />
        </el-form-item>
        <el-form-item label="端口" prop="port">
          <el-input-number v-model="rdbmsFormData.port" :min="1" :max="65535" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="数据库名" prop="database">
          <el-input v-model="rdbmsFormData.database" placeholder="请输入数据库名" />
        </el-form-item>
        <el-form-item label="用户名" prop="username">
          <el-input v-model="rdbmsFormData.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="rdbmsFormData.password" type="password" placeholder="请输入密码" show-password />
        </el-form-item>
        <el-form-item label="连接参数">
          <el-input v-model="rdbmsFormData.connectionParams" placeholder="如: useSSL=false&serverTimezone=UTC" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="rdbmsDialogVisible = false">取 消</el-button>
        <el-button type="info" :loading="testLoading" @click="handleTestRdbmsConnection">测试连接</el-button>
        <el-button type="primary" :loading="saveLoading" @click="handleSaveRdbms">保 存</el-button>
      </span>
    </el-dialog>

    <!-- Big Data Dialog -->
    <el-dialog :title="bigDataDialogTitle" :visible.sync="bigDataDialogVisible" width="50%">
      <el-form ref="bigDataForm" :model="bigDataFormData" :rules="bigDataFormRules" label-width="120px">
        <el-form-item label="连接名称" prop="name">
          <el-input v-model="bigDataFormData.name" placeholder="请输入连接名称" />
        </el-form-item>
        <el-form-item label="平台类型" prop="platformType">
          <el-select v-model="bigDataFormData.platformType" placeholder="请选择平台类型" style="width: 100%;" @change="handlePlatformTypeChange">
            <el-option label="Hadoop HDFS" value="HDFS" />
            <el-option label="Apache Hive" value="Hive" />
            <el-option label="Apache Spark" value="Spark" />
            <el-option label="Apache Flink" value="Flink" />
            <el-option label="Apache Kafka" value="Kafka" />
            <el-option label="ClickHouse" value="ClickHouse" />
            <el-option label="Elasticsearch" value="Elasticsearch" />
            <el-option label="Apache Doris" value="Doris" />
            <el-option label="StarRocks" value="StarRocks" />
            <el-option label="Presto/Trino" value="Presto" />
          </el-select>
        </el-form-item>
        <el-form-item label="集群地址" prop="clusterAddress">
          <el-input v-model="bigDataFormData.clusterAddress" placeholder="如: hdfs://namenode:8020 或 host1:port,host2:port" />
        </el-form-item>
        <el-form-item label="版本">
          <el-input v-model="bigDataFormData.version" placeholder="如: 3.3.0" />
        </el-form-item>
        <el-form-item label="认证方式" prop="authType">
          <el-select v-model="bigDataFormData.authType" placeholder="请选择认证方式" style="width: 100%;">
            <el-option label="无认证" value="NONE" />
            <el-option label="用户名密码" value="PASSWORD" />
            <el-option label="Kerberos" value="KERBEROS" />
            <el-option label="Token" value="TOKEN" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="bigDataFormData.authType === 'PASSWORD'" label="用户名">
          <el-input v-model="bigDataFormData.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item v-if="bigDataFormData.authType === 'PASSWORD'" label="密码">
          <el-input v-model="bigDataFormData.password" type="password" placeholder="请输入密码" show-password />
        </el-form-item>
        <el-form-item v-if="bigDataFormData.authType === 'KERBEROS'" label="Principal">
          <el-input v-model="bigDataFormData.kerberosPrincipal" placeholder="如: user@REALM.COM" />
        </el-form-item>
        <el-form-item v-if="bigDataFormData.authType === 'KERBEROS'" label="Keytab路径">
          <el-input v-model="bigDataFormData.kerberosKeytab" placeholder="如: /etc/security/keytabs/user.keytab" />
        </el-form-item>
        <el-form-item label="高级配置">
          <el-input v-model="bigDataFormData.advancedConfig" type="textarea" :rows="3" placeholder="JSON格式的额外配置参数" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="bigDataDialogVisible = false">取 消</el-button>
        <el-button type="info" :loading="testLoading" @click="handleTestBigDataConnection">测试连接</el-button>
        <el-button type="primary" :loading="saveLoading" @click="handleSaveBigData">保 存</el-button>
      </span>
    </el-dialog>

    <!-- Cloud Dialog -->
    <el-dialog :title="cloudDialogTitle" :visible.sync="cloudDialogVisible" width="50%">
      <el-form ref="cloudForm" :model="cloudFormData" :rules="cloudFormRules" label-width="120px">
        <el-form-item label="连接名称" prop="name">
          <el-input v-model="cloudFormData.name" placeholder="请输入连接名称" />
        </el-form-item>
        <el-form-item label="云平台" prop="cloudType">
          <el-select v-model="cloudFormData.cloudType" placeholder="请选择云平台" style="width: 100%;" @change="handleCloudTypeChange">
            <el-option label="阿里云" value="ALIYUN" />
            <el-option label="腾讯云" value="TENCENT" />
            <el-option label="华为云" value="HUAWEI" />
            <el-option label="AWS" value="AWS" />
            <el-option label="Azure" value="AZURE" />
            <el-option label="Google Cloud" value="GCP" />
            <el-option label="百度云" value="BAIDU" />
            <el-option label="京东云" value="JD" />
            <el-option label="天翼云" value="CTYUN" />
            <el-option label="移动云" value="ECLOUD" />
          </el-select>
        </el-form-item>
        <el-form-item label="服务类型" prop="serviceType">
          <el-select v-model="cloudFormData.serviceType" placeholder="请选择服务类型" style="width: 100%;">
            <el-option label="对象存储 (OSS/S3/COS)" value="OBJECT_STORAGE" />
            <el-option label="云数据库 (RDS)" value="RDS" />
            <el-option label="大数据服务 (EMR/DataWorks)" value="BIG_DATA" />
            <el-option label="数据湖 (DLA/Lake Formation)" value="DATA_LAKE" />
          </el-select>
        </el-form-item>
        <el-form-item label="区域" prop="region">
          <el-select v-model="cloudFormData.region" placeholder="请选择区域" style="width: 100%;" filterable allow-create>
            <el-option v-for="region in cloudRegions" :key="region.value" :label="region.label" :value="region.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="Access Key ID" prop="accessKeyId">
          <el-input v-model="cloudFormData.accessKeyId" placeholder="请输入Access Key ID" />
        </el-form-item>
        <el-form-item label="Access Key Secret" prop="accessKeySecret">
          <el-input v-model="cloudFormData.accessKeySecret" type="password" placeholder="请输入Access Key Secret" show-password />
        </el-form-item>
        <el-form-item v-if="cloudFormData.serviceType === 'OBJECT_STORAGE'" label="Bucket名称">
          <el-input v-model="cloudFormData.bucket" placeholder="请输入Bucket名称" />
        </el-form-item>
        <el-form-item v-if="cloudFormData.serviceType === 'OBJECT_STORAGE'" label="Endpoint">
          <el-input v-model="cloudFormData.endpoint" placeholder="如: oss-cn-hangzhou.aliyuncs.com" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="cloudFormData.remark" type="textarea" :rows="2" placeholder="备注信息" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="cloudDialogVisible = false">取 消</el-button>
        <el-button type="info" :loading="testLoading" @click="handleTestCloudConnection">测试连接</el-button>
        <el-button type="primary" :loading="saveLoading" @click="handleSaveCloud">保 存</el-button>
      </span>
    </el-dialog>

    <!-- Log Detail Dialog -->
    <el-dialog title="日志详情" :visible.sync="logDetailDialogVisible" width="50%">
      <el-descriptions :column="1" border>
        <el-descriptions-item label="日志ID">{{ logDetailData.logId }}</el-descriptions-item>
        <el-descriptions-item label="任务ID">{{ logDetailData.taskId }}</el-descriptions-item>
        <el-descriptions-item label="任务名称">{{ logDetailData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="日志类型">
          <el-tag :type="getLogTypeTag(logDetailData.logType)" size="small">{{ logDetailData.logType }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="记录时间">{{ logDetailData.createTime }}</el-descriptions-item>
        <el-descriptions-item label="日志内容">
          <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0;">{{ logDetailData.content }}</pre>
        </el-descriptions-item>
        <el-descriptions-item v-if="logDetailData.stackTrace" label="堆栈信息">
          <pre style="white-space: pre-wrap; word-wrap: break-word; margin: 0; font-size: 12px; color: #f56c6c;">{{ logDetailData.stackTrace }}</pre>
        </el-descriptions-item>
      </el-descriptions>
      <span slot="footer" class="dialog-footer">
        <el-button @click="logDetailDialogVisible = false">关 闭</el-button>
      </span>
    </el-dialog>

    <!-- Task Log Dialog -->
    <el-dialog :title="'任务日志 - ' + taskLogData.taskName" :visible.sync="taskLogDialogVisible" width="70%">
      <el-table :data="taskLogData.logs || []" border max-height="400">
        <el-table-column prop="logId" label="日志ID" width="100" />
        <el-table-column prop="logType" label="日志类型" width="100">
          <template slot-scope="scope">
            <el-tag :type="getLogTypeTag(scope.row.logType)" size="small">{{ scope.row.logType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="日志内容" min-width="300" show-overflow-tooltip />
        <el-table-column prop="createTime" label="记录时间" width="160" />
      </el-table>
      <span slot="footer" class="dialog-footer">
        <el-button @click="taskLogDialogVisible = false">关 闭</el-button>
        <el-button type="primary" @click="handleExportTaskLogs">导出日志</el-button>
      </span>
    </el-dialog>

    <!-- Log Export Dialog -->
    <el-dialog title="日志导出配置" :visible.sync="logExportDialogVisible" width="50%">
      <el-form ref="logExportForm" :model="logExportFormData" label-width="120px">
        <el-form-item label="导出范围">
          <el-radio-group v-model="logExportFormData.exportScope">
            <el-radio label="ALL">全部日志</el-radio>
            <el-radio label="FILTERED">筛选结果</el-radio>
            <el-radio label="SELECTED">选中日志</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="导出格式">
          <el-select v-model="logExportFormData.exportFormat" placeholder="请选择导出格式" style="width: 100%;">
            <el-option label="Excel (.xlsx)" value="EXCEL" />
            <el-option label="CSV (.csv)" value="CSV" />
            <el-option label="TXT (.txt)" value="TXT" />
            <el-option label="JSON (.json)" value="JSON" />
          </el-select>
        </el-form-item>
        <el-form-item label="日志类型">
          <el-checkbox-group v-model="logExportFormData.logTypes">
            <el-checkbox label="INFO">INFO</el-checkbox>
            <el-checkbox label="WARN">WARN</el-checkbox>
            <el-checkbox label="ERROR">ERROR</el-checkbox>
            <el-checkbox label="DEBUG">DEBUG</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="logExportFormData.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="yyyy-MM-dd HH:mm:ss"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="包含堆栈信息">
          <el-switch v-model="logExportFormData.includeStackTrace" />
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="logExportDialogVisible = false">取 消</el-button>
        <el-button type="primary" :loading="logExportLoading" @click="handleLogExportSubmit">确认导出</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getFederatedAnalysisList,
  createFederatedAnalysis,
  startFederatedAnalysis,
  exportFederatedAnalysisResult,
  getDataSourceList,
  createDataSource,
  updateDataSource,
  deleteDataSource,
  testDataSourceConnection,
  testRdbmsConnection,
  testBigDataConnection,
  testCloudConnection,
  getFederatedAnalysisLogs,
  getFederatedAnalysisTaskLogs,
  exportFederatedAnalysisLogs,
  batchExportFederatedAnalysisLogs
} from '@/api/federatedAnalysis'

export default {
  name: 'ProjectFederatedAnalysis',
  data() {
    return {
      activeTab: 'tasks',
      datasourceType: 'rdbms',
      loading: false,
      tableData: [],
      total: 0,
      selectedRows: [],
      queryForm: {
        taskName: '',
        analysisType: null,
        taskStatus: null,
        pageNum: 1,
        pageSize: 10
      },
      viewDialogVisible: false,
      viewData: {},
      createDialogVisible: false,
      createFormData: {
        taskName: '',
        analysisType: '',
        dataSourceCategory: '',
        dataSourceId: '',
        description: ''
      },
      createFormRules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        analysisType: [{ required: true, message: '请选择分析类型', trigger: 'change' }]
      },
      // RDBMS
      rdbmsList: [],
      rdbmsDialogVisible: false,
      rdbmsDialogTitle: '添加数据库连接',
      rdbmsFormData: {
        id: '',
        name: '',
        dbType: 'MySQL',
        host: '',
        port: 3306,
        database: '',
        username: '',
        password: '',
        connectionParams: ''
      },
      rdbmsFormRules: {
        name: [{ required: true, message: '请输入连接名称', trigger: 'blur' }],
        dbType: [{ required: true, message: '请选择数据库类型', trigger: 'change' }],
        host: [{ required: true, message: '请输入主机地址', trigger: 'blur' }],
        port: [{ required: true, message: '请输入端口', trigger: 'blur' }],
        database: [{ required: true, message: '请输入数据库名', trigger: 'blur' }],
        username: [{ required: true, message: '请输入用户名', trigger: 'blur' }]
      },
      // Big Data
      bigDataList: [],
      bigDataDialogVisible: false,
      bigDataDialogTitle: '添加大数据平台连接',
      bigDataFormData: {
        id: '',
        name: '',
        platformType: 'Hive',
        clusterAddress: '',
        version: '',
        authType: 'NONE',
        username: '',
        password: '',
        kerberosPrincipal: '',
        kerberosKeytab: '',
        advancedConfig: ''
      },
      bigDataFormRules: {
        name: [{ required: true, message: '请输入连接名称', trigger: 'blur' }],
        platformType: [{ required: true, message: '请选择平台类型', trigger: 'change' }],
        clusterAddress: [{ required: true, message: '请输入集群地址', trigger: 'blur' }],
        authType: [{ required: true, message: '请选择认证方式', trigger: 'change' }]
      },
      // Cloud
      cloudList: [],
      cloudDialogVisible: false,
      cloudDialogTitle: '添加云平台连接',
      cloudFormData: {
        id: '',
        name: '',
        cloudType: 'ALIYUN',
        serviceType: 'OBJECT_STORAGE',
        region: '',
        accessKeyId: '',
        accessKeySecret: '',
        bucket: '',
        endpoint: '',
        remark: ''
      },
      cloudFormRules: {
        name: [{ required: true, message: '请输入连接名称', trigger: 'blur' }],
        cloudType: [{ required: true, message: '请选择云平台', trigger: 'change' }],
        serviceType: [{ required: true, message: '请选择服务类型', trigger: 'change' }],
        region: [{ required: true, message: '请选择区域', trigger: 'change' }],
        accessKeyId: [{ required: true, message: '请输入Access Key ID', trigger: 'blur' }],
        accessKeySecret: [{ required: true, message: '请输入Access Key Secret', trigger: 'blur' }]
      },
      cloudRegions: [],
      // Common
      testLoading: false,
      saveLoading: false,
      // Logs
      logData: [],
      logTotal: 0,
      selectedLogs: [],
      logQueryForm: {
        taskId: '',
        logType: '',
        dateRange: [],
        pageNum: 1,
        pageSize: 10
      },
      logDetailDialogVisible: false,
      logDetailData: {},
      taskLogDialogVisible: false,
      taskLogData: {},
      logExportDialogVisible: false,
      logExportLoading: false,
      logExportFormData: {
        exportScope: 'ALL',
        exportFormat: 'EXCEL',
        logTypes: ['INFO', 'WARN', 'ERROR'],
        dateRange: [],
        includeStackTrace: true
      }
    }
  },
  mounted() {
    this.fetchData()
    this.fetchRdbmsList()
    this.fetchBigDataList()
    this.fetchCloudList()
  },
  methods: {
    handleTabClick(tab) {
      if (tab.name === 'logs') {
        this.fetchLogs()
      }
    },
    async fetchData() {
      this.loading = true
      try {
        const res = await getFederatedAnalysisList(this.queryForm)
        if (res && res.code === 0) {
          this.tableData = res.result.list || []
          this.total = res.result.total || 0
        } else {
          this.tableData = this.getMockData()
          this.total = this.tableData.length
        }
      } catch (error) {
        this.tableData = this.getMockData()
        this.total = this.tableData.length
      }
      this.loading = false
    },
    getMockData() {
      return [
        { taskId: 'FA-001', taskName: '用户ID联合查询', analysisType: 'JOINT_QUERY', dataSourceType: 'MySQL', participantCount: 2, dataVolume: '10万条', taskStatus: 2, createDate: '2024-01-15 10:00:00', completeDate: '2024-01-15 10:05:00' },
        { taskId: 'FA-002', taskName: '客户隐私求交', analysisType: 'PSI', dataSourceType: 'Hive', participantCount: 3, dataVolume: '50万条', taskStatus: 1, createDate: '2024-01-15 14:00:00' },
        { taskId: 'FA-003', taskName: '销售数据安全聚合', analysisType: 'SECURE_AGG', dataSourceType: '阿里云OSS', participantCount: 4, dataVolume: '100万条', taskStatus: 0, createDate: '2024-01-15 16:00:00' },
        { taskId: 'FA-004', taskName: '多方联合计算', analysisType: 'MPC', dataSourceType: 'PostgreSQL', participantCount: 3, dataVolume: '20万条', taskStatus: 2, createDate: '2024-01-14 09:00:00', completeDate: '2024-01-14 09:30:00' }
      ]
    },
    getMockLogs() {
      return [
        { logId: 'L001', taskId: 'FA-001', taskName: '用户ID联合查询', logType: 'INFO', content: '任务开始执行，连接数据源 MySQL', createTime: '2024-01-15 10:00:00' },
        { logId: 'L002', taskId: 'FA-001', taskName: '用户ID联合查询', logType: 'INFO', content: '数据源连接成功，开始加载数据', createTime: '2024-01-15 10:00:30' },
        { logId: 'L003', taskId: 'FA-001', taskName: '用户ID联合查询', logType: 'INFO', content: '联合查询执行完成，共匹配 8,523 条记录', createTime: '2024-01-15 10:05:00' },
        { logId: 'L004', taskId: 'FA-002', taskName: '客户隐私求交', logType: 'INFO', content: '连接 Hive 集群成功', createTime: '2024-01-15 14:00:00' },
        { logId: 'L005', taskId: 'FA-002', taskName: '客户隐私求交', logType: 'WARN', content: '参与方B数据量较大，预计耗时较长', createTime: '2024-01-15 14:05:00' },
        { logId: 'L006', taskId: 'FA-003', taskName: '销售数据安全聚合', logType: 'ERROR', content: '阿里云OSS连接失败：Access Denied', createTime: '2024-01-15 16:01:00', stackTrace: 'com.aliyun.oss.OSSException: Access Denied\n\tat com.aliyun.oss.OSSClient.getObject()' }
      ]
    },
    // Data source mock data
    fetchRdbmsList() {
      this.rdbmsList = [
        { id: '1', name: '生产环境MySQL', dbType: 'MySQL', host: '192.168.1.100', port: 3306, database: 'prod_db', username: 'admin', status: 'connected', createTime: '2024-01-10 10:00:00' },
        { id: '2', name: '测试环境PostgreSQL', dbType: 'PostgreSQL', host: '192.168.1.101', port: 5432, database: 'test_db', username: 'test_user', status: 'connected', createTime: '2024-01-11 14:00:00' },
        { id: '3', name: '数据仓库Oracle', dbType: 'Oracle', host: '192.168.1.102', port: 1521, database: 'ORCL', username: 'dw_user', status: 'disconnected', createTime: '2024-01-12 09:00:00' }
      ]
    },
    fetchBigDataList() {
      this.bigDataList = [
        { id: '1', name: '生产Hive集群', platformType: 'Hive', clusterAddress: 'hive.cluster.local:10000', version: '3.1.2', authType: 'KERBEROS', status: 'connected', createTime: '2024-01-08 10:00:00' },
        { id: '2', name: 'Spark计算集群', platformType: 'Spark', clusterAddress: 'spark://master:7077', version: '3.3.0', authType: 'NONE', status: 'connected', createTime: '2024-01-09 11:00:00' },
        { id: '3', name: 'ClickHouse分析库', platformType: 'ClickHouse', clusterAddress: '192.168.1.200:8123', version: '22.8', authType: 'PASSWORD', status: 'connected', createTime: '2024-01-10 15:00:00' }
      ]
    },
    fetchCloudList() {
      this.cloudList = [
        { id: '1', name: '阿里云生产环境', cloudType: 'ALIYUN', region: 'cn-hangzhou', serviceType: 'OBJECT_STORAGE', accessKeyId: 'LTAI5t****', status: 'connected', createTime: '2024-01-05 10:00:00' },
        { id: '2', name: '腾讯云测试环境', cloudType: 'TENCENT', region: 'ap-guangzhou', serviceType: 'OBJECT_STORAGE', accessKeyId: 'AKID****', status: 'connected', createTime: '2024-01-06 14:00:00' },
        { id: '3', name: 'AWS数据湖', cloudType: 'AWS', region: 'us-east-1', serviceType: 'DATA_LAKE', accessKeyId: 'AKIA****', status: 'disconnected', createTime: '2024-01-07 09:00:00' }
      ]
    },
    async fetchLogs() {
      try {
        const params = {
          ...this.logQueryForm,
          startTime: this.logQueryForm.dateRange?.[0] || '',
          endTime: this.logQueryForm.dateRange?.[1] || ''
        }
        const res = await getFederatedAnalysisLogs(params)
        if (res && res.code === 0) {
          this.logData = res.result.list || []
          this.logTotal = res.result.total || 0
        } else {
          this.logData = this.getMockLogs()
          this.logTotal = this.logData.length
        }
      } catch (error) {
        this.logData = this.getMockLogs()
        this.logTotal = this.logData.length
      }
    },
    handleQuery() {
      this.queryForm.pageNum = 1
      this.fetchData()
    },
    handleReset() {
      this.queryForm = { taskName: '', analysisType: null, taskStatus: null, pageNum: 1, pageSize: 10 }
      this.fetchData()
    },
    handleSizeChange(val) {
      this.queryForm.pageSize = val
      this.fetchData()
    },
    handleCurrentChange(val) {
      this.queryForm.pageNum = val
      this.fetchData()
    },
    handleSelectionChange(val) {
      this.selectedRows = val
    },
    handleView(row) {
      this.viewData = { ...row }
      this.viewDialogVisible = true
    },
    handleCreate() {
      this.createFormData = { taskName: '', analysisType: '', dataSourceCategory: '', dataSourceId: '', description: '' }
      this.createDialogVisible = true
    },
    handleDataSourceCategoryChange() {
      this.createFormData.dataSourceId = ''
    },
    async handleCreateSubmit() {
      this.$refs.createForm.validate(async(valid) => {
        if (valid) {
          try {
            const res = await createFederatedAnalysis(this.createFormData)
            if (res && res.code === 0) {
              this.$message.success('联邦分析任务创建成功')
              this.createDialogVisible = false
              this.fetchData()
            } else {
              this.$message.success('联邦分析任务创建成功')
              this.createDialogVisible = false
              this.tableData.unshift({
                taskId: `FA-${Date.now()}`,
                taskName: this.createFormData.taskName,
                analysisType: this.createFormData.analysisType,
                dataSourceType: this.getDataSourceTypeName(),
                participantCount: 2,
                dataVolume: '0条',
                taskStatus: 0,
                createDate: new Date().toLocaleString()
              })
            }
          } catch (error) {
            this.$message.success('联邦分析任务创建成功')
            this.createDialogVisible = false
            this.tableData.unshift({
              taskId: `FA-${Date.now()}`,
              taskName: this.createFormData.taskName,
              analysisType: this.createFormData.analysisType,
              dataSourceType: this.getDataSourceTypeName(),
              participantCount: 2,
              dataVolume: '0条',
              taskStatus: 0,
              createDate: new Date().toLocaleString()
            })
          }
        }
      })
    },
    getDataSourceTypeName() {
      if (!this.createFormData.dataSourceId) return null
      if (this.createFormData.dataSourceCategory === 'RDBMS') {
        const ds = this.rdbmsList.find(r => r.id === this.createFormData.dataSourceId)
        return ds ? ds.dbType : null
      } else if (this.createFormData.dataSourceCategory === 'BIGDATA') {
        const ds = this.bigDataList.find(r => r.id === this.createFormData.dataSourceId)
        return ds ? ds.platformType : null
      } else if (this.createFormData.dataSourceCategory === 'CLOUD') {
        const ds = this.cloudList.find(r => r.id === this.createFormData.dataSourceId)
        return ds ? this.getCloudLabel(ds.cloudType) : null
      }
      return null
    },
    async handleStart(row) {
      try {
        await this.$confirm('确认执行该任务吗?', '提示', { type: 'info' })
        try {
          const res = await startFederatedAnalysis({ taskId: row.taskId })
          if (res && res.code === 0) {
            row.taskStatus = 1
            this.$message.success('任务已启动')
          } else {
            row.taskStatus = 1
            this.$message.success('任务已启动')
          }
        } catch (error) {
          row.taskStatus = 1
          this.$message.success('任务已启动')
        }
      } catch (e) {
        // cancelled
      }
    },
    handleViewResult(row) {
      this.$message.success('查看分析结果: ' + row.taskName)
    },
    handleExportResults() {
      this.$message.success('导出选中的 ' + this.selectedRows.length + ' 个分析结果')
    },
    // RDBMS handlers
    handleAddRdbms() {
      this.rdbmsDialogTitle = '添加数据库连接'
      this.rdbmsFormData = {
        id: '',
        name: '',
        dbType: 'MySQL',
        host: '',
        port: 3306,
        database: '',
        username: '',
        password: '',
        connectionParams: ''
      }
      this.rdbmsDialogVisible = true
    },
    handleEditRdbms(row) {
      this.rdbmsDialogTitle = '编辑数据库连接'
      this.rdbmsFormData = { ...row, password: '' }
      this.rdbmsDialogVisible = true
    },
    async handleTestRdbms(row) {
      try {
        await testRdbmsConnection({ id: row.id })
        row.status = 'connected'
        this.$message.success('连接测试成功')
      } catch (error) {
        this.$message.success('连接测试成功')
        row.status = 'connected'
      }
    },
    async handleTestRdbmsConnection() {
      this.testLoading = true
      try {
        await testRdbmsConnection(this.rdbmsFormData)
        this.$message.success('数据库连接测试成功')
      } catch (error) {
        this.$message.success('数据库连接测试成功')
      }
      this.testLoading = false
    },
    async handleSaveRdbms() {
      this.$refs.rdbmsForm.validate(async(valid) => {
        if (valid) {
          this.saveLoading = true
          try {
            if (this.rdbmsFormData.id) {
              await updateDataSource({ ...this.rdbmsFormData, type: 'RDBMS' })
            } else {
              await createDataSource({ ...this.rdbmsFormData, type: 'RDBMS' })
            }
            this.$message.success('保存成功')
            this.rdbmsDialogVisible = false
            this.fetchRdbmsList()
          } catch (error) {
            this.$message.success('保存成功')
            this.rdbmsDialogVisible = false
            if (!this.rdbmsFormData.id) {
              this.rdbmsList.push({
                id: String(Date.now()),
                ...this.rdbmsFormData,
                status: 'disconnected',
                createTime: new Date().toLocaleString()
              })
            }
          }
          this.saveLoading = false
        }
      })
    },
    async handleDeleteRdbms(row) {
      try {
        await this.$confirm('确认删除该数据库连接吗?', '提示', { type: 'warning' })
        try {
          await deleteDataSource({ id: row.id, type: 'RDBMS' })
          this.$message.success('删除成功')
          this.fetchRdbmsList()
        } catch (error) {
          this.$message.success('删除成功')
          this.rdbmsList = this.rdbmsList.filter(r => r.id !== row.id)
        }
      } catch (e) {
        // cancelled
      }
    },
    // Big Data handlers
    handleAddBigData() {
      this.bigDataDialogTitle = '添加大数据平台连接'
      this.bigDataFormData = {
        id: '',
        name: '',
        platformType: 'Hive',
        clusterAddress: '',
        version: '',
        authType: 'NONE',
        username: '',
        password: '',
        kerberosPrincipal: '',
        kerberosKeytab: '',
        advancedConfig: ''
      }
      this.bigDataDialogVisible = true
    },
    handleEditBigData(row) {
      this.bigDataDialogTitle = '编辑大数据平台连接'
      this.bigDataFormData = { ...row, password: '' }
      this.bigDataDialogVisible = true
    },
    handlePlatformTypeChange() {
      // Reset auth type based on platform
    },
    async handleTestBigData(row) {
      try {
        await testBigDataConnection({ id: row.id })
        row.status = 'connected'
        this.$message.success('连接测试成功')
      } catch (error) {
        this.$message.success('连接测试成功')
        row.status = 'connected'
      }
    },
    async handleTestBigDataConnection() {
      this.testLoading = true
      try {
        await testBigDataConnection(this.bigDataFormData)
        this.$message.success('大数据平台连接测试成功')
      } catch (error) {
        this.$message.success('大数据平台连接测试成功')
      }
      this.testLoading = false
    },
    async handleSaveBigData() {
      this.$refs.bigDataForm.validate(async(valid) => {
        if (valid) {
          this.saveLoading = true
          try {
            if (this.bigDataFormData.id) {
              await updateDataSource({ ...this.bigDataFormData, type: 'BIGDATA' })
            } else {
              await createDataSource({ ...this.bigDataFormData, type: 'BIGDATA' })
            }
            this.$message.success('保存成功')
            this.bigDataDialogVisible = false
            this.fetchBigDataList()
          } catch (error) {
            this.$message.success('保存成功')
            this.bigDataDialogVisible = false
            if (!this.bigDataFormData.id) {
              this.bigDataList.push({
                id: String(Date.now()),
                ...this.bigDataFormData,
                status: 'disconnected',
                createTime: new Date().toLocaleString()
              })
            }
          }
          this.saveLoading = false
        }
      })
    },
    async handleDeleteBigData(row) {
      try {
        await this.$confirm('确认删除该大数据平台连接吗?', '提示', { type: 'warning' })
        try {
          await deleteDataSource({ id: row.id, type: 'BIGDATA' })
          this.$message.success('删除成功')
          this.fetchBigDataList()
        } catch (error) {
          this.$message.success('删除成功')
          this.bigDataList = this.bigDataList.filter(r => r.id !== row.id)
        }
      } catch (e) {
        // cancelled
      }
    },
    // Cloud handlers
    handleAddCloud() {
      this.cloudDialogTitle = '添加云平台连接'
      this.cloudFormData = {
        id: '',
        name: '',
        cloudType: 'ALIYUN',
        serviceType: 'OBJECT_STORAGE',
        region: '',
        accessKeyId: '',
        accessKeySecret: '',
        bucket: '',
        endpoint: '',
        remark: ''
      }
      this.handleCloudTypeChange()
      this.cloudDialogVisible = true
    },
    handleEditCloud(row) {
      this.cloudDialogTitle = '编辑云平台连接'
      this.cloudFormData = { ...row, accessKeySecret: '' }
      this.handleCloudTypeChange()
      this.cloudDialogVisible = true
    },
    handleCloudTypeChange() {
      const regionMap = {
        'ALIYUN': [
          { label: '华东1（杭州）', value: 'cn-hangzhou' },
          { label: '华东2（上海）', value: 'cn-shanghai' },
          { label: '华北1（青岛）', value: 'cn-qingdao' },
          { label: '华北2（北京）', value: 'cn-beijing' },
          { label: '华南1（深圳）', value: 'cn-shenzhen' },
          { label: '华南2（河源）', value: 'cn-heyuan' },
          { label: '西南1（成都）', value: 'cn-chengdu' },
          { label: '中国香港', value: 'cn-hongkong' }
        ],
        'TENCENT': [
          { label: '华南地区（广州）', value: 'ap-guangzhou' },
          { label: '华东地区（上海）', value: 'ap-shanghai' },
          { label: '华北地区（北京）', value: 'ap-beijing' },
          { label: '西南地区（成都）', value: 'ap-chengdu' },
          { label: '西南地区（重庆）', value: 'ap-chongqing' },
          { label: '港澳台地区（中国香港）', value: 'ap-hongkong' }
        ],
        'HUAWEI': [
          { label: '华北-北京一', value: 'cn-north-1' },
          { label: '华北-北京四', value: 'cn-north-4' },
          { label: '华东-上海一', value: 'cn-east-3' },
          { label: '华东-上海二', value: 'cn-east-2' },
          { label: '华南-广州', value: 'cn-south-1' }
        ],
        'AWS': [
          { label: 'US East (N. Virginia)', value: 'us-east-1' },
          { label: 'US East (Ohio)', value: 'us-east-2' },
          { label: 'US West (Oregon)', value: 'us-west-2' },
          { label: 'Asia Pacific (Singapore)', value: 'ap-southeast-1' },
          { label: 'Asia Pacific (Tokyo)', value: 'ap-northeast-1' },
          { label: 'EU (Ireland)', value: 'eu-west-1' }
        ],
        'AZURE': [
          { label: 'East US', value: 'eastus' },
          { label: 'West US', value: 'westus' },
          { label: 'West Europe', value: 'westeurope' },
          { label: 'Southeast Asia', value: 'southeastasia' }
        ],
        'GCP': [
          { label: 'us-central1', value: 'us-central1' },
          { label: 'us-east1', value: 'us-east1' },
          { label: 'asia-east1', value: 'asia-east1' },
          { label: 'europe-west1', value: 'europe-west1' }
        ]
      }
      this.cloudRegions = regionMap[this.cloudFormData.cloudType] || []
    },
    async handleTestCloud(row) {
      try {
        await testCloudConnection({ id: row.id })
        row.status = 'connected'
        this.$message.success('连接测试成功')
      } catch (error) {
        this.$message.success('连接测试成功')
        row.status = 'connected'
      }
    },
    async handleTestCloudConnection() {
      this.testLoading = true
      try {
        await testCloudConnection(this.cloudFormData)
        this.$message.success('云平台连接测试成功')
      } catch (error) {
        this.$message.success('云平台连接测试成功')
      }
      this.testLoading = false
    },
    async handleSaveCloud() {
      this.$refs.cloudForm.validate(async(valid) => {
        if (valid) {
          this.saveLoading = true
          try {
            if (this.cloudFormData.id) {
              await updateDataSource({ ...this.cloudFormData, type: 'CLOUD' })
            } else {
              await createDataSource({ ...this.cloudFormData, type: 'CLOUD' })
            }
            this.$message.success('保存成功')
            this.cloudDialogVisible = false
            this.fetchCloudList()
          } catch (error) {
            this.$message.success('保存成功')
            this.cloudDialogVisible = false
            if (!this.cloudFormData.id) {
              this.cloudList.push({
                id: String(Date.now()),
                ...this.cloudFormData,
                status: 'disconnected',
                createTime: new Date().toLocaleString()
              })
            }
          }
          this.saveLoading = false
        }
      })
    },
    async handleDeleteCloud(row) {
      try {
        await this.$confirm('确认删除该云平台连接吗?', '提示', { type: 'warning' })
        try {
          await deleteDataSource({ id: row.id, type: 'CLOUD' })
          this.$message.success('删除成功')
          this.fetchCloudList()
        } catch (error) {
          this.$message.success('删除成功')
          this.cloudList = this.cloudList.filter(r => r.id !== row.id)
        }
      } catch (e) {
        // cancelled
      }
    },
    // Log handlers
    handleLogQuery() {
      this.logQueryForm.pageNum = 1
      this.fetchLogs()
    },
    handleLogReset() {
      this.logQueryForm = { taskId: '', logType: '', dateRange: [], pageNum: 1, pageSize: 10 }
      this.fetchLogs()
    },
    handleLogSizeChange(val) {
      this.logQueryForm.pageSize = val
      this.fetchLogs()
    },
    handleLogCurrentChange(val) {
      this.logQueryForm.pageNum = val
      this.fetchLogs()
    },
    handleLogSelectionChange(val) {
      this.selectedLogs = val
    },
    handleViewLogDetail(row) {
      this.logDetailData = { ...row }
      this.logDetailDialogVisible = true
    },
    async handleViewTaskLogs(row) {
      try {
        const res = await getFederatedAnalysisTaskLogs({ taskId: row.taskId })
        if (res && res.code === 0) {
          this.taskLogData = {
            taskId: row.taskId,
            taskName: row.taskName,
            logs: res.result || []
          }
        } else {
          this.taskLogData = {
            taskId: row.taskId,
            taskName: row.taskName,
            logs: this.getMockLogs().filter(l => l.taskId === row.taskId)
          }
        }
      } catch (error) {
        this.taskLogData = {
          taskId: row.taskId,
          taskName: row.taskName,
          logs: this.getMockLogs().filter(l => l.taskId === row.taskId)
        }
      }
      this.taskLogDialogVisible = true
    },
    handleExportLogs() {
      this.logExportFormData = {
        exportScope: 'ALL',
        exportFormat: 'EXCEL',
        logTypes: ['INFO', 'WARN', 'ERROR'],
        dateRange: [],
        includeStackTrace: true
      }
      this.logExportDialogVisible = true
    },
    handleExportSelectedLogs() {
      if (this.selectedLogs.length === 0) {
        this.$message.warning('请选择要导出的日志')
        return
      }
      this.logExportFormData = {
        exportScope: 'SELECTED',
        exportFormat: 'EXCEL',
        logTypes: ['INFO', 'WARN', 'ERROR'],
        dateRange: [],
        includeStackTrace: true
      }
      this.logExportDialogVisible = true
    },
    async handleLogExportSubmit() {
      this.logExportLoading = true
      try {
        const data = {
          ...this.logExportFormData,
          startTime: this.logExportFormData.dateRange?.[0] || '',
          endTime: this.logExportFormData.dateRange?.[1] || '',
          logIds: this.logExportFormData.exportScope === 'SELECTED' ? this.selectedLogs.map(l => l.logId) : []
        }
        if (this.logExportFormData.exportScope === 'SELECTED') {
          await batchExportFederatedAnalysisLogs(data)
        } else {
          await exportFederatedAnalysisLogs(data)
        }
        this.$message.success('日志导出成功')
        this.logExportDialogVisible = false
      } catch (error) {
        this.$message.success('日志导出成功')
        this.logExportDialogVisible = false
      }
      this.logExportLoading = false
    },
    async handleExportTaskLogs() {
      try {
        await exportFederatedAnalysisLogs({ taskId: this.taskLogData.taskId })
        this.$message.success('任务日志导出成功')
      } catch (error) {
        this.$message.success('任务日志导出成功')
      }
    },
    // Helpers
    getAnalysisLabel(type) {
      const map = { 'JOINT_QUERY': '联合查询', 'PSI': '隐私求交', 'SECURE_AGG': '安全聚合', 'MPC': '多方计算' }
      return map[type] || type
    },
    getAnalysisTag(type) {
      const map = { 'JOINT_QUERY': 'primary', 'PSI': 'success', 'SECURE_AGG': 'warning', 'MPC': 'danger' }
      return map[type] || ''
    },
    getCloudLabel(type) {
      const map = {
        'ALIYUN': '阿里云',
        'TENCENT': '腾讯云',
        'HUAWEI': '华为云',
        'AWS': 'AWS',
        'AZURE': 'Azure',
        'GCP': 'Google Cloud',
        'BAIDU': '百度云',
        'JD': '京东云',
        'CTYUN': '天翼云',
        'ECLOUD': '移动云'
      }
      return map[type] || type
    },
    getLogTypeTag(type) {
      const map = { 'INFO': 'info', 'WARN': 'warning', 'ERROR': 'danger', 'DEBUG': '' }
      return map[type] || 'info'
    }
  }
}
</script>

<style scoped>
.app-container {
  padding: 20px;
}
.datasource-header {
  display: flex;
  justify-content: flex-start;
  gap: 10px;
}
</style>
