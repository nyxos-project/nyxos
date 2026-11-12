# Performance (handoff 10 section 18)

Measured in VMs on one host (Intel Core Ultra 9 285H). VM numbers are indicative only:
CPU is virtualised, graphics go through virtio-gpu, storage is a file on Btrfs. Nothing
was measured on physical hardware, so none of these numbers is a claim about real
machines. Raw output: [evidence/logs/perf-*.txt](evidence/logs/), `installed-state.txt`,
`runtime-ai-core*.txt`.

## System

| Measure | Installed base system (install VM) | Dev VM (every Welcome app enabled) |
| --- | --- | --- |
| Boot (`systemd-analyze`) | 15.5 s: firmware 1.6, loader 3.5, kernel 0.8, initrd 6.4 (includes typing the LUKS passphrase), userspace 3.1 | 13.9 s: firmware 1.7, loader 3.5, kernel 0.9, initrd 3.9, userspace 4.0 |
| Login to desktop | 2.0 s from Enter at the greeter to the user's Hyprland; Welcome up within 30 s | (autologin) |
| Memory used, idle | 1.07 GB at the login screen | 2.3 GB of 16 GB with the session idle, all windows closed |
| User session RSS | not measured | 1.6 GB in 128 processes |
| CPU, idle 60 s | not measured | 1.7 % of 6 vCPU |
| Running services | | 52 user, 25 system |
| Disk | 8.2 GiB store, 8.7 GiB used on / | system closure 11.4 GiB |

Biggest resident processes in the idle session: Quickshell (bar, dock, Control Center,
OSD, Glimpse in one process) 297 MB; Clipboard's UI 140 MB; llama-server 75 MB with no
model loaded; Glimpse backend 50 MB; Hyprland 49 MB. Every root service is under 35 MB.

## Applications

Time from launch to the first window (polling Hyprland every 50 ms), warm cache, and RSS
4 s after start:

| App | Start (ms, 2 runs) | RSS (MB) |
| --- | --- | ---: |
| Store | 453 / 501 | 210 |
| Calculator | 576 / 511 | 131 |
| Notepad | 567 / 512 | 133 |
| Passwords | 535 / 519 | 132 |
| Activity | 581 / 510 | 131 |
| PDF | 595 / 595 | 146 |
| Calendar | 623 / 638 | 150 |
| Chat | 643 / 529 | 146 |
| Photos | 761 / 666 | 161 |
| Weather | 712 / 688 | 150 |
| Lyra | 798 / 771 | 235 |
| Files | 797 / 746 | 208 |
| Music | 813 / 712 | 174 |
| Mail | 885 / 720 | 220 |
| Settings | 913 / 941 | 233 |
| Notes, Git | one valid run each: 573, 608 | 143, 174 |

Every app opens in under a second. The floor of about 130 MB per GTK app (Calculator,
Notepad) comes from each app loading its own GTK, renderer and theme stack; several apps
open at once add up quickly (NYX-PERF-001).

## Shell

- Live theme change: the bar repainted 375 ms after `nyx-theme set`; running apps
  repainted without restart.
- Backend restart after a crash: under 4 s for every shell backend.
- Shell Core: 3 min 53 s CPU over 21 h of uptime (about 0.3 % of one core), 10.3 MB peak.
- Not measured: frame timing and animation smoothness (no frame-time tooling over
  virtio), overlay latency, notification latency.

## AI

In the dev VM with the only installed model (SmolLM2 135M, Q2_K): model load 5.3 s; first
request including the load 41.4 s; warm request 6.9 s for 16 tokens; prompt processing
15.7 tokens/s; the Vulkan device isn't used in the VM ("0.0 GB GPU"). These numbers say
nothing about hardware, where a 135M model should be far faster. AI Core's own statistics
showed "first token avg 0 ms; 0 tokens/s" after two completed endpoint requests: requests
through the OpenAI endpoint aren't counted (NYX-PERF-002). Voice latency, concurrent
requests and eviction: not measured.

## Findings

### NYX-PERF-001: Every GTK app costs at least 130 MB, and the shell 300 MB in one process

- **Component:** nyx-design (`nyx-ui`, `nyx-theme`) as built into each app; nyx-shell `nyx-shell-qs`
- **Category:** performance
- **Severity:** P3
- **Status of feature:** verified (VM)
- **Description:** RSS 4 s after start: Calculator 131 MB, Notepad 133 MB, Settings 233 MB; Quickshell 297 MB. Each app links and initialises its own copy of the theme and widget code (at seven different nyx-design revisions, NYX-PKG-002).
- **Expected:** Small utilities stay well under 100 MB on an 8 GB machine; handoff 10 section 18 asks for memory footprints to be measured and justified.
- **Actual:** evidence/logs/perf-app-startup.txt, perf-idle.txt.
- **Reproduce / verify:** `ps -o rss= -p $(pgrep -f nyx-calculator)` 4 s after starting it.
- **Evidence:** as above
- **Affected versions:** as pinned in nyx-packages d69e87e
- **User impact:** On 8 GB machines, a handful of Nyx apps plus a browser pushes into swap.
- **Recommended correction:** Profile one small app (heap and GPU renderer: GSK's GL vs Vulkan renderer, font and icon caches) before optimising; align nyx-design revisions first so a fix reaches every app.
- **Effort:** M
- **Dependencies:** NYX-PKG-002
- **Verification criteria:** Calculator and Notepad under 80 MB RSS on hardware.

### NYX-PERF-002: AI Core's statistics ignore requests made through its OpenAI endpoint

- **Component:** nyx-ai `crates/nyx-ai-core/src/openai.rs`, service statistics
- **Category:** performance
- **Severity:** P3
- **Status of feature:** verified
- **Description:** After two completed chat completions through 127.0.0.1:8080, `nyx-ai status` reported "Requests 2 … first token avg 0 ms; 0 tokens/s avg".
- **Expected:** Time to first token and throughput reflect every request (handoff 04, resource scheduling and diagnostics).
- **Actual:** evidence/logs/runtime-ai-core-api.txt
- **Reproduce / verify:** Two `curl` chat completions, then `nyx-ai status`.
- **Evidence:** as above
- **Affected versions:** nyx-ai d325462
- **User impact:** The numbers Settings and `nyx-ai status` show for coding-tool use are wrong; benchmarking through the endpoint is impossible.
- **Recommended correction:** Record timings for forwarded requests (llama-server returns `timings` in each response).
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `nyx-ai status` shows non-zero first-token time after an endpoint request.
