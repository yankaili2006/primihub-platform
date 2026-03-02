# PrimiHub 测试工具集

本目录包含 PrimiHub 平台的测试、调试、修复和验证工具。

## 📊 工具统计

- **总计**: 107个工具
- **Python脚本**: 47个
- **Shell脚本**: 60个

---

## 📁 工具分类

### 1. PSI（隐私求交）测试工具

#### 任务创建
- `create_psi_dh.py` - 创建DH密钥交换PSI任务
- `create_psi_he.py` - 创建同态加密PSI任务
- `create_psi_ot.py` - 创建KKRT OT PSI任务

#### 测试执行
- `psi_client_full_test.py` - PSI完整客户端测试
- `psi_scheduled_test.py` - PSI定时测试
- `test_psi_cross_node.py` - 跨节点PSI测试
- `test_psi_with_cli.py` - CLI PSI测试

#### 任务管理
- `check_psi_tasks.py` - 检查PSI任务状态
- `fix_psi_tasks.py` - 修复PSI任务
- `fix_psi_tasks.sh` - PSI任务修复脚本
- `trigger_psi_tasks.py` - 触发PSI任务（Python版）
- `trigger_psi_tasks.sh` - 触发PSI任务（Shell版）
- `trigger_psi_tasks_v2.sh` - PSI任务触发v2
- `trigger_psi_tasks_final.sh` - PSI任务触发最终版

#### 示例
- `psi_workflow_example.sh` - PSI工作流示例

---

### 2. PIR（隐私检索）测试工具

- `create_pir_dh.py` - 创建DH PIR任务
- `create_pir_template.py` - PIR模板创建
- `create_db_resource_and_test_pir.py` - 数据库资源PIR测试
- `create_resource_and_test_pir.py` - 资源PIR测试
- `pir_workflow_example.sh` - PIR工作流示例

---

### 3. 联邦学习（FL）测试工具

- `create_fl_project_complete.py` - 完整FL项目创建
- `run_fl_training_full.py` - 完整FL训练运行
- `test_end_to_end_fl.py` - 端到端FL测试
- `test_fl_with_real_data.py` - 真实数据FL测试
- `test_with_real_data.py` - 真实数据测试

---

### 4. Web界面测试工具

- `browser_test_tool.py` - 浏览器测试工具
- `complete_web_test.py` - 完整Web测试
- `simple_web_test.py` - 简单Web测试
- `selenium_menu_test.py` - Selenium菜单测试
- `menu_function_test.py` - 菜单功能测试
- `test_login.py` - 登录测试
- `test_login_and_menus.sh` - 登录和菜单测试

---

### 5. API测试工具

- `check_all_apis.py` - 检查所有API
- `check_api_response.py` - API响应检查
- `test-all-apis.sh` - 测试所有API
- `test-api-auto.sh` - API自动测试
- `test-resource-api.sh` - 资源API测试
- `test-user-api.py` - 用户API测试
- `test_xgboost_api.py` - XGBoost API测试
- `test_get_publickey.py` - 公钥获取测试
- `advanced_test_tool.py` - 高级测试工具

---

### 6. 节点连接和网络工具

#### 连接检查
- `check_node_communication.sh` - 节点通信检查
- `check_node_connections.sh` - 节点连接检查
- `check_node_services.sh` - 节点服务检查
- `deep_connection_check.sh` - 深度连接检查
- `diagnose_connection_status.sh` - 诊断连接状态

#### 连接建立
- `connect_nodes.sh` - 连接节点
- `configure_node_in_nacos.sh` - Nacos节点配置
- `establish_node_connection.sh` - 建立节点连接
- `establish_full_mesh_connection.sh` - 建立全网状连接

#### 连接修复
- `fix_node_connection.sh` - 修复节点连接
- `fix_node_connection_cli.py` - 节点连接修复CLI
- `fix-node-network.sh` - 修复节点网络
- `fix_full_mesh_via_api.sh` - 通过API修复全网状

#### 验证和演示
- `final_node_connection_verification.sh` - 最终节点连接验证
- `node_authentication_demo.sh` - 节点认证演示
- `test-node-network.sh` - 测试节点网络

---

### 7. 数据库工具

- `check_db.py` - 数据库检查
- `database.sh` - 数据库管理
- `database-backup.sh` - 数据库备份
- `database-restore.sh` - 数据库恢复
- `verify-database.sh` - 数据库验证
- `verify-nacos-db.sh` - Nacos数据库验证
- `migrate-db.sh` - 数据库迁移
- `investigate_node_tables.sh` - 调查节点表

---

### 8. 系统修复工具

#### 用户ID修复
- `apply-userid-fix.sh` - 应用用户ID修复
- `apply-userid-fix-v2.sh` - 用户ID修复v2
- `rollback-userid-fix.sh` - 回滚用户ID修复
- `verify-userid-fix.sh` - 验证用户ID修复

