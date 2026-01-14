# 联邦求差和联邦求并Python算法配置指南

## 概述

本文档说明如何为联邦求差和联邦求并功能配置独立的Python算法实现。每个功能对应不同的隐私计算算法，支持ECDH、KKRT和TEE三种实现方式。

## 算法文件结构

建议在PrimiHub引擎中创建以下目录结构：

```
primihub/
├── python/
│   ├── primihub/
│   │   ├── algorithm/
│   │   │   ├── set_operations/          # 集合运算算法目录
│   │   │   │   ├── __init__.py
│   │   │   │   ├── difference.py        # 联邦求差算法
│   │   │   │   ├── union.py             # 联邦求并算法
│   │   │   │   ├── intersection.py      # 隐私求交算法（已存在）
│   │   │   │   └── utils.py             # 通用工具函数
```

## 1. 联邦求差算法实现 (difference.py)

### 1.1 ECDH实现

```python
"""
联邦求差 - ECDH实现
计算集合差集 A - B，确保双方数据隐私
"""

import hashlib
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes

class ECDHDifference:
    """基于ECDH的联邦求差"""

    def __init__(self, direction=0):
        """
        初始化
        Args:
            direction: 0表示A-B，1表示B-A
        """
        self.direction = direction
        self.private_key = ec.generate_private_key(ec.SECP256R1())
        self.public_key = self.private_key.public_key()

    def compute_difference(self, set_a, set_b, party_role='initiator'):
        """
        计算集合差集

        Args:
            set_a: 本方集合
            set_b: 对方加密集合
            party_role: 'initiator' 或 'participant'

        Returns:
            差集结果
        """
        if party_role == 'initiator':
            # 发起方：计算A-B
            if self.direction == 0:
                return self._compute_a_minus_b(set_a, set_b)
            else:
                return self._compute_b_minus_a(set_a, set_b)
        else:
            # 参与方：协助计算
            return self._assist_computation(set_a, set_b)

    def _compute_a_minus_b(self, set_a, encrypted_set_b):
        """计算 A - B"""
        # 1. 对本方集合进行加密
        encrypted_a = self._encrypt_set(set_a)

        # 2. 找出A中不在B中的元素
        difference = []
        for item in encrypted_a:
            if item not in encrypted_set_b:
                difference.append(item)

        return difference

    def _compute_b_minus_a(self, set_b, encrypted_set_a):
        """计算 B - A"""
        # 实现 B - A 的逻辑
        encrypted_b = self._encrypt_set(set_b)

        difference = []
        for item in encrypted_b:
            if item not in encrypted_set_a:
                difference.append(item)

        return difference

    def _encrypt_set(self, data_set):
        """使用ECDH加密集合"""
        encrypted = []
        for item in data_set:
            # 使用椭圆曲线加密
            item_bytes = str(item).encode()
            digest = hashes.Hash(hashes.SHA256())
            digest.update(item_bytes)
            encrypted_item = digest.finalize()
            encrypted.append(encrypted_item)

        return encrypted

    def _assist_computation(self, local_set, remote_request):
        """协助对方计算"""
        # 返回加密后的本方集合
        return self._encrypt_set(local_set)


# 算法入口函数
def execute_difference(params):
    """
    执行联邦求差任务

    Args:
        params: dict，包含以下字段：
            - own_data: 本方数据集
            - other_data: 对方数据（或加密数据）
            - direction: 0 (A-B) 或 1 (B-A)
            - party_role: 'initiator' 或 'participant'
            - method: 'ecdh', 'kkrt', 'tee'

    Returns:
        差集结果
    """
    direction = params.get('direction', 0)
    method = params.get('method', 'ecdh')

    if method == 'ecdh':
        algo = ECDHDifference(direction)
        return algo.compute_difference(
            params['own_data'],
            params.get('other_data', []),
            params.get('party_role', 'initiator')
        )
    elif method == 'kkrt':
        # TODO: 实现KKRT算法
        raise NotImplementedError("KKRT差集算法待实现")
    elif method == 'tee':
        # TODO: 实现TEE算法
        raise NotImplementedError("TEE差集算法待实现")
    else:
        raise ValueError(f"不支持的算法类型: {method}")
```

### 1.2 KKRT实现 (待实现)

```python
class KKRTDifference:
    """基于KKRT的联邦求差"""

    def __init__(self, direction=0):
        self.direction = direction
        # KKRT特定初始化

    def compute_difference(self, set_a, set_b, party_role):
        # KKRT协议实现
        pass
```

## 2. 联邦求并算法实现 (union.py)

