import json
import socket
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4
import time
import random


HOST = "127.0.0.1"
PORT = 8888

APP_DIR = Path(__file__).resolve().parent
DATA_DIR = APP_DIR / "data"
LOG_PATH = DATA_DIR / "logs.jsonl"

attempt_counter = defaultdict(int)
BLOCK_THRESHOLD = 3


def append_log(entry: dict) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=True) + "\n")


print("Cyber Deception Honeypot running...")
print(f"Listening on {HOST}:{PORT}")

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((HOST, PORT))
server.listen(10)

while True:
    conn, addr = server.accept()
    ip = addr[0]
    data = conn.recv(2048).decode(errors="ignore").strip()
    conn.close()

    attempt_counter[ip] += 1

    severity = "LOW"
    attack_type = "Weak Credential Attempt"
    if "admin" in data or "root" in data:
        attack_type = "Default Credential Attack"
        severity = "CRITICAL"
    elif attempt_counter[ip] >= BLOCK_THRESHOLD:
        attack_type = "Brute Force Simulation"
        severity = "HIGH"

    actor_name = f"intruder-{format((int(time.time()*1000) ^ random.randint(0, 1_000_000)) & 0xFFFFF, 'x')}"
    event = {
        "id": str(uuid4()),
        "ts": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "title": attack_type,
        "severity": severity,
        "source": "simulator",
        "actor": {"username": actor_name, "family": "intruder"},
        "ip": ip,
        "details": {"raw": data, "attempts_from_ip": attempt_counter[ip]},
    }
    append_log(event)

    if attempt_counter[ip] >= BLOCK_THRESHOLD:
        print(f"[BLOCKED] {ip} temporarily blocked (simulation)")
    print(f"[{severity}] {event['ts']} {ip} {attack_type} | {data}")
