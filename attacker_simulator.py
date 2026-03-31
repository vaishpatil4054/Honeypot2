import random
import socket
import time


TARGET_IP = "127.0.0.1"
TARGET_PORT = 8888

usernames = [
    "admin",
    "root",
    "guest",
    "test",
    "user",
    "support",
    "sysadmin",
    "operator",
    "analyst",
]
passwords = [
    "123456",
    "password",
    "admin@123",
    "qwerty",
    "letmein",
    "welcome",
    "changeme",
    "iloveyou",
]

for _ in range(18):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.connect((TARGET_IP, TARGET_PORT))
        username = random.choice(usernames)
        password = random.choice(passwords)
        payload = f"username={username}, password={password}\n"
        s.send(payload.encode())
        print(f"[+] Sent -> {payload.strip()}")
        time.sleep(0.45)
    finally:
        s.close()

