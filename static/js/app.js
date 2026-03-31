document.documentElement.classList.add("js-on");

function $(sel) {
  return document.querySelector(sel);
}

function $all(sel) {
  return Array.from(document.querySelectorAll(sel));
}

function fmtInt(n) {
  return new Intl.NumberFormat().format(n);
}

function toastAutoHide() {
  const t = $(".toast");
  if (!t) return;
  setTimeout(() => {
    t.style.opacity = "0";
    t.style.transform = "translateY(-8px)";
    t.style.transition = "all 260ms ease";
    setTimeout(() => t.remove(), 280);
  }, 2400);
}

async function fetchJSON(url, opts) {
  // Avoid cached API responses so charts actually move as new logs arrive.
  const res = await fetch(url, { cache: "no-store", ...(opts || {}) });
  if (!res.ok) throw new Error("HTTP " + res.status);
  return await res.json();
}

function calc24h(points) {
  return points.reduce((a, p) => a + (p.v || 0), 0);
}

function renderCharts(summary) {
  const charts = window.SentinelCharts;
  if (!charts) return;
  const { barChart, lineChart } = charts;
  const sev = summary.by_severity || {};
  const sevItems = [
    { k: "CRIT", v: sev.CRITICAL || 0, c1: "rgba(255,77,125,0.95)", c2: "rgba(255,77,125,0.15)" },
    { k: "HIGH", v: sev.HIGH || 0, c1: "rgba(255,128,77,0.95)", c2: "rgba(255,128,77,0.15)" },
    { k: "MED", v: sev.MEDIUM || 0, c1: "rgba(255,204,61,0.95)", c2: "rgba(255,204,61,0.15)" },
    { k: "LOW", v: sev.LOW || 0, c1: "rgba(64,255,191,0.92)", c2: "rgba(64,255,191,0.12)" },
    { k: "INFO", v: sev.INFO || 0, c1: "rgba(109,193,255,0.92)", c2: "rgba(109,193,255,0.12)" },
  ];

  const sevCanvas = $("#chartSeverity");
  if (sevCanvas) barChart(sevCanvas, sevItems, { subtitle: "Severity distribution" });

  const actCanvas = $("#chartActivity");
  if (actCanvas) {
    lineChart(
      actCanvas,
      summary.activity || [],
      "rgba(109,193,255,0.24)",
      "rgba(109,193,255,0.92)",
    );
  }

  const actors = (summary.top_actors || []).map(([k, v]) => ({
    k: (k || "unknown").slice(0, 12),
    v,
    c1: "rgba(64,255,191,0.92)",
    c2: "rgba(64,255,191,0.12)",
  }));
  const actorCanvas = $("#chartActors");
  if (actorCanvas) {
    barChart(
      actorCanvas,
      actors.length
        ? actors
        : [{ k: "-", v: 0, c1: "rgba(132,164,255,0.3)", c2: "rgba(132,164,255,0.08)" }],
      { subtitle: "Top usernames" },
    );
  }
}

function animateNumber(el, value) {
  const start = 0;
  const dur = 520;
  const t0 = performance.now();
  function step(t) {
    const p = Math.min(1, (t - t0) / dur);
    const v = Math.floor(start + (value - start) * (1 - Math.pow(1 - p, 3)));
    el.textContent = fmtInt(v);
    if (p < 1) requestAnimationFrame(step);
  }
  requestAnimationFrame(step);
}

function hookTableRows() {
  const rows = $all("#eventsTable tbody tr");
  rows.forEach((tr) => {
    const href = tr.getAttribute("data-href");
    if (href) tr.classList.add("is-clickable");
    tr.addEventListener("click", () => {
      if (href) window.location.href = href;
    });
  });
}

function hookSeverityFilter() {
  const chips = $all("#severityChips .chip");
  const rows = $all("#eventsTable tbody tr");
  if (!chips.length || !rows.length) return;

  const setActive = (sev) => {
    chips.forEach((c) => c.classList.toggle("is-on", c.getAttribute("data-sev") === sev));
    rows.forEach((r) => {
      const rowSev = r.getAttribute("data-sev") || "INFO";
      const show = sev === "ALL" || rowSev === sev;
      r.style.display = show ? "" : "none";
    });
  };

  chips.forEach((c) => {
    c.addEventListener("click", () => setActive(c.getAttribute("data-sev") || "ALL"));
  });
}

