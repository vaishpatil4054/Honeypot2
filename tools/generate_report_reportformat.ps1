param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$OutputDocPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Honeypot2_Report_ReportFormat.doc"),
  [string]$OutputHtmlPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "Honeypot2_Report_ReportFormat.html")
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

function P([string]$text) {
  return "<p>" + (Escape-Html $text) + "</p>"
}

function Pre([string]$text) {
  return "<pre class='code'><code>" + (Escape-Html $text) + "</code></pre>"
}

function Bullets([string[]]$items) {
  $li = ($items | ForEach-Object { "<li>" + (Escape-Html $_) + "</li>" }) -join ""
  return "<ul>$li</ul>"
}

function HtmlTable($headers, $rows) {
  $th = ($headers | ForEach-Object { "<th>" + (Escape-Html $_) + "</th>" }) -join ""
  $tr = ($rows | ForEach-Object {
    $td = ($_ | ForEach-Object { "<td>" + (Escape-Html ([string]$_)) + "</td>" }) -join ""
    "<tr>$td</tr>"
  }) -join ""
  return "<table class='t'><thead><tr>$th</tr></thead><tbody>$tr</tbody></table>"
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

function Tail-Text([string]$relPath, [int]$lines) {
  $full = Join-Path $ProjectRoot $relPath
  if (!(Test-Path -LiteralPath $full)) { return "" }
  try {
    return [string]::Join("`n", (Get-Content -LiteralPath $full -Tail $lines -Encoding UTF8))
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

function Add-SourceSection([System.Text.StringBuilder]$sb, [string]$title, [string]$relPath) {
  $full = Join-Path $ProjectRoot $relPath
  if (!(Test-Path -LiteralPath $full)) { return }
  [void]$sb.AppendLine((Heading 3 $title))
  [void]$sb.AppendLine("<p class='small muted'>" + (Escape-Html $relPath) + "</p>")
  $content = Get-Content -LiteralPath $full -Raw -Encoding UTF8
  [void]$sb.AppendLine((Pre $content))
}

$requirements = Get-ReqText
$today = (Get-Date).ToString("dd MMMM yyyy")
$projectName = "Cyber Deception Honeypot Project (Python + Flask)"

$sb = New-Object System.Text.StringBuilder
$titleEsc = Escape-Html $projectName
[void]$sb.AppendLine("<!DOCTYPE html><html><head><meta charset='utf-8' /><title>Project Report - $titleEsc</title>")
[void]$sb.AppendLine(@"
<style>
  body { font-family: Calibri, Arial, sans-serif; font-size: 11pt; line-height: 1.35; color: #111; }
  h1 { font-size: 22pt; margin: 10pt 0 8pt; text-align: center; }
  h2 { font-size: 16pt; margin: 18pt 0 8pt; }
  h3 { font-size: 13pt; margin: 14pt 0 6pt; }
  h4 { font-size: 12pt; margin: 12pt 0 6pt; }
  p { margin: 6pt 0; text-align: justify; }
  ul { margin: 6pt 0 6pt 18pt; }
  .center { text-align: center; }
  .small { font-size: 10pt; }
  .muted { color: #444; }
  .chapter { font-weight: 700; text-align: center; font-size: 16pt; margin-top: 10pt; }
  .chapter-sub { font-weight: 700; text-align: center; font-size: 14pt; margin: 2pt 0 10pt; }
  .code { font-family: Consolas, 'Courier New', monospace; font-size: 9.5pt; white-space: pre-wrap; border: 1px solid #ddd; padding: 8pt; background: #fafafa; }
  .t { border-collapse: collapse; width: 100%; margin: 8pt 0; }
  .t th, .t td { border: 1px solid #444; padding: 5pt; vertical-align: top; }
  .t th { background: #f0f0f0; }
  .figure-title { font-weight: 700; margin-bottom: 4pt; }
  .figure { border: 1px solid #999; padding: 8pt; background: #fff; }
</style>
</head><body>
"@)

# Title page
[void]$sb.AppendLine("<div class='center'>")
[void]$sb.AppendLine("<h1>PROJECT REPORT</h1>")
[void]$sb.AppendLine("<h2 class='center'>" + (Escape-Html $projectName) + "</h2>")
[void]$sb.AppendLine("<p class='muted'>Generated on $today</p>")
[void]$sb.AppendLine("<p class='small muted'>Note: This .doc is HTML for easy generation; Word/Google Docs may render spacing slightly differently.</p>")
[void]$sb.AppendLine("</div>")
[void]$sb.AppendLine((PageBreak))

# Keep the chapter items; user said keep items as-is.
[void]$sb.AppendLine((Heading 2 "CONTENTS"))
[void]$sb.AppendLine((Bullets @(
  "CHAPTER - 1: INTRODUCTION",
  "CHAPTER - 2: LITERATURE REVIEW",
  "CHAPTER - 3: PROPOSED SYSTEM",
  "CHAPTER - 4: METHODOLOGY",
  "CHAPTER - 5: SYSTEM DESIGN",
  "CHAPTER - 6: IMPLEMENTATION",
  "CHAPTER - 7: TESTING",
  "CHAPTER - 8: ADVANTAGES AND FUTURE SCOPE",
  "CHAPTER - 9: CONCLUSION AND FUTURE WORK",
  "CHAPTER - 10: REFERENCES",
  "ANNEXURE: SCREENSHOTS, OUTPUT, CODE"
)))
[void]$sb.AppendLine((PageBreak))

# -------------------------
# CHAPTER 1 (kept as-is, from user-provided format)
# -------------------------
[void]$sb.AppendLine("<div class='chapter'>CHAPTER - 1</div>")
[void]$sb.AppendLine("<div class='chapter-sub'>INTRODUCTION</div>")
[void]$sb.AppendLine((Heading 3 "1.1 Introduction of the project"))
[void]$sb.AppendLine((P "Cybersecurity has become one of the most critical aspects of modern digital infrastructure as organizations increasingly rely on computer networks, cloud services, and internet-based systems to store and manage sensitive data. With the rapid expansion of digital technologies, cyber threats such as hacking, malware attacks, phishing, ransomware, and unauthorized access have also grown significantly. Traditional security mechanisms such as firewalls, antivirus software, and intrusion detection systems primarily focus on protecting systems by blocking malicious activities. However, attackers continuously develop new techniques to bypass these defenses. Because of this evolving threat landscape, cybersecurity professionals require advanced methods not only to prevent attacks but also to detect and understand them. One such approach is the concept of Cyber Deception, which involves creating misleading or fake environments within a network to attract and study attackers. Cyber deception technologies help security teams identify malicious behavior early and gain insights into the strategies used by cybercriminals."))
[void]$sb.AppendLine((P "A key component of cyber deception is the Honeypot, which is a decoy system designed to imitate real computer systems, services, or applications in order to attract potential attackers. A honeypot appears like a legitimate target within a network but is actually isolated and monitored by security professionals. When attackers attempt to interact with the honeypot system, their actions are carefully recorded and analyzed. This allows cybersecurity researchers to observe attack patterns, identify vulnerabilities being exploited, and understand the tools and techniques used by hackers. Unlike traditional security systems that simply block suspicious activities, honeypots allow organizations to study the behavior of attackers in a controlled environment without risking actual critical systems."))
[void]$sb.AppendLine((P "The Cyber Deception Honeypot project focuses on creating such a controlled environment where simulated services and systems are deployed to attract malicious users. These systems may mimic commonly targeted services such as web servers, databases, login portals, or network services. When an attacker attempts to scan or exploit these systems, the honeypot captures valuable information including login attempts, commands executed, malware uploaded, and network activity. This data can then be used for security analysis, threat intelligence collection, and improvement of defensive mechanisms. By analyzing the collected information, organizations can better understand emerging cyber threats and strengthen their cybersecurity strategies."))
[void]$sb.AppendLine((P "Honeypots are widely used across multiple domains within the field of cybersecurity. In network security, they help detect unauthorized access and scanning activities within a network. In malware analysis, honeypots can capture malicious software and allow researchers to study its behavior in a safe environment. In threat intelligence, honeypots collect real-world attack data that helps identify global cyberattack trends. They are also commonly used in cybersecurity research and education, where students and researchers can observe attacker techniques and learn about system vulnerabilities. Additionally, many organizations deploy honeypots as part of their security infrastructure to act as early warning systems that alert administrators about potential intrusions."))
[void]$sb.AppendLine((P "There are different types of honeypots depending on their level of interaction with attackers. Low-interaction honeypots simulate limited services and are easier to deploy and maintain. They provide basic information about attack attempts but do not allow deep interaction. High-interaction honeypots, on the other hand, simulate real operating systems and services, allowing attackers to interact more extensively with the system. This provides more detailed information about attacker behavior but requires careful monitoring to prevent misuse. Honeypots can also be categorized as production honeypots, which are used within organizations to enhance security, and research honeypots, which are used by cybersecurity researchers to study attack techniques and trends."))

[void]$sb.AppendLine((Heading 3 "1.2 Objectives of the Project"))
[void]$sb.AppendLine((P "The main objective of the Cyber Deception Honeypot Project is to design and implement a system that can detect, monitor, and analyze malicious activities by attracting potential attackers into a controlled and monitored environment. As cyber threats continue to increase in complexity and frequency, it is important for organizations and researchers to understand the behavior, techniques, and tools used by attackers. A honeypot-based cyber deception system helps in studying these threats without exposing real systems to risk. The project aims to demonstrate how deceptive technologies can be used to improve cybersecurity defense mechanisms and provide valuable insights into cyberattack patterns."))
[void]$sb.AppendLine((P "One of the primary objectives of this project is to develop a decoy system that imitates real network services and systems in order to attract attackers. These fake systems appear legitimate to hackers, encouraging them to interact with the environment. By doing so, the system can capture and record various types of attack activities such as login attempts, command executions, malware uploads, and network scanning behavior. This information helps security analysts understand the techniques used by attackers and identify potential vulnerabilities in network infrastructures."))
[void]$sb.AppendLine((P "Another important objective is to collect and analyze attack data generated by malicious users who interact with the honeypot system. The collected data can provide valuable insights into the types of attacks commonly performed, the tools used by attackers, and the patterns followed during cyber intrusions. By studying this data, organizations can improve their security strategies and develop stronger protection mechanisms against cyber threats."))
[void]$sb.AppendLine((P "The project also aims to demonstrate the concept of cyber deception as an effective cybersecurity strategy. Instead of only focusing on preventing attacks, cyber deception techniques mislead attackers by presenting them with fake systems and services. This allows defenders to gain intelligence about attack methods while keeping critical systems safe. Implementing such a strategy helps organizations detect intrusions at an early stage and respond more effectively to potential threats."))
[void]$sb.AppendLine((P "Another objective of this project is to create awareness and understanding of honeypot technology in the field of cybersecurity. The project serves as a practical example for students, researchers, and cybersecurity professionals to learn how honeypot systems work and how they can be implemented in real-world environments. It provides hands-on knowledge about monitoring attacker activities and analyzing security logs."))
[void]$sb.AppendLine((P "Finally, the project aims to enhance overall network security by identifying vulnerabilities and improving defensive strategies. By observing how attackers attempt to exploit systems, organizations can identify weaknesses in their infrastructure and take proactive measures to strengthen their security policies. In this way, the Cyber Deception Honeypot Project contributes to building more secure and resilient network environments."))
[void]$sb.AppendLine((PageBreak))

# -------------------------
# CHAPTER 2 (kept as-is, but update "Limitation of Existing System" to match this project)
# -------------------------
[void]$sb.AppendLine("<div class='chapter'>CHAPTER - 2</div>")
[void]$sb.AppendLine("<div class='chapter-sub'>LITERATURE REVIEW</div>")
[void]$sb.AppendLine((Heading 3 "2.1 Literature Review"))
[void]$sb.AppendLine((P "Cybersecurity researchers and professionals have increasingly explored the use of deception technologies to strengthen network defenses and improve threat detection capabilities. One of the most widely studied and implemented cyber deception techniques is the honeypot system. A honeypot is a decoy system intentionally designed to attract attackers and monitor their behavior in a controlled environment. Over the years, several studies and research papers have examined the effectiveness of honeypots in detecting cyber threats, collecting attack data, and improving overall security strategies."))
[void]$sb.AppendLine((P "Early research in the field of honeypots focused on understanding how attackers interact with vulnerable systems and how security professionals can use this information to improve defense mechanisms. Researchers introduced the concept of deploying fake services and systems that mimic real network resources. When attackers attempt to exploit these systems, their actions can be recorded and analyzed. These early studies demonstrated that honeypots can provide valuable insights into attacker behavior, including the tools, commands, and techniques used during cyber intrusions."))
[void]$sb.AppendLine((P "Several cybersecurity researchers have also explored the classification of honeypots based on their level of interaction with attackers. Low-interaction honeypots simulate limited services such as login systems or network ports and are primarily used for detecting automated attacks and scanning activities. High-interaction honeypots, on the other hand, provide real operating systems and applications that allow attackers to interact more deeply with the system. These honeypots are more complex but provide detailed information about attacker techniques and vulnerabilities being exploited. Research studies have shown that combining both types of honeypots can provide a balanced approach to monitoring cyber threats."))
[void]$sb.AppendLine((P "In recent years, cyber deception has evolved beyond traditional honeypots and has become a broader security strategy used by organizations to mislead attackers. Researchers have developed advanced deception systems that include fake databases, decoy credentials, and simulated network environments. These systems are designed to confuse attackers and divert them away from critical assets while security teams analyze their behavior. Studies indicate that deception-based security approaches significantly reduce the time required to detect intrusions because any interaction with a deceptive system is considered suspicious."))
[void]$sb.AppendLine((P "Many research projects have also focused on the integration of honeypots with other security technologies such as intrusion detection systems (IDS), security information and event management (SIEM) tools, and machine learning algorithms. This integration allows automated analysis of attack patterns and improves the efficiency of threat detection."))
[void]$sb.AppendLine((P "Overall, the literature indicates that cyber deception honeypots play an important role in modern cybersecurity strategies. They provide a proactive approach to detecting and understanding cyberattacks by allowing organizations to observe attacker behavior in a controlled environment. As cyber threats continue to evolve, researchers continue to explore new ways to enhance honeypot technologies and integrate them with advanced security solutions to improve the protection of digital infrastructures."))

[void]$sb.AppendLine((Heading 3 "2.2 Limitation of Existing System (Updated for this project)"))
[void]$sb.AppendLine((P "The following limitations summarize why a deception-based honeypot + dashboard approach is useful compared to only relying on traditional security tools:"))
[void]$sb.AppendLine((Bullets @(
  "Focus on prevention rather than analysis: firewalls and antivirus mainly block activity but do not capture detailed attacker behavior.",
  "Inability to detect new or unknown attacks: signature/rule-based tools may miss novel variations unless signatures are updated.",
  "High false positives: IDS and monitoring tools can generate noisy alerts that are difficult to triage.",
  "Limited information about attackers: blocking a request often loses context such as payload patterns, repeated attempts, and behavior over time.",
  "Reactive approach: many tools respond after suspicious activity is detected rather than providing early intelligence.",
  "Limited real-time attack intelligence: without a controlled sensor (honeypot), collecting realistic attack traces for study is harder.",
  "Limited capability to study attacker behavior: traditional controls rarely provide a safe environment to observe the attacker.",
  "Difficulty for students to demonstrate end-to-end monitoring: heavy SIEM stacks are complex; a lightweight pipeline is easier to reproduce."
)))
[void]$sb.AppendLine((Heading 3 "2.3 Problem Statement"))
[void]$sb.AppendLine((P "Traditional security mechanisms mainly focus on preventing attacks rather than understanding attacker behavior. Organizations often struggle to detect advanced or unknown attacks early, and alert noise makes triage difficult. Therefore, there is a need for a controlled environment that can attract attack attempts, record them as structured events, and visualize them to support analysis and learning. This project addresses that need using a local TCP honeypot, structured JSONL logging, and a Flask dashboard."))
[void]$sb.AppendLine((Heading 3 "2.4 Scope of the Project"))
[void]$sb.AppendLine((P "The scope of this project is a safe, local deception environment for learning and demonstration. The honeypot and dashboard run on localhost by default, collect and visualize attack-like interactions, and provide evidence through logs and UI screenshots. The project is intended for research/education and does not replace enterprise security controls; instead, it complements them by enabling observation and analysis."))
[void]$sb.AppendLine((PageBreak))

# -------------------------
# CHAPTER 3 (Replace with project-accurate Proposed System)
# -------------------------
[void]$sb.AppendLine("<div class='chapter'>CHAPTER - 3</div>")
[void]$sb.AppendLine("<div class='chapter-sub'>PROPOSED SYSTEM</div>")

[void]$sb.AppendLine((Heading 3 "3.1 Introduction to Proposed System (Updated to match this project)"))
[void]$sb.AppendLine((P "The proposed system is a Cyber Deception Honeypot with a Web Dashboard. Unlike large enterprise honeypots that simulate many services, this project focuses on a safe, lightweight implementation that can be demonstrated on a single machine. It consists of a TCP honeypot listener, an attacker simulator, a structured log file (JSONL), and a Flask-based dashboard that visualizes the collected events."))
[void]$sb.AppendLine((P "The honeypot listens on 127.0.0.1:8888 and captures inbound payload strings that resemble credential attempts. Each connection is classified using explainable rules and stored as a structured event record. The dashboard reads the log file and presents charts and an event table (newest-first) so that users can monitor activity in a live-style view."))

[void]$sb.AppendLine((Heading 3 "Proposed System (Key Points)"))
[void]$sb.AppendLine((Bullets @(
  "Implementation of Honeypot Technology: a low-interaction TCP honeypot collects suspicious payloads.",
  "Controlled Environment: services bind to localhost by default to avoid accidental exposure.",
  "Monitoring and Logging: each event is appended as JSON Lines (one JSON object per line).",
  "Attack Classification: rule-based severity assignment (LOW/HIGH/CRITICAL) based on keywords and thresholds.",
  "Dashboard Visualization: Flask UI shows severity mix, activity trend, top actors, and event drill-down.",
  "Simulator Support: attacker_simulator.py generates controlled traffic for testing and demonstration.",
  "Threat Data Storage: events are stored in data/logs.jsonl for later analysis and evidence.",
  "Educational Use: the complete pipeline is easy to set up and explain in a report."
)))

[void]$sb.AppendLine((Heading 3 "3.2 System Analysis"))
[void]$sb.AppendLine((Heading 4 "3.2.1 Functional Requirements (Mapped to this implementation)"))
[void]$sb.AppendLine((Bullets @(
  "System must start a TCP listener on 127.0.0.1:8888 (honeypot.py).",
  "System must capture payload strings and record the client IP address.",
  "System must classify events (attack type + severity) using rule-based logic.",
  "System must persist events in append-only JSONL format at data/logs.jsonl.",
  "System must provide a web dashboard (app.py) for login, intake, dashboard view, and event details.",
  "System must provide JSON APIs for summary and events to keep the dashboard charts updated.",
  "System must provide a simulator (attacker_simulator.py) for repeatable attack-like traffic.",
  "System must support safe operation and isolation by default (localhost binding)."
)))

[void]$sb.AppendLine((Heading 4 "3.2.2 Non-Functional Requirements (Implementation-aligned)"))
[void]$sb.AppendLine((P "Non-functional requirements describe how the system should behave in terms of quality:"))
[void]$sb.AppendLine((Bullets @(
  "Performance: handle repeated simulator bursts and still append logs without corruption.",
  "Reliability: append-only JSONL logging; dashboard tolerates missing/invalid lines.",
  "Usability: dashboard pages are simple and readable for demonstrations.",
  "Maintainability: modular scripts (honeypot.py, app.py, attacker_simulator.py, start_project.py).",
  "Safety: bind to 127.0.0.1 by default; treat inputs as text and never execute them.",
  "Scalability (future): schema and modules allow adding more simulated services/ports later."
)))

[void]$sb.AppendLine((Heading 4 "3.3 Algorithm Used (Actual project logic)"))
[void]$sb.AppendLine((P "The honeypot uses rule-based classification. Default credential keywords are treated as higher risk, and repeated attempts from an IP address increase severity. This logic is explainable and suitable for educational reporting."))
[void]$sb.AppendLine((Pre @"
On each TCP connection:
  receive payload and source IP
  attempts_from_ip[ip] += 1
  if payload contains 'admin' or 'root':
      severity = CRITICAL
      attack_type = Default Credential Attack
  else if attempts_from_ip[ip] >= 3:
      severity = HIGH
      attack_type = Brute Force Simulation
  else:
      severity = LOW
      attack_type = Weak Credential Attempt
  append event as JSON object to data/logs.jsonl
"@))
[void]$sb.AppendLine((PageBreak))

# -------------------------
# CHAPTER 4/5 (keep items but update architecture + ER diagram + output diagrams)
# -------------------------
[void]$sb.AppendLine("<div class='chapter'>CHAPTER - 4</div>")
[void]$sb.AppendLine("<div class='chapter-sub'>METHODOLOGY</div>")
[void]$sb.AppendLine((P "Methodology means the step-by-step approach used to design, implement, and evaluate the honeypot system. It explains how the project is carried out from planning to testing."))
[void]$sb.AppendLine((Bullets @(
  "Project Planning and Requirement Analysis",
  "Literature Review and Research",
  "System Architecture Design",
  "Implementation of Deception Mechanisms (low-interaction TCP honeypot)",
  "Logging and Monitoring System (JSONL + dashboard)",
  "Testing and Validation (simulator + dashboard evidence)",
  "Documentation and Reporting (screenshots, outputs, code)"
)))
[void]$sb.AppendLine((PageBreak))

[void]$sb.AppendLine("<div class='chapter'>CHAPTER - 5</div>")
[void]$sb.AppendLine("<div class='chapter-sub'>SYSTEM DESIGN</div>")

[void]$sb.AppendLine((Heading 3 "5.1 System Architecture (Updated to match this project)"))
[void]$sb.AppendLine((P "The system architecture in this implementation is local and consists of separate modules that communicate through an append-only event log. The attacker simulator connects to the honeypot via TCP, and the dashboard reads the generated JSONL events to visualize telemetry."))
[void]$sb.AppendLine((Pre @"
┌─────────────────────────┐
│ Attacker Simulator       │
│ (attacker_simulator.py)  │
└────────────┬────────────┘
             │ TCP (127.0.0.1:8888)
             ▼
┌─────────────────────────┐
│ TCP Honeypot             │
│ (honeypot.py)            │
│ - classify attempts       │
│ - append JSONL events     │
└────────────┬────────────┘
             │ writes
             ▼
┌─────────────────────────┐
│ data/logs.jsonl          │
│ (append-only event log)  │
└────────────┬────────────┘
             │ reads + aggregates
             ▼
┌─────────────────────────┐
│ Web Dashboard (Flask)     │
│ (app.py + templates)      │
│ - charts + event stream   │
│ - intake + detail pages   │
└─────────────────────────┘
"@))

[void]$sb.AppendLine((Heading 3 "5.2 E-R Diagram (Updated + Clear + Bold)"))
[void]$sb.AppendLine((P "Note: The implementation uses JSONL rather than a relational database, but an ER diagram is provided to clearly explain the event schema."))
[void]$sb.AppendLine((Pre @"
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
                 |       DETAILS      |
                 |--------------------|
                 | raw payload        |
                 | attempts_from_ip   |
                 | system / note      |
                 | other metadata     |
                 +--------------------+
"@))

[void]$sb.AppendLine((Heading 3 "5.3 Output / Results (Updated to match this project)"))
[void]$sb.AppendLine((P "The output of the project is the live dashboard that shows the event stream and summary charts. When the simulator runs, new events appear in the dashboard, severity counts update, and activity trends become visible."))
[void]$sb.AppendLine((P "Key output indicators include: total events, CRITICAL events, events over time (activity chart), and top actors within a recent time window."))
[void]$sb.AppendLine((PageBreak))

# -------------------------
# ANNEXURE (screenshots, output, code)
# -------------------------
[void]$sb.AppendLine((Heading 2 "ANNEXURE"))
[void]$sb.AppendLine((Heading 3 "A) Screenshots (Embedded + Placeholders)"))
[void]$sb.AppendLine((P "The following images are included from the project assets. Add real screenshots after running the project (login page, dashboard, event details, and terminal output)."))

$systemSvg = ImgDataUri "static\\img\\system.svg" "System overview"
if ($systemSvg) {
  [void]$sb.AppendLine("<div class='figure-title'>Screenshot/Figure 1: System Overview</div>")
  [void]$sb.AppendLine("<div class='figure'>$systemSvg</div>")
  [void]$sb.AppendLine("<p class='small muted'>Source: static/img/system.svg</p>")
}
$dashSvg = ImgDataUri "static\\img\\dashboard_mock.svg" "Dashboard mock"
if ($dashSvg) {
  [void]$sb.AppendLine("<div class='figure-title'>Screenshot/Figure 2: Dashboard Mock</div>")
  [void]$sb.AppendLine("<div class='figure'>$dashSvg</div>")
  [void]$sb.AppendLine("<p class='small muted'>Source: static/img/dashboard_mock.svg</p>")
}

[void]$sb.AppendLine((P "Screenshots to add manually:"))
[void]$sb.AppendLine((Bullets @(
  "Browser: /login page",
  "Browser: /dashboard page (charts + table)",
  "Browser: /event/<id> detail page",
  "Terminal: honeypot.py output",
  "Terminal: attacker_simulator.py output"
)))

[void]$sb.AppendLine((Heading 3 "B) Sample Output Logs (Last 100 lines)"))
$logTail = Tail-Text "data\\logs.jsonl" 100
if ($logTail) {
  [void]$sb.AppendLine((Pre $logTail))
} else {
  [void]$sb.AppendLine((P "No logs found at data/logs.jsonl. Run the project and simulator, then regenerate this report."))
}

[void]$sb.AppendLine((Heading 3 "C) Code (Updated to match this project)"))
[void]$sb.AppendLine((P "Key source files used in this implementation:"))
[void]$sb.AppendLine((Bullets @(
  "honeypot.py (TCP honeypot listener + rule-based classification)",
  "app.py (Flask dashboard + APIs + UI pages)",
  "attacker_simulator.py (traffic generator for testing)",
  "start_project.py / start_project.bat (launcher)",
  "templates/ and static/ (UI assets)"
)))

Add-SourceSection $sb "honeypot.py" "honeypot.py"
Add-SourceSection $sb "app.py" "app.py"
Add-SourceSection $sb "attacker_simulator.py" "attacker_simulator.py"
Add-SourceSection $sb "start_project.py" "start_project.py"
Add-SourceSection $sb "start_project.bat" "start_project.bat"

[void]$sb.AppendLine("</body></html>")

[System.IO.File]::WriteAllBytes($OutputDocPath, [System.Text.Encoding]::UTF8.GetBytes($sb.ToString()))
[System.IO.File]::WriteAllBytes($OutputHtmlPath, [System.Text.Encoding]::UTF8.GetBytes($sb.ToString()))

Write-Host "Wrote report (doc) : $OutputDocPath"
Write-Host "Wrote report (html): $OutputHtmlPath"
