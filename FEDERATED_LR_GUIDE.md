# 联邦学习LR项目创建指南

## 当前系统状态

### ✅ 已就绪
- **2个机构**:
  - API测试机构 (ID: 000000000000000000000000test0001)
  - PSI协作机构 (ID: 000000000000000000000000test0002)
- **4个数据资源**:
  - 用户特征数据_20260111_171336
  - 用户特征数据_20260111_174136
  - 机构A用户数据_20260111_175810
  - 机构B用户数据_20260111_175856

### ⚠️ 当前问题
**登录API存在CAPTCHA配置问题**，导致无法通过API登录系统。

错误信息：
```
缺少参数:validateKeyName
```

当提供validateKeyName参数时，返回500内部服务器错误，原因是CAPTCHA服务初始化失败。

## 解决方案

### 方案1: 使用Web界面（推荐）

由于API登录存在问题，建议直接使用Web界面创建联邦学习项目：

1. **访问Web界面**:
   - 机构1: http://localhost:30811
   - 机构2: http://localhost:30812
   - 机构3: http://localhost:30813

2. **登录系统**:
   - 用户名: admin
   - 密码: Admin@123456

3. **创建联邦LR项目**:
   - 进入"项目管理" → "创建项目"
   - 选择"联邦学习"类型
   - 选择"横向联邦学习"模式
   - 添加两个合作机构
   - 关联数据资源

4. **配置LR模型**:
   - 进入"模型管理" → "创建模型"
   - 选择"逻辑回归(Logistic Regression)"算法
   - 配置参数:
     - max_iter: 100 (最大迭代次数)
     - learning_rate: 0.01 (学习率)
     - batch_size: 32 (批次大小)
     - penalty: l2 (正则化方式)

5. **执行模型**:
   - 点击"运行模型"按钮
   - 查看任务执行状态
   - 查看训练结果

### 方案2: 修复CAPTCHA配置

如果需要使用API，需要修复CAPTCHA配置：

#### 问题根源
UserController.java (line 32-34) 强制要求validateKeyName参数：
```java
if(loginParam.getValidateKeyName()==null|| "".equals(loginParam.getValidateKeyName().trim())) {
    return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"validateKeyName");
}
```

但CAPTCHA服务初始化失败，导致验证无法完成。

#### 修复步骤

**选项A: 禁用CAPTCHA验证（仅用于测试）**

修改 `UserController.java`:
```java
@PostMapping("login")
public BaseResultEntity login(LoginParam loginParam,@RequestHeader(value = "ip",defaultValue = "") String ip){
    if(loginParam.getUserAccount()==null|| "".equals(loginParam.getUserAccount().trim())) {
        return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"userAccount");
    }
    if(loginParam.getUserPassword()==null|| "".equals(loginParam.getUserPassword().trim())) {
        return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"userPassword");
    }
    // 注释掉validateKeyName检查（仅用于测试）
    // if(loginParam.getValidateKeyName()==null|| "".equals(loginParam.getValidateKeyName().trim())) {
    //     return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"validateKeyName");
    // }
    return sysUserService.login(loginParam,ip);
}
```

然后重新编译和部署：
```bash
cd /home/primihub/primihub-platform/primihub-service
mvn clean package -DskipTests
# 复制新的JAR到容器
docker cp application/target/application-*.jar application0:/applications/application.jar
docker restart application0 application1 application2
```

**选项B: 修复CAPTCHA服务配置**

检查并修复CAPTCHA相关配置文件，确保图片资源路径正确。

## 联邦学习LR项目完整流程

### 1. 数据准备

两方各自准备训练数据：

**机构1数据** (包含标签):
```csv
id,age,income,credit_score,label
1,25,50000,720,1
2,35,75000,680,0
...
```

**机构2数据** (包含特征):
```csv
id,education,employment_years,debt_ratio
1,16,3,0.3
2,18,10,0.2
...
```

### 2. 创建数据资源

通过Web界面或API创建数据资源，定义字段类型和描述。

### 3. 创建联邦学习项目

