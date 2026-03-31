param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$OutputPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Honeypot2_Report_v2.doc")
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

function Figure([string]$title, [string]$imgHtml, [string]$caption) {
  return @"
<div style='margin: 10pt 0;'>
  <div style='font-weight: 700; margin-bottom: 4pt;'>$(Escape-Html $title)</div>
  <div style='border: 1px solid #999; padding: 8pt; background: #fff;'>$imgHtml</div>
  <div class='small muted' style='margin-top: 4pt;'>$(Escape-Html $caption)</div>
</div>
"@
}

function Get-MimeFromExt([string]$path) {
  $ext = [IO.Path]::GetExtension($path)
  if (-not $ext) { $ext = "" }
  $ext = $ext.ToLowerInvariant()
  switch ($ext) {
    ".png" { return "image/png" }
    ".jpg" { return "image/jpeg" }
    ".jpeg" { return "image/jpeg" }
    ".gif" { return "image/gif" }
    ".svg" { return "image/svg+xml" }
    default { return "application/octet-stream" }
  }
}

function ImgDataUri([string]$relPath, [string]$alt = "") {
  $full = Join-Path $ProjectRoot $relPath
  if (!(Test-Path -LiteralPath $full)) { return "" }
  try {
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $b64 = [Convert]::ToBase64String($bytes)
    $mime = Get-MimeFromExt $full
    $altEsc = Escape-Html $alt
    return "<img alt='$altEsc' style='max-width:100%; height:auto; display:block; margin:0 auto;' src='data:$mime;base64,$b64' />"
  } catch {
    return ""
  }
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
[void]$sb.AppendLine((Para "This project implements an educational cyber deception honeypot and a monitoring dashboard to observe and record suspicious behavior related to credential attacks. The system demonstrates how a controlled decoy service can capture attacker-like interactions and convert them into structured security events that are easy to analyze."))
[void]$sb.AppendLine((Para "A low-interaction TCP honeypot listens on localhost and records inbound payloads. The payload is evaluated using explainable rule-based logic to identify patterns such as default credential keywords (e.g., admin/root) and repeated attempts from the same IP address. Each observation is stored as a single JSON object in a JSON Lines (JSONL) log file (one event per line)."))
[void]$sb.AppendLine((Para "A Flask-based web dashboard reads the log file, normalizes events, aggregates them into metrics (counts by severity, time-window activity, top actors), and visualizes the results through charts and an event stream. The dashboard also supports manual intake so an operator can record additional notes as events."))
[void]$sb.AppendLine((Para "The solution is designed for safe local execution (127.0.0.1 binding by default) and minimal setup cost. The report documents theory, requirements, design, methodology, implementation details, testing strategy, and future enhancements. Annexures provide figures/screenshots, sample logs, and source code to support reproducibility."))
[void]$sb.AppendLine((PageBreak))

# 2 Introduction
[void]$sb.AppendLine((Heading 2 "2. INTRODUCTION"))
[void]$sb.AppendLine((Heading 3 "2.1 Introduction to Project"))
[void]$sb.AppendLine((Para "Credential-based attacks are among the most common ways attackers attempt initial access. In many cases, attackers begin with low-cost automated techniques such as trying default usernames and passwords, brute forcing weak credentials, or repeatedly testing common password lists. Because these attacks are cheap and scalable, they can occur continuously against exposed services."))
[void]$sb.AppendLine((Para "Cyber deception complements traditional prevention controls by deploying decoy targets that are instrumented to log and reveal attacker behavior. A honeypot is a controlled decoy service that acts as a sensor: it captures who connected, what they attempted, and when it happened. This helps create measurable evidence for analysis and learning."))
[void]$sb.AppendLine((Para "This project demonstrates an end-to-end monitoring pipeline using a local TCP honeypot and a web dashboard. The honeypot captures payloads and generates structured events with severity labels. The dashboard reads those events, summarizes trends, and provides drill-down views so an analyst can investigate details."))
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
[void]$sb.AppendLine((Heading 3 "2.4 Motivation"))
[void]$sb.AppendLine((Para "The motivation of the project is to make security monitoring concepts practical and visible. Instead of treating attacks as abstract ideas, the system produces observable events and demonstrates how even simple classification rules can highlight critical patterns such as default credential attempts and brute force behavior."))
[void]$sb.AppendLine((Heading 3 "2.5 Problem Definition"))
[void]$sb.AppendLine((Para "The problem addressed is: design a safe and simple deception-based system that records suspicious credential-related activity, stores it in a structured format, assigns meaningful severity labels, and visualizes the results in a dashboard suitable for demonstrations and academic evaluation."))
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

Add-Subsection $sb 3 "3.7 Security Monitoring Concepts" @(
  "Security monitoring turns system activity into actionable signals. A typical monitoring pipeline includes data collection (telemetry), normalization, enrichment, storage, aggregation, and visualization. The goal is to reduce raw noise into a form that supports decision making.",
  "For credential-related attacks, useful signals include: attempt frequency, repeated attempts from one source, known high-risk usernames (admin/root), and bursts over time. Even simple rule-based signals can provide strong educational value when presented clearly."
) @(
  "Telemetry collection and normalization",
  "Event enrichment and storage",
  "Aggregation and visualization for rapid analysis"
)

Add-Subsection $sb 3 "3.8 Severity and Prioritization" @(
  "Severity labels help prioritize investigation. A severity model should be consistent, explainable, and aligned with risk. For example, a default credential attempt suggests an attacker is targeting privileged access and therefore justifies a higher severity.",
  "In this project, severity is assigned using transparent rules so the results can be justified in a report. While rule-based severity is limited compared to advanced anomaly detection, it is appropriate for an educational environment."
)

Add-Subsection $sb 3 "3.9 Ethical and Safety Considerations for Honeypots" @(
  "Honeypots must be deployed responsibly. If exposed unintentionally, they can be abused by attackers or can attract activity that is difficult to manage. Best practice includes isolation (VM/container), strict network controls, and binding to localhost for student projects.",
  "This project defaults to localhost binding to prevent accidental exposure. The attacker simulator is also configured for localhost, ensuring demonstrations can be conducted safely and legally."
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
[void]$sb.AppendLine((Heading 3 "4.1.2 Design Rationale"))
[void]$sb.AppendLine((Para "The design intentionally separates event capture from visualization. The honeypot focuses on reliably capturing and logging events, while the dashboard focuses on summarizing and presenting those events. This separation makes the system easier to understand, test, and extend."))
[void]$sb.AppendLine((Para "File-based JSONL storage is chosen because it is append-friendly, easy to parse, and does not require running a database server. For an academic project, this significantly reduces setup complexity while still producing realistic telemetry."))
[void]$sb.AppendLine((Para "Rule-based severity classification is used because it is transparent and explainable in a report. Although more advanced approaches exist (statistical anomaly detection, machine learning), simple rules are sufficient to demonstrate core monitoring concepts and to produce interpretable results."))
[void]$sb.AppendLine((Heading 3 "4.2 System Analysis"))
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
[void]$sb.AppendLine((Para "A simple academic schedule can be represented as an incremental timeline. The exact dates can be adjusted based on your semester plan, but the typical order of work is:"))
[void]$sb.AppendLine((BulletList @(
  "Week 1: Requirement gathering, scope definition, and architecture planning.",
  "Week 2: Honeypot implementation and structured logging (JSONL).",
  "Week 3: Dashboard UI, APIs, and chart-based visualization.",
  "Week 4: Testing with simulator, documentation, screenshots, and final report preparation."
)))
[void]$sb.AppendLine((Heading 4 "4.2.5 Feasibility Study"))
[void]$sb.AppendLine((Para "Technical feasibility: the system uses standard Python libraries and Flask, and runs on a typical laptop without external infrastructure. File-based JSONL storage avoids database setup while remaining suitable for structured logging."))
[void]$sb.AppendLine((Para "Operational feasibility: the dashboard provides an easy workflow for demonstrations. The simulator generates repeatable traffic so the system can be evaluated even without external network exposure."))
[void]$sb.AppendLine((Para "Economic feasibility: the technology stack is free/open-source and does not require paid services. The deployment cost is limited to a normal computer with Python installed."))
[void]$sb.AppendLine((Heading 4 "4.2.6 Project Risks and Mitigation"))
[void]$sb.AppendLine((BulletList @(
  "Risk: accidental exposure of the honeypot to the internet. Mitigation: bind to 127.0.0.1 by default and recommend isolated environments for extensions.",
  "Risk: log growth over time. Mitigation: keep a rolling window in the dashboard and optionally clear logs before demos.",
  "Risk: misleading severity labels due to simple rules. Mitigation: document limitations and treat the output as educational, not production-grade."
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
[void]$sb.AppendLine((BulletList @(
  "id (string): Unique event identifier (UUID) for traceability.",
  "ts (string): UTC timestamp in ISO 8601 format (Z suffix) for consistent ordering.",
  "title (string): Attack type or action label (e.g., Default Credential Attack).",
  "severity (string): INFO / LOW / MEDIUM / HIGH / CRITICAL for prioritization.",
  "source (string): Origin of event (simulator / web / intake) to understand context.",
  "actor (object): Identity grouping (username, family) used in charts and summaries.",
  "ip (string): Source IP address of the connection or request.",
  "details (object): Flexible metadata such as raw payload, attempt counters, and notes."
)))
[void]$sb.AppendLine((Para "JSONL is suitable for append-only logging: each new event is written as a new line without rewriting earlier data. This is reliable for continuous monitoring and simple for the dashboard to read incrementally."))

[void]$sb.AppendLine((Heading 3 "4.5 API Endpoints (Dashboard)"))
$routeRows = Get-FlaskRouteTableRows
if ($routeRows.Count -gt 0) {
  [void]$sb.AppendLine((Para "The dashboard exposes routes for pages and JSON APIs used by the UI for periodic updates. The following list summarizes the interface:"))
  foreach ($r in $routeRows) {
    $handler = ""
    if ($r.Count -ge 3 -and $null -ne $r[2]) { $handler = [string]$r[2] }
    [void]$sb.AppendLine((Para ("• " + $r[0] + " " + $r[1] + " (handler: " + $handler + ")")))
  }
} else {
  [void]$sb.AppendLine((Para "Route list not available (app.py not found)."))
}
[void]$sb.AppendLine((PageBreak))

# 5 Methodology
[void]$sb.AppendLine((Heading 2 "5. METHODOLOGY"))
[void]$sb.AppendLine((Para "Methodology describes the process used to plan, design, implement, and validate the system. For this project, an incremental development methodology is selected because it produces a working prototype early and allows improvements to be added in small, testable steps."))
[void]$sb.AppendLine((Heading 3 "5.1 Development Approach"))
[void]$sb.AppendLine((Para "The work is executed in iterations. Each iteration delivers a demonstrable feature and reduces uncertainty:"))
[void]$sb.AppendLine((BulletList @(
  "Iteration 1: Implement the TCP listener and write events to an append-only JSONL log.",
  "Iteration 2: Add rule-based classification and severity labeling.",
  "Iteration 3: Build Flask pages (login, intake, dashboard, event details).",
  "Iteration 4: Add summary aggregation and chart visualizations.",
  "Iteration 5: Add the attacker simulator and finalize test cases and documentation."
)))
[void]$sb.AppendLine((Heading 3 "5.2 Tools and Technologies"))
[void]$sb.AppendLine((Para "Python is used for both the honeypot and the web application. Flask provides web routing, template rendering, and JSON APIs. HTML/CSS define the UI layout, and JavaScript renders charts and periodically refreshes summary data. JSONL is used as the storage format because it is simple, structured, and easy to append."))
[void]$sb.AppendLine((Heading 3 "5.3 Data Pipeline (Capture to Visualization)"))
[void]$sb.AppendLine((Para "The operational pipeline is: capture → normalize → classify → enrich → persist → aggregate → visualize. Separating these steps improves maintainability and makes the report easier to explain."))
[void]$sb.AppendLine((BulletList @(
  "Capture: accept TCP connection and read a payload string.",
  "Normalize: decode safely, trim whitespace, and handle invalid bytes without crashing.",
  "Classify: apply explainable rules (keywords and thresholds).",
  "Enrich: attach timestamps (UTC), actor labels, and details metadata.",
  "Persist: append a single JSON object to logs.jsonl.",
  "Aggregate: compute totals, severity mix, and time buckets for activity charts.",
  "Visualize: render charts and event tables; support event detail drill-down."
)))
[void]$sb.AppendLine((Heading 3 "5.4 Safety and Ethical Considerations"))
[void]$sb.AppendLine((Para "Even in academic settings, honeypots should be deployed responsibly. This project uses localhost binding by default to prevent accidental exposure. If extended to a network environment, it should run only in an isolated lab with explicit authorization, firewall rules, and monitoring. Inputs are treated as text and are never executed."))
[void]$sb.AppendLine((PageBreak))

# 6 System design
[void]$sb.AppendLine((Heading 2 "6. SYSTEM DESIGN"))
[void]$sb.AppendLine((Heading 3 "6.1 Architecture"))
[void]$sb.AppendLine((CodeBlock "Simulator -> Honeypot (TCP 8888) -> logs.jsonl -> Dashboard (Flask HTTP 5000+)"))
[void]$sb.AppendLine((Para "The design follows a producer-consumer pattern: the honeypot produces events and appends them to an event log, while the dashboard consumes the latest events to compute summaries and render the UI. This separation keeps the honeypot simple and allows multiple consumers (future analytics modules) to reuse the same log data."))
[void]$sb.AppendLine((Heading 3 "6.2 ER Diagram (Conceptual)"))
[void]$sb.AppendLine((Para "The implementation uses JSONL (file-based logs) rather than a relational database. However, an ER view is still useful to clearly explain the data model used in each event record."))
[void]$sb.AppendLine((Para "ER Diagram (clear representation):"))
[void]$sb.AppendLine((CodeBlock @"
                +----------------------+
                |        ACTOR         |
                |----------------------|
                | username : string    |
                | family   : string    |
                +----------+-----------+
                           |
                           | 1..* generates
                           |
                 +---------v----------+
                 |        EVENT       |
                 |--------------------|
                 | id       : UUID    |
                 | ts       : UTC     |
                 | title    : string  |
                 | severity : enum    |
                 | source   : string  |
                 | ip       : string  |
                 +---------+----------+
                           |
                           | 1..1 has
                           |
                 +---------v----------+
                 |       DETAILS     |
                 |-------------------|
                 | raw payload       |
                 | attempts_from_ip  |
                 | system / note     |
                 | other metadata    |
                 +-------------------+
"@))
[void]$sb.AppendLine((Para "In the JSONL schema used in this project, ACTOR and DETAILS are nested objects inside EVENT. The ER diagram above represents the conceptual relationship to make the structure clear in the report."))
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
[void]$sb.AppendLine((Para "This annexure contains screenshots/figures. Two project images are embedded automatically (if available), and you can add your own screenshots after running the system."))

$systemSvg = ImgDataUri "static\\img\\system.svg" "System overview"
if ($systemSvg) {
  [void]$sb.AppendLine((Figure "Figure A1: System Overview" $systemSvg "Embedded from static/img/system.svg. If Word does not render SVG, replace this with a PNG screenshot or exported diagram."))
}

$dashSvg = ImgDataUri "static\\img\\dashboard_mock.svg" "Dashboard mock"
if ($dashSvg) {
  [void]$sb.AppendLine((Figure "Figure A2: Dashboard Mock" $dashSvg "Embedded from static/img/dashboard_mock.svg. Replace with an actual dashboard screenshot after running the project."))
}

[void]$sb.AppendLine((Para "Recommended screenshots to include in the final report:"))
[void]$sb.AppendLine((BulletList @(
  "Login page in browser (/login).",
  "Dashboard page with charts and event stream (/dashboard).",
  "Event detail page for a selected event (/event/<id>).",
  "Terminal output of honeypot.py while receiving simulator payloads.",
  "Terminal output of attacker_simulator.py showing sent payloads."
)))
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
$logTail = Tail-Text "data\\logs.jsonl" 100
if (![string]::IsNullOrWhiteSpace($logTail)) {
  [void]$sb.AppendLine((Para "Sample (last 100 lines):"))
  [void]$sb.AppendLine((CodeBlock $logTail))
} else {
  [void]$sb.AppendLine((Para "No logs found at data/logs.jsonl. Generate events (run the project and simulator) and re-run this report generator."))
}

[void]$sb.AppendLine((PageBreak))

# Annexure V: Glossary and Acronyms
[void]$sb.AppendLine((Heading 2 "ANNEXURE V: GLOSSARY AND ACRONYMS"))
[void]$sb.AppendLine((Heading 3 "Glossary"))
$glossary = @(
  @("Actor","A user/attacker identity label associated with an event."),
  @("Attack Surface","All points where an attacker can attempt access."),
  @("Brute Force","Repeated attempts to guess credentials."),
  @("Credential Stuffing","Reusing leaked credentials across services."),
  @("Dashboard","A UI that summarizes and visualizes security telemetry."),
  @("Decoy","A controlled resource meant to attract attackers."),
  @("Deception","A defensive strategy that misleads attackers and collects telemetry."),
  @("DFD","Data Flow Diagram that shows movement of data."),
  @("Event","A structured log record describing an observed action."),
  @("False Positive","Benign activity incorrectly flagged as malicious."),
  @("Honeypot","A decoy service/system used to observe attacker behavior."),
  @("Indicator","Evidence that points to suspicious behavior."),
  @("JSONL","JSON Lines: one JSON object per line (append-friendly log format)."),
  @("Least Privilege","Grant only minimal permissions needed to perform a task."),
  @("Localhost","The local machine network interface (127.0.0.1)."),
  @("Payload","Data sent to a service (e.g., a credential string)."),
  @("Reconnaissance","Information gathering phase of an attack."),
  @("Severity","Label indicating priority/impact (INFO to CRITICAL)."),
  @("Telemetry","Collected logs/measurements used for monitoring and analysis."),
  @("Time Bucket","Grouping events into fixed time intervals for charts."),
  @("UTC","Coordinated Universal Time, used for consistent timestamps.")
)
foreach ($g in $glossary) {
  [void]$sb.AppendLine("<p><b>" + (Escape-Html ([string]$g[0])) + ":</b> " + (Escape-Html ([string]$g[1])) + "</p>")
}

[void]$sb.AppendLine((Heading 3 "Acronyms"))
$acronyms = @(
  @("API","Application Programming Interface"),
  @("CRUD","Create, Read, Update, Delete"),
  @("CSS","Cascading Style Sheets"),
  @("DFD","Data Flow Diagram"),
  @("HTTP","Hypertext Transfer Protocol"),
  @("IP","Internet Protocol"),
  @("JSON","JavaScript Object Notation"),
  @("NFR","Non-Functional Requirement"),
  @("NIST","National Institute of Standards and Technology"),
  @("OWASP","Open Worldwide Application Security Project"),
  @("RFC","Request for Comments"),
  @("SIEM","Security Information and Event Management"),
  @("TCP","Transmission Control Protocol"),
  @("UML","Unified Modeling Language"),
  @("UUID","Universally Unique Identifier"),
  @("VM","Virtual Machine")
)
foreach ($a in $acronyms) {
  [void]$sb.AppendLine("<p><b>" + (Escape-Html ([string]$a[0])) + ":</b> " + (Escape-Html ([string]$a[1])) + "</p>")
}

[void]$sb.AppendLine("</body></html>")

$outDir = Split-Path -Parent $OutputPath
if (!(Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
[System.IO.File]::WriteAllBytes($OutputPath, [System.Text.Encoding]::UTF8.GetBytes($sb.ToString()))
Write-Host "Wrote report to: $OutputPath"


