#!/usr/bin/env python3
"""Real Device P2P LAN Synchronization Test Harness.

Tests bidirectional synchronization integrity of all shared household
entities between two physical Android devices connected via ADB.

Usage:
    python3 scripts/test_real_device_sync.py
    python3 scripts/test_real_device_sync.py --dev1 <serial1> --dev2 <serial2>
    python3 scripts/test_real_device_sync.py --install
"""

import argparse
import os
import re
import sqlite3
import subprocess
import sys
import tempfile
import time
import uuid
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

PACKAGE_NAME = "br.com.innominata.mysweethome"
APK_PATH = "build/app/outputs/flutter-apk/app-debug.apk"
DB_REL_PATH = "app_flutter/my_sweet_home.db"


def run_cmd(cmd, check=True, capture=True):
    res = subprocess.run(cmd, shell=True, capture_output=capture, text=True)
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed ({res.returncode}): {cmd}\n{res.stderr}")
    return res


def get_connected_devices():
    out = run_cmd("adb devices").stdout
    devices = []
    for line in out.strip().split("\n")[1:]:
        parts = line.strip().split()
        if len(parts) >= 2 and parts[1] == "device":
            devices.append(parts[0])
    return devices


def get_device_model(device_id):
    try:
        res = run_cmd(f'adb -s "{device_id}" shell getprop ro.product.model', check=False)
        return res.stdout.strip()
    except Exception:
        return "Unknown"


def install_apk(device_id):
    print(f"[*] Installing APK on device {device_id}...")
    run_cmd(f'adb -s "{device_id}" push "{APK_PATH}" /data/local/tmp/app.apk')
    res = run_cmd(f'adb -s "{device_id}" shell pm install -r --user 0 /data/local/tmp/app.apk', check=False)
    if "Success" not in res.stdout:
        run_cmd(f'adb -s "{device_id}" shell pm install -r /data/local/tmp/app.apk')
    print(f"[+] APK installed on {device_id}")


def pull_db(device_id, local_path):
    with open(local_path, "wb") as f:
        subprocess.run(
            ["adb", "-s", device_id, "exec-out", "run-as", PACKAGE_NAME, "cat", DB_REL_PATH],
            stdout=f,
            check=True,
        )


