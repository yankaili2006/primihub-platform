# PrimiHub 快速参考指南

## 一键启动

```bash
# 1. 启动平台后端
cd primihub-platform/primihub-service/application
./start-minimal.sh

# 2. 启动前端
cd primihub-platform/primihub-webconsole
npm run serve

# 3. 启动Meta Service
cd primihub-meta
java -jar fusion-simple.jar --server.port=7977 --grpc.server.port=9090 &
java -jar fusion-simple.jar --server.port=7978 --grpc.server.port=9091 &
java -jar fusion-simple.jar --server.port=7979 --grpc.server.port=9092 &

# 4. 访问
# 前端: http://localhost:8080 (admin/admin)
# API: http://localhost:8090/doc.html
```

## Python环境配置

```bash
# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖（必须按此版本）
pip install --no-cache-dir \
  torch==2.6.0+cpu \
  torchvision==0.21.0+cpu \
  --index-url https://download.pytorch.org/whl/cpu

pip install --no-cache-dir \
  loguru scikit-learn phe opacus numpy pandas grpcio protobuf
```

## 功能测试

```bash
cd primihub

# PSI (307ms)
./primihub-cli --task_config_file=example/psi_ecdh_task_conf.json

# PIR (429ms)
./primihub-cli --task_config_file=example/keyword_pir_task_conf.json

# FL (~8s, 98%准确率)
./primihub-cli --task_config_file=example/FL/neural_network/hfl_binclass_plaintext.json
```

## 关键端口

| 服务 | 端口 |
|------|------|
| 前端 | 8080 |
| 后端 | 8090 |
| Meta | 7977-7979 |
| 节点 | 50050-50052 |

## 常见问题速查

| 问题 | 解决方案 |
|------|----------|
| ERROR: 265 | 安装Python依赖: `pip install loguru sklearn phe opacus` |
| torch.nn.RMSNorm不存在 | 升级torch: `pip install torch==2.6.0+cpu` |
| party count: 0 | 启动Meta Service |
| Column "ip" not found | 使用schema-complete-h2.sql |
| Docker拉取超时 | 使用start-minimal.sh简化部署 |
| 磁盘空间不足 | 使用torch CPU版本 + `--no-cache-dir` |

## 依赖版本要求

```
✅ Python: 3.10-3.12 (已验证3.12.3)
✅ torch: 2.6.0+cpu (必须2.6+)
✅ Java: JDK 17+
✅ Node.js: v16+
```

## 检查服务状态

```bash
# 一键检查
curl http://localhost:8090/actuator/health  # 后端
curl http://localhost:7977/health           # Meta
ps aux | grep "bazel-bin/node" | wc -l      # 节点(应为3)
```

## 查看结果

```bash
# PSI结果
cat data/result/psi_result.csv

# PIR结果
cat data/result/pir_result.csv

# FL结果
cat data/result/Bob_metrics.json
ls -lh data/result/*_model.pkl
```

## 日志位置

```bash
/tmp/test-service.log           # 平台服务
/tmp/fl_training*.log           # FL训练
/home/primihub/github/primihub/log_node{0,1,2}  # 计算节点
```

## 完整文档

- 部署指南: [DEPLOYMENT.md](DEPLOYMENT.md)
- 故障排查: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Python配置: [python/SETUP.md](python/SETUP.md)
- 测试报告: `/tmp/fl_success_report.md`

---

**2026-01-02更新** | PrimiHub v0.1.0+
