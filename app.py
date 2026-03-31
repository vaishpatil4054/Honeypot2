import json
import os
import random
import threading
import time
import uuid
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from typing import Optional

from flask import Flask, jsonify, redirect, render_template, request, url_for


APP_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(APP_DIR, "data")
LOG_PATH = os.path.join(DATA_DIR, "logs.jsonl")

_ACTOR_SEQ = 0


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _ensure_data_dir() -> None:
    os.makedirs(DATA_DIR, exist_ok=True)


def _append_log(entry: dict) -> None:
    _ensure_data_dir()
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=True) + "\n")


def _iter_logs(limit: Optional[int] = None):
    if not os.path.exists(LOG_PATH):
        return []

    logs: list[dict] = []
    with open(LOG_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                e = json.loads(line)
                # Normalize existing events so the UI consistently shows one source.
                e["source"] = "simulator"
                actor = e.get("actor") or {}
                if isinstance(actor, dict):
                    # Backfill a stable grouping key for charts.
                    if not actor.get("family"):
                        actor["family"] = actor.get("username", "") or ""
                    e["actor"] = actor
                logs.append(e)
            except Exception:
                continue

    logs.reverse()  # newest-first
    if limit is not None:
        return logs[:limit]
    return logs


def _parse_ts(ts: str) -> Optional[datetime]:
    try:
        if ts.endswith("Z"):
            ts = ts[:-1] + "+00:00"
        return datetime.fromisoformat(ts)
    except Exception:
        return None


def _bucket_window(logs_oldest_first: list[dict], *, minutes: int, step_minutes: int = 5) -> list[dict]:
    now = _utc_now()
    start = now - timedelta(minutes=minutes)

    buckets: dict[str, int] = defaultdict(int)
    for log in logs_oldest_first:
        ts = _parse_ts(log.get("ts", ""))
        if not ts:
            continue
        if ts < start:
            continue
        minute = (ts.minute // step_minutes) * step_minutes
        bucket = ts.replace(minute=minute, second=0, microsecond=0)
        key = bucket.isoformat().replace("+00:00", "Z")
        buckets[key] += 1

    out = []
    # Align cursor to boundary.
    cursor_minute = (start.minute // step_minutes) * step_minutes
    cursor = start.replace(minute=cursor_minute, second=0, microsecond=0)
    while cursor <= now:
        key = cursor.isoformat().replace("+00:00", "Z")
        out.append({"t": key, "v": buckets.get(key, 0)})
        cursor += timedelta(minutes=step_minutes)
    return out


def _summary(logs_newest_first: list[dict]) -> dict:
    severities = Counter()
    sources = Counter()
    top_actors = Counter()

    for log in logs_newest_first:
        severities[log.get("severity", "INFO")] += 1
        sources[log.get("source", "web")] += 1
        actor_obj = log.get("actor") or {}
        if isinstance(actor_obj, dict):
            actor_key = actor_obj.get("family") or actor_obj.get("username") or ""
        else:
            actor_key = ""
        if actor_key:
            top_actors[actor_key] += 1

    # Rolling window for "Top Actors" so it visibly changes.
    cutoff = _utc_now() - timedelta(minutes=120)
    top_actors_recent = Counter()
    for log in logs_newest_first:
        ts = _parse_ts(log.get("ts", ""))
        if not ts or ts < cutoff:
            continue
        actor_obj = log.get("actor") or {}
        if isinstance(actor_obj, dict):
            actor_key = actor_obj.get("family") or actor_obj.get("username") or ""
        else:
            actor_key = ""
        if actor_key:
            top_actors_recent[actor_key] += 1

    return {
        "total": len(logs_newest_first),
        "by_severity": dict(severities),
        "by_source": dict(sources),
        "top_actors": top_actors_recent.most_common(8),
        # Keep a 24h rollup for the stat card, but chart a shorter window so it visibly moves.
        "last24h": _bucket_window(list(reversed(logs_newest_first)), minutes=24 * 60, step_minutes=5),
        "activity": _bucket_window(list(reversed(logs_newest_first)), minutes=120, step_minutes=5),
    }


def _system_status_from_critical(critical_count: int) -> tuple[str, str]:
    """
    Map CRITICAL count to a UI status label + CSS class.
    Rules requested:
    - Healthy if criticals are small (<= 3)
    - Degraded around 8 criticals
    - Down around 15 criticals
    """
    if critical_count >= 15:
        return ("Down", "down")
    if critical_count >= 4:
        return ("Degraded", "degraded")
    return ("Healthy", "ok")


def _new_event(
    *,
    title: str,
    severity: str,
    source: str,
    actor_username: Optional[str],
    ip: Optional[str],
    details: Optional[dict] = None,
) -> dict:
    now = _utc_now()
    actor_username = actor_username or ""
    actor_family = actor_username
    if actor_username.count("-") >= 2:
        # For simulator names like "shadow-operator-3af9c", family becomes "shadow-operator".
        actor_family = "-".join(actor_username.split("-")[:-1])
    return {
        "id": str(uuid.uuid4()),
        "ts": now.isoformat().replace("+00:00", "Z"),
        "title": title,
        "severity": severity,
        "source": "simulator",
        "actor": {"username": actor_username, "family": actor_family},
        "ip": ip or "",
        "details": details or {},
    }


def _random_actor() -> str:
    global _ACTOR_SEQ
    _ACTOR_SEQ += 1

    adj = [
        "silent",
        "swift",
        "bright",
        "shadow",
        "crimson",
        "aurora",
        "neon",
        "iron",
        "delta",
        "nova",
        "signal",
        "cipher",
    ]
    role = [
        "analyst",
        "operator",
        "agent",
        "probe",
        "runner",
        "guest",
        "service",
        "watcher",
        "user",
        "node",
    ]

    # Short suffix from time+seq so bursts don't repeat names.
    stamp = int(time.time() * 1000) ^ (_ACTOR_SEQ * 2654435761)
    suffix = format(stamp & 0xFFFFF, "x")
    return f"{random.choice(adj)}-{random.choice(role)}-{suffix}"


def _simulate_event() -> dict:
    titles = [
        "Login attempt",
        "Credential stuffing pattern",
        "Suspicious form submission",
        "Privilege escalation probe",
        "API token misuse",
        "Unusual traffic spike",
    ]
    # Bias away from INFO so the dashboard doesn't look "stuck" on INFO.
    severity = random.choices(
        ["INFO", "LOW", "MEDIUM", "HIGH", "CRITICAL"],
        weights=[2, 12, 10, 8, 6],
        k=1,
    )[0]
    title = random.choice(titles)
    user = _random_actor()
    ip = f"10.{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(1, 254)}"
    return _new_event(
        title=title,
        severity=severity,
        source="simulator",
        actor_username=user,
        ip=ip,
        details={
            "notes": "Synthetic event for demo/testing.",
            "correlation": f"INC-{random.randint(1000, 9999)}",
        },
    )


app = Flask(__name__)
# Accept both `/path` and `/path/` to reduce "URL not found" confusion.
app.url_map.strict_slashes = False


@app.context_processor
def inject_system_status():
    logs = _iter_logs(limit=1500)
    summary = _summary(logs)
    critical = int((summary.get("by_severity") or {}).get("CRITICAL", 0) or 0)
    label, css = _system_status_from_critical(critical)
    return {
        "system_status_label": label,
        "system_status_class": css,
        "system_critical_count": critical,
    }


def _start_auto_simulator() -> None:
    """
    Background event generator so the dashboard has non-login activity.
    Avoid starting twice under the Flask debug reloader.
    """

    enabled = os.environ.get("AUTO_SIMULATE", "1").strip() not in {"0", "false", "False"}
    if not enabled:
        return

    # In debug mode, Werkzeug runs a reloader parent + a child. Only start in the child.
    if app.debug and os.environ.get("WERKZEUG_RUN_MAIN") != "true":
        return

    try:
        interval_s = float(os.environ.get("AUTO_SIMULATE_INTERVAL", "10").strip())
    except Exception:
        interval_s = 10.0
    interval_s = max(2.0, min(120.0, interval_s))

    def _loop():
        # Small delay so the server boots first.
        time.sleep(1.0)
        while True:
            try:
                # Bursty traffic makes the activity chart visibly move.
                burst = random.choices([0, 1, 2, 3, 4], weights=[1, 5, 6, 4, 2], k=1)[0]
                if random.random() < 0.12:
                    burst += random.randint(6, 14)
                for _ in range(burst):
                    _append_log(_simulate_event())
            except Exception:
                pass
            time.sleep(interval_s)

    t = threading.Thread(target=_loop, daemon=True, name="auto-simulator")
    t.start()


@app.get("/")
def root():
    return redirect(url_for("login_page"))


@app.get("/__ping")
def ping():
    routes = sorted({str(r.rule) for r in app.url_map.iter_rules()})
    return jsonify({"ok": True, "app": "cyber-deception-dashboard", "routes": routes})


@app.get("/login")
def login_page():
    return render_template("login.html")


@app.post("/login")
def login_submit():
    username = (request.form.get("username") or "").strip()
    ip = request.headers.get("X-Forwarded-For", request.remote_addr) or ""
    event = _new_event(
        title="Dashboard login",
        severity="INFO",
        source="web",
        actor_username=username or "unknown",
        ip=ip,
        details={"path": "/login"},
    )
    _append_log(event)
    return redirect(url_for("dashboard", flash="login_ok"))


@app.get("/intake")
def intake_page():
    return render_template("intake.html")


@app.post("/intake")
def intake_submit():
    system = (request.form.get("system") or "").strip()
    username = (request.form.get("username") or "").strip()
    action = (request.form.get("action") or "").strip()
    severity = (request.form.get("severity") or "LOW").strip().upper()
    note = (request.form.get("note") or "").strip()

    if severity not in {"INFO", "LOW", "MEDIUM", "HIGH", "CRITICAL"}:
        severity = "LOW"

    ip = request.headers.get("X-Forwarded-For", request.remote_addr) or ""
    event = _new_event(
        title=action or "User submitted intake",
        severity=severity,
        source="intake",
        actor_username=username or "unknown",
        ip=ip,
        details={"system": system, "note": note},
    )
    _append_log(event)
    return redirect(url_for("dashboard", flash="intake_ok"))


@app.get("/dashboard")
def dashboard():
    flash = request.args.get("flash") or ""
    logs = _iter_logs(limit=250)
    summary = _summary(_iter_logs(limit=1500))
    now_ts = _utc_now().isoformat().replace("+00:00", "Z")
    latest = logs[0] if logs else None
    return render_template(
        "dashboard.html",
        logs=logs,
        flash=flash,
        summary=summary,
        now_ts=now_ts,
        latest=latest,
    )


@app.get("/event/<event_id>")
def event_detail(event_id: str):
    logs = _iter_logs(limit=None)
    event = next((e for e in logs if e.get("id") == event_id), None)
    if not event:
        return render_template("event.html", event=None), 404
    return render_template("event.html", event=event)


@app.get("/api/summary")
def api_summary():
    logs = _iter_logs(limit=1500)
    return jsonify(_summary(logs))


@app.get("/api/events")
def api_events():
    limit = request.args.get("limit", "50")
    try:
        limit_int = max(1, min(500, int(limit)))
    except Exception:
        limit_int = 50
    return jsonify({"events": _iter_logs(limit=limit_int)})


@app.post("/api/simulate")
def api_simulate():
    event = _simulate_event()
    _append_log(event)
    return jsonify({"ok": True, "event": event})


@app.post("/api/burst")
def api_burst():
    try:
        count = int((request.args.get("count") or "25").strip())
    except Exception:
        count = 25
    count = max(1, min(200, count))
    events = []
    for _ in range(count):
        e = _simulate_event()
        _append_log(e)
        events.append(e)
    return jsonify({"ok": True, "count": count, "events": events})


if __name__ == "__main__":
    _start_auto_simulator()
    try:
        port = int((os.environ.get("PORT") or "5000").strip())
    except Exception:
        port = 5000
    app.run(host="127.0.0.1", port=port, debug=True)