def push_db_safe(device_id, local_path):
    # Stop process to avoid conflicts with SQLite journal/WAL
    run_cmd(f'adb -s "{device_id}" shell am force-stop {PACKAGE_NAME}')
    time.sleep(1)

    subprocess.run(
        ["adb", "-s", device_id, "push", local_path, "/data/local/tmp/app_temp.db"],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    subprocess.run(
        ["adb", "-s", device_id, "shell", f"run-as {PACKAGE_NAME} cp /data/local/tmp/app_temp.db {DB_REL_PATH}"],
        check=True,
        shell=True,
        stdout=subprocess.DEVNULL,
    )
    subprocess.run(
        ["adb", "-s", device_id, "shell", f"run-as {PACKAGE_NAME} rm -f {DB_REL_PATH}-shm {DB_REL_PATH}-wal"],
        check=False,
        shell=True,
        stdout=subprocess.DEVNULL,
    )


def start_app(device_id):
    run_cmd(f'adb -s "{device_id}" shell monkey -p {PACKAGE_NAME} 1')
    time.sleep(2)


def clean_test_data(db_path):
    """Removes previous test records while preserving household settings."""
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    tables = [
        'shopping_items', 'recipe_ingredients', 'stock_items',
        'purchase_items', 'expenses', 'budgets', 'tasks', 'recipes',
        'shopping_lists', 'stores', 'products', 'categories',
        'bills', 'checklist_items'
    ]
    for tbl in tables:
        try:
            cur.execute(
                f"DELETE FROM {tbl} WHERE id LIKE 'test_%' OR id LIKE 'cat_%' "
                f"OR id LIKE 'prod_%' OR id LIKE 'store_%' OR id LIKE 'list_%' "
                f"OR id LIKE 'sitem_%' OR id LIKE 'task_%' OR id LIKE 'rec_%' "
                f"OR id LIKE 'stock_%' OR id LIKE 'bill_%' OR id LIKE 'exp_%' "
                f"OR id LIKE 'bgt_%' OR id LIKE 'chk_%'"
            )
        except Exception:
            pass
    try:
        cur.execute(
            "DELETE FROM sync_column_versions WHERE row_id LIKE 'test_%' "
            "OR row_id LIKE 'cat_%' OR row_id LIKE 'prod_%' OR row_id LIKE 'store_%' "
            "OR row_id LIKE 'list_%' OR row_id LIKE 'sitem_%' OR row_id LIKE 'task_%' "
            "OR row_id LIKE 'rec_%' OR row_id LIKE 'stock_%' OR row_id LIKE 'bill_%' "
            "OR row_id LIKE 'exp_%' OR row_id LIKE 'bgt_%' OR row_id LIKE 'chk_%'"
        )
    except Exception:
        pass
    conn.commit()
    conn.close()


def navigate_and_sync(device_id):
    """Dynamically navigates from any screen to Shared Household and triggers sync."""
    for attempt in range(6):
        subprocess.run(["adb", "-s", device_id, "shell", "uiautomator dump /data/local/tmp/nav.xml"], check=False)
        xml_bytes = subprocess.run(
            ["adb", "-s", device_id, "exec-out", "cat", "/data/local/tmp/nav.xml"],
            capture_output=True,
        ).stdout
        try:
            root = ET.fromstring(xml_bytes)
        except Exception:
            time.sleep(1)
            continue

        # 1. If already on the screen and sync button exists, tap and finish
        for n in root.iter():
            desc = n.attrib.get("content-desc", "")
            text = n.attrib.get("text", "")
            if (
                "Sincronizar agora" in desc
                or "Sync now" in desc
                or "Sincronizar agora" in text
                or "Sync now" in text
            ):
                m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.attrib.get("bounds", ""))
                if m:
                    cx = (int(m.group(1)) + int(m.group(3))) // 2
                    cy = (int(m.group(2)) + int(m.group(4))) // 2
                    subprocess.run(["adb", "-s", device_id, "shell", f"input tap {cx} {cy}"])
                    print(f"[+] Triggered sync on {device_id} ({cx}, {cy})")
                    # Wait 1.2s and capture visual sync feedback
                    time.sleep(1.2)
                    subprocess.run(
                        ["adb", "-s", device_id, "shell", "uiautomator dump /data/local/tmp/feedback.xml"],
                        check=False,
                    )
                    fb_bytes = subprocess.run(
                        ["adb", "-s", device_id, "exec-out", "cat", "/data/local/tmp/feedback.xml"],
                        capture_output=True,
                    ).stdout
                    try:
                        fb_root = ET.fromstring(fb_bytes)
                        for fbn in fb_root.iter():
                            fbd = fbn.attrib.get("content-desc", "") or fbn.attrib.get("text", "")
                            if any(w in fbd.lower() for w in ["sync", "sincroniz", "peer", "device"]):
                                print(f"    [UI Feedback on {device_id}]: {fbd.strip()}")
                                break
                    except Exception:
                        pass
                    return True

        # 2. If 'Casa compartilhada' or 'Shared household' is present, tap to enter
        found_casa = False
        for n in root.iter():
            desc = n.attrib.get("content-desc", "")
            text = n.attrib.get("text", "")
            if (
                "Casa compartilhada" in desc
                or "Shared household" in desc
                or "Casa compartilhada" in text
                or "Shared household" in text
            ):
                m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.attrib.get("bounds", ""))
                if m:
                    cx = (int(m.group(1)) + int(m.group(3))) // 2
                    cy = (int(m.group(2)) + int(m.group(4))) // 2
                    subprocess.run(["adb", "-s", device_id, "shell", f"input tap {cx} {cy}"])
                    found_casa = True
                    time.sleep(1.5)
                    break
        if found_casa:
            continue

        # 3. If 'Ajustes' or 'Settings' is present, tap to open settings
        found_ajustes = False
        for n in root.iter():
            desc = n.attrib.get("content-desc", "")
            text = n.attrib.get("text", "")
            if "Ajustes" in desc or "Settings" in desc or "Ajustes" in text or "Settings" in text:
                m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.attrib.get("bounds", ""))
                if m:
                    cx = (int(m.group(1)) + int(m.group(3))) // 2
                    cy = (int(m.group(2)) + int(m.group(4))) // 2
                    subprocess.run(["adb", "-s", device_id, "shell", f"input tap {cx} {cy}"])
                    found_ajustes = True
                    time.sleep(1.5)
                    break
        if found_ajustes:
            continue

        # 4. If a dialog is open, attempt to dismiss/cancel
        for n in root.iter():
            desc = n.attrib.get("content-desc", "")
            text = n.attrib.get("text", "")
            if "Cancelar" in desc or "Cancel" in desc or "Cancelar" in text or "Cancel" in text:
                m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.attrib.get("bounds", ""))
                if m:
                    cx = (int(m.group(1)) + int(m.group(3))) // 2
                    cy = (int(m.group(2)) + int(m.group(4))) // 2
                    subprocess.run(["adb", "-s", device_id, "shell", f"input tap {cx} {cy}"])
                    time.sleep(1)
                    break

        time.sleep(1)

    return False