#### 部署修复
- `fix-deployment-issues.sh` - 修复部署问题
- `fix-offline-deploy.sh` - 修复离线部署
- `deploy-all-fixes.sh` - 部署所有修复

#### 服务修复
- `fix-healthcheck.sh` - 修复健康检查
- `fix-mysql-connection.sh` - 修复MySQL连接
- `fix-nacos-local-organ.sh` - 修复Nacos本地组织
- `fix-resource-404.sh` - 修复资源404

#### 认证修复
- `test-auth-fix.sh` - 测试认证修复
- `test_encryption_fix.py` - 测试加密修复
- `test_encryption_flow.py` - 测试加密流程

---

### 9. 调试和分析工具

- `debug_psi_cross_organ.py` - 调试跨组织PSI
- `analyze_long_running_task.py` - 分析长时间运行任务
- `diagnose-login.sh` - 诊断登录问题
- `final_connection_solution.py` - 最终连接解决方案
- `comprehensive_results.py` - 综合结果查看
- `view_results_fixed.py` - 查看结果（修复版）
- `view_training_results.py` - 查看训练结果

---

### 10. 配置和验证工具

#### 配置检查
- `check-nacos-config.sh` - 检查Nacos配置
- `check-organizations.sh` - 检查组织配置
- `check_all_node_status.py` - 检查所有节点状态
- `check_publickey.py` - 检查公钥

#### 系统验证
- `verify_frontend.sh` - 验证前端
- `health_check.sh` - 健康检查

#### 配置管理
- `update_nacos_keys.sh` - 更新Nacos密钥
- `view_node_publickeys.sh` - 查看节点公钥
- `query-users.sh` - 查询用户

#### 清理工具
- `cleanup.sh` - 清理脚本
- `cleanup_and_verify_connections.sh` - 清理并验证连接

---

### 11. CLI和通用工具

- `primihub-cli.py` - PrimiHub CLI工具（98KB，功能最全）
- `test_tool.py` - 通用测试工具
- `test-cli-demo.sh` - CLI演示测试

---

### 12. 资源管理工具

- `insert_fusion_resource_db.py` - 插入融合资源到数据库
- `register_fusion_resource_directly.py` - 直接注册融合资源
- `create-offline-package.sh` - 创建离线包
- `download-docker-packages.sh` - 下载Docker包

---

### 13. 演示和示例

- `final_demo.sh` - 最终演示
- `demo-node-authentication.sh` - 节点认证演示
- `run-frontend-test.sh` - 运行前端测试

---

## 🚀 快速开始

### PSI测试
```bash
# 创建PSI任务
python3 create_psi_dh.py

# 运行完整测试
python3 psi_client_full_test.py

# 检查任务状态
python3 check_psi_tasks.py
```

### 节点连接测试
```bash
# 检查节点服务
./check_node_services.sh

# 测试节点通信
./check_node_communication.sh

# 建立节点连接
./establish_node_connection.sh
```

### API测试
```bash
# 测试所有API
./test-all-apis.sh

# 检查API响应
python3 check_api_response.py
```

### Web界面测试
```bash
# 简单Web测试
python3 simple_web_test.py

# 完整Web测试
python3 complete_web_test.py
```

---

## 📝 使用说明

### Python脚本
大多数Python脚本需要以下依赖：
```bash
pip3 install requests pymysql pika selenium
```

### Shell脚本
Shell脚本通常需要：
- Docker环境
- MySQL客户端
- curl工具

### 权限设置
如果脚本无法执行，添加执行权限：
```bash
chmod +x script_name.sh
```

---

## 🔧 常见问题

### 1. 连接数据库失败
确保MySQL容器正在运行：
```bash
docker ps | grep mysql
```

### 2. API测试失败
检查服务是否启动：
```bash
curl http://localhost:30811/api/oauth/getAuthList
```

### 3. 节点连接问题
使用诊断工具：
```bash
./diagnose_connection_status.sh
```

---

## 📚 相关文档

- [PSI测试指南](../PSI_COMPLETE_SUMMARY.md)
- [节点连接指南](../NODE_CONNECTION_COMPLETE_GUIDE.md)
- [API测试文档](../README_API_TESTING.md)
- [故障排除](../TROUBLESHOOTING.md)

---

## 🤝 贡献

这些工具从 `primihub-deploy` 项目迁移而来，用于：
- 功能测试
- 问题诊断
- 系统修复
- 性能验证

如需添加新工具或改进现有工具，请遵循现有的命名和组织规范。

---

## 📞 支持

如遇问题，请查看：
1. 工具内置的帮助信息（`--help`）
2. 相关的markdown文档
3. 项目主README

---

**最后更新**: 2026-03-02
**工具数量**: 107个
**维护状态**: 活跃
