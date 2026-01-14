#!/usr/bin/env python3
"""
PrimiHub 隐私计算功能快速测试
一键测试PSI、PIR和联邦学习的核心功能
"""
import subprocess
import sys
import time
from datetime import datetime

def print_banner(text):
    """打印横幅"""
    width = 80
    print("\n" + "="*width)
    print(f"{text:^{width}}")
    print("="*width + "\n")

def print_section(text):
    """打印章节"""
    print(f"\n{'─'*80}")
    print(f"▶ {text}")
    print(f"{'─'*80}\n")

def run_test(script_path, description, working_dir=None):
    """运行测试脚本"""
    print_section(description)
    print(f"脚本: {script_path}")
    print(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    try:
        cmd = ["python3", script_path]
        if working_dir:
            result = subprocess.run(
                cmd,
                cwd=working_dir,
                capture_output=True,
                text=True,
                timeout=60
            )
        else:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60
            )

        print(result.stdout)
        if result.stderr:
            print("错误输出:", result.stderr)

        if result.returncode == 0:
            print("\n✅ 测试通过")
            return True
        else:
            print(f"\n❌ 测试失败 (退出码: {result.returncode})")
            return False
    except subprocess.TimeoutExpired:
        print("\n⏰ 测试超时（60秒）")
        return False
    except Exception as e:
        print(f"\n❌ 测试异常: {e}")
        return False

def main():
    """主函数"""
    print_banner("🚀 PrimiHub 隐私计算功能快速测试")

    print("本测试将依次验证以下功能：")
    print("  1. PSI - 隐私集合求交（DH算法）")
    print("  2. PIR - 隐私信息检索")
    print("  3. 联邦学习 - 端到端测试")
    print("\n请确保PrimiHub平台已启动并运行正常。")

    response = input("\n是否继续测试？[y/N] ")
    if response.lower() != 'y':
        print("测试已取消")
        sys.exit(0)

    results = {}

    # 1. PSI测试
    print_banner("测试 1/3: PSI（隐私集合求交）")
    print("算法: DH (Diffie-Hellman 密钥交换)")
    print("说明: 在不泄露各方数据的前提下计算交集")

    time.sleep(2)

    psi_result = run_test(
        "psi/create_psi_dh.py",
        "创建PSI任务 - DH算法"
    )
    results['PSI'] = psi_result

    time.sleep(3)

    # 2. PIR测试
    print_banner("测试 2/3: PIR（隐私信息检索）")
    print("说明: 在不泄露查询内容的前提下检索信息")

    time.sleep(2)

    pir_result = run_test(
        "pir/create_pir_dh.py",
        "创建PIR任务 - DH算法"
    )
    results['PIR'] = pir_result

    time.sleep(3)

    # 3. 联邦学习测试
    print_banner("测试 3/3: 联邦学习")
    print("说明: 多方协作训练模型而不共享原始数据")
    print("注意: 联邦学习测试可能需要较长时间，此处仅创建项目")

    time.sleep(2)

    fl_result = run_test(
        "federated_learning/create_fl_project_complete.py",
        "创建联邦学习项目"
    )
    results['联邦学习'] = fl_result

    # 打印测试总结
    print_banner("📊 测试总结")

    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    total = len(results)
    passed = sum(1 for r in results.values() if r)

    print("测试结果:")
    for name, result in results.items():
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {name:12s}: {status}")

    print(f"\n总计: {passed}/{total} 个测试通过")

    if passed == total:
        print("\n🎉 恭喜！所有测试均通过！")
        print("\n接下来你可以：")
        print("  1. 查看详细文档: ~/primihub-platform/tests/README.md")
        print("  2. 运行PSI实时测试: cd psi && python3 test_psi_realtime.py dh")
        print("  3. 查看Web界面: http://192.168.99.5:30811")
        return 0
    else:
        print("\n⚠️  部分测试未通过，请检查：")
        print("  1. PrimiHub平台是否正常运行")
        print("  2. API端点配置是否正确")
        print("  3. 测试资源是否已创建")
        print("  4. 查看详细错误日志")
        return 1

if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n\n测试被用户中断")
        sys.exit(130)
    except Exception as e:
        print(f"\n\n❌ 测试过程中发生异常: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
