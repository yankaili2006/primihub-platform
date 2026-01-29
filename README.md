[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
# Welcome to primihub-platform
primihub-platform is a Muti-Party Computation and Muti-Party federated task security scheduling platform for mpc and fl point to point service.

## Features

PrimiHub Platform is a comprehensive **Multi-Party Secure Computation Platform** that enables organizations to collaborate on data analysis and machine learning without exposing raw data.

### Core Capabilities

**Privacy Computing Features:**
- 🔍 **Private Information Retrieval (PIR)** - Query databases without revealing query content
- 🔒 **Private Set Intersection (PSI)** - Compute intersections without exposing unique data
- 🤖 **Federated Learning** - Train models collaboratively across multiple parties
- 📊 **Multi-Party Analytics** - Secure data analysis across organizations

**Platform Services:**
- 📁 **Resource Management** - Centralized data resource lifecycle management
- 🚀 **Project Management** - Multi-party collaboration project orchestration
- 🧠 **Model Registry** - Federated model versioning and deployment
- 🔧 **Inference Services** - Online model prediction and serving
- 👥 **Access Control** - Fine-grained role-based permission system
- 📝 **Audit Logging** - Comprehensive operation tracking and compliance


and have a clear directory:

    ├─primihub-platform
        ├─primihub-service
        │   ├─application
        │   ├─biz
        │   ├─gateway
        │   └─script
        └─primihub-webconsole

## Getting Started

### Quick Start (Recommended)

For a quick deployment using H2 database (development/testing):

```bash
# 1. Start backend service
cd primihub-service/application
./start-minimal.sh

# 2. Start frontend (in another terminal)
cd primihub-webconsole
npm run serve

# 3. Access the platform
# Frontend: http://localhost:8080 (admin/admin)
# API Docs: http://localhost:8090/doc.html
```

### Documentation

- **[🚀 Quick Reference](QUICKREF.md)** - One-page quick reference guide
- **[📖 Deployment Guide](DEPLOYMENT.md)** - Detailed deployment instructions
- **[🔧 Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions
- **[🐍 Python Setup](../primihub/python/SETUP.md)** - Python environment configuration

### Platform Menus

The platform provides 9 main functional modules accessible through a permission-controlled menu system:

#### 🔐 Privacy Computing Modules

| Module | Route | Description |
|--------|-------|-------------|
| **Private Search (PIR)** | `/privateSearch` | Execute privacy-preserving information retrieval queries without exposing search keywords |
| **Private Set Intersection** | `/PSI` | Perform multi-party set intersection with configurable PSI algorithms |
| **Project Management** | `/project` | Create and manage multi-party collaboration projects with resource allocation |
| **Model Management** | `/model` | Build, train and manage federated learning models with component configuration |
| **Inference Services** | `/reasoning` | Deploy and manage model inference services for online prediction |

#### 💾 Resource Module

| Module | Route | Description |
|--------|-------|-------------|
| **Resource Management** | `/resource` | Manage data resources across 4 categories:<br>• My Resources - User uploaded datasets<br>• Collaborative Resources - Shared by partners<br>• Available Resources - Requestable resources<br>• Derived Data - Results from privacy computations |

#### ⚙️ System Administration Modules

| Module | Route | Description |
|--------|-------|-------------|
| **System Settings** | `/setting` | Configure users, roles, and manage federation nodes |
| **Whitelist Management** | `/whitelist` | Control registration access via email/phone whitelists |
| **Operation Logs** | `/operationLog` | Audit trail with comprehensive logging and filtering |

### Permission System

The platform implements a **three-tier permission model**:

1. **Menu Permission** (auth_type=1) - Controls access to top-level menus
2. **Page Permission** (auth_type=2) - Controls access to specific pages/sub-menus
3. **Button Permission** (auth_type=3) - Controls granular operations like add/edit/delete

**Permission Flow:**
```
User Login → Fetch Permission List → Generate Dynamic Routes → Permission Guard → Render Authorized Menus
```

Key tables: `sys_auth`, `sys_role`, `sys_ra` (role-auth mapping), `sys_user`, `sys_ur` (user-role mapping)

### Architecture

**Frontend Stack:**
- Vue.js 2.x + Vuex + Vue Router
- Element UI Component Library
- Dynamic routing with permission control

**Backend Stack:**
- Spring Boot RESTful API
- H2 (development) / MySQL (production)
- Redis for permission caching

**Key Directories:**
```
primihub-platform/
├── primihub-webconsole/          # Frontend application
│   ├── src/
│   │   ├── views/                # Page components
│   │   │   ├── privateSearch/    # PIR module
│   │   │   ├── PSI/             # PSI module
│   │   │   ├── project/         # Project management
│   │   │   ├── model/           # Model management
│   │   │   ├── reasoning/       # Inference services
│   │   │   ├── resource/        # Resource management
│   │   │   └── setting/         # System settings
│   │   ├── api/                 # API definitions
│   │   ├── router/              # Route configuration
│   │   └── store/               # Vuex state management
└── primihub-service/            # Backend services
    ├── application/             # Main application
    ├── biz/                     # Business logic
    ├── gateway/                 # API gateway
    └── script/                  # Deployment scripts
```

### Components

Before we start, please refer to [primihub](https://github.com/primihub/primihub) and start node.

then we can get started from those projects.

- [primihub-meta](https://github.com/primihub/primihub-meta) : connect primihub-service and have the right data access.
- [primihub-service](./primihub-service/README.md) : provide all most of service capabilities and api.
- [primihub-webconsole](./primihub-webconsole/README.md) : you can operate specific functions and have a clear view.

### Key Updates (2026-01-02)

**⚠️ Important for FL (Federated Learning) Users:**

The original `requirements.txt` is outdated. For FL functionality, use:
- **Python**: 3.10-3.12 (tested with 3.12.3)
- **PyTorch**: 2.6.0+cpu or higher (⚠️ must be 2.6+, older versions will fail)
- **Install**: See [Python Setup Guide](../primihub/python/SETUP.md) for details

Quick install:
```bash
pip install --no-cache-dir \
  torch==2.6.0+cpu torchvision==0.21.0+cpu \
  --index-url https://download.pytorch.org/whl/cpu
pip install --no-cache-dir loguru scikit-learn phe opacus
```

### API Reference

The platform exposes RESTful APIs for all major functions:

#### Privacy Computing APIs
- **PIR (Private Information Retrieval)**
  - `GET /data/pir/getPirTaskList` - List PIR tasks
  - `POST /data/pir/pirSubmitTask` - Submit PIR query
  - `GET /data/pir/getPirTaskDetail` - Get task details

- **PSI (Private Set Intersection)**
  - `GET /data/psi/getPsiTaskList` - List PSI tasks
  - `POST /data/psi/saveDataPsi` - Create PSI task
  - `GET /data/psi/cancelPsiTask` - Cancel task
  - `GET /data/psi/retryPsiTask` - Retry failed task

#### Resource & Project APIs
- **Project Management**
  - `GET /data/project/getProjectList` - List projects
  - `POST /data/project/saveOrUpdateProject` - Create/update project
  - `POST /data/project/approval` - Approve project
  - `POST /data/project/closeProject` - Close project

- **Resource Management**
  - `GET /data/resource/getdataresourcelist` - List resources
  - `POST /data/resource/saveorupdateresource` - Create/update resource
  - `GET /data/resource/getdataresource` - Get resource details
  - `GET /data/resource/deldataresource` - Delete resource

#### Model & Inference APIs
- **Model Management**
  - `GET /data/model/getmodellist` - List models
  - `POST /data/model/saveModelAndComponent` - Save model
  - `GET /data/model/getdatamodel` - Get model details
  - `GET /data/task/getModelTaskList` - List model tasks

- **Inference Services**
  - `GET /data/reasoning/getReasoningList` - List inference services
  - `POST /data/reasoning/saveReasoning` - Create/update service
  - `GET /data/reasoning/getReasoning` - Get service details

#### System Management APIs
- **User & Role**
  - `GET /sys/user/findUserPage` - List users
  - `POST /sys/user/saveOrUpdateUser` - Create/update user
  - `GET /sys/role/findRolePage` - List roles
  - `POST /sys/role/saveOrUpdateRole` - Create/update role

- **Whitelist**
  - `GET /sys/whitelist/findWhitelistPage` - List whitelists
  - `POST /sys/whitelist/saveOrUpdateWhitelist` - Create/update whitelist
  - `POST /sys/whitelist/deleteWhitelist` - Delete whitelist

- **Operation Logs**
  - `POST /dev-api/sys/operationLog/getOperationLogPage` - List logs
  - `GET /dev-api/sys/operationLog/getOperationLogDetail` - Get log details
  - `POST /dev-api/sys/operationLog/exportOperationLog` - Export logs

**API Documentation:** Access interactive API docs at `http://localhost:8090/doc.html` after starting the backend service.

## License
[Apache License 2.0](./LICENSE)

## Contact Us

It's pleasure to offer a primihub assistant to a contract list by scanning the QR code. You can get support on technique,business and the chance to community with us util the assistant invite you to the open source community group.

![assitant](./assitant.png)

And also welcome to follow our official account and slack home page([primihub slack](https://primihub.slack.com/join/shared_invite/zt-1af0l22ar-jmTI2C_DPUd3QSuPuOsYdA#/shared-invite/email)).

![offical](./offical.JPEG)

