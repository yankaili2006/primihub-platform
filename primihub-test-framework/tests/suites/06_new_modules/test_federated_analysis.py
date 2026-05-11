#!/usr/bin/env python3
"""联邦分析功能测试"""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../lib'))
from api_client import PrimiHubAPIClient
from report_generator import TestReport

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:30811/prod-api/")
ADMIN_USER = os.environ.get("ADMIN_USER", "admin")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "123456")

class FederatedAnalysisTest:
    def __init__(self):
        self.client = PrimiHubAPIClient(BASE_URL)
        self.report = TestReport()
        self.task_id = None
        self.datasource_id = None

    def run(self):
        print("\n" + "="*60)
        print("联邦分析功能测试".center(60))
        print("="*60)
        try:
            self.test_login()
            self.test_sql_validate()
            self.test_sql_format()
            self.test_sql_functions()
            self.test_create_task()
            self.test_task_list()
            self.test_task_detail()
            self.test_run_task()
            self.test_stop_task()
            self.test_datasource_crud()
            self.test_platform_types()
            self.generate_report()
        except Exception as e:
            print(f"\n错误: {e}")
            import traceback; traceback.print_exc()
        finally:
            try: self.client.logout()
            except: pass

    def test_login(self):
        s = time.time()
        r = self.client.login(ADMIN_USER, ADMIN_PASSWORD)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦分析", "登录", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 登录")

    def test_sql_validate(self):
        s = time.time()
        r = self.client.validate_sql({"sql": "SELECT id, name FROM user WHERE age > 18", "dataResources": []})
        ok = r.get('code') == 0
        self.report.add_test_result("联邦分析", "SQL验证", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} SQL验证")

    def test_sql_format(self):
        s = time.time()
        r = self.client.format_sql({"sql": "select id,name from user where age>18"})
        ok = r.get('code') == 0
        formatted = r.get('result', {}).get('formattedSql', '')
        self.report.add_test_result("联邦分析", "SQL格式化", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} SQL格式化")

    def test_sql_functions(self):
        s = time.time()
        r = self.client.get_sql_functions()
        ok = r.get('code') == 0
        funcs = r.get('result', [])
        self.report.add_test_result("联邦分析", "SQL函数列表", "passed" if ok else "failed", time.time()-s)
        count = len(funcs) if funcs else 0
        print(f"{'✅' if ok else '❌'} SQL函数列表 ({count}个)")

    def test_create_task(self):
        s = time.time()
        data = {
            "taskName": f"分析任务测试_{int(time.time())}",
            "sourceSql": "SELECT id, name, age FROM user WHERE age > 18",
            "projectId": 1
        }
        r = self.client.create_analysis_task(data)
        ok = r.get('code') == 0
        if ok:
            self.task_id = r.get('result', {}).get('taskId')
        self.report.add_test_result("联邦分析", "创建任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 创建任务 (ID: {self.task_id})")

    def test_task_list(self):
        s = time.time()
        r = self.client.get_analysis_task_list()
        ok = r.get('code') == 0
        count = len(r.get('result', {}).get('list', []))
        self.report.add_test_result("联邦分析", "任务列表", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 任务列表 ({count}条)")

    def test_task_detail(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.get_analysis_task_detail(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦分析", "任务详情", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 任务详情")

    def test_run_task(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.run_analysis_task(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦分析", "执行任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 执行任务")

    def test_stop_task(self):
        if not self.task_id: return
        s = time.time()
        r = self.client.stop_analysis_task(self.task_id)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦分析", "停止任务", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 停止任务")

    def test_datasource_crud(self):
        s = time.time()
        ds_data = {
            "sourceName": f"测试数据源_{int(time.time())}",
            "sourceType": "MySQL",
            "host": "localhost",
            "port": 3306,
            "databaseName": "test_db",
            "username": "root",
            "password": "password"
        }
        r = self.client.create_analysis_datasource(ds_data)
        ok = r.get('code') == 0
        self.report.add_test_result("联邦分析", "创建数据源", "passed" if ok else "failed", time.time()-s)
        print(f"{'✅' if ok else '❌'} 创建数据源")

        s2 = time.time()
        r2 = self.client.get_analysis_datasource_list()
        ok2 = r2.get('code') == 0
        self.report.add_test_result("联邦分析", "数据源列表", "passed" if ok2 else "failed", time.time()-s2)
        sources = r2.get('result', [])
        if sources:
            self.datasource_id = sources[0].get('id')
        print(f"{'✅' if ok2 else '❌'} 数据源列表 ({len(sources) if sources else 0}个)")

        if self.datasource_id:
            r3 = self.client.test_analysis_datasource(ds_data)
            ok3 = r3.get('code') == 0
            self.report.add_test_result("联邦分析", "测试数据源", "passed" if ok3 else "failed", time.time()-s2)
            print(f"{'✅' if ok3 else '❌'} 测试数据源")

            r4 = self.client.delete_analysis_datasource(self.datasource_id)
            ok4 = r4.get('code') == 0
            self.report.add_test_result("联邦分析", "删除数据源", "passed" if ok4 else "failed", time.time()-s2)
            print(f"{'✅' if ok4 else '❌'} 删除数据源")

    def test_platform_types(self):
        for label, method in [("RDBMS", self.client.get_rdbms_types),
                               ("BigData", self.client.get_bigdata_types),
                               ("Cloud", self.client.get_cloud_types)]:
            s = time.time()
            r = method()
            ok = r.get('code') == 0
            types = r.get('result', [])
            self.report.add_test_result("联邦分析", f"{label}类型列表", "passed" if ok else "failed", time.time()-s)
            print(f"{'✅' if ok else '❌'} {label}类型 ({len(types) if types else 0}个)")

    def generate_report(self):
        d = os.path.join(os.path.dirname(__file__), '../../reports')
        os.makedirs(d, exist_ok=True)
        t = time.strftime('%Y%m%d_%H%M%S')
        self.report.generate_html_report(os.path.join(d, f'federated_analysis_test_{t}.html'))
        self.report.print_summary()

if __name__ == "__main__":
    import logging; logging.basicConfig(level=logging.INFO)
    FederatedAnalysisTest().run()
