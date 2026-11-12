# Reliability and recovery (handoff 10 sections 6, 19)

All tests ran in the dev VM (`nyxos-dev`, generation 245) between 01:30 and 04:35 on
2026-11-12, with an Incus snapshot taken first and restored afterwards. Commands and
output: [evidence/logs/](evidence/logs/); narrative: [evidence/runtime-notes.md](evidence/runtime-notes.md).

## Results

| Test | Result | Evidence |
| --- | --- | --- |
| Every launcher entry opened from the dock and through GIO (as Glimpse launches) | 46 of 48 open both ways; the 2 that don't are helper entries ("Foot Server", "uuctl") | smoke-dock/, smoke-glimpse/ |
| SIGKILL each backend once (bar, dock, CC, Glimpse, notifications ×2, switcher, theme, fluxd, AI Core, clipboard) | **pass**: each restarted within 4 s, surfaces and D-Bus names back | logs/shell-backend-kills.txt |
| Quickshell (bar + dock + CC + OSD + Glimpse) killed 6 times in a minute | **fail**: systemd's start limit stops it; only the wallpaper is left; nothing restarts it (NYX-SHELL-001) | logs/shell-qs-crashloop.txt, shots/shell-qs-crashloop.png |
| Shell Core killed with Glimpse open | Escape still closes Glimpse (not reproduced); while Shell Core is down Glimpse can't open; first toggle 2 s after it returns does nothing, later ones work (NYX-SHELL-002, partly) | logs/shell-core-loss.txt |
| Lock screen: crash the locker, then the fallback | **pass**: hyprlock takes over, then nyx-lock restarts; LockedHint stays yes; a new window never shows over the lock | logs/lock-crash.txt, shots/lock-*.png |
| Monitor hot-plug (headless output in the VM) | **fail**: wallpaper and Glimpse on the new output, no bar, no dock after 20 s (NYX-REL-003) | logs/monitor-hotplug.txt |
| Low memory (MemAvailable driven to 30 MB) | **pass**: kernel OOM killer took only the hog; no service lost | logs/low-memory.txt |
| Disk full (XDG folders on a full tmpfs) | **pass**: apps start; CLIs report "No space left on device" | logs/disk-full.txt |
| Network loss | **pass** with rough edges: everything recovers; some errors are raw (NYX-UX-002) | logs/network-loss.txt |
| Interrupted System Manager change | **fail**: overrides keep the unapplied change (NYX-REL-002) | logs/interrupted-system-change.txt |
| Failed system build | **pass**: change undone, system unchanged | logs/installed-after-gc-settings.txt |
| Rollback | **pass**: 4 s, history recorded | logs/rollback.txt |
| Corrupt config | dock: **pass** (kept as `.broken-…`, defaults); theme: silently falls back to the system theme (NYX-THEME-003) | logs/config-corruption.txt |
| Backup and restore | **pass**: restore to a separate folder byte-identical | logs/backup-restore*.txt |
| Connect with fluxd stopped | **pass**: clear "Flux isn't running" with Start Flux | logs/connect-fluxd-stopped.txt |
| Suspend/resume, GPU reset, device disconnect | not tested (VM) | [hardware.md](hardware.md) |

## Unrecoverable or user-hostile failure modes found

1. Installing from the 0.1.0 ISO (NYX-INST-001, P0).
2. System changes after the first weekly GC (NYX-INST-002, P1).
3. The whole visible shell gone after a crash loop, recoverable only from a terminal
   with `systemctl --user reset-failed` (NYX-SHELL-001, P2).

## Findings

### NYX-REL-001: The journal is flooded with duplicate D-Bus service warnings and per-launch QML warnings