async function hookSimulate() {
  const buttons = $all('[data-action="burst"]');
  if (!buttons.length) return;

  buttons.forEach((btn) => {
    btn.addEventListener("click", async () => {
      const prev = btn.textContent;
      const action = btn.getAttribute("data-action") || "burst";
      btn.disabled = true;
      btn.textContent = "Generating...";
      try {
        await fetchJSON("/api/burst?count=25", { method: "POST" });
        await hydrateDashboard();
        await refreshEventsTable();
      } catch {
        btn.textContent = "Failed";
      } finally {
        setTimeout(() => {
          btn.disabled = false;
          btn.textContent = prev || "Simulate Event";
        }, 600);
      }
    });
  });
}

function getActiveSeverity() {
  const on = $("#severityChips .chip.is-on");
  return (on && on.getAttribute("data-sev")) || "ALL";
}

function setActiveSeverity(sev) {
  const chips = $all("#severityChips .chip");
  const rows = $all("#eventsTable tbody tr");
  chips.forEach((c) => c.classList.toggle("is-on", c.getAttribute("data-sev") === sev));
  rows.forEach((r) => {
    const rowSev = r.getAttribute("data-sev") || "INFO";
    const show = sev === "ALL" || rowSev === sev;
    r.style.display = show ? "" : "none";
  });
}

function buildRow(log) {
  const tr = document.createElement("tr");
  tr.setAttribute("data-sev", log.severity || "INFO");
  if (log.id) {
    tr.setAttribute("data-href", "/event/" + log.id);
    tr.classList.add("is-clickable");
  }

  const tdTs = document.createElement("td");
  tdTs.className = "mono";
  tdTs.textContent = log.ts || "";

  const tdSev = document.createElement("td");
  const sevSpan = document.createElement("span");
  const sev = (log.severity || "INFO").toLowerCase();
  sevSpan.className = "sev sev-" + sev;
  sevSpan.textContent = (log.severity || "INFO").toUpperCase();
  tdSev.appendChild(sevSpan);

  const tdSource = document.createElement("td");
  tdSource.textContent = log.source || "";

  const tdTitle = document.createElement("td");
  tdTitle.textContent = log.title || "";

  const tdActor = document.createElement("td");
  tdActor.textContent = (log.actor && log.actor.username) || "";

  const tdIp = document.createElement("td");
  tdIp.className = "mono";
  tdIp.textContent = log.ip || "";

  tr.appendChild(tdTs);
  tr.appendChild(tdSev);
  tr.appendChild(tdSource);
  tr.appendChild(tdTitle);
  tr.appendChild(tdActor);
  tr.appendChild(tdIp);
  return tr;
}

async function refreshEventsTable() {
  const tbody = $("#eventsTable tbody");
  if (!tbody) return;

  const active = getActiveSeverity();
  const data = await fetchJSON("/api/events?limit=250");
  const events = data.events || [];

  // Replace rows (fast enough for 250).
  tbody.innerHTML = "";
  for (const e of events) {
    tbody.appendChild(buildRow(e));
  }

  hookTableRows();
  setActiveSeverity(active);
}

async function hydrateDashboard() {
  const totalEl = $("#statTotal");
  const critEl = $("#statCritical");
  const d24El = $("#stat24h");

  try {
    const summary = await fetchJSON("/api/summary");
    if (totalEl) animateNumber(totalEl, summary.total || 0);
    if (critEl) animateNumber(critEl, (summary.by_severity || {}).CRITICAL || 0);
    if (d24El) animateNumber(d24El, calc24h(summary.last24h || []));
    renderCharts(summary);
  } catch {
    if (totalEl) totalEl.textContent = "n/a";
  }
}

window.addEventListener("load", () => {
  toastAutoHide();
  hookTableRows();
  hookSeverityFilter();
  hookSimulate();
  hydrateDashboard();

  // Live refresh on the dashboard page (charts + table).
  if ($("#chartSeverity") || $("#eventsTable")) {
    // Immediate refresh so the newest login event shows up right away.
    refreshEventsTable();
    setInterval(() => {
      hydrateDashboard();
      refreshEventsTable();
    }, 10000);
  }
});
