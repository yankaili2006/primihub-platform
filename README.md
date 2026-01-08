[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
# Welcome to primihub-platform
primihub-platform is a Muti-Party Computation and Muti-Party federated task security scheduling platform for mpc and fl point to point service.

## Features
Providing production-level service capabilities:
- Data access
- Multi-Party Resource Fusion
- Task Scheduling
- Multi-Party Federated Model Registry
- Multi-Party Cooperation Authority Management


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

## License
[Apache License 2.0](./LICENSE)

## Contact Us

It's pleasure to offer a primihub assistant to a contract list by scanning the QR code. You can get support on technique,business and the chance to community with us util the assistant invite you to the open source community group.

![assitant](./assitant.png)

And also welcome to follow our official account and slack home page([primihub slack](https://primihub.slack.com/join/shared_invite/zt-1af0l22ar-jmTI2C_DPUd3QSuPuOsYdA#/shared-invite/email)).

![offical](./offical.JPEG)

