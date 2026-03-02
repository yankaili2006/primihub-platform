#!/usr/bin/env python3
import pymysql

# Connect to MySQL
conn = pymysql.connect(
    host='100.64.0.23',
    port=30811,
    user='root',
    password='primihub123',
    database='primihub_meta',
    charset='utf8mb4'
)

try:
    with conn.cursor() as cursor:
        # Query organ info
        sql = "SELECT id, organ_id, organ_name, gateway, public_key, examine_state, enable, apply_id FROM sys_organ_info"
        cursor.execute(sql)
        results = cursor.fetchall()

        print("=" * 120)
        print("机构信息 (sys_organ_info)")
        print("=" * 120)
        print(f"{'ID':<5} {'Organ ID':<35} {'Organ Name':<20} {'Gateway':<30} {'Public Key':<15} {'Examine':<8} {'Enable':<7} {'Apply ID':<10}")
        print("-" * 120)

        for row in results:
            id_val, organ_id, organ_name, gateway, public_key, examine_state, enable, apply_id = row
            pk_display = (public_key[:12] + "..." if public_key and len(public_key) > 12 else (public_key or "NULL"))
            gateway_display = (gateway[:28] + "..." if gateway and len(gateway) > 28 else (gateway or "NULL"))
            print(f"{id_val:<5} {organ_id:<35} {organ_name:<20} {gateway_display:<30} {pk_display:<15} {examine_state:<8} {enable:<7} {str(apply_id) if apply_id else 'NULL':<10}")

        print("\n")

        # Query local organ info
        sql2 = "SELECT organ_id, organ_name, gateway_address, public_key FROM sys_local_organ_info"
        cursor.execute(sql2)
        local_results = cursor.fetchall()

        print("=" * 120)
        print("本地机构信息 (sys_local_organ_info)")
        print("=" * 120)
        print(f"{'Organ ID':<35} {'Organ Name':<20} {'Gateway Address':<40} {'Public Key':<15}")
        print("-" * 120)

        for row in local_results:
            organ_id, organ_name, gateway_addr, public_key = row
            pk_display = (public_key[:12] + "..." if public_key and len(public_key) > 12 else (public_key or "NULL"))
            print(f"{organ_id:<35} {organ_name:<20} {gateway_addr:<40} {pk_display:<15}")

finally:
    conn.close()