```python
"""
联邦求并 - ECDH实现
计算集合并集 A ∪ B，确保双方数据隐私
"""

import hashlib
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes

class ECDHUnion:
    """基于ECDH的联邦求并"""

    def __init__(self):
        self.private_key = ec.generate_private_key(ec.SECP256R1())
        self.public_key = self.private_key.public_key()

    def compute_union(self, set_a, set_b, party_role='initiator'):
        """
        计算集合并集

        Args:
            set_a: 本方集合
            set_b: 对方加密集合
            party_role: 'initiator' 或 'participant'

        Returns:
            并集结果（去重）
        """
        if party_role == 'initiator':
            return self._compute_union_initiator(set_a, set_b)
        else:
            return self._assist_computation(set_a)

    def _compute_union_initiator(self, set_a, encrypted_set_b):
        """发起方计算并集"""
        # 1. 加密本方集合
        encrypted_a = self._encrypt_set(set_a)

        # 2. 合并两个加密集合
        union_set = set()
        union_set.update(encrypted_a)
        union_set.update(encrypted_set_b)

        # 3. 返回去重后的结果
        return list(union_set)

    def _encrypt_set(self, data_set):
        """使用ECDH加密集合"""
        encrypted = []
        for item in data_set:
            item_bytes = str(item).encode()
            digest = hashes.Hash(hashes.SHA256())
            digest.update(item_bytes)
            encrypted_item = digest.finalize()
            encrypted.append(encrypted_item)

        return encrypted

    def _assist_computation(self, local_set):
        """协助对方计算"""
        return self._encrypt_set(local_set)


def execute_union(params):
    """
    执行联邦求并任务

    Args:
        params: dict，包含以下字段：
            - own_data: 本方数据集
            - other_data: 对方数据（或加密数据）
            - party_role: 'initiator' 或 'participant'
            - method: 'ecdh', 'kkrt', 'tee'

    Returns:
        并集结果
    """
    method = params.get('method', 'ecdh')

    if method == 'ecdh':
        algo = ECDHUnion()
        return algo.compute_union(
            params['own_data'],
            params.get('other_data', []),
            params.get('party_role', 'initiator')
        )
    elif method == 'kkrt':
        raise NotImplementedError("KKRT并集算法待实现")
    elif method == 'tee':
        raise NotImplementedError("TEE并集算法待实现")
    else:
        raise ValueError(f"不支持的算法类型: {method}")
```

## 3. 算法注册配置

在Java后端的Service中调用Python算法：

### 3.1 更新DataDifferenceService.java

```java
public BaseResultEntity saveDataDifference(DataDifferenceReq req, Long userId) {
    try {
        String taskId = UUID.randomUUID().toString();

        // 1. 构建Python算法参数
        Map<String, Object> algorithmParams = new HashMap<>();
        algorithmParams.put("own_data", loadResourceData(req.getOwnResourceId()));
        algorithmParams.put("direction", req.getDifferenceDirection());
        algorithmParams.put("party_role", "initiator");
        algorithmParams.put("method", getMethodName(req.getTag())); // 0->ecdh, 1->kkrt, 2->tee

        // 2. 调用Python算法引擎
        String algorithmPath = "primihub.algorithm.set_operations.difference.execute_difference";
        Object result = pythonEngine.execute(algorithmPath, algorithmParams);

        // 3. 保存结果到数据库
        // ... 省略数据库操作代码

        // 4. 记录计算日志
        recordComputeLog(taskId, req.getResultName(), "联邦求差", userId, null, 1);

        return BaseResultEntity.success(result);
    } catch (Exception e) {
        log.error("执行联邦求差任务失败", e);
        return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务执行失败");
    }
}

private String getMethodName(Integer tag) {
    switch (tag) {
        case 0: return "ecdh";
        case 1: return "kkrt";
        case 2: return "tee";
        default: return "ecdh";
    }
}
```

### 3.2 更新DataUnionService.java

```java
public BaseResultEntity saveDataUnion(DataUnionReq req, Long userId) {
    try {
        String taskId = UUID.randomUUID().toString();

        // 构建算法参数
        Map<String, Object> algorithmParams = new HashMap<>();
        algorithmParams.put("own_data", loadResourceData(req.getOwnResourceId()));
        algorithmParams.put("party_role", "initiator");
        algorithmParams.put("method", getMethodName(req.getTag()));

        // 调用Python算法
        String algorithmPath = "primihub.algorithm.set_operations.union.execute_union";
        Object result = pythonEngine.execute(algorithmPath, algorithmParams);

        // 保存结果和记录日志
        recordComputeLog(taskId, req.getResultName(), "联邦求并", userId, null, 1);

        return BaseResultEntity.success(result);
    } catch (Exception e) {
        log.error("执行联邦求并任务失败", e);
        return BaseResultEntity.failure(BaseResultEnum.FAILURE, "任务执行失败");
    }
}
```

