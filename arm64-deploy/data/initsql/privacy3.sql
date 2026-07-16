-- Complete schema (base + folded V2..V14, Flyway removed). Regenerated on MariaDB 10.11.
SET FOREIGN_KEY_CHECKS=0;
/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.18-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: privacy3
-- ------------------------------------------------------
-- Server version	10.11.18-MariaDB-ubu2204

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `privacy3`
--

/*!40000 DROP DATABASE IF EXISTS `privacy3`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `privacy3` /*!40100 DEFAULT CHARACTER SET utf8mb3 COLLATE utf8mb3_bin */;

USE `privacy3`;

--
-- Table structure for table `api_auth_config`
--

DROP TABLE IF EXISTS `api_auth_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_auth_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_id` bigint(20) NOT NULL COMMENT '关联接口ID',
  `auth_name` varchar(100) NOT NULL COMMENT '授权名称',
  `app_key` varchar(128) NOT NULL COMMENT 'AppKey',
  `app_secret` varchar(256) NOT NULL COMMENT 'AppSecret',
  `auth_type` varchar(30) DEFAULT 'APP_KEY' COMMENT '鉴权类型: APP_KEY/JWT/OAuth2',
  `allowed_ips` varchar(500) DEFAULT NULL COMMENT '允许IP列表(逗号分隔)',
  `expire_time` datetime DEFAULT NULL COMMENT '过期时间',
  `status` tinyint(4) DEFAULT 1 COMMENT '状态: 0禁用 1启用',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_key` (`app_key`),
  KEY `idx_api_id` (`api_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='接口授权配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `api_auth_config`
--

LOCK TABLES `api_auth_config` WRITE;
/*!40000 ALTER TABLE `api_auth_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `api_auth_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `api_call_log`
--

DROP TABLE IF EXISTS `api_call_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_call_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_id` bigint(20) DEFAULT NULL COMMENT '关联接口ID',
  `auth_id` bigint(20) DEFAULT NULL COMMENT '关联授权ID',
  `request_path` varchar(255) NOT NULL COMMENT '请求路径',
  `request_method` varchar(10) DEFAULT NULL COMMENT '请求方法',
  `request_params` text DEFAULT NULL COMMENT '请求参数',
  `request_headers` text DEFAULT NULL COMMENT '请求头',
  `response_code` int(11) DEFAULT NULL COMMENT '响应状态码',
  `response_body` text DEFAULT NULL COMMENT '响应体',
  `client_ip` varchar(64) DEFAULT NULL COMMENT '客户端IP',
  `execution_time` int(11) DEFAULT NULL COMMENT '执行时长(ms)',
  `is_success` tinyint(1) DEFAULT 1 COMMENT '是否成功',
  `error_message` varchar(2000) DEFAULT NULL COMMENT '错误信息',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_api_id` (`api_id`),
  KEY `idx_auth_id` (`auth_id`),
  KEY `idx_is_success` (`is_success`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='接口调用日志表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `api_call_log`
--

LOCK TABLES `api_call_log` WRITE;
/*!40000 ALTER TABLE `api_call_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `api_call_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `api_definition`
--

DROP TABLE IF EXISTS `api_definition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `api_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_name` varchar(100) NOT NULL COMMENT '接口名称',
  `api_path` varchar(255) NOT NULL COMMENT '接口路径',
  `api_method` varchar(10) NOT NULL COMMENT '请求方法: GET/POST/PUT/DELETE',
  `protocol` varchar(20) DEFAULT 'REST' COMMENT '协议',
  `content_type` varchar(50) DEFAULT 'application/json' COMMENT 'Content-Type',
  `description` varchar(500) DEFAULT NULL COMMENT '接口描述',
  `request_example` text DEFAULT NULL COMMENT '请求示例',
  `response_example` text DEFAULT NULL COMMENT '响应示例',
  `status` tinyint(4) DEFAULT 1 COMMENT '状态: 0禁用 1启用',
  `is_require_auth` tinyint(1) DEFAULT 1 COMMENT '是否需要授权',
  `rate_limit` int(11) DEFAULT 0 COMMENT '速率限制(次/秒)',
  `timeout` int(11) DEFAULT 30000 COMMENT '超时时间(ms)',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_api_path` (`api_path`),
  KEY `idx_status` (`status`),
  KEY `idx_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='接口定义表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `api_definition`
--

LOCK TABLES `api_definition` WRITE;
/*!40000 ALTER TABLE `api_definition` DISABLE KEYS */;
/*!40000 ALTER TABLE `api_definition` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_component`
--

DROP TABLE IF EXISTS `data_component`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_component` (
  `component_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '组件id',
  `front_component_id` varchar(255) DEFAULT NULL COMMENT '前端组件id',
  `model_id` bigint(20) DEFAULT NULL COMMENT '模型id',
  `task_id` bigint(20) DEFAULT NULL COMMENT '任务id',
  `component_code` varchar(255) DEFAULT NULL COMMENT '组件code',
  `component_name` varchar(255) DEFAULT NULL COMMENT '组件名称',
  `shape` varchar(255) DEFAULT NULL COMMENT '形状',
  `width` int(11) DEFAULT 0 COMMENT '宽度',
  `height` int(11) DEFAULT 0 COMMENT '高度',
  `coordinate_y` int(11) DEFAULT 0 COMMENT '坐标y',
  `coordinate_x` int(11) DEFAULT 0 COMMENT '坐标x',
  `data_json` mediumtext DEFAULT NULL COMMENT '组件参数json',
  `start_time` bigint(20) DEFAULT 0 COMMENT '开始时间戳',
  `end_time` bigint(20) DEFAULT 0 COMMENT '结束时间戳',
  `component_state` tinyint(4) DEFAULT 0 COMMENT '组件运行状态 0初始 1成功 2运行中 3失败',
  `input_file_path` varchar(255) DEFAULT NULL COMMENT '输入文件路径',
  `output_file_path` varchar(255) DEFAULT NULL COMMENT '输出文件路径',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`component_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='组件表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_component`
--

LOCK TABLES `data_component` WRITE;
/*!40000 ALTER TABLE `data_component` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_component` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_component_draft`
--

DROP TABLE IF EXISTS `data_component_draft`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_component_draft` (
  `draft_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '草稿id',
  `draft_name` varchar(255) DEFAULT NULL COMMENT '草稿名称',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户id',
  `component_json` mediumtext DEFAULT NULL COMMENT '组件json',
  `component_image` mediumtext DEFAULT NULL COMMENT '组件图',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`draft_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='组件草稿表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_component_draft`
--

LOCK TABLES `data_component_draft` WRITE;
/*!40000 ALTER TABLE `data_component_draft` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_component_draft` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_difference`
--

DROP TABLE IF EXISTS `data_difference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_difference` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '求差主键',
  `own_organ_id` varchar(50) NOT NULL COMMENT '本机构id',
  `own_resource_id` varchar(50) NOT NULL COMMENT '本机构资源id',
  `own_keyword` varchar(255) NOT NULL COMMENT '本机构资源关键字',
  `other_organ_id` varchar(50) NOT NULL COMMENT '其他机构id',
  `other_resource_id` varchar(50) NOT NULL COMMENT '其他机构资源id',
  `other_keyword` varchar(255) NOT NULL COMMENT '其他机构资源关键字',
  `output_file_path_type` tinyint(4) DEFAULT 0 COMMENT '文件路径输出类型 0默认 自动生成',
  `output_no_repeat` tinyint(4) DEFAULT 0 COMMENT '输出内容是否不去重 默认0 不去重 1去重',
  `tag` tinyint(4) DEFAULT 0 COMMENT '实现方法 0:ECDH 1:KKRT 2:TEE',
  `result_name` varchar(255) NOT NULL COMMENT '结果名称',
  `output_format` varchar(50) DEFAULT 'csv' COMMENT '输出格式',
  `result_organ_ids` varchar(255) NOT NULL COMMENT '结果获取方 多机构逗号间隔',
  `difference_direction` tinyint(4) DEFAULT 0 COMMENT '求差方向 0:本机构-其他机构 1:其他机构-本机构',
  `remarks` text DEFAULT NULL COMMENT '备注',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `tee_organ_id` varchar(50) DEFAULT NULL COMMENT 'TEE机构ID',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_own_organ_id` (`own_organ_id`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='联邦求差主表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_difference`
--

LOCK TABLES `data_difference` WRITE;
/*!40000 ALTER TABLE `data_difference` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_difference` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_difference_task`
--

DROP TABLE IF EXISTS `data_difference_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_difference_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '求差任务id',
  `difference_id` bigint(20) NOT NULL COMMENT '求差id',
  `task_id` varchar(100) NOT NULL COMMENT '对外展示的任务uuid',
  `task_state` tinyint(4) DEFAULT 0 COMMENT '运行状态 0未运行 1完成 2运行中 3失败 4取消',
  `ascription` varchar(255) DEFAULT NULL COMMENT '结果归属',
  `ascription_type` tinyint(4) DEFAULT 0 COMMENT '结果归属类型 0一方 1双方',
  `file_rows` int(11) DEFAULT 0 COMMENT '结果文件行数',
  `file_path` varchar(500) DEFAULT NULL COMMENT '文件路径',
  `file_content` text DEFAULT NULL COMMENT '文件内容',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_difference_id` (`difference_id`),
  KEY `idx_task_state` (`task_state`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='联邦求差任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_difference_task`
--

LOCK TABLES `data_difference_task` WRITE;
/*!40000 ALTER TABLE `data_difference_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_difference_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_file_field`
--

DROP TABLE IF EXISTS `data_file_field`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_file_field` (
  `field_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '字段id',
  `file_id` bigint(20) DEFAULT NULL COMMENT '文件id',
  `resource_id` bigint(20) DEFAULT NULL COMMENT '资源id',
  `field_name` varchar(255) DEFAULT NULL COMMENT '字段名称',
  `field_as` varchar(255) DEFAULT NULL COMMENT '字段别名',
  `field_type` int(11) DEFAULT 0 COMMENT '字段类型 默认0 string',
  `field_desc` varchar(255) DEFAULT NULL COMMENT '字段描述',
  `relevance` int(11) DEFAULT 0 COMMENT '关键字 0否 1是',
  `grouping` int(11) DEFAULT 0 COMMENT '分组 0否 1是',
  `protection_status` int(11) DEFAULT 0 COMMENT '保护开关 0关闭 1开启',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`field_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='资源字段表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_file_field`
--

LOCK TABLES `data_file_field` WRITE;
/*!40000 ALTER TABLE `data_file_field` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_file_field` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_fusion_copy_task`
--

DROP TABLE IF EXISTS `data_fusion_copy_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_fusion_copy_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_type` tinyint(4) NOT NULL COMMENT '任务类型 1 批量 2 单条',
  `current_offset` bigint(20) NOT NULL COMMENT '当前偏移量',
  `target_offset` bigint(20) NOT NULL COMMENT '目标便宜量',
  `task_table` varchar(64) NOT NULL COMMENT '复制任务表名',
  `server_address` varchar(64) DEFAULT NULL COMMENT '发送地址',
  `organ_id` varchar(64) DEFAULT NULL COMMENT '机构ID',
  `latest_error_msg` varchar(1024) NOT NULL COMMENT '最近一次复制失败原因',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `current_offset_ix` (`current_offset`) USING BTREE,
  KEY `target_offset_ix` (`target_offset`) USING BTREE,
  KEY `c_time_ix` (`c_time`) USING BTREE,
  KEY `u_time_ix` (`u_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_fusion_copy_task`
--

LOCK TABLES `data_fusion_copy_task` WRITE;
/*!40000 ALTER TABLE `data_fusion_copy_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_fusion_copy_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_model`
--

DROP TABLE IF EXISTS `data_model`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_model` (
  `model_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '模型id',
  `model_uuid` varchar(255) DEFAULT NULL COMMENT '模型uuid',
  `model_name` varchar(255) DEFAULT NULL COMMENT '模型名称',
  `model_desc` varchar(255) DEFAULT NULL COMMENT '模型描述',
  `model_type` int(2) DEFAULT NULL COMMENT '模型模板',
  `project_id` bigint(20) DEFAULT NULL COMMENT '项目id',
  `resource_num` int(8) DEFAULT NULL COMMENT '资源个数',
  `y_value_column` varchar(255) DEFAULT NULL COMMENT 'y值字段',
  `component_speed` varchar(255) DEFAULT NULL COMMENT '组件执行进度id',
  `train_type` tinyint(4) DEFAULT 0 COMMENT '训练类型 0纵向 1横向 默认纵向',
  `is_draft` tinyint(4) DEFAULT 0 COMMENT '是否草稿 0是 1不是 默认是',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户id',
  `organ_id` varchar(255) DEFAULT NULL COMMENT '机构id',
  `component_json` mediumtext DEFAULT NULL COMMENT '组件json',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`model_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='模型表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_model`
--

LOCK TABLES `data_model` WRITE;
/*!40000 ALTER TABLE `data_model` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_model` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_model_component`
--

DROP TABLE IF EXISTS `data_model_component`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_model_component` (
  `mc_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '关系id',
  `model_id` bigint(20) DEFAULT NULL COMMENT '模型id',
  `task_id` bigint(20) DEFAULT NULL COMMENT '任务id',
  `input_component_id` bigint(20) DEFAULT NULL COMMENT '输入组件id',
  `output_component_id` bigint(20) DEFAULT NULL COMMENT '输出组件id',
  `point_type` varchar(255) DEFAULT NULL COMMENT '指向类型(直线、曲线图等等)',
  `point_json` varchar(255) DEFAULT NULL COMMENT '指向json数据',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`mc_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='组件模型关系表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_model_component`
--

LOCK TABLES `data_model_component` WRITE;
/*!40000 ALTER TABLE `data_model_component` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_model_component` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_model_quota`
--

DROP TABLE IF EXISTS `data_model_quota`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_model_quota` (
  `quota_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `quota_type` int(11) DEFAULT NULL,
  `quota_images` varchar(255) DEFAULT NULL,
  `model_id` bigint(20) DEFAULT NULL,
  `component_id` bigint(20) DEFAULT NULL,
  `auc` decimal(12,6) DEFAULT NULL,
  `ks` decimal(12,6) DEFAULT NULL,
  `gini` decimal(12,6) DEFAULT NULL,
  `precision` decimal(12,6) DEFAULT NULL,
  `recall` decimal(12,6) DEFAULT NULL,
  `f1_score` decimal(12,6) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT 0,
  `create_date` timestamp NULL DEFAULT current_timestamp(),
  `update_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`quota_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_model_quota`
--

LOCK TABLES `data_model_quota` WRITE;
/*!40000 ALTER TABLE `data_model_quota` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_model_quota` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_model_task`
--

DROP TABLE IF EXISTS `data_model_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_model_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `model_id` bigint(20) DEFAULT NULL COMMENT '模型id',
  `task_id` bigint(20) DEFAULT NULL COMMENT '任务id',
  `predict_file` varchar(255) DEFAULT NULL COMMENT '预测文件路径',
  `predict_content` mediumtext DEFAULT NULL COMMENT '预测文件内容',
  `component_json` mediumtext DEFAULT NULL COMMENT '模型运行组件列表json',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='模型任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_model_task`
--

LOCK TABLES `data_model_task` WRITE;
/*!40000 ALTER TABLE `data_model_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_model_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_mpc_task`
--

DROP TABLE IF EXISTS `data_mpc_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_mpc_task` (
  `task_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id_name` varchar(255) DEFAULT NULL,
  `script_id` bigint(20) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `task_status` int(11) DEFAULT 0,
  `task_desc` varchar(255) DEFAULT NULL,
  `log_data` blob DEFAULT NULL,
  `result_file_path` varchar(255) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT 0,
  `create_date` timestamp NULL DEFAULT current_timestamp(),
  `update_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_mpc_task`
--

LOCK TABLES `data_mpc_task` WRITE;
/*!40000 ALTER TABLE `data_mpc_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_mpc_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_mr`
--

DROP TABLE IF EXISTS `data_mr`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_mr` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '资源id',
  `model_id` bigint(20) DEFAULT NULL COMMENT '模型id',
  `resource_id` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '资源id',
  `task_id` bigint(20) DEFAULT NULL COMMENT '任务ID',
  `take_part_type` tinyint(4) DEFAULT 0 COMMENT '参与类型 0使用数据 1衍生数据',
  `alignment_num` int(8) DEFAULT NULL COMMENT '对齐后记录数量',
  `primitive_param_num` int(8) DEFAULT NULL COMMENT '原始变量数量',
  `modelParam_num` int(8) DEFAULT NULL COMMENT '入模变量数量',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='模型资源表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_mr`
--

LOCK TABLES `data_mr` WRITE;
/*!40000 ALTER TABLE `data_mr` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_mr` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_pir_task`
--

DROP TABLE IF EXISTS `data_pir_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_pir_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'pir任务id',
  `task_id` bigint(20) DEFAULT NULL COMMENT '任务ID',
  `provider_organ_name` varchar(255) DEFAULT NULL COMMENT '协作方机构名称',
  `resource_id` varchar(64) DEFAULT NULL COMMENT '资源ID',
  `resource_name` varchar(64) DEFAULT NULL COMMENT '资源名称',
  `retrieval_id` varchar(255) DEFAULT NULL COMMENT '检索ID',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='pir 任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_pir_task`
--

LOCK TABLES `data_pir_task` WRITE;
/*!40000 ALTER TABLE `data_pir_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_pir_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_project`
--

DROP TABLE IF EXISTS `data_project`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_project` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `project_id` varchar(141) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '项目ID 机构后12位+UUID',
  `project_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '项目名称',
  `project_desc` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '项目描述',
  `created_organ_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '机构id',
  `created_organ_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '机构名称',
  `created_username` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建者名称',
  `resource_num` int(11) DEFAULT 0 COMMENT '资源数',
  `provider_organ_names` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '协作方机构名称 保存三个',
  `status` tinyint(4) DEFAULT 0 COMMENT '项目状态 0审核中 1可用 2关闭',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `project_id_ix` (`project_id`) USING BTREE,
  KEY `created_organ_id_ix` (`created_organ_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='项目表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_project`
--

LOCK TABLES `data_project` WRITE;
/*!40000 ALTER TABLE `data_project` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_project` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_project_organ`
--

DROP TABLE IF EXISTS `data_project_organ`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_project_organ` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `po_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '项目机构关联ID UUID',
  `project_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '项目ID',
  `organ_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '机构ID',
  `initiate_organ_id` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发起方机构ID',
  `participation_identity` tinyint(4) DEFAULT NULL COMMENT '机构项目中参与身份 1发起者 2协作者',
  `audit_status` tinyint(4) DEFAULT NULL COMMENT '审核状态 0审核中 1同意 2拒绝',
  `audit_opinion` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '审核意见',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `project_id_ix` (`project_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='项目资源授权审核表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_project_organ`
--

LOCK TABLES `data_project_organ` WRITE;
/*!40000 ALTER TABLE `data_project_organ` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_project_organ` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_project_resource`
--

DROP TABLE IF EXISTS `data_project_resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_project_resource` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `pr_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '项目资源ID  UUID',
  `project_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '项目id',
  `initiate_organ_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发起方机构ID',
  `organ_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '机构ID',
  `participation_identity` tinyint(1) DEFAULT NULL COMMENT '机构项目中参与身份 1发起者 2协作者',
  `is_del` tinyint(1) DEFAULT 0 COMMENT '是否删除',
  `resource_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '资源ID',
  `audit_status` tinyint(4) DEFAULT NULL COMMENT '审核状态 0审核中 1同意 2拒绝',
  `audit_opinion` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '审核意见',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `project_id_ix` (`project_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='项目资源关系表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_project_resource`
--

LOCK TABLES `data_project_resource` WRITE;
/*!40000 ALTER TABLE `data_project_resource` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_project_resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_psi`
--

DROP TABLE IF EXISTS `data_psi`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_psi` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'psi 主键',
  `own_organ_id` varchar(255) DEFAULT NULL COMMENT '本机构id',
  `own_resource_id` varchar(255) DEFAULT NULL COMMENT '本机构资源id',
  `own_keyword` varchar(255) DEFAULT NULL COMMENT '本机构资源关键字',
  `other_organ_id` varchar(255) DEFAULT NULL COMMENT '其他机构id',
  `other_resource_id` varchar(255) DEFAULT NULL COMMENT '其他机构资源id',
  `other_keyword` varchar(255) DEFAULT NULL COMMENT '其他机构资源关键字',
  `output_file_path_type` tinyint(4) DEFAULT 0 COMMENT '文件路径输出类型 0默认 自动生成',
  `output_no_repeat` tinyint(4) DEFAULT 0 COMMENT '输出内容是否不去重 默认0 不去重 1去重',
  `tag` tinyint(4) DEFAULT 0 COMMENT '0表示openmined psi，1表示libPsi的KKRT psi',
  `result_name` varchar(255) DEFAULT NULL COMMENT '结果名称',
  `output_content` int(11) DEFAULT 0 COMMENT '输出内容 默认0 0交集 1差集',
  `output_format` varchar(255) DEFAULT NULL COMMENT '输出格式',
  `result_organ_ids` varchar(255) DEFAULT NULL COMMENT '结果获取方 多机构","号间隔',
  `tee_organ_id` varchar(255) DEFAULT NULL COMMENT 'tee 机构ID',
  `remarks` varchar(255) DEFAULT NULL COMMENT '备注',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户id',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_psi`
--

LOCK TABLES `data_psi` WRITE;
/*!40000 ALTER TABLE `data_psi` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_psi` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_psi_resource`
--

DROP TABLE IF EXISTS `data_psi_resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_psi_resource` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'psi资源id',
  `resource_id` bigint(20) DEFAULT NULL COMMENT '资源id',
  `psi_resource_desc` varchar(255) DEFAULT NULL COMMENT 'psi资源描述',
  `table_structure_template` varchar(255) DEFAULT NULL COMMENT '表结构模板',
  `organ_type` int(11) DEFAULT NULL COMMENT '机构类型',
  `results_allow_open` int(11) DEFAULT NULL COMMENT '是否允许结果出现在对方节点上',
  `keyword_list` varchar(255) DEFAULT NULL COMMENT '关键字 关键字:类型,关键字:类型.....',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_psi_resource`
--

LOCK TABLES `data_psi_resource` WRITE;
/*!40000 ALTER TABLE `data_psi_resource` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_psi_resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_psi_task`
--

DROP TABLE IF EXISTS `data_psi_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_psi_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'psi任务id',
  `psi_id` bigint(20) DEFAULT NULL COMMENT 'psi id',
  `task_id` varchar(255) DEFAULT NULL COMMENT '对外展示的任务uuid 同时也是文件名称',
  `task_state` int(11) DEFAULT 0 COMMENT '运行状态 0未运行 1运行中 2完成 默认0',
  `ascription_type` int(11) DEFAULT 0 COMMENT '归属类型 0一方 1双方',
  `ascription` varchar(255) DEFAULT NULL COMMENT '结果归属',
  `file_rows` int(11) DEFAULT 0 COMMENT '文件行数',
  `file_path` varchar(255) DEFAULT NULL COMMENT '文件路径',
  `file_content` mediumtext DEFAULT NULL COMMENT '文件内容',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_psi_task`
--

LOCK TABLES `data_psi_task` WRITE;
/*!40000 ALTER TABLE `data_psi_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_psi_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_reasoning`
--

DROP TABLE IF EXISTS `data_reasoning`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_reasoning` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '推理ID',
  `reasoning_id` varchar(255) DEFAULT NULL COMMENT '推理展示uuid',
  `reasoning_name` varchar(255) DEFAULT NULL COMMENT '推理名称',
  `reasoning_desc` varchar(255) DEFAULT NULL COMMENT '推理描述',
  `reasoning_type` tinyint(4) DEFAULT NULL COMMENT '推理类型 0两方 1三方',
  `reasoning_state` tinyint(4) DEFAULT NULL COMMENT '推理状态',
  `task_id` bigint(20) DEFAULT NULL COMMENT '任务ID',
  `run_task_id` bigint(20) DEFAULT NULL COMMENT '任务ID',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户ID',
  `release_date` datetime DEFAULT NULL COMMENT '发布日期',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='推理表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_reasoning`
--

LOCK TABLES `data_reasoning` WRITE;
/*!40000 ALTER TABLE `data_reasoning` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_reasoning` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_reasoning_resource`
--

DROP TABLE IF EXISTS `data_reasoning_resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_reasoning_resource` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '推理资源ID',
  `reasoning_id` bigint(20) DEFAULT NULL COMMENT '推理ID',
  `resource_id` varchar(64) DEFAULT NULL COMMENT '资源ID',
  `organ_id` varchar(64) DEFAULT NULL COMMENT '机构ID',
  `participation_identity` tinyint(1) DEFAULT NULL COMMENT '机构项目中参与身份 1发起者 2协作者',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='推理资源表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_reasoning_resource`
--

LOCK TABLES `data_reasoning_resource` WRITE;
/*!40000 ALTER TABLE `data_reasoning_resource` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_reasoning_resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_requirement`
--

DROP TABLE IF EXISTS `data_requirement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_requirement` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `requirement_code` varchar(64) NOT NULL COMMENT '需求编码',
  `requirement_name` varchar(128) NOT NULL COMMENT '需求名称',
  `requirement_desc` text DEFAULT NULL COMMENT '需求描述',
  `requirement_type` varchar(32) DEFAULT NULL COMMENT '需求类型',
  `data_fields` text DEFAULT NULL COMMENT '所需数据字段(JSON)',
  `data_volume` bigint(20) DEFAULT NULL COMMENT '所需数据量',
  `data_format` varchar(32) DEFAULT NULL COMMENT '所需数据格式',
  `priority` tinyint(4) DEFAULT 0 COMMENT '优先级',
  `status` tinyint(4) DEFAULT 0 COMMENT '状态',
  `user_id` bigint(20) NOT NULL COMMENT '创建人ID',
  `user_name` varchar(64) DEFAULT NULL COMMENT '创建人',
  `organ_id` bigint(20) DEFAULT NULL COMMENT '机构ID',
  `organ_name` varchar(128) DEFAULT NULL COMMENT '机构名称',
  `start_date` datetime DEFAULT NULL COMMENT '开始日期',
  `end_date` datetime DEFAULT NULL COMMENT '结束日期',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '删除标记',
  `create_date` datetime DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_requirement_code` (`requirement_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='数据需求表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_requirement`
--

LOCK TABLES `data_requirement` WRITE;
/*!40000 ALTER TABLE `data_requirement` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_requirement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_requirement_config`
--

DROP TABLE IF EXISTS `data_requirement_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_requirement_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `config_key` varchar(64) NOT NULL COMMENT '配置键',
  `config_value` text NOT NULL COMMENT '配置值',
  `config_desc` varchar(255) DEFAULT NULL COMMENT '配置描述',
  `config_type` varchar(32) DEFAULT NULL COMMENT '配置类型',
  `is_enabled` tinyint(4) DEFAULT 1 COMMENT '启用标记',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '删除标记',
  `create_date` datetime DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='数据需求配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_requirement_config`
--

LOCK TABLES `data_requirement_config` WRITE;
/*!40000 ALTER TABLE `data_requirement_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_requirement_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_requirement_match`
--

DROP TABLE IF EXISTS `data_requirement_match`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_requirement_match` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `requirement_id` bigint(20) NOT NULL COMMENT '需求ID',
  `resource_id` bigint(20) NOT NULL COMMENT '资源ID',
  `match_score` decimal(5,2) DEFAULT 0.00 COMMENT '匹配得分',
  `match_status` tinyint(4) DEFAULT 0 COMMENT '匹配状态',
  `match_type` varchar(32) DEFAULT NULL COMMENT '匹配类型',
  `match_details` text DEFAULT NULL COMMENT '匹配详情(JSON)',
  `confirm_user_id` bigint(20) DEFAULT NULL COMMENT '确认人ID',
  `confirm_user_name` varchar(64) DEFAULT NULL COMMENT '确认人',
  `confirm_date` datetime DEFAULT NULL COMMENT '确认时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '删除标记',
  `create_date` datetime DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_requirement_id` (`requirement_id`),
  KEY `idx_resource_id` (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='数据需求匹配表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_requirement_match`
--

LOCK TABLES `data_requirement_match` WRITE;
/*!40000 ALTER TABLE `data_requirement_match` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_requirement_match` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_resource`
--

DROP TABLE IF EXISTS `data_resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_resource` (
  `resource_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '资源id',
  `resource_name` varchar(255) DEFAULT NULL COMMENT '资源名称',
  `resource_desc` varchar(255) DEFAULT NULL COMMENT '资源描述',
  `resource_sort_type` int(2) DEFAULT NULL COMMENT '资源分类（银行，电商，媒体，运营商，保险）',
  `resource_auth_type` int(1) DEFAULT NULL COMMENT '授权类型（公开，私有）',
  `resource_source` int(1) DEFAULT NULL COMMENT '资源来源（文件上传，数据库链接）',
  `resource_num` int(8) DEFAULT NULL COMMENT '资源数',
  `file_id` bigint(20) DEFAULT NULL COMMENT '文件id',
  `file_size` bigint(20) DEFAULT NULL COMMENT '文件大小',
  `file_suffix` varchar(255) DEFAULT NULL COMMENT '文件后缀',
  `file_rows` bigint(20) DEFAULT NULL COMMENT '文件行数',
  `file_columns` int(8) DEFAULT NULL COMMENT '文件列数',
  `file_handle_status` tinyint(4) DEFAULT NULL COMMENT '文件处理状态',
  `file_handle_field` mediumtext DEFAULT NULL COMMENT '文件头字段',
  `file_contains_y` tinyint(4) DEFAULT 0 COMMENT '文件字段是否包含y字段 0否 1是',
  `file_y_rows` int(11) DEFAULT 0 COMMENT '文件字段y值内容不为空的行数',
  `file_y_ratio` decimal(8,4) DEFAULT 0.0000 COMMENT '文件字段y值内容不为空的行数在总行的占比',
  `public_organ_id` varchar(3072) DEFAULT NULL COMMENT '机构列表',
  `resource_fusion_id` varchar(255) DEFAULT NULL COMMENT '中心节点资源ID',
  `db_id` int(8) DEFAULT NULL COMMENT '数据库id',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户id',
  `organ_id` bigint(20) DEFAULT NULL COMMENT '机构id',
  `url` varchar(255) DEFAULT NULL COMMENT '资源表示路径',
  `resource_hash_code` varchar(255) DEFAULT NULL COMMENT '资源hash值',
  `resource_state` tinyint(4) NOT NULL DEFAULT 0 COMMENT '资源状态 0上线 1下线',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`resource_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='资源表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_resource`
--

LOCK TABLES `data_resource` WRITE;
/*!40000 ALTER TABLE `data_resource` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_resource_auth_record`
--

DROP TABLE IF EXISTS `data_resource_auth_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_resource_auth_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `resource_id` varchar(255) DEFAULT NULL,
  `auth_organ_id` varchar(255) DEFAULT NULL,
  `auth_organ_name` varchar(255) DEFAULT NULL,
  `auth_type` int(11) DEFAULT NULL,
  `grouping` int(11) DEFAULT NULL,
  `relevance` int(11) DEFAULT NULL,
  `protection_status` int(11) DEFAULT NULL,
  `auth_status` int(11) DEFAULT 0,
  `apply_user_id` bigint(20) DEFAULT NULL,
  `apply_user_name` varchar(255) DEFAULT NULL,
  `approve_user_id` bigint(20) DEFAULT NULL,
  `approve_user_name` varchar(255) DEFAULT NULL,
  `approve_comment` text DEFAULT NULL,
  `approve_date` datetime DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  `project_id` bigint(20) DEFAULT NULL COMMENT '项目ID',
  `record_status` int(11) DEFAULT NULL COMMENT '记录状态',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户ID',
  `user_name` varchar(255) DEFAULT NULL COMMENT '用户名',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_resource_auth_record`
--

LOCK TABLES `data_resource_auth_record` WRITE;
/*!40000 ALTER TABLE `data_resource_auth_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_resource_auth_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_resource_tag`
--

DROP TABLE IF EXISTS `data_resource_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_resource_tag` (
  `tag_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '标签id',
  `tag_name` varchar(255) DEFAULT NULL COMMENT '标签名称',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`tag_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='标签表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_resource_tag`
--

LOCK TABLES `data_resource_tag` WRITE;
/*!40000 ALTER TABLE `data_resource_tag` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_resource_tag` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_resource_visibility_auth`
--

DROP TABLE IF EXISTS `data_resource_visibility_auth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_resource_visibility_auth` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `resource_id` bigint(20) NOT NULL COMMENT '资源id',
  `organ_global_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '机构唯一id',
  `organ_name` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '资源名称',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `resource_id_ix` (`resource_id`) USING BTREE,
  KEY `organ_global_id_ix` (`organ_global_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_resource_visibility_auth`
--

LOCK TABLES `data_resource_visibility_auth` WRITE;
/*!40000 ALTER TABLE `data_resource_visibility_auth` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_resource_visibility_auth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_rt`
--

DROP TABLE IF EXISTS `data_rt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_rt` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `resource_id` bigint(20) DEFAULT NULL COMMENT '资源id',
  `tag_id` bigint(20) DEFAULT NULL COMMENT '标签id',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='资源标签关系表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_rt`
--

LOCK TABLES `data_rt` WRITE;
/*!40000 ALTER TABLE `data_rt` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_rt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_script`
--

DROP TABLE IF EXISTS `data_script`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_script` (
  `script_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `catalogue` int(11) DEFAULT 0,
  `p_script_id` bigint(20) DEFAULT NULL,
  `script_type` int(11) DEFAULT NULL,
  `script_status` int(11) DEFAULT NULL,
  `script_content` blob DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `organ_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT 0,
  `create_date` timestamp NULL DEFAULT current_timestamp(),
  `update_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`script_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_script`
--

LOCK TABLES `data_script` WRITE;
/*!40000 ALTER TABLE `data_script` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_script` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_source`
--

DROP TABLE IF EXISTS `data_source`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_source` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '草稿id',
  `db_type` int(11) DEFAULT NULL COMMENT '数据库类型',
  `db_driver` varchar(100) DEFAULT NULL COMMENT '驱动类',
  `db_url` varchar(500) DEFAULT NULL COMMENT '数据源地址',
  `db_name` varchar(100) DEFAULT NULL COMMENT '数据库名称',
  `db_table_name` varchar(100) DEFAULT NULL COMMENT '数据库名称',
  `db_username` varchar(100) DEFAULT NULL COMMENT '用户名',
  `db_password` varchar(100) DEFAULT NULL COMMENT '密码',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='资源数据库';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_source`
--

LOCK TABLES `data_source` WRITE;
/*!40000 ALTER TABLE `data_source` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_source` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_task`
--

DROP TABLE IF EXISTS `data_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_task` (
  `task_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '任务id',
  `task_id_name` varchar(255) DEFAULT NULL COMMENT '任务id展示名',
  `task_name` varchar(255) DEFAULT NULL COMMENT '任务名称',
  `task_desc` varchar(255) DEFAULT NULL COMMENT '任务描述',
  `task_state` int(11) DEFAULT 0 COMMENT '任务状态(0未开始 1成功 2运行中 3失败 4取消)',
  `task_type` int(11) DEFAULT NULL COMMENT '任务类型 1、模型 2、PSI 3、PIR',
  `task_result_path` varchar(255) DEFAULT NULL COMMENT '文件返回路径',
  `task_result_content` mediumtext DEFAULT NULL COMMENT '文件返回内容',
  `task_start_time` bigint(20) DEFAULT NULL COMMENT '任务开始时间',
  `task_end_time` bigint(20) DEFAULT NULL COMMENT '任务结束时间',
  `task_user_id` bigint(20) DEFAULT NULL COMMENT '任务创建人',
  `task_error_msg` mediumtext DEFAULT NULL COMMENT '任务异常信息',
  `is_cooperation` tinyint(4) DEFAULT 0 COMMENT '是否协作任务0否 1是',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`task_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='数据任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_task`
--

LOCK TABLES `data_task` WRITE;
/*!40000 ALTER TABLE `data_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_task_execution_log`
--

DROP TABLE IF EXISTS `data_task_execution_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_task_execution_log` (
  `log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `task_id` varchar(50) NOT NULL COMMENT '任务ID',
  `task_id_name` varchar(100) DEFAULT NULL COMMENT '任务标识名称',
  `task_type` tinyint(4) DEFAULT NULL COMMENT '任务类型：1-模型 2-PSI 3-PIR 4-推理 5-联合统计',
  `component_id` bigint(20) DEFAULT NULL COMMENT '组件ID（模型任务有组件）',
  `component_name` varchar(100) DEFAULT NULL COMMENT '组件名称',
  `log_level` varchar(20) DEFAULT NULL COMMENT '日志级别：INFO/WARN/ERROR',
  `log_type` varchar(50) DEFAULT NULL COMMENT '日志类型：START/RUNNING/SUCCESS/FAIL/CANCEL',
  `log_message` text DEFAULT NULL COMMENT '日志消息',
  `execution_phase` varchar(50) DEFAULT NULL COMMENT '执行阶段（如：数据准备、模型训练、结果保存）',
  `error_code` varchar(50) DEFAULT NULL COMMENT '错误码',
  `error_stack` text DEFAULT NULL COMMENT '错误堆栈',
  `execution_time` bigint(20) DEFAULT NULL COMMENT '执行耗时（毫秒）',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除：0-否 1-是',
  `created_time` timestamp NULL DEFAULT current_timestamp() COMMENT '创建时间',
  PRIMARY KEY (`log_id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_task_type` (`task_type`),
  KEY `idx_log_level` (`log_level`),
  KEY `idx_created_time` (`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务执行日志表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_task_execution_log`
--

LOCK TABLES `data_task_execution_log` WRITE;
/*!40000 ALTER TABLE `data_task_execution_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_task_execution_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_union`
--

DROP TABLE IF EXISTS `data_union`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_union` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '求并主键',
  `own_organ_id` varchar(50) NOT NULL COMMENT '本机构id',
  `own_resource_id` varchar(50) NOT NULL COMMENT '本机构资源id',
  `own_keyword` varchar(255) NOT NULL COMMENT '本机构资源关键字',
  `other_organ_id` varchar(50) NOT NULL COMMENT '其他机构id',
  `other_resource_id` varchar(50) NOT NULL COMMENT '其他机构资源id',
  `other_keyword` varchar(255) NOT NULL COMMENT '其他机构资源关键字',
  `output_file_path_type` tinyint(4) DEFAULT 0 COMMENT '文件路径输出类型 0默认 自动生成',
  `output_no_repeat` tinyint(4) DEFAULT 0 COMMENT '输出内容是否不去重 默认0 不去重 1去重',
  `tag` tinyint(4) DEFAULT 0 COMMENT '实现方法 0:ECDH 1:KKRT 2:TEE',
  `result_name` varchar(255) NOT NULL COMMENT '结果名称',
  `output_format` varchar(50) DEFAULT 'csv' COMMENT '输出格式',
  `result_organ_ids` varchar(255) NOT NULL COMMENT '结果获取方 多机构逗号间隔',
  `remarks` text DEFAULT NULL COMMENT '备注',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `tee_organ_id` varchar(50) DEFAULT NULL COMMENT 'TEE机构ID',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_own_organ_id` (`own_organ_id`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='联邦求并主表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_union`
--

LOCK TABLES `data_union` WRITE;
/*!40000 ALTER TABLE `data_union` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_union` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_union_task`
--

DROP TABLE IF EXISTS `data_union_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_union_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '求并任务id',
  `union_id` bigint(20) NOT NULL COMMENT '求并id',
  `task_id` varchar(100) NOT NULL COMMENT '对外展示的任务uuid',
  `task_state` tinyint(4) DEFAULT 0 COMMENT '运行状态 0未运行 1完成 2运行中 3失败 4取消',
  `ascription` varchar(255) DEFAULT NULL COMMENT '结果归属',
  `ascription_type` tinyint(4) DEFAULT 0 COMMENT '结果归属类型 0一方 1双方',
  `file_rows` int(11) DEFAULT 0 COMMENT '结果文件行数',
  `file_path` varchar(500) DEFAULT NULL COMMENT '文件路径',
  `file_content` text DEFAULT NULL COMMENT '文件内容',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_union_id` (`union_id`),
  KEY `idx_task_state` (`task_state`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='联邦求并任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_union_task`
--

LOCK TABLES `data_union_task` WRITE;
/*!40000 ALTER TABLE `data_union_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_union_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_visiting_users`
--

DROP TABLE IF EXISTS `data_visiting_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_visiting_users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '来访ID',
  `familiarity_practitioner` tinyint(4) DEFAULT NULL COMMENT '从业者',
  `familiarity_AlreadyInUse` tinyint(4) DEFAULT NULL COMMENT '已在应用',
  `familiarity_veryFamiliar` tinyint(4) DEFAULT NULL COMMENT '非常熟悉',
  `familiarity_generalFamiliar` tinyint(4) DEFAULT NULL COMMENT '一般熟悉',
  `familiarity_notKnow` tinyint(4) DEFAULT NULL COMMENT '完全不懂',
  `gender_male` tinyint(4) DEFAULT NULL COMMENT '男',
  `gender_female` tinyint(4) DEFAULT NULL COMMENT '女',
  `city_beijing` tinyint(4) DEFAULT NULL COMMENT '北京',
  `city_shanghai` tinyint(4) DEFAULT NULL COMMENT '上海',
  `city_shenzhen` tinyint(4) DEFAULT NULL COMMENT '深圳',
  `city_hangzhou` tinyint(4) DEFAULT NULL COMMENT '杭州',
  `city_changsha` tinyint(4) DEFAULT NULL COMMENT '长沙',
  `industry_internet` tinyint(4) DEFAULT NULL COMMENT '互联网',
  `industry_financial` tinyint(4) DEFAULT NULL COMMENT '金融',
  `industry_government` tinyint(4) DEFAULT NULL COMMENT '政府',
  `industry_medical` tinyint(4) DEFAULT NULL COMMENT '医疗',
  `industry_industrial` tinyint(4) DEFAULT NULL COMMENT '工业',
  `industry_car` tinyint(4) DEFAULT NULL COMMENT '汽车',
  `industry_newEnergy` tinyint(4) DEFAULT NULL COMMENT '新能源',
  `industry_other` tinyint(4) DEFAULT NULL COMMENT '其他',
  `visitPurposes_cooperation` tinyint(4) DEFAULT NULL COMMENT '商业合作',
  `visitPurposes_learning` tinyint(4) DEFAULT NULL COMMENT '学习',
  `visitPurposes_trial` tinyint(4) DEFAULT NULL COMMENT '试用',
  `visitPurposes_browse` tinyint(4) DEFAULT NULL COMMENT '随便看看',
  `age_age` tinyint(4) DEFAULT NULL COMMENT '年龄',
  `jobPosition_manager` tinyint(4) DEFAULT NULL COMMENT '管理者',
  `jobPosition_PM` tinyint(4) DEFAULT NULL COMMENT '产品',
  `jobPosition_developer` tinyint(4) DEFAULT NULL COMMENT '技术',
  `jobPosition_commerceAffairs` tinyint(4) DEFAULT NULL COMMENT '商务',
  `jobPosition_solution` tinyint(4) DEFAULT NULL COMMENT '解决方案',
  `jobPosition_other` tinyint(4) DEFAULT NULL COMMENT '其他',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `create_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `update_date` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='应用市场来访用户';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_visiting_users`
--

LOCK TABLES `data_visiting_users` WRITE;
/*!40000 ALTER TABLE `data_visiting_users` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_visiting_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `evidence_api_call_log`
--

DROP TABLE IF EXISTS `evidence_api_call_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `evidence_api_call_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_key_id` bigint(20) DEFAULT NULL COMMENT '关联API密钥ID',
  `api_path` varchar(255) NOT NULL COMMENT '请求路径',
  `request_method` varchar(10) DEFAULT NULL COMMENT '请求方法',
  `request_params` text DEFAULT NULL COMMENT '请求参数',
  `response_code` int(11) DEFAULT NULL COMMENT '响应码',
  `response_body` text DEFAULT NULL COMMENT '响应体',
  `client_ip` varchar(64) DEFAULT NULL COMMENT '客户端IP',
  `execution_time` int(11) DEFAULT NULL COMMENT '执行时间(ms)',
  `status` tinyint(4) DEFAULT 1 COMMENT '状态: 0失败 1成功',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_api_key_id` (`api_key_id`),
  KEY `idx_api_path` (`api_path`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证API调用日志表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evidence_api_call_log`
--

LOCK TABLES `evidence_api_call_log` WRITE;
/*!40000 ALTER TABLE `evidence_api_call_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `evidence_api_call_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `evidence_api_key`
--

DROP TABLE IF EXISTS `evidence_api_key`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `evidence_api_key` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `api_key` varchar(128) NOT NULL COMMENT 'API密钥',
  `secret_key` varchar(256) NOT NULL COMMENT '密钥密文',
  `status` tinyint(4) DEFAULT 1 COMMENT '状态: 0禁用 1启用',
  `expiry_date` datetime DEFAULT NULL COMMENT '过期时间',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_api_key` (`api_key`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证API密钥表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evidence_api_key`
--

LOCK TABLES `evidence_api_key` WRITE;
/*!40000 ALTER TABLE `evidence_api_key` DISABLE KEYS */;
/*!40000 ALTER TABLE `evidence_api_key` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `evidence_config`
--

DROP TABLE IF EXISTS `evidence_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `evidence_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_key` varchar(64) NOT NULL COMMENT '配置键',
  `config_value` text DEFAULT NULL COMMENT '配置值',
  `config_desc` varchar(500) DEFAULT NULL COMMENT '配置说明',
  `is_encrypted` tinyint(1) DEFAULT 0 COMMENT '是否加密',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evidence_config`
--

LOCK TABLES `evidence_config` WRITE;
/*!40000 ALTER TABLE `evidence_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `evidence_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `evidence_export_record`
--

DROP TABLE IF EXISTS `evidence_export_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `evidence_export_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `evidence_id` bigint(20) DEFAULT NULL COMMENT '关联存证ID',
  `export_type` varchar(30) NOT NULL COMMENT '导出类型: plain/encrypted',
  `file_name` varchar(255) DEFAULT NULL COMMENT '文件名',
  `file_size` bigint(20) DEFAULT NULL COMMENT '文件大小',
  `is_encrypted` tinyint(1) DEFAULT 0 COMMENT '是否加密',
  `encrypt_algorithm` varchar(30) DEFAULT NULL COMMENT '加密算法',
  `status` tinyint(4) DEFAULT 0 COMMENT '状态: 0处理中 1已完成 2失败',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_evidence_id` (`evidence_id`),
  KEY `idx_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证导出记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evidence_export_record`
--

LOCK TABLES `evidence_export_record` WRITE;
/*!40000 ALTER TABLE `evidence_export_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `evidence_export_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `evidence_record`
--

DROP TABLE IF EXISTS `evidence_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `evidence_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `evidence_hash` varchar(128) NOT NULL COMMENT '存证哈希',
  `evidence_data` longtext DEFAULT NULL COMMENT '存证数据(JSON)',
  `evidence_type` varchar(50) DEFAULT NULL COMMENT '存证类型: file/text/hash',
  `file_name` varchar(255) DEFAULT NULL COMMENT '文件名',
  `file_size` bigint(20) DEFAULT NULL COMMENT '文件大小(字节)',
  `file_type` varchar(50) DEFAULT NULL COMMENT '文件MIME类型',
  `status` tinyint(4) DEFAULT 0 COMMENT '状态: 0待上链 1已上链 2已验证 3已过期',
  `block_height` bigint(20) DEFAULT NULL COMMENT '区块链高度',
  `block_hash` varchar(128) DEFAULT NULL COMMENT '区块哈希',
  `tx_hash` varchar(128) DEFAULT NULL COMMENT '交易哈希',
  `chain_type` varchar(30) DEFAULT 'FABRIC' COMMENT '区块链类型',
  `description` varchar(500) DEFAULT NULL COMMENT '存证描述',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_evidence_hash` (`evidence_hash`),
  KEY `idx_status` (`status`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evidence_record`
--

LOCK TABLES `evidence_record` WRITE;
/*!40000 ALTER TABLE `evidence_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `evidence_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `evidence_timestamp`
--

DROP TABLE IF EXISTS `evidence_timestamp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `evidence_timestamp` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `evidence_id` bigint(20) NOT NULL COMMENT '关联存证ID',
  `timestamp_value` datetime NOT NULL COMMENT '时间戳时间',
  `timestamp_hash` varchar(128) DEFAULT NULL COMMENT '时间戳哈希',
  `timestamp_source` varchar(50) DEFAULT 'LOCAL' COMMENT '时间戳来源: LOCAL/NTP/BLOCKCHAIN',
  `nonce` varchar(64) DEFAULT NULL COMMENT '随机数',
  `status` tinyint(4) DEFAULT 0 COMMENT '状态: 0待确认 1已确认 2已验证',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_evidence_id` (`evidence_id`),
  KEY `idx_timestamp_value` (`timestamp_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存证时间戳表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evidence_timestamp`
--

LOCK TABLES `evidence_timestamp` WRITE;
/*!40000 ALTER TABLE `evidence_timestamp` DISABLE KEYS */;
/*!40000 ALTER TABLE `evidence_timestamp` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_analysis_datasource`
--

DROP TABLE IF EXISTS `federated_analysis_datasource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_analysis_datasource` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `source_name` varchar(100) NOT NULL COMMENT '数据源名称',
  `source_type` varchar(30) NOT NULL COMMENT '类型: mysql/postgresql/oracle/spark/hive/flink/oss/s3',
  `source_config` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '连接参数' CHECK (json_valid(`source_config`)),
  `is_connected` tinyint(1) DEFAULT 0 COMMENT '上次连接测试结果',
  `last_test_time` datetime DEFAULT NULL COMMENT '最后测试时间',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_source_type` (`source_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦分析数据源配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_analysis_datasource`
--

LOCK TABLES `federated_analysis_datasource` WRITE;
/*!40000 ALTER TABLE `federated_analysis_datasource` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_analysis_datasource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_analysis_result`
--

DROP TABLE IF EXISTS `federated_analysis_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_analysis_result` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` bigint(20) NOT NULL COMMENT '关联任务ID',
  `result_type` varchar(30) DEFAULT 'final' COMMENT '结果类型: schema/interim/final',
  `result_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '结果数据' CHECK (json_valid(`result_data`)),
  `result_file` varchar(500) DEFAULT NULL COMMENT '结果文件路径',
  `column_metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '列元数据' CHECK (json_valid(`column_metadata`)),
  `row_count` int(11) DEFAULT NULL COMMENT '结果行数',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦分析结果表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_analysis_result`
--

LOCK TABLES `federated_analysis_result` WRITE;
/*!40000 ALTER TABLE `federated_analysis_result` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_analysis_result` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_analysis_task`
--

DROP TABLE IF EXISTS `federated_analysis_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_analysis_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_name` varchar(200) NOT NULL COMMENT '任务名称',
  `project_id` bigint(20) DEFAULT NULL COMMENT '关联项目ID',
  `source_sql` text NOT NULL COMMENT '原始SQL',
  `rewritten_sql` text DEFAULT NULL COMMENT '改写后SQL',
  `task_state` tinyint(4) DEFAULT 0 COMMENT '状态: 0待执行 1执行中 2成功 3失败',
  `task_param` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '执行参数' CHECK (json_valid(`task_param`)),
  `result_summary` varchar(500) DEFAULT NULL COMMENT '结果摘要',
  `result_row_count` int(11) DEFAULT NULL COMMENT '结果行数',
  `error_message` varchar(2000) DEFAULT NULL COMMENT '错误信息',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_task_state` (`task_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦分析任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_analysis_task`
--

LOCK TABLES `federated_analysis_task` WRITE;
/*!40000 ALTER TABLE `federated_analysis_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_analysis_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_billing_record`
--

DROP TABLE IF EXISTS `federated_billing_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_billing_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `rule_id` bigint(20) NOT NULL COMMENT '关联规则ID',
  `task_type` varchar(30) NOT NULL COMMENT '任务类型: psi/difference/union/analysis',
  `task_id` bigint(20) NOT NULL COMMENT '关联任务ID',
  `requester_organ_id` varchar(50) NOT NULL COMMENT '请求方机构ID',
  `provider_organ_id` varchar(50) DEFAULT NULL COMMENT '提供方机构ID',
  `resource_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '使用资源ID列表' CHECK (json_valid(`resource_ids`)),
  `billing_type` varchar(30) NOT NULL COMMENT '计费类型',
  `query_count` int(11) DEFAULT 0 COMMENT '查询次数',
  `hit_count` int(11) DEFAULT 0 COMMENT '命中记录数',
  `dedup_key` varchar(64) DEFAULT NULL COMMENT '去重KEY',
  `dedup_window_start` datetime DEFAULT NULL COMMENT '去重窗口开始',
  `dedup_window_end` datetime DEFAULT NULL COMMENT '去重窗口结束',
  `unit_price` decimal(12,4) DEFAULT NULL COMMENT '单价',
  `discount_rate_applied` decimal(5,4) DEFAULT NULL COMMENT '实际折扣率',
  `total_charge` decimal(12,4) NOT NULL COMMENT '总费用',
  `charge_status` tinyint(4) DEFAULT 0 COMMENT '状态: 0待结算 1已结算 2已退款',
  `billing_time` datetime NOT NULL COMMENT '计费时间',
  `settled_at` datetime DEFAULT NULL COMMENT '结算时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_type`,`task_id`),
  KEY `idx_requester` (`requester_organ_id`),
  KEY `idx_billing_time` (`billing_time`),
  KEY `idx_dedup_key` (`dedup_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦查询计费记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_billing_record`
--

LOCK TABLES `federated_billing_record` WRITE;
/*!40000 ALTER TABLE `federated_billing_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_billing_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_billing_rule`
--

DROP TABLE IF EXISTS `federated_billing_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_billing_rule` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `rule_name` varchar(100) NOT NULL COMMENT '规则名称',
  `billing_type` varchar(30) NOT NULL COMMENT '计费类型: by_count/by_hit/fixed_dedup/rolling_dedup',
  `apply_resource_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '适用资源ID列表' CHECK (json_valid(`apply_resource_ids`)),
  `apply_organ_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '适用机构ID列表' CHECK (json_valid(`apply_organ_ids`)),
  `base_fee` decimal(12,4) DEFAULT 0.0000 COMMENT '基础费',
  `min_charge` decimal(12,4) DEFAULT 0.0000 COMMENT '最低收费',
  `is_active` tinyint(1) DEFAULT 0 COMMENT '是否启用',
  `effective_from` datetime DEFAULT NULL COMMENT '生效时间',
  `effective_to` datetime DEFAULT NULL COMMENT '失效时间',
  `price_per_query` decimal(12,4) DEFAULT NULL COMMENT '每次查询价格',
  `enable_discount` tinyint(1) DEFAULT NULL COMMENT '是否启用折扣',
  `discount_threshold` int(11) DEFAULT NULL COMMENT '折扣阈值',
  `discount_rate` decimal(5,4) DEFAULT NULL COMMENT '折扣率',
  `price_per_hit` decimal(12,4) DEFAULT NULL COMMENT '每条命中价格',
  `enable_tiered` tinyint(1) DEFAULT NULL COMMENT '是否启用阶梯价',
  `tiered_pricing` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '阶梯价配置' CHECK (json_valid(`tiered_pricing`)),
  `dedup_time_window` varchar(20) DEFAULT NULL COMMENT '去重窗口',
  `price_per_unique` decimal(12,4) DEFAULT NULL COMMENT '去重后每条价格',
  `repeat_discount` decimal(5,4) DEFAULT NULL COMMENT '重复折扣',
  `rolling_window_hours` int(11) DEFAULT NULL COMMENT '滚动窗口(小时)',
  `slide_interval_hours` int(11) DEFAULT NULL COMMENT '滑动间隔(小时)',
  `rolling_price_per_unique` decimal(12,4) DEFAULT NULL COMMENT '滚动去重价格',
  `rolling_repeat_discount` decimal(5,4) DEFAULT NULL COMMENT '滚动重复折扣',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_billing_type` (`billing_type`),
  KEY `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦查询计费规则表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_billing_rule`
--

LOCK TABLES `federated_billing_rule` WRITE;
/*!40000 ALTER TABLE `federated_billing_rule` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_billing_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_learning`
--

DROP TABLE IF EXISTS `federated_learning`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_learning` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '联邦学习主键',
  `task_type` tinyint(4) NOT NULL COMMENT '任务类型 1:建模 2:预测',
  `algorithm_type` tinyint(4) NOT NULL COMMENT '算法类型 1:线性回归 2:逻辑回归 3:XGBoost',
  `federated_type` tinyint(4) NOT NULL DEFAULT 2 COMMENT '联邦类型 1:横向 2:纵向',
  `task_name` varchar(255) NOT NULL COMMENT '任务名称',
  `project_id` bigint(20) DEFAULT NULL COMMENT '项目ID',
  `own_organ_id` varchar(50) NOT NULL COMMENT '本机构id',
  `own_resource_id` varchar(50) NOT NULL COMMENT '本机构资源id',
  `own_features` text DEFAULT NULL COMMENT '本机构特征字段（逗号分隔）',
  `label_feature` varchar(255) DEFAULT NULL COMMENT '标签字段（仅标签方有值）',
  `is_label_owner` tinyint(4) DEFAULT 0 COMMENT '是否为标签方 0否 1是',
  `participant_organ_ids` varchar(255) NOT NULL COMMENT '参与机构ids（逗号分隔）',
  `participant_resource_ids` text DEFAULT NULL COMMENT '参与机构资源ids（JSON格式）',
  `training_params` text DEFAULT NULL COMMENT '训练参数（JSON格式）',
  `model_id` varchar(100) DEFAULT NULL COMMENT '模型ID（预测时使用）',
  `model_path` varchar(500) DEFAULT NULL COMMENT '模型存储路径',
  `result_path` varchar(500) DEFAULT NULL COMMENT '结果存储路径',
  `remarks` text DEFAULT NULL COMMENT '备注',
  `user_id` bigint(20) NOT NULL COMMENT '用户ID',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_own_organ_id` (`own_organ_id`),
  KEY `idx_task_type` (`task_type`),
  KEY `idx_algorithm_type` (`algorithm_type`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_create_date` (`create_date`),
  KEY `idx_model_id` (`model_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='联邦学习主表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_learning`
--

LOCK TABLES `federated_learning` WRITE;
/*!40000 ALTER TABLE `federated_learning` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_learning` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_learning_task`
--

DROP TABLE IF EXISTS `federated_learning_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_learning_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '联邦学习任务id',
  `fl_id` bigint(20) NOT NULL COMMENT '联邦学习id',
  `task_id` varchar(100) NOT NULL COMMENT '对外展示的任务uuid',
  `task_state` tinyint(4) DEFAULT 0 COMMENT '运行状态 0未运行 1完成 2运行中 3失败 4取消',
  `current_round` int(11) DEFAULT 0 COMMENT '当前轮次',
  `total_rounds` int(11) DEFAULT 0 COMMENT '总轮次',
  `accuracy` double DEFAULT NULL COMMENT '训练准确率',
  `loss` double DEFAULT NULL COMMENT '训练损失',
  `metrics` text DEFAULT NULL COMMENT '模型评估指标（JSON格式）',
  `result_rows` int(11) DEFAULT 0 COMMENT '预测结果行数',
  `result_file_path` varchar(500) DEFAULT NULL COMMENT '结果文件路径',
  `execution_log` text DEFAULT NULL COMMENT '执行日志',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` timestamp NOT NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_fl_id` (`fl_id`),
  KEY `idx_task_state` (`task_state`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='联邦学习任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_learning_task`
--

LOCK TABLES `federated_learning_task` WRITE;
/*!40000 ALTER TABLE `federated_learning_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_learning_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_query_log`
--

DROP TABLE IF EXISTS `federated_query_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_query_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` bigint(20) DEFAULT NULL COMMENT '关联任务ID',
  `log_level` varchar(10) DEFAULT 'INFO' COMMENT '日志级别: DEBUG/INFO/WARN/ERROR',
  `log_message` text DEFAULT NULL COMMENT '日志内容',
  `log_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '结构化日志数据' CHECK (json_valid(`log_data`)),
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_log_level` (`log_level`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦查询日志表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_query_log`
--

LOCK TABLES `federated_query_log` WRITE;
/*!40000 ALTER TABLE `federated_query_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_query_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_query_task`
--

DROP TABLE IF EXISTS `federated_query_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_query_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_name` varchar(200) NOT NULL COMMENT '任务名称',
  `algorithm` varchar(30) NOT NULL COMMENT '算法: DH/OT/HE',
  `query_mode` varchar(30) NOT NULL COMMENT '模式: batch/realtime',
  `query_type` varchar(30) DEFAULT 'psi' COMMENT '查询类型: psi/difference/union',
  `task_state` tinyint(4) DEFAULT 0 COMMENT '状态: 0待执行 1执行中 2成功 3失败',
  `source_config` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '数据源配置' CHECK (json_valid(`source_config`)),
  `result_summary` varchar(500) DEFAULT NULL COMMENT '结果摘要',
  `result_row_count` int(11) DEFAULT NULL COMMENT '结果行数',
  `error_message` varchar(2000) DEFAULT NULL COMMENT '错误信息',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_algorithm` (`algorithm`),
  KEY `idx_task_state` (`task_state`),
  KEY `idx_created_by` (`created_by`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦查询任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_query_task`
--

LOCK TABLES `federated_query_task` WRITE;
/*!40000 ALTER TABLE `federated_query_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_query_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_stats_config`
--

DROP TABLE IF EXISTS `federated_stats_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_stats_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_name` varchar(100) NOT NULL COMMENT '配置名称',
  `storage_type` varchar(30) NOT NULL COMMENT '存储类型: local/oss/s3',
  `storage_path` varchar(500) DEFAULT NULL COMMENT '存储路径',
  `connection_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '连接参数' CHECK (json_valid(`connection_json`)),
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦统计存储配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_stats_config`
--

LOCK TABLES `federated_stats_config` WRITE;
/*!40000 ALTER TABLE `federated_stats_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_stats_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_stats_result`
--

DROP TABLE IF EXISTS `federated_stats_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_stats_result` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` bigint(20) NOT NULL COMMENT '关联任务ID',
  `result_type` varchar(30) DEFAULT 'final' COMMENT '结果类型: interim/final',
  `result_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '结果数据' CHECK (json_valid(`result_data`)),
  `result_file` varchar(500) DEFAULT NULL COMMENT '结果文件路径',
  `row_count` int(11) DEFAULT NULL COMMENT '结果行数',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦统计结果表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_stats_result`
--

LOCK TABLES `federated_stats_result` WRITE;
/*!40000 ALTER TABLE `federated_stats_result` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_stats_result` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_stats_task`
--

DROP TABLE IF EXISTS `federated_stats_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_stats_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_name` varchar(200) NOT NULL COMMENT '任务名称',
  `project_id` bigint(20) DEFAULT NULL COMMENT '关联项目ID',
  `stats_type` varchar(50) NOT NULL COMMENT '统计类型: descriptive/group_by/conditional/proportion/t_test/f_test/chi_square/regression/correlation',
  `algorithm_type` varchar(30) DEFAULT NULL COMMENT '算法类型: DH/OT/HE',
  `task_state` tinyint(4) DEFAULT 0 COMMENT '状态: 0待执行 1执行中 2成功 3失败 4取消',
  `task_param` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '任务参数' CHECK (json_valid(`task_param`)),
  `result_summary` varchar(500) DEFAULT NULL COMMENT '结果摘要',
  `error_message` varchar(2000) DEFAULT NULL COMMENT '错误信息',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_stats_type` (`stats_type`),
  KEY `idx_task_state` (`task_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='联邦统计任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_stats_task`
--

LOCK TABLES `federated_stats_task` WRITE;
/*!40000 ALTER TABLE `federated_stats_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_stats_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `federated_stats_task_log`
--

DROP TABLE IF EXISTS `federated_stats_task_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `federated_stats_task_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` bigint(20) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `project_id` bigint(20) DEFAULT NULL,
  `stats_type` int(11) DEFAULT NULL,
  `algorithm_type` int(11) DEFAULT NULL,
  `task_state` int(11) DEFAULT 0,
  `task_param` text DEFAULT NULL,
  `result_type` int(11) DEFAULT NULL,
  `result_data` text DEFAULT NULL,
  `result_file` varchar(512) DEFAULT NULL,
  `result_summary` text DEFAULT NULL,
  `row_count` bigint(20) DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `federated_stats_task_log`
--

LOCK TABLES `federated_stats_task_log` WRITE;
/*!40000 ALTER TABLE `federated_stats_task_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `federated_stats_task_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fl_workflow`
--

DROP TABLE IF EXISTS `fl_workflow`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fl_workflow` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_id` varchar(64) DEFAULT NULL,
  `workflow_name` varchar(255) DEFAULT NULL,
  `participants` text DEFAULT NULL,
  `dataset_id` varchar(141) DEFAULT NULL,
  `dataset_name` varchar(255) DEFAULT NULL,
  `rounds` int(11) DEFAULT 100,
  `learning_rate` double DEFAULT 0.01,
  `nodes` mediumtext DEFAULT NULL,
  `status` tinyint(4) DEFAULT 0,
  `result_summary` varchar(1000) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `user_name` varchar(64) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `create_date` datetime DEFAULT current_timestamp(),
  `update_date` datetime DEFAULT current_timestamp(),
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_wf` (`workflow_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='联邦建模工作流';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fl_workflow`
--

LOCK TABLES `fl_workflow` WRITE;
/*!40000 ALTER TABLE `fl_workflow` DISABLE KEYS */;
/*!40000 ALTER TABLE `fl_workflow` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fl_workflow_log`
--

DROP TABLE IF EXISTS `fl_workflow_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fl_workflow_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_id` varchar(64) DEFAULT NULL,
  `log_level` varchar(16) DEFAULT 'info',
  `log_content` varchar(2000) DEFAULT NULL,
  `create_date` datetime DEFAULT current_timestamp(),
  `is_del` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_wf` (`workflow_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='联邦建模工作流日志';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fl_workflow_log`
--

LOCK TABLES `fl_workflow_log` WRITE;
/*!40000 ALTER TABLE `fl_workflow_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `fl_workflow_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `monitor_alert_config`
--

DROP TABLE IF EXISTS `monitor_alert_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `monitor_alert_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `monitor_type` varchar(30) NOT NULL COMMENT '监控类型: CPU/MEMORY/DISK/DATABASE/JVM/REDIS',
  `threshold` decimal(10,2) NOT NULL COMMENT '告警阈值',
  `duration` int(11) DEFAULT 300 COMMENT '持续时长(秒)',
  `alert_level` tinyint(4) DEFAULT 1 COMMENT '告警级别: 1警告 2严重 3紧急',
  `notify_method` varchar(50) DEFAULT NULL COMMENT '通知方式: email/sms/webhook',
  `notify_target` varchar(500) DEFAULT NULL COMMENT '通知目标',
  `is_enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_monitor_type` (`monitor_type`),
  KEY `idx_is_enabled` (`is_enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='监控告警配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `monitor_alert_config`
--

LOCK TABLES `monitor_alert_config` WRITE;
/*!40000 ALTER TABLE `monitor_alert_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `monitor_alert_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `monitor_alert_history`
--

DROP TABLE IF EXISTS `monitor_alert_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `monitor_alert_history` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_id` bigint(20) DEFAULT NULL COMMENT '关联配置ID',
  `monitor_type` varchar(30) NOT NULL COMMENT '监控类型',
  `alert_level` tinyint(4) DEFAULT 1 COMMENT '告警级别',
  `alert_value` decimal(10,2) DEFAULT NULL COMMENT '触发值',
  `threshold` decimal(10,2) DEFAULT NULL COMMENT '阈值',
  `message` varchar(1000) DEFAULT NULL COMMENT '告警消息',
  `status` tinyint(4) DEFAULT 0 COMMENT '状态: 0未处理 1已处理 2已忽略',
  `handled_by` bigint(20) DEFAULT NULL COMMENT '处理人',
  `handled_at` datetime DEFAULT NULL COMMENT '处理时间',
  `handle_remark` varchar(500) DEFAULT NULL COMMENT '处理备注',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_config_id` (`config_id`),
  KEY `idx_monitor_type` (`monitor_type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='监控告警历史表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `monitor_alert_history`
--

LOCK TABLES `monitor_alert_history` WRITE;
/*!40000 ALTER TABLE `monitor_alert_history` DISABLE KEYS */;
/*!40000 ALTER TABLE `monitor_alert_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `monitor_record`
--

DROP TABLE IF EXISTS `monitor_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `monitor_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `monitor_type` varchar(30) NOT NULL COMMENT '监控类型: CPU/MEMORY/DISK/DATABASE/JVM/REDIS',
  `metric_name` varchar(100) NOT NULL COMMENT '指标名称',
  `metric_value` decimal(15,4) NOT NULL COMMENT '指标值',
  `unit` varchar(20) DEFAULT NULL COMMENT '单位',
  `extra_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '扩展数据' CHECK (json_valid(`extra_data`)),
  `recorded_at` datetime NOT NULL COMMENT '记录时间',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_monitor_type` (`monitor_type`),
  KEY `idx_metric_name` (`metric_name`),
  KEY `idx_recorded_at` (`recorded_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='监控记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `monitor_record`
--

LOCK TABLES `monitor_record` WRITE;
/*!40000 ALTER TABLE `monitor_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `monitor_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node_access_party`
--

DROP TABLE IF EXISTS `node_access_party`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `node_access_party` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `organ_id` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `organ_gateway` varchar(512) DEFAULT NULL,
  `apply_reason` text DEFAULT NULL,
  `access_level` int(11) DEFAULT NULL,
  `ip_whitelist` text DEFAULT NULL,
  `valid_from` datetime DEFAULT NULL,
  `valid_until` datetime DEFAULT NULL,
  `apply_status` int(11) DEFAULT 0,
  `approve_user_id` bigint(20) DEFAULT NULL,
  `approve_user_name` varchar(255) DEFAULT NULL,
  `approve_comment` text DEFAULT NULL,
  `approve_date` datetime DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 0,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node_access_party`
--

LOCK TABLES `node_access_party` WRITE;
/*!40000 ALTER TABLE `node_access_party` DISABLE KEYS */;
/*!40000 ALTER TABLE `node_access_party` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node_approval_config`
--

DROP TABLE IF EXISTS `node_approval_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `node_approval_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `organ_id` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `workflow_type` varchar(64) DEFAULT NULL,
  `is_enabled` tinyint(1) DEFAULT 1,
  `steps_count` int(11) DEFAULT 1,
  `notification_enabled` tinyint(1) DEFAULT 0,
  `notification_emails` text DEFAULT NULL,
  `auto_approve_rules` text DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node_approval_config`
--

LOCK TABLES `node_approval_config` WRITE;
/*!40000 ALTER TABLE `node_approval_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `node_approval_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node_approval_step`
--

DROP TABLE IF EXISTS `node_approval_step`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `node_approval_step` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_id` bigint(20) DEFAULT NULL,
  `step_number` int(11) DEFAULT NULL,
  `step_name` varchar(255) DEFAULT NULL,
  `approver_id` bigint(20) DEFAULT NULL,
  `approver_name` varchar(255) DEFAULT NULL,
  `approver_role` varchar(255) DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `comment` text DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `attachments` text DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node_approval_step`
--

LOCK TABLES `node_approval_step` WRITE;
/*!40000 ALTER TABLE `node_approval_step` DISABLE KEYS */;
/*!40000 ALTER TABLE `node_approval_step` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node_approval_workflow`
--

DROP TABLE IF EXISTS `node_approval_workflow`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `node_approval_workflow` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_type` varchar(64) DEFAULT NULL,
  `workflow_title` varchar(255) DEFAULT NULL,
  `organ_id` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `request_data` text DEFAULT NULL,
  `current_step` int(11) DEFAULT 0,
  `total_steps` int(11) DEFAULT 0,
  `status` int(11) DEFAULT 0,
  `requester_id` bigint(20) DEFAULT NULL,
  `requester_name` varchar(255) DEFAULT NULL,
  `requester_comment` text DEFAULT NULL,
  `final_approver_id` bigint(20) DEFAULT NULL,
  `final_approver_name` varchar(255) DEFAULT NULL,
  `final_comment` text DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node_approval_workflow`
--

LOCK TABLES `node_approval_workflow` WRITE;
/*!40000 ALTER TABLE `node_approval_workflow` DISABLE KEYS */;
/*!40000 ALTER TABLE `node_approval_workflow` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node_cooperation_party`
--

DROP TABLE IF EXISTS `node_cooperation_party`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `node_cooperation_party` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `organ_id` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `organ_gateway` varchar(512) DEFAULT NULL,
  `cooperation_type` int(11) DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `agreement_file_path` varchar(512) DEFAULT NULL,
  `sla_uptime_target` double DEFAULT NULL,
  `sla_response_time` int(11) DEFAULT NULL,
  `health_score` double DEFAULT NULL,
  `data_sent_count` bigint(20) DEFAULT 0,
  `data_received_count` bigint(20) DEFAULT 0,
  `last_activity_time` datetime DEFAULT NULL,
  `cooperation_status` int(11) DEFAULT 0,
  `initiated_by_us` tinyint(1) DEFAULT 0,
  `created_by` bigint(20) DEFAULT NULL,
  `created_by_name` varchar(255) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node_cooperation_party`
--

LOCK TABLES `node_cooperation_party` WRITE;
/*!40000 ALTER TABLE `node_cooperation_party` DISABLE KEYS */;
/*!40000 ALTER TABLE `node_cooperation_party` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node_data_exchange_log`
--

DROP TABLE IF EXISTS `node_data_exchange_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `node_data_exchange_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `exchange_id` varchar(255) DEFAULT NULL,
  `source_organ_id` varchar(255) DEFAULT NULL,
  `source_organ_name` varchar(255) DEFAULT NULL,
  `target_organ_id` varchar(255) DEFAULT NULL,
  `target_organ_name` varchar(255) DEFAULT NULL,
  `exchange_type` varchar(64) DEFAULT NULL,
  `data_type` varchar(64) DEFAULT NULL,
  `data_id` varchar(255) DEFAULT NULL,
  `data_name` varchar(255) DEFAULT NULL,
  `data_size` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `error_msg` text DEFAULT NULL,
  `retry_count` int(11) DEFAULT 0,
  `started_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `duration_ms` bigint(20) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node_data_exchange_log`
--

LOCK TABLES `node_data_exchange_log` WRITE;
/*!40000 ALTER TABLE `node_data_exchange_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `node_data_exchange_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_ledger_export`
--

DROP TABLE IF EXISTS `project_ledger_export`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_ledger_export` (
  `export_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `export_type` varchar(16) DEFAULT NULL,
  `export_format` varchar(16) DEFAULT NULL,
  `project_count` int(11) DEFAULT 0,
  `project_ids` varchar(4000) DEFAULT NULL,
  `export_status` tinyint(4) DEFAULT 1,
  `export_user_id` bigint(20) DEFAULT NULL,
  `export_user_name` varchar(64) DEFAULT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `file_content` mediumtext DEFAULT NULL,
  `error_msg` varchar(500) DEFAULT NULL,
  `export_date` datetime DEFAULT current_timestamp(),
  `is_del` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`export_id`),
  KEY `idx_user` (`export_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='项目台账导出记录';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_ledger_export`
--

LOCK TABLES `project_ledger_export` WRITE;
/*!40000 ALTER TABLE `project_ledger_export` DISABLE KEYS */;
/*!40000 ALTER TABLE `project_ledger_export` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_permission`
--

DROP TABLE IF EXISTS `project_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_permission` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `project_id` varchar(141) DEFAULT NULL,
  `project_name` varchar(255) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `permission_type` varchar(32) DEFAULT NULL,
  `permission_status` tinyint(4) DEFAULT 0,
  `template_id` bigint(20) DEFAULT NULL,
  `resource_ids` varchar(2000) DEFAULT NULL,
  `grant_date` datetime DEFAULT NULL,
  `expire_date` datetime DEFAULT NULL,
  `grant_user_id` bigint(20) DEFAULT NULL,
  `grant_user_name` varchar(64) DEFAULT NULL,
  `revoke_user_id` bigint(20) DEFAULT NULL,
  `revoke_user_name` varchar(64) DEFAULT NULL,
  `remark` varchar(500) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT 0,
  `create_date` datetime DEFAULT current_timestamp(),
  `update_date` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_status` (`permission_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='项目权限';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_permission`
--

LOCK TABLES `project_permission` WRITE;
/*!40000 ALTER TABLE `project_permission` DISABLE KEYS */;
/*!40000 ALTER TABLE `project_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_permission_template`
--

DROP TABLE IF EXISTS `project_permission_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_permission_template` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `template_name` varchar(255) DEFAULT NULL,
  `template_desc` varchar(500) DEFAULT NULL,
  `permissions` varchar(255) DEFAULT NULL,
  `create_user_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT 0,
  `create_date` datetime DEFAULT current_timestamp(),
  `update_date` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='项目权限模板';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_permission_template`
--

LOCK TABLES `project_permission_template` WRITE;
/*!40000 ALTER TABLE `project_permission_template` DISABLE KEYS */;
/*!40000 ALTER TABLE `project_permission_template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_result`
--

DROP TABLE IF EXISTS `project_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_result` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `project_id` varchar(141) DEFAULT NULL,
  `project_name` varchar(255) DEFAULT NULL,
  `task_id` varchar(141) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `result_type` varchar(32) DEFAULT NULL,
  `result_name` varchar(255) DEFAULT NULL,
  `result_desc` varchar(500) DEFAULT NULL,
  `save_status` tinyint(4) DEFAULT 0,
  `file_size` bigint(20) DEFAULT NULL,
  `file_md5` varchar(64) DEFAULT NULL,
  `save_path` varchar(500) DEFAULT NULL,
  `save_directory` varchar(255) DEFAULT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `save_format` varchar(32) DEFAULT NULL,
  `file_content` mediumtext DEFAULT NULL,
  `remark` varchar(500) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `create_date` datetime DEFAULT current_timestamp(),
  `save_date` datetime DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`),
  KEY `idx_status` (`save_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='项目结果保存';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_result`
--

LOCK TABLES `project_result` WRITE;
/*!40000 ALTER TABLE `project_result` DISABLE KEYS */;
/*!40000 ALTER TABLE `project_result` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_result_config`
--

DROP TABLE IF EXISTS `project_result_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_result_config` (
  `id` bigint(20) NOT NULL,
  `default_path` varchar(255) DEFAULT '/data/results',
  `auto_save` tinyint(4) DEFAULT 0,
  `retention_days` int(11) DEFAULT 30,
  `max_storage_gb` int(11) DEFAULT 100,
  `update_date` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='项目结果保存配置';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_result_config`
--

LOCK TABLES `project_result_config` WRITE;
/*!40000 ALTER TABLE `project_result_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `project_result_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scene_api_config`
--

DROP TABLE IF EXISTS `scene_api_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `scene_api_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `scene_type` varchar(50) NOT NULL COMMENT '场景类型',
  `api_name` varchar(100) NOT NULL COMMENT '接口名称',
  `api_url` varchar(500) DEFAULT NULL COMMENT '接口地址',
  `protocol` varchar(20) DEFAULT 'REST' COMMENT '协议',
  `auth_type` varchar(30) DEFAULT NULL COMMENT '鉴权类型',
  `api_key` varchar(500) DEFAULT NULL COMMENT 'API密钥',
  `status` tinyint(4) DEFAULT 1 COMMENT '状态',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景API配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scene_api_config`
--

LOCK TABLES `scene_api_config` WRITE;
/*!40000 ALTER TABLE `scene_api_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `scene_api_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scene_data_source`
--

DROP TABLE IF EXISTS `scene_data_source`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `scene_data_source` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `source_name` varchar(200) NOT NULL COMMENT '数据源名称',
  `source_type` varchar(50) DEFAULT NULL COMMENT '数据源类型: mysql/oracle/postgresql/api等',
  `department` varchar(200) DEFAULT NULL COMMENT '所属部门',
  `host` varchar(255) DEFAULT NULL COMMENT '主机地址',
  `port` int(11) DEFAULT NULL COMMENT '端口',
  `db_name` varchar(200) DEFAULT NULL COMMENT '数据库名',
  `username` varchar(200) DEFAULT NULL COMMENT '用户名',
  `password` varchar(500) DEFAULT NULL COMMENT '密码',
  `connection_info` varchar(1000) DEFAULT NULL COMMENT '连接信息描述',
  `data_count` bigint(20) DEFAULT 0 COMMENT '数据量',
  `status` tinyint(4) DEFAULT 0 COMMENT '状态: 1已连接 0未连接',
  `last_sync_time` datetime DEFAULT NULL COMMENT '最近同步时间',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_source_type` (`source_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景数据源对接表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scene_data_source`
--

LOCK TABLES `scene_data_source` WRITE;
/*!40000 ALTER TABLE `scene_data_source` DISABLE KEYS */;
/*!40000 ALTER TABLE `scene_data_source` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scene_data_sync_record`
--

DROP TABLE IF EXISTS `scene_data_sync_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `scene_data_sync_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `source_id` bigint(20) DEFAULT NULL COMMENT '数据源ID',
  `source_name` varchar(200) DEFAULT NULL COMMENT '数据源名称',
  `sync_type` varchar(50) DEFAULT NULL COMMENT '同步类型: manual/auto',
  `record_count` bigint(20) DEFAULT 0 COMMENT '同步记录数',
  `duration` varchar(50) DEFAULT NULL COMMENT '耗时',
  `status` tinyint(4) DEFAULT 1 COMMENT '状态: 1成功 0失败',
  `sync_time` datetime DEFAULT current_timestamp() COMMENT '同步时间',
  PRIMARY KEY (`id`),
  KEY `idx_source_id` (`source_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景数据源同步记录表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scene_data_sync_record`
--

LOCK TABLES `scene_data_sync_record` WRITE;
/*!40000 ALTER TABLE `scene_data_sync_record` DISABLE KEYS */;
/*!40000 ALTER TABLE `scene_data_sync_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scene_imported_data`
--

DROP TABLE IF EXISTS `scene_imported_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `scene_imported_data` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `scene_type` varchar(64) NOT NULL COMMENT '场景类型: electronic_cert / police_fusion',
  `task_id` bigint(20) DEFAULT NULL COMMENT '关联 scene_task.id',
  `batch_no` varchar(64) DEFAULT NULL COMMENT '导入批次号',
  `row_index` int(11) DEFAULT NULL COMMENT '批次内行号(从0起)',
  `row_json` text DEFAULT NULL COMMENT '单行数据(JSON)',
  `created_by` bigint(20) DEFAULT NULL COMMENT '导入人',
  `created_at` datetime NOT NULL DEFAULT current_timestamp() COMMENT '导入时间',
  PRIMARY KEY (`id`),
  KEY `idx_scene_type` (`scene_type`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_batch_no` (`batch_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='场景机构数据接入-真实数据行';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scene_imported_data`
--

LOCK TABLES `scene_imported_data` WRITE;
/*!40000 ALTER TABLE `scene_imported_data` DISABLE KEYS */;
/*!40000 ALTER TABLE `scene_imported_data` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scene_key_config`
--

DROP TABLE IF EXISTS `scene_key_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `scene_key_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `scene_type` varchar(50) NOT NULL COMMENT '场景类型',
  `key_name` varchar(100) NOT NULL COMMENT '密钥名称',
  `scheme` varchar(30) DEFAULT NULL COMMENT '加密方案: BFV/CKKS/BGV',
  `public_key` text DEFAULT NULL COMMENT '公钥',
  `private_key` text DEFAULT NULL COMMENT '私钥',
  `key_size` int(11) DEFAULT NULL COMMENT '密钥长度',
  `status` tinyint(4) DEFAULT 1 COMMENT '状态',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景密钥配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scene_key_config`
--

LOCK TABLES `scene_key_config` WRITE;
/*!40000 ALTER TABLE `scene_key_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `scene_key_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scene_task`
--

DROP TABLE IF EXISTS `scene_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `scene_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `scene_type` varchar(50) NOT NULL COMMENT '场景类型: police_fusion/electronic_cert',
  `task_name` varchar(200) NOT NULL COMMENT '任务名称',
  `task_type` varchar(50) NOT NULL COMMENT '任务子类型',
  `params` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '任务参数' CHECK (json_valid(`params`)),
  `task_state` tinyint(4) DEFAULT 0 COMMENT '状态: 0待执行 1成功 2失败',
  `result_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '结果数据' CHECK (json_valid(`result_data`)),
  `error_message` varchar(2000) DEFAULT NULL COMMENT '错误信息',
  `created_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_scene_type` (`scene_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='场景定制化任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scene_task`
--

LOCK TABLES `scene_task` WRITE;
/*!40000 ALTER TABLE `scene_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `scene_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shared_dataset`
--

DROP TABLE IF EXISTS `shared_dataset`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `shared_dataset` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `dataset_code` varchar(64) NOT NULL COMMENT '数据集编码',
  `dataset_name` varchar(255) NOT NULL COMMENT '数据集名称',
  `dataset_desc` text DEFAULT NULL COMMENT '数据集描述',
  `data_type` varchar(32) DEFAULT NULL COMMENT '数据类型',
  `data_format` varchar(32) DEFAULT NULL COMMENT '数据格式',
  `data_fields` text DEFAULT NULL COMMENT '数据字段(JSON)',
  `data_volume` bigint(20) DEFAULT NULL COMMENT '数据量',
  `share_status` int(11) DEFAULT 0 COMMENT '共享状态',
  `share_scope` int(11) DEFAULT 0 COMMENT '共享范围',
  `target_organ_ids` text DEFAULT NULL COMMENT '目标机构ID列表',
  `resource_id` bigint(20) DEFAULT NULL COMMENT '关联资源ID',
  `resource_name` varchar(255) DEFAULT NULL COMMENT '关联资源名称',
  `usage_terms` varchar(1000) DEFAULT NULL COMMENT '使用条款',
  `user_id` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `user_name` varchar(64) DEFAULT NULL COMMENT '创建人',
  `organ_id` bigint(20) DEFAULT NULL COMMENT '机构ID',
  `organ_name` varchar(128) DEFAULT NULL COMMENT '机构名称',
  `start_date` datetime DEFAULT NULL COMMENT '共享开始日期',
  `end_date` datetime DEFAULT NULL COMMENT '共享结束日期',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '删除标记',
  `create_date` datetime DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dataset_code` (`dataset_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_share_status` (`share_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='共享数据集表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shared_dataset`
--

LOCK TABLES `shared_dataset` WRITE;
/*!40000 ALTER TABLE `shared_dataset` DISABLE KEYS */;
/*!40000 ALTER TABLE `shared_dataset` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `single_party`
--

DROP TABLE IF EXISTS `single_party`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `single_party` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `algorithm_type` int(11) NOT NULL COMMENT '算法类型 1:数据统计 2:数据清洗 3:数据缩放 4:特征编码 5:特征分箱 6:特征筛选 7:特征衍生 8:LR算法 9:XGB算法 10:Python脚本',
  `task_name` varchar(255) NOT NULL COMMENT '任务名称',
  `project_id` bigint(20) DEFAULT NULL COMMENT '项目ID',
  `resource_id` varchar(100) NOT NULL COMMENT '资源ID',
  `selected_features` text DEFAULT NULL COMMENT '选择的特征字段（逗号分隔）',
  `algorithm_params` text DEFAULT NULL COMMENT '算法参数（JSON格式）',
  `result_path` varchar(500) DEFAULT NULL COMMENT '结果存储路径',
  `remarks` varchar(500) DEFAULT NULL COMMENT '备注',
  `user_id` bigint(20) DEFAULT NULL COMMENT '用户ID',
  `is_del` int(11) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` datetime DEFAULT NULL COMMENT '创建时间',
  `update_date` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  KEY `idx_algorithm_type` (`algorithm_type`),
  KEY `idx_project_id` (`project_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='单方算法表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `single_party`
--

LOCK TABLES `single_party` WRITE;
/*!40000 ALTER TABLE `single_party` DISABLE KEYS */;
/*!40000 ALTER TABLE `single_party` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `single_party_task`
--

DROP TABLE IF EXISTS `single_party_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `single_party_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `sp_id` bigint(20) NOT NULL COMMENT '单方算法ID',
  `task_id` varchar(100) NOT NULL COMMENT '任务UUID',
  `task_state` int(11) DEFAULT 0 COMMENT '运行状态 0未运行 1完成 2运行中 3失败 4取消',
  `result_rows` int(11) DEFAULT NULL COMMENT '结果行数',
  `result_file_path` varchar(500) DEFAULT NULL COMMENT '结果文件路径',
  `execution_log` text DEFAULT NULL COMMENT '执行日志',
  `is_del` int(11) DEFAULT 0 COMMENT '是否删除 0否 1是',
  `create_date` datetime DEFAULT NULL COMMENT '创建时间',
  `update_date` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_sp_id` (`sp_id`),
  KEY `idx_task_state` (`task_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='单方算法任务表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `single_party_task`
--

LOCK TABLES `single_party_task` WRITE;
/*!40000 ALTER TABLE `single_party_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `single_party_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sp_ext_log`
--

DROP TABLE IF EXISTS `sp_ext_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sp_ext_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(141) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `task_category` varchar(16) DEFAULT NULL,
  `log_level` varchar(16) DEFAULT 'INFO',
  `log_content` varchar(2000) DEFAULT NULL,
  `create_date` datetime DEFAULT current_timestamp(),
  `is_del` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='单方作业学习日志';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sp_ext_log`
--

LOCK TABLES `sp_ext_log` WRITE;
/*!40000 ALTER TABLE `sp_ext_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `sp_ext_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sp_ext_task`
--

DROP TABLE IF EXISTS `sp_ext_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sp_ext_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(141) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `task_category` varchar(16) DEFAULT 'PREPROCESS',
  `algorithm_type` int(11) DEFAULT NULL,
  `sub_type` varchar(32) DEFAULT NULL,
  `resource_id` varchar(141) DEFAULT NULL,
  `resource_name` varchar(255) DEFAULT NULL,
  `params` text DEFAULT NULL,
  `task_state` tinyint(4) DEFAULT 0,
  `progress` int(11) DEFAULT 0,
  `result_content` mediumtext DEFAULT NULL,
  `result_path` varchar(500) DEFAULT NULL,
  `error_msg` varchar(1000) DEFAULT NULL,
  `remark` varchar(500) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `user_name` varchar(64) DEFAULT NULL,
  `organ_id` varchar(64) DEFAULT NULL,
  `create_date` datetime DEFAULT current_timestamp(),
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_cat` (`task_category`),
  KEY `idx_state` (`task_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='单方作业预处理/脚本任务';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sp_ext_task`
--

LOCK TABLES `sp_ext_task` WRITE;
/*!40000 ALTER TABLE `sp_ext_task` DISABLE KEYS */;
/*!40000 ALTER TABLE `sp_ext_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_auth`
--

DROP TABLE IF EXISTS `sys_auth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_auth` (
  `auth_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '权限id',
  `auth_name` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '权限名称',
  `auth_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `auth_type` tinyint(4) NOT NULL COMMENT '权限类型 1 菜单 2 列表 3 按钮',
  `p_auth_id` bigint(20) NOT NULL COMMENT '父id',
  `r_auth_id` bigint(20) NOT NULL COMMENT '根id',
  `full_path` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '完整路径',
  `auth_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '过滤路径',
  `data_auth_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '数据权限代码',
  `auth_index` int(16) NOT NULL COMMENT '顺序',
  `auth_depth` int(16) NOT NULL COMMENT '深度',
  `is_show` tinyint(4) NOT NULL COMMENT '是否展示',
  `is_editable` tinyint(4) NOT NULL COMMENT '是否可编辑',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`auth_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=26271 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='权限表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_auth`
--

LOCK TABLES `sys_auth` WRITE;
/*!40000 ALTER TABLE `sys_auth` DISABLE KEYS */;
INSERT INTO `sys_auth` VALUES
(1001,'项目管理','Project',1,0,1001,'1001','','own',1,0,1,1,0,'2022-09-14 08:41:41.172','2022-09-14 08:41:41.178'),
(1002,'项目列表','ProjectList',2,1001,1001,'1001,1002','/project/getProjectList','own',1,1,1,1,0,'2022-09-14 08:41:41.181','2022-09-14 08:41:41.182'),
(1003,'项目详情','ProjectDetail',3,1001,1001,'1001,1003','/project/getProjectDetails','own',2,1,1,1,0,'2022-09-14 08:41:41.183','2022-09-14 08:41:41.185'),
(1004,'任务详情','ModelTaskDetail',3,1001,1001,'1001,1004','/project/getProjectDetails','own',3,1,1,1,0,'2022-09-14 08:41:41.186','2022-09-14 08:41:41.188'),
(1005,'新建项目','ProjectCreate',3,1002,1001,'1001,1002,1005','/project/saveOrUpdateProject','own',1,2,1,1,0,'2022-09-14 08:41:41.189','2022-09-14 08:41:41.191'),
(1006,'关闭项目','ProjectDelete',3,1002,1001,'1001,1002,1006','/project/closeProject','own',2,2,1,1,0,'2022-09-14 08:41:41.192','2022-09-14 08:41:41.194'),
(1007,'模型管理','Model',1,0,1007,'1007','/model/getmodellist','own',2,0,1,1,0,'2022-09-14 08:41:41.195','2022-09-14 08:41:41.197'),
(1008,'模型列表','ModelList',2,1007,1007,'1007,1008','/model/getmodellist','own',1,1,1,1,0,'2022-09-14 08:41:41.198','2022-09-14 08:41:41.200'),
(1009,'模型详情','ModelDetail',3,1008,1007,'1007,1008,1009','/model/getdatamodel','own',1,2,1,1,0,'2022-09-14 08:41:41.201','2022-09-14 08:41:41.202'),
(1010,'模型查看','ModelView',3,1008,1007,'1007,1008,1010','/model/getdatamodel','own',2,2,1,1,0,'2022-09-14 08:41:41.204','2022-09-14 08:41:41.205'),
(1011,'添加模型','ModelCreate',3,1008,1007,'1007,1008,1011','/model/saveModelAndComponent','own',3,2,1,1,0,'2022-09-14 08:41:41.206','2022-09-14 08:41:41.208'),
(1012,'模型编辑','ModelEdit',3,1008,1007,'1007,1008,1012','/model/saveModelAndComponent','own',4,2,1,1,0,'2022-09-14 08:41:41.209','2022-09-14 08:41:41.211'),
(1013,'执行记录列表','ModelTaskHistory',3,1008,1007,'1007,1008,1013','/task/saveModelAndComponent','own',5,2,1,1,0,'2022-09-14 08:41:41.212','2022-09-14 08:41:41.214'),
(1014,'模型运行','ModelRun',3,1008,1007,'1007,1008,1014','/model/runTaskModel','own',6,2,1,1,0,'2022-09-14 08:41:41.215','2022-09-14 08:41:41.216'),
(1015,'下载结果','ModelResultDownload',3,1008,1007,'1007,1008,1015','/task/downloadTaskFile','own',7,2,1,1,0,'2022-09-14 08:41:41.219','2022-09-14 08:41:41.221'),
(1016,'匿踪查询','PrivateSearch',1,0,1016,'1016','/fusionResource/getResourceList','own',3,0,1,1,0,'2022-09-14 08:41:41.223','2022-09-14 08:41:41.224'),
(1017,'匿踪查询按钮','PrivateSearchButton',3,1016,1016,'1016,1017','/pir/pirSubmitTask','own',1,1,1,1,0,'2022-09-14 08:41:41.226','2022-09-14 08:41:41.227'),
(1018,'匿踪查询列表','PrivateSearchList',2,1016,1016,'1016,1018','/pir/downloadPirTask','own',2,1,1,1,0,'2022-09-14 08:41:41.229','2022-09-14 08:41:41.230'),
(1019,'隐私求交','PSI',1,0,1019,'1019','','own',4,0,1,1,0,'2022-09-14 08:41:41.232','2022-09-14 08:41:41.234'),
(1020,'求交任务','PSITask',2,1019,1019,'1019,1020','/psi/getPsiResourceAllocationList','own',1,1,1,1,0,'2022-09-14 08:41:41.236','2022-09-14 08:41:41.237'),
(1021,'求交结果','PSIList',2,1019,1019,'1019,1021','/psi/getPsiTaskList','own',2,1,1,1,0,'2022-09-14 08:41:41.238','2022-09-14 08:41:41.240'),
(1022,'资源管理','ResourceMenu',1,0,1022,'1022','','own',5,0,1,1,0,'2022-09-14 08:41:41.241','2022-09-14 08:41:41.243'),
(1023,'资源概览','ResourceList',2,1022,1022,'1022,1023','/resource/getdataresourcelist','own',1,1,1,1,0,'2022-09-14 08:41:41.244','2022-09-14 08:41:41.246'),
(1024,'资源详情','ResourceDetail',3,1022,1022,'1022,1024','/resource/getdataresource','own',2,1,1,1,0,'2022-09-14 08:41:41.247','2022-09-14 08:41:41.248'),
(1025,'上传资源','ResourceUpload',3,1022,1022,'1022,1025','/resource/saveorupdateresource','own',3,1,1,1,0,'2022-09-14 08:41:41.250','2022-09-14 08:41:41.251'),
(1026,'编辑资源','ResourceEdit',3,1022,1022,'1022,1026','/resource/saveorupdateresource','own',4,1,1,1,0,'2022-09-14 08:41:41.252','2022-09-14 08:41:41.254'),
(1027,'联邦资源','UnionList',2,1022,1022,'1022,1027','/fusionResource/getResourceList','own',5,1,1,1,0,'2022-09-14 08:41:41.255','2022-09-14 08:41:41.257'),
(1028,'联邦资源详情','UnionResourceDetail',3,1027,1022,'1022,1027,1028','/fusionResource/getDataResource','own',1,2,1,1,0,'2022-09-14 08:41:41.258','2022-09-14 08:41:41.259'),
(1029,'系统设置','Setting',1,0,1029,'1029','','own',6,0,1,0,0,'2022-09-14 08:41:41.265','2022-09-14 08:41:41.266'),
(1030,'用户管理','UserManage',2,1029,1029,'1029,1030','/user/findUserPage','own',1,1,1,0,0,'2022-09-14 08:41:41.268','2022-09-14 08:41:41.269'),
(1031,'用户新增','UserAdd',3,1030,1029,'1029,1030,1031','/user/saveOrUpdateUser','own',1,2,1,0,0,'2022-09-14 08:41:41.270','2022-09-14 08:41:41.272'),
(1032,'用户编辑','UserEdit',3,1030,1029,'1029,1030,1032','/user/saveOrUpdateUser','own',2,2,1,0,0,'2022-09-14 08:41:41.273','2022-09-14 08:41:41.275'),
(1033,'用户删除','UserDelete',3,1030,1029,'1029,1030,1033','/user/deleteSysUser','own',3,2,1,0,0,'2022-09-14 08:41:41.276','2022-09-14 08:41:41.277'),
(1034,'密码重置','UserPasswordReset',3,1030,1029,'1029,1030,1034','/user/initPassword','own',4,2,1,0,0,'2022-09-14 08:41:41.279','2022-09-14 08:41:41.280'),
(1035,'角色管理','RoleManage',2,1029,1029,'1029,1035','/role/findRolePage','own',2,1,1,0,0,'2022-09-14 08:41:41.281','2022-09-14 08:41:41.283'),
(1036,'角色新增','RoleAdd',3,1035,1029,'1029,1035,1036','/role/saveOrUpdateRole','own',1,2,1,0,0,'2022-09-14 08:41:41.284','2022-09-14 08:41:41.286'),
(1037,'角色编辑','RoleEdit',3,1035,1029,'1029,1035,1037','/role/saveOrUpdateRole','own',2,2,1,0,0,'2022-09-14 08:41:41.287','2022-09-14 08:41:41.289'),
(1038,'角色删除','RoleDelete',3,1035,1029,'1029,1035,1038','/role/deleteSysRole','own',3,2,1,0,0,'2022-09-14 08:41:41.290','2022-09-14 08:41:41.292'),
(1039,'菜单管理','MenuManage',2,1029,1029,'1029,1039','/auth/getAuthTree','own',3,1,1,0,0,'2022-09-14 08:41:41.293','2022-09-14 08:41:41.294'),
(1040,'菜单新增','MenuAdd',3,1039,1029,'1029,1039,1040','/auth/createAuthNode','own',1,2,1,0,0,'2022-09-14 08:41:41.296','2022-09-14 08:41:41.297'),
(1041,'菜单编辑','MenuEdit',3,1039,1029,'1029,1039,1041','/auth/alterAuthNodeStatus','own',2,2,1,0,0,'2022-09-14 08:41:41.299','2022-09-14 08:41:41.300'),
(1042,'菜单编辑','MenuDelete',3,1039,1029,'1029,1039,1042','/auth/deleteAuthNode','own',3,2,1,0,0,'2022-09-14 08:41:41.302','2022-09-14 08:41:41.303'),
(1043,'中心管理','CenterManage',2,1029,1029,'1029,1043','','own',4,1,1,0,0,'2022-09-14 08:41:41.305','2022-09-14 08:41:41.306'),
(1044,'编辑机构信息','OrganChange',3,1043,1029,'1029,1043,1044','/organ/changeLocalOrganInfo','own',1,2,1,0,0,'2022-09-14 08:41:41.308','2022-09-14 08:41:41.309'),
(1045,'添加中心节点','FusionAdd',3,1043,1029,'1029,1043,1045','/fusion/registerConnection','own',2,2,1,0,0,'2022-09-14 08:41:41.310','2022-09-14 08:41:41.312'),
(1046,'删除中心节点','FusionDelete',3,1043,1029,'1029,1043,1046','/fusion/deleteConnection','own',3,2,1,0,0,'2022-09-14 08:41:41.313','2022-09-14 08:41:41.314'),
(1047,'创建群组','GroupCreate',3,1043,1029,'1029,1043,1047','/fusion/createGroup','own',4,2,1,0,0,'2022-09-14 08:41:41.316','2022-09-14 08:41:41.317'),
(1048,'加入群组','GroupJoin',3,1043,1029,'1029,1043,1048','/fusion/joinGroup','own',5,2,1,0,0,'2022-09-14 08:41:41.318','2022-09-14 08:41:41.320'),
(1049,'退出群组','GroupExit',3,1043,1029,'1029,1043,1049','/fusion/exitGroup','own',6,2,1,0,0,'2022-09-14 08:41:41.321','2022-09-14 08:41:41.322'),
(1050,'项目禁用','closeProject',3,1003,1001,'1001,1003,1050','/project/closeProject','own',1,2,1,0,0,'2022-09-14 08:41:41.324','2022-09-14 08:41:41.325'),
(1051,'项目启动','openProject',3,1003,1001,'1001,1003,1051','/project/openProject','own',2,2,1,0,0,'2022-09-14 08:41:41.326','2022-09-14 08:41:41.328'),
(1052,'模型任务删除','deleteModelTask',3,1003,1001,'1001,1003,1052','/task/deleteTask','own',3,2,1,0,0,'2022-09-14 08:41:41.330','2022-09-14 08:41:41.331'),
(1053,'模型复制','copyModelTask',3,1003,1001,'1001,1003,1053','','own',4,2,1,0,0,'2022-09-14 08:41:41.332','2022-09-14 08:41:41.334'),
(1054,'模型推理','ModelReasoning',1,0,1054,'1054','','own',7,0,1,0,0,'2022-09-14 08:41:41.335','2022-09-14 08:41:41.337'),
(1055,'模型推理列表','ModelReasoningList',2,1054,1054,'1054,1055','','own',1,1,1,0,0,'2022-09-14 08:41:41.338','2022-09-14 08:41:41.340'),
(1056,'模型推理任务','ModelReasoningTask',3,1054,1054,'1054,1056','','own',2,1,1,0,0,'2022-09-14 08:41:41.341','2022-09-14 08:41:41.343'),
(1057,'模型推理详情','ModelReasoningDetail',3,1054,1054,'1054,1057','','own',3,1,1,0,0,'2022-09-14 08:41:41.344','2022-09-14 08:41:41.345'),
(1058,'日志','Log',1,0,1058,'1058','','own',8,0,1,0,0,'2022-09-14 08:41:41.346','2022-09-14 08:41:41.348'),
(1059,'匿踪查询任务','PIRTask',2,1016,1016,'1016,1059',' ','own',2,2,1,0,0,'2022-09-21 08:47:42.129','2022-09-21 09:36:39.176'),
(1060,'衍生数据资源','DerivedDataList',2,1022,1022,'1022,1060',' ','own',2,2,1,0,0,'2022-10-30 18:33:03.000','2022-10-30 18:33:08.000'),
(1061,'衍生数据资源详情','DerivedDataResourceDetail',2,1060,1022,'1022,1060,1061',' ','own',2,2,1,0,0,'2022-10-30 10:34:38.945','2022-10-30 10:34:38.945'),
(1062,'日志列表','LogList',2,1058,1058,'1058,1061',' ','own',2,2,1,0,0,'2022-11-14 13:44:39.353','2022-11-14 13:44:39.353'),
(1063,'界面设置','UISetting',2,1029,1029,'1029,1063',' ','own',2,2,0,0,0,'2022-12-01 10:55:42.000','2022-12-01 10:55:46.000'),
(1064,'隐私求交任务详情','PSIDetail',2,1019,1019,'1019,1064',' ','own',2,2,0,0,0,'2023-09-27 15:48:54.000','2023-09-27 15:48:57.586'),
(1065,'隐匿查询任务详情','PIRDetail',2,1016,1016,'1016,1065',' ','own',2,2,0,0,0,'2023-09-27 15:48:54.000','2023-09-27 15:48:57.586'),
(1067,'可申请的资源','AvailableResources',2,1022,1022,'1022,1067',' ','own',2,2,1,0,0,'2023-11-23 10:45:43.682','2023-11-30 14:45:03.227'),
(2000,'基于隐私计算的数据可信共享','DemandRoot',1,0,2000,'2000','','own',100,0,1,1,0,'2026-07-16 02:12:05.828','2026-07-16 02:12:05.828'),
(2001,'用户管理','DM01',1,2000,2000,'2000,2001','','own',1,1,1,1,0,'2026-07-16 02:12:05.828','2026-07-16 02:12:05.828'),
(2002,'白名单','DM02',1,2000,2000,'2000,2002','','own',2,1,1,1,0,'2026-07-16 02:12:05.830','2026-07-16 02:12:05.830'),
(2003,'租户管理','DM03',1,2000,2000,'2000,2003','','own',3,1,1,1,0,'2026-07-16 02:12:05.831','2026-07-16 02:12:05.831'),
(2004,'存证管理','DM04',1,2000,2000,'2000,2004','','own',4,1,1,1,0,'2026-07-16 02:12:05.834','2026-07-16 02:12:05.834'),
(2005,'日志管理','DM05',1,2000,2000,'2000,2005','','own',5,1,1,1,0,'2026-07-16 02:12:05.835','2026-07-16 02:12:05.835'),
(2006,'角色管理','DM06',1,2000,2000,'2000,2006','','own',6,1,1,1,0,'2026-07-16 02:12:05.837','2026-07-16 02:12:05.837'),
(2007,'监控管理','DM07',1,2000,2000,'2000,2007','','own',7,1,1,1,0,'2026-07-16 02:12:05.839','2026-07-16 02:12:05.839'),
(2008,'项目管理','DM08',1,2000,2000,'2000,2008','','own',8,1,1,1,0,'2026-07-16 02:12:05.841','2026-07-16 02:12:05.841'),
(2009,'节点管理','DM09',1,2000,2000,'2000,2009','','own',9,1,1,1,0,'2026-07-16 02:12:05.843','2026-07-16 02:12:05.843'),
(2010,'系统设置','DM10',1,2000,2000,'2000,2010','','own',10,1,1,1,0,'2026-07-16 02:12:05.846','2026-07-16 02:12:05.846'),
(2011,'数据管理','DM11',1,2000,2000,'2000,2011','','own',11,1,1,1,0,'2026-07-16 02:12:05.847','2026-07-16 02:12:05.847'),
(2012,'接口管理','DM12',1,2000,2000,'2000,2012','','own',12,1,1,1,0,'2026-07-16 02:12:05.850','2026-07-16 02:12:05.850'),
(2013,'联邦查询功能','DM13',1,2000,2000,'2000,2013','','own',13,1,1,1,0,'2026-07-16 02:12:05.852','2026-07-16 02:12:05.852'),
(2014,'联邦统计功能','DM14',1,2000,2000,'2000,2014','','own',14,1,1,1,0,'2026-07-16 02:12:05.860','2026-07-16 02:12:05.860'),
(2015,'联邦分析功能','DM15',1,2000,2000,'2000,2015','','own',15,1,1,1,0,'2026-07-16 02:12:05.863','2026-07-16 02:12:05.863'),
(2016,'联邦学习功能','DM16',1,2000,2000,'2000,2016','','own',16,1,1,1,0,'2026-07-16 02:12:05.867','2026-07-16 02:12:05.867'),
(2017,'场景定制化一','DM17',1,2000,2000,'2000,2017','','own',17,1,1,1,0,'2026-07-16 02:12:05.877','2026-07-16 02:12:05.877'),
(2018,'场景定制化二','DM18',1,2000,2000,'2000,2018','','own',18,1,1,1,0,'2026-07-16 02:12:05.879','2026-07-16 02:12:05.879'),
(20101,'新增用户','UserAdd',3,2001,2000,'2000,2001,20101','/user/saveOrUpdateUser','own',1,2,1,1,0,'2026-07-16 02:12:05.828','2026-07-16 02:12:05.828'),
(20102,'删除用户','UserDelete',3,2001,2000,'2000,2001,20102','/user/deleteSysUser','own',2,2,1,1,0,'2026-07-16 02:12:05.829','2026-07-16 02:12:05.829'),
(20103,'冻结用户','DM01F003',3,2001,2000,'2000,2001,20103','/demand/m01/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.829','2026-07-16 02:12:05.829'),
(20104,'用户列表展示','UserManage',2,2001,2000,'2000,2001,20104','/user/findUserPage','own',4,2,1,1,0,'2026-07-16 02:12:05.829','2026-07-16 02:12:05.829'),
(20105,'用户角色绑定','DM01F005',3,2001,2000,'2000,2001,20105','/demand/m01/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.829','2026-07-16 02:12:05.829'),
(20106,'用户角色解绑','DM01F006',3,2001,2000,'2000,2001,20106','/demand/m01/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.830','2026-07-16 02:12:05.830'),
(20201,'增加白名单','DM02F001',3,2002,2000,'2000,2002,20201','/demand/m02/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.830','2026-07-16 02:12:05.830'),
(20202,'删除白名单','WhitelistDelete',3,2002,2000,'2000,2002,20202','/whitelist/deleteWhitelist','own',2,2,1,1,0,'2026-07-16 02:12:05.830','2026-07-16 02:12:05.830'),
(20203,'白名单配置','DM02F003',3,2002,2000,'2000,2002,20203','/demand/m02/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.831','2026-07-16 02:12:05.831'),
(20204,'白名单列表','DM02F004',2,2002,2000,'2000,2002,20204','/demand/m02/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.831','2026-07-16 02:12:05.831'),
(20205,'白名单访问日志记录','DM02F005',3,2002,2000,'2000,2002,20205','/demand/m02/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.831','2026-07-16 02:12:05.831'),
(20301,'增加租户','DM03F001',3,2003,2000,'2000,2003,20301','/demand/m03/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.831','2026-07-16 02:12:05.831'),
(20302,'删除租户','DM03F002',3,2003,2000,'2000,2003,20302','/demand/m03/f002','own',2,2,1,1,0,'2026-07-16 02:12:05.832','2026-07-16 02:12:05.832'),
(20303,'冻结租户','DM03F003',3,2003,2000,'2000,2003,20303','/demand/m03/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.832','2026-07-16 02:12:05.832'),
(20304,'租户列表','DM03F004',2,2003,2000,'2000,2003,20304','/demand/m03/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.832','2026-07-16 02:12:05.832'),
(20305,'租户间计算流程隔离','DM03F005',3,2003,2000,'2000,2003,20305','/demand/m03/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.832','2026-07-16 02:12:05.832'),
(20306,'租户资源分配增加','DM03F006',3,2003,2000,'2000,2003,20306','/demand/m03/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.833','2026-07-16 02:12:05.833'),
(20307,'租户资源分配删除','DM03F007',3,2003,2000,'2000,2003,20307','/demand/m03/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.833','2026-07-16 02:12:05.833'),
(20308,'租户数据隔离','DM03F008',3,2003,2000,'2000,2003,20308','/demand/m03/f008','own',8,2,1,1,0,'2026-07-16 02:12:05.833','2026-07-16 02:12:05.833'),
(20401,'时间戳管理','EvidenceTimestamp',3,2004,2000,'2000,2004,20401','/evidence/findTimestampPage','own',1,2,1,1,0,'2026-07-16 02:12:05.834','2026-07-16 02:12:05.834'),
(20402,'存证配置','EvidenceConfig',3,2004,2000,'2000,2004,20402','/evidence/getEvidenceConfig','own',2,2,1,1,0,'2026-07-16 02:12:05.834','2026-07-16 02:12:05.834'),
(20403,'存证查询','EvidenceQuery',2,2004,2000,'2000,2004,20403','/evidence/findEvidencePage','own',3,2,1,1,0,'2026-07-16 02:12:05.834','2026-07-16 02:12:05.834'),
(20404,'存证加密导出','DM04F004',3,2004,2000,'2000,2004,20404','/demand/m04/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.835','2026-07-16 02:12:05.835'),
(20405,'存证接口对接','DM04F005',3,2004,2000,'2000,2004,20405','/demand/m04/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.835','2026-07-16 02:12:05.835'),
(20501,'操作日志定义','OperationLogDefinition',3,2005,2000,'2000,2005,20501','/log/findOperationLogDefinitionPage','own',1,2,1,1,0,'2026-07-16 02:12:05.835','2026-07-16 02:12:05.835'),
(20502,'调度日志定义','ScheduleLogDefinition',3,2005,2000,'2000,2005,20502','/log/findScheduleLogDefinitionPage','own',2,2,1,1,0,'2026-07-16 02:12:05.835','2026-07-16 02:12:05.835'),
(20503,'计算日志定义','ComputeLogDefinition',3,2005,2000,'2000,2005,20503','/log/findComputeLogDefinitionPage','own',3,2,1,1,0,'2026-07-16 02:12:05.836','2026-07-16 02:12:05.836'),
(20504,'操作日志记录','OperationLog',3,2005,2000,'2000,2005,20504','/log/findOperationLogPage','own',4,2,1,1,0,'2026-07-16 02:12:05.836','2026-07-16 02:12:05.836'),
(20505,'调度日志记录','ScheduleLog',3,2005,2000,'2000,2005,20505','/log/findScheduleLogPage','own',5,2,1,1,0,'2026-07-16 02:12:05.836','2026-07-16 02:12:05.836'),
(20506,'计算日志记录','ComputeLog',3,2005,2000,'2000,2005,20506','/log/findComputeLogPage','own',6,2,1,1,0,'2026-07-16 02:12:05.836','2026-07-16 02:12:05.836'),
(20507,'日志导出','DM05F007',3,2005,2000,'2000,2005,20507','/demand/m05/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.837','2026-07-16 02:12:05.837'),
(20601,'增加角色','RoleAdd',3,2006,2000,'2000,2006,20601','/role/saveOrUpdateRole','own',1,2,1,1,0,'2026-07-16 02:12:05.837','2026-07-16 02:12:05.837'),
(20602,'编辑角色','RoleEdit',3,2006,2000,'2000,2006,20602','/role/saveOrUpdateRole','own',2,2,1,1,0,'2026-07-16 02:12:05.838','2026-07-16 02:12:05.838'),
(20603,'删除角色','RoleDelete',3,2006,2000,'2000,2006,20603','/role/deleteSysRole','own',3,2,1,1,0,'2026-07-16 02:12:05.838','2026-07-16 02:12:05.838'),
(20604,'调整角色权限','DM06F004',3,2006,2000,'2000,2006,20604','/demand/m06/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.838','2026-07-16 02:12:05.838'),
(20605,'角色列表','RoleManage',2,2006,2000,'2000,2006,20605','/role/findRolePage','own',5,2,1,1,0,'2026-07-16 02:12:05.839','2026-07-16 02:12:05.839'),
(20606,'角色分配','DM06F006',3,2006,2000,'2000,2006,20606','/demand/m06/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.839','2026-07-16 02:12:05.839'),
(20701,'操作系统监控及报警（CPU）','DM07F001',3,2007,2000,'2000,2007,20701','/demand/m07/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.839','2026-07-16 02:12:05.839'),
(20702,'操作系统监控及报警（内存）','DM07F002',3,2007,2000,'2000,2007,20702','/demand/m07/f002','own',2,2,1,1,0,'2026-07-16 02:12:05.839','2026-07-16 02:12:05.839'),
(20703,'操作系统监控及报警（磁盘）','DM07F003',3,2007,2000,'2000,2007,20703','/demand/m07/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.840','2026-07-16 02:12:05.840'),
(20704,'数据库监控及报警','DM07F004',3,2007,2000,'2000,2007,20704','/demand/m07/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.840','2026-07-16 02:12:05.840'),
(20705,'中间件监控及报警（JVM）','DM07F005',3,2007,2000,'2000,2007,20705','/demand/m07/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.840','2026-07-16 02:12:05.840'),
(20706,'中间件监控及报警（Redis）','DM07F006',3,2007,2000,'2000,2007,20706','/demand/m07/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.840','2026-07-16 02:12:05.840'),
(20801,'新建项目','ProjectCreate',3,2008,2000,'2000,2008,20801','/project/saveOrUpdateProject','own',1,2,1,1,0,'2026-07-16 02:12:05.842','2026-07-16 02:12:05.842'),
(20802,'删除项目','ProjectDelete',3,2008,2000,'2000,2008,20802','/project/closeProject','own',2,2,1,1,0,'2026-07-16 02:12:05.842','2026-07-16 02:12:05.842'),
(20803,'归档项目','DM08F003',3,2008,2000,'2000,2008,20803','/demand/m08/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.842','2026-07-16 02:12:05.842'),
(20804,'项目列表','ProjectList',2,2008,2000,'2000,2008,20804','/project/getProjectList','own',4,2,1,1,0,'2026-07-16 02:12:05.842','2026-07-16 02:12:05.842'),
(20805,'项目流程审核配置','DM08F005',3,2008,2000,'2000,2008,20805','/demand/m08/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.842','2026-07-16 02:12:05.842'),
(20806,'项目权限配置','DM08F006',3,2008,2000,'2000,2008,20806','/demand/m08/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.843','2026-07-16 02:12:05.843'),
(20807,'项目结果保存','DM08F007',3,2008,2000,'2000,2008,20807','/demand/m08/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.843','2026-07-16 02:12:05.843'),
(20808,'项目台账导出','DM08F008',3,2008,2000,'2000,2008,20808','/demand/m08/f008','own',8,2,1,1,0,'2026-07-16 02:12:05.843','2026-07-16 02:12:05.843'),
(20901,'节点建立合作','NodeCooperationEstablish',3,2009,2000,'2000,2009,20901','/demand/m09/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.844','2026-07-16 02:12:05.844'),
(20902,'节点取消合作','NodeCooperationCancel',3,2009,2000,'2000,2009,20902','/demand/m09/f002','own',2,2,1,1,0,'2026-07-16 02:12:05.844','2026-07-16 02:12:05.844'),
(20903,'节点列表','NodeListEnhanced',2,2009,2000,'2000,2009,20903','/demand/m09/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.844','2026-07-16 02:12:05.844'),
(20904,'节点属性编辑','NodePropertyEdit',3,2009,2000,'2000,2009,20904','/demand/m09/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.844','2026-07-16 02:12:05.844'),
(20905,'节点属性展示','NodePropertyDisplay',2,2009,2000,'2000,2009,20905','/demand/m09/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.845','2026-07-16 02:12:05.845'),
(20906,'接入方管理','AccessManagement',3,2009,2000,'2000,2009,20906','/demand/m09/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.845','2026-07-16 02:12:05.845'),
(20907,'合作方管理','CooperationManagement',3,2009,2000,'2000,2009,20907','/demand/m09/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.845','2026-07-16 02:12:05.845'),
(20908,'节点审批工作流','NodeApprovalWorkflow',3,2009,2000,'2000,2009,20908','/demand/m09/f008','own',8,2,1,1,0,'2026-07-16 02:12:05.845','2026-07-16 02:12:05.845'),
(20909,'节点数据交换','NodeDataExchange',3,2009,2000,'2000,2009,20909','/demand/m09/f009','own',9,2,1,1,0,'2026-07-16 02:12:05.845','2026-07-16 02:12:05.845'),
(21001,'网络地址设置','DM10F001',3,2010,2000,'2000,2010,21001','/demand/m10/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.846','2026-07-16 02:12:05.846'),
(21002,'时间配置','SystemConfigTime',3,2010,2000,'2000,2010,21002','/systemConfig/getTimeConfig','own',2,2,1,1,0,'2026-07-16 02:12:05.846','2026-07-16 02:12:05.846'),
(21003,'登录限制（首次修改密码）','DM10F003',3,2010,2000,'2000,2010,21003','/demand/m10/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.846','2026-07-16 02:12:05.846'),
(21004,'登录限制（错误次数锁定）','DM10F004',3,2010,2000,'2000,2010,21004','/demand/m10/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.846','2026-07-16 02:12:05.846'),
(21005,'登录限制（错误锁定时长）','DM10F005',3,2010,2000,'2000,2010,21005','/demand/m10/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.846','2026-07-16 02:12:05.846'),
(21006,'平台个性化设置','DM10F006',3,2010,2000,'2000,2010,21006','/demand/m10/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.847','2026-07-16 02:12:05.847'),
(21007,'平台FTP设置','DM10F007',3,2010,2000,'2000,2010,21007','/demand/m10/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.847','2026-07-16 02:12:05.847'),
(21101,'新增数据源','DM11F001',3,2011,2000,'2000,2011,21101','/demand/m11/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.847','2026-07-16 02:12:05.847'),
(21102,'删除数据源','DM11F002',3,2011,2000,'2000,2011,21102','/demand/m11/f002','own',2,2,1,1,0,'2026-07-16 02:12:05.848','2026-07-16 02:12:05.848'),
(21103,'数据源配置','DM11F003',3,2011,2000,'2000,2011,21103','/demand/m11/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.848','2026-07-16 02:12:05.848'),
(21104,'数据源列表','DM11F004',2,2011,2000,'2000,2011,21104','/demand/m11/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.848','2026-07-16 02:12:05.848'),
(21105,'新增数据集','DM11F005',3,2011,2000,'2000,2011,21105','/demand/m11/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.848','2026-07-16 02:12:05.848'),
(21106,'删除数据集','DM11F006',3,2011,2000,'2000,2011,21106','/demand/m11/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.848','2026-07-16 02:12:05.848'),
(21107,'数据集配置','DM11F007',3,2011,2000,'2000,2011,21107','/demand/m11/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.848','2026-07-16 02:12:05.848'),
(21108,'数据集列表','DM11F008',2,2011,2000,'2000,2011,21108','/demand/m11/f008','own',8,2,1,1,0,'2026-07-16 02:12:05.849','2026-07-16 02:12:05.849'),
(21109,'新增数据需求','DataRequirementAdd',3,2011,2000,'2000,2011,21109','/dataRequirement/addDataRequirement','own',9,2,1,1,0,'2026-07-16 02:12:05.849','2026-07-16 02:12:05.849'),
(21110,'删除数据需求','DataRequirementDelete',3,2011,2000,'2000,2011,21110','/dataRequirement/deleteDataRequirement','own',10,2,1,1,0,'2026-07-16 02:12:05.849','2026-07-16 02:12:05.849'),
(21111,'数据需求配置','DataRequirementConfig',3,2011,2000,'2000,2011,21111','/dataRequirement/findConfigPage','own',11,2,1,1,0,'2026-07-16 02:12:05.849','2026-07-16 02:12:05.849'),
(21112,'数据需求列表','DataRequirementList',2,2011,2000,'2000,2011,21112','/dataRequirement/findDataRequirementPage','own',12,2,1,1,0,'2026-07-16 02:12:05.849','2026-07-16 02:12:05.849'),
(21113,'匹配数据需求所需数据','DataRequirementMatch',3,2011,2000,'2000,2011,21113','/dataRequirement/matchDataRequirements','own',13,2,1,1,0,'2026-07-16 02:12:05.849','2026-07-16 02:12:05.849'),
(21114,'新增共享数据集','SharedDatasetAdd',3,2011,2000,'2000,2011,21114','/sharedDataset/addSharedDataset','own',14,2,1,1,0,'2026-07-16 02:12:05.850','2026-07-16 02:12:05.850'),
(21115,'删除共享数据集','SharedDatasetDelete',3,2011,2000,'2000,2011,21115','/sharedDataset/deleteSharedDataset','own',15,2,1,1,0,'2026-07-16 02:12:05.850','2026-07-16 02:12:05.850'),
(21116,'共享数据集列表','SharedDatasetList',2,2011,2000,'2000,2011,21116','/sharedDataset/findSharedDatasetPage','own',16,2,1,1,0,'2026-07-16 02:12:05.850','2026-07-16 02:12:05.850'),
(21201,'新增接口','ApiManageAdd',3,2012,2000,'2000,2012,21201','/apiManage/addApi','own',1,2,1,1,0,'2026-07-16 02:12:05.851','2026-07-16 02:12:05.851'),
(21202,'删除接口','ApiManageDelete',3,2012,2000,'2000,2012,21202','/apiManage/deleteApi','own',2,2,1,1,0,'2026-07-16 02:12:05.851','2026-07-16 02:12:05.851'),
(21203,'接口列表','ApiManageList',2,2012,2000,'2000,2012,21203','/apiManage/findApiPage','own',3,2,1,1,0,'2026-07-16 02:12:05.851','2026-07-16 02:12:05.851'),
(21204,'接口授权配置','DM12F004',3,2012,2000,'2000,2012,21204','/demand/m12/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.851','2026-07-16 02:12:05.851'),
(21205,'接口授权校验','DM12F005',3,2012,2000,'2000,2012,21205','/demand/m12/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.851','2026-07-16 02:12:05.851'),
(21206,'接口日志记录','DM12F006',3,2012,2000,'2000,2012,21206','/demand/m12/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.852','2026-07-16 02:12:05.852'),
(21301,'基于密钥交换DH算法的批量联邦查询','DM13F001',2,2013,2000,'2000,2013,21301','/demand/m13/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.852','2026-07-16 02:12:05.852'),
(21302,'基于不经意传输OT算法的批量联邦查询','DM13F002',2,2013,2000,'2000,2013,21302','/demand/m13/f002','own',2,2,1,1,0,'2026-07-16 02:12:05.852','2026-07-16 02:12:05.852'),
(21303,'基于全同态加密HE算法的批量联邦查询','DM13F003',2,2013,2000,'2000,2013,21303','/demand/m13/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.853','2026-07-16 02:12:05.853'),
(21304,'基于密钥交换DH算法的实时联邦查询','DM13F004',2,2013,2000,'2000,2013,21304','/demand/m13/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.853','2026-07-16 02:12:05.853'),
(21305,'基于不经意传输OT算法的实时联邦查询','DM13F005',2,2013,2000,'2000,2013,21305','/demand/m13/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.853','2026-07-16 02:12:05.853'),
(21306,'基于全同态加密HE算法的实时联邦查询','DM13F006',2,2013,2000,'2000,2013,21306','/demand/m13/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.853','2026-07-16 02:12:05.853'),
(21307,'基于密钥交换DH算法的批量联邦求交','DM13F007',3,2013,2000,'2000,2013,21307','/demand/m13/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.853','2026-07-16 02:12:05.853'),
(21308,'基于不经意传输OT算法的批量联邦求交','DM13F008',3,2013,2000,'2000,2013,21308','/demand/m13/f008','own',8,2,1,1,0,'2026-07-16 02:12:05.854','2026-07-16 02:12:05.854'),
(21309,'基于全同态加密HE算法的批量联邦求交','DM13F009',3,2013,2000,'2000,2013,21309','/demand/m13/f009','own',9,2,1,1,0,'2026-07-16 02:12:05.854','2026-07-16 02:12:05.854'),
(21310,'基于密钥交换DH算法的实时联邦求交','DM13F010',3,2013,2000,'2000,2013,21310','/demand/m13/f010','own',10,2,1,1,0,'2026-07-16 02:12:05.854','2026-07-16 02:12:05.854'),
(21311,'基于不经意传输OT算法的实时联邦求交','DM13F011',3,2013,2000,'2000,2013,21311','/demand/m13/f011','own',11,2,1,1,0,'2026-07-16 02:12:05.854','2026-07-16 02:12:05.854'),
(21312,'基于全同态加密HE算法的实时联邦求交','DM13F012',3,2013,2000,'2000,2013,21312','/demand/m13/f012','own',12,2,1,1,0,'2026-07-16 02:12:05.855','2026-07-16 02:12:05.855'),
(21313,'联邦求交去除重复数据','DM13F013',3,2013,2000,'2000,2013,21313','/demand/m13/f013','own',13,2,1,1,0,'2026-07-16 02:12:05.855','2026-07-16 02:12:05.855'),
(21314,'联邦求交多列联合ID','DM13F014',3,2013,2000,'2000,2013,21314','/demand/m13/f014','own',14,2,1,1,0,'2026-07-16 02:12:05.855','2026-07-16 02:12:05.855'),
(21315,'联邦求交日志记录','DM13F015',3,2013,2000,'2000,2013,21315','/demand/m13/f015','own',15,2,1,1,0,'2026-07-16 02:12:05.855','2026-07-16 02:12:05.855'),
(21316,'联邦求交日志导出','DM13F016',3,2013,2000,'2000,2013,21316','/demand/m13/f016','own',16,2,1,1,0,'2026-07-16 02:12:05.855','2026-07-16 02:12:05.855'),
(21317,'联邦查询日志记录','DM13F017',2,2013,2000,'2000,2013,21317','/demand/m13/f017','own',17,2,1,1,0,'2026-07-16 02:12:05.856','2026-07-16 02:12:05.856'),
(21318,'联邦查询日志导出','DM13F018',2,2013,2000,'2000,2013,21318','/demand/m13/f018','own',18,2,1,1,0,'2026-07-16 02:12:05.856','2026-07-16 02:12:05.856'),
(21319,'联邦求差','DM13F019',3,2013,2000,'2000,2013,21319','/demand/m13/f019','own',19,2,1,1,0,'2026-07-16 02:12:05.856','2026-07-16 02:12:05.856'),
(21320,'联邦求查日志记录','DM13F020',3,2013,2000,'2000,2013,21320','/demand/m13/f020','own',20,2,1,1,0,'2026-07-16 02:12:05.856','2026-07-16 02:12:05.856'),
(21321,'联邦求差日志导出','DM13F021',3,2013,2000,'2000,2013,21321','/demand/m13/f021','own',21,2,1,1,0,'2026-07-16 02:12:05.856','2026-07-16 02:12:05.856'),
(21322,'联邦求并','DM13F022',3,2013,2000,'2000,2013,21322','/demand/m13/f022','own',22,2,1,1,0,'2026-07-16 02:12:05.856','2026-07-16 02:12:05.856'),
(21323,'联邦求并日志记录','DM13F023',3,2013,2000,'2000,2013,21323','/demand/m13/f023','own',23,2,1,1,0,'2026-07-16 02:12:05.857','2026-07-16 02:12:05.857'),
(21324,'联邦求并日志导出','DM13F024',3,2013,2000,'2000,2013,21324','/demand/m13/f024','own',24,2,1,1,0,'2026-07-16 02:12:05.857','2026-07-16 02:12:05.857'),
(21325,'联邦查询去除重复数据','DM13F025',2,2013,2000,'2000,2013,21325','/demand/m13/f025','own',25,2,1,1,0,'2026-07-16 02:12:05.857','2026-07-16 02:12:05.857'),
(21326,'联邦查询多列联合ID','DM13F026',2,2013,2000,'2000,2013,21326','/demand/m13/f026','own',26,2,1,1,0,'2026-07-16 02:12:05.857','2026-07-16 02:12:05.857'),
(21327,'联邦查询Payload分块','DM13F027',2,2013,2000,'2000,2013,21327','/demand/m13/f027','own',27,2,1,1,0,'2026-07-16 02:12:05.858','2026-07-16 02:12:05.858'),
(21328,'联邦查询Payload指定输出字段','DM13F028',2,2013,2000,'2000,2013,21328','/demand/m13/f028','own',28,2,1,1,0,'2026-07-16 02:12:05.858','2026-07-16 02:12:05.858'),
(21329,'联邦查询计费（按次数）','DM13F029',2,2013,2000,'2000,2013,21329','/demand/m13/f029','own',29,2,1,1,0,'2026-07-16 02:12:05.858','2026-07-16 02:12:05.858'),
(21330,'联邦查询计费（按命中）','DM13F030',2,2013,2000,'2000,2013,21330','/demand/m13/f030','own',30,2,1,1,0,'2026-07-16 02:12:05.858','2026-07-16 02:12:05.858'),
(21331,'联邦查询去重计费（固定时间范围）','DM13F031',2,2013,2000,'2000,2013,21331','/demand/m13/f031','own',31,2,1,1,0,'2026-07-16 02:12:05.858','2026-07-16 02:12:05.858'),
(21332,'联邦查询去重计费（滚动时间范围）','DM13F032',2,2013,2000,'2000,2013,21332','/demand/m13/f032','own',32,2,1,1,0,'2026-07-16 02:12:05.858','2026-07-16 02:12:05.858'),
(21333,'联邦查询实时接口校验','DM13F033',2,2013,2000,'2000,2013,21333','/demand/m13/f033','own',33,2,1,1,0,'2026-07-16 02:12:05.859','2026-07-16 02:12:05.859'),
(21334,'联邦求交分桶工具','DM13F034',3,2013,2000,'2000,2013,21334','/demand/m13/f034','own',34,2,1,1,0,'2026-07-16 02:12:05.859','2026-07-16 02:12:05.859'),
(21335,'联邦查询压缩工具','DM13F035',2,2013,2000,'2000,2013,21335','/demand/m13/f035','own',35,2,1,1,0,'2026-07-16 02:12:05.859','2026-07-16 02:12:05.859'),
(21336,'联邦查询解压工具','DM13F036',2,2013,2000,'2000,2013,21336','/demand/m13/f036','own',36,2,1,1,0,'2026-07-16 02:12:05.859','2026-07-16 02:12:05.859'),
(21337,'联邦查询分桶工具','DM13F037',2,2013,2000,'2000,2013,21337','/demand/m13/f037','own',37,2,1,1,0,'2026-07-16 02:12:05.859','2026-07-16 02:12:05.859'),
(21338,'联邦查询编码工具','DM13F038',2,2013,2000,'2000,2013,21338','/demand/m13/f038','own',38,2,1,1,0,'2026-07-16 02:12:05.860','2026-07-16 02:12:05.860'),
(21339,'联邦查询解码工具','DM13F039',2,2013,2000,'2000,2013,21339','/demand/m13/f039','own',39,2,1,1,0,'2026-07-16 02:12:05.860','2026-07-16 02:12:05.860'),
(21401,'联邦统计描述性统计（均值、最值、方差、标准差、中位数）','DM14F001',3,2014,2000,'2000,2014,21401','/demand/m14/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.860','2026-07-16 02:12:05.860'),
(21402,'联邦统计分组统计','DM14F002',3,2014,2000,'2000,2014,21402','/demand/m14/f002','own',2,2,1,1,0,'2026-07-16 02:12:05.860','2026-07-16 02:12:05.860'),
(21403,'联邦统计条件统计','DM14F003',3,2014,2000,'2000,2014,21403','/demand/m14/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.860','2026-07-16 02:12:05.860'),
(21404,'联邦统计占比统计','DM14F004',3,2014,2000,'2000,2014,21404','/demand/m14/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.861','2026-07-16 02:12:05.861'),
(21405,'联邦统计检验分析-T检验','DM14F005',3,2014,2000,'2000,2014,21405','/demand/m14/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.861','2026-07-16 02:12:05.861'),
(21406,'联邦统计检验分析-F检验','DM14F006',3,2014,2000,'2000,2014,21406','/demand/m14/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.861','2026-07-16 02:12:05.861'),
(21407,'联邦统计检验分析-卡方检验','DM14F007',3,2014,2000,'2000,2014,21407','/demand/m14/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.861','2026-07-16 02:12:05.861'),
(21408,'联邦统计回归分析','DM14F008',3,2014,2000,'2000,2014,21408','/demand/m14/f008','own',8,2,1,1,0,'2026-07-16 02:12:05.861','2026-07-16 02:12:05.861'),
(21409,'联邦统计相关性分析','DM14F009',3,2014,2000,'2000,2014,21409','/demand/m14/f009','own',9,2,1,1,0,'2026-07-16 02:12:05.862','2026-07-16 02:12:05.862'),
(21410,'联邦统计结果存储','FederatedStatisticsResultStorage',3,2014,2000,'2000,2014,21410','/federatedStatistics/resultStorage','own',10,2,1,1,0,'2026-07-16 02:12:05.862','2026-07-16 02:12:05.862'),
(21411,'联邦统计结果导出','FederatedStatisticsResultExport',3,2014,2000,'2000,2014,21411','/federatedStatistics/resultExport','own',11,2,1,1,0,'2026-07-16 02:12:05.862','2026-07-16 02:12:05.862'),
(21412,'联邦统计日志记录','FederatedStatisticsLogRecord',3,2014,2000,'2000,2014,21412','/federatedStatistics/logRecord','own',12,2,1,1,0,'2026-07-16 02:12:05.862','2026-07-16 02:12:05.862'),
(21413,'联邦统计日志导出','FederatedStatisticsLogExport',3,2014,2000,'2000,2014,21413','/federatedStatistics/logExport','own',13,2,1,1,0,'2026-07-16 02:12:05.863','2026-07-16 02:12:05.863'),
(21501,'联邦分析SQL安全校验','DM15F001',3,2015,2000,'2000,2015,21501','/demand/m15/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.864','2026-07-16 02:12:05.864'),
(21502,'联邦分析字段保密属性','DM15F002',3,2015,2000,'2000,2015,21502','/demand/m15/f002','own',2,2,1,1,0,'2026-07-16 02:12:05.864','2026-07-16 02:12:05.864'),
(21503,'联邦分析筛选算子（where等）','DM15F003',3,2015,2000,'2000,2015,21503','/demand/m15/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.864','2026-07-16 02:12:05.864'),
(21504,'联邦分析连接算子（join等）','DM15F004',3,2015,2000,'2000,2015,21504','/demand/m15/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.864','2026-07-16 02:12:05.864'),
(21505,'联邦分析聚合算子（sum/avg等）','DM15F005',3,2015,2000,'2000,2015,21505','/demand/m15/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.864','2026-07-16 02:12:05.864'),
(21506,'联邦分析分组算子（groupby等）','DM15F006',3,2015,2000,'2000,2015,21506','/demand/m15/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.864','2026-07-16 02:12:05.864'),
(21507,'联邦分析排序算子','DM15F007',3,2015,2000,'2000,2015,21507','/demand/m15/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.865','2026-07-16 02:12:05.865'),
(21508,'联邦分析窗口函数','DM15F008',3,2015,2000,'2000,2015,21508','/demand/m15/f008','own',8,2,1,1,0,'2026-07-16 02:12:05.865','2026-07-16 02:12:05.865'),
(21509,'联邦分析关联子查询','DM15F009',2,2015,2000,'2000,2015,21509','/demand/m15/f009','own',9,2,1,1,0,'2026-07-16 02:12:05.865','2026-07-16 02:12:05.865'),
(21510,'联邦分析非关联子查询','DM15F010',2,2015,2000,'2000,2015,21510','/demand/m15/f010','own',10,2,1,1,0,'2026-07-16 02:12:05.865','2026-07-16 02:12:05.865'),
(21511,'联邦分析对接主流关系型数据库','FederatedAnalysisRelationalDB',3,2015,2000,'2000,2015,21511','/federatedAnalysis/relationalDB','own',11,2,1,1,0,'2026-07-16 02:12:05.865','2026-07-16 02:12:05.865'),
(21512,'联邦分析对接主流大数据平台','FederatedAnalysisBigData',3,2015,2000,'2000,2015,21512','/federatedAnalysis/bigData','own',12,2,1,1,0,'2026-07-16 02:12:05.865','2026-07-16 02:12:05.865'),
(21513,'联邦分析对接主流公有云平台','FederatedAnalysisPublicCloud',3,2015,2000,'2000,2015,21513','/federatedAnalysis/publicCloud','own',13,2,1,1,0,'2026-07-16 02:12:05.866','2026-07-16 02:12:05.866'),
(21514,'联邦分析日志记录','FederatedAnalysisLogRecord',3,2015,2000,'2000,2015,21514','/federatedAnalysis/logRecord','own',14,2,1,1,0,'2026-07-16 02:12:05.866','2026-07-16 02:12:05.866'),
(21515,'联邦分析日志导出','FederatedAnalysisLogExport',3,2015,2000,'2000,2015,21515','/federatedAnalysis/logExport','own',15,2,1,1,0,'2026-07-16 02:12:05.866','2026-07-16 02:12:05.866'),
(21516,'联邦分析字符类型函数','DM15F016',3,2015,2000,'2000,2015,21516','/demand/m15/f016','own',16,2,1,1,0,'2026-07-16 02:12:05.866','2026-07-16 02:12:05.866'),
(21517,'联邦分析日期类型函数','DM15F017',3,2015,2000,'2000,2015,21517','/demand/m15/f017','own',17,2,1,1,0,'2026-07-16 02:12:05.867','2026-07-16 02:12:05.867'),
(21518,'联邦分析时间戳类型函数','DM15F018',3,2015,2000,'2000,2015,21518','/demand/m15/f018','own',18,2,1,1,0,'2026-07-16 02:12:05.867','2026-07-16 02:12:05.867'),
(21519,'联邦分析 SQL 格式化','DM15F019',3,2015,2000,'2000,2015,21519','/demand/m15/f019','own',19,2,1,1,0,'2026-07-16 02:12:05.867','2026-07-16 02:12:05.867'),
(21520,'联邦分析浮点类型函数','DM15F020',3,2015,2000,'2000,2015,21520','/demand/m15/f020','own',20,2,1,1,0,'2026-07-16 02:12:05.867','2026-07-16 02:12:05.867'),
(21601,'联邦学习数据融合','DM16F001',3,2016,2000,'2000,2016,21601','/demand/m16/f001','own',1,2,1,1,0,'2026-07-16 02:12:05.867','2026-07-16 02:12:05.867'),
(21602,'联邦学习预处理','DM16F002',3,2016,2000,'2000,2016,21602','/demand/m16/f002','own',2,2,1,1,0,'2026-07-16 02:12:05.868','2026-07-16 02:12:05.868'),
(21603,'联邦学习特征相似度分析','DM16F003',3,2016,2000,'2000,2016,21603','/demand/m16/f003','own',3,2,1,1,0,'2026-07-16 02:12:05.868','2026-07-16 02:12:05.868'),
(21604,'联邦学习特征编码','DM16F004',3,2016,2000,'2000,2016,21604','/demand/m16/f004','own',4,2,1,1,0,'2026-07-16 02:12:05.868','2026-07-16 02:12:05.868'),
(21605,'联邦学习特征对齐','DM16F005',3,2016,2000,'2000,2016,21605','/demand/m16/f005','own',5,2,1,1,0,'2026-07-16 02:12:05.868','2026-07-16 02:12:05.868'),
(21606,'联邦学习特征分享','DM16F006',3,2016,2000,'2000,2016,21606','/demand/m16/f006','own',6,2,1,1,0,'2026-07-16 02:12:05.869','2026-07-16 02:12:05.869'),
(21607,'联邦学习特征填充','DM16F007',3,2016,2000,'2000,2016,21607','/demand/m16/f007','own',7,2,1,1,0,'2026-07-16 02:12:05.869','2026-07-16 02:12:05.869'),
(21608,'联邦学习样本列扩展','DM16F008',3,2016,2000,'2000,2016,21608','/demand/m16/f008','own',8,2,1,1,0,'2026-07-16 02:12:05.869','2026-07-16 02:12:05.869'),
(21609,'联邦学习样本加权','DM16F009',3,2016,2000,'2000,2016,21609','/demand/m16/f009','own',9,2,1,1,0,'2026-07-16 02:12:05.869','2026-07-16 02:12:05.869'),
(21610,'联邦学习指标建模分析','DM16F010',3,2016,2000,'2000,2016,21610','/demand/m16/f010','own',10,2,1,1,0,'2026-07-16 02:12:05.870','2026-07-16 02:12:05.870'),
(21611,'联邦学习特征装仓','DM16F011',3,2016,2000,'2000,2016,21611','/demand/m16/f011','own',11,2,1,1,0,'2026-07-16 02:12:05.870','2026-07-16 02:12:05.870'),
(21612,'联邦学习数据分割','DM16F012',3,2016,2000,'2000,2016,21612','/demand/m16/f012','own',12,2,1,1,0,'2026-07-16 02:12:05.870','2026-07-16 02:12:05.870'),
(21613,'联邦学习数据转换','DM16F013',3,2016,2000,'2000,2016,21613','/demand/m16/f013','own',13,2,1,1,0,'2026-07-16 02:12:05.870','2026-07-16 02:12:05.870'),
(21614,'联邦学习线性回归建模（纵向）','DM16F014',3,2016,2000,'2000,2016,21614','/demand/m16/f014','own',14,2,1,1,0,'2026-07-16 02:12:05.870','2026-07-16 02:12:05.870'),
(21615,'联邦学习逻辑回归建模（纵向）','DM16F015',3,2016,2000,'2000,2016,21615','/demand/m16/f015','own',15,2,1,1,0,'2026-07-16 02:12:05.871','2026-07-16 02:12:05.871'),
(21616,'联邦学习XGBoost建模（纵向）','DM16F016',3,2016,2000,'2000,2016,21616','/demand/m16/f016','own',16,2,1,1,0,'2026-07-16 02:12:05.871','2026-07-16 02:12:05.871'),
(21617,'联邦学习线性回归预测（纵向）','DM16F017',3,2016,2000,'2000,2016,21617','/demand/m16/f017','own',17,2,1,1,0,'2026-07-16 02:12:05.871','2026-07-16 02:12:05.871'),
(21618,'联邦学习逻辑回归预测（纵向）','DM16F018',3,2016,2000,'2000,2016,21618','/demand/m16/f018','own',18,2,1,1,0,'2026-07-16 02:12:05.871','2026-07-16 02:12:05.871'),
(21619,'联邦学习XGBoost预测（纵向）','DM16F019',3,2016,2000,'2000,2016,21619','/demand/m16/f019','own',19,2,1,1,0,'2026-07-16 02:12:05.871','2026-07-16 02:12:05.871'),
(21620,'联邦学习模型评估','DM16F020',3,2016,2000,'2000,2016,21620','/demand/m16/f020','own',20,2,1,1,0,'2026-07-16 02:12:05.872','2026-07-16 02:12:05.872'),
(21621,'联邦学习模型预览','DM16F021',3,2016,2000,'2000,2016,21621','/demand/m16/f021','own',21,2,1,1,0,'2026-07-16 02:12:05.872','2026-07-16 02:12:05.872'),
(21622,'联邦学习模型导入','DM16F022',3,2016,2000,'2000,2016,21622','/demand/m16/f022','own',22,2,1,1,0,'2026-07-16 02:12:05.872','2026-07-16 02:12:05.872'),
(21623,'联邦学习模型导出','DM16F023',3,2016,2000,'2000,2016,21623','/demand/m16/f023','own',23,2,1,1,0,'2026-07-16 02:12:05.872','2026-07-16 02:12:05.872'),
(21624,'联邦建模工作台','FederatedLearningIndex',2,2016,2000,'2000,2016,21624','/federatedLearning/index','own',24,2,1,1,0,'2026-07-16 02:12:05.873','2026-07-16 02:12:05.873'),
(21625,'联邦建模参数调优','FederatedLearningParamTuning',3,2016,2000,'2000,2016,21625','/federatedLearning/paramTuning','own',25,2,1,1,0,'2026-07-16 02:12:05.873','2026-07-16 02:12:05.873'),
(21626,'联邦建模训练迭代','DM16F026',3,2016,2000,'2000,2016,21626','/federatedLearning/trainingIteration','own',26,2,1,1,0,'2026-07-16 02:12:05.873','2026-07-16 02:12:05.873'),
(21627,'联邦建模训练报告','FederatedLearningTrainingReport',3,2016,2000,'2000,2016,21627','/federatedLearning/trainingReport','own',27,2,1,1,0,'2026-07-16 02:12:05.873','2026-07-16 02:12:05.873'),
(21628,'联邦学习日志记录','FederatedLearningLogRecord',3,2016,2000,'2000,2016,21628','/federatedLearning/logRecord','own',28,2,1,1,0,'2026-07-16 02:12:05.873','2026-07-16 02:12:05.873'),
(21629,'联邦学习日志导出','FederatedLearningLogExport',3,2016,2000,'2000,2016,21629','/federatedLearning/logExport','own',29,2,1,1,0,'2026-07-16 02:12:05.873','2026-07-16 02:12:05.873'),
(21630,'单方数据合并模块','DM16F030',3,2016,2000,'2000,2016,21630','/federatedLearning/dataMerge','own',30,2,1,1,0,'2026-07-16 02:12:05.874','2026-07-16 02:12:05.874'),
(21631,'单方数据统计','DM16F031',3,2016,2000,'2000,2016,21631','/demand/m16/f031','own',31,2,1,1,0,'2026-07-16 02:12:05.874','2026-07-16 02:12:05.874'),
(21632,'单方数据清洗','DM16F032',3,2016,2000,'2000,2016,21632','/demand/m16/f032','own',32,2,1,1,0,'2026-07-16 02:12:05.874','2026-07-16 02:12:05.874'),
(21633,'单方数据缩放','DM16F033',3,2016,2000,'2000,2016,21633','/demand/m16/f033','own',33,2,1,1,0,'2026-07-16 02:12:05.875','2026-07-16 02:12:05.875'),
(21634,'单方特征编码','DM16F034',3,2016,2000,'2000,2016,21634','/demand/m16/f034','own',34,2,1,1,0,'2026-07-16 02:12:05.875','2026-07-16 02:12:05.875'),
(21635,'单方特征分箱','DM16F035',3,2016,2000,'2000,2016,21635','/demand/m16/f035','own',35,2,1,1,0,'2026-07-16 02:12:05.875','2026-07-16 02:12:05.875'),
(21636,'单方特征筛选','DM16F036',3,2016,2000,'2000,2016,21636','/demand/m16/f036','own',36,2,1,1,0,'2026-07-16 02:12:05.875','2026-07-16 02:12:05.875'),
(21637,'单方特征衍生','DM16F037',3,2016,2000,'2000,2016,21637','/demand/m16/f037','own',37,2,1,1,0,'2026-07-16 02:12:05.875','2026-07-16 02:12:05.875'),
(21638,'单方机器学习LR算法','DM16F038',3,2016,2000,'2000,2016,21638','/demand/m16/f038','own',38,2,1,1,0,'2026-07-16 02:12:05.876','2026-07-16 02:12:05.876'),
(21639,'单方机器学习XGB算法','DM16F039',3,2016,2000,'2000,2016,21639','/demand/m16/f039','own',39,2,1,1,0,'2026-07-16 02:12:05.876','2026-07-16 02:12:05.876'),
(21640,'单方python脚本处理','DM16F040',3,2016,2000,'2000,2016,21640','/demand/m16/f040','own',40,2,1,1,0,'2026-07-16 02:12:05.876','2026-07-16 02:12:05.876'),
(21641,'单方sql处理','DM16F041',3,2016,2000,'2000,2016,21641','/demand/m16/f041','own',41,2,1,1,0,'2026-07-16 02:12:05.876','2026-07-16 02:12:05.876'),
(21642,'单方学习日志记录','DM16F042',3,2016,2000,'2000,2016,21642','/demand/m16/f042','own',42,2,1,1,0,'2026-07-16 02:12:05.876','2026-07-16 02:12:05.876'),
(21643,'单方学习日志导出','DM16F043',3,2016,2000,'2000,2016,21643','/demand/m16/f043','own',43,2,1,1,0,'2026-07-16 02:12:05.877','2026-07-16 02:12:05.877'),
(21701,'警务数据交集数据融合','PoliceDataIntersection',3,2017,2000,'2000,2017,21701','/policeDataFusion/intersection','own',1,2,1,1,0,'2026-07-16 02:12:05.877','2026-07-16 02:12:05.877'),
(21702,'保险机构接口对接','InsuranceApiConnect',3,2017,2000,'2000,2017,21702','/policeDataFusion/insuranceApi','own',2,2,1,1,0,'2026-07-16 02:12:05.877','2026-07-16 02:12:05.877'),
(21703,'保险机构同态密钥创建','InsuranceHomomorphicKey',3,2017,2000,'2000,2017,21703','/policeDataFusion/homomorphicKey','own',3,2,1,1,0,'2026-07-16 02:12:05.877','2026-07-16 02:12:05.877'),
(21704,'保险机构模型同态加密','InsuranceModelEncrypt',3,2017,2000,'2000,2017,21704','/policeDataFusion/modelEncrypt','own',4,2,1,1,0,'2026-07-16 02:12:05.878','2026-07-16 02:12:05.878'),
(21705,'加密模型联合运算','EncryptedModelCompute',3,2017,2000,'2000,2017,21705','/policeDataFusion/encryptedCompute','own',5,2,1,1,0,'2026-07-16 02:12:05.878','2026-07-16 02:12:05.878'),
(21706,'保险机构数据解密','InsuranceDataDecrypt',3,2017,2000,'2000,2017,21706','/policeDataFusion/dataDecrypt','own',6,2,1,1,0,'2026-07-16 02:12:05.878','2026-07-16 02:12:05.878'),
(21707,'警务数据对接','ElectronicCertPoliceConnect',3,2017,2000,'2000,2017,21707','/electronicCert/policeConnect','own',7,2,1,1,0,'2026-07-16 02:12:05.878','2026-07-16 02:12:05.878'),
(21708,'模型密文数据安全交换（批量）','ModelCipherBatchExchange',3,2017,2000,'2000,2017,21708','/policeDataFusion/batchExchange','own',8,2,1,1,0,'2026-07-16 02:12:05.878','2026-07-16 02:12:05.878'),
(21709,'流程执行日志记录','ElectronicCertLogRecord',3,2017,2000,'2000,2017,21709','/electronicCert/logRecord','own',9,2,1,1,0,'2026-07-16 02:12:05.879','2026-07-16 02:12:05.879'),
(21710,'流程执行日志导出','ElectronicCertLogExport',3,2017,2000,'2000,2017,21710','/electronicCert/logExport','own',10,2,1,1,0,'2026-07-16 02:12:05.879','2026-07-16 02:12:05.879'),
(21801,'电子证件特征转换','ElectronicCertFeatureConvert',3,2018,2000,'2000,2018,21801','/electronicCert/featureConvert','own',1,2,1,1,0,'2026-07-16 02:12:05.879','2026-07-16 02:12:05.879'),
(21802,'现场证件特征转换','OnSiteCertFeatureConvert',3,2018,2000,'2000,2018,21802','/electronicCert/onSiteConvert','own',2,2,1,1,0,'2026-07-16 02:12:05.879','2026-07-16 02:12:05.879'),
(21803,'特征数据隐私比对','FeaturePrivacyCompare',3,2018,2000,'2000,2018,21803','/electronicCert/privacyCompare','own',3,2,1,1,0,'2026-07-16 02:12:05.880','2026-07-16 02:12:05.880'),
(21804,'警务数据对接','ElectronicCertPoliceConnect',3,2018,2000,'2000,2018,21804','/electronicCert/policeConnect','own',4,2,1,1,0,'2026-07-16 02:12:05.880','2026-07-16 02:12:05.880'),
(21805,'使用机构数据接入','OrgDataImport',3,2018,2000,'2000,2018,21805','/electronicCert/orgDataImport','own',5,2,1,1,0,'2026-07-16 02:12:05.880','2026-07-16 02:12:05.880'),
(21806,'使用机构数据导出','OrgDataExport',3,2018,2000,'2000,2018,21806','/electronicCert/orgDataExport','own',6,2,1,1,0,'2026-07-16 02:12:05.880','2026-07-16 02:12:05.880'),
(21807,'特征密文数据安全交换（批量）','FeatureCipherBatchExchange',3,2018,2000,'2000,2018,21807','/electronicCert/batchExchange','own',7,2,1,1,0,'2026-07-16 02:12:05.880','2026-07-16 02:12:05.880'),
(21808,'特征密文数据安全交换（实时）','FeatureCipherRealTimeExchange',3,2018,2000,'2000,2018,21808','/electronicCert/realTimeExchange','own',8,2,1,1,0,'2026-07-16 02:12:05.880','2026-07-16 02:12:05.880'),
(21809,'流程执行日志记录','ElectronicCertLogRecord',3,2018,2000,'2000,2018,21809','/electronicCert/logRecord','own',9,2,1,1,0,'2026-07-16 02:12:05.881','2026-07-16 02:12:05.881'),
(21810,'流程执行日志导出','ElectronicCertLogExport',3,2018,2000,'2000,2018,21810','/electronicCert/logExport','own',10,2,1,1,0,'2026-07-16 02:12:05.881','2026-07-16 02:12:05.881'),
(26000,'前端可用页面解锁','FePagesUnlock',1,0,26000,'26000','','own',200,0,1,1,0,'2026-07-16 02:12:05.964','2026-07-16 02:12:05.964'),
(26001,'AccessManagement','AccessManagement',2,26000,26000,'26000,26001','','own',1,1,1,1,0,'2026-07-16 02:12:05.964','2026-07-16 02:12:05.964'),
(26002,'ApiAuth','ApiAuth',2,26000,26000,'26000,26002','','own',2,1,1,1,0,'2026-07-16 02:12:05.964','2026-07-16 02:12:05.964'),
(26003,'ApiList','ApiList',2,26000,26000,'26000,26003','','own',3,1,1,1,0,'2026-07-16 02:12:05.964','2026-07-16 02:12:05.964'),
(26004,'ApiLog','ApiLog',2,26000,26000,'26000,26004','','own',4,1,1,1,0,'2026-07-16 02:12:05.964','2026-07-16 02:12:05.964'),
(26005,'ApiManage','ApiManage',2,26000,26000,'26000,26005','','own',5,1,1,1,0,'2026-07-16 02:12:05.965','2026-07-16 02:12:05.965'),
(26006,'App','App',2,26000,26000,'26000,26006','','own',6,1,1,1,0,'2026-07-16 02:12:05.965','2026-07-16 02:12:05.965'),
(26007,'AppMain','AppMain',2,26000,26000,'26000,26007','','own',7,1,1,1,0,'2026-07-16 02:12:05.965','2026-07-16 02:12:05.965'),
(26008,'Application','Application',2,26000,26000,'26000,26008','','own',8,1,1,1,0,'2026-07-16 02:12:05.965','2026-07-16 02:12:05.965'),
(26009,'ApplicationDetail','ApplicationDetail',2,26000,26000,'26000,26009','','own',9,1,1,1,0,'2026-07-16 02:12:05.965','2026-07-16 02:12:05.965'),
(26010,'ApprovalWorkflow','ApprovalWorkflow',2,26000,26000,'26000,26010','','own',10,1,1,1,0,'2026-07-16 02:12:05.966','2026-07-16 02:12:05.966'),
(26011,'AvailableResources','AvailableResources',2,26000,26000,'26000,26011','','own',11,1,1,1,0,'2026-07-16 02:12:05.966','2026-07-16 02:12:05.966'),
(26012,'BigModel','BigModel',2,26000,26000,'26000,26012','','own',12,1,1,1,0,'2026-07-16 02:12:05.966','2026-07-16 02:12:05.966'),
(26013,'CancelCooperation','CancelCooperation',2,26000,26000,'26000,26013','','own',13,1,1,1,0,'2026-07-16 02:12:05.966','2026-07-16 02:12:05.966'),
(26014,'CenterManage','CenterManage',2,26000,26000,'26000,26014','','own',14,1,1,1,0,'2026-07-16 02:12:05.967','2026-07-16 02:12:05.967'),
(26015,'ComputeLog','ComputeLog',2,26000,26000,'26000,26015','','own',15,1,1,1,0,'2026-07-16 02:12:05.967','2026-07-16 02:12:05.967'),
(26016,'ComputeLogDefinition','ComputeLogDefinition',2,26000,26000,'26000,26016','','own',16,1,1,1,0,'2026-07-16 02:12:05.967','2026-07-16 02:12:05.967'),
(26017,'CooperationManagement','CooperationManagement',2,26000,26000,'26000,26017','','own',17,1,1,1,0,'2026-07-16 02:12:05.967','2026-07-16 02:12:05.967'),
(26018,'DataExchangeLog','DataExchangeLog',2,26000,26000,'26000,26018','','own',18,1,1,1,0,'2026-07-16 02:12:05.967','2026-07-16 02:12:05.967'),
(26019,'DataRequirementConfig','DataRequirementConfig',2,26000,26000,'26000,26019','','own',19,1,1,1,0,'2026-07-16 02:12:05.967','2026-07-16 02:12:05.967'),
(26020,'DataRequirementList','DataRequirementList',2,26000,26000,'26000,26020','','own',20,1,1,1,0,'2026-07-16 02:12:05.968','2026-07-16 02:12:05.968'),
(26021,'DataRequirementMatch','DataRequirementMatch',2,26000,26000,'26000,26021','','own',21,1,1,1,0,'2026-07-16 02:12:05.968','2026-07-16 02:12:05.968'),
(26022,'DerivedDataList','DerivedDataList',2,26000,26000,'26000,26022','','own',22,1,1,1,0,'2026-07-16 02:12:05.968','2026-07-16 02:12:05.968'),
(26023,'DerivedDataResourceDetail','DerivedDataResourceDetail',2,26000,26000,'26000,26023','','own',23,1,1,1,0,'2026-07-16 02:12:05.968','2026-07-16 02:12:05.968'),
(26024,'Difference','Difference',2,26000,26000,'26000,26024','','own',24,1,1,1,0,'2026-07-16 02:12:05.968','2026-07-16 02:12:05.968'),
(26025,'DifferenceDetail','DifferenceDetail',2,26000,26000,'26000,26025','','own',25,1,1,1,0,'2026-07-16 02:12:05.969','2026-07-16 02:12:05.969'),
(26026,'DifferenceList','DifferenceList',2,26000,26000,'26000,26026','','own',26,1,1,1,0,'2026-07-16 02:12:05.969','2026-07-16 02:12:05.969'),
(26027,'DifferenceTask','DifferenceTask',2,26000,26000,'26000,26027','','own',27,1,1,1,0,'2026-07-16 02:12:05.969','2026-07-16 02:12:05.969'),
(26028,'ElectronicCertCompare','ElectronicCertCompare',2,26000,26000,'26000,26028','','own',28,1,1,1,0,'2026-07-16 02:12:05.969','2026-07-16 02:12:05.969'),
(26029,'ElectronicCertFeatureConvert','ElectronicCertFeatureConvert',2,26000,26000,'26000,26029','','own',29,1,1,1,0,'2026-07-16 02:12:05.970','2026-07-16 02:12:05.970'),
(26030,'ElectronicCertLogExport','ElectronicCertLogExport',2,26000,26000,'26000,26030','','own',30,1,1,1,0,'2026-07-16 02:12:05.970','2026-07-16 02:12:05.970'),
(26031,'ElectronicCertLogRecord','ElectronicCertLogRecord',2,26000,26000,'26000,26031','','own',31,1,1,1,0,'2026-07-16 02:12:05.970','2026-07-16 02:12:05.970'),
(26032,'ElectronicCertPoliceConnect','ElectronicCertPoliceConnect',2,26000,26000,'26000,26032','','own',32,1,1,1,0,'2026-07-16 02:12:05.970','2026-07-16 02:12:05.970'),
(26033,'EncryptedModelCompute','EncryptedModelCompute',2,26000,26000,'26000,26033','','own',33,1,1,1,0,'2026-07-16 02:12:05.970','2026-07-16 02:12:05.970'),
(26034,'Evidence','Evidence',2,26000,26000,'26000,26034','','own',34,1,1,1,0,'2026-07-16 02:12:05.970','2026-07-16 02:12:05.970'),
(26035,'EvidenceApi','EvidenceApi',2,26000,26000,'26000,26035','','own',35,1,1,1,0,'2026-07-16 02:12:05.971','2026-07-16 02:12:05.971'),
(26036,'EvidenceConfig','EvidenceConfig',2,26000,26000,'26000,26036','','own',36,1,1,1,0,'2026-07-16 02:12:05.971','2026-07-16 02:12:05.971'),
(26037,'EvidenceExport','EvidenceExport',2,26000,26000,'26000,26037','','own',37,1,1,1,0,'2026-07-16 02:12:05.971','2026-07-16 02:12:05.971'),
(26038,'EvidenceQuery','EvidenceQuery',2,26000,26000,'26000,26038','','own',38,1,1,1,0,'2026-07-16 02:12:05.971','2026-07-16 02:12:05.971'),
(26039,'EvidenceTimestamp','EvidenceTimestamp',2,26000,26000,'26000,26039','','own',39,1,1,1,0,'2026-07-16 02:12:05.971','2026-07-16 02:12:05.971'),
(26040,'FAAggregateOperator','FAAggregateOperator',2,26000,26000,'26000,26040','','own',40,1,1,1,0,'2026-07-16 02:12:05.972','2026-07-16 02:12:05.972'),
(26041,'FACharFunctions','FACharFunctions',2,26000,26000,'26000,26041','','own',41,1,1,1,0,'2026-07-16 02:12:05.972','2026-07-16 02:12:05.972'),
(26042,'FACorrelatedSubquery','FACorrelatedSubquery',2,26000,26000,'26000,26042','','own',42,1,1,1,0,'2026-07-16 02:12:05.972','2026-07-16 02:12:05.972'),
(26043,'FADateFunctions','FADateFunctions',2,26000,26000,'26000,26043','','own',43,1,1,1,0,'2026-07-16 02:12:05.972','2026-07-16 02:12:05.972'),
(26044,'FAFilterOperator','FAFilterOperator',2,26000,26000,'26000,26044','','own',44,1,1,1,0,'2026-07-16 02:12:05.973','2026-07-16 02:12:05.973'),
(26045,'FAFloatFunctions','FAFloatFunctions',2,26000,26000,'26000,26045','','own',45,1,1,1,0,'2026-07-16 02:12:05.973','2026-07-16 02:12:05.973'),
(26046,'FAGroupOperator','FAGroupOperator',2,26000,26000,'26000,26046','','own',46,1,1,1,0,'2026-07-16 02:12:05.973','2026-07-16 02:12:05.973'),
(26047,'FAJoinOperator','FAJoinOperator',2,26000,26000,'26000,26047','','own',47,1,1,1,0,'2026-07-16 02:12:05.973','2026-07-16 02:12:05.973'),
(26048,'FANonCorrelatedSubquery','FANonCorrelatedSubquery',2,26000,26000,'26000,26048','','own',48,1,1,1,0,'2026-07-16 02:12:05.973','2026-07-16 02:12:05.973'),
(26049,'FASortOperator','FASortOperator',2,26000,26000,'26000,26049','','own',49,1,1,1,0,'2026-07-16 02:12:05.973','2026-07-16 02:12:05.973'),
(26050,'FASqlFormatter','FASqlFormatter',2,26000,26000,'26000,26050','','own',50,1,1,1,0,'2026-07-16 02:12:05.974','2026-07-16 02:12:05.974'),
(26051,'FATimestampFunctions','FATimestampFunctions',2,26000,26000,'26000,26051','','own',51,1,1,1,0,'2026-07-16 02:12:05.974','2026-07-16 02:12:05.974'),
(26052,'FAWindowFunction','FAWindowFunction',2,26000,26000,'26000,26052','','own',52,1,1,1,0,'2026-07-16 02:12:05.974','2026-07-16 02:12:05.974'),
(26053,'FLDataFusion','FLDataFusion',2,26000,26000,'26000,26053','','own',53,1,1,1,0,'2026-07-16 02:12:05.974','2026-07-16 02:12:05.974'),
(26054,'FLDataSplit','FLDataSplit',2,26000,26000,'26000,26054','','own',54,1,1,1,0,'2026-07-16 02:12:05.974','2026-07-16 02:12:05.974'),
(26055,'FLDataTransform','FLDataTransform',2,26000,26000,'26000,26055','','own',55,1,1,1,0,'2026-07-16 02:12:05.975','2026-07-16 02:12:05.975'),
(26056,'FLFeatureAlign','FLFeatureAlign',2,26000,26000,'26000,26056','','own',56,1,1,1,0,'2026-07-16 02:12:05.975','2026-07-16 02:12:05.975'),
(26057,'FLFeatureEncode','FLFeatureEncode',2,26000,26000,'26000,26057','','own',57,1,1,1,0,'2026-07-16 02:12:05.975','2026-07-16 02:12:05.975'),
(26058,'FLFeatureFill','FLFeatureFill',2,26000,26000,'26000,26058','','own',58,1,1,1,0,'2026-07-16 02:12:05.975','2026-07-16 02:12:05.975'),
(26059,'FLFeatureShare','FLFeatureShare',2,26000,26000,'26000,26059','','own',59,1,1,1,0,'2026-07-16 02:12:05.975','2026-07-16 02:12:05.975'),
(26060,'FLFeatureSimilarity','FLFeatureSimilarity',2,26000,26000,'26000,26060','','own',60,1,1,1,0,'2026-07-16 02:12:05.975','2026-07-16 02:12:05.975'),
(26061,'FLFeatureWarehouse','FLFeatureWarehouse',2,26000,26000,'26000,26061','','own',61,1,1,1,0,'2026-07-16 02:12:05.976','2026-07-16 02:12:05.976'),
(26062,'FLMetricModeling','FLMetricModeling',2,26000,26000,'26000,26062','','own',62,1,1,1,0,'2026-07-16 02:12:05.976','2026-07-16 02:12:05.976'),
(26063,'FLSampleExpand','FLSampleExpand',2,26000,26000,'26000,26063','','own',63,1,1,1,0,'2026-07-16 02:12:05.976','2026-07-16 02:12:05.976'),
(26064,'FLSampleWeight','FLSampleWeight',2,26000,26000,'26000,26064','','own',64,1,1,1,0,'2026-07-16 02:12:05.979','2026-07-16 02:12:05.979'),
(26065,'FLVerticalLinearPredict','FLVerticalLinearPredict',2,26000,26000,'26000,26065','','own',65,1,1,1,0,'2026-07-16 02:12:05.979','2026-07-16 02:12:05.979'),
(26066,'FLVerticalLinearTrain','FLVerticalLinearTrain',2,26000,26000,'26000,26066','','own',66,1,1,1,0,'2026-07-16 02:12:05.979','2026-07-16 02:12:05.979'),
(26067,'FLVerticalLogisticPredict','FLVerticalLogisticPredict',2,26000,26000,'26000,26067','','own',67,1,1,1,0,'2026-07-16 02:12:05.986','2026-07-16 02:12:05.986'),
(26068,'FLVerticalLogisticTrain','FLVerticalLogisticTrain',2,26000,26000,'26000,26068','','own',68,1,1,1,0,'2026-07-16 02:12:05.986','2026-07-16 02:12:05.986'),
(26069,'FLVerticalXGBoostPredict','FLVerticalXGBoostPredict',2,26000,26000,'26000,26069','','own',69,1,1,1,0,'2026-07-16 02:12:05.986','2026-07-16 02:12:05.986'),
(26070,'FLVerticalXGBoostTrain','FLVerticalXGBoostTrain',2,26000,26000,'26000,26070','','own',70,1,1,1,0,'2026-07-16 02:12:05.987','2026-07-16 02:12:05.987'),
(26071,'FeatureCipherBatchExchange','FeatureCipherBatchExchange',2,26000,26000,'26000,26071','','own',71,1,1,1,0,'2026-07-16 02:12:05.987','2026-07-16 02:12:05.987'),
(26072,'FeatureCipherRealTimeExchange','FeatureCipherRealTimeExchange',2,26000,26000,'26000,26072','','own',72,1,1,1,0,'2026-07-16 02:12:05.987','2026-07-16 02:12:05.987'),
(26073,'FeaturePrivacyCompare','FeaturePrivacyCompare',2,26000,26000,'26000,26073','','own',73,1,1,1,0,'2026-07-16 02:12:05.987','2026-07-16 02:12:05.987'),
(26074,'FederatedAnalysisBigData','FederatedAnalysisBigData',2,26000,26000,'26000,26074','','own',74,1,1,1,0,'2026-07-16 02:12:05.987','2026-07-16 02:12:05.987'),
(26075,'FederatedAnalysisFieldConfidentiality','FederatedAnalysisFieldConfidentiality',2,26000,26000,'26000,26075','','own',75,1,1,1,0,'2026-07-16 02:12:05.988','2026-07-16 02:12:05.988'),
(26076,'FederatedAnalysisIndex','FederatedAnalysisIndex',2,26000,26000,'26000,26076','','own',76,1,1,1,0,'2026-07-16 02:12:05.988','2026-07-16 02:12:05.988'),
(26077,'FederatedAnalysisLogExport','FederatedAnalysisLogExport',2,26000,26000,'26000,26077','','own',77,1,1,1,0,'2026-07-16 02:12:05.988','2026-07-16 02:12:05.988'),
(26078,'FederatedAnalysisLogRecord','FederatedAnalysisLogRecord',2,26000,26000,'26000,26078','','own',78,1,1,1,0,'2026-07-16 02:12:05.988','2026-07-16 02:12:05.988'),
(26079,'FederatedAnalysisPublicCloud','FederatedAnalysisPublicCloud',2,26000,26000,'26000,26079','','own',79,1,1,1,0,'2026-07-16 02:12:05.989','2026-07-16 02:12:05.989'),
(26080,'FederatedAnalysisRelationalDB','FederatedAnalysisRelationalDB',2,26000,26000,'26000,26080','','own',80,1,1,1,0,'2026-07-16 02:12:05.989','2026-07-16 02:12:05.989'),
(26081,'FederatedAnalysisSqlValidator','FederatedAnalysisSqlValidator',2,26000,26000,'26000,26081','','own',81,1,1,1,0,'2026-07-16 02:12:05.989','2026-07-16 02:12:05.989'),
(26082,'FederatedLearning','FederatedLearning',2,26000,26000,'26000,26082','','own',82,1,1,1,0,'2026-07-16 02:12:05.990','2026-07-16 02:12:05.990'),
(26083,'FederatedLearningIndex','FederatedLearningIndex',2,26000,26000,'26000,26083','','own',83,1,1,1,0,'2026-07-16 02:12:05.990','2026-07-16 02:12:05.990'),
(26084,'FederatedLearningList','FederatedLearningList',2,26000,26000,'26000,26084','','own',84,1,1,1,0,'2026-07-16 02:12:05.990','2026-07-16 02:12:05.990'),
(26085,'FederatedLearningLogExport','FederatedLearningLogExport',2,26000,26000,'26000,26085','','own',85,1,1,1,0,'2026-07-16 02:12:05.990','2026-07-16 02:12:05.990'),
(26086,'FederatedLearningLogRecord','FederatedLearningLogRecord',2,26000,26000,'26000,26086','','own',86,1,1,1,0,'2026-07-16 02:12:05.990','2026-07-16 02:12:05.990'),
(26087,'FederatedLearningParamTuning','FederatedLearningParamTuning',2,26000,26000,'26000,26087','','own',87,1,1,1,0,'2026-07-16 02:12:05.990','2026-07-16 02:12:05.990'),
(26088,'FederatedLearningSinglePartyDataMerge','FederatedLearningSinglePartyDataMerge',2,26000,26000,'26000,26088','','own',88,1,1,1,0,'2026-07-16 02:12:05.991','2026-07-16 02:12:05.991'),
(26089,'FederatedLearningTrainingIteration','FederatedLearningTrainingIteration',2,26000,26000,'26000,26089','','own',89,1,1,1,0,'2026-07-16 02:12:05.991','2026-07-16 02:12:05.991'),
(26090,'FederatedLearningTrainingReport','FederatedLearningTrainingReport',2,26000,26000,'26000,26090','','own',90,1,1,1,0,'2026-07-16 02:12:05.991','2026-07-16 02:12:05.991'),
(26091,'FederatedModelExport','FederatedModelExport',2,26000,26000,'26000,26091','','own',91,1,1,1,0,'2026-07-16 02:12:05.991','2026-07-16 02:12:05.991'),
(26092,'FederatedModelImport','FederatedModelImport',2,26000,26000,'26000,26092','','own',92,1,1,1,0,'2026-07-16 02:12:05.992','2026-07-16 02:12:05.992'),
(26093,'FederatedModelPreview','FederatedModelPreview',2,26000,26000,'26000,26093','','own',93,1,1,1,0,'2026-07-16 02:12:05.992','2026-07-16 02:12:05.992'),
(26094,'FederatedModelingWorkbench','FederatedModelingWorkbench',2,26000,26000,'26000,26094','','own',94,1,1,1,0,'2026-07-16 02:12:05.992','2026-07-16 02:12:05.992'),
(26095,'FederatedQuery','FederatedQuery',2,26000,26000,'26000,26095','','own',95,1,1,1,0,'2026-07-16 02:12:05.992','2026-07-16 02:12:05.992'),
(26096,'FederatedQueryApiValidation','FederatedQueryApiValidation',2,26000,26000,'26000,26096','','own',96,1,1,1,0,'2026-07-16 02:12:05.992','2026-07-16 02:12:05.992'),
(26097,'FederatedQueryBillingByCount','FederatedQueryBillingByCount',2,26000,26000,'26000,26097','','own',97,1,1,1,0,'2026-07-16 02:12:05.993','2026-07-16 02:12:05.993'),
(26098,'FederatedQueryBillingByHit','FederatedQueryBillingByHit',2,26000,26000,'26000,26098','','own',98,1,1,1,0,'2026-07-16 02:12:05.993','2026-07-16 02:12:05.993'),
(26099,'FederatedQueryDHBatch','FederatedQueryDHBatch',2,26000,26000,'26000,26099','','own',99,1,1,1,0,'2026-07-16 02:12:05.993','2026-07-16 02:12:05.993'),
(26100,'FederatedQueryDHRealtime','FederatedQueryDHRealtime',2,26000,26000,'26000,26100','','own',100,1,1,1,0,'2026-07-16 02:12:05.993','2026-07-16 02:12:05.993'),
(26101,'FederatedQueryDeduplicationFixed','FederatedQueryDeduplicationFixed',2,26000,26000,'26000,26101','','own',101,1,1,1,0,'2026-07-16 02:12:05.993','2026-07-16 02:12:05.993'),
(26102,'FederatedQueryDeduplicationRolling','FederatedQueryDeduplicationRolling',2,26000,26000,'26000,26102','','own',102,1,1,1,0,'2026-07-16 02:12:05.993','2026-07-16 02:12:05.993'),
(26103,'FederatedQueryHEBatch','FederatedQueryHEBatch',2,26000,26000,'26000,26103','','own',103,1,1,1,0,'2026-07-16 02:12:05.994','2026-07-16 02:12:05.994'),
(26104,'FederatedQueryHERealtime','FederatedQueryHERealtime',2,26000,26000,'26000,26104','','own',104,1,1,1,0,'2026-07-16 02:12:05.994','2026-07-16 02:12:05.994'),
(26105,'FederatedQueryIntersectionBatch','FederatedQueryIntersectionBatch',2,26000,26000,'26000,26105','','own',105,1,1,1,0,'2026-07-16 02:12:05.994','2026-07-16 02:12:05.994'),
(26106,'FederatedQueryIntersectionDedup','FederatedQueryIntersectionDedup',2,26000,26000,'26000,26106','','own',106,1,1,1,0,'2026-07-16 02:12:05.994','2026-07-16 02:12:05.994'),
(26107,'FederatedQueryIntersectionMultiColumn','FederatedQueryIntersectionMultiColumn',2,26000,26000,'26000,26107','','own',107,1,1,1,0,'2026-07-16 02:12:05.994','2026-07-16 02:12:05.994'),
(26108,'FederatedQueryIntersectionRealtime','FederatedQueryIntersectionRealtime',2,26000,26000,'26000,26108','','own',108,1,1,1,0,'2026-07-16 02:12:05.995','2026-07-16 02:12:05.995'),
(26109,'FederatedQueryLogIntersectionExport','FederatedQueryLogIntersectionExport',2,26000,26000,'26000,26109','','own',109,1,1,1,0,'2026-07-16 02:12:05.995','2026-07-16 02:12:05.995'),
(26110,'FederatedQueryLogIntersectionRecord','FederatedQueryLogIntersectionRecord',2,26000,26000,'26000,26110','','own',110,1,1,1,0,'2026-07-16 02:12:05.995','2026-07-16 02:12:05.995'),
(26111,'FederatedQueryLogQueryExport','FederatedQueryLogQueryExport',2,26000,26000,'26000,26111','','own',111,1,1,1,0,'2026-07-16 02:12:05.996','2026-07-16 02:12:05.996'),
(26112,'FederatedQueryLogQueryRecord','FederatedQueryLogQueryRecord',2,26000,26000,'26000,26112','','own',112,1,1,1,0,'2026-07-16 02:12:05.996','2026-07-16 02:12:05.996'),
(26113,'FederatedQueryOTBatch','FederatedQueryOTBatch',2,26000,26000,'26000,26113','','own',113,1,1,1,0,'2026-07-16 02:12:05.996','2026-07-16 02:12:05.996'),
(26114,'FederatedQueryOTRealtime','FederatedQueryOTRealtime',2,26000,26000,'26000,26114','','own',114,1,1,1,0,'2026-07-16 02:12:05.996','2026-07-16 02:12:05.996'),
(26115,'FederatedQueryOutputFields','FederatedQueryOutputFields',2,26000,26000,'26000,26115','','own',115,1,1,1,0,'2026-07-16 02:12:05.996','2026-07-16 02:12:05.996'),
(26116,'FederatedQueryPayloadChunk','FederatedQueryPayloadChunk',2,26000,26000,'26000,26116','','own',116,1,1,1,0,'2026-07-16 02:12:05.997','2026-07-16 02:12:05.997'),
(26117,'FederatedQueryToolsBucket','FederatedQueryToolsBucket',2,26000,26000,'26000,26117','','own',117,1,1,1,0,'2026-07-16 02:12:05.997','2026-07-16 02:12:05.997'),
(26118,'FederatedQueryToolsCodec','FederatedQueryToolsCodec',2,26000,26000,'26000,26118','','own',118,1,1,1,0,'2026-07-16 02:12:05.997','2026-07-16 02:12:05.997'),
(26119,'FederatedQueryToolsCompress','FederatedQueryToolsCompress',2,26000,26000,'26000,26119','','own',119,1,1,1,0,'2026-07-16 02:12:05.997','2026-07-16 02:12:05.997'),
(26120,'FederatedQueryToolsDecompress','FederatedQueryToolsDecompress',2,26000,26000,'26000,26120','','own',120,1,1,1,0,'2026-07-16 02:12:05.997','2026-07-16 02:12:05.997'),
(26121,'FederatedQueryToolsDedup','FederatedQueryToolsDedup',2,26000,26000,'26000,26121','','own',121,1,1,1,0,'2026-07-16 02:12:05.998','2026-07-16 02:12:05.998'),
(26122,'FederatedStatisticsChiSquareTest','FederatedStatisticsChiSquareTest',2,26000,26000,'26000,26122','','own',122,1,1,1,0,'2026-07-16 02:12:05.998','2026-07-16 02:12:05.998'),
(26123,'FederatedStatisticsConditionStats','FederatedStatisticsConditionStats',2,26000,26000,'26000,26123','','own',123,1,1,1,0,'2026-07-16 02:12:05.998','2026-07-16 02:12:05.998'),
(26124,'FederatedStatisticsCorrelationAnalysis','FederatedStatisticsCorrelationAnalysis',2,26000,26000,'26000,26124','','own',124,1,1,1,0,'2026-07-16 02:12:05.998','2026-07-16 02:12:05.998'),
(26125,'FederatedStatisticsFTest','FederatedStatisticsFTest',2,26000,26000,'26000,26125','','own',125,1,1,1,0,'2026-07-16 02:12:05.999','2026-07-16 02:12:05.999'),
(26126,'FederatedStatisticsGroupStats','FederatedStatisticsGroupStats',2,26000,26000,'26000,26126','','own',126,1,1,1,0,'2026-07-16 02:12:05.999','2026-07-16 02:12:05.999'),
(26127,'FederatedStatisticsIndex','FederatedStatisticsIndex',2,26000,26000,'26000,26127','','own',127,1,1,1,0,'2026-07-16 02:12:05.999','2026-07-16 02:12:05.999'),
(26128,'FederatedStatisticsLogExport','FederatedStatisticsLogExport',2,26000,26000,'26000,26128','','own',128,1,1,1,0,'2026-07-16 02:12:05.999','2026-07-16 02:12:05.999'),
(26129,'FederatedStatisticsLogRecord','FederatedStatisticsLogRecord',2,26000,26000,'26000,26129','','own',129,1,1,1,0,'2026-07-16 02:12:05.999','2026-07-16 02:12:05.999'),
(26130,'FederatedStatisticsRatioStats','FederatedStatisticsRatioStats',2,26000,26000,'26000,26130','','own',130,1,1,1,0,'2026-07-16 02:12:06.000','2026-07-16 02:12:06.000'),
(26131,'FederatedStatisticsRegressionAnalysis','FederatedStatisticsRegressionAnalysis',2,26000,26000,'26000,26131','','own',131,1,1,1,0,'2026-07-16 02:12:06.000','2026-07-16 02:12:06.000'),
(26132,'FederatedStatisticsResultExport','FederatedStatisticsResultExport',2,26000,26000,'26000,26132','','own',132,1,1,1,0,'2026-07-16 02:12:06.000','2026-07-16 02:12:06.000'),
(26133,'FederatedStatisticsResultStorage','FederatedStatisticsResultStorage',2,26000,26000,'26000,26133','','own',133,1,1,1,0,'2026-07-16 02:12:06.000','2026-07-16 02:12:06.000'),
(26134,'FederatedStatisticsTTest','FederatedStatisticsTTest',2,26000,26000,'26000,26134','','own',134,1,1,1,0,'2026-07-16 02:12:06.000','2026-07-16 02:12:06.000'),
(26135,'FormData','FormData',2,26000,26000,'26000,26135','','own',135,1,1,1,0,'2026-07-16 02:12:06.001','2026-07-16 02:12:06.001'),
(26136,'Hamburger','Hamburger',2,26000,26000,'26000,26136','','own',136,1,1,1,0,'2026-07-16 02:12:06.001','2026-07-16 02:12:06.001'),
(26137,'InsuranceApiConnect','InsuranceApiConnect',2,26000,26000,'26000,26137','','own',137,1,1,1,0,'2026-07-16 02:12:06.001','2026-07-16 02:12:06.001'),
(26138,'InsuranceDataDecrypt','InsuranceDataDecrypt',2,26000,26000,'26000,26138','','own',138,1,1,1,0,'2026-07-16 02:12:06.001','2026-07-16 02:12:06.001'),
(26139,'InsuranceHomomorphicKey','InsuranceHomomorphicKey',2,26000,26000,'26000,26139','','own',139,1,1,1,0,'2026-07-16 02:12:06.002','2026-07-16 02:12:06.002'),
(26140,'InsuranceModelEncrypt','InsuranceModelEncrypt',2,26000,26000,'26000,26140','','own',140,1,1,1,0,'2026-07-16 02:12:06.002','2026-07-16 02:12:06.002'),
(26141,'Layout','Layout',2,26000,26000,'26000,26141','','own',141,1,1,1,0,'2026-07-16 02:12:06.002','2026-07-16 02:12:06.002'),
(26142,'Log','Log',2,26000,26000,'26000,26142','','own',142,1,1,1,0,'2026-07-16 02:12:06.002','2026-07-16 02:12:06.002'),
(26143,'LogDetail','LogDetail',2,26000,26000,'26000,26143','','own',143,1,1,1,0,'2026-07-16 02:12:06.002','2026-07-16 02:12:06.002'),
(26144,'LogExport','LogExport',2,26000,26000,'26000,26144','','own',144,1,1,1,0,'2026-07-16 02:12:06.003','2026-07-16 02:12:06.003'),
(26145,'LogList','LogList',2,26000,26000,'26000,26145','','own',145,1,1,1,0,'2026-07-16 02:12:06.003','2026-07-16 02:12:06.003'),
(26146,'Map','Map',2,26000,26000,'26000,26146','','own',146,1,1,1,0,'2026-07-16 02:12:06.003','2026-07-16 02:12:06.003'),
(26147,'MenuItem','MenuItem',2,26000,26000,'26000,26147','','own',147,1,1,1,0,'2026-07-16 02:12:06.003','2026-07-16 02:12:06.003'),
(26148,'Model','Model',2,26000,26000,'26000,26148','','own',148,1,1,1,0,'2026-07-16 02:12:06.003','2026-07-16 02:12:06.003'),
(26149,'ModelCipherBatchExchange','ModelCipherBatchExchange',2,26000,26000,'26000,26149','','own',149,1,1,1,0,'2026-07-16 02:12:06.004','2026-07-16 02:12:06.004'),
(26150,'ModelCreate','ModelCreate',2,26000,26000,'26000,26150','','own',150,1,1,1,0,'2026-07-16 02:12:06.004','2026-07-16 02:12:06.004'),
(26151,'ModelDetail','ModelDetail',2,26000,26000,'26000,26151','','own',151,1,1,1,0,'2026-07-16 02:12:06.004','2026-07-16 02:12:06.004'),
(26152,'ModelList','ModelList',2,26000,26000,'26000,26152','','own',152,1,1,1,0,'2026-07-16 02:12:06.004','2026-07-16 02:12:06.004'),
(26153,'ModelReasoning','ModelReasoning',2,26000,26000,'26000,26153','','own',153,1,1,1,0,'2026-07-16 02:12:06.004','2026-07-16 02:12:06.004'),
(26154,'ModelReasoningDetail','ModelReasoningDetail',2,26000,26000,'26000,26154','','own',154,1,1,1,0,'2026-07-16 02:12:06.005','2026-07-16 02:12:06.005'),
(26155,'ModelReasoningList','ModelReasoningList',2,26000,26000,'26000,26155','','own',155,1,1,1,0,'2026-07-16 02:12:06.005','2026-07-16 02:12:06.005'),
(26156,'ModelReasoningTask','ModelReasoningTask',2,26000,26000,'26000,26156','','own',156,1,1,1,0,'2026-07-16 02:12:06.005','2026-07-16 02:12:06.005'),
(26157,'ModelTaskDetail','ModelTaskDetail',2,26000,26000,'26000,26157','','own',157,1,1,1,0,'2026-07-16 02:12:06.006','2026-07-16 02:12:06.006'),
(26158,'Monitor','Monitor',2,26000,26000,'26000,26158','','own',158,1,1,1,0,'2026-07-16 02:12:06.006','2026-07-16 02:12:06.006'),
(26159,'MonitorAlerts','MonitorAlerts',2,26000,26000,'26000,26159','','own',159,1,1,1,0,'2026-07-16 02:12:06.006','2026-07-16 02:12:06.006'),
(26160,'MonitorDatabase','MonitorDatabase',2,26000,26000,'26000,26160','','own',160,1,1,1,0,'2026-07-16 02:12:06.006','2026-07-16 02:12:06.006'),
(26161,'MonitorIndex','MonitorIndex',2,26000,26000,'26000,26161','','own',161,1,1,1,0,'2026-07-16 02:12:06.006','2026-07-16 02:12:06.006'),
(26162,'MonitorMiddleware','MonitorMiddleware',2,26000,26000,'26000,26162','','own',162,1,1,1,0,'2026-07-16 02:12:06.006','2026-07-16 02:12:06.006'),
(26163,'MonitorOs','MonitorOs',2,26000,26000,'26000,26163','','own',163,1,1,1,0,'2026-07-16 02:12:06.007','2026-07-16 02:12:06.007'),
(26164,'OnSiteCertFeatureConvert','OnSiteCertFeatureConvert',2,26000,26000,'26000,26164','','own',164,1,1,1,0,'2026-07-16 02:12:06.007','2026-07-16 02:12:06.007'),
(26165,'OperationLog','OperationLog',2,26000,26000,'26000,26165','','own',165,1,1,1,0,'2026-07-16 02:12:06.007','2026-07-16 02:12:06.007'),
(26166,'OperationLogDefinition','OperationLogDefinition',2,26000,26000,'26000,26166','','own',166,1,1,1,0,'2026-07-16 02:12:06.007','2026-07-16 02:12:06.007'),
(26167,'OrgDataExport','OrgDataExport',2,26000,26000,'26000,26167','','own',167,1,1,1,0,'2026-07-16 02:12:06.007','2026-07-16 02:12:06.007'),
(26168,'OrgDataImport','OrgDataImport',2,26000,26000,'26000,26168','','own',168,1,1,1,0,'2026-07-16 02:12:06.008','2026-07-16 02:12:06.008'),
(26169,'OrganManage','OrganManage',2,26000,26000,'26000,26169','','own',169,1,1,1,0,'2026-07-16 02:12:06.008','2026-07-16 02:12:06.008'),
(26170,'PIRDetail','PIRDetail',2,26000,26000,'26000,26170','','own',170,1,1,1,0,'2026-07-16 02:12:06.008','2026-07-16 02:12:06.008'),
(26171,'PIRTask','PIRTask',2,26000,26000,'26000,26171','','own',171,1,1,1,0,'2026-07-16 02:12:06.008','2026-07-16 02:12:06.008'),
(26172,'PSI','PSI',2,26000,26000,'26000,26172','','own',172,1,1,1,0,'2026-07-16 02:12:06.009','2026-07-16 02:12:06.009'),
(26173,'PSIDetail','PSIDetail',2,26000,26000,'26000,26173','','own',173,1,1,1,0,'2026-07-16 02:12:06.009','2026-07-16 02:12:06.009'),
(26174,'PSIList','PSIList',2,26000,26000,'26000,26174','','own',174,1,1,1,0,'2026-07-16 02:12:06.009','2026-07-16 02:12:06.009'),
(26175,'PSIResult','PSIResult',2,26000,26000,'26000,26175','','own',175,1,1,1,0,'2026-07-16 02:12:06.009','2026-07-16 02:12:06.009'),
(26176,'PSITask','PSITask',2,26000,26000,'26000,26176','','own',176,1,1,1,0,'2026-07-16 02:12:06.009','2026-07-16 02:12:06.009'),
(26177,'PasswordLevel','PasswordLevel',2,26000,26000,'26000,26177','','own',177,1,1,1,0,'2026-07-16 02:12:06.009','2026-07-16 02:12:06.009'),
(26178,'PersonalInfo','PersonalInfo',2,26000,26000,'26000,26178','','own',178,1,1,1,0,'2026-07-16 02:12:06.010','2026-07-16 02:12:06.010'),
(26179,'PoliceDataConnect','PoliceDataConnect',2,26000,26000,'26000,26179','','own',179,1,1,1,0,'2026-07-16 02:12:06.010','2026-07-16 02:12:06.010'),
(26180,'PoliceDataFusion','PoliceDataFusion',2,26000,26000,'26000,26180','','own',180,1,1,1,0,'2026-07-16 02:12:06.010','2026-07-16 02:12:06.010'),
(26181,'PoliceDataIntersection','PoliceDataIntersection',2,26000,26000,'26000,26181','','own',181,1,1,1,0,'2026-07-16 02:12:06.010','2026-07-16 02:12:06.010'),
(26182,'PoliceDataLogExport','PoliceDataLogExport',2,26000,26000,'26000,26182','','own',182,1,1,1,0,'2026-07-16 02:12:06.010','2026-07-16 02:12:06.010'),
(26183,'PoliceDataLogRecord','PoliceDataLogRecord',2,26000,26000,'26000,26183','','own',183,1,1,1,0,'2026-07-16 02:12:06.011','2026-07-16 02:12:06.011'),
(26184,'PrivateSearch','PrivateSearch',2,26000,26000,'26000,26184','','own',184,1,1,1,0,'2026-07-16 02:12:06.011','2026-07-16 02:12:06.011'),
(26185,'PrivateSearchList','PrivateSearchList',2,26000,26000,'26000,26185','','own',185,1,1,1,0,'2026-07-16 02:12:06.011','2026-07-16 02:12:06.011'),
(26186,'Project','Project',2,26000,26000,'26000,26186','','own',186,1,1,1,0,'2026-07-16 02:12:06.011','2026-07-16 02:12:06.011'),
(26187,'ProjectApprovalConfig','ProjectApprovalConfig',2,26000,26000,'26000,26187','','own',187,1,1,1,0,'2026-07-16 02:12:06.011','2026-07-16 02:12:06.011'),
(26188,'ProjectCreate','ProjectCreate',2,26000,26000,'26000,26188','','own',188,1,1,1,0,'2026-07-16 02:12:06.011','2026-07-16 02:12:06.011'),
(26189,'ProjectDetail','ProjectDetail',2,26000,26000,'26000,26189','','own',189,1,1,1,0,'2026-07-16 02:12:06.012','2026-07-16 02:12:06.012'),
(26190,'ProjectFATasks','ProjectFATasks',2,26000,26000,'26000,26190','','own',190,1,1,1,0,'2026-07-16 02:12:06.012','2026-07-16 02:12:06.012'),
(26191,'ProjectFLTasks','ProjectFLTasks',2,26000,26000,'26000,26191','','own',191,1,1,1,0,'2026-07-16 02:12:06.012','2026-07-16 02:12:06.012'),
(26192,'ProjectFSTasks','ProjectFSTasks',2,26000,26000,'26000,26192','','own',192,1,1,1,0,'2026-07-16 02:12:06.013','2026-07-16 02:12:06.013'),
(26193,'ProjectFederatedAnalysis','ProjectFederatedAnalysis',2,26000,26000,'26000,26193','','own',193,1,1,1,0,'2026-07-16 02:12:06.013','2026-07-16 02:12:06.013'),
(26194,'ProjectFederatedLearning','ProjectFederatedLearning',2,26000,26000,'26000,26194','','own',194,1,1,1,0,'2026-07-16 02:12:06.013','2026-07-16 02:12:06.013'),
(26195,'ProjectFederatedStatistics','ProjectFederatedStatistics',2,26000,26000,'26000,26195','','own',195,1,1,1,0,'2026-07-16 02:12:06.013','2026-07-16 02:12:06.013'),
(26196,'ProjectLedgerExport','ProjectLedgerExport',2,26000,26000,'26000,26196','','own',196,1,1,1,0,'2026-07-16 02:12:06.013','2026-07-16 02:12:06.013'),
(26197,'ProjectList','ProjectList',2,26000,26000,'26000,26197','','own',197,1,1,1,0,'2026-07-16 02:12:06.013','2026-07-16 02:12:06.013'),
(26198,'ProjectPermission','ProjectPermission',2,26000,26000,'26000,26198','','own',198,1,1,1,0,'2026-07-16 02:12:06.014','2026-07-16 02:12:06.014'),
(26199,'ProjectResultSave','ProjectResultSave',2,26000,26000,'26000,26199','','own',199,1,1,1,0,'2026-07-16 02:12:06.014','2026-07-16 02:12:06.014'),
(26200,'ResourceAuthAudit','ResourceAuthAudit',2,26000,26000,'26000,26200','','own',200,1,1,1,0,'2026-07-16 02:12:06.014','2026-07-16 02:12:06.014'),
(26201,'ResourceAuthRecord','ResourceAuthRecord',2,26000,26000,'26000,26201','','own',201,1,1,1,0,'2026-07-16 02:12:06.015','2026-07-16 02:12:06.015'),
(26202,'ResourceDetail','ResourceDetail',2,26000,26000,'26000,26202','','own',202,1,1,1,0,'2026-07-16 02:12:06.015','2026-07-16 02:12:06.015'),
(26203,'ResourceEdit','ResourceEdit',2,26000,26000,'26000,26203','','own',203,1,1,1,0,'2026-07-16 02:12:06.015','2026-07-16 02:12:06.015'),
(26204,'ResourceList','ResourceList',2,26000,26000,'26000,26204','','own',204,1,1,1,0,'2026-07-16 02:12:06.015','2026-07-16 02:12:06.015'),
(26205,'ResourceMenu','ResourceMenu',2,26000,26000,'26000,26205','','own',205,1,1,1,0,'2026-07-16 02:12:06.015','2026-07-16 02:12:06.015'),
(26206,'ResourceUpload','ResourceUpload',2,26000,26000,'26000,26206','','own',206,1,1,1,0,'2026-07-16 02:12:06.016','2026-07-16 02:12:06.016'),
(26207,'RoleManage','RoleManage',2,26000,26000,'26000,26207','','own',207,1,1,1,0,'2026-07-16 02:12:06.016','2026-07-16 02:12:06.016'),
(26208,'ScheduleLog','ScheduleLog',2,26000,26000,'26000,26208','','own',208,1,1,1,0,'2026-07-16 02:12:06.016','2026-07-16 02:12:06.016'),
(26209,'ScheduleLogDefinition','ScheduleLogDefinition',2,26000,26000,'26000,26209','','own',209,1,1,1,0,'2026-07-16 02:12:06.016','2026-07-16 02:12:06.016'),
(26210,'Setting','Setting',2,26000,26000,'26000,26210','','own',210,1,1,1,0,'2026-07-16 02:12:06.016','2026-07-16 02:12:06.016'),
(26211,'SharedDatasetList','SharedDatasetList',2,26000,26000,'26000,26211','','own',211,1,1,1,0,'2026-07-16 02:12:06.017','2026-07-16 02:12:06.017'),
(26212,'SidebarItem','SidebarItem',2,26000,26000,'26000,26212','','own',212,1,1,1,0,'2026-07-16 02:12:06.017','2026-07-16 02:12:06.017'),
(26213,'SingleParty','SingleParty',2,26000,26000,'26000,26213','','own',213,1,1,1,0,'2026-07-16 02:12:06.017','2026-07-16 02:12:06.017'),
(26214,'SinglePartyDataCleaning','SinglePartyDataCleaning',2,26000,26000,'26000,26214','','own',214,1,1,1,0,'2026-07-16 02:12:06.017','2026-07-16 02:12:06.017'),
(26215,'SinglePartyDataScaling','SinglePartyDataScaling',2,26000,26000,'26000,26215','','own',215,1,1,1,0,'2026-07-16 02:12:06.017','2026-07-16 02:12:06.017'),
(26216,'SinglePartyDataStats','SinglePartyDataStats',2,26000,26000,'26000,26216','','own',216,1,1,1,0,'2026-07-16 02:12:06.017','2026-07-16 02:12:06.017'),
(26217,'SinglePartyDetail','SinglePartyDetail',2,26000,26000,'26000,26217','','own',217,1,1,1,0,'2026-07-16 02:12:06.018','2026-07-16 02:12:06.018'),
(26218,'SinglePartyFeatureBin','SinglePartyFeatureBin',2,26000,26000,'26000,26218','','own',218,1,1,1,0,'2026-07-16 02:12:06.018','2026-07-16 02:12:06.018'),
(26219,'SinglePartyFeatureDerive','SinglePartyFeatureDerive',2,26000,26000,'26000,26219','','own',219,1,1,1,0,'2026-07-16 02:12:06.018','2026-07-16 02:12:06.018'),
(26220,'SinglePartyFeatureEncode','SinglePartyFeatureEncode',2,26000,26000,'26000,26220','','own',220,1,1,1,0,'2026-07-16 02:12:06.018','2026-07-16 02:12:06.018'),
(26221,'SinglePartyFeatureSelect','SinglePartyFeatureSelect',2,26000,26000,'26000,26221','','own',221,1,1,1,0,'2026-07-16 02:12:06.018','2026-07-16 02:12:06.018'),
(26222,'SinglePartyLRAlgorithm','SinglePartyLRAlgorithm',2,26000,26000,'26000,26222','','own',222,1,1,1,0,'2026-07-16 02:12:06.019','2026-07-16 02:12:06.019'),
(26223,'SinglePartyList','SinglePartyList',2,26000,26000,'26000,26223','','own',223,1,1,1,0,'2026-07-16 02:12:06.019','2026-07-16 02:12:06.019'),
(26224,'SinglePartyLogExport','SinglePartyLogExport',2,26000,26000,'26000,26224','','own',224,1,1,1,0,'2026-07-16 02:12:06.020','2026-07-16 02:12:06.020'),
(26225,'SinglePartyLogRecord','SinglePartyLogRecord',2,26000,26000,'26000,26225','','own',225,1,1,1,0,'2026-07-16 02:12:06.020','2026-07-16 02:12:06.020'),
(26226,'SinglePartyPythonScript','SinglePartyPythonScript',2,26000,26000,'26000,26226','','own',226,1,1,1,0,'2026-07-16 02:12:06.020','2026-07-16 02:12:06.020'),
(26227,'SinglePartySqlProcess','SinglePartySqlProcess',2,26000,26000,'26000,26227','','own',227,1,1,1,0,'2026-07-16 02:12:06.020','2026-07-16 02:12:06.020'),
(26228,'SinglePartyTask','SinglePartyTask',2,26000,26000,'26000,26228','','own',228,1,1,1,0,'2026-07-16 02:12:06.020','2026-07-16 02:12:06.020'),
(26229,'SinglePartyXGBAlgorithm','SinglePartyXGBAlgorithm',2,26000,26000,'26000,26229','','own',229,1,1,1,0,'2026-07-16 02:12:06.021','2026-07-16 02:12:06.021'),
(26230,'SvgIcon','SvgIcon',2,26000,26000,'26000,26230','','own',230,1,1,1,0,'2026-07-16 02:12:06.021','2026-07-16 02:12:06.021'),
(26231,'SystemConfig','SystemConfig',2,26000,26000,'26000,26231','','own',231,1,1,1,0,'2026-07-16 02:12:06.021','2026-07-16 02:12:06.021'),
(26232,'Tenant','Tenant',2,26000,26000,'26000,26232','','own',232,1,1,1,0,'2026-07-16 02:12:06.021','2026-07-16 02:12:06.021'),
(26233,'TenantDataIsolation','TenantDataIsolation',2,26000,26000,'26000,26233','','own',233,1,1,1,0,'2026-07-16 02:12:06.021','2026-07-16 02:12:06.021'),
(26234,'TenantIsolationConfig','TenantIsolationConfig',2,26000,26000,'26000,26234','','own',234,1,1,1,0,'2026-07-16 02:12:06.021','2026-07-16 02:12:06.021'),
(26235,'TenantList','TenantList',2,26000,26000,'26000,26235','','own',235,1,1,1,0,'2026-07-16 02:12:06.022','2026-07-16 02:12:06.022'),
(26236,'TenantResource','TenantResource',2,26000,26000,'26000,26236','','own',236,1,1,1,0,'2026-07-16 02:12:06.022','2026-07-16 02:12:06.022'),
(26237,'UISetting','UISetting',2,26000,26000,'26000,26237','','own',237,1,1,1,0,'2026-07-16 02:12:06.022','2026-07-16 02:12:06.022'),
(26238,'Union','Union',2,26000,26000,'26000,26238','','own',238,1,1,1,0,'2026-07-16 02:12:06.022','2026-07-16 02:12:06.022'),
(26239,'UnionDetail','UnionDetail',2,26000,26000,'26000,26239','','own',239,1,1,1,0,'2026-07-16 02:12:06.023','2026-07-16 02:12:06.023'),
(26240,'UnionList','UnionList',2,26000,26000,'26000,26240','','own',240,1,1,1,0,'2026-07-16 02:12:06.023','2026-07-16 02:12:06.023'),
(26241,'UnionResourceDetail','UnionResourceDetail',2,26000,26000,'26000,26241','','own',241,1,1,1,0,'2026-07-16 02:12:06.023','2026-07-16 02:12:06.023'),
(26242,'UnionTask','UnionTask',2,26000,26000,'26000,26242','','own',242,1,1,1,0,'2026-07-16 02:12:06.023','2026-07-16 02:12:06.023'),
(26243,'UserManage','UserManage',2,26000,26000,'26000,26243','','own',243,1,1,1,0,'2026-07-16 02:12:06.023','2026-07-16 02:12:06.023'),
(26244,'Whitelist','Whitelist',2,26000,26000,'26000,26244','','own',244,1,1,1,0,'2026-07-16 02:12:06.023','2026-07-16 02:12:06.023'),
(26245,'WhitelistAccessLog','WhitelistAccessLog',2,26000,26000,'26000,26245','','own',245,1,1,1,0,'2026-07-16 02:12:06.024','2026-07-16 02:12:06.024'),
(26246,'WhitelistConfig','WhitelistConfig',2,26000,26000,'26000,26246','','own',246,1,1,1,0,'2026-07-16 02:12:06.024','2026-07-16 02:12:06.024'),
(26247,'WhitelistList','WhitelistList',2,26000,26000,'26000,26247','','own',247,1,1,1,0,'2026-07-16 02:12:06.024','2026-07-16 02:12:06.024'),
(26248,'applicationIndex','applicationIndex',2,26000,26000,'26000,26248','','own',248,1,1,1,0,'2026-07-16 02:12:06.024','2026-07-16 02:12:06.024'),
(26249,'breadcrumb','breadcrumb',2,26000,26000,'26000,26249','','own',249,1,1,1,0,'2026-07-16 02:12:06.024','2026-07-16 02:12:06.024'),
(26250,'mapIndex','mapIndex',2,26000,26000,'26000,26250','','own',250,1,1,1,0,'2026-07-16 02:12:06.025','2026-07-16 02:12:06.025'),
(26251,'oldPassword','oldPassword',2,26000,26000,'26000,26251','','own',251,1,1,1,0,'2026-07-16 02:12:06.025','2026-07-16 02:12:06.025'),
(26252,'password','password',2,26000,26000,'26000,26252','','own',252,1,1,1,0,'2026-07-16 02:12:06.025','2026-07-16 02:12:06.025'),
(26253,'passwordAgain','passwordAgain',2,26000,26000,'26000,26253','','own',253,1,1,1,0,'2026-07-16 02:12:06.025','2026-07-16 02:12:06.025'),
(26254,'userAccount','userAccount',2,26000,26000,'26000,26254','','own',254,1,1,1,0,'2026-07-16 02:12:06.025','2026-07-16 02:12:06.025'),
(26255,'verificationCode','verificationCode',2,26000,26000,'26000,26255','','own',255,1,1,1,0,'2026-07-16 02:12:06.025','2026-07-16 02:12:06.025'),
(26256,'删除资源','ResourceDelete',3,1023,1022,'1022,1023,26256','/data/resource/deldataresource','own',11,2,1,1,0,'2026-07-16 02:12:06.435','2026-07-16 02:12:06.444'),
(26257,'冻结用户','UserFreeze',3,2001,2000,'2000,2001,26257','/sys/user/freezeUser','own',15,2,1,1,0,'2026-07-16 02:12:06.435','2026-07-16 02:12:06.444'),
(26258,'新增白名单','WhitelistAdd',3,26247,26000,'26000,26247,26258','/whitelist/addWhitelist','own',11,2,1,1,0,'2026-07-16 02:12:06.435','2026-07-16 02:12:06.444'),
(26259,'编辑白名单','WhitelistEdit',3,26247,26000,'26000,26247,26259','/whitelist/updateWhitelist','own',12,2,1,1,0,'2026-07-16 02:12:06.435','2026-07-16 02:12:06.444'),
(26260,'编辑白名单配置','WhitelistConfigEdit',3,26246,26000,'26000,26246,26260','/whitelist/saveWhitelistConfig','own',11,2,1,1,0,'2026-07-16 02:12:06.435','2026-07-16 02:12:06.444'),
(26261,'新增租户','TenantAdd',3,26235,26000,'26000,26235,26261','/tenant/addTenant','own',11,2,1,1,0,'2026-07-16 02:12:06.435','2026-07-16 02:12:06.444'),
(26262,'编辑租户','TenantEdit',3,26235,26000,'26000,26235,26262','/tenant/updateTenant','own',12,2,1,1,0,'2026-07-16 02:12:06.435','2026-07-16 02:12:06.444'),
(26263,'删除租户','TenantDelete',3,26235,26000,'26000,26235,26263','/tenant/deleteTenant','own',13,2,1,1,0,'2026-07-16 02:12:06.435','2026-07-16 02:12:06.444'),
(26264,'冻结租户','TenantFreeze',3,26235,26000,'26000,26235,26264','/tenant/freezeTenant','own',14,2,1,1,0,'2026-07-16 02:12:06.435','2026-07-16 02:12:06.444');
/*!40000 ALTER TABLE `sys_auth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_compute_log`
--

DROP TABLE IF EXISTS `sys_compute_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_compute_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(255) DEFAULT NULL,
  `task_name` varchar(255) DEFAULT NULL,
  `compute_type` varchar(64) DEFAULT NULL COMMENT '计算类型',
  `organ_id` varchar(255) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `user_name` varchar(255) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `duration_ms` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `result_summary` text DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `log_code` varchar(64) DEFAULT NULL,
  `project_id` bigint(20) DEFAULT NULL,
  `project_name` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `execution_time` bigint(20) DEFAULT NULL,
  `error_msg` varchar(1000) DEFAULT NULL,
  `resource_usage` varchar(255) DEFAULT NULL,
  `result_data` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_compute_log`
--

LOCK TABLES `sys_compute_log` WRITE;
/*!40000 ALTER TABLE `sys_compute_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_compute_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_compute_log_definition`
--

DROP TABLE IF EXISTS `sys_compute_log_definition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_compute_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `log_name` varchar(255) DEFAULT NULL,
  `compute_type` varchar(64) DEFAULT NULL COMMENT '计算类型',
  `description` text DEFAULT NULL,
  `is_enabled` tinyint(1) DEFAULT 1,
  `retention_days` int(11) DEFAULT 30,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  `module_name` varchar(128) DEFAULT NULL COMMENT '模块名',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_compute_log_definition`
--

LOCK TABLES `sys_compute_log_definition` WRITE;
/*!40000 ALTER TABLE `sys_compute_log_definition` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_compute_log_definition` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_config`
--

DROP TABLE IF EXISTS `sys_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_group` varchar(50) NOT NULL COMMENT '配置分组: network/time/login_restriction/personalization/ftp',
  `config_key` varchar(100) NOT NULL COMMENT '配置键',
  `config_value` text DEFAULT NULL COMMENT '配置值',
  `config_desc` varchar(500) DEFAULT NULL COMMENT '配置说明',
  `is_encrypted` tinyint(1) DEFAULT 0 COMMENT '是否加密存储',
  `created_by` bigint(20) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime DEFAULT current_timestamp() COMMENT '创建时间',
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_key` (`config_group`,`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_config`
--

LOCK TABLES `sys_config` WRITE;
/*!40000 ALTER TABLE `sys_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_file`
--

DROP TABLE IF EXISTS `sys_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_file` (
  `file_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '文件id',
  `file_source` int(12) NOT NULL COMMENT '文件来源',
  `file_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '文件地址',
  `file_name` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '文件名称',
  `file_suffix` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '文件后缀',
  `file_size` bigint(20) NOT NULL COMMENT '文件实际大小',
  `file_current_size` bigint(20) NOT NULL COMMENT '文件当前大小',
  `file_area` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '文件区域',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`file_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='文件表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_file`
--

LOCK TABLES `sys_file` WRITE;
/*!40000 ALTER TABLE `sys_file` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_file` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_operation_log`
--

DROP TABLE IF EXISTS `sys_operation_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_operation_log` (
  `log_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `user_id` bigint(20) DEFAULT NULL COMMENT '操作用户ID',
  `user_name` varchar(100) DEFAULT NULL COMMENT '操作用户名',
  `operation_type` varchar(64) DEFAULT NULL COMMENT '操作类型',
  `operation_module` varchar(50) DEFAULT NULL COMMENT '操作模块（如：用户管理、项目管理）',
  `operation_desc` varchar(200) DEFAULT NULL COMMENT '操作描述',
  `request_method` varchar(10) DEFAULT NULL COMMENT '请求方法：POST/PUT/DELETE',
  `request_url` varchar(500) DEFAULT NULL COMMENT '请求URL',
  `request_params` text DEFAULT NULL COMMENT '请求参数（JSON格式）',
  `response_code` varchar(20) DEFAULT NULL COMMENT '响应状态码',
  `response_msg` varchar(500) DEFAULT NULL COMMENT '响应消息',
  `operation_time` bigint(20) DEFAULT NULL COMMENT '操作耗时（毫秒）',
  `ip_address` varchar(50) DEFAULT NULL COMMENT 'IP地址',
  `user_agent` varchar(500) DEFAULT NULL COMMENT '用户代理',
  `exception_msg` text DEFAULT NULL COMMENT '异常信息',
  `is_success` tinyint(4) DEFAULT 1 COMMENT '是否成功：0-失败 1-成功',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除：0-否 1-是',
  `created_time` timestamp NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `updated_time` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  `error_msg` varchar(1024) DEFAULT NULL,
  `execution_time` bigint(20) DEFAULT NULL,
  `log_code` varchar(255) DEFAULT NULL,
  `organ_id` varchar(255) DEFAULT NULL,
  `organ_name` varchar(255) DEFAULT NULL,
  `response_result` varchar(1024) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  PRIMARY KEY (`log_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_operation_type` (`operation_type`),
  KEY `idx_created_time` (`created_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统操作日志表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_operation_log`
--

LOCK TABLES `sys_operation_log` WRITE;
/*!40000 ALTER TABLE `sys_operation_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_operation_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_operation_log_definition`
--

DROP TABLE IF EXISTS `sys_operation_log_definition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_operation_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `log_name` varchar(255) DEFAULT NULL,
  `log_type` varchar(64) DEFAULT NULL COMMENT '操作类型',
  `module_name` varchar(128) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `is_enabled` tinyint(1) DEFAULT 1,
  `retention_days` int(11) DEFAULT 30,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_operation_log_definition`
--

LOCK TABLES `sys_operation_log_definition` WRITE;
/*!40000 ALTER TABLE `sys_operation_log_definition` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_operation_log_definition` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_organ`
--

DROP TABLE IF EXISTS `sys_organ`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_organ` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '机构id',
  `apply_id` varchar(255) DEFAULT NULL COMMENT '申请加入ID',
  `organ_id` varchar(255) DEFAULT NULL COMMENT '申请加入机构ID',
  `organ_name` varchar(255) DEFAULT NULL COMMENT '申请加入机构名称',
  `organ_gateway` varchar(255) DEFAULT NULL COMMENT '申请加入机构网关地址',
  `public_key` varchar(1000) DEFAULT NULL COMMENT '机构公钥',
  `examine_state` tinyint(4) DEFAULT 0 COMMENT '可用状态(0待审批 1同意 2拒绝)',
  `examine_msg` mediumtext DEFAULT NULL COMMENT '审批信息',
  `node_state` tinyint(4) DEFAULT 0 COMMENT '可用状态(0不在线 1在线)',
  `fusion_state` tinyint(4) DEFAULT 0 COMMENT '可用状态(0不在线 1在线)',
  `platform_state` tinyint(4) DEFAULT 0 COMMENT '可用状态(0不在线 1在线)',
  `lat` decimal(18,14) DEFAULT NULL COMMENT '纬度',
  `lon` decimal(18,14) DEFAULT NULL COMMENT '经度',
  `country` varchar(255) DEFAULT NULL COMMENT '区域',
  `enable` tinyint(4) NOT NULL COMMENT '是否启用 0启用 1禁用',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  `p_organ_id` varchar(255) DEFAULT NULL COMMENT '父机构id(内部机构树)',
  `organ_index` int(11) DEFAULT 0 COMMENT '同级顺序',
  `identity` int(11) DEFAULT 1 COMMENT '机构身份(D20)',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='机构信息';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_organ`
--

LOCK TABLES `sys_organ` WRITE;
/*!40000 ALTER TABLE `sys_organ` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_organ` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_ra`
--

DROP TABLE IF EXISTS `sys_ra`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_ra` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `auth_id` bigint(20) NOT NULL COMMENT '权限id',
  `is_del` tinyint(2) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2121 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色权限表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_ra`
--

LOCK TABLES `sys_ra` WRITE;
/*!40000 ALTER TABLE `sys_ra` DISABLE KEYS */;
INSERT INTO `sys_ra` VALUES
(1000,1,1001,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1001,1,1002,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1002,1,1003,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1003,1,1004,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1004,1,1005,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1005,1,1006,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1006,1,1007,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1007,1,1008,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1008,1,1009,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1009,1,1010,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1010,1,1011,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1011,1,1012,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1012,1,1013,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1013,1,1014,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1014,1,1015,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1015,1,1016,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1016,1,1017,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1017,1,1018,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1018,1,1019,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1019,1,1020,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1020,1,1021,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1021,1,1022,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1022,1,1023,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1023,1,1024,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1024,1,1025,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1025,1,1026,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1026,1,1027,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1027,1,1028,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1028,1,1029,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1029,1,1030,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1030,1,1031,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1031,1,1032,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1032,1,1033,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1033,1,1034,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1034,1,1035,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1035,1,1036,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1036,1,1037,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1037,1,1038,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1038,1,1039,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1039,1,1040,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1040,1,1041,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1041,1,1042,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1042,1,1043,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1043,1,1044,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1044,1,1045,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1045,1,1046,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1046,1,1047,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1047,1,1048,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1048,1,1049,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1049,1,1050,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1050,1,1051,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1051,1,1052,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1052,1,1053,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1053,1,1054,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1054,1,1055,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1055,1,1056,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1056,1,1057,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1057,1,1059,0,'2022-07-19 08:51:05.228','2022-07-19 08:51:05.228'),
(1058,1000,1001,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1059,1000,1002,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1060,1000,1005,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1061,1000,1006,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1062,1000,1003,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1063,1000,1050,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1064,1000,1051,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1065,1000,1052,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1066,1000,1053,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1067,1000,1004,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1068,1000,1007,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1069,1000,1008,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1070,1000,1009,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1071,1000,1010,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1072,1000,1011,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1073,1000,1012,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1074,1000,1013,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1075,1000,1014,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1076,1000,1015,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1077,1000,1016,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1078,1000,1017,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1079,1000,1018,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1080,1000,1059,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1081,1000,1019,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1082,1000,1020,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1083,1000,1021,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1084,1000,1022,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1085,1000,1023,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1086,1000,1024,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1087,1000,1025,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1088,1000,1026,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1089,1000,1027,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1090,1000,1028,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1091,1000,1054,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1092,1000,1055,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1093,1000,1056,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1094,1000,1057,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1095,1000,1058,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1096,1,1060,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1097,1,1061,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1098,1000,1060,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1099,1000,1061,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1100,1,1062,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1101,1000,1062,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1102,1,1063,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1103,1,1058,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1104,1,1064,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1105,1,1065,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1106,1000,1064,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1107,1000,1065,0,'2022-10-27 10:47:26.136','2022-10-27 10:47:26.136'),
(1108,1,2000,0,'2026-07-16 02:12:05.881','2026-07-16 02:12:05.881'),
(1109,1,2001,0,'2026-07-16 02:12:05.881','2026-07-16 02:12:05.881'),
(1110,1,20101,0,'2026-07-16 02:12:05.882','2026-07-16 02:12:05.882'),
(1111,1,20102,0,'2026-07-16 02:12:05.882','2026-07-16 02:12:05.882'),
(1112,1,20103,0,'2026-07-16 02:12:05.882','2026-07-16 02:12:05.882'),
(1113,1,20104,0,'2026-07-16 02:12:05.882','2026-07-16 02:12:05.882'),
(1114,1,20105,0,'2026-07-16 02:12:05.882','2026-07-16 02:12:05.882'),
(1115,1,20106,0,'2026-07-16 02:12:05.882','2026-07-16 02:12:05.882'),
(1116,1,2002,0,'2026-07-16 02:12:05.882','2026-07-16 02:12:05.882'),
(1117,1,20201,0,'2026-07-16 02:12:05.883','2026-07-16 02:12:05.883'),
(1118,1,20202,0,'2026-07-16 02:12:05.883','2026-07-16 02:12:05.883'),
(1119,1,20203,0,'2026-07-16 02:12:05.883','2026-07-16 02:12:05.883'),
(1120,1,20204,0,'2026-07-16 02:12:05.883','2026-07-16 02:12:05.883'),
(1121,1,20205,0,'2026-07-16 02:12:05.883','2026-07-16 02:12:05.883'),
(1122,1,2003,0,'2026-07-16 02:12:05.883','2026-07-16 02:12:05.883'),
(1123,1,20301,0,'2026-07-16 02:12:05.883','2026-07-16 02:12:05.883'),
(1124,1,20302,0,'2026-07-16 02:12:05.884','2026-07-16 02:12:05.884'),
(1125,1,20303,0,'2026-07-16 02:12:05.884','2026-07-16 02:12:05.884'),
(1126,1,20304,0,'2026-07-16 02:12:05.884','2026-07-16 02:12:05.884'),
(1127,1,20305,0,'2026-07-16 02:12:05.884','2026-07-16 02:12:05.884'),
(1128,1,20306,0,'2026-07-16 02:12:05.885','2026-07-16 02:12:05.885'),
(1129,1,20307,0,'2026-07-16 02:12:05.885','2026-07-16 02:12:05.885'),
(1130,1,20308,0,'2026-07-16 02:12:05.885','2026-07-16 02:12:05.885'),
(1131,1,2004,0,'2026-07-16 02:12:05.885','2026-07-16 02:12:05.885'),
(1132,1,20401,0,'2026-07-16 02:12:05.885','2026-07-16 02:12:05.885'),
(1133,1,20402,0,'2026-07-16 02:12:05.885','2026-07-16 02:12:05.885'),
(1134,1,20403,0,'2026-07-16 02:12:05.886','2026-07-16 02:12:05.886'),
(1135,1,20404,0,'2026-07-16 02:12:05.886','2026-07-16 02:12:05.886'),
(1136,1,20405,0,'2026-07-16 02:12:05.886','2026-07-16 02:12:05.886'),
(1137,1,2005,0,'2026-07-16 02:12:05.886','2026-07-16 02:12:05.886'),
(1138,1,20501,0,'2026-07-16 02:12:05.886','2026-07-16 02:12:05.886'),
(1139,1,20502,0,'2026-07-16 02:12:05.886','2026-07-16 02:12:05.886'),
(1140,1,20503,0,'2026-07-16 02:12:05.886','2026-07-16 02:12:05.886'),
(1141,1,20504,0,'2026-07-16 02:12:05.887','2026-07-16 02:12:05.887'),
(1142,1,20505,0,'2026-07-16 02:12:05.887','2026-07-16 02:12:05.887'),
(1143,1,20506,0,'2026-07-16 02:12:05.887','2026-07-16 02:12:05.887'),
(1144,1,20507,0,'2026-07-16 02:12:05.887','2026-07-16 02:12:05.887'),
(1145,1,2006,0,'2026-07-16 02:12:05.887','2026-07-16 02:12:05.887'),
(1146,1,20601,0,'2026-07-16 02:12:05.887','2026-07-16 02:12:05.887'),
(1147,1,20602,0,'2026-07-16 02:12:05.888','2026-07-16 02:12:05.888'),
(1148,1,20603,0,'2026-07-16 02:12:05.888','2026-07-16 02:12:05.888'),
(1149,1,20604,0,'2026-07-16 02:12:05.888','2026-07-16 02:12:05.888'),
(1150,1,20605,0,'2026-07-16 02:12:05.888','2026-07-16 02:12:05.888'),
(1151,1,20606,0,'2026-07-16 02:12:05.888','2026-07-16 02:12:05.888'),
(1152,1,2007,0,'2026-07-16 02:12:05.889','2026-07-16 02:12:05.889'),
(1153,1,20701,0,'2026-07-16 02:12:05.889','2026-07-16 02:12:05.889'),
(1154,1,20702,0,'2026-07-16 02:12:05.889','2026-07-16 02:12:05.889'),
(1155,1,20703,0,'2026-07-16 02:12:05.889','2026-07-16 02:12:05.889'),
(1156,1,20704,0,'2026-07-16 02:12:05.889','2026-07-16 02:12:05.889'),
(1157,1,20705,0,'2026-07-16 02:12:05.889','2026-07-16 02:12:05.889'),
(1158,1,20706,0,'2026-07-16 02:12:05.890','2026-07-16 02:12:05.890'),
(1159,1,2008,0,'2026-07-16 02:12:05.890','2026-07-16 02:12:05.890'),
(1160,1,20801,0,'2026-07-16 02:12:05.890','2026-07-16 02:12:05.890'),
(1161,1,20802,0,'2026-07-16 02:12:05.890','2026-07-16 02:12:05.890'),
(1162,1,20803,0,'2026-07-16 02:12:05.890','2026-07-16 02:12:05.890'),
(1163,1,20804,0,'2026-07-16 02:12:05.890','2026-07-16 02:12:05.890'),
(1164,1,20805,0,'2026-07-16 02:12:05.890','2026-07-16 02:12:05.890'),
(1165,1,20806,0,'2026-07-16 02:12:05.891','2026-07-16 02:12:05.891'),
(1166,1,20807,0,'2026-07-16 02:12:05.891','2026-07-16 02:12:05.891'),
(1167,1,20808,0,'2026-07-16 02:12:05.891','2026-07-16 02:12:05.891'),
(1168,1,2009,0,'2026-07-16 02:12:05.891','2026-07-16 02:12:05.891'),
(1169,1,20901,0,'2026-07-16 02:12:05.891','2026-07-16 02:12:05.891'),
(1170,1,20902,0,'2026-07-16 02:12:05.891','2026-07-16 02:12:05.891'),
(1171,1,20903,0,'2026-07-16 02:12:05.891','2026-07-16 02:12:05.891'),
(1172,1,20904,0,'2026-07-16 02:12:05.892','2026-07-16 02:12:05.892'),
(1173,1,20905,0,'2026-07-16 02:12:05.892','2026-07-16 02:12:05.892'),
(1174,1,20906,0,'2026-07-16 02:12:05.892','2026-07-16 02:12:05.892'),
(1175,1,20907,0,'2026-07-16 02:12:05.892','2026-07-16 02:12:05.892'),
(1176,1,20908,0,'2026-07-16 02:12:05.892','2026-07-16 02:12:05.892'),
(1177,1,20909,0,'2026-07-16 02:12:05.892','2026-07-16 02:12:05.892'),
(1178,1,2010,0,'2026-07-16 02:12:05.893','2026-07-16 02:12:05.893'),
(1179,1,21001,0,'2026-07-16 02:12:05.893','2026-07-16 02:12:05.893'),
(1180,1,21002,0,'2026-07-16 02:12:05.893','2026-07-16 02:12:05.893'),
(1181,1,21003,0,'2026-07-16 02:12:05.893','2026-07-16 02:12:05.893'),
(1182,1,21004,0,'2026-07-16 02:12:05.893','2026-07-16 02:12:05.893'),
(1183,1,21005,0,'2026-07-16 02:12:05.893','2026-07-16 02:12:05.893'),
(1184,1,21006,0,'2026-07-16 02:12:05.893','2026-07-16 02:12:05.893'),
(1185,1,21007,0,'2026-07-16 02:12:05.893','2026-07-16 02:12:05.893'),
(1186,1,2011,0,'2026-07-16 02:12:05.894','2026-07-16 02:12:05.894'),
(1187,1,21101,0,'2026-07-16 02:12:05.894','2026-07-16 02:12:05.894'),
(1188,1,21102,0,'2026-07-16 02:12:05.894','2026-07-16 02:12:05.894'),
(1189,1,21103,0,'2026-07-16 02:12:05.894','2026-07-16 02:12:05.894'),
(1190,1,21104,0,'2026-07-16 02:12:05.894','2026-07-16 02:12:05.894'),
(1191,1,21105,0,'2026-07-16 02:12:05.894','2026-07-16 02:12:05.894'),
(1192,1,21106,0,'2026-07-16 02:12:05.894','2026-07-16 02:12:05.894'),
(1193,1,21107,0,'2026-07-16 02:12:05.895','2026-07-16 02:12:05.895'),
(1194,1,21108,0,'2026-07-16 02:12:05.895','2026-07-16 02:12:05.895'),
(1195,1,21109,0,'2026-07-16 02:12:05.895','2026-07-16 02:12:05.895'),
(1196,1,21110,0,'2026-07-16 02:12:05.895','2026-07-16 02:12:05.895'),
(1197,1,21111,0,'2026-07-16 02:12:05.895','2026-07-16 02:12:05.895'),
(1198,1,21112,0,'2026-07-16 02:12:05.896','2026-07-16 02:12:05.896'),
(1199,1,21113,0,'2026-07-16 02:12:05.896','2026-07-16 02:12:05.896'),
(1200,1,21114,0,'2026-07-16 02:12:05.896','2026-07-16 02:12:05.896'),
(1201,1,21115,0,'2026-07-16 02:12:05.896','2026-07-16 02:12:05.896'),
(1202,1,21116,0,'2026-07-16 02:12:05.896','2026-07-16 02:12:05.896'),
(1203,1,2012,0,'2026-07-16 02:12:05.896','2026-07-16 02:12:05.896'),
(1204,1,21201,0,'2026-07-16 02:12:05.896','2026-07-16 02:12:05.896'),
(1205,1,21202,0,'2026-07-16 02:12:05.897','2026-07-16 02:12:05.897'),
(1206,1,21203,0,'2026-07-16 02:12:05.897','2026-07-16 02:12:05.897'),
(1207,1,21204,0,'2026-07-16 02:12:05.897','2026-07-16 02:12:05.897'),
(1208,1,21205,0,'2026-07-16 02:12:05.897','2026-07-16 02:12:05.897'),
(1209,1,21206,0,'2026-07-16 02:12:05.898','2026-07-16 02:12:05.898'),
(1210,1,2013,0,'2026-07-16 02:12:05.898','2026-07-16 02:12:05.898'),
(1211,1,21301,0,'2026-07-16 02:12:05.898','2026-07-16 02:12:05.898'),
(1212,1,21302,0,'2026-07-16 02:12:05.898','2026-07-16 02:12:05.898'),
(1213,1,21303,0,'2026-07-16 02:12:05.898','2026-07-16 02:12:05.898'),
(1214,1,21304,0,'2026-07-16 02:12:05.898','2026-07-16 02:12:05.898'),
(1215,1,21305,0,'2026-07-16 02:12:05.898','2026-07-16 02:12:05.898'),
(1216,1,21306,0,'2026-07-16 02:12:05.899','2026-07-16 02:12:05.899'),
(1217,1,21307,0,'2026-07-16 02:12:05.899','2026-07-16 02:12:05.899'),
(1218,1,21308,0,'2026-07-16 02:12:05.899','2026-07-16 02:12:05.899'),
(1219,1,21309,0,'2026-07-16 02:12:05.899','2026-07-16 02:12:05.899'),
(1220,1,21310,0,'2026-07-16 02:12:05.899','2026-07-16 02:12:05.899'),
(1221,1,21311,0,'2026-07-16 02:12:05.899','2026-07-16 02:12:05.899'),
(1222,1,21312,0,'2026-07-16 02:12:05.900','2026-07-16 02:12:05.900'),
(1223,1,21313,0,'2026-07-16 02:12:05.900','2026-07-16 02:12:05.900'),
(1224,1,21314,0,'2026-07-16 02:12:05.900','2026-07-16 02:12:05.900'),
(1225,1,21315,0,'2026-07-16 02:12:05.900','2026-07-16 02:12:05.900'),
(1226,1,21316,0,'2026-07-16 02:12:05.900','2026-07-16 02:12:05.900'),
(1227,1,21317,0,'2026-07-16 02:12:05.900','2026-07-16 02:12:05.900'),
(1228,1,21318,0,'2026-07-16 02:12:05.900','2026-07-16 02:12:05.900'),
(1229,1,21319,0,'2026-07-16 02:12:05.901','2026-07-16 02:12:05.901'),
(1230,1,21320,0,'2026-07-16 02:12:05.901','2026-07-16 02:12:05.901'),
(1231,1,21321,0,'2026-07-16 02:12:05.901','2026-07-16 02:12:05.901'),
(1232,1,21322,0,'2026-07-16 02:12:05.901','2026-07-16 02:12:05.901'),
(1233,1,21323,0,'2026-07-16 02:12:05.901','2026-07-16 02:12:05.901'),
(1234,1,21324,0,'2026-07-16 02:12:05.901','2026-07-16 02:12:05.901'),
(1235,1,21325,0,'2026-07-16 02:12:05.901','2026-07-16 02:12:05.901'),
(1236,1,21326,0,'2026-07-16 02:12:05.902','2026-07-16 02:12:05.902'),
(1237,1,21327,0,'2026-07-16 02:12:05.902','2026-07-16 02:12:05.902'),
(1238,1,21328,0,'2026-07-16 02:12:05.902','2026-07-16 02:12:05.902'),
(1239,1,21329,0,'2026-07-16 02:12:05.902','2026-07-16 02:12:05.902'),
(1240,1,21330,0,'2026-07-16 02:12:05.902','2026-07-16 02:12:05.902'),
(1241,1,21331,0,'2026-07-16 02:12:05.903','2026-07-16 02:12:05.903'),
(1242,1,21332,0,'2026-07-16 02:12:05.903','2026-07-16 02:12:05.903'),
(1243,1,21333,0,'2026-07-16 02:12:05.903','2026-07-16 02:12:05.903'),
(1244,1,21334,0,'2026-07-16 02:12:05.903','2026-07-16 02:12:05.903'),
(1245,1,21335,0,'2026-07-16 02:12:05.903','2026-07-16 02:12:05.903'),
(1246,1,21336,0,'2026-07-16 02:12:05.903','2026-07-16 02:12:05.903'),
(1247,1,21337,0,'2026-07-16 02:12:05.903','2026-07-16 02:12:05.903'),
(1248,1,21338,0,'2026-07-16 02:12:05.904','2026-07-16 02:12:05.904'),
(1249,1,21339,0,'2026-07-16 02:12:05.904','2026-07-16 02:12:05.904'),
(1250,1,2014,0,'2026-07-16 02:12:05.904','2026-07-16 02:12:05.904'),
(1251,1,21401,0,'2026-07-16 02:12:05.904','2026-07-16 02:12:05.904'),
(1252,1,21402,0,'2026-07-16 02:12:05.904','2026-07-16 02:12:05.904'),
(1253,1,21403,0,'2026-07-16 02:12:05.904','2026-07-16 02:12:05.904'),
(1254,1,21404,0,'2026-07-16 02:12:05.904','2026-07-16 02:12:05.904'),
(1255,1,21405,0,'2026-07-16 02:12:05.904','2026-07-16 02:12:05.904'),
(1256,1,21406,0,'2026-07-16 02:12:05.905','2026-07-16 02:12:05.905'),
(1257,1,21407,0,'2026-07-16 02:12:05.905','2026-07-16 02:12:05.905'),
(1258,1,21408,0,'2026-07-16 02:12:05.905','2026-07-16 02:12:05.905'),
(1259,1,21409,0,'2026-07-16 02:12:05.905','2026-07-16 02:12:05.905'),
(1260,1,21410,0,'2026-07-16 02:12:05.905','2026-07-16 02:12:05.905'),
(1261,1,21411,0,'2026-07-16 02:12:05.905','2026-07-16 02:12:05.905'),
(1262,1,21412,0,'2026-07-16 02:12:05.906','2026-07-16 02:12:05.906'),
(1263,1,21413,0,'2026-07-16 02:12:05.906','2026-07-16 02:12:05.906'),
(1264,1,2015,0,'2026-07-16 02:12:05.906','2026-07-16 02:12:05.906'),
(1265,1,21501,0,'2026-07-16 02:12:05.907','2026-07-16 02:12:05.907'),
(1266,1,21502,0,'2026-07-16 02:12:05.907','2026-07-16 02:12:05.907'),
(1267,1,21503,0,'2026-07-16 02:12:05.907','2026-07-16 02:12:05.907'),
(1268,1,21504,0,'2026-07-16 02:12:05.907','2026-07-16 02:12:05.907'),
(1269,1,21505,0,'2026-07-16 02:12:05.907','2026-07-16 02:12:05.907'),
(1270,1,21506,0,'2026-07-16 02:12:05.907','2026-07-16 02:12:05.907'),
(1271,1,21507,0,'2026-07-16 02:12:05.907','2026-07-16 02:12:05.907'),
(1272,1,21508,0,'2026-07-16 02:12:05.908','2026-07-16 02:12:05.908'),
(1273,1,21509,0,'2026-07-16 02:12:05.908','2026-07-16 02:12:05.908'),
(1274,1,21510,0,'2026-07-16 02:12:05.908','2026-07-16 02:12:05.908'),
(1275,1,21511,0,'2026-07-16 02:12:05.908','2026-07-16 02:12:05.908'),
(1276,1,21512,0,'2026-07-16 02:12:05.908','2026-07-16 02:12:05.908'),
(1277,1,21513,0,'2026-07-16 02:12:05.908','2026-07-16 02:12:05.908'),
(1278,1,21514,0,'2026-07-16 02:12:05.909','2026-07-16 02:12:05.909'),
(1279,1,21515,0,'2026-07-16 02:12:05.909','2026-07-16 02:12:05.909'),
(1280,1,21516,0,'2026-07-16 02:12:05.909','2026-07-16 02:12:05.909'),
(1281,1,21517,0,'2026-07-16 02:12:05.909','2026-07-16 02:12:05.909'),
(1282,1,21518,0,'2026-07-16 02:12:05.909','2026-07-16 02:12:05.909'),
(1283,1,21519,0,'2026-07-16 02:12:05.910','2026-07-16 02:12:05.910'),
(1284,1,21520,0,'2026-07-16 02:12:05.910','2026-07-16 02:12:05.910'),
(1285,1,2016,0,'2026-07-16 02:12:05.910','2026-07-16 02:12:05.910'),
(1286,1,21601,0,'2026-07-16 02:12:05.910','2026-07-16 02:12:05.910'),
(1287,1,21602,0,'2026-07-16 02:12:05.910','2026-07-16 02:12:05.910'),
(1288,1,21603,0,'2026-07-16 02:12:05.910','2026-07-16 02:12:05.910'),
(1289,1,21604,0,'2026-07-16 02:12:05.910','2026-07-16 02:12:05.910'),
(1290,1,21605,0,'2026-07-16 02:12:05.911','2026-07-16 02:12:05.911'),
(1291,1,21606,0,'2026-07-16 02:12:05.911','2026-07-16 02:12:05.911'),
(1292,1,21607,0,'2026-07-16 02:12:05.911','2026-07-16 02:12:05.911'),
(1293,1,21608,0,'2026-07-16 02:12:05.911','2026-07-16 02:12:05.911'),
(1294,1,21609,0,'2026-07-16 02:12:05.911','2026-07-16 02:12:05.911'),
(1295,1,21610,0,'2026-07-16 02:12:05.912','2026-07-16 02:12:05.912'),
(1296,1,21611,0,'2026-07-16 02:12:05.912','2026-07-16 02:12:05.912'),
(1297,1,21612,0,'2026-07-16 02:12:05.912','2026-07-16 02:12:05.912'),
(1298,1,21613,0,'2026-07-16 02:12:05.912','2026-07-16 02:12:05.912'),
(1299,1,21614,0,'2026-07-16 02:12:05.912','2026-07-16 02:12:05.912'),
(1300,1,21615,0,'2026-07-16 02:12:05.912','2026-07-16 02:12:05.912'),
(1301,1,21616,0,'2026-07-16 02:12:05.912','2026-07-16 02:12:05.912'),
(1302,1,21617,0,'2026-07-16 02:12:05.913','2026-07-16 02:12:05.913'),
(1303,1,21618,0,'2026-07-16 02:12:05.913','2026-07-16 02:12:05.913'),
(1304,1,21619,0,'2026-07-16 02:12:05.913','2026-07-16 02:12:05.913'),
(1305,1,21620,0,'2026-07-16 02:12:05.913','2026-07-16 02:12:05.913'),
(1306,1,21621,0,'2026-07-16 02:12:05.913','2026-07-16 02:12:05.913'),
(1307,1,21622,0,'2026-07-16 02:12:05.914','2026-07-16 02:12:05.914'),
(1308,1,21623,0,'2026-07-16 02:12:05.914','2026-07-16 02:12:05.914'),
(1309,1,21624,0,'2026-07-16 02:12:05.914','2026-07-16 02:12:05.914'),
(1310,1,21625,0,'2026-07-16 02:12:05.914','2026-07-16 02:12:05.914'),
(1311,1,21626,0,'2026-07-16 02:12:05.914','2026-07-16 02:12:05.914'),
(1312,1,21627,0,'2026-07-16 02:12:05.914','2026-07-16 02:12:05.914'),
(1313,1,21628,0,'2026-07-16 02:12:05.914','2026-07-16 02:12:05.914'),
(1314,1,21629,0,'2026-07-16 02:12:05.915','2026-07-16 02:12:05.915'),
(1315,1,21630,0,'2026-07-16 02:12:05.915','2026-07-16 02:12:05.915'),
(1316,1,21631,0,'2026-07-16 02:12:05.915','2026-07-16 02:12:05.915'),
(1317,1,21632,0,'2026-07-16 02:12:05.915','2026-07-16 02:12:05.915'),
(1318,1,21633,0,'2026-07-16 02:12:05.915','2026-07-16 02:12:05.915'),
(1319,1,21634,0,'2026-07-16 02:12:05.915','2026-07-16 02:12:05.915'),
(1320,1,21635,0,'2026-07-16 02:12:05.915','2026-07-16 02:12:05.915'),
(1321,1,21636,0,'2026-07-16 02:12:05.916','2026-07-16 02:12:05.916'),
(1322,1,21637,0,'2026-07-16 02:12:05.916','2026-07-16 02:12:05.916'),
(1323,1,21638,0,'2026-07-16 02:12:05.916','2026-07-16 02:12:05.916'),
(1324,1,21639,0,'2026-07-16 02:12:05.916','2026-07-16 02:12:05.916'),
(1325,1,21640,0,'2026-07-16 02:12:05.916','2026-07-16 02:12:05.916'),
(1326,1,21641,0,'2026-07-16 02:12:05.916','2026-07-16 02:12:05.916'),
(1327,1,21642,0,'2026-07-16 02:12:05.917','2026-07-16 02:12:05.917'),
(1328,1,21643,0,'2026-07-16 02:12:05.917','2026-07-16 02:12:05.917'),
(1329,1,2017,0,'2026-07-16 02:12:05.917','2026-07-16 02:12:05.917'),
(1330,1,21701,0,'2026-07-16 02:12:05.917','2026-07-16 02:12:05.917'),
(1331,1,21702,0,'2026-07-16 02:12:05.917','2026-07-16 02:12:05.917'),
(1332,1,21703,0,'2026-07-16 02:12:05.917','2026-07-16 02:12:05.917'),
(1333,1,21704,0,'2026-07-16 02:12:05.918','2026-07-16 02:12:05.918'),
(1334,1,21705,0,'2026-07-16 02:12:05.918','2026-07-16 02:12:05.918'),
(1335,1,21706,0,'2026-07-16 02:12:05.918','2026-07-16 02:12:05.918'),
(1336,1,21707,0,'2026-07-16 02:12:05.918','2026-07-16 02:12:05.918'),
(1337,1,21708,0,'2026-07-16 02:12:05.918','2026-07-16 02:12:05.918'),
(1338,1,21709,0,'2026-07-16 02:12:05.918','2026-07-16 02:12:05.918'),
(1339,1,21710,0,'2026-07-16 02:12:05.918','2026-07-16 02:12:05.918'),
(1340,1,2018,0,'2026-07-16 02:12:05.919','2026-07-16 02:12:05.919'),
(1341,1,21801,0,'2026-07-16 02:12:05.919','2026-07-16 02:12:05.919'),
(1342,1,21802,0,'2026-07-16 02:12:05.919','2026-07-16 02:12:05.919'),
(1343,1,21803,0,'2026-07-16 02:12:05.919','2026-07-16 02:12:05.919'),
(1344,1,21804,0,'2026-07-16 02:12:05.919','2026-07-16 02:12:05.919'),
(1345,1,21805,0,'2026-07-16 02:12:05.919','2026-07-16 02:12:05.919'),
(1346,1,21806,0,'2026-07-16 02:12:05.919','2026-07-16 02:12:05.919'),
(1347,1,21807,0,'2026-07-16 02:12:05.920','2026-07-16 02:12:05.920'),
(1348,1,21808,0,'2026-07-16 02:12:05.920','2026-07-16 02:12:05.920'),
(1349,1,21809,0,'2026-07-16 02:12:05.920','2026-07-16 02:12:05.920'),
(1350,1,21810,0,'2026-07-16 02:12:05.920','2026-07-16 02:12:05.920'),
(1351,1000,2000,0,'2026-07-16 02:12:05.921','2026-07-16 02:12:05.921'),
(1352,1000,2001,0,'2026-07-16 02:12:05.921','2026-07-16 02:12:05.921'),
(1353,1000,20101,0,'2026-07-16 02:12:05.921','2026-07-16 02:12:05.921'),
(1354,1000,20102,0,'2026-07-16 02:12:05.921','2026-07-16 02:12:05.921'),
(1355,1000,20103,0,'2026-07-16 02:12:05.921','2026-07-16 02:12:05.921'),
(1356,1000,20104,0,'2026-07-16 02:12:05.921','2026-07-16 02:12:05.921'),
(1357,1000,20105,0,'2026-07-16 02:12:05.921','2026-07-16 02:12:05.921'),
(1358,1000,20106,0,'2026-07-16 02:12:05.922','2026-07-16 02:12:05.922'),
(1359,1000,2002,0,'2026-07-16 02:12:05.922','2026-07-16 02:12:05.922'),
(1360,1000,20201,0,'2026-07-16 02:12:05.922','2026-07-16 02:12:05.922'),
(1361,1000,20202,0,'2026-07-16 02:12:05.922','2026-07-16 02:12:05.922'),
(1362,1000,20203,0,'2026-07-16 02:12:05.922','2026-07-16 02:12:05.922'),
(1363,1000,20204,0,'2026-07-16 02:12:05.922','2026-07-16 02:12:05.922'),
(1364,1000,20205,0,'2026-07-16 02:12:05.922','2026-07-16 02:12:05.922'),
(1365,1000,2003,0,'2026-07-16 02:12:05.923','2026-07-16 02:12:05.923'),
(1366,1000,20301,0,'2026-07-16 02:12:05.923','2026-07-16 02:12:05.923'),
(1367,1000,20302,0,'2026-07-16 02:12:05.923','2026-07-16 02:12:05.923'),
(1368,1000,20303,0,'2026-07-16 02:12:05.923','2026-07-16 02:12:05.923'),
(1369,1000,20304,0,'2026-07-16 02:12:05.923','2026-07-16 02:12:05.923'),
(1370,1000,20305,0,'2026-07-16 02:12:05.923','2026-07-16 02:12:05.923'),
(1371,1000,20306,0,'2026-07-16 02:12:05.924','2026-07-16 02:12:05.924'),
(1372,1000,20307,0,'2026-07-16 02:12:05.924','2026-07-16 02:12:05.924'),
(1373,1000,20308,0,'2026-07-16 02:12:05.924','2026-07-16 02:12:05.924'),
(1374,1000,2004,0,'2026-07-16 02:12:05.924','2026-07-16 02:12:05.924'),
(1375,1000,20401,0,'2026-07-16 02:12:05.924','2026-07-16 02:12:05.924'),
(1376,1000,20402,0,'2026-07-16 02:12:05.924','2026-07-16 02:12:05.924'),
(1377,1000,20403,0,'2026-07-16 02:12:05.924','2026-07-16 02:12:05.924'),
(1378,1000,20404,0,'2026-07-16 02:12:05.925','2026-07-16 02:12:05.925'),
(1379,1000,20405,0,'2026-07-16 02:12:05.925','2026-07-16 02:12:05.925'),
(1380,1000,2005,0,'2026-07-16 02:12:05.925','2026-07-16 02:12:05.925'),
(1381,1000,20501,0,'2026-07-16 02:12:05.925','2026-07-16 02:12:05.925'),
(1382,1000,20502,0,'2026-07-16 02:12:05.925','2026-07-16 02:12:05.925'),
(1383,1000,20503,0,'2026-07-16 02:12:05.925','2026-07-16 02:12:05.925'),
(1384,1000,20504,0,'2026-07-16 02:12:05.925','2026-07-16 02:12:05.925'),
(1385,1000,20505,0,'2026-07-16 02:12:05.926','2026-07-16 02:12:05.926'),
(1386,1000,20506,0,'2026-07-16 02:12:05.926','2026-07-16 02:12:05.926'),
(1387,1000,20507,0,'2026-07-16 02:12:05.926','2026-07-16 02:12:05.926'),
(1388,1000,2006,0,'2026-07-16 02:12:05.926','2026-07-16 02:12:05.926'),
(1389,1000,20601,0,'2026-07-16 02:12:05.926','2026-07-16 02:12:05.926'),
(1390,1000,20602,0,'2026-07-16 02:12:05.926','2026-07-16 02:12:05.926'),
(1391,1000,20603,0,'2026-07-16 02:12:05.926','2026-07-16 02:12:05.926'),
(1392,1000,20604,0,'2026-07-16 02:12:05.927','2026-07-16 02:12:05.927'),
(1393,1000,20605,0,'2026-07-16 02:12:05.927','2026-07-16 02:12:05.927'),
(1394,1000,20606,0,'2026-07-16 02:12:05.927','2026-07-16 02:12:05.927'),
(1395,1000,2007,0,'2026-07-16 02:12:05.927','2026-07-16 02:12:05.927'),
(1396,1000,20701,0,'2026-07-16 02:12:05.927','2026-07-16 02:12:05.927'),
(1397,1000,20702,0,'2026-07-16 02:12:05.928','2026-07-16 02:12:05.928'),
(1398,1000,20703,0,'2026-07-16 02:12:05.928','2026-07-16 02:12:05.928'),
(1399,1000,20704,0,'2026-07-16 02:12:05.928','2026-07-16 02:12:05.928'),
(1400,1000,20705,0,'2026-07-16 02:12:05.928','2026-07-16 02:12:05.928'),
(1401,1000,20706,0,'2026-07-16 02:12:05.928','2026-07-16 02:12:05.928'),
(1402,1000,2008,0,'2026-07-16 02:12:05.928','2026-07-16 02:12:05.928'),
(1403,1000,20801,0,'2026-07-16 02:12:05.929','2026-07-16 02:12:05.929'),
(1404,1000,20802,0,'2026-07-16 02:12:05.929','2026-07-16 02:12:05.929'),
(1405,1000,20803,0,'2026-07-16 02:12:05.929','2026-07-16 02:12:05.929'),
(1406,1000,20804,0,'2026-07-16 02:12:05.929','2026-07-16 02:12:05.929'),
(1407,1000,20805,0,'2026-07-16 02:12:05.929','2026-07-16 02:12:05.929'),
(1408,1000,20806,0,'2026-07-16 02:12:05.929','2026-07-16 02:12:05.929'),
(1409,1000,20807,0,'2026-07-16 02:12:05.929','2026-07-16 02:12:05.929'),
(1410,1000,20808,0,'2026-07-16 02:12:05.929','2026-07-16 02:12:05.929'),
(1411,1000,2009,0,'2026-07-16 02:12:05.930','2026-07-16 02:12:05.930'),
(1412,1000,20901,0,'2026-07-16 02:12:05.930','2026-07-16 02:12:05.930'),
(1413,1000,20902,0,'2026-07-16 02:12:05.930','2026-07-16 02:12:05.930'),
(1414,1000,20903,0,'2026-07-16 02:12:05.930','2026-07-16 02:12:05.930'),
(1415,1000,20904,0,'2026-07-16 02:12:05.930','2026-07-16 02:12:05.930'),
(1416,1000,20905,0,'2026-07-16 02:12:05.931','2026-07-16 02:12:05.931'),
(1417,1000,20906,0,'2026-07-16 02:12:05.931','2026-07-16 02:12:05.931'),
(1418,1000,20907,0,'2026-07-16 02:12:05.931','2026-07-16 02:12:05.931'),
(1419,1000,20908,0,'2026-07-16 02:12:05.931','2026-07-16 02:12:05.931'),
(1420,1000,20909,0,'2026-07-16 02:12:05.931','2026-07-16 02:12:05.931'),
(1421,1000,2010,0,'2026-07-16 02:12:05.931','2026-07-16 02:12:05.931'),
(1422,1000,21001,0,'2026-07-16 02:12:05.931','2026-07-16 02:12:05.931'),
(1423,1000,21002,0,'2026-07-16 02:12:05.932','2026-07-16 02:12:05.932'),
(1424,1000,21003,0,'2026-07-16 02:12:05.932','2026-07-16 02:12:05.932'),
(1425,1000,21004,0,'2026-07-16 02:12:05.932','2026-07-16 02:12:05.932'),
(1426,1000,21005,0,'2026-07-16 02:12:05.932','2026-07-16 02:12:05.932'),
(1427,1000,21006,0,'2026-07-16 02:12:05.932','2026-07-16 02:12:05.932'),
(1428,1000,21007,0,'2026-07-16 02:12:05.932','2026-07-16 02:12:05.932'),
(1429,1000,2011,0,'2026-07-16 02:12:05.932','2026-07-16 02:12:05.932'),
(1430,1000,21101,0,'2026-07-16 02:12:05.933','2026-07-16 02:12:05.933'),
(1431,1000,21102,0,'2026-07-16 02:12:05.933','2026-07-16 02:12:05.933'),
(1432,1000,21103,0,'2026-07-16 02:12:05.933','2026-07-16 02:12:05.933'),
(1433,1000,21104,0,'2026-07-16 02:12:05.933','2026-07-16 02:12:05.933'),
(1434,1000,21105,0,'2026-07-16 02:12:05.933','2026-07-16 02:12:05.933'),
(1435,1000,21106,0,'2026-07-16 02:12:05.933','2026-07-16 02:12:05.933'),
(1436,1000,21107,0,'2026-07-16 02:12:05.933','2026-07-16 02:12:05.933'),
(1437,1000,21108,0,'2026-07-16 02:12:05.934','2026-07-16 02:12:05.934'),
(1438,1000,21109,0,'2026-07-16 02:12:05.934','2026-07-16 02:12:05.934'),
(1439,1000,21110,0,'2026-07-16 02:12:05.934','2026-07-16 02:12:05.934'),
(1440,1000,21111,0,'2026-07-16 02:12:05.934','2026-07-16 02:12:05.934'),
(1441,1000,21112,0,'2026-07-16 02:12:05.934','2026-07-16 02:12:05.934'),
(1442,1000,21113,0,'2026-07-16 02:12:05.934','2026-07-16 02:12:05.934'),
(1443,1000,21114,0,'2026-07-16 02:12:05.935','2026-07-16 02:12:05.935'),
(1444,1000,21115,0,'2026-07-16 02:12:05.935','2026-07-16 02:12:05.935'),
(1445,1000,21116,0,'2026-07-16 02:12:05.935','2026-07-16 02:12:05.935'),
(1446,1000,2012,0,'2026-07-16 02:12:05.935','2026-07-16 02:12:05.935'),
(1447,1000,21201,0,'2026-07-16 02:12:05.935','2026-07-16 02:12:05.935'),
(1448,1000,21202,0,'2026-07-16 02:12:05.935','2026-07-16 02:12:05.935'),
(1449,1000,21203,0,'2026-07-16 02:12:05.935','2026-07-16 02:12:05.935'),
(1450,1000,21204,0,'2026-07-16 02:12:05.936','2026-07-16 02:12:05.936'),
(1451,1000,21205,0,'2026-07-16 02:12:05.936','2026-07-16 02:12:05.936'),
(1452,1000,21206,0,'2026-07-16 02:12:05.936','2026-07-16 02:12:05.936'),
(1453,1000,2013,0,'2026-07-16 02:12:05.936','2026-07-16 02:12:05.936'),
(1454,1000,21301,0,'2026-07-16 02:12:05.936','2026-07-16 02:12:05.936'),
(1455,1000,21302,0,'2026-07-16 02:12:05.936','2026-07-16 02:12:05.936'),
(1456,1000,21303,0,'2026-07-16 02:12:05.936','2026-07-16 02:12:05.936'),
(1457,1000,21304,0,'2026-07-16 02:12:05.937','2026-07-16 02:12:05.937'),
(1458,1000,21305,0,'2026-07-16 02:12:05.937','2026-07-16 02:12:05.937'),
(1459,1000,21306,0,'2026-07-16 02:12:05.937','2026-07-16 02:12:05.937'),
(1460,1000,21307,0,'2026-07-16 02:12:05.937','2026-07-16 02:12:05.937'),
(1461,1000,21308,0,'2026-07-16 02:12:05.937','2026-07-16 02:12:05.937'),
(1462,1000,21309,0,'2026-07-16 02:12:05.937','2026-07-16 02:12:05.937'),
(1463,1000,21310,0,'2026-07-16 02:12:05.938','2026-07-16 02:12:05.938'),
(1464,1000,21311,0,'2026-07-16 02:12:05.938','2026-07-16 02:12:05.938'),
(1465,1000,21312,0,'2026-07-16 02:12:05.938','2026-07-16 02:12:05.938'),
(1466,1000,21313,0,'2026-07-16 02:12:05.938','2026-07-16 02:12:05.938'),
(1467,1000,21314,0,'2026-07-16 02:12:05.938','2026-07-16 02:12:05.938'),
(1468,1000,21315,0,'2026-07-16 02:12:05.938','2026-07-16 02:12:05.938'),
(1469,1000,21316,0,'2026-07-16 02:12:05.938','2026-07-16 02:12:05.938'),
(1470,1000,21317,0,'2026-07-16 02:12:05.939','2026-07-16 02:12:05.939'),
(1471,1000,21318,0,'2026-07-16 02:12:05.939','2026-07-16 02:12:05.939'),
(1472,1000,21319,0,'2026-07-16 02:12:05.939','2026-07-16 02:12:05.939'),
(1473,1000,21320,0,'2026-07-16 02:12:05.939','2026-07-16 02:12:05.939'),
(1474,1000,21321,0,'2026-07-16 02:12:05.939','2026-07-16 02:12:05.939'),
(1475,1000,21322,0,'2026-07-16 02:12:05.939','2026-07-16 02:12:05.939'),
(1476,1000,21323,0,'2026-07-16 02:12:05.939','2026-07-16 02:12:05.939'),
(1477,1000,21324,0,'2026-07-16 02:12:05.940','2026-07-16 02:12:05.940'),
(1478,1000,21325,0,'2026-07-16 02:12:05.940','2026-07-16 02:12:05.940'),
(1479,1000,21326,0,'2026-07-16 02:12:05.940','2026-07-16 02:12:05.940'),
(1480,1000,21327,0,'2026-07-16 02:12:05.940','2026-07-16 02:12:05.940'),
(1481,1000,21328,0,'2026-07-16 02:12:05.940','2026-07-16 02:12:05.940'),
(1482,1000,21329,0,'2026-07-16 02:12:05.940','2026-07-16 02:12:05.940'),
(1483,1000,21330,0,'2026-07-16 02:12:05.941','2026-07-16 02:12:05.941'),
(1484,1000,21331,0,'2026-07-16 02:12:05.941','2026-07-16 02:12:05.941'),
(1485,1000,21332,0,'2026-07-16 02:12:05.941','2026-07-16 02:12:05.941'),
(1486,1000,21333,0,'2026-07-16 02:12:05.941','2026-07-16 02:12:05.941'),
(1487,1000,21334,0,'2026-07-16 02:12:05.941','2026-07-16 02:12:05.941'),
(1488,1000,21335,0,'2026-07-16 02:12:05.941','2026-07-16 02:12:05.941'),
(1489,1000,21336,0,'2026-07-16 02:12:05.942','2026-07-16 02:12:05.942'),
(1490,1000,21337,0,'2026-07-16 02:12:05.942','2026-07-16 02:12:05.942'),
(1491,1000,21338,0,'2026-07-16 02:12:05.942','2026-07-16 02:12:05.942'),
(1492,1000,21339,0,'2026-07-16 02:12:05.942','2026-07-16 02:12:05.942'),
(1493,1000,2014,0,'2026-07-16 02:12:05.942','2026-07-16 02:12:05.942'),
(1494,1000,21401,0,'2026-07-16 02:12:05.942','2026-07-16 02:12:05.942'),
(1495,1000,21402,0,'2026-07-16 02:12:05.942','2026-07-16 02:12:05.942'),
(1496,1000,21403,0,'2026-07-16 02:12:05.942','2026-07-16 02:12:05.942'),
(1497,1000,21404,0,'2026-07-16 02:12:05.943','2026-07-16 02:12:05.943'),
(1498,1000,21405,0,'2026-07-16 02:12:05.943','2026-07-16 02:12:05.943'),
(1499,1000,21406,0,'2026-07-16 02:12:05.943','2026-07-16 02:12:05.943'),
(1500,1000,21407,0,'2026-07-16 02:12:05.943','2026-07-16 02:12:05.943'),
(1501,1000,21408,0,'2026-07-16 02:12:05.943','2026-07-16 02:12:05.943'),
(1502,1000,21409,0,'2026-07-16 02:12:05.943','2026-07-16 02:12:05.943'),
(1503,1000,21410,0,'2026-07-16 02:12:05.943','2026-07-16 02:12:05.943'),
(1504,1000,21411,0,'2026-07-16 02:12:05.944','2026-07-16 02:12:05.944'),
(1505,1000,21412,0,'2026-07-16 02:12:05.944','2026-07-16 02:12:05.944'),
(1506,1000,21413,0,'2026-07-16 02:12:05.944','2026-07-16 02:12:05.944'),
(1507,1000,2015,0,'2026-07-16 02:12:05.944','2026-07-16 02:12:05.944'),
(1508,1000,21501,0,'2026-07-16 02:12:05.944','2026-07-16 02:12:05.944'),
(1509,1000,21502,0,'2026-07-16 02:12:05.944','2026-07-16 02:12:05.944'),
(1510,1000,21503,0,'2026-07-16 02:12:05.945','2026-07-16 02:12:05.945'),
(1511,1000,21504,0,'2026-07-16 02:12:05.945','2026-07-16 02:12:05.945'),
(1512,1000,21505,0,'2026-07-16 02:12:05.945','2026-07-16 02:12:05.945'),
(1513,1000,21506,0,'2026-07-16 02:12:05.945','2026-07-16 02:12:05.945'),
(1514,1000,21507,0,'2026-07-16 02:12:05.945','2026-07-16 02:12:05.945'),
(1515,1000,21508,0,'2026-07-16 02:12:05.945','2026-07-16 02:12:05.945'),
(1516,1000,21509,0,'2026-07-16 02:12:05.945','2026-07-16 02:12:05.945'),
(1517,1000,21510,0,'2026-07-16 02:12:05.946','2026-07-16 02:12:05.946'),
(1518,1000,21511,0,'2026-07-16 02:12:05.946','2026-07-16 02:12:05.946'),
(1519,1000,21512,0,'2026-07-16 02:12:05.946','2026-07-16 02:12:05.946'),
(1520,1000,21513,0,'2026-07-16 02:12:05.946','2026-07-16 02:12:05.946'),
(1521,1000,21514,0,'2026-07-16 02:12:05.946','2026-07-16 02:12:05.946'),
(1522,1000,21515,0,'2026-07-16 02:12:05.946','2026-07-16 02:12:05.946'),
(1523,1000,21516,0,'2026-07-16 02:12:05.947','2026-07-16 02:12:05.947'),
(1524,1000,21517,0,'2026-07-16 02:12:05.947','2026-07-16 02:12:05.947'),
(1525,1000,21518,0,'2026-07-16 02:12:05.947','2026-07-16 02:12:05.947'),
(1526,1000,21519,0,'2026-07-16 02:12:05.947','2026-07-16 02:12:05.947'),
(1527,1000,21520,0,'2026-07-16 02:12:05.948','2026-07-16 02:12:05.948'),
(1528,1000,2016,0,'2026-07-16 02:12:05.948','2026-07-16 02:12:05.948'),
(1529,1000,21601,0,'2026-07-16 02:12:05.948','2026-07-16 02:12:05.948'),
(1530,1000,21602,0,'2026-07-16 02:12:05.948','2026-07-16 02:12:05.948'),
(1531,1000,21603,0,'2026-07-16 02:12:05.948','2026-07-16 02:12:05.948'),
(1532,1000,21604,0,'2026-07-16 02:12:05.948','2026-07-16 02:12:05.948'),
(1533,1000,21605,0,'2026-07-16 02:12:05.948','2026-07-16 02:12:05.948'),
(1534,1000,21606,0,'2026-07-16 02:12:05.949','2026-07-16 02:12:05.949'),
(1535,1000,21607,0,'2026-07-16 02:12:05.949','2026-07-16 02:12:05.949'),
(1536,1000,21608,0,'2026-07-16 02:12:05.949','2026-07-16 02:12:05.949'),
(1537,1000,21609,0,'2026-07-16 02:12:05.949','2026-07-16 02:12:05.949'),
(1538,1000,21610,0,'2026-07-16 02:12:05.949','2026-07-16 02:12:05.949'),
(1539,1000,21611,0,'2026-07-16 02:12:05.949','2026-07-16 02:12:05.949'),
(1540,1000,21612,0,'2026-07-16 02:12:05.949','2026-07-16 02:12:05.949'),
(1541,1000,21613,0,'2026-07-16 02:12:05.949','2026-07-16 02:12:05.949'),
(1542,1000,21614,0,'2026-07-16 02:12:05.950','2026-07-16 02:12:05.950'),
(1543,1000,21615,0,'2026-07-16 02:12:05.950','2026-07-16 02:12:05.950'),
(1544,1000,21616,0,'2026-07-16 02:12:05.950','2026-07-16 02:12:05.950'),
(1545,1000,21617,0,'2026-07-16 02:12:05.950','2026-07-16 02:12:05.950'),
(1546,1000,21618,0,'2026-07-16 02:12:05.950','2026-07-16 02:12:05.950'),
(1547,1000,21619,0,'2026-07-16 02:12:05.950','2026-07-16 02:12:05.950'),
(1548,1000,21620,0,'2026-07-16 02:12:05.951','2026-07-16 02:12:05.951'),
(1549,1000,21621,0,'2026-07-16 02:12:05.951','2026-07-16 02:12:05.951'),
(1550,1000,21622,0,'2026-07-16 02:12:05.951','2026-07-16 02:12:05.951'),
(1551,1000,21623,0,'2026-07-16 02:12:05.951','2026-07-16 02:12:05.951'),
(1552,1000,21624,0,'2026-07-16 02:12:05.951','2026-07-16 02:12:05.951'),
(1553,1000,21625,0,'2026-07-16 02:12:05.951','2026-07-16 02:12:05.951'),
(1554,1000,21626,0,'2026-07-16 02:12:05.952','2026-07-16 02:12:05.952'),
(1555,1000,21627,0,'2026-07-16 02:12:05.952','2026-07-16 02:12:05.952'),
(1556,1000,21628,0,'2026-07-16 02:12:05.952','2026-07-16 02:12:05.952'),
(1557,1000,21629,0,'2026-07-16 02:12:05.952','2026-07-16 02:12:05.952'),
(1558,1000,21630,0,'2026-07-16 02:12:05.952','2026-07-16 02:12:05.952'),
(1559,1000,21631,0,'2026-07-16 02:12:05.952','2026-07-16 02:12:05.952'),
(1560,1000,21632,0,'2026-07-16 02:12:05.953','2026-07-16 02:12:05.953'),
(1561,1000,21633,0,'2026-07-16 02:12:05.953','2026-07-16 02:12:05.953'),
(1562,1000,21634,0,'2026-07-16 02:12:05.953','2026-07-16 02:12:05.953'),
(1563,1000,21635,0,'2026-07-16 02:12:05.953','2026-07-16 02:12:05.953'),
(1564,1000,21636,0,'2026-07-16 02:12:05.953','2026-07-16 02:12:05.953'),
(1565,1000,21637,0,'2026-07-16 02:12:05.953','2026-07-16 02:12:05.953'),
(1566,1000,21638,0,'2026-07-16 02:12:05.954','2026-07-16 02:12:05.954'),
(1567,1000,21639,0,'2026-07-16 02:12:05.954','2026-07-16 02:12:05.954'),
(1568,1000,21640,0,'2026-07-16 02:12:05.954','2026-07-16 02:12:05.954'),
(1569,1000,21641,0,'2026-07-16 02:12:05.954','2026-07-16 02:12:05.954'),
(1570,1000,21642,0,'2026-07-16 02:12:05.954','2026-07-16 02:12:05.954'),
(1571,1000,21643,0,'2026-07-16 02:12:05.955','2026-07-16 02:12:05.955'),
(1572,1000,2017,0,'2026-07-16 02:12:05.955','2026-07-16 02:12:05.955'),
(1573,1000,21701,0,'2026-07-16 02:12:05.955','2026-07-16 02:12:05.955'),
(1574,1000,21702,0,'2026-07-16 02:12:05.955','2026-07-16 02:12:05.955'),
(1575,1000,21703,0,'2026-07-16 02:12:05.955','2026-07-16 02:12:05.955'),
(1576,1000,21704,0,'2026-07-16 02:12:05.955','2026-07-16 02:12:05.955'),
(1577,1000,21705,0,'2026-07-16 02:12:05.955','2026-07-16 02:12:05.955'),
(1578,1000,21706,0,'2026-07-16 02:12:05.956','2026-07-16 02:12:05.956'),
(1579,1000,21707,0,'2026-07-16 02:12:05.956','2026-07-16 02:12:05.956'),
(1580,1000,21708,0,'2026-07-16 02:12:05.956','2026-07-16 02:12:05.956'),
(1581,1000,21709,0,'2026-07-16 02:12:05.956','2026-07-16 02:12:05.956'),
(1582,1000,21710,0,'2026-07-16 02:12:05.956','2026-07-16 02:12:05.956'),
(1583,1000,2018,0,'2026-07-16 02:12:05.956','2026-07-16 02:12:05.956'),
(1584,1000,21801,0,'2026-07-16 02:12:05.956','2026-07-16 02:12:05.956'),
(1585,1000,21802,0,'2026-07-16 02:12:05.957','2026-07-16 02:12:05.957'),
(1586,1000,21803,0,'2026-07-16 02:12:05.957','2026-07-16 02:12:05.957'),
(1587,1000,21804,0,'2026-07-16 02:12:05.957','2026-07-16 02:12:05.957'),
(1588,1000,21805,0,'2026-07-16 02:12:05.957','2026-07-16 02:12:05.957'),
(1589,1000,21806,0,'2026-07-16 02:12:05.958','2026-07-16 02:12:05.958'),
(1590,1000,21807,0,'2026-07-16 02:12:05.958','2026-07-16 02:12:05.958'),
(1591,1000,21808,0,'2026-07-16 02:12:05.958','2026-07-16 02:12:05.958'),
(1592,1000,21809,0,'2026-07-16 02:12:05.958','2026-07-16 02:12:05.958'),
(1593,1000,21810,0,'2026-07-16 02:12:05.959','2026-07-16 02:12:05.959'),
(1594,1,26000,0,'2026-07-16 02:12:06.026','2026-07-16 02:12:06.026'),
(1595,1,26001,0,'2026-07-16 02:12:06.026','2026-07-16 02:12:06.026'),
(1596,1,26002,0,'2026-07-16 02:12:06.026','2026-07-16 02:12:06.026'),
(1597,1,26003,0,'2026-07-16 02:12:06.026','2026-07-16 02:12:06.026'),
(1598,1,26004,0,'2026-07-16 02:12:06.027','2026-07-16 02:12:06.027'),
(1599,1,26005,0,'2026-07-16 02:12:06.027','2026-07-16 02:12:06.027'),
(1600,1,26006,0,'2026-07-16 02:12:06.027','2026-07-16 02:12:06.027'),
(1601,1,26007,0,'2026-07-16 02:12:06.027','2026-07-16 02:12:06.027'),
(1602,1,26008,0,'2026-07-16 02:12:06.027','2026-07-16 02:12:06.027'),
(1603,1,26009,0,'2026-07-16 02:12:06.028','2026-07-16 02:12:06.028'),
(1604,1,26010,0,'2026-07-16 02:12:06.028','2026-07-16 02:12:06.028'),
(1605,1,26011,0,'2026-07-16 02:12:06.028','2026-07-16 02:12:06.028'),
(1606,1,26012,0,'2026-07-16 02:12:06.028','2026-07-16 02:12:06.028'),
(1607,1,26013,0,'2026-07-16 02:12:06.028','2026-07-16 02:12:06.028'),
(1608,1,26014,0,'2026-07-16 02:12:06.028','2026-07-16 02:12:06.028'),
(1609,1,26015,0,'2026-07-16 02:12:06.028','2026-07-16 02:12:06.028'),
(1610,1,26016,0,'2026-07-16 02:12:06.029','2026-07-16 02:12:06.029'),
(1611,1,26017,0,'2026-07-16 02:12:06.029','2026-07-16 02:12:06.029'),
(1612,1,26018,0,'2026-07-16 02:12:06.029','2026-07-16 02:12:06.029'),
(1613,1,26019,0,'2026-07-16 02:12:06.029','2026-07-16 02:12:06.029'),
(1614,1,26020,0,'2026-07-16 02:12:06.029','2026-07-16 02:12:06.029'),
(1615,1,26021,0,'2026-07-16 02:12:06.029','2026-07-16 02:12:06.029'),
(1616,1,26022,0,'2026-07-16 02:12:06.029','2026-07-16 02:12:06.029'),
(1617,1,26023,0,'2026-07-16 02:12:06.030','2026-07-16 02:12:06.030'),
(1618,1,26024,0,'2026-07-16 02:12:06.030','2026-07-16 02:12:06.030'),
(1619,1,26025,0,'2026-07-16 02:12:06.030','2026-07-16 02:12:06.030'),
(1620,1,26026,0,'2026-07-16 02:12:06.030','2026-07-16 02:12:06.030'),
(1621,1,26027,0,'2026-07-16 02:12:06.030','2026-07-16 02:12:06.030'),
(1622,1,26028,0,'2026-07-16 02:12:06.031','2026-07-16 02:12:06.031'),
(1623,1,26029,0,'2026-07-16 02:12:06.031','2026-07-16 02:12:06.031'),
(1624,1,26030,0,'2026-07-16 02:12:06.031','2026-07-16 02:12:06.031'),
(1625,1,26031,0,'2026-07-16 02:12:06.031','2026-07-16 02:12:06.031'),
(1626,1,26032,0,'2026-07-16 02:12:06.031','2026-07-16 02:12:06.031'),
(1627,1,26033,0,'2026-07-16 02:12:06.032','2026-07-16 02:12:06.032'),
(1628,1,26034,0,'2026-07-16 02:12:06.032','2026-07-16 02:12:06.032'),
(1629,1,26035,0,'2026-07-16 02:12:06.032','2026-07-16 02:12:06.032'),
(1630,1,26036,0,'2026-07-16 02:12:06.032','2026-07-16 02:12:06.032'),
(1631,1,26037,0,'2026-07-16 02:12:06.032','2026-07-16 02:12:06.032'),
(1632,1,26038,0,'2026-07-16 02:12:06.032','2026-07-16 02:12:06.032'),
(1633,1,26039,0,'2026-07-16 02:12:06.032','2026-07-16 02:12:06.032'),
(1634,1,26040,0,'2026-07-16 02:12:06.033','2026-07-16 02:12:06.033'),
(1635,1,26041,0,'2026-07-16 02:12:06.033','2026-07-16 02:12:06.033'),
(1636,1,26042,0,'2026-07-16 02:12:06.033','2026-07-16 02:12:06.033'),
(1637,1,26043,0,'2026-07-16 02:12:06.033','2026-07-16 02:12:06.033'),
(1638,1,26044,0,'2026-07-16 02:12:06.033','2026-07-16 02:12:06.033'),
(1639,1,26045,0,'2026-07-16 02:12:06.034','2026-07-16 02:12:06.034'),
(1640,1,26046,0,'2026-07-16 02:12:06.034','2026-07-16 02:12:06.034'),
(1641,1,26047,0,'2026-07-16 02:12:06.034','2026-07-16 02:12:06.034'),
(1642,1,26048,0,'2026-07-16 02:12:06.034','2026-07-16 02:12:06.034'),
(1643,1,26049,0,'2026-07-16 02:12:06.035','2026-07-16 02:12:06.035'),
(1644,1,26050,0,'2026-07-16 02:12:06.035','2026-07-16 02:12:06.035'),
(1645,1,26051,0,'2026-07-16 02:12:06.035','2026-07-16 02:12:06.035'),
(1646,1,26052,0,'2026-07-16 02:12:06.035','2026-07-16 02:12:06.035'),
(1647,1,26053,0,'2026-07-16 02:12:06.035','2026-07-16 02:12:06.035'),
(1648,1,26054,0,'2026-07-16 02:12:06.035','2026-07-16 02:12:06.035'),
(1649,1,26055,0,'2026-07-16 02:12:06.036','2026-07-16 02:12:06.036'),
(1650,1,26056,0,'2026-07-16 02:12:06.036','2026-07-16 02:12:06.036'),
(1651,1,26057,0,'2026-07-16 02:12:06.036','2026-07-16 02:12:06.036'),
(1652,1,26058,0,'2026-07-16 02:12:06.036','2026-07-16 02:12:06.036'),
(1653,1,26059,0,'2026-07-16 02:12:06.036','2026-07-16 02:12:06.036'),
(1654,1,26060,0,'2026-07-16 02:12:06.036','2026-07-16 02:12:06.036'),
(1655,1,26061,0,'2026-07-16 02:12:06.037','2026-07-16 02:12:06.037'),
(1656,1,26062,0,'2026-07-16 02:12:06.037','2026-07-16 02:12:06.037'),
(1657,1,26063,0,'2026-07-16 02:12:06.037','2026-07-16 02:12:06.037'),
(1658,1,26064,0,'2026-07-16 02:12:06.037','2026-07-16 02:12:06.037'),
(1659,1,26065,0,'2026-07-16 02:12:06.037','2026-07-16 02:12:06.037'),
(1660,1,26066,0,'2026-07-16 02:12:06.037','2026-07-16 02:12:06.037'),
(1661,1,26067,0,'2026-07-16 02:12:06.040','2026-07-16 02:12:06.040'),
(1662,1,26068,0,'2026-07-16 02:12:06.040','2026-07-16 02:12:06.040'),
(1663,1,26069,0,'2026-07-16 02:12:06.040','2026-07-16 02:12:06.040'),
(1664,1,26070,0,'2026-07-16 02:12:06.040','2026-07-16 02:12:06.040'),
(1665,1,26071,0,'2026-07-16 02:12:06.040','2026-07-16 02:12:06.040'),
(1666,1,26072,0,'2026-07-16 02:12:06.041','2026-07-16 02:12:06.041'),
(1667,1,26073,0,'2026-07-16 02:12:06.041','2026-07-16 02:12:06.041'),
(1668,1,26074,0,'2026-07-16 02:12:06.041','2026-07-16 02:12:06.041'),
(1669,1,26075,0,'2026-07-16 02:12:06.041','2026-07-16 02:12:06.041'),
(1670,1,26076,0,'2026-07-16 02:12:06.041','2026-07-16 02:12:06.041'),
(1671,1,26077,0,'2026-07-16 02:12:06.042','2026-07-16 02:12:06.042'),
(1672,1,26078,0,'2026-07-16 02:12:06.042','2026-07-16 02:12:06.042'),
(1673,1,26079,0,'2026-07-16 02:12:06.042','2026-07-16 02:12:06.042'),
(1674,1,26080,0,'2026-07-16 02:12:06.042','2026-07-16 02:12:06.042'),
(1675,1,26081,0,'2026-07-16 02:12:06.042','2026-07-16 02:12:06.042'),
(1676,1,26082,0,'2026-07-16 02:12:06.042','2026-07-16 02:12:06.042'),
(1677,1,26083,0,'2026-07-16 02:12:06.043','2026-07-16 02:12:06.043'),
(1678,1,26084,0,'2026-07-16 02:12:06.043','2026-07-16 02:12:06.043'),
(1679,1,26085,0,'2026-07-16 02:12:06.043','2026-07-16 02:12:06.043'),
(1680,1,26086,0,'2026-07-16 02:12:06.043','2026-07-16 02:12:06.043'),
(1681,1,26087,0,'2026-07-16 02:12:06.043','2026-07-16 02:12:06.043'),
(1682,1,26088,0,'2026-07-16 02:12:06.043','2026-07-16 02:12:06.043'),
(1683,1,26089,0,'2026-07-16 02:12:06.044','2026-07-16 02:12:06.044'),
(1684,1,26090,0,'2026-07-16 02:12:06.044','2026-07-16 02:12:06.044'),
(1685,1,26091,0,'2026-07-16 02:12:06.044','2026-07-16 02:12:06.044'),
(1686,1,26092,0,'2026-07-16 02:12:06.044','2026-07-16 02:12:06.044'),
(1687,1,26093,0,'2026-07-16 02:12:06.044','2026-07-16 02:12:06.044'),
(1688,1,26094,0,'2026-07-16 02:12:06.044','2026-07-16 02:12:06.044'),
(1689,1,26095,0,'2026-07-16 02:12:06.045','2026-07-16 02:12:06.045'),
(1690,1,26096,0,'2026-07-16 02:12:06.045','2026-07-16 02:12:06.045'),
(1691,1,26097,0,'2026-07-16 02:12:06.045','2026-07-16 02:12:06.045'),
(1692,1,26098,0,'2026-07-16 02:12:06.045','2026-07-16 02:12:06.045'),
(1693,1,26099,0,'2026-07-16 02:12:06.045','2026-07-16 02:12:06.045'),
(1694,1,26100,0,'2026-07-16 02:12:06.045','2026-07-16 02:12:06.045'),
(1695,1,26101,0,'2026-07-16 02:12:06.046','2026-07-16 02:12:06.046'),
(1696,1,26102,0,'2026-07-16 02:12:06.046','2026-07-16 02:12:06.046'),
(1697,1,26103,0,'2026-07-16 02:12:06.046','2026-07-16 02:12:06.046'),
(1698,1,26104,0,'2026-07-16 02:12:06.046','2026-07-16 02:12:06.046'),
(1699,1,26105,0,'2026-07-16 02:12:06.046','2026-07-16 02:12:06.046'),
(1700,1,26106,0,'2026-07-16 02:12:06.046','2026-07-16 02:12:06.046'),
(1701,1,26107,0,'2026-07-16 02:12:06.046','2026-07-16 02:12:06.046'),
(1702,1,26108,0,'2026-07-16 02:12:06.047','2026-07-16 02:12:06.047'),
(1703,1,26109,0,'2026-07-16 02:12:06.047','2026-07-16 02:12:06.047'),
(1704,1,26110,0,'2026-07-16 02:12:06.047','2026-07-16 02:12:06.047'),
(1705,1,26111,0,'2026-07-16 02:12:06.047','2026-07-16 02:12:06.047'),
(1706,1,26112,0,'2026-07-16 02:12:06.047','2026-07-16 02:12:06.047'),
(1707,1,26113,0,'2026-07-16 02:12:06.048','2026-07-16 02:12:06.048'),
(1708,1,26114,0,'2026-07-16 02:12:06.048','2026-07-16 02:12:06.048'),
(1709,1,26115,0,'2026-07-16 02:12:06.048','2026-07-16 02:12:06.048'),
(1710,1,26116,0,'2026-07-16 02:12:06.048','2026-07-16 02:12:06.048'),
(1711,1,26117,0,'2026-07-16 02:12:06.048','2026-07-16 02:12:06.048'),
(1712,1,26118,0,'2026-07-16 02:12:06.049','2026-07-16 02:12:06.049'),
(1713,1,26119,0,'2026-07-16 02:12:06.049','2026-07-16 02:12:06.049'),
(1714,1,26120,0,'2026-07-16 02:12:06.049','2026-07-16 02:12:06.049'),
(1715,1,26121,0,'2026-07-16 02:12:06.049','2026-07-16 02:12:06.049'),
(1716,1,26122,0,'2026-07-16 02:12:06.049','2026-07-16 02:12:06.049'),
(1717,1,26123,0,'2026-07-16 02:12:06.049','2026-07-16 02:12:06.049'),
(1718,1,26124,0,'2026-07-16 02:12:06.049','2026-07-16 02:12:06.049'),
(1719,1,26125,0,'2026-07-16 02:12:06.050','2026-07-16 02:12:06.050'),
(1720,1,26126,0,'2026-07-16 02:12:06.050','2026-07-16 02:12:06.050'),
(1721,1,26127,0,'2026-07-16 02:12:06.050','2026-07-16 02:12:06.050'),
(1722,1,26128,0,'2026-07-16 02:12:06.050','2026-07-16 02:12:06.050'),
(1723,1,26129,0,'2026-07-16 02:12:06.050','2026-07-16 02:12:06.050'),
(1724,1,26130,0,'2026-07-16 02:12:06.050','2026-07-16 02:12:06.050'),
(1725,1,26131,0,'2026-07-16 02:12:06.051','2026-07-16 02:12:06.051'),
(1726,1,26132,0,'2026-07-16 02:12:06.051','2026-07-16 02:12:06.051'),
(1727,1,26133,0,'2026-07-16 02:12:06.051','2026-07-16 02:12:06.051'),
(1728,1,26134,0,'2026-07-16 02:12:06.051','2026-07-16 02:12:06.051'),
(1729,1,26135,0,'2026-07-16 02:12:06.051','2026-07-16 02:12:06.051'),
(1730,1,26136,0,'2026-07-16 02:12:06.052','2026-07-16 02:12:06.052'),
(1731,1,26137,0,'2026-07-16 02:12:06.052','2026-07-16 02:12:06.052'),
(1732,1,26138,0,'2026-07-16 02:12:06.052','2026-07-16 02:12:06.052'),
(1733,1,26139,0,'2026-07-16 02:12:06.052','2026-07-16 02:12:06.052'),
(1734,1,26140,0,'2026-07-16 02:12:06.052','2026-07-16 02:12:06.052'),
(1735,1,26141,0,'2026-07-16 02:12:06.053','2026-07-16 02:12:06.053'),
(1736,1,26142,0,'2026-07-16 02:12:06.053','2026-07-16 02:12:06.053'),
(1737,1,26143,0,'2026-07-16 02:12:06.053','2026-07-16 02:12:06.053'),
(1738,1,26144,0,'2026-07-16 02:12:06.053','2026-07-16 02:12:06.053'),
(1739,1,26145,0,'2026-07-16 02:12:06.053','2026-07-16 02:12:06.053'),
(1740,1,26146,0,'2026-07-16 02:12:06.053','2026-07-16 02:12:06.053'),
(1741,1,26147,0,'2026-07-16 02:12:06.054','2026-07-16 02:12:06.054'),
(1742,1,26148,0,'2026-07-16 02:12:06.054','2026-07-16 02:12:06.054'),
(1743,1,26149,0,'2026-07-16 02:12:06.054','2026-07-16 02:12:06.054'),
(1744,1,26150,0,'2026-07-16 02:12:06.054','2026-07-16 02:12:06.054'),
(1745,1,26151,0,'2026-07-16 02:12:06.054','2026-07-16 02:12:06.054'),
(1746,1,26152,0,'2026-07-16 02:12:06.054','2026-07-16 02:12:06.054'),
(1747,1,26153,0,'2026-07-16 02:12:06.054','2026-07-16 02:12:06.054'),
(1748,1,26154,0,'2026-07-16 02:12:06.055','2026-07-16 02:12:06.055'),
(1749,1,26155,0,'2026-07-16 02:12:06.055','2026-07-16 02:12:06.055'),
(1750,1,26156,0,'2026-07-16 02:12:06.055','2026-07-16 02:12:06.055'),
(1751,1,26157,0,'2026-07-16 02:12:06.055','2026-07-16 02:12:06.055'),
(1752,1,26158,0,'2026-07-16 02:12:06.056','2026-07-16 02:12:06.056'),
(1753,1,26159,0,'2026-07-16 02:12:06.056','2026-07-16 02:12:06.056'),
(1754,1,26160,0,'2026-07-16 02:12:06.056','2026-07-16 02:12:06.056'),
(1755,1,26161,0,'2026-07-16 02:12:06.056','2026-07-16 02:12:06.056'),
(1756,1,26162,0,'2026-07-16 02:12:06.056','2026-07-16 02:12:06.056'),
(1757,1,26163,0,'2026-07-16 02:12:06.056','2026-07-16 02:12:06.056'),
(1758,1,26164,0,'2026-07-16 02:12:06.056','2026-07-16 02:12:06.056'),
(1759,1,26165,0,'2026-07-16 02:12:06.057','2026-07-16 02:12:06.057'),
(1760,1,26166,0,'2026-07-16 02:12:06.057','2026-07-16 02:12:06.057'),
(1761,1,26167,0,'2026-07-16 02:12:06.057','2026-07-16 02:12:06.057'),
(1762,1,26168,0,'2026-07-16 02:12:06.057','2026-07-16 02:12:06.057'),
(1763,1,26169,0,'2026-07-16 02:12:06.057','2026-07-16 02:12:06.057'),
(1764,1,26170,0,'2026-07-16 02:12:06.057','2026-07-16 02:12:06.057'),
(1765,1,26171,0,'2026-07-16 02:12:06.058','2026-07-16 02:12:06.058'),
(1766,1,26172,0,'2026-07-16 02:12:06.058','2026-07-16 02:12:06.058'),
(1767,1,26173,0,'2026-07-16 02:12:06.058','2026-07-16 02:12:06.058'),
(1768,1,26174,0,'2026-07-16 02:12:06.058','2026-07-16 02:12:06.058'),
(1769,1,26175,0,'2026-07-16 02:12:06.058','2026-07-16 02:12:06.058'),
(1770,1,26176,0,'2026-07-16 02:12:06.058','2026-07-16 02:12:06.058'),
(1771,1,26177,0,'2026-07-16 02:12:06.059','2026-07-16 02:12:06.059'),
(1772,1,26178,0,'2026-07-16 02:12:06.059','2026-07-16 02:12:06.059'),
(1773,1,26179,0,'2026-07-16 02:12:06.059','2026-07-16 02:12:06.059'),
(1774,1,26180,0,'2026-07-16 02:12:06.059','2026-07-16 02:12:06.059'),
(1775,1,26181,0,'2026-07-16 02:12:06.059','2026-07-16 02:12:06.059'),
(1776,1,26182,0,'2026-07-16 02:12:06.060','2026-07-16 02:12:06.060'),
(1777,1,26183,0,'2026-07-16 02:12:06.060','2026-07-16 02:12:06.060'),
(1778,1,26184,0,'2026-07-16 02:12:06.060','2026-07-16 02:12:06.060'),
(1779,1,26185,0,'2026-07-16 02:12:06.060','2026-07-16 02:12:06.060'),
(1780,1,26186,0,'2026-07-16 02:12:06.060','2026-07-16 02:12:06.060'),
(1781,1,26187,0,'2026-07-16 02:12:06.060','2026-07-16 02:12:06.060'),
(1782,1,26188,0,'2026-07-16 02:12:06.060','2026-07-16 02:12:06.060'),
(1783,1,26189,0,'2026-07-16 02:12:06.061','2026-07-16 02:12:06.061'),
(1784,1,26190,0,'2026-07-16 02:12:06.061','2026-07-16 02:12:06.061'),
(1785,1,26191,0,'2026-07-16 02:12:06.061','2026-07-16 02:12:06.061'),
(1786,1,26192,0,'2026-07-16 02:12:06.061','2026-07-16 02:12:06.061'),
(1787,1,26193,0,'2026-07-16 02:12:06.061','2026-07-16 02:12:06.061'),
(1788,1,26194,0,'2026-07-16 02:12:06.061','2026-07-16 02:12:06.061'),
(1789,1,26195,0,'2026-07-16 02:12:06.062','2026-07-16 02:12:06.062'),
(1790,1,26196,0,'2026-07-16 02:12:06.062','2026-07-16 02:12:06.062'),
(1791,1,26197,0,'2026-07-16 02:12:06.062','2026-07-16 02:12:06.062'),
(1792,1,26198,0,'2026-07-16 02:12:06.062','2026-07-16 02:12:06.062'),
(1793,1,26199,0,'2026-07-16 02:12:06.062','2026-07-16 02:12:06.062'),
(1794,1,26200,0,'2026-07-16 02:12:06.062','2026-07-16 02:12:06.062'),
(1795,1,26201,0,'2026-07-16 02:12:06.063','2026-07-16 02:12:06.063'),
(1796,1,26202,0,'2026-07-16 02:12:06.063','2026-07-16 02:12:06.063'),
(1797,1,26203,0,'2026-07-16 02:12:06.063','2026-07-16 02:12:06.063'),
(1798,1,26204,0,'2026-07-16 02:12:06.063','2026-07-16 02:12:06.063'),
(1799,1,26205,0,'2026-07-16 02:12:06.063','2026-07-16 02:12:06.063'),
(1800,1,26206,0,'2026-07-16 02:12:06.064','2026-07-16 02:12:06.064'),
(1801,1,26207,0,'2026-07-16 02:12:06.064','2026-07-16 02:12:06.064'),
(1802,1,26208,0,'2026-07-16 02:12:06.064','2026-07-16 02:12:06.064'),
(1803,1,26209,0,'2026-07-16 02:12:06.064','2026-07-16 02:12:06.064'),
(1804,1,26210,0,'2026-07-16 02:12:06.064','2026-07-16 02:12:06.064'),
(1805,1,26211,0,'2026-07-16 02:12:06.064','2026-07-16 02:12:06.064'),
(1806,1,26212,0,'2026-07-16 02:12:06.065','2026-07-16 02:12:06.065'),
(1807,1,26213,0,'2026-07-16 02:12:06.065','2026-07-16 02:12:06.065'),
(1808,1,26214,0,'2026-07-16 02:12:06.065','2026-07-16 02:12:06.065'),
(1809,1,26215,0,'2026-07-16 02:12:06.065','2026-07-16 02:12:06.065'),
(1810,1,26216,0,'2026-07-16 02:12:06.065','2026-07-16 02:12:06.065'),
(1811,1,26217,0,'2026-07-16 02:12:06.065','2026-07-16 02:12:06.065'),
(1812,1,26218,0,'2026-07-16 02:12:06.065','2026-07-16 02:12:06.065'),
(1813,1,26219,0,'2026-07-16 02:12:06.066','2026-07-16 02:12:06.066'),
(1814,1,26220,0,'2026-07-16 02:12:06.066','2026-07-16 02:12:06.066'),
(1815,1,26221,0,'2026-07-16 02:12:06.066','2026-07-16 02:12:06.066'),
(1816,1,26222,0,'2026-07-16 02:12:06.066','2026-07-16 02:12:06.066'),
(1817,1,26223,0,'2026-07-16 02:12:06.066','2026-07-16 02:12:06.066'),
(1818,1,26224,0,'2026-07-16 02:12:06.067','2026-07-16 02:12:06.067'),
(1819,1,26225,0,'2026-07-16 02:12:06.067','2026-07-16 02:12:06.067'),
(1820,1,26226,0,'2026-07-16 02:12:06.067','2026-07-16 02:12:06.067'),
(1821,1,26227,0,'2026-07-16 02:12:06.067','2026-07-16 02:12:06.067'),
(1822,1,26228,0,'2026-07-16 02:12:06.067','2026-07-16 02:12:06.067'),
(1823,1,26229,0,'2026-07-16 02:12:06.067','2026-07-16 02:12:06.067'),
(1824,1,26230,0,'2026-07-16 02:12:06.068','2026-07-16 02:12:06.068'),
(1825,1,26231,0,'2026-07-16 02:12:06.068','2026-07-16 02:12:06.068'),
(1826,1,26232,0,'2026-07-16 02:12:06.068','2026-07-16 02:12:06.068'),
(1827,1,26233,0,'2026-07-16 02:12:06.068','2026-07-16 02:12:06.068'),
(1828,1,26234,0,'2026-07-16 02:12:06.068','2026-07-16 02:12:06.068'),
(1829,1,26235,0,'2026-07-16 02:12:06.069','2026-07-16 02:12:06.069'),
(1830,1,26236,0,'2026-07-16 02:12:06.069','2026-07-16 02:12:06.069'),
(1831,1,26237,0,'2026-07-16 02:12:06.069','2026-07-16 02:12:06.069'),
(1832,1,26238,0,'2026-07-16 02:12:06.069','2026-07-16 02:12:06.069'),
(1833,1,26239,0,'2026-07-16 02:12:06.069','2026-07-16 02:12:06.069'),
(1834,1,26240,0,'2026-07-16 02:12:06.069','2026-07-16 02:12:06.069'),
(1835,1,26241,0,'2026-07-16 02:12:06.070','2026-07-16 02:12:06.070'),
(1836,1,26242,0,'2026-07-16 02:12:06.070','2026-07-16 02:12:06.070'),
(1837,1,26243,0,'2026-07-16 02:12:06.070','2026-07-16 02:12:06.070'),
(1838,1,26244,0,'2026-07-16 02:12:06.070','2026-07-16 02:12:06.070'),
(1839,1,26245,0,'2026-07-16 02:12:06.070','2026-07-16 02:12:06.070'),
(1840,1,26246,0,'2026-07-16 02:12:06.071','2026-07-16 02:12:06.071'),
(1841,1,26247,0,'2026-07-16 02:12:06.071','2026-07-16 02:12:06.071'),
(1842,1,26248,0,'2026-07-16 02:12:06.071','2026-07-16 02:12:06.071'),
(1843,1,26249,0,'2026-07-16 02:12:06.071','2026-07-16 02:12:06.071'),
(1844,1,26250,0,'2026-07-16 02:12:06.071','2026-07-16 02:12:06.071'),
(1845,1,26251,0,'2026-07-16 02:12:06.071','2026-07-16 02:12:06.071'),
(1846,1,26252,0,'2026-07-16 02:12:06.071','2026-07-16 02:12:06.071'),
(1847,1,26253,0,'2026-07-16 02:12:06.072','2026-07-16 02:12:06.072'),
(1848,1,26254,0,'2026-07-16 02:12:06.072','2026-07-16 02:12:06.072'),
(1849,1,26255,0,'2026-07-16 02:12:06.072','2026-07-16 02:12:06.072'),
(1850,1000,26000,0,'2026-07-16 02:12:06.072','2026-07-16 02:12:06.072'),
(1851,1000,26001,0,'2026-07-16 02:12:06.072','2026-07-16 02:12:06.072'),
(1852,1000,26002,0,'2026-07-16 02:12:06.073','2026-07-16 02:12:06.073'),
(1853,1000,26003,0,'2026-07-16 02:12:06.073','2026-07-16 02:12:06.073'),
(1854,1000,26004,0,'2026-07-16 02:12:06.073','2026-07-16 02:12:06.073'),
(1855,1000,26005,0,'2026-07-16 02:12:06.073','2026-07-16 02:12:06.073'),
(1856,1000,26006,0,'2026-07-16 02:12:06.073','2026-07-16 02:12:06.073'),
(1857,1000,26007,0,'2026-07-16 02:12:06.073','2026-07-16 02:12:06.073'),
(1858,1000,26008,0,'2026-07-16 02:12:06.074','2026-07-16 02:12:06.074'),
(1859,1000,26009,0,'2026-07-16 02:12:06.074','2026-07-16 02:12:06.074'),
(1860,1000,26010,0,'2026-07-16 02:12:06.074','2026-07-16 02:12:06.074'),
(1861,1000,26011,0,'2026-07-16 02:12:06.074','2026-07-16 02:12:06.074'),
(1862,1000,26012,0,'2026-07-16 02:12:06.074','2026-07-16 02:12:06.074'),
(1863,1000,26013,0,'2026-07-16 02:12:06.075','2026-07-16 02:12:06.075'),
(1864,1000,26014,0,'2026-07-16 02:12:06.075','2026-07-16 02:12:06.075'),
(1865,1000,26015,0,'2026-07-16 02:12:06.075','2026-07-16 02:12:06.075'),
(1866,1000,26016,0,'2026-07-16 02:12:06.075','2026-07-16 02:12:06.075'),
(1867,1000,26017,0,'2026-07-16 02:12:06.075','2026-07-16 02:12:06.075'),
(1868,1000,26018,0,'2026-07-16 02:12:06.075','2026-07-16 02:12:06.075'),
(1869,1000,26019,0,'2026-07-16 02:12:06.076','2026-07-16 02:12:06.076'),
(1870,1000,26020,0,'2026-07-16 02:12:06.076','2026-07-16 02:12:06.076'),
(1871,1000,26021,0,'2026-07-16 02:12:06.076','2026-07-16 02:12:06.076'),
(1872,1000,26022,0,'2026-07-16 02:12:06.076','2026-07-16 02:12:06.076'),
(1873,1000,26023,0,'2026-07-16 02:12:06.076','2026-07-16 02:12:06.076'),
(1874,1000,26024,0,'2026-07-16 02:12:06.076','2026-07-16 02:12:06.076'),
(1875,1000,26025,0,'2026-07-16 02:12:06.076','2026-07-16 02:12:06.076'),
(1876,1000,26026,0,'2026-07-16 02:12:06.077','2026-07-16 02:12:06.077'),
(1877,1000,26027,0,'2026-07-16 02:12:06.077','2026-07-16 02:12:06.077'),
(1878,1000,26028,0,'2026-07-16 02:12:06.077','2026-07-16 02:12:06.077'),
(1879,1000,26029,0,'2026-07-16 02:12:06.077','2026-07-16 02:12:06.077'),
(1880,1000,26030,0,'2026-07-16 02:12:06.077','2026-07-16 02:12:06.077'),
(1881,1000,26031,0,'2026-07-16 02:12:06.077','2026-07-16 02:12:06.077'),
(1882,1000,26032,0,'2026-07-16 02:12:06.078','2026-07-16 02:12:06.078'),
(1883,1000,26033,0,'2026-07-16 02:12:06.078','2026-07-16 02:12:06.078'),
(1884,1000,26034,0,'2026-07-16 02:12:06.078','2026-07-16 02:12:06.078'),
(1885,1000,26035,0,'2026-07-16 02:12:06.078','2026-07-16 02:12:06.078'),
(1886,1000,26036,0,'2026-07-16 02:12:06.079','2026-07-16 02:12:06.079'),
(1887,1000,26037,0,'2026-07-16 02:12:06.079','2026-07-16 02:12:06.079'),
(1888,1000,26038,0,'2026-07-16 02:12:06.079','2026-07-16 02:12:06.079'),
(1889,1000,26039,0,'2026-07-16 02:12:06.079','2026-07-16 02:12:06.079'),
(1890,1000,26040,0,'2026-07-16 02:12:06.079','2026-07-16 02:12:06.079'),
(1891,1000,26041,0,'2026-07-16 02:12:06.079','2026-07-16 02:12:06.079'),
(1892,1000,26042,0,'2026-07-16 02:12:06.079','2026-07-16 02:12:06.079'),
(1893,1000,26043,0,'2026-07-16 02:12:06.080','2026-07-16 02:12:06.080'),
(1894,1000,26044,0,'2026-07-16 02:12:06.080','2026-07-16 02:12:06.080'),
(1895,1000,26045,0,'2026-07-16 02:12:06.080','2026-07-16 02:12:06.080'),
(1896,1000,26046,0,'2026-07-16 02:12:06.080','2026-07-16 02:12:06.080'),
(1897,1000,26047,0,'2026-07-16 02:12:06.080','2026-07-16 02:12:06.080'),
(1898,1000,26048,0,'2026-07-16 02:12:06.080','2026-07-16 02:12:06.080'),
(1899,1000,26049,0,'2026-07-16 02:12:06.080','2026-07-16 02:12:06.080'),
(1900,1000,26050,0,'2026-07-16 02:12:06.081','2026-07-16 02:12:06.081'),
(1901,1000,26051,0,'2026-07-16 02:12:06.081','2026-07-16 02:12:06.081'),
(1902,1000,26052,0,'2026-07-16 02:12:06.081','2026-07-16 02:12:06.081'),
(1903,1000,26053,0,'2026-07-16 02:12:06.081','2026-07-16 02:12:06.081'),
(1904,1000,26054,0,'2026-07-16 02:12:06.082','2026-07-16 02:12:06.082'),
(1905,1000,26055,0,'2026-07-16 02:12:06.082','2026-07-16 02:12:06.082'),
(1906,1000,26056,0,'2026-07-16 02:12:06.082','2026-07-16 02:12:06.082'),
(1907,1000,26057,0,'2026-07-16 02:12:06.082','2026-07-16 02:12:06.082'),
(1908,1000,26058,0,'2026-07-16 02:12:06.083','2026-07-16 02:12:06.083'),
(1909,1000,26059,0,'2026-07-16 02:12:06.083','2026-07-16 02:12:06.083'),
(1910,1000,26060,0,'2026-07-16 02:12:06.083','2026-07-16 02:12:06.083'),
(1911,1000,26061,0,'2026-07-16 02:12:06.083','2026-07-16 02:12:06.083'),
(1912,1000,26062,0,'2026-07-16 02:12:06.083','2026-07-16 02:12:06.083'),
(1913,1000,26063,0,'2026-07-16 02:12:06.083','2026-07-16 02:12:06.083'),
(1914,1000,26064,0,'2026-07-16 02:12:06.084','2026-07-16 02:12:06.084'),
(1915,1000,26065,0,'2026-07-16 02:12:06.084','2026-07-16 02:12:06.084'),
(1916,1000,26066,0,'2026-07-16 02:12:06.084','2026-07-16 02:12:06.084'),
(1917,1000,26067,0,'2026-07-16 02:12:06.084','2026-07-16 02:12:06.084'),
(1918,1000,26068,0,'2026-07-16 02:12:06.084','2026-07-16 02:12:06.084'),
(1919,1000,26069,0,'2026-07-16 02:12:06.084','2026-07-16 02:12:06.084'),
(1920,1000,26070,0,'2026-07-16 02:12:06.084','2026-07-16 02:12:06.084'),
(1921,1000,26071,0,'2026-07-16 02:12:06.085','2026-07-16 02:12:06.085'),
(1922,1000,26072,0,'2026-07-16 02:12:06.085','2026-07-16 02:12:06.085'),
(1923,1000,26073,0,'2026-07-16 02:12:06.085','2026-07-16 02:12:06.085'),
(1924,1000,26074,0,'2026-07-16 02:12:06.085','2026-07-16 02:12:06.085'),
(1925,1000,26075,0,'2026-07-16 02:12:06.086','2026-07-16 02:12:06.086'),
(1926,1000,26076,0,'2026-07-16 02:12:06.086','2026-07-16 02:12:06.086'),
(1927,1000,26077,0,'2026-07-16 02:12:06.086','2026-07-16 02:12:06.086'),
(1928,1000,26078,0,'2026-07-16 02:12:06.086','2026-07-16 02:12:06.086'),
(1929,1000,26079,0,'2026-07-16 02:12:06.087','2026-07-16 02:12:06.087'),
(1930,1000,26080,0,'2026-07-16 02:12:06.087','2026-07-16 02:12:06.087'),
(1931,1000,26081,0,'2026-07-16 02:12:06.087','2026-07-16 02:12:06.087'),
(1932,1000,26082,0,'2026-07-16 02:12:06.087','2026-07-16 02:12:06.087'),
(1933,1000,26083,0,'2026-07-16 02:12:06.087','2026-07-16 02:12:06.087'),
(1934,1000,26084,0,'2026-07-16 02:12:06.088','2026-07-16 02:12:06.088'),
(1935,1000,26085,0,'2026-07-16 02:12:06.088','2026-07-16 02:12:06.088'),
(1936,1000,26086,0,'2026-07-16 02:12:06.088','2026-07-16 02:12:06.088'),
(1937,1000,26087,0,'2026-07-16 02:12:06.088','2026-07-16 02:12:06.088'),
(1938,1000,26088,0,'2026-07-16 02:12:06.088','2026-07-16 02:12:06.088'),
(1939,1000,26089,0,'2026-07-16 02:12:06.088','2026-07-16 02:12:06.088'),
(1940,1000,26090,0,'2026-07-16 02:12:06.090','2026-07-16 02:12:06.090'),
(1941,1000,26091,0,'2026-07-16 02:12:06.090','2026-07-16 02:12:06.090'),
(1942,1000,26092,0,'2026-07-16 02:12:06.090','2026-07-16 02:12:06.090'),
(1943,1000,26093,0,'2026-07-16 02:12:06.091','2026-07-16 02:12:06.091'),
(1944,1000,26094,0,'2026-07-16 02:12:06.091','2026-07-16 02:12:06.091'),
(1945,1000,26095,0,'2026-07-16 02:12:06.091','2026-07-16 02:12:06.091'),
(1946,1000,26096,0,'2026-07-16 02:12:06.091','2026-07-16 02:12:06.091'),
(1947,1000,26097,0,'2026-07-16 02:12:06.091','2026-07-16 02:12:06.091'),
(1948,1000,26098,0,'2026-07-16 02:12:06.091','2026-07-16 02:12:06.091'),
(1949,1000,26099,0,'2026-07-16 02:12:06.092','2026-07-16 02:12:06.092'),
(1950,1000,26100,0,'2026-07-16 02:12:06.092','2026-07-16 02:12:06.092'),
(1951,1000,26101,0,'2026-07-16 02:12:06.092','2026-07-16 02:12:06.092'),
(1952,1000,26102,0,'2026-07-16 02:12:06.092','2026-07-16 02:12:06.092'),
(1953,1000,26103,0,'2026-07-16 02:12:06.093','2026-07-16 02:12:06.093'),
(1954,1000,26104,0,'2026-07-16 02:12:06.093','2026-07-16 02:12:06.093'),
(1955,1000,26105,0,'2026-07-16 02:12:06.093','2026-07-16 02:12:06.093'),
(1956,1000,26106,0,'2026-07-16 02:12:06.093','2026-07-16 02:12:06.093'),
(1957,1000,26107,0,'2026-07-16 02:12:06.093','2026-07-16 02:12:06.093'),
(1958,1000,26108,0,'2026-07-16 02:12:06.093','2026-07-16 02:12:06.093'),
(1959,1000,26109,0,'2026-07-16 02:12:06.093','2026-07-16 02:12:06.093'),
(1960,1000,26110,0,'2026-07-16 02:12:06.094','2026-07-16 02:12:06.094'),
(1961,1000,26111,0,'2026-07-16 02:12:06.094','2026-07-16 02:12:06.094'),
(1962,1000,26112,0,'2026-07-16 02:12:06.094','2026-07-16 02:12:06.094'),
(1963,1000,26113,0,'2026-07-16 02:12:06.094','2026-07-16 02:12:06.094'),
(1964,1000,26114,0,'2026-07-16 02:12:06.094','2026-07-16 02:12:06.094'),
(1965,1000,26115,0,'2026-07-16 02:12:06.094','2026-07-16 02:12:06.094'),
(1966,1000,26116,0,'2026-07-16 02:12:06.094','2026-07-16 02:12:06.094'),
(1967,1000,26117,0,'2026-07-16 02:12:06.095','2026-07-16 02:12:06.095'),
(1968,1000,26118,0,'2026-07-16 02:12:06.095','2026-07-16 02:12:06.095'),
(1969,1000,26119,0,'2026-07-16 02:12:06.095','2026-07-16 02:12:06.095'),
(1970,1000,26120,0,'2026-07-16 02:12:06.095','2026-07-16 02:12:06.095'),
(1971,1000,26121,0,'2026-07-16 02:12:06.095','2026-07-16 02:12:06.095'),
(1972,1000,26122,0,'2026-07-16 02:12:06.095','2026-07-16 02:12:06.095'),
(1973,1000,26123,0,'2026-07-16 02:12:06.096','2026-07-16 02:12:06.096'),
(1974,1000,26124,0,'2026-07-16 02:12:06.096','2026-07-16 02:12:06.096'),
(1975,1000,26125,0,'2026-07-16 02:12:06.096','2026-07-16 02:12:06.096'),
(1976,1000,26126,0,'2026-07-16 02:12:06.096','2026-07-16 02:12:06.096'),
(1977,1000,26127,0,'2026-07-16 02:12:06.097','2026-07-16 02:12:06.097'),
(1978,1000,26128,0,'2026-07-16 02:12:06.097','2026-07-16 02:12:06.097'),
(1979,1000,26129,0,'2026-07-16 02:12:06.097','2026-07-16 02:12:06.097'),
(1980,1000,26130,0,'2026-07-16 02:12:06.097','2026-07-16 02:12:06.097'),
(1981,1000,26131,0,'2026-07-16 02:12:06.097','2026-07-16 02:12:06.097'),
(1982,1000,26132,0,'2026-07-16 02:12:06.097','2026-07-16 02:12:06.097'),
(1983,1000,26133,0,'2026-07-16 02:12:06.098','2026-07-16 02:12:06.098'),
(1984,1000,26134,0,'2026-07-16 02:12:06.098','2026-07-16 02:12:06.098'),
(1985,1000,26135,0,'2026-07-16 02:12:06.098','2026-07-16 02:12:06.098'),
(1986,1000,26136,0,'2026-07-16 02:12:06.098','2026-07-16 02:12:06.098'),
(1987,1000,26137,0,'2026-07-16 02:12:06.098','2026-07-16 02:12:06.098'),
(1988,1000,26138,0,'2026-07-16 02:12:06.098','2026-07-16 02:12:06.098'),
(1989,1000,26139,0,'2026-07-16 02:12:06.098','2026-07-16 02:12:06.098'),
(1990,1000,26140,0,'2026-07-16 02:12:06.099','2026-07-16 02:12:06.099'),
(1991,1000,26141,0,'2026-07-16 02:12:06.099','2026-07-16 02:12:06.099'),
(1992,1000,26142,0,'2026-07-16 02:12:06.099','2026-07-16 02:12:06.099'),
(1993,1000,26143,0,'2026-07-16 02:12:06.099','2026-07-16 02:12:06.099'),
(1994,1000,26144,0,'2026-07-16 02:12:06.099','2026-07-16 02:12:06.099'),
(1995,1000,26145,0,'2026-07-16 02:12:06.100','2026-07-16 02:12:06.100'),
(1996,1000,26146,0,'2026-07-16 02:12:06.100','2026-07-16 02:12:06.100'),
(1997,1000,26147,0,'2026-07-16 02:12:06.100','2026-07-16 02:12:06.100'),
(1998,1000,26148,0,'2026-07-16 02:12:06.100','2026-07-16 02:12:06.100'),
(1999,1000,26149,0,'2026-07-16 02:12:06.100','2026-07-16 02:12:06.100'),
(2000,1000,26150,0,'2026-07-16 02:12:06.100','2026-07-16 02:12:06.100'),
(2001,1000,26151,0,'2026-07-16 02:12:06.101','2026-07-16 02:12:06.101'),
(2002,1000,26152,0,'2026-07-16 02:12:06.101','2026-07-16 02:12:06.101'),
(2003,1000,26153,0,'2026-07-16 02:12:06.101','2026-07-16 02:12:06.101'),
(2004,1000,26154,0,'2026-07-16 02:12:06.101','2026-07-16 02:12:06.101'),
(2005,1000,26155,0,'2026-07-16 02:12:06.101','2026-07-16 02:12:06.101'),
(2006,1000,26156,0,'2026-07-16 02:12:06.102','2026-07-16 02:12:06.102'),
(2007,1000,26157,0,'2026-07-16 02:12:06.102','2026-07-16 02:12:06.102'),
(2008,1000,26158,0,'2026-07-16 02:12:06.102','2026-07-16 02:12:06.102'),
(2009,1000,26159,0,'2026-07-16 02:12:06.102','2026-07-16 02:12:06.102'),
(2010,1000,26160,0,'2026-07-16 02:12:06.102','2026-07-16 02:12:06.102'),
(2011,1000,26161,0,'2026-07-16 02:12:06.102','2026-07-16 02:12:06.102'),
(2012,1000,26162,0,'2026-07-16 02:12:06.103','2026-07-16 02:12:06.103'),
(2013,1000,26163,0,'2026-07-16 02:12:06.103','2026-07-16 02:12:06.103'),
(2014,1000,26164,0,'2026-07-16 02:12:06.103','2026-07-16 02:12:06.103'),
(2015,1000,26165,0,'2026-07-16 02:12:06.103','2026-07-16 02:12:06.103'),
(2016,1000,26166,0,'2026-07-16 02:12:06.103','2026-07-16 02:12:06.103'),
(2017,1000,26167,0,'2026-07-16 02:12:06.103','2026-07-16 02:12:06.103'),
(2018,1000,26168,0,'2026-07-16 02:12:06.104','2026-07-16 02:12:06.104'),
(2019,1000,26169,0,'2026-07-16 02:12:06.104','2026-07-16 02:12:06.104'),
(2020,1000,26170,0,'2026-07-16 02:12:06.104','2026-07-16 02:12:06.104'),
(2021,1000,26171,0,'2026-07-16 02:12:06.104','2026-07-16 02:12:06.104'),
(2022,1000,26172,0,'2026-07-16 02:12:06.104','2026-07-16 02:12:06.104'),
(2023,1000,26173,0,'2026-07-16 02:12:06.105','2026-07-16 02:12:06.105'),
(2024,1000,26174,0,'2026-07-16 02:12:06.105','2026-07-16 02:12:06.105'),
(2025,1000,26175,0,'2026-07-16 02:12:06.105','2026-07-16 02:12:06.105'),
(2026,1000,26176,0,'2026-07-16 02:12:06.105','2026-07-16 02:12:06.105'),
(2027,1000,26177,0,'2026-07-16 02:12:06.105','2026-07-16 02:12:06.105'),
(2028,1000,26178,0,'2026-07-16 02:12:06.105','2026-07-16 02:12:06.105'),
(2029,1000,26179,0,'2026-07-16 02:12:06.106','2026-07-16 02:12:06.106'),
(2030,1000,26180,0,'2026-07-16 02:12:06.106','2026-07-16 02:12:06.106'),
(2031,1000,26181,0,'2026-07-16 02:12:06.106','2026-07-16 02:12:06.106'),
(2032,1000,26182,0,'2026-07-16 02:12:06.106','2026-07-16 02:12:06.106'),
(2033,1000,26183,0,'2026-07-16 02:12:06.106','2026-07-16 02:12:06.106'),
(2034,1000,26184,0,'2026-07-16 02:12:06.106','2026-07-16 02:12:06.106'),
(2035,1000,26185,0,'2026-07-16 02:12:06.106','2026-07-16 02:12:06.106'),
(2036,1000,26186,0,'2026-07-16 02:12:06.107','2026-07-16 02:12:06.107'),
(2037,1000,26187,0,'2026-07-16 02:12:06.107','2026-07-16 02:12:06.107'),
(2038,1000,26188,0,'2026-07-16 02:12:06.107','2026-07-16 02:12:06.107'),
(2039,1000,26189,0,'2026-07-16 02:12:06.107','2026-07-16 02:12:06.107'),
(2040,1000,26190,0,'2026-07-16 02:12:06.108','2026-07-16 02:12:06.108'),
(2041,1000,26191,0,'2026-07-16 02:12:06.108','2026-07-16 02:12:06.108'),
(2042,1000,26192,0,'2026-07-16 02:12:06.108','2026-07-16 02:12:06.108'),
(2043,1000,26193,0,'2026-07-16 02:12:06.108','2026-07-16 02:12:06.108'),
(2044,1000,26194,0,'2026-07-16 02:12:06.108','2026-07-16 02:12:06.108'),
(2045,1000,26195,0,'2026-07-16 02:12:06.109','2026-07-16 02:12:06.109'),
(2046,1000,26196,0,'2026-07-16 02:12:06.109','2026-07-16 02:12:06.109'),
(2047,1000,26197,0,'2026-07-16 02:12:06.109','2026-07-16 02:12:06.109'),
(2048,1000,26198,0,'2026-07-16 02:12:06.109','2026-07-16 02:12:06.109'),
(2049,1000,26199,0,'2026-07-16 02:12:06.109','2026-07-16 02:12:06.109'),
(2050,1000,26200,0,'2026-07-16 02:12:06.109','2026-07-16 02:12:06.109'),
(2051,1000,26201,0,'2026-07-16 02:12:06.109','2026-07-16 02:12:06.109'),
(2052,1000,26202,0,'2026-07-16 02:12:06.110','2026-07-16 02:12:06.110'),
(2053,1000,26203,0,'2026-07-16 02:12:06.110','2026-07-16 02:12:06.110'),
(2054,1000,26204,0,'2026-07-16 02:12:06.110','2026-07-16 02:12:06.110'),
(2055,1000,26205,0,'2026-07-16 02:12:06.110','2026-07-16 02:12:06.110'),
(2056,1000,26206,0,'2026-07-16 02:12:06.110','2026-07-16 02:12:06.110'),
(2057,1000,26207,0,'2026-07-16 02:12:06.110','2026-07-16 02:12:06.110'),
(2058,1000,26208,0,'2026-07-16 02:12:06.111','2026-07-16 02:12:06.111'),
(2059,1000,26209,0,'2026-07-16 02:12:06.111','2026-07-16 02:12:06.111'),
(2060,1000,26210,0,'2026-07-16 02:12:06.111','2026-07-16 02:12:06.111'),
(2061,1000,26211,0,'2026-07-16 02:12:06.111','2026-07-16 02:12:06.111'),
(2062,1000,26212,0,'2026-07-16 02:12:06.112','2026-07-16 02:12:06.112'),
(2063,1000,26213,0,'2026-07-16 02:12:06.112','2026-07-16 02:12:06.112'),
(2064,1000,26214,0,'2026-07-16 02:12:06.112','2026-07-16 02:12:06.112'),
(2065,1000,26215,0,'2026-07-16 02:12:06.112','2026-07-16 02:12:06.112'),
(2066,1000,26216,0,'2026-07-16 02:12:06.112','2026-07-16 02:12:06.112'),
(2067,1000,26217,0,'2026-07-16 02:12:06.112','2026-07-16 02:12:06.112'),
(2068,1000,26218,0,'2026-07-16 02:12:06.113','2026-07-16 02:12:06.113'),
(2069,1000,26219,0,'2026-07-16 02:12:06.113','2026-07-16 02:12:06.113'),
(2070,1000,26220,0,'2026-07-16 02:12:06.113','2026-07-16 02:12:06.113'),
(2071,1000,26221,0,'2026-07-16 02:12:06.113','2026-07-16 02:12:06.113'),
(2072,1000,26222,0,'2026-07-16 02:12:06.113','2026-07-16 02:12:06.113'),
(2073,1000,26223,0,'2026-07-16 02:12:06.113','2026-07-16 02:12:06.113'),
(2074,1000,26224,0,'2026-07-16 02:12:06.114','2026-07-16 02:12:06.114'),
(2075,1000,26225,0,'2026-07-16 02:12:06.114','2026-07-16 02:12:06.114'),
(2076,1000,26226,0,'2026-07-16 02:12:06.114','2026-07-16 02:12:06.114'),
(2077,1000,26227,0,'2026-07-16 02:12:06.114','2026-07-16 02:12:06.114'),
(2078,1000,26228,0,'2026-07-16 02:12:06.114','2026-07-16 02:12:06.114'),
(2079,1000,26229,0,'2026-07-16 02:12:06.114','2026-07-16 02:12:06.114'),
(2080,1000,26230,0,'2026-07-16 02:12:06.114','2026-07-16 02:12:06.114'),
(2081,1000,26231,0,'2026-07-16 02:12:06.115','2026-07-16 02:12:06.115'),
(2082,1000,26232,0,'2026-07-16 02:12:06.115','2026-07-16 02:12:06.115'),
(2083,1000,26233,0,'2026-07-16 02:12:06.115','2026-07-16 02:12:06.115'),
(2084,1000,26234,0,'2026-07-16 02:12:06.115','2026-07-16 02:12:06.115'),
(2085,1000,26235,0,'2026-07-16 02:12:06.116','2026-07-16 02:12:06.116'),
(2086,1000,26236,0,'2026-07-16 02:12:06.116','2026-07-16 02:12:06.116'),
(2087,1000,26237,0,'2026-07-16 02:12:06.116','2026-07-16 02:12:06.116'),
(2088,1000,26238,0,'2026-07-16 02:12:06.116','2026-07-16 02:12:06.116'),
(2089,1000,26239,0,'2026-07-16 02:12:06.116','2026-07-16 02:12:06.116'),
(2090,1000,26240,0,'2026-07-16 02:12:06.116','2026-07-16 02:12:06.116'),
(2091,1000,26241,0,'2026-07-16 02:12:06.116','2026-07-16 02:12:06.116'),
(2092,1000,26242,0,'2026-07-16 02:12:06.117','2026-07-16 02:12:06.117'),
(2093,1000,26243,0,'2026-07-16 02:12:06.117','2026-07-16 02:12:06.117'),
(2094,1000,26244,0,'2026-07-16 02:12:06.117','2026-07-16 02:12:06.117'),
(2095,1000,26245,0,'2026-07-16 02:12:06.117','2026-07-16 02:12:06.117'),
(2096,1000,26246,0,'2026-07-16 02:12:06.117','2026-07-16 02:12:06.117'),
(2097,1000,26247,0,'2026-07-16 02:12:06.117','2026-07-16 02:12:06.117'),
(2098,1000,26248,0,'2026-07-16 02:12:06.117','2026-07-16 02:12:06.117'),
(2099,1000,26249,0,'2026-07-16 02:12:06.118','2026-07-16 02:12:06.118'),
(2100,1000,26250,0,'2026-07-16 02:12:06.118','2026-07-16 02:12:06.118'),
(2101,1000,26251,0,'2026-07-16 02:12:06.118','2026-07-16 02:12:06.118'),
(2102,1000,26252,0,'2026-07-16 02:12:06.118','2026-07-16 02:12:06.118'),
(2103,1000,26253,0,'2026-07-16 02:12:06.118','2026-07-16 02:12:06.118'),
(2104,1000,26254,0,'2026-07-16 02:12:06.118','2026-07-16 02:12:06.118'),
(2105,1000,26255,0,'2026-07-16 02:12:06.119','2026-07-16 02:12:06.119'),
(2106,1,26256,0,'2026-07-16 02:12:06.463','2026-07-16 02:12:06.463'),
(2107,1,26257,0,'2026-07-16 02:12:06.463','2026-07-16 02:12:06.463'),
(2108,1,26258,0,'2026-07-16 02:12:06.463','2026-07-16 02:12:06.463'),
(2109,1,26259,0,'2026-07-16 02:12:06.463','2026-07-16 02:12:06.463'),
(2110,1,26260,0,'2026-07-16 02:12:06.463','2026-07-16 02:12:06.463'),
(2111,1,26261,0,'2026-07-16 02:12:06.463','2026-07-16 02:12:06.463'),
(2112,1,26262,0,'2026-07-16 02:12:06.463','2026-07-16 02:12:06.463'),
(2113,1,26263,0,'2026-07-16 02:12:06.463','2026-07-16 02:12:06.463'),
(2114,1,26264,0,'2026-07-16 02:12:06.463','2026-07-16 02:12:06.463');
/*!40000 ALTER TABLE `sys_ra` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_role`
--

DROP TABLE IF EXISTS `sys_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role` (
  `role_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '角色id',
  `role_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '角色名称',
  `is_editable` tinyint(4) NOT NULL COMMENT '是否可编辑',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`role_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1001 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_role`
--

LOCK TABLES `sys_role` WRITE;
/*!40000 ALTER TABLE `sys_role` DISABLE KEYS */;
INSERT INTO `sys_role` VALUES
(1,'超级管理员',0,0,'2022-03-25 17:08:52.100','2022-03-25 17:43:29.970'),
(1000,'业务权限',1,0,'2022-04-27 17:50:02.139','2022-04-27 17:50:02.139');
/*!40000 ALTER TABLE `sys_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_schedule_log`
--

DROP TABLE IF EXISTS `sys_schedule_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_schedule_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(255) DEFAULT NULL,
  `job_group` varchar(128) DEFAULT NULL,
  `trigger_type` varchar(64) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `duration_ms` bigint(20) DEFAULT NULL,
  `status` int(11) DEFAULT 0,
  `result_message` text DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `error_msg` varchar(1024) DEFAULT NULL,
  `execute_server` varchar(255) DEFAULT NULL,
  `execution_time` bigint(20) DEFAULT NULL,
  `log_code` varchar(255) DEFAULT NULL,
  `retry_count` int(11) DEFAULT NULL,
  `schedule_cron` varchar(255) DEFAULT NULL,
  `schedule_name` varchar(255) DEFAULT NULL,
  `schedule_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_schedule_log`
--

LOCK TABLES `sys_schedule_log` WRITE;
/*!40000 ALTER TABLE `sys_schedule_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_schedule_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_schedule_log_definition`
--

DROP TABLE IF EXISTS `sys_schedule_log_definition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_schedule_log_definition` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `log_code` varchar(64) DEFAULT NULL,
  `log_name` varchar(255) DEFAULT NULL,
  `job_name` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `cron_expression` varchar(128) DEFAULT NULL,
  `is_enabled` tinyint(1) DEFAULT 1,
  `retention_days` int(11) DEFAULT 30,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `update_date` datetime DEFAULT NULL,
  `schedule_type` varchar(64) DEFAULT NULL COMMENT '调度类型',
  `module_name` varchar(128) DEFAULT NULL COMMENT '模块名',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_schedule_log_definition`
--

LOCK TABLES `sys_schedule_log_definition` WRITE;
/*!40000 ALTER TABLE `sys_schedule_log_definition` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_schedule_log_definition` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_ur`
--

DROP TABLE IF EXISTS `sys_ur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_ur` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `user_id` bigint(20) NOT NULL COMMENT '用户id',
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `is_del` bigint(20) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户角色关系表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_ur`
--

LOCK TABLES `sys_ur` WRITE;
/*!40000 ALTER TABLE `sys_ur` DISABLE KEYS */;
INSERT INTO `sys_ur` VALUES
(1,1,1,0,'2022-03-25 17:55:53.090','2022-03-25 18:03:28.371');
/*!40000 ALTER TABLE `sys_ur` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_user`
--

DROP TABLE IF EXISTS `sys_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user` (
  `user_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '用户id',
  `user_account` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '账户名称',
  `user_password` varchar(128) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '账户密码',
  `user_name` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '用户昵称',
  `role_id_list` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '角色id集合',
  `is_forbid` tinyint(4) NOT NULL COMMENT '是否禁用',
  `is_editable` tinyint(4) NOT NULL COMMENT '是否可编辑',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更改时间',
  `auth_uuid` varchar(255) DEFAULT NULL COMMENT '第三方uuid',
  `ip` varchar(255) DEFAULT NULL COMMENT '第三方uuid',
  `register_type` tinyint(4) NOT NULL COMMENT '注册类型1：管理员创建 2：邮箱 3：手机',
  `first_login` tinyint(1) DEFAULT 1 COMMENT '是否首次登录(0=否 1=是)',
  PRIMARY KEY (`user_id`) USING BTREE,
  UNIQUE KEY `ix_unique_user_account` (`user_account`) USING BTREE COMMENT '账户名称唯一索引',
  KEY `ix_index_auth_uuid` (`auth_uuid`)
) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user`
--

LOCK TABLES `sys_user` WRITE;
/*!40000 ALTER TABLE `sys_user` DISABLE KEYS */;
INSERT INTO `sys_user` VALUES
(1,'admin','a0f34ffac5a82245e4fca2e21f358a42','admin','1',0,1,0,'2022-03-25 17:55:53.048','2022-07-18 17:13:02.377','','',1,1);
/*!40000 ALTER TABLE `sys_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_user_whitelist`
--

DROP TABLE IF EXISTS `sys_user_whitelist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_whitelist` (
  `whitelist_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `whitelist_type` tinyint(4) NOT NULL COMMENT '白名单类型：1=邮箱，2=手机号',
  `whitelist_value` varchar(100) NOT NULL COMMENT '白名单值（邮箱地址或手机号）',
  `whitelist_desc` varchar(255) DEFAULT NULL COMMENT '备注说明',
  `status` tinyint(4) NOT NULL DEFAULT 1 COMMENT '状态：0=禁用，1=启用',
  `is_del` tinyint(4) NOT NULL DEFAULT 0 COMMENT '是否删除：0=否，1=是',
  `creator_id` bigint(20) DEFAULT NULL COMMENT '创建人ID',
  `creator_name` varchar(64) DEFAULT NULL COMMENT '创建人姓名',
  `c_time` timestamp NULL DEFAULT current_timestamp() COMMENT '创建时间',
  `u_time` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`whitelist_id`),
  UNIQUE KEY `uk_type_value` (`whitelist_type`,`whitelist_value`,`is_del`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_user_whitelist`
--

LOCK TABLES `sys_user_whitelist` WRITE;
/*!40000 ALTER TABLE `sys_user_whitelist` DISABLE KEYS */;
/*!40000 ALTER TABLE `sys_user_whitelist` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tenant`
--

DROP TABLE IF EXISTS `tenant`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenant` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_code` varchar(64) DEFAULT NULL,
  `tenant_name` varchar(255) DEFAULT NULL,
  `contact_person` varchar(128) DEFAULT NULL,
  `contact_phone` varchar(64) DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `data_isolation` int(11) DEFAULT 0,
  `compute_isolation` int(11) DEFAULT 0,
  `resource_count` bigint(20) DEFAULT 0,
  `is_del` tinyint(1) DEFAULT 0,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tenant`
--

LOCK TABLES `tenant` WRITE;
/*!40000 ALTER TABLE `tenant` DISABLE KEYS */;
/*!40000 ALTER TABLE `tenant` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tenant_isolation_config`
--

DROP TABLE IF EXISTS `tenant_isolation_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenant_isolation_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint(20) DEFAULT NULL,
  `isolation_type` varchar(64) DEFAULT NULL,
  `config_key` varchar(128) DEFAULT NULL,
  `config_value` text DEFAULT NULL,
  `description` text DEFAULT NULL,
  `is_enabled` tinyint(1) DEFAULT 1,
  `is_del` tinyint(1) DEFAULT 0,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `cpu_quota` int(11) DEFAULT 0 COMMENT 'CPU配额（核）',
  `memory_quota` int(11) DEFAULT 0 COMMENT '内存配额（GB）',
  `storage_quota` int(11) DEFAULT 0 COMMENT '存储配额（GB）',
  `dataset_limit` int(11) DEFAULT 0 COMMENT '数据集数量限制',
  `model_limit` int(11) DEFAULT 0 COMMENT '模型数量限制',
  `concurrent_tasks` int(11) DEFAULT 10 COMMENT '并发任务数',
  `network_isolation` tinyint(1) DEFAULT 0 COMMENT '网络隔离',
  `namespace` varchar(100) DEFAULT NULL COMMENT '命名空间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tenant_isolation_config`
--

LOCK TABLES `tenant_isolation_config` WRITE;
/*!40000 ALTER TABLE `tenant_isolation_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `tenant_isolation_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tenant_resource_allocation`
--

DROP TABLE IF EXISTS `tenant_resource_allocation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenant_resource_allocation` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint(20) DEFAULT NULL,
  `resource_type` varchar(64) DEFAULT NULL,
  `total_quota` bigint(20) DEFAULT NULL,
  `used_quota` bigint(20) DEFAULT 0,
  `reserved_quota` bigint(20) DEFAULT 0,
  `unit` varchar(32) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `effective_time` datetime DEFAULT NULL,
  `expiry_time` datetime DEFAULT NULL,
  `permission_level` int(11) DEFAULT NULL,
  `quota_amount` varchar(255) DEFAULT NULL,
  `quota_unit` varchar(255) DEFAULT NULL,
  `remark` varchar(1024) DEFAULT NULL,
  `resource_id` varchar(255) DEFAULT NULL,
  `resource_name` varchar(255) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tenant_resource_allocation`
--

LOCK TABLES `tenant_resource_allocation` WRITE;
/*!40000 ALTER TABLE `tenant_resource_allocation` DISABLE KEYS */;
/*!40000 ALTER TABLE `tenant_resource_allocation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `whitelist`
--

DROP TABLE IF EXISTS `whitelist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `whitelist` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `type` varchar(64) DEFAULT NULL,
  `value` varchar(512) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `status` int(11) DEFAULT 1,
  `create_user_id` bigint(20) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `whitelist`
--

LOCK TABLES `whitelist` WRITE;
/*!40000 ALTER TABLE `whitelist` DISABLE KEYS */;
/*!40000 ALTER TABLE `whitelist` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `whitelist_access_log`
--

DROP TABLE IF EXISTS `whitelist_access_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `whitelist_access_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `whitelist_id` bigint(20) DEFAULT NULL,
  `access_ip` varchar(128) DEFAULT NULL,
  `access_user_id` bigint(20) DEFAULT NULL,
  `access_type` varchar(64) DEFAULT NULL,
  `access_result` varchar(64) DEFAULT NULL COMMENT '访问结果',
  `remark` varchar(512) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_date` datetime DEFAULT NULL,
  `access_time` datetime DEFAULT NULL,
  `access_url` varchar(1024) DEFAULT NULL,
  `fail_reason` varchar(255) DEFAULT NULL,
  `request_method` varchar(255) DEFAULT NULL,
  `request_params` varchar(1024) DEFAULT NULL,
  `response_code` varchar(255) DEFAULT NULL,
  `response_time` bigint(20) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `whitelist_access_log`
--

LOCK TABLES `whitelist_access_log` WRITE;
/*!40000 ALTER TABLE `whitelist_access_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `whitelist_access_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `whitelist_config`
--

DROP TABLE IF EXISTS `whitelist_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `whitelist_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_key` varchar(128) DEFAULT NULL,
  `config_value` text DEFAULT NULL,
  `config_type` varchar(64) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `update_user_id` bigint(20) DEFAULT NULL,
  `update_user` varchar(255) DEFAULT NULL,
  `is_del` tinyint(1) DEFAULT 0,
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `whitelist_config`
--

LOCK TABLES `whitelist_config` WRITE;
/*!40000 ALTER TABLE `whitelist_config` DISABLE KEYS */;
INSERT INTO `whitelist_config` VALUES
(1,'enableWhitelist','false','boolean','是否启用白名单功能',NULL,NULL,0,NULL,NULL),
(2,'defaultPolicy','DENY','string','默认策略：ALLOW-允许，DENY-拒绝',NULL,NULL,0,NULL,NULL),
(3,'enableAccessLog','true','boolean','是否记录访问日志',NULL,NULL,0,NULL,NULL),
(4,'logRetentionDays','30','number','日志保留天数',NULL,NULL,0,NULL,NULL),
(5,'ipMatchMode','EXACT','string','IP匹配模式：EXACT-精确，CIDR-CIDR，RANGE-范围',NULL,NULL,0,NULL,NULL),
(6,'maxFailedAttempts','5','number','最大失败尝试次数',NULL,NULL,0,NULL,NULL),
(7,'lockDuration','30','number','锁定时长（分钟）',NULL,NULL,0,NULL,NULL),
(8,'enableAlert','false','boolean','是否启用告警',NULL,NULL,0,NULL,NULL),
(9,'alertEmails','','string','告警邮箱',NULL,NULL,0,NULL,NULL),
(10,'cacheTime','300','number','缓存时间（秒）',NULL,NULL,0,NULL,NULL);
/*!40000 ALTER TABLE `whitelist_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Current Database: `fusion3`
--

/*!40000 DROP DATABASE IF EXISTS `fusion3`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `fusion3` /*!40100 DEFAULT CHARACTER SET utf8mb3 COLLATE utf8mb3_bin */;

USE `fusion3`;

--
-- Table structure for table `data_requirement`
--

DROP TABLE IF EXISTS `data_requirement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_requirement` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `requirement_code` varchar(64) NOT NULL COMMENT '需求编码',
  `requirement_name` varchar(128) NOT NULL COMMENT '需求名称',
  `requirement_desc` text DEFAULT NULL COMMENT '需求描述',
  `requirement_type` varchar(32) DEFAULT NULL COMMENT '需求类型',
  `data_fields` text DEFAULT NULL COMMENT '所需数据字段(JSON格式)',
  `data_volume` bigint(20) DEFAULT NULL COMMENT '所需数据量',
  `data_format` varchar(32) DEFAULT NULL COMMENT '所需数据格式',
  `priority` tinyint(4) DEFAULT 0 COMMENT '优先级(0-低 1-中 2-高)',
  `status` tinyint(4) DEFAULT 0 COMMENT '状态(0-待匹配 1-已匹配 2-已完成 3-已关闭)',
  `user_id` bigint(20) NOT NULL COMMENT '创建人用户ID',
  `user_name` varchar(64) DEFAULT NULL COMMENT '创建人用户名',
  `organ_id` bigint(20) DEFAULT NULL COMMENT '机构ID',
  `organ_name` varchar(128) DEFAULT NULL COMMENT '机构名称',
  `start_date` datetime DEFAULT NULL COMMENT '需求开始日期',
  `end_date` datetime DEFAULT NULL COMMENT '需求结束日期',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '删除标记',
  `create_date` datetime DEFAULT current_timestamp() COMMENT '创建时间',
  `update_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_requirement_code` (`requirement_code`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_create_date` (`create_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='数据需求表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_requirement`
--

LOCK TABLES `data_requirement` WRITE;
/*!40000 ALTER TABLE `data_requirement` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_requirement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_requirement_config`
--

DROP TABLE IF EXISTS `data_requirement_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_requirement_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `config_key` varchar(64) NOT NULL,
  `config_value` text NOT NULL,
  `config_desc` varchar(255) DEFAULT NULL,
  `config_type` varchar(32) DEFAULT NULL,
  `is_enabled` tinyint(4) DEFAULT 1,
  `is_del` tinyint(4) DEFAULT 0,
  `create_date` datetime DEFAULT current_timestamp(),
  `update_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='数据需求配置表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_requirement_config`
--

LOCK TABLES `data_requirement_config` WRITE;
/*!40000 ALTER TABLE `data_requirement_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_requirement_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_requirement_match`
--

DROP TABLE IF EXISTS `data_requirement_match`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_requirement_match` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `requirement_id` bigint(20) NOT NULL,
  `resource_id` bigint(20) NOT NULL,
  `match_score` decimal(5,2) DEFAULT 0.00,
  `match_status` tinyint(4) DEFAULT 0,
  `match_type` varchar(32) DEFAULT NULL,
  `match_details` text DEFAULT NULL,
  `is_del` tinyint(4) DEFAULT 0,
  `create_date` datetime DEFAULT current_timestamp(),
  `update_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_requirement_id` (`requirement_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='数据需求匹配表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_requirement_match`
--

LOCK TABLES `data_requirement_match` WRITE;
/*!40000 ALTER TABLE `data_requirement_match` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_requirement_match` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_set`
--

DROP TABLE IF EXISTS `data_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_set` (
  `id` varchar(255) NOT NULL COMMENT '主键',
  `access_info` text DEFAULT NULL COMMENT '访问信息',
  `driver` varchar(255) NOT NULL COMMENT '资源类型',
  `address` varchar(255) DEFAULT NULL COMMENT '资源地址',
  `visibility` varchar(255) NOT NULL COMMENT '可见性',
  `available` varchar(255) NOT NULL COMMENT '可获得',
  `holder` tinyint(4) DEFAULT 0 COMMENT '是否持有 0持有 1不持有',
  `fields` text DEFAULT NULL COMMENT '字段列表',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_set`
--

LOCK TABLES `data_set` WRITE;
/*!40000 ALTER TABLE `data_set` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_set` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fusion_organ`
--

DROP TABLE IF EXISTS `fusion_organ`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fusion_organ` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `global_id` varchar(64) NOT NULL COMMENT '唯一id',
  `global_name` varchar(64) NOT NULL COMMENT '机构名称',
  `register_time` datetime(3) NOT NULL COMMENT '注册时间',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `global_id_ix` (`global_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fusion_organ`
--

LOCK TABLES `fusion_organ` WRITE;
/*!40000 ALTER TABLE `fusion_organ` DISABLE KEYS */;
/*!40000 ALTER TABLE `fusion_organ` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fusion_organ_resource_auth`
--

DROP TABLE IF EXISTS `fusion_organ_resource_auth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fusion_organ_resource_auth` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `resource_id` bigint(20) NOT NULL COMMENT '资源id',
  `organ_id` bigint(20) NOT NULL COMMENT '机构id',
  `project_id` varchar(255) DEFAULT NULL COMMENT '项目ID',
  `audit_status` tinyint(4) NOT NULL DEFAULT 1 COMMENT '审核状态',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `resource_id_ix` (`resource_id`) USING BTREE,
  KEY `organ_id_ix` (`organ_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fusion_organ_resource_auth`
--

LOCK TABLES `fusion_organ_resource_auth` WRITE;
/*!40000 ALTER TABLE `fusion_organ_resource_auth` DISABLE KEYS */;
/*!40000 ALTER TABLE `fusion_organ_resource_auth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fusion_resource`
--

DROP TABLE IF EXISTS `fusion_resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fusion_resource` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `resource_id` varchar(64) DEFAULT NULL COMMENT '资源ID',
  `resource_name` varchar(255) DEFAULT NULL COMMENT '资源名称',
  `resource_desc` varchar(255) DEFAULT NULL COMMENT '资源描述',
  `resource_type` tinyint(4) DEFAULT NULL COMMENT '资源类型 上传...',
  `resource_auth_type` tinyint(4) DEFAULT NULL COMMENT '授权类型（公开，私有，可见性）',
  `resource_rows_count` int(11) DEFAULT NULL COMMENT '资源行数',
  `resource_column_count` int(11) DEFAULT NULL COMMENT '资源列数',
  `resource_column_name_list` text DEFAULT NULL COMMENT '字段列表',
  `resource_contains_y` tinyint(4) DEFAULT NULL COMMENT '资源字段中是否包含y字段 0否 1是',
  `resource_y_rows_count` int(11) DEFAULT NULL COMMENT '文件字段y值内容不为空和0的行数',
  `resource_y_ratio` decimal(10,2) DEFAULT NULL COMMENT '文件字段y值内容不为空的行数在总行的占比',
  `resource_tag` varchar(255) DEFAULT NULL COMMENT '资源标签 格式tag,tag',
  `organ_id` varchar(64) DEFAULT NULL COMMENT '机构ID',
  `resource_hash_code` varchar(255) DEFAULT NULL COMMENT '资源hash值',
  `resource_state` tinyint(4) NOT NULL DEFAULT 0 COMMENT '资源状态 0上线 1下线',
  `user_name` varchar(255) DEFAULT NULL COMMENT '用户名称',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `resource_id_ix` (`resource_id`) USING BTREE,
  KEY `organ_id_ix` (`organ_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fusion_resource`
--

LOCK TABLES `fusion_resource` WRITE;
/*!40000 ALTER TABLE `fusion_resource` DISABLE KEYS */;
/*!40000 ALTER TABLE `fusion_resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fusion_resource_field`
--

DROP TABLE IF EXISTS `fusion_resource_field`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fusion_resource_field` (
  `field_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '字段id',
  `resource_id` bigint(20) DEFAULT NULL COMMENT '资源id',
  `field_name` varchar(255) DEFAULT NULL COMMENT '字段名称',
  `field_as` varchar(255) DEFAULT NULL COMMENT '字段别名',
  `field_type` int(11) DEFAULT 0 COMMENT '字段类型 默认0 string',
  `field_desc` varchar(255) DEFAULT NULL COMMENT '字段描述',
  `is_del` tinyint(4) DEFAULT 0 COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '修改时间',
  PRIMARY KEY (`field_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fusion_resource_field`
--

LOCK TABLES `fusion_resource_field` WRITE;
/*!40000 ALTER TABLE `fusion_resource_field` DISABLE KEYS */;
/*!40000 ALTER TABLE `fusion_resource_field` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fusion_resource_tag`
--

DROP TABLE IF EXISTS `fusion_resource_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fusion_resource_tag` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `name` varchar(255) DEFAULT NULL COMMENT '标签名称',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fusion_resource_tag`
--

LOCK TABLES `fusion_resource_tag` WRITE;
/*!40000 ALTER TABLE `fusion_resource_tag` DISABLE KEYS */;
/*!40000 ALTER TABLE `fusion_resource_tag` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fusion_resource_visibility_auth`
--

DROP TABLE IF EXISTS `fusion_resource_visibility_auth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fusion_resource_visibility_auth` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `resource_id` varchar(64) NOT NULL COMMENT '资源id',
  `organ_global_id` varchar(64) NOT NULL COMMENT '机构id',
  `is_del` tinyint(4) NOT NULL COMMENT '是否删除',
  `c_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) COMMENT '创建时间',
  `u_time` datetime(3) NOT NULL DEFAULT current_timestamp(3) ON UPDATE current_timestamp(3) COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `resource_id_ix` (`resource_id`) USING BTREE,
  KEY `organ_global_id_ix` (`organ_global_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fusion_resource_visibility_auth`
--

LOCK TABLES `fusion_resource_visibility_auth` WRITE;
/*!40000 ALTER TABLE `fusion_resource_visibility_auth` DISABLE KEYS */;
/*!40000 ALTER TABLE `fusion_resource_visibility_auth` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-16  2:20:40
SET FOREIGN_KEY_CHECKS=1;
GRANT ALL ON *.* TO 'primihub'@'%';
