import subprocess
import os
import sys
import time
import webbrowser
from pathlib import Path
import socket


print("Starting project (honeypot + web dashboard)...")

app_dir = Path(__file__).resolve().parent
log_path = app_dir / "data" / "logs.jsonl"
if log_path.exists():
    try:
        log_path.unlink()
        print("Cleared previous logs: data/logs.jsonl")
    except Exception as e:
        print("Warning: could not clear previous logs:", e)

subprocess.Popen([sys.executable, "honeypot.py"])
time.sleep(0.8)

def _port_free(port: int) -> bool:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(("127.0.0.1", port))
        return True
    except OSError:
        return False


port = 5000
for candidate in range(5000, 5011):
    if _port_free(candidate):
        port = candidate
        break

try:
    env = os.environ.copy()
except Exception:
    env = {}
env["PORT"] = str(port)

subprocess.Popen([sys.executable, "app.py"], env=env)
time.sleep(1.2)

webbrowser.open(f"http://127.0.0.1:{port}/login")
print(f"Running at http://127.0.0.1:{port}")
