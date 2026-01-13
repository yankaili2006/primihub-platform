# Data Requirement Management Implementation Plan

## Overview
Add data requirement management functionality to the resource management module without modifying existing logic. This will include 5 new sub-menus and complete CRUD operations.

## Architecture Overview
Following the established three-layer architecture pattern:
- **Frontend**: Vue.js components with Element UI
- **Gateway**: Spring Cloud Gateway routing with SysAuth filter
- **Backend**: Controller → Service → Repository → MyBatis Mapper
- **Database**: New tables in primary database

## 1. Database Design

### 1.1 Main Table: data_requirement
```sql
CREATE TABLE `data_requirement` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `requirement_code` VARCHAR(64) NOT NULL COMMENT 'Requirement Code',
  `requirement_name` VARCHAR(128) NOT NULL COMMENT 'Requirement Name',
  `requirement_desc` TEXT COMMENT 'Requirement Description',
  `requirement_type` VARCHAR(32) COMMENT 'Requirement Type (模型训练/数据分析/隐私求交等)',
  `data_fields` TEXT COMMENT 'Required data fields (JSON format)',
  `data_volume` BIGINT COMMENT 'Required data volume',
  `data_format` VARCHAR(32) COMMENT 'Required data format (CSV/JSON/等)',
  `priority` TINYINT DEFAULT 0 COMMENT 'Priority (0-低 1-中 2-高)',
  `status` TINYINT DEFAULT 0 COMMENT 'Status (0-待匹配 1-已匹配 2-已完成 3-已关闭)',
  `user_id` BIGINT NOT NULL COMMENT 'Creator User ID',
  `user_name` VARCHAR(64) COMMENT 'Creator User Name',
  `organ_id` BIGINT COMMENT 'Organization ID',
  `organ_name` VARCHAR(128) COMMENT 'Organization Name',
  `start_date` DATETIME COMMENT 'Start Date',
  `end_date` DATETIME COMMENT 'End Date',
  `is_del` TINYINT DEFAULT 0 COMMENT 'Delete Flag (0-未删除 1-已删除)',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Create Time',
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update Time',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_requirement_code` (`requirement_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Data Requirement Table';
```

### 1.2 Configuration Table: data_requirement_config
```sql
CREATE TABLE `data_requirement_config` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `config_key` VARCHAR(64) NOT NULL COMMENT 'Config Key',
  `config_value` TEXT NOT NULL COMMENT 'Config Value',
  `config_desc` VARCHAR(255) COMMENT 'Config Description',
  `config_type` VARCHAR(32) COMMENT 'Config Type (系统配置/匹配规则/等)',
  `is_enabled` TINYINT DEFAULT 1 COMMENT 'Enable Flag (0-禁用 1-启用)',
  `is_del` TINYINT DEFAULT 0 COMMENT 'Delete Flag',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Data Requirement Configuration Table';
```

### 1.3 Matching Table: data_requirement_match
```sql
CREATE TABLE `data_requirement_match` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `requirement_id` BIGINT NOT NULL COMMENT 'Requirement ID',
  `resource_id` BIGINT NOT NULL COMMENT 'Resource ID (from data_resource)',
  `match_score` DECIMAL(5,2) COMMENT 'Match Score (0.00-100.00)',
  `match_status` TINYINT DEFAULT 0 COMMENT 'Match Status (0-待确认 1-已确认 2-已拒绝)',
  `match_type` VARCHAR(32) COMMENT 'Match Type (自动匹配/手动匹配)',
  `match_details` TEXT COMMENT 'Match Details (JSON)',
  `is_del` TINYINT DEFAULT 0 COMMENT 'Delete Flag',
  `create_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `update_date` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_requirement_id` (`requirement_id`),
  KEY `idx_resource_id` (`resource_id`),
  KEY `idx_match_score` (`match_score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Data Requirement Match Table';
```

## 2. Backend Implementation

### 2.1 Entity Classes (biz/src/main/java/com/primihub/biz/entity/data/po/)

**DataRequirement.java** - Main entity
**DataRequirementConfig.java** - Configuration entity
**DataRequirementMatch.java** - Match relationship entity

### 2.2 Repository Layer (biz/src/main/java/com/primihub/biz/repository/primarydb/data/)

**DataRequirementPrimarydbRepository.java**
- Interface defining database operations
- Methods: insert, update, delete, selectById, selectList, selectCount, etc.

**MyBatis Mapper XML** (biz/src/main/resources/mybatis/mapper/primarydb/data/DataRequirementPrimarydbRepositoryMapper.xml)
- SQL implementations for all CRUD operations
- Dynamic SQL for flexible querying with multiple conditions

### 2.3 Service Layer (biz/src/main/java/com/primihub/biz/service/data/)

**DataRequirementService.java**
- Business logic methods:
  - `findDataRequirementPage()` - Paginated list query
  - `addDataRequirement()` - Add new requirement
  - `updateDataRequirement()` - Update requirement
  - `deleteDataRequirement()` - Soft delete requirement
  - `getDataRequirementById()` - Get by ID
  - `findDataRequirementConfigPage()` - Config list
  - `addDataRequirementConfig()` - Add config
  - `updateDataRequirementConfig()` - Update config
  - `deleteDataRequirementConfig()` - Delete config
  - `matchDataRequirements()` - Auto matching algorithm
  - `confirmMatch()` - Confirm match
  - `rejectMatch()` - Reject match
  - `findMatchedResources()` - Query matched resources

### 2.4 Controller Layer (application/src/main/java/com/primihub/application/controller/data/)

**DataRequirementController.java**
- REST API endpoints:

#### Data Requirement CRUD
- `GET /dataRequirement/findDataRequirementPage` - Query requirement list
- `POST /dataRequirement/addDataRequirement` - Add requirement
- `POST /dataRequirement/updateDataRequirement` - Update requirement
- `POST /dataRequirement/deleteDataRequirement` - Delete requirement
- `GET /dataRequirement/getDataRequirementById` - Get by ID

#### Configuration Management
- `GET /dataRequirement/findConfigPage` - Query config list
- `POST /dataRequirement/addConfig` - Add config
- `POST /dataRequirement/updateConfig` - Update config
- `POST /dataRequirement/deleteConfig` - Delete config

#### Matching Functionality
- `POST /dataRequirement/matchDataRequirements` - Execute matching
- `GET /dataRequirement/findMatchedResources` - Query matched resources
- `POST /dataRequirement/confirmMatch` - Confirm match
- `POST /dataRequirement/rejectMatch` - Reject match

## 3. Gateway Configuration

### 3.1 Add Route in gateway/src/main/resources/application.yaml

```yaml
- id: data-requirement-url-proxy
  uri: lb://platform
  predicates:
    - Path=/dataRequirement/**
  filters:
    - BaseParam
    - SysAuth
    - SysLog
```

## 4. Frontend Implementation

### 4.1 Router Configuration (primihub-webconsole/src/router/index.js)

Add children to the existing `/resource` route:
```javascript
{
  path: 'requirementList',
  name: 'DataRequirementList',
  component: () => import('@/views/resource/requirementList'),
  meta: { title: '数据需求列表' }
},
{
  path: 'requirementAdd',
  name: 'DataRequirementAdd',
  component: () => import('@/views/resource/requirementAdd'),
  meta: { title: '新增数据需求' }
},
{
  path: 'requirementConfig',
  name: 'DataRequirementConfig',
  component: () => import('@/views/resource/requirementConfig'),
  meta: { title: '数据需求配置' }
},
{
  path: 'requirementMatch',
  name: 'DataRequirementMatch',
  component: () => import('@/views/resource/requirementMatch'),
  meta: { title: '匹配数据需求所需数据' }
}
```

### 4.2 API Module (primihub-webconsole/src/api/dataRequirement.js)

Create new API module with axios calls for all endpoints:
- `findDataRequirementPage(params)` - GET with query params
- `addDataRequirement(data)` - POST with body
- `updateDataRequirement(data)` - POST with body
- `deleteDataRequirement(id)` - POST with id param
- `findConfigPage(params)` - GET config list
- `addConfig(data)` - POST config
- `updateConfig(data)` - POST config update
- `deleteConfig(id)` - POST config delete
- `matchDataRequirements(requirementId)` - POST match execution
- `findMatchedResources(requirementId)` - GET matched resources
- `confirmMatch(matchId)` - POST confirm
- `rejectMatch(matchId)` - POST reject

### 4.3 Vue Components (primihub-webconsole/src/views/resource/)

**requirementList.vue** - Data requirement list page
- el-table for displaying requirements
- Search filters (keyword, status, type, date range)
- Pagination
- Action buttons (Add, Edit, Delete, View Matches)
- Dialog for add/edit forms

**requirementAdd.vue** - Add/Edit requirement page (can be dialog in list)
- el-form with validation rules
- Fields: requirement_name, requirement_desc, requirement_type, data_fields, data_volume, priority, start_date, end_date
- Submit and Cancel buttons

**requirementConfig.vue** - Configuration management page
- el-table for displaying configs
- CRUD operations for configuration items
- Config types: matching rules, system parameters, etc.

**requirementMatch.vue** - Matching page
- Two-panel layout:
  - Left: List of requirements (with filters)
  - Right: Matched resources for selected requirement
- Match score display
- Actions: Execute Auto-Match, Confirm, Reject
- Match details display

## 5. Permission Configuration

### 5.1 SQL Script (primihub-service/script/data_requirement_permissions.sql)

```sql
-- Insert first-level menu: Data Requirement Management (as child of Resource Management)
SELECT auth_id INTO @resource_id FROM sys_auth WHERE auth_code = 'ResourceMenu';

-- Insert second-level menus under Resource Management
INSERT INTO sys_auth (auth_code, auth_name, auth_type, auth_url, parent_auth_id, auth_sort, is_del) VALUES
('DataRequirementList', '数据需求列表', 2, '/dataRequirement/findDataRequirementPage', @resource_id, 10, 0),
('DataRequirementAdd', '新增数据需求', 2, '/dataRequirement/addDataRequirement', @resource_id, 11, 0),
('DataRequirementDelete', '删除数据需求', 3, '/dataRequirement/deleteDataRequirement', @resource_id, 12, 0),
('DataRequirementConfig', '数据需求配置', 2, '/dataRequirement/findConfigPage', @resource_id, 13, 0),
('DataRequirementMatch', '匹配数据需求所需数据', 2, '/dataRequirement/matchDataRequirements', @resource_id, 14, 0);

-- Assign all permissions to super admin role (role_id=1)
INSERT INTO sys_ra (role_id, auth_id, is_del)
SELECT 1, auth_id, 0 FROM sys_auth
WHERE auth_code IN ('DataRequirementList', 'DataRequirementAdd', 'DataRequirementDelete',
                    'DataRequirementConfig', 'DataRequirementMatch')
AND is_del = 0;
```

### 5.2 Execute in All Databases
Run the script in: privacy1, privacy2, privacy3

## 6. Matching Algorithm Design

### 6.1 Matching Logic
The auto-matching algorithm will score each resource based on:
1. **Field Matching** (40 points): Compare required fields with resource columns
2. **Data Volume** (20 points): Check if resource has sufficient data rows
3. **Data Format** (20 points): Check format compatibility
4. **Data Type** (20 points): Check if requirement type matches resource type

### 6.2 Implementation in Service Layer
```java
public BaseResultEntity matchDataRequirements(Long requirementId) {
    // 1. Get requirement details
    // 2. Query all available resources
    // 3. Calculate match score for each resource
    // 4. Save matches with score >= threshold (configurable)
    // 5. Return matched resources sorted by score
}
```

## 7. Implementation Steps

### Step 1: Database Setup
1. Create SQL migration script with all 3 tables
2. Execute in all databases (privacy1, privacy2, privacy3)
3. Verify table creation

### Step 2: Backend Implementation
1. Create entity classes (DataRequirement, DataRequirementConfig, DataRequirementMatch)
2. Create Repository interface and MyBatis mapper XML
3. Implement Service layer with business logic
4. Create Controller with REST endpoints
5. Add Gateway route configuration

### Step 3: Frontend Implementation
1. Create API module (dataRequirement.js)
2. Update router with new routes
3. Create Vue components:
   - requirementList.vue
   - requirementAdd.vue (or dialog)
   - requirementConfig.vue
   - requirementMatch.vue
4. Add menu items to navigation

### Step 4: Permission Configuration
1. Create permission SQL script
2. Execute in all databases
3. Verify permissions in sys_auth table
4. Test access control

### Step 5: Testing
1. Unit tests for Service layer
2. Integration tests for API endpoints
3. Frontend component testing
4. End-to-end testing of matching functionality

## 8. Key Design Decisions

1. **Non-intrusive Design**: All new tables and code are separate from existing resource management
2. **Soft Delete Pattern**: Following existing pattern with is_del field
3. **Pagination**: Using existing PageParam class for consistency
4. **Permission Integration**: Adding permissions under existing ResourceMenu
5. **Matching Algorithm**: Configurable threshold and scoring weights
6. **Status Management**: Clear status flow for requirements and matches

## 9. Files to Create

### Backend
- `primihub-service/biz/src/main/java/com/primihub/biz/entity/data/po/DataRequirement.java`
- `primihub-service/biz/src/main/java/com/primihub/biz/entity/data/po/DataRequirementConfig.java`
- `primihub-service/biz/src/main/java/com/primihub/biz/entity/data/po/DataRequirementMatch.java`
- `primihub-service/biz/src/main/java/com/primihub/biz/repository/primarydb/data/DataRequirementPrimarydbRepository.java`
- `primihub-service/biz/src/main/resources/mybatis/mapper/primarydb/data/DataRequirementPrimarydbRepositoryMapper.xml`
- `primihub-service/biz/src/main/java/com/primihub/biz/service/data/DataRequirementService.java`
- `primihub-service/application/src/main/java/com/primihub/application/controller/data/DataRequirementController.java`
- `primihub-service/script/data_requirement.sql` (DDL)
- `primihub-service/script/data_requirement_permissions.sql` (Permissions)

### Frontend
- `primihub-webconsole/src/api/dataRequirement.js`
- `primihub-webconsole/src/views/resource/requirementList.vue`
- `primihub-webconsole/src/views/resource/requirementConfig.vue`
- `primihub-webconsole/src/views/resource/requirementMatch.vue`

### Configuration
- Update: `primihub-service/gateway/src/main/resources/application.yaml`
- Update: `primihub-webconsole/src/router/index.js`

## 10. Estimated Complexity

- **Backend**: ~15 files, ~2500 lines of code
- **Frontend**: ~4 files, ~1500 lines of code
- **Database**: 3 tables, 2 SQL scripts
- **Configuration**: 2 file updates

Total estimated implementation: Medium complexity, following established patterns throughout.