```json
{
  "projectName": "联邦LR项目_两方协作",
  "projectDesc": "两方合作进行联邦逻辑回归算法训练",
  "projectType": "2",
  "projectMode": "1",
  "projectOrganList": [
    {
      "organId": "000000000000000000000000test0001",
      "organName": "API测试机构",
      "isMyOrgan": 1
    },
    {
      "organId": "000000000000000000000000test0002",
      "organName": "PSI协作机构",
      "isMyOrgan": 0
    }
  ],
  "projectResourceList": [
    {"resourceId": 3},
    {"resourceId": 4}
  ]
}
```

### 4. 创建LR模型

```json
{
  "modelName": "联邦LR模型",
  "modelDesc": "两方联邦逻辑回归模型",
  "projectId": "<项目ID>",
  "componentList": [
    {
      "componentCode": "LogisticRegression",
      "componentName": "逻辑回归",
      "componentParams": {
        "max_iter": 100,
        "learning_rate": 0.01,
        "batch_size": 32,
        "penalty": "l2"
      }
    }
  ]
}
```

### 5. 执行模型

调用 `/data/model/runTaskModel` API，传入modelId参数。

### 6. 查看结果

- 查看任务状态: `/data/task/getTaskData?taskId=<任务ID>`
- 查看模型详情: `/data/model/getdatamodel?taskId=<任务ID>`
- 下载结果文件: `/data/task/downloadTaskFile?taskId=<任务ID>`

## API端点总结

### 认证
- POST `/sys/user/login` - 用户登录
- GET `/sys/user/logout` - 用户登出

### 机构管理
- GET `/sys/organ/getOrganList` - 获取机构列表

### 资源管理
- POST `/data/resource/saveorupdateresource` - 创建/更新资源
- GET `/data/resource/getresourcelist` - 获取资源列表

### 项目管理
- POST `/data/project/saveOrUpdateProject` - 创建/更新项目
- GET `/data/project/getProjectList` - 获取项目列表
- GET `/data/project/getProjectDetails` - 获取项目详情

### 模型管理
- GET `/data/model/getModelComponent` - 获取可用模型组件
- POST `/data/model/saveModelAndComponent` - 创建模型
- GET `/data/model/runTaskModel` - 执行模型
- GET `/data/model/getmodellist` - 获取模型列表

### 任务管理
- GET `/data/task/getTaskList` - 获取任务列表
- GET `/data/task/getTaskData` - 获取任务详情
- GET `/data/task/getTaskLogInfo` - 获取任务日志

## 已创建的脚本

### 1. create_federated_lr_project.py
完整的联邦LR项目创建和执行脚本（需要修复登录后使用）。

### 2. create_federated_lr_simple.py
简化版脚本，用于测试系统连接和状态检查。

## 下一步行动

1. **立即可用**: 使用Web界面创建联邦LR项目
2. **API修复**: 修复CAPTCHA配置以启用API访问
3. **脚本执行**: 修复后运行 `create_federated_lr_project.py`

## 技术架构

```
┌─────────────┐         ┌─────────────┐
│   机构1     │         │   机构2     │
│  (发起方)   │         │  (合作方)   │
├─────────────┤         ├─────────────┤
│ 数据资源A   │         │ 数据资源B   │
│ (特征+标签) │         │  (特征)     │
└──────┬──────┘         └──────┬──────┘
       │                       │
       │    联邦学习协议        │
       │  (梯度聚合/参数更新)   │
       │                       │
       └───────┬───────────────┘
               │
        ┌──────▼──────┐
        │  联邦LR模型  │
        │  (全局模型)  │
        └─────────────┘
```

## 联邦LR算法说明

**逻辑回归(Logistic Regression)** 是一种经典的二分类算法，在联邦学习场景下：

1. **横向联邦学习**: 两方拥有相同特征但不同样本
2. **纵向联邦学习**: 两方拥有相同样本但不同特征

本系统支持两种模式，可根据实际数据分布选择。

### 关键参数

- **max_iter**: 最大迭代次数，控制训练轮数
- **learning_rate**: 学习率，控制参数更新步长
- **batch_size**: 批次大小，控制每次训练的样本数
- **penalty**: 正则化方式 (l1/l2)，防止过拟合

## 联系支持

如需进一步帮助，请查看：
- PrimiHub官方文档
- GitHub Issues: https://github.com/primihub/primihub