def get_active_household(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("SELECT id, name FROM sync_household WHERE active = 1 ORDER BY joined_at DESC LIMIT 1")
    row = cur.fetchone()
    conn.close()
    return row


def ensure_sync_triggers_active(conn):
    cur = conn.cursor()
    cur.execute("DELETE FROM settings WHERE key = 'sync_applying_remote'")
    conn.commit()


def main():
    parser = argparse.ArgumentParser(description="P2P LAN sync test harness for physical Android devices")
    parser.add_argument("--dev1", help="ADB serial for Device 1")
    parser.add_argument("--dev2", help="ADB serial for Device 2")
    parser.add_argument("--install", action="store_true", help="Reinstall APK on both devices")
    args = parser.parse_args()

    devices = get_connected_devices()
    if len(devices) < 2:
        print(f"[!] Error: At least 2 devices connected via ADB are required. Found: {devices}")
        sys.exit(1)

    dev1 = args.dev1 or devices[0]
    dev2 = args.dev2 or devices[1]

    model1 = get_device_model(dev1)
    model2 = get_device_model(dev2)

    print("=== P2P REAL DEVICE SYNCHRONIZATION TEST ===")
    print(f"Device 1: {dev1} ({model1})")
    print(f"Device 2: {dev2} ({model2})")

    if args.install:
        install_apk(dev1)
        install_apk(dev2)

    temp_dir = tempfile.mkdtemp(prefix="msh_sync_test_")
    db1_path = os.path.join(temp_dir, "dev1.db")
    db2_path = os.path.join(temp_dir, "dev2.db")

    print("[*] Pulling databases to verify shared household...")
    pull_db(dev1, db1_path)
    pull_db(dev2, db2_path)

    h1 = get_active_household(db1_path)
    h2 = get_active_household(db2_path)

    if not h1 or not h2:
        print(f"[!] Error: Device has no active household. Dev1: {h1}, Dev2: {h2}")
        sys.exit(1)

    if h1[0] != h2[0]:
        print(f"[!] Warning: Household IDs differ! Dev1: {h1[0]} vs Dev2: {h2[0]}. Devices must be in the same household.")
        sys.exit(1)

    household_id = h1[0]
    print(f"[+] Both connected to household: '{h1[1]}' (ID: {household_id})")

    test_specs = [
        {
            "name": "Product Categories (categories)",
            "origin": 1,
            "table": "categories",
            "insert_sql": """
                INSERT INTO categories (id, name, kind, icon_key, color_hex, is_system, sort_order)
                VALUES (?, ?, 'both', 'tag', '#4CAF50', 0, 99)
            """,
            "make_params": lambda uid, now: (
                f"cat_{uid}",
                f"Category {uid[:6]}",
            ),
            "check_sql": "SELECT id, name, kind FROM categories WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] == "both",
        },
        {
            "name": "Catalog Products (products)",
            "origin": 1,
            "table": "products",
            "insert_sql": """
                INSERT INTO products (id, canonical_name, category_id, default_unit, package_size_milli, is_archived, created_at, updated_at)
                VALUES (?, ?, ?, 'un', 1000, 0, ?, ?)
            """,
            "make_params": lambda uid, now: (
                f"prod_{uid}",
                f"Test Product {uid[:6]}",
                f"cat_{uid}",
                now,
                now,
            ),
            "check_sql": "SELECT id, canonical_name, created_at FROM products WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] is not None,
        },
        {
            "name": "Stores / Establishments (stores)",
            "origin": 2,
            "table": "stores",
            "insert_sql": """
                INSERT INTO stores (id, name, address, created_at, updated_at)
                VALUES (?, ?, '123 Test Street', ?, ?)
            """,
            "make_params": lambda uid, now: (
                f"store_{uid}",
                f"Supermarket {uid[:6]}",
                now,
                now,
            ),
            "check_sql": "SELECT id, name, created_at FROM stores WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] is not None,
        },
        {
            "name": "Shopping Lists (shopping_lists)",
            "origin": 2,
            "table": "shopping_lists",
            "insert_sql": """
                INSERT INTO shopping_lists (id, name, is_archived, created_at, updated_at)
                VALUES (?, ?, 0, ?, ?)
            """,
            "make_params": lambda uid, now: (
                f"list_{uid}",
                f"Market List {uid[:6]}",
                now,
                now,
            ),
            "check_sql": "SELECT id, name, created_at FROM shopping_lists WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] is not None,
        },
        {
            "name": "Shopping Items (shopping_items)",
            "origin": 2,
            "table": "shopping_items",
            "insert_sql": """
                INSERT INTO shopping_items (id, list_id, free_text, quantity_milli, unit, position, is_checked, source)
                VALUES (?, ?, ?, 2000, 'un', 0, 0, 'manual')
            """,
            "make_params": lambda uid, now: (
                f"sitem_{uid}",
                f"list_{uid}",
                f"Test Item {uid[:6]}",
            ),
            "check_sql": "SELECT id, free_text, quantity_milli FROM shopping_items WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] == 2000,
        },
        {
            "name": "Household Tasks (tasks)",
            "origin": 1,
            "table": "tasks",
            "insert_sql": """
                INSERT INTO tasks (id, title, notes, due_at, all_day, is_completed, created_at, updated_at, sync_state)
                VALUES (?, ?, ?, ?, 1, 0, ?, ?, 'synced')
            """,
            "make_params": lambda uid, now: (
                f"task_{uid}",
                f"Test Task {uid[:6]}",
                "Automated notes",
                now,
                now,
                now,
            ),
            "check_sql": "SELECT id, title, created_at, updated_at FROM tasks WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] is not None and row[3] is not None,
        },
        {
            "name": "Culinary Recipes (recipes)",
            "origin": 1,
            "table": "recipes",
            "insert_sql": """
                INSERT INTO recipes (id, title, instructions, prep_minutes, servings, is_favorite, created_at, updated_at)
                VALUES (?, ?, 'Mix ingredients and bake for 30 minutes', 45, 4, 1, ?, ?)
            """,
            "make_params": lambda uid, now: (
                f"rec_{uid}",
                f"Carrot Cake {uid[:6]}",
                now,
                now,
            ),
            "check_sql": "SELECT id, title, created_at FROM recipes WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] is not None,
        },
        {
            "name": "Stock / Pantry Items (stock_items)",
            "origin": 2,
            "table": "stock_items",
            "insert_sql": """
                INSERT INTO stock_items (id, product_id, quantity_milli, unit, low_stock_threshold_milli, created_at, updated_at)
                VALUES (?, ?, 3000, 'un', 1000, ?, ?)
            """,
            "make_params": lambda uid, now: (
                f"stock_{uid}",
                f"prod_{uid}",
                now,
                now,
            ),
            "check_sql": "SELECT id, quantity_milli, created_at FROM stock_items WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[1] == 3000,
        },
        {
            "name": "Recurring Bills (bills)",
            "origin": 1,
            "table": "bills",
            "insert_sql": """
                INSERT INTO bills (id, title, amount_cents, is_amount_variable, due_day, reminder_days_before, is_active)
                VALUES (?, ?, 12500, 0, 15, 3, 1)
            """,
            "make_params": lambda uid, now: (
                f"bill_{uid}",
                f"Fiber Internet {uid[:6]}",
            ),
            "check_sql": "SELECT id, title, amount_cents FROM bills WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] == 12500,
        },
        {
            "name": "Financial Expenses (expenses)",
            "origin": 2,
            "table": "expenses",
            "insert_sql": """
                INSERT INTO expenses (id, description, amount_cents, occurred_on, created_at, updated_at)
                VALUES (?, ?, 4590, ?, ?, ?)
            """,
            "make_params": lambda uid, now: (
                f"exp_{uid}",
                f"Lunch {uid[:6]}",
                now[:10],
                now,
                now,
            ),
            "check_sql": "SELECT id, description, amount_cents, created_at FROM expenses WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] == 4590,
        },
        {
            "name": "Monthly Budgets (budgets)",
            "origin": 1,
            "table": "budgets",
            "insert_sql": """
                INSERT INTO budgets (id, year_month, category_id, limit_cents, base_income_cents, extra_income_cents)
                VALUES (?, ?, ?, 250000, 0, 0)
            """,
            "make_params": lambda uid, now: (
                f"bgt_{uid}",
                now[:7],
                f"cat_{uid}",
            ),
            "check_sql": "SELECT id, year_month, limit_cents FROM budgets WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] == 250000,
        },
        {
            "name": "Household Checklist (checklist_items)",
            "origin": 2,
            "table": "checklist_items",
            "insert_sql": """
                INSERT INTO checklist_items (id, title, room_category, is_marked, position, created_at, updated_at)
                VALUES (?, ?, 'kitchen', 0, 1, ?, ?)
            """,
            "make_params": lambda uid, now: (
                f"chk_{uid}",
                f"Organizer Bin {uid[:6]}",
                now,
                now,
            ),
            "check_sql": "SELECT id, title, room_category, created_at FROM checklist_items WHERE id = ?",
            "get_id": lambda params: params[0],
            "validate": lambda row: row is not None and row[2] == "kitchen",
        },
    ]

    shared_uid = uuid.uuid4().hex[:8]
    now_iso = datetime.now(timezone.utc).isoformat()

    print("[*] Cleaning up previous test data in databases...")
    clean_test_data(db1_path)
    clean_test_data(db2_path)

    print(f"\n[*] Preparing test data (unique UID: {shared_uid})...")
    conn1 = sqlite3.connect(db1_path)
    conn2 = sqlite3.connect(db2_path)
    ensure_sync_triggers_active(conn1)
    ensure_sync_triggers_active(conn2)

    inserted_items = []

    # Apply insertions respecting foreign keys and triggering local SQLite triggers
    for spec in test_specs:
        target_conn = conn1 if spec["origin"] == 1 else conn2
        src_dev_name = model1 if spec["origin"] == 1 else model2
        dest_dev_name = model2 if spec["origin"] == 1 else model1

        params = spec["make_params"](shared_uid, now_iso)
        item_id = spec["get_id"](params)

        target_conn.execute(spec["insert_sql"], params)
        inserted_items.append((spec, item_id, src_dev_name, dest_dev_name))

    conn1.commit()
    conn2.commit()
    conn1.close()
    conn2.close()

    print("[*] Pushing databases to physical devices (safe mode with force-stop)...")
    push_db_safe(dev1, db1_path)
    push_db_safe(dev2, db2_path)

    print("[*] Starting applications on devices...")
    start_app(dev1)
    start_app(dev2)

    print("[*] Navigating and triggering sync on Device 1...")
    navigate_and_sync(dev1)
    time.sleep(2)

    print("[*] Navigating and triggering sync on Device 2...")
    navigate_and_sync(dev2)

    print("[*] Waiting 7 seconds for P2P transmission and persistence...")
    time.sleep(7)

    print("[*] Pulling updated databases after synchronization for validation...")
    db1_after = os.path.join(temp_dir, "dev1_after.db")
    db2_after = os.path.join(temp_dir, "dev2_after.db")
    pull_db(dev1, db1_after)
    pull_db(dev2, db2_after)

    conn1_after = sqlite3.connect(db1_after)
    conn2_after = sqlite3.connect(db2_after)

    print("\n" + "=" * 75)
    print(f"{'ENTITY':<38} | {'ROUTE (SRC -> DEST)':<23} | {'STATUS'}")
    print("=" * 75)

    all_passed = True
    for spec, item_id, src_name, dest_name in inserted_items:
        check_conn = conn2_after if spec["origin"] == 1 else conn1_after
        cur = check_conn.cursor()
        cur.execute(spec["check_sql"], (item_id,))
        row = cur.fetchone()

        passed = spec["validate"](row)
        if not passed:
            all_passed = False
            status = "FAILED [X]"
        else:
            status = "PASSED [OK]"

        route = f"{src_name[:10]} -> {dest_name[:10]}"
        print(f"{spec['name']:<38} | {route:<23} | {status}")

    conn1_after.close()
    conn2_after.close()

    print("=" * 75)
    if all_passed:
        print("[TOTAL SUCCESS] All 12 entities synchronized bidirectionally!")
    else:
        print("[!] Some entities failed to synchronize.")
        sys.exit(1)


if __name__ == "__main__":
    main()
