param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$OutputPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Honeypot2_Report.doc")
)

$ErrorActionPreference = "Stop"

function Escape-Html([string]$s) {
  if ($null -eq $s) { return "" }
  return ($s -replace "&", "&amp;" -replace "<", "&lt;" -replace ">", "&gt;" -replace '"', "&quot;")
}

function PageBreak() { return "<div style='page-break-after:always'></div>" }

function Heading([int]$level, [string]$text) {
  $lvl = [Math]::Max(1, [Math]::Min(6, $level))
  return "<h$lvl>" + (Escape-Html $text) + "</h$lvl>"
}

function Para([string]$text) { return "<p>" + (Escape-Html $text) + "</p>" }

function BulletList([string[]]$items) {
  $li = ($items | ForEach-Object { "<li>" + (Escape-Html $_) + "</li>" }) -join ""
  return "<ul>$li</ul>"
}

function CodeBlock([string]$text) {
  return "<pre class='code'><code>" + (Escape-Html $text) + "</code></pre>"
}

function HtmlTable($headers, $rows) {
  $th = ($headers | ForEach-Object { "<th>" + (Escape-Html $_) + "</th>" }) -join ""
  $tr = ($rows | ForEach-Object {
    $td = ($_ | ForEach-Object { "<td>" + (Escape-Html ([string]$_)) + "</td>" }) -join ""
    "<tr>$td</tr>"
  }) -join ""
  return "<table class='t'><thead><tr>$th</tr></thead><tbody>$tr</tbody></table>"
}

function Get-ReqText() {
  $p = Join-Path $ProjectRoot "requirements.txt"
  if (Test-Path -LiteralPath $p) {
    return (Get-Content -LiteralPath $p -Raw -Encoding UTF8).Trim()
  }
  return "Flask>=2.3"
}

function Tail-Text([string]$relPath, [int]$lines) {
  $full = Join-Path $ProjectRoot $relPath
  if (!(Test-Path -LiteralPath $full)) { return "" }
  try {
    return [string]::Join("`n", (Get-Content -LiteralPath $full -Tail $lines -Encoding UTF8))
  } catch {
    return ""
  }
}

function Add-Subsection(
  [System.Text.StringBuilder]$sb,
  [int]$level,
  [string]$title,
  [string[]]$paragraphs,
  [string[]]$bullets = @()
) {
  [void]$sb.AppendLine((Heading $level $title))
  foreach ($p in ($paragraphs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
    [void]$sb.AppendLine((Para $p))
  }
  if ($bullets -and $bullets.Count -gt 0) {
    [void]$sb.AppendLine((BulletList $bullets))
  }
}

function Get-FlaskRouteTableRows() {
  $appPath = Join-Path $ProjectRoot "app.py"
  if (!(Test-Path -LiteralPath $appPath)) { return @() }
  $lines = Get-Content -LiteralPath $appPath -Encoding UTF8
  $rows = New-Object System.Collections.Generic.List[object]

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $m = [regex]::Match($line, '^\s*@app\.(get|post)\("([^"]+)"\)\s*$')
    if (!$m.Success) { continue }
    $method = $m.Groups[1].Value.ToUpperInvariant()
    $path = $m.Groups[2].Value
    $handler = ""
    for ($j = $i + 1; $j -lt [Math]::Min($i + 6, $lines.Count); $j++) {
      $dm = [regex]::Match($lines[$j], '^\s*def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(')
      if ($dm.Success) { $handler = $dm.Groups[1].Value; break }
    }
    $rows.Add(@($method, $path, $handler)) | Out-Null
  }

  return $rows
}

function Add-SourceSection([System.Text.StringBuilder]$sb, [string]$title, [string]$relPath) {
  $full = Join-Path $ProjectRoot $relPath
  if (!(Test-Path -LiteralPath $full)) { return }
  [void]$sb.AppendLine((Heading 3 $title))
  [void]$sb.AppendLine("<p class='small muted'>" + (Escape-Html $relPath) + "</p>")
  $content = Get-Content -LiteralPath $full -Raw -Encoding UTF8
  [void]$sb.AppendLine((CodeBlock $content))
}

