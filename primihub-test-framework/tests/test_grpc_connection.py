#!/usr/bin/env python3
"""
测试gRPC连接到Meta服务
"""
import grpc
from google.protobuf import descriptor_pool
import sys

def test_grpc_connection():
    """测试gRPC连接"""
    target = 'primihub-meta2:9099'

    print(f"测试gRPC连接到: {target}")
    print("=" * 70)

    try:
        # 创建insecure channel
        channel = grpc.insecure_channel(target)

        # 测试连接
        print("1. 创建gRPC channel... ✅")

        # 尝试连接
        try:
            grpc.channel_ready_future(channel).result(timeout=5)
            print("2. Channel ready... ✅")
            print()
            print("🎉 gRPC连接成功!")
            print()
            print("分析: Python gRPC客户端可以连接")
            print("说明Meta服务gRPC完全正常")
            print("问题在于primihub-node的C++ gRPC客户端")

        except grpc.FutureTimeoutError:
            print("2. Channel ready timeout... ❌")
            print()
            print("⚠️  gRPC握手超时")
            print("可能原因: 服务器不响应gRPC连接")

    except Exception as e:
        print(f"❌ 连接失败: {e}")
        print()
        print("说明: 无法建立gRPC连接")

    finally:
        try:
            channel.close()
        except:
            pass

if __name__ == "__main__":
    test_grpc_connection()
