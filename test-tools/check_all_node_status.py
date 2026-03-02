#!/usr/bin/env python3
import pymysql

# Database configurations for all three nodes
databases = [
    {'name': 'Node 30811 (privacy1)', 'db': 'privacy1'},
    {'name': 'Node 30812 (privacy2)', 'db': 'privacy2'},
    {'name': 'Node 30813 (privacy3)', 'db': 'privacy3'},
]

print("=" * 120)
print("检查所有节点的 sys_organ 表状态")
print("=" * 120)

for db_config in databases:
    print(f"\n{'=' * 120}")
    print(f"{db_config['name']}")
    print(f"{'=' * 120}")

    try:
        conn = pymysql.connect(
            host='100.64.0.23',
            port=3306,
            user='root',
            password='root',
            database=db_config['db'],
            charset='utf8mb4'
        )

        with conn.cursor() as cursor:
            # Get all organs except local
            sql = """
                SELECT id, organ_id, organ_name, examine_state, enable,
                       node_state, fusion_state, platform_state, public_key
                FROM sys_organ
                WHERE organ_id != '100000000000000001'
                ORDER BY id
            """
            cursor.execute(sql)
            results = cursor.fetchall()

            if not results:
                print("  ⚠ 没有找到远程机构记录")
            else:
                print(f"  找到 {len(results)} 个远程机构:\n")
                for row in results:
                    id_val, organ_id, organ_name, examine_state, enable, node_state, fusion_state, platform_state, public_key = row
                    pk_display = (public_key[:20] + "..." if public_key and len(public_key) > 20 else (public_key or "NULL"))

                    print(f"  ID: {id_val}")
                    print(f"  机构ID: {organ_id}")
                    print(f"  机构名称: {organ_name}")
                    print(f"  审批状态 (examine_state): {examine_state} {'✓ 已批准' if examine_state == 1 else '✗ 未批准'}")
                    print(f"  启用状态 (enable): {enable} {'✓ 已启用' if enable == 1 else '✗ 未启用'}")
                    print(f"  节点状态 (node_state): {node_state} {'✓ 已连接' if node_state == 1 else '✗ 未连接'}")
                    print(f"  融合状态 (fusion_state): {fusion_state}")
                    print(f"  平台状态 (platform_state): {platform_state}")
                    print(f"  公钥: {pk_display}")
                    print()

            # Get statistics
            sql_stats = """
                SELECT
                    COUNT(*) as total,
                    SUM(CASE WHEN examine_state=1 THEN 1 ELSE 0 END) as approved,
                    SUM(CASE WHEN enable=1 THEN 1 ELSE 0 END) as enabled,
                    SUM(CASE WHEN node_state=1 THEN 1 ELSE 0 END) as node_connected
                FROM sys_organ
                WHERE organ_id != '100000000000000001'
            """
            cursor.execute(sql_stats)
            stats = cursor.fetchone()
            total, approved, enabled, node_connected = stats

            print(f"  统计: 总数={total}, 已批准={approved}, 已启用={enabled}, 节点已连接={node_connected}")

        conn.close()

    except Exception as e:
        print(f"  ✗ 错误: {e}")

print("\n" + "=" * 120)
print("检查完成")
print("=" * 120)