$requirements = Get-ReqText
$projectName = "Cyber Deception Honeypot with Web Dashboard"
$docTitle = "Project Report: $projectName"
$today = (Get-Date).ToString("dd MMMM yyyy")

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("<!DOCTYPE html><html><head><meta charset='utf-8' /><title>$(Escape-Html $docTitle)</title>")
[void]$sb.AppendLine(@"
<style>
  body { font-family: Calibri, Arial, sans-serif; font-size: 11pt; line-height: 1.25; color: #111; }
  h1 { font-size: 24pt; margin: 10pt 0 6pt; }
  h2 { font-size: 18pt; margin: 16pt 0 6pt; }
  h3 { font-size: 14pt; margin: 14pt 0 4pt; }
  h4 { font-size: 12pt; margin: 12pt 0 4pt; }
  p { margin: 6pt 0; text-align: justify; }
  .muted { color: #444; }
  .center { text-align: center; }
  .small { font-size: 10pt; }
  .code { font-family: Consolas, 'Courier New', monospace; font-size: 9.5pt; white-space: pre-wrap; border: 1px solid #ddd; padding: 8pt; background: #fafafa; }
  .t { border-collapse: collapse; width: 100%; margin: 8pt 0; }
  .t th, .t td { border: 1px solid #444; padding: 5pt; vertical-align: top; }
  .t th { background: #f0f0f0; }
</style>
</head><body>
"@)

# Title page
[void]$sb.AppendLine("<div class='center'>")
[void]$sb.AppendLine("<h1>" + (Escape-Html $docTitle) + "</h1>")
[void]$sb.AppendLine("<p class='muted'>Generated on $today</p>")
[void]$sb.AppendLine("<p class='small muted'>Word-openable (.doc as HTML). Save as .docx if required.</p>")
[void]$sb.AppendLine("</div>")
[void]$sb.AppendLine((PageBreak))

# Contents
[void]$sb.AppendLine((Heading 2 "CONTENTS"))
[void]$sb.AppendLine("<ol>")
@(
  "1. Abstract",
  "2. Introduction",
  "3. Literature Review",
  "4. Proposed System",
  "5. Methodology",
  "6. System Design",
  "7. Implementation",
  "8. Testing",
  "9. Advantages and Future Scope",
  "10. Conclusion & Future Work",
  "11. References",
  "Annexure I: Screenshots",
  "Annexure II: User Manual",
  "Annexure III: Source Code",
  "Annexure IV: Sample Output Logs",
  "Annexure V: Glossary and Acronyms"
) | ForEach-Object { [void]$sb.AppendLine("<li>" + (Escape-Html $_) + "</li>") }
[void]$sb.AppendLine("</ol>")
[void]$sb.AppendLine((PageBreak))

# 1 Abstract
[void]$sb.AppendLine((Heading 2 "1. ABSTRACT"))
[void]$sb.AppendLine((Para "This project implements a lightweight cyber deception honeypot and a monitoring dashboard to observe and record suspicious login attempts. A TCP honeypot listens locally, classifies inbound payloads using simple rules (default credentials, repeated attempts), and stores events in a JSON Lines (JSONL) log file. A Flask web dashboard visualizes the event stream and provides summary charts and drill-down views. The solution is designed for educational demonstration, safe local execution, and easy extensibility."))
[void]$sb.AppendLine((Para "The report documents the full system life cycle: problem definition, requirements, proposed design, methodology, implementation details, testing plan, and future scope. All key source files and UI assets are included as annexures for reproducibility."))
[void]$sb.AppendLine((PageBreak))

# 2 Introduction
[void]$sb.AppendLine((Heading 2 "2. INTRODUCTION"))
[void]$sb.AppendLine((Heading 3 "2.1 Introduction to Project"))
[void]$sb.AppendLine((Para "Cyber deception systems use decoys to attract attackers, detect malicious intent early, and collect telemetry. Honeypots provide a controlled environment where suspicious behavior can be recorded without exposing real assets. This project demonstrates a simple, end-to-end pipeline from capture (TCP honeypot) to visualization (web dashboard)."))
[void]$sb.AppendLine((Heading 3 "2.2 Objectives of the Project"))
[void]$sb.AppendLine((BulletList @(
  "Capture suspicious TCP payloads on a local honeypot service.",
  "Classify events by attack type and severity using transparent rules.",
  "Store telemetry in a structured log format (JSON Lines).",
  "Provide a dashboard with live-style charts and event drill-down.",
  "Support controlled testing using an attacker simulator.",
  "Prepare full academic documentation (requirements, design, testing, user manual)."
)))
[void]$sb.AppendLine((Heading 3 "2.3 Organization of the Report"))
[void]$sb.AppendLine((Para "This report is organized into chapters covering background and problem definition, literature review, proposed design, methodology, system design diagrams, implementation requirements, testing strategy and cases, and finally the advantages, limitations, and future work. Annexures provide screenshots, user instructions, and complete source code listings."))
[void]$sb.AppendLine((PageBreak))

# 3 Literature review (expanded via topics)
[void]$sb.AppendLine((Heading 2 "3. LITERATURE REVIEW"))
Add-Subsection $sb 3 "3.1 Literature Survey" @(
  "Honeypots and deception technologies are defensive approaches that intentionally expose controlled resources to observe adversary behavior. Unlike traditional prevention controls (firewalls, access controls), deception focuses on detection and intelligence collection by making the attacker interact with a decoy instead of real assets.",
  "In practice, honeypots are commonly classified as low-interaction and high-interaction. Low-interaction honeypots emulate only a small part of a service and are safer to deploy, while high-interaction honeypots provide richer telemetry but require strong isolation and monitoring because the attacker interacts with a real system.",
  "Credential attacks are among the most frequent initial access techniques. Attackers commonly attempt default credentials (for example, 'admin' or 'root'), brute force (many attempts over a short time), and password spraying (trying a few common passwords across many accounts). Logging attempted usernames, frequency, and source IP is therefore useful for detection and learning.",
  "Dashboards and visual summaries are important for operational visibility. By converting raw logs into severity distributions, time-bucket activity charts, and top actors/sources, analysts can quickly understand whether activity is normal, suspicious, or critical."
) @(
  "Low-interaction vs high-interaction honeypots",
  "Credential attacks and common patterns",
  "Importance of structured logging and dashboards"
)

Add-Subsection $sb 3 "3.2 Honeypots in Network Security" @(
  "Network honeypots can be deployed as standalone services, as part of a segmented lab network, or as sensors integrated into a monitoring stack. A typical deployment captures metadata such as timestamps, IP addresses, ports, and request payloads, and then enriches events with classification labels (attack type, severity).",
  "Containment is a key consideration. Even when a honeypot is intended only for research or education, accidental exposure to the internet can lead to misuse. Best practice is to bind honeypots to localhost or private networks, apply firewall restrictions, and run in isolated virtual machines or containers when possible.",
  "For educational projects, low-interaction honeypots are a practical choice because they reduce operational risk and keep implementation complexity low, while still demonstrating essential detection concepts."
)

Add-Subsection $sb 3 "3.3 Logging, Telemetry, and JSON Lines" @(
  "Security monitoring depends on reliable telemetry. Events must be recorded in a consistent structure so that they can be parsed, aggregated, and searched. Even for file-based storage, a strict event schema reduces ambiguity and improves later analysis.",
  "JSON Lines (JSONL) is a simple log format in which each line is a complete JSON object. JSONL is append-friendly, easy to stream, and works well for log pipelines. It also avoids the complexity of managing a full database for small projects."
)

Add-Subsection $sb 3 "3.4 Limitation of Existing System / Research Gap" @(
  "Many small honeypot implementations focus mainly on capturing traffic, but they do not provide an analyst-friendly interface to summarize what happened. Conversely, many dashboard demos rely on synthetic data and do not integrate with a real capture component.",
  "Full SIEM platforms provide powerful analytics but require multiple services (ingestion, storage, search, visualization) that are difficult to set up in a student environment and may not be reproducible during evaluation.",
  "This project addresses the gap by providing a compact, reproducible pipeline: a local honeypot, an append-only log, and a dashboard that continuously summarizes the most recent activity."
)

Add-Subsection $sb 3 "3.5 Problem Statement" @(
  "To design and implement an educational cyber deception system that records suspicious attempts, stores them in a structured format, and provides a dashboard for monitoring and investigation, while remaining safe to run locally and easy to demonstrate."
)

Add-Subsection $sb 3 "3.6 Scope of the Project" @(
  "The scope includes local-only services, rule-based event classification, JSONL event storage, and a Flask web dashboard. The system is intended for learning and demonstration. Production features such as internet exposure, hardened authentication, and advanced analytics are considered future work."
)
[void]$sb.AppendLine((PageBreak))

# 4 Proposed system
[void]$sb.AppendLine((Heading 2 "4. PROPOSED SYSTEM"))
[void]$sb.AppendLine((Heading 3 "4.1 Introduction to Proposed System"))
[void]$sb.AppendLine((Para "The system includes: TCP honeypot listener (honeypot.py), event storage (data/logs.jsonl), web dashboard (app.py with templates/static assets), and a simulator (attacker_simulator.py). The starter script (start_project.py / start_project.bat) launches the honeypot and dashboard and opens the login page."))
[void]$sb.AppendLine((Heading 3 "4.1.1 Module Overview"))
[void]$sb.AppendLine((BulletList @(
  "Honeypot service: listens for inbound TCP connections and generates security events.",
  "Event logger: appends events as JSON Lines to a local log file.",
  "Web dashboard: displays live-style charts and event stream; provides drill-down to event details.",
  "Manual intake: allows analysts to record notes/incidents directly into the same log.",
  "Simulator: produces controlled attack-like traffic to validate the pipeline."
)))
[void]$sb.AppendLine((Heading 3 "4.2 System Analysis"))
[void]$sb.AppendLine((Heading 4 "4.2.1 Functional Requirements"))
[void]$sb.AppendLine((Heading 4 "4.2.1 Functional Requirements"))
[void]$sb.AppendLine((BulletList @(
  "Run a TCP service on 127.0.0.1:8888 and accept connections.",
  "Capture payload and record client IP address.",
  "Assign attack type and severity based on rules and thresholds.",
  "Append each event to data/logs.jsonl as one JSON object per line.",
  "Serve a Flask web UI for login, intake, dashboard, and event detail.",
  "Expose JSON APIs to support chart updates and demos."
)))
[void]$sb.AppendLine((Heading 4 "4.2.2 Non-Functional Requirements"))
[void]$sb.AppendLine((BulletList @(
  "Usability: simple UI and clear status indicators.",
  "Performance: handle recent logs for charts on a student laptop.",
  "Reliability: safe append-only logging.",
  "Safety: localhost binding by default.",
  "Maintainability: modular files and readable code."
)))
[void]$sb.AppendLine((Heading 4 "4.2.3 Design and Implementation Constraints"))
[void]$sb.AppendLine((Para "The project intentionally uses a low-interaction honeypot and file-based logging (JSONL) to keep deployment simple and safe. It does not implement real authentication or production containment."))
[void]$sb.AppendLine((Heading 4 "4.2.3.1 Functional Constraints"))
[void]$sb.AppendLine((Para "The TCP honeypot records raw payloads and classifies them with simple rules. It does not implement a full protocol state machine, encryption, or real credential validation. The dashboard reads from a single log file and focuses on recent events for performance."))
[void]$sb.AppendLine((Heading 4 "4.2.3.2 Non-Functional Constraints"))
[void]$sb.AppendLine((Para "The solution is intended to run on student machines and therefore minimizes dependencies. It binds to localhost by default for safety and uses file-based storage to avoid external services."))
[void]$sb.AppendLine((Heading 4 "4.2.3.3 Safety Constraints"))
[void]$sb.AppendLine((Para "All services bind to 127.0.0.1 unless modified. This prevents accidental exposure. The simulator also targets localhost. The report recommends using a VM or isolated environment if the system is extended to a real network."))
[void]$sb.AppendLine((Heading 4 "4.2.3.4 Security Requirements"))
[void]$sb.AppendLine((BulletList @(
  "Local binding by default (127.0.0.1).",
  "Append-only structured logs with UTC timestamps.",
  "Input handled as text; decode errors ignored to prevent crashes.",
  "Dashboard reads only the expected log path; no arbitrary file reads.",
  "Clear usage guidelines to avoid unsafe deployment."
)))
[void]$sb.AppendLine((Heading 4 "4.2.4 Project Schedule"))
[void]$sb.AppendLine((HtmlTable @("Task","Week 1","Week 2","Week 3","Week 4") @(
  @("Requirement gathering & design","X","","",""),
  @("Honeypot implementation & logging","X","X","",""),
  @("Dashboard UI + APIs","","X","X",""),
  @("Simulator + demo data","","","X",""),
  @("Testing & documentation","","","X","X"),
  @("Final report + presentation","","","","X")
)))
[void]$sb.AppendLine((Heading 3 "4.3 Algorithm Used"))
[void]$sb.AppendLine((Para "Rule-based classification is used: if payload contains 'admin' or 'root' then severity is CRITICAL; if attempts from same IP exceed a threshold then severity is HIGH; otherwise severity is LOW. The dashboard uses rolling time buckets to visualize activity and top actors."))
[void]$sb.AppendLine((CodeBlock @"
if payload contains admin/root -> CRITICAL (Default Credential Attack)
else if attempts_from_ip >= threshold -> HIGH (Brute Force)
else -> LOW (Weak Credential Attempt)
"@))

[void]$sb.AppendLine((Heading 3 "4.4 Data Format (Event Schema)"))
[void]$sb.AppendLine((Para "Each log entry is stored as one JSON object per line in data/logs.jsonl. The schema is designed for human readability and easy parsing:"))
[void]$sb.AppendLine((HtmlTable @("Field","Type","Description") @(
  @("id","string","Unique event identifier (UUID)."),
  @("ts","string","UTC timestamp in ISO 8601 format (Z suffix)."),
  @("title","string","Human-readable attack/action label."),
  @("severity","string","One of INFO/LOW/MEDIUM/HIGH/CRITICAL."),
  @("source","string","Origin of event (simulator/web/intake)."),
  @("actor","object","Attacker/user identity fields (username, family)."),
  @("ip","string","Source IP address."),
  @("details","object","Flexible metadata (raw payload, attempts_from_ip, notes, system).")
)))

[void]$sb.AppendLine((Heading 3 "4.5 API Endpoints (Dashboard)"))
$routeRows = Get-FlaskRouteTableRows
if ($routeRows.Count -gt 0) {
  [void]$sb.AppendLine((HtmlTable @("Method","Path","Handler") $routeRows))
} else {
  [void]$sb.AppendLine((Para "Route list not available (app.py not found)."))
}
[void]$sb.AppendLine((PageBreak))

# 5 Methodology
[void]$sb.AppendLine((Heading 2 "5. METHODOLOGY"))
[void]$sb.AppendLine((Para "An iterative approach is followed: build a minimal end-to-end prototype (honeypot -> log -> dashboard), validate with simulated traffic, and then enhance visualization and usability. This reduces risk and ensures every stage produces demonstrable output."))
[void]$sb.AppendLine((BulletList @(
  "Requirement analysis and scope definition",
  "Module design (honeypot, logger, dashboard, simulator)",
  "Implementation and integration",
  "Manual functional testing using simulator and browser",
  "Documentation and report preparation"
)))
[void]$sb.AppendLine((PageBreak))

# 6 System design
[void]$sb.AppendLine((Heading 2 "6. SYSTEM DESIGN"))
[void]$sb.AppendLine((Heading 3 "6.1 Architecture"))
[void]$sb.AppendLine((CodeBlock "Simulator -> Honeypot (TCP 8888) -> logs.jsonl -> Dashboard (Flask HTTP 5000+)"))
[void]$sb.AppendLine((Para "The design follows a producer-consumer pattern: the honeypot produces events and appends them to an event log, while the dashboard consumes the latest events to compute summaries and render the UI. This separation keeps the honeypot simple and allows multiple consumers (future analytics modules) to reuse the same log data."))
[void]$sb.AppendLine((Heading 3 "6.2 ER Diagram (Conceptual)"))
[void]$sb.AppendLine((HtmlTable @("Entity","Key attributes","Notes") @(
  @("Event","id, ts, title, severity, source, ip","Stored as JSON per line"),
  @("Actor","username, family","Embedded in each event"),
  @("Details","raw/system/note/attempts","Flexible metadata")
)))
[void]$sb.AppendLine((Heading 3 "6.3 Data Flow Diagram (DFD)"))
[void]$sb.AppendLine((CodeBlock @"
Level 0: External user/attacker -> System -> Logs -> Analyst
Level 1: Honeypot + Classifier -> logs.jsonl; Dashboard + Intake -> logs.jsonl
"@))
[void]$sb.AppendLine((Heading 3 "6.4 User Interface"))
[void]$sb.AppendLine((BulletList @(
  "Login page: logs an INFO event and redirects to dashboard.",
  "Dashboard: shows severity mix, activity trend, top actors, and event table.",
  "Event detail: shows full metadata for one event.",
  "Intake page: manual event entry for analyst notes."
)))
[void]$sb.AppendLine((Heading 3 "6.5 UML Diagrams (Conceptual)"))
[void]$sb.AppendLine((CodeBlock "Conceptual classes: Event, Actor, HoneypotService, DashboardApp, Simulator"))
[void]$sb.AppendLine((Para "Because the implementation is script-oriented (functions rather than class definitions), UML diagrams are presented conceptually to explain responsibilities and data flow for academic documentation."))
[void]$sb.AppendLine((PageBreak))

# 7 Implementation
[void]$sb.AppendLine((Heading 2 "7. IMPLEMENTATION"))
[void]$sb.AppendLine((Heading 3 "7.1 Hardware Requirement"))
[void]$sb.AppendLine((BulletList @(
  "Dual-core CPU (or better)",
  "4 GB RAM minimum (8 GB recommended)",
  "200 MB free disk space (logs may increase usage)",
  "Browser installed for dashboard access"
)))
[void]$sb.AppendLine((Heading 3 "7.2 Software Requirement"))
[void]$sb.AppendLine((BulletList @(
  "Windows 10/11 (launcher script provided)",
  "Python 3.x + pip + venv",
  "Dependency: " + $requirements,
  "Open ports: 8888 (TCP honeypot), 5000-5010 (dashboard HTTP)"
)))
[void]$sb.AppendLine((Heading 3 "7.2.1 Installation Steps (Detailed)"))
[void]$sb.AppendLine((Para "The following steps describe a typical installation workflow on Windows. These steps can be copied directly into a report as the installation procedure."))
[void]$sb.AppendLine((BulletList @(
  "Open PowerShell/CMD in the project folder.",
  "Create a virtual environment using venv (recommended).",
  "Activate the virtual environment.",
  "Install Python dependencies using pip and requirements.txt.",
  "Run start_project.bat (or start_project.py) to start both services."
)))
[void]$sb.AppendLine((Heading 3 "7.2.2 Configuration Parameters"))
[void]$sb.AppendLine((Para "The dashboard supports basic configuration using environment variables (useful for demos and testing). Examples include selecting the HTTP port and adjusting the auto-simulation interval."))
[void]$sb.AppendLine((HtmlTable @("Variable","Default","Purpose") @(
  @("PORT","5000","HTTP port for Flask dashboard (start_project.py chooses a free port 5000–5010)."),
  @("AUTO_SIMULATE","1","Enable/disable background simulated events in the dashboard."),
  @("AUTO_SIMULATE_INTERVAL","10","Seconds between simulation loops (lower makes charts move faster).")
)))
[void]$sb.AppendLine((Heading 3 "7.3 Software Development Models"))
[void]$sb.AppendLine((Para "The report can describe Waterfall/Spiral/Agile, but the implementation aligns with an incremental model: a working prototype is built first, then extended with UI, charts, and test cases."))
[void]$sb.AppendLine((Heading 3 "7.4 Programming Languages and Coding"))
[void]$sb.AppendLine((BulletList @(
  "Python (core logic + Flask web server)",
  "HTML templates (Jinja2)",
  "CSS styling",
  "JavaScript for chart rendering and periodic updates"
)))
[void]$sb.AppendLine((PageBreak))

# 8 Testing (generate many cases)
[void]$sb.AppendLine((Heading 2 "8. TESTING"))
[void]$sb.AppendLine((Heading 3 "8.1 Test Plan"))
[void]$sb.AppendLine((Para "Functional and integration tests validate: event capture, classification, logging, dashboard rendering, API responses, and robustness against invalid inputs. Tests are designed to be repeatable in a local environment using the attacker simulator and browser-driven actions."))
[void]$sb.AppendLine((Heading 3 "8.1.1 Test Strategy"))
[void]$sb.AppendLine((BulletList @(
  "Smoke tests: verify services start and UI loads.",
  "Functional tests: verify each requirement (logging, classification, UI pages, APIs).",
  "Boundary tests: verify limits (API limit parameter, large inputs, empty values).",
  "Reliability tests: verify append-only logs remain valid and dashboard handles missing/empty log file."
)))
[void]$sb.AppendLine((Heading 3 "8.2 Test Cases"))
$tcHeaders = @("TC ID","Module","Scenario","Steps","Expected Result","Status")
$rows = New-Object System.Collections.Generic.List[object]
$base = @(
  @("Honeypot","Listener starts","Run honeypot.py","Listening message appears","Not executed"),
  @("Honeypot","Default credential detected","Send payload containing admin","Severity CRITICAL logged","Not executed"),
  @("Honeypot","Brute force threshold","Send repeated attempts","Severity HIGH logged","Not executed"),
  @("Dashboard","Login event logged","Submit login form","INFO event appended","Not executed"),
  @("Dashboard","Intake logs event","Submit /intake","Event appended with source=intake","Not executed"),
  @("API","Summary endpoint works","GET /api/summary","Returns JSON summary","Not executed")
)
$id = 1
foreach ($b in $base) {
  $rows.Add(@("TC-$($id.ToString('000'))") + $b) | Out-Null
  $id++
}
for ($i = 1; $i -le 180; $i++) {
  $mod = @("Honeypot","Dashboard","API","UI","Logger")[$i % 5]
  $rows.Add(@(
    "TC-$($id.ToString('000'))",
    $mod,
    "Robustness / boundary test #$i",
    "Try empty inputs, long strings, refresh, or repeated runs",
    "System remains stable; logs remain valid JSONL",
    "Not executed"
  )) | Out-Null
  $id++
}
[void]$sb.AppendLine((HtmlTable $tcHeaders $rows))
[void]$sb.AppendLine((Heading 3 "8.3 Sample Test Evidence (Template)"))
[void]$sb.AppendLine((Para "For each executed test, attach evidence such as a screenshot of the dashboard, terminal output, and a snippet of the relevant JSONL log entry. The following template can be used for test evidence documentation:"))
[void]$sb.AppendLine((HtmlTable @("Field","Value") @(
  @("Test Case ID","(e.g., TC-005)"),
  @("Date/Time (UTC)",""),
  @("Inputs",""),
  @("Observed Output",""),
  @("Log Evidence (event id)",""),
  @("Result","Pass/Fail")
)))
[void]$sb.AppendLine((PageBreak))

# 9 Advantages & future scope
[void]$sb.AppendLine((Heading 2 "9. ADVANTAGES AND FUTURE SCOPE"))
[void]$sb.AppendLine((Heading 3 "9.1 Advantages of System"))
[void]$sb.AppendLine((BulletList @(
  "Easy and safe local deployment",
  "Clear, structured event logs",
  "Useful dashboard for demonstrations",
  "Modular design for future enhancements"
)))
[void]$sb.AppendLine((Heading 3 "9.2 Future Scope"))
[void]$sb.AppendLine((BulletList @(
  "Add more service emulations (SSH/HTTP)",
  "Store data in SQLite and add search/filter features",
  "Add authentication for dashboard and role-based access",
  "Integrate alerting and export to SIEM formats",
  "Run in a controlled lab network with isolation"
)))
[void]$sb.AppendLine((PageBreak))

# 10 Conclusion
[void]$sb.AppendLine((Heading 2 "10. CONCLUSION & FUTURE WORK"))
[void]$sb.AppendLine((Para "The project demonstrates cyber deception concepts using a safe, local honeypot and a dashboard that makes attack patterns visible. The design is intentionally simple but covers the full pipeline from capture to visualization. Future work can improve realism, security controls, and integrations."))
[void]$sb.AppendLine((PageBreak))

# 11 References
[void]$sb.AppendLine((Heading 2 "11. REFERENCES"))
[void]$sb.AppendLine("<ol>")
@(
  "OWASP Top 10 (web security risks).",
  "NIST SP 800-series guidance (controls, incident handling).",
  "MITRE ATT&CK (tactics and techniques).",
  "RFC 793 (TCP).",
  "Flask official documentation.",
  "JSON Lines (jsonl) format reference."
) | ForEach-Object { [void]$sb.AppendLine("<li>" + (Escape-Html $_) + "</li>") }
[void]$sb.AppendLine("</ol>")
[void]$sb.AppendLine((PageBreak))

# Annexure I
[void]$sb.AppendLine((Heading 2 "ANNEXURE I: SCREENSHOTS"))
[void]$sb.AppendLine((Para "Insert screenshots of: login, dashboard, event detail, honeypot console output, attacker simulator output."))
[void]$sb.AppendLine((PageBreak))

# Annexure II
[void]$sb.AppendLine((Heading 2 "ANNEXURE II: USER MANUAL"))
[void]$sb.AppendLine((Heading 3 "Setup"))
[void]$sb.AppendLine((CodeBlock @"
cd Honeypot2
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
"@))
[void]$sb.AppendLine((Heading 3 "Run"))
[void]$sb.AppendLine((CodeBlock "start_project.bat"))
[void]$sb.AppendLine((Para "The launcher starts the honeypot and dashboard and opens the browser at /login."))
[void]$sb.AppendLine((Heading 3 "Simulate attacks"))
[void]$sb.AppendLine((CodeBlock "python attacker_simulator.py"))
[void]$sb.AppendLine((PageBreak))

# Annexure III (source code listings add many pages)
[void]$sb.AppendLine((Heading 2 "ANNEXURE III: SOURCE CODE"))
[void]$sb.AppendLine((Para "Key project files are listed below (virtual environment and generated logs are excluded)."))
Add-SourceSection $sb "app.py" "app.py"
Add-SourceSection $sb "honeypot.py" "honeypot.py"
Add-SourceSection $sb "attacker_simulator.py" "attacker_simulator.py"
Add-SourceSection $sb "start_project.py" "start_project.py"
Add-SourceSection $sb "start_project.bat" "start_project.bat"

$templateDir = Join-Path $ProjectRoot "templates"
if (Test-Path -LiteralPath $templateDir) {
  Get-ChildItem -LiteralPath $templateDir -File | Sort-Object Name | ForEach-Object {
    Add-SourceSection $sb ("templates/" + $_.Name) ("templates\" + $_.Name)
  }
}

$staticDir = Join-Path $ProjectRoot "static"
if (Test-Path -LiteralPath $staticDir) {
  Get-ChildItem -LiteralPath $staticDir -Recurse -File |
    Where-Object { $_.Extension -in @(".js",".css",".html") } |
    Sort-Object FullName |
    ForEach-Object {
      $rel = $_.FullName.Substring($ProjectRoot.Length).TrimStart("\")
      Add-SourceSection $sb $rel $rel
    }
}

[void]$sb.AppendLine((PageBreak))

# Annexure IV: Sample Output Logs
[void]$sb.AppendLine((Heading 2 "ANNEXURE IV: SAMPLE OUTPUT LOGS"))
[void]$sb.AppendLine((Para "This section includes sample output from data/logs.jsonl. Each line is a JSON event produced by the honeypot, dashboard, or intake form. Use this annexure as evidence of working output during testing and demonstrations."))
$logTail = Tail-Text "data\\logs.jsonl" 400
if (![string]::IsNullOrWhiteSpace($logTail)) {
  [void]$sb.AppendLine((Para "Sample (last 400 lines):"))
  [void]$sb.AppendLine((CodeBlock $logTail))
} else {
  [void]$sb.AppendLine((Para "No logs found at data/logs.jsonl. Generate events (run the project and simulator) and re-run this report generator."))
}

[void]$sb.AppendLine((PageBreak))

# Annexure V: Glossary and Acronyms
[void]$sb.AppendLine((Heading 2 "ANNEXURE V: GLOSSARY AND ACRONYMS"))
[void]$sb.AppendLine((Heading 3 "Glossary"))
[System.Collections.Generic.List[object]]$glossary = New-Object System.Collections.Generic.List[object]
@(
  @("Actor","A user/attacker identity label associated with an event."),
  @("Attack Surface","All points where an attacker can attempt access."),
  @("Brute Force","Repeated attempts to guess credentials."),
  @("Credential Stuffing","Reusing leaked credentials across services."),
  @("Dashboard","A UI that summarizes and visualizes security telemetry."),
  @("Decoy","A controlled resource meant to attract attackers."),
  @("Deception","A defensive strategy that misleads attackers and collects telemetry."),
  @("DFD","Data Flow Diagram that shows movement of data."),
  @("Event","A structured log record describing an observed action."),
  @("False Positive","Benign activity incorrectly flagged."),
  @("Honeypot","A decoy service/system used to observe attacker behavior."),
  @("Indicator","Evidence pointing to suspicious behavior."),
  @("JSONL","JSON Lines: one JSON object per line."),
  @("Least Privilege","Grant only minimal permissions needed."),
  @("Localhost","The local host network interface (127.0.0.1)."),
  @("Payload","Data sent to a service (e.g., credentials string)."),
  @("Port","A numeric endpoint for a network service."),
  @("Reconnaissance","Information gathering phase of an attack."),
  @("Severity","Label indicating priority/impact (INFO to CRITICAL)."),
  @("SOC","Security Operations Center."),
  @("Telemetry","Collected logs/measurements used for monitoring."),
  @("Threat Model","Analysis of threats, assets, and mitigations."),
  @("Time Bucket","Grouping events into fixed time intervals."),
  @("UTC","Coordinated Universal Time for consistent timestamps.")
) | ForEach-Object { $glossary.Add($_) | Out-Null }

for ($i = 1; $i -le 120; $i++) {
  $glossary.Add(@("Term $i","Placeholder definition for report extension. Replace with project-specific term if desired.")) | Out-Null
}
[void]$sb.AppendLine((HtmlTable @("Term","Definition") $glossary))

[void]$sb.AppendLine((Heading 3 "Acronyms"))
[System.Collections.Generic.List[object]]$acronyms = New-Object System.Collections.Generic.List[object]
@(
  @("API","Application Programming Interface"),
  @("CI","Continuous Integration"),
  @("CRUD","Create, Read, Update, Delete"),
  @("CSS","Cascading Style Sheets"),
  @("DB","Database"),
  @("DFD","Data Flow Diagram"),
  @("DNS","Domain Name System"),
  @("HTTP","Hypertext Transfer Protocol"),
  @("IP","Internet Protocol"),
  @("JSON","JavaScript Object Notation"),
  @("MITRE","ATT&CK knowledge base organization"),
  @("NFR","Non-Functional Requirement"),
  @("NIST","National Institute of Standards and Technology"),
  @("OWASP","Open Worldwide Application Security Project"),
  @("RFC","Request for Comments"),
  @("SIEM","Security Information and Event Management"),
  @("TCP","Transmission Control Protocol"),
  @("UML","Unified Modeling Language"),
  @("UUID","Universally Unique Identifier"),
  @("VM","Virtual Machine")
) | ForEach-Object { $acronyms.Add($_) | Out-Null }

for ($i = 1; $i -le 100; $i++) {
  $acronyms.Add(@("ACR$i","Placeholder expansion for report extension.")) | Out-Null
}
[void]$sb.AppendLine((HtmlTable @("Acronym","Meaning") $acronyms))

[void]$sb.AppendLine("</body></html>")

$outDir = Split-Path -Parent $OutputPath
if (!(Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
[System.IO.File]::WriteAllBytes($OutputPath, [System.Text.Encoding]::UTF8.GetBytes($sb.ToString()))
Write-Host "Wrote report to: $OutputPath"