- **Component:** nyx-packages `modules/nixos/default.nix` (`services.dbus.packages` plus `environment.systemPackages`); nyx-dock `CardPopup.qml:75`
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Every D-Bus service file is found twice (the package's store path and `/run/current-system/sw/share/dbus-1`), and dbus-broker logs "Ignoring duplicate name" at error priority on every reload: 3,050 error-priority lines this boot. Two different nyx-system store paths both provide `io.github.design_nexus.nyx.Theme`. Every app launch logs `CardPopup.qml:75: Unable to assign [undefined]`; launching Files, Music and Settings logs "Failed to register: Unable to acquire bus name" though the window opens.
- **Expected:** An idle system's error log is near-empty so real errors stand out.
- **Actual:** evidence/logs/runtime-system-journal-errors.txt.gz; smoke-dock/report.tsv.
- **Reproduce / verify:** `journalctl -b -p err | grep -c 'Ignoring duplicate'`
- **Evidence:** as above
- **Affected versions:** nyx-packages d69e87e
- **User impact:** Diagnosing real failures is harder; crash reports and support logs are noise.
- **Recommended correction:** Install D-Bus service files through one path only; find the second nyx-system in the bus's service directories; fix the dock's undefined binding; check the activation path of the three apps that lose the bus-name race.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `journalctl -b -p err` on a fresh boot has no "Ignoring duplicate" lines; smoke test logs no CardPopup warnings.

### NYX-REL-002: An interrupted System Manager change leaves the unapplied change in the overrides layer

- **Component:** nyx-system `apps/system-manager` (change application)
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, verified defective
- **Description:** The System Manager writes `/etc/nyxos/overrides/system.json` before building and only restores it if the build fails. If the manager dies mid-build (crash, OOM, power loss), the file keeps the new value, nothing records the change, and the next unrelated change silently applies it.
- **Expected:** "a change is built before it's switched to, and undone if either fails" (nyxos README); an interrupted change is undone or completed on restart (handoff 08 section 3.5).
- **Actual:** `nyx-system service fwupd on`, manager SIGKILLed 6 s in: client "Remote peer disconnected"; `system.json` contains `"fwupd": true`; no history entry; running system unchanged.
- **Reproduce / verify:** as above; `cat /etc/nyxos/overrides/system.json`.
- **Evidence:** evidence/logs/interrupted-system-change.txt
- **Affected versions:** nyx-system 6f0c47c
- **User impact:** After a crash or power cut during a change, a later change (or update) turns on something the user never saw applied, or keeps failing for a reason they can't see.
- **Recommended correction:** Write the new overrides to a staging file, build with it, and rename over `system.json` only after the switch succeeds; on start, discard a leftover staging file and log it.
- **Effort:** S–M
- **Dependencies:** none
- **Verification criteria:** Repeat the reproduction: `system.json` is unchanged afterwards and the next change applies only itself.

### NYX-REL-003: A monitor connected while the session runs gets no bar or dock

- **Component:** nyx-shell `nyx-shell-qs` (bar and dock surfaces per screen)
- **Category:** reliability
- **Severity:** P2
- **Status of feature:** implemented, verified defective in the VM; confirm on hardware
- **Description:** After `hyprctl output create headless` the new output gets the wallpaper and Glimpse opens there, but neither the bar nor the dock appears, at 2, 5, 10 or 20 s. No bar or dock setting restricts monitors (`nyx settings value bar monitors` → program default).
- **Expected:** Nyx Bar is "on every monitor" (its README); handoff 03 section 4.4 (shared monitor awareness) and handoff 10 section 7.
- **Actual:** evidence/logs/monitor-hotplug.txt (layer lists per monitor), shots/monitor-added.png.
- **Reproduce / verify:** In a session: `hyprctl output create headless`, then `hyprctl layers -j`.
- **Evidence:** as above
- **Affected versions:** nyx-shell 975092e, nyx-bar 4a84c75, nyx-dock 0cd8173
- **User impact:** Plugging in an external display gives a screen with no bar or dock until the shell restarts (if the behaviour is the same with physical outputs).
- **Recommended correction:** Make the bar and dock surfaces follow `Quickshell.screens` changes (Variants model), or restart the surfaces on output changes from Shell Core's monitor state; add a hot-plug test.
- **Effort:** S–M
- **Dependencies:** NYX-ARCH-001 (Shell Core already tracks monitors)
- **Verification criteria:** With a second physical display plugged in during a session, the bar and dock appear on it within 2 s, and leave cleanly on unplug.
