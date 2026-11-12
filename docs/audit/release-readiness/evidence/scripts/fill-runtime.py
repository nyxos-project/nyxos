#!/usr/bin/env python3
"""Replace each app scorecard's 'Filled in Phase D/F.' with its runtime results.

Usage (from the audit folder): evidence/scripts/fill-runtime.py
Reads evidence/smoke-dock/report.tsv, smoke-glimpse/report.tsv, logs/perf-app-startup.txt
and a table of app-specific runtime notes below.
"""
import csv
import glob
import os
import re

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.dirname(os.path.dirname(here))


def smoke(path):
    out = {}
    with open(path) as f:
        for row in csv.reader(f, delimiter="\t"):
            if len(row) >= 3:
                out[row[2].removesuffix(".desktop").lower()] = (row[0], row[1])
    return out


dock = smoke(os.path.join(root, "evidence/smoke-dock/report.tsv"))
glimpse = smoke(os.path.join(root, "evidence/smoke-glimpse/report.tsv"))
perf = {}
for line in open(os.path.join(root, "evidence/logs/perf-app-startup.txt")).read().splitlines()[1:]:
    parts = line.split()
    if len(parts) >= 3:
        perf[parts[0].lower()] = parts[1:]

# Desktop IDs per scorecard (some packages have several launcher entries).
ids = {
    "media-player": ["mediaplayer"], "office": ["write", "sheets", "present"],
    "photos": ["photos", "photoviewer"], "biometrics": [], "installer": [], "greeter": [],
    "cloud": [], "pdf": ["pdf"],
}
perf_names = {"office": "office", "pdf": "pdf"}

extra = {
    "files": "No data-loss defect reproduced at runtime; under a full disk Files starts and logs 'No space left on device' for its assets and open tabs (logs/disk-full.txt). With the accessibility bridge forced on, 26/26 visible buttons have names (logs/atspi-buttons.txt).",
    "settings": "Connected Devices with fluxd stopped shows 'Flux isn't running … Start Flux' (shots/settings-devices-fluxd-stopped.png). 55/55 visible buttons named with the bridge forced on. Launch logs 'Failed to register: Unable to acquire bus name' though the window opens (NYX-REL-001).",
    "store": "Offline, the header shows the raw Flathub resolver error (NYX-UX-002). 4 of 60 buttons unnamed (NYX-A11Y-003).",
    "calculator": "Repaints live on a theme change (logs/theme-switch.txt); 32/32 buttons named; starts on a full disk.",
    "notepad": "8/8 buttons named; starts on a full disk (logs/disk-full.txt).",
    "mail": "29/29 buttons named. Per-user install fails after Calendar (NYX-PKG-008) on the installed system.",
    "calendar": "Per-user install on the installed system works, but its D-Bus name isn't activatable, `nyx calendar` is unknown and its daemon waits for the next sign-in (NYX-PKG-009); a second app with session units then can't install (NYX-PKG-008).",
    "backup": "CLI backup to a local repository, full verify (0 errors) and restore to a separate folder: byte-identical (logs/backup-restore*.txt). `schedule --enable` writes a timer whose ExecStart is a /nix/store path (BACKUP-001 premise confirmed).",
    "archive": "Crafted zip (`../`, absolute path, symlink escape) extracted with the shipped 7-Zip 26.04 and the app's switches: nothing escaped the destination (logs/archive-zipslip.txt); ARCHIVE-002 not reproduced.",
    "glimpse": "Opens as an overlay from the dock and via GIO; Escape closes it. Can't open while Shell Core is down; the first toggle 2 s after Shell Core returns does nothing (logs/shell-core-loss.txt). Opens on a hot-plugged monitor when focused.",
    "share": "Firewall on the dev VM and the installed system accepts only 22 (dev VM), 12100, 5353 and ICMP: 53317 closed, confirming SHARE-001's premise (logs/runtime-security-probes.txt, installed-state.txt).",
    "welcome": "On the installed system Welcome opens at the first sign-in on its first page (14 steps) (shots/installed-first-login.png). 'Review and apply' not exercised end to end.",
    "installer": "Headless install with the same steps fails at step 11 on the 0.1.0 ISO (`/mnt` missing, NYX-INST-001); with `/mnt` created it installs in 112 s and boots (installation.md). GUI pages and the keyboard-layout issue (INSTALLER-001) not exercised.",
    "greeter": "On the installed system: user card, focused password field, power buttons; typing the password signed in, session up 2.0 s later; wordmark cut to 'NYX' at 1280×800, session named 'Hyprland (uwsm-managed)' (NYX-UX-003, shots/installed-greeter.png).",
    "biometrics": "Lock screen: face first with 'Use password'; locker crash → hyprlock takes over → locker restarted; session stayed locked (logs/lock-crash.txt). Face/fingerprint gates fail in the VM (no hardware) and the password works. NYX-SEC-002 key-service spoof confirmed.",
    "clipboard": "Overlay opens from the dock and GIO and closes with Escape; daemon restarted within 4 s after SIGKILL.",
    "assistant": "Not exercised at runtime (wake word, voice and actions need audio hardware); its daemons and Aura/HUD units run on the dev VM.",
    "chat": "AI Core endpoint answered without a key from any local user (NYX-SEC-001 confirmed); Chat UI opened; inference in the VM is not representative.",
    "notes": "First run is a separate vault dialog with flat buttons and larger text than the suite (ux-accessibility.md); starts on a full disk.",
    "lyra": "Content area is YouTube Music's own web page (shots via smoke-dock).",
    "weather": "Offline it keeps showing cached data with no visible offline note (shots/offline-weather.png).",
    "cloud": "nyx-cloudd listens on 127.0.0.1:35951 (logs/runtime-listening.txt).",
}

for path in sorted(glob.glob(os.path.join(root, "apps/*.md"))):
    name = os.path.basename(path)[:-3]
    if name == "TEMPLATE":
        continue
    text = open(path).read()
    if "Filled in Phase D/F." not in text:
        continue
    lines = []
    for i in ids.get(name, [name]):
        key = f"io.github.design_nexus.nyx.{i}"
        d = dock.get(key)
        g = glimpse.get(key)
        if d:
            lines.append(f"- Smoke test ({d[1]}): dock launch **{d[0]}**, Glimpse/GIO launch **{g[0] if g else 'n/a'}** (evidence/smoke-dock, smoke-glimpse).")
    p = perf.get(perf_names.get(name, name))
    if p and p[0] != "timeout":
        rss = p[2] if len(p) > 2 else "?"
        lines.append(f"- Start to first window {p[0]} / {p[1]} ms (two warm runs), RSS {rss} MB 4 s after start (logs/perf-app-startup.txt, dev VM).")
    if name in extra:
        lines.append(f"- {extra[name]}")
    if not lines:
        lines.append("- Not exercised at runtime in this audit.")
    text = text.replace("Filled in Phase D/F.", "\n".join(lines))
    open(path, "w").write(text)
    print(name, len(lines))
