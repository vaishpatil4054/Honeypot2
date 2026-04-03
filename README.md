# Cyber Deception Honeypot + Dashboard (Honeypot2)

A lightweight, **local-first** cyber deception honeypot project:

- `honeypot.py`: a low-interaction TCP honeypot on `127.0.0.1:8888`
- `app.py`: a Flask web dashboard that visualizes events from `data/logs.jsonl`
- `attacker_simulator.py`: generates repeatable “attacker-like” traffic for demos/testing
- `start_project.py` / `start_project.bat`: starts the honeypot + dashboard and opens the browser

> Safety: this project binds to `127.0.0.1` (localhost) by default so it is not exposed to the internet.

---

## Features

- Structured logging (**JSON Lines / JSONL**) to `data/logs.jsonl`
- Rule-based classification:
  - **CRITICAL** for default-credential keywords (`admin`, `root`)
  - **HIGH** for repeated attempts from the same IP (threshold)
  - **LOW** otherwise
- Web dashboard:
  - severity mix chart
  - activity (time buckets)
  - top actors
  - event stream + event detail drill-down
- Optional auto-simulator (dashboard can generate synthetic events in the background)

---

## Tech Stack

- Python 3.x
- Flask (`requirements.txt` => `Flask>=2.3`)
- HTML/CSS/JS (templates + static assets)

---

## Project Structure

```
Honeypot2/
├─ app.py
├─ honeypot.py
├─ attacker_simulator.py
├─ start_project.py
├─ start_project.bat
├─ requirements.txt
├─ data/
│  ├─ .gitkeep
│  └─ logs.jsonl
├─ static/
│  ├─ css/app.css
│  ├─ js/app.js
│  ├─ js/charts.js
│  └─ img/
│     ├─ dashboard_mock.svg
│     └─ system.svg
└─ templates/
   ├─ base.html
   ├─ login.html
   ├─ dashboard.html
   ├─ event.html
   └─ intake.html
```

---

## Setup

### 1) Create a virtual environment

Windows (PowerShell):

```powershell
python -m venv .venv
.\.venv\Scripts\activate
```

### 2) Install dependencies

```powershell
pip install -r requirements.txt
```

---

## Run

### Option A: One-click (Windows)

```powershell
.\start_project.bat
```

### Option B: Python launcher

```powershell
python .\start_project.py
```

The launcher:

- clears `data/logs.jsonl` (best for a clean demo)
- starts `honeypot.py` (TCP `127.0.0.1:8888`)
- starts `app.py` (HTTP `127.0.0.1:5000–5010`, picks a free port)
- opens the login page in your browser

---

## Simulate Attacks

With the honeypot running:

```powershell
python .\attacker_simulator.py
```

You should see new events appear in the dashboard and new lines appended to `data/logs.jsonl`.

---

## Configuration

Environment variables (optional):

- `PORT` (default `5000`): dashboard port (the launcher finds a free port in `5000..5010`)
- `AUTO_SIMULATE` (default `1`): `0` to disable background synthetic event generation in `app.py`
- `AUTO_SIMULATE_INTERVAL` (default `10`): seconds between background simulation loops

Example:

```powershell
$env:AUTO_SIMULATE="0"
python .\app.py
```

---

## Logs (JSONL)

Events are stored in `data/logs.jsonl` as one JSON object per line. Typical fields:

- `id` (UUID)
- `ts` (UTC timestamp, ISO format)
- `title` (attack/action label)
- `severity` (`INFO|LOW|MEDIUM|HIGH|CRITICAL`)
- `source` (`simulator|web|intake`)
- `actor` (`username`, `family`)
- `ip`
- `details` (payload / attempt counters / notes)

---

## Screenshots

These SVGs are included in the repo (useful for reports/README):

- `static/img/system.svg`
- `static/img/dashboard_mock.svg`

---

## Troubleshooting

### Port 8888 already in use (WinError 10048)

1) Find the process:

```powershell
netstat -ano | findstr :8888
```

2) Stop it (replace `<PID>`):

```powershell
taskkill /PID <PID> /F
```

### Dashboard not opening

Check the terminal output from `start_project.py` for the exact URL (it can be `5000–5010`), then open it manually:

- `http://127.0.0.1:<PORT>/login`

---

## Notes for GitHub

- Do **not** commit `.venv/` or `data/logs.jsonl` (see `.gitignore`).
- This project is designed for local demos and learning; do not expose it publicly without isolation and hardening.