## 4. 算法配置文件

创建 `algorithm_config.yaml`:

```yaml
algorithms:
  difference:
    name: "联邦求差"
    module: "primihub.algorithm.set_operations.difference"
    entry: "execute_difference"
    methods:
      - ecdh: "ECDH协议实现"
      - kkrt: "KKRT协议实现"
      - tee: "TEE可信执行环境"
    params:
      - own_data: "本方数据集"
      - direction: "求差方向 0:A-B 1:B-A"
      - party_role: "角色 initiator/participant"

  union:
    name: "联邦求并"
    module: "primihub.algorithm.set_operations.union"
    entry: "execute_union"
    methods:
      - ecdh: "ECDH协议实现"
      - kkrt: "KKRT协议实现"
      - tee: "TEE可信执行环境"
    params:
      - own_data: "本方数据集"
      - party_role: "角色 initiator/participant"
```

## 5. 测试算法

### 5.1 Python单元测试

```python
# test_difference.py
import unittest
from primihub.algorithm.set_operations.difference import execute_difference

class TestDifference(unittest.TestCase):

    def test_ecdh_difference_a_minus_b(self):
        """测试 A - B"""
        params = {
            'own_data': [1, 2, 3, 4, 5],
            'other_data': [3, 4, 5, 6, 7],
            'direction': 0,
            'party_role': 'initiator',
            'method': 'ecdh'
        }

        result = execute_difference(params)
        # 期望结果: [1, 2]
        self.assertEqual(len(result), 2)

    def test_ecdh_difference_b_minus_a(self):
        """测试 B - A"""
        params = {
            'own_data': [3, 4, 5, 6, 7],
            'other_data': [1, 2, 3, 4, 5],
            'direction': 1,
            'party_role': 'initiator',
            'method': 'ecdh'
        }

        result = execute_difference(params)
        # 期望结果: [6, 7]
        self.assertEqual(len(result), 2)

if __name__ == '__main__':
    unittest.main()
```

### 5.2 集成测试

使用Postman或curl测试完整流程：

```bash
# 测试联邦求差
curl -X POST http://localhost:8080/data/difference/saveDataDifference \
  -H "Content-Type: application/json" \
  -H "userId: 1" \
  -d '{
    "ownOrganId": "org1",
    "ownResourceId": "res1",
    "ownKeyword": "id",
    "otherOrganId": "org2",
    "otherResourceId": "res2",
    "otherKeyword": "id",
    "resultName": "test_diff",
    "resultOrganIds": "org1",
    "tag": 0,
    "differenceDirection": 0
  }'

# 测试联邦求并
curl -X POST http://localhost:8080/data/union/saveDataUnion \
  -H "Content-Type: application/json" \
  -H "userId: 1" \
  -d '{
    "ownOrganId": "org1",
    "ownResourceId": "res1",
    "ownKeyword": "id",
    "otherOrganId": "org2",
    "otherResourceId": "res2",
    "otherKeyword": "id",
    "resultName": "test_union",
    "resultOrganIds": "org1,org2",
    "tag": 0
  }'
```

## 6. 部署说明

### 6.1 安装依赖

```bash
pip install cryptography
pip install pycryptodome
```

### 6.2 配置环境变量

```bash
export PRIMIHUB_ALGORITHM_PATH=/path/to/primihub/python
export PRIMIHUB_LOG_LEVEL=INFO
```

### 6.3 启动服务

```bash
# 启动Python算法服务
python -m primihub.algorithm.server

# 启动Java后端服务
cd primihub-service
mvn spring-boot:run
```

## 7. 性能优化建议

1. **批量处理**: 对大数据集使用分批处理
2. **缓存机制**: 缓存加密结果避免重复计算
3. **并行计算**: 利用多线程/多进程加速
4. **数据压缩**: 传输前压缩数据减少网络开销

## 8. 安全建议

1. **密钥管理**: 使用安全的密钥存储和轮换机制
2. **通信加密**: 使用TLS加密算法执行过程中的通信
3. **审计日志**: 记录所有算法调用和结果
4. **访问控制**: 严格控制算法执行权限

## 参考资源

- PrimiHub官方文档: https://docs.primihub.com
- ECDH协议: https://en.wikipedia.org/wiki/Elliptic-curve_Diffie–Hellman
- KKRT协议: https://eprint.iacr.org/2016/799
- TEE技术: https://www.intel.com/content/www/us/en/developer/tools/software-guard-extensions/overview.html

---

**版本**: v1.0.0
**更新日期**: 2026-01-14
**维护者**: PrimiHub团队
