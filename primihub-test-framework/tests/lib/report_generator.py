#!/usr/bin/env python3
"""
Test Report Generator
测试报告生成器

支持生成多种格式的测试报告：
- JSON: 结构化数据，便于解析
- HTML: 可视化报告，便于查看
- Markdown: 文本报告，便于分享
"""

import json
import os
from datetime import datetime, timedelta
from typing import List, Dict, Any
from pathlib import Path


class TestReport:
    """测试报告类"""

    def __init__(self):
        """初始化测试报告"""
        self.start_time = datetime.now()
        self.end_time = None
        self.test_results = []
        self.summary = {
            'total': 0,
            'passed': 0,
            'failed': 0,
            'skipped': 0,
            'error': 0
        }

    def add_test_result(self, suite: str, test_name: str, status: str,
                       duration: float, error_msg: str = None,
                       details: Dict = None):
        """
        添加测试结果

        Args:
            suite: 测试套件名称
            test_name: 测试用例名称
            status: 测试状态 (passed, failed, skipped, error)
            duration: 执行时间（秒）
            error_msg: 错误信息（可选）
            details: 额外详情（可选）
        """
        result = {
            'suite': suite,
            'test_name': test_name,
            'status': status,
            'duration': duration,
            'error_msg': error_msg,
            'details': details,
            'timestamp': datetime.now().isoformat()
        }

        self.test_results.append(result)

        # 更新统计
        self.summary['total'] += 1
        if status == 'passed':
            self.summary['passed'] += 1
        elif status == 'failed':
            self.summary['failed'] += 1
        elif status == 'skipped':
            self.summary['skipped'] += 1
        elif status == 'error':
            self.summary['error'] += 1

    def finalize(self):
        """完成报告，计算总执行时间"""
        self.end_time = datetime.now()

    def get_duration(self) -> float:
        """获取总执行时间（秒）"""
        if self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        return 0

    def get_pass_rate(self) -> float:
        """计算通过率"""
        if self.summary['total'] == 0:
            return 0.0
        return (self.summary['passed'] / self.summary['total']) * 100

    def generate_json_report(self, output_file: str):
        """
        生成JSON格式报告

        Args:
            output_file: 输出文件路径
        """
        if not self.end_time:
            self.finalize()

        report_data = {
            'summary': {
                **self.summary,
                'pass_rate': f"{self.get_pass_rate():.2f}%",
                'total_duration': self.get_duration(),
                'start_time': self.start_time.isoformat(),
                'end_time': self.end_time.isoformat()
            },
            'test_results': self.test_results
        }

        # 确保输出目录存在
        os.makedirs(os.path.dirname(output_file) if os.path.dirname(output_file) else '.', exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)

        print(f"JSON报告已生成: {output_file}")

    def generate_html_report(self, output_file: str):
        """
        生成HTML格式报告

        Args:
            output_file: 输出文件路径
        """
        if not self.end_time:
            self.finalize()

        # HTML模板
        html_template = """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrimiHub测试报告</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        h1 {{
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
            margin-bottom: 30px;
        }}
        .summary {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }}
        .summary-card {{
            padding: 20px;
            border-radius: 5px;
            text-align: center;
        }}
        .summary-card.total {{ background: #2196F3; color: white; }}
        .summary-card.passed {{ background: #4CAF50; color: white; }}
        .summary-card.failed {{ background: #f44336; color: white; }}
        .summary-card.skipped {{ background: #FF9800; color: white; }}
        .summary-card.error {{ background: #9C27B0; color: white; }}
        .summary-card h3 {{
            font-size: 36px;
            margin-bottom: 5px;
        }}
        .summary-card p {{
            font-size: 14px;
            opacity: 0.9;
        }}
        .metrics {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
            padding: 20px;
            background: #f9f9f9;
            border-radius: 5px;
        }}
        .metric {{
            display: flex;
            justify-content: space-between;
            padding: 10px;
            background: white;
            border-radius: 3px;
        }}
        .metric-label {{
            font-weight: bold;
            color: #555;
        }}
        .metric-value {{
            color: #333;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }}
        th {{
            background: #4CAF50;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }}
        td {{
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }}
        tr:hover {{
            background: #f5f5f5;
        }}
        .status {{
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: bold;
        }}
        .status.passed {{ background: #4CAF50; color: white; }}
        .status.failed {{ background: #f44336; color: white; }}
        .status.skipped {{ background: #FF9800; color: white; }}
        .status.error {{ background: #9C27B0; color: white; }}
        .error-msg {{
            color: #f44336;
            font-size: 12px;
            margin-top: 5px;
        }}
        .progress-bar {{
            width: 100%;
            height: 30px;
            background: #e0e0e0;
            border-radius: 15px;
            overflow: hidden;
            margin: 20px 0;
        }}
        .progress-fill {{
            height: 100%;
            background: linear-gradient(90deg, #4CAF50, #45a049);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            transition: width 0.3s ease;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>PrimiHub 测试报告</h1>

        <div class="summary">
            <div class="summary-card total">
                <h3>{total}</h3>
                <p>总测试数</p>
            </div>
            <div class="summary-card passed">
                <h3>{passed}</h3>
                <p>通过</p>
            </div>
            <div class="summary-card failed">
                <h3>{failed}</h3>
                <p>失败</p>
            </div>
            <div class="summary-card skipped">
                <h3>{skipped}</h3>
                <p>跳过</p>
            </div>
            <div class="summary-card error">
                <h3>{error}</h3>
                <p>错误</p>
            </div>
        </div>

        <div class="progress-bar">
            <div class="progress-fill" style="width: {pass_rate}%">
                通过率: {pass_rate}%
            </div>
        </div>

        <div class="metrics">
            <div class="metric">
                <span class="metric-label">开始时间:</span>
                <span class="metric-value">{start_time}</span>
            </div>
            <div class="metric">
                <span class="metric-label">结束时间:</span>
                <span class="metric-value">{end_time}</span>
            </div>
            <div class="metric">
                <span class="metric-label">总耗时:</span>
                <span class="metric-value">{duration}</span>
            </div>
            <div class="metric">
                <span class="metric-label">通过率:</span>
                <span class="metric-value">{pass_rate}%</span>
            </div>
        </div>

        <h2>测试详情</h2>
        <table>
            <thead>
                <tr>
                    <th>测试套件</th>
                    <th>测试用例</th>
                    <th>状态</th>
                    <th>耗时(秒)</th>
                    <th>时间戳</th>
                </tr>
            </thead>
            <tbody>
                {test_rows}
            </tbody>
        </table>
    </div>
</body>
</html>
"""

        # 生成测试行HTML
        test_rows = []
        for result in self.test_results:
            error_html = ""
            if result['error_msg']:
                error_html = f"<div class='error-msg'>{result['error_msg']}</div>"

            row = f"""
                <tr>
                    <td>{result['suite']}</td>
                    <td>{result['test_name']}{error_html}</td>
                    <td><span class="status {result['status']}">{result['status'].upper()}</span></td>
                    <td>{result['duration']:.3f}</td>
                    <td>{result['timestamp']}</td>
                </tr>
            """
            test_rows.append(row)

        # 格式化时间
        duration_str = str(timedelta(seconds=int(self.get_duration())))

        # 填充模板
        html_content = html_template.format(
            total=self.summary['total'],
            passed=self.summary['passed'],
            failed=self.summary['failed'],
            skipped=self.summary['skipped'],
            error=self.summary['error'],
            pass_rate=f"{self.get_pass_rate():.2f}",
            start_time=self.start_time.strftime('%Y-%m-%d %H:%M:%S'),
            end_time=self.end_time.strftime('%Y-%m-%d %H:%M:%S'),
            duration=duration_str,
            test_rows=''.join(test_rows)
        )

        # 确保输出目录存在
        os.makedirs(os.path.dirname(output_file) if os.path.dirname(output_file) else '.', exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)

        print(f"HTML报告已生成: {output_file}")

    def generate_markdown_report(self, output_file: str):
        """
        生成Markdown格式报告

        Args:
            output_file: 输出文件路径
        """
        if not self.end_time:
            self.finalize()

        lines = [
            "# PrimiHub 测试报告",
            "",
            "## 测试摘要",
            "",
            f"- **总测试数**: {self.summary['total']}",
            f"- **通过**: {self.summary['passed']} ✅",
            f"- **失败**: {self.summary['failed']} ❌",
            f"- **跳过**: {self.summary['skipped']} ⏭️",
            f"- **错误**: {self.summary['error']} 🔥",
            f"- **通过率**: {self.get_pass_rate():.2f}%",
            "",
            "## 测试指标",
            "",
            f"- **开始时间**: {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}",
            f"- **结束时间**: {self.end_time.strftime('%Y-%m-%d %H:%M:%S')}",
            f"- **总耗时**: {str(timedelta(seconds=int(self.get_duration())))}",
            "",
            "## 测试详情",
            "",
            "| 测试套件 | 测试用例 | 状态 | 耗时(秒) | 时间戳 |",
            "|---------|---------|------|----------|--------|"
        ]

        for result in self.test_results:
            status_icon = {
                'passed': '✅',
                'failed': '❌',
                'skipped': '⏭️',
                'error': '🔥'
            }.get(result['status'], '❓')

            error_info = f" - {result['error_msg']}" if result['error_msg'] else ""

            lines.append(
                f"| {result['suite']} | {result['test_name']}{error_info} | "
                f"{status_icon} {result['status']} | {result['duration']:.3f} | "
                f"{result['timestamp']} |"
            )

        # 确保输出目录存在
        os.makedirs(os.path.dirname(output_file) if os.path.dirname(output_file) else '.', exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))

        print(f"Markdown报告已生成: {output_file}")

    def print_summary(self):
        """打印测试摘要到控制台"""
        if not self.end_time:
            self.finalize()

        print("\n" + "="*60)
        print("测试摘要")
        print("="*60)
        print(f"总测试数: {self.summary['total']}")
        print(f"通过: {self.summary['passed']} ✅")
        print(f"失败: {self.summary['failed']} ❌")
        print(f"跳过: {self.summary['skipped']} ⏭️")
        print(f"错误: {self.summary['error']} 🔥")
        print(f"通过率: {self.get_pass_rate():.2f}%")
        print(f"总耗时: {str(timedelta(seconds=int(self.get_duration())))}")
        print("="*60 + "\n")


if __name__ == "__main__":
    # 示例用法
    report = TestReport()

    # 添加一些测试结果
    report.add_test_result("用户管理", "test_user_login", "passed", 0.5)
    report.add_test_result("用户管理", "test_user_create", "passed", 0.8)
    report.add_test_result("数据管理", "test_resource_upload", "failed", 1.2,
                          error_msg="连接超时")
    report.add_test_result("项目管理", "test_project_create", "passed", 0.6)
    report.add_test_result("隐私计算", "test_psi_task", "skipped", 0.0,
                          error_msg="测试数据不足")

    # 生成报告
    report.generate_json_report("./reports/test_report.json")
    report.generate_html_report("./reports/test_report.html")
    report.generate_markdown_report("./reports/test_report.md")
    report.print_summary()
