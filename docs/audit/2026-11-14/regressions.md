# Fixes from the first audit, checked again

Checked on the dev VM at generation 266 (nyxos ed46205, nyx-packages 9045e4c, rebuilt for
this audit) or by reading the code, as noted. Only the fixes listed here were re-checked;
every other row of [remediation.md](../release-readiness/remediation.md) is **not
re-checked**.

| Finding | Result | How |
| --- | --- | --- |
| NYX-CI-001 format check | holds | `gh run list`: CI green on `main` and `stable` of nyxos and nyx-packages, 14 Nov |
| NYX-INST-001 `/mnt` | holds (code) | `plan.rs:284` makes `/mnt`; `iso/live-image.nix` tmpfiles rule. No ISO install run this time |
| NYX-INST-002 GC root | holds (code) | `plan.rs:372-376` and its test |
| NYX-A11Y-001 accessibility bus | holds | `org.a11y.Bus` on the session bus; no `NO_AT_BRIDGE`/`GTK_A11Y` in the session |
| NYX-APP-SHARE-001 port 53317 | holds | `iptables -S nixos-fw` has both rules |
| G4 AI endpoint off, key, Host check | holds | `nyx-aid-openai.socket` not enabled, nothing on :8080; code read (nyx-ai 185369e) |
| G5 Connect only on trusted networks | holds | 12100 only through the empty `nyx-trusted-net` chain; `fluxd` inactive (no phone paired) |
| G6 screen capture permissions | holds, with NYX-HYPR-010 | 6 allow rules and the deny in `hyprland.lua`; Hyprland matches the whole path, first rule wins |
| G7 recovery asks for a password | holds (code) | `apps/recovery/src/signin.rs`; no recovery boot this time |
| G8 shell failure notice | holds (configuration) | `OnFailure=nyx-shell-failed.service` on both units; not triggered |
| G9 signed releases | holds, with NYX-UPD-003/004 | `/etc/nyxos/release-signers` present; `signed.rs` read; System Manager's unit has git and ssh-keygen |
| NYX-SEC primary user in `input` | holds | `id ken`: no `input` |
| ptrace scope | holds | `kernel.yama.ptrace_scope = 1` |
| NYX-REL-001 duplicate D-Bus names | holds | no "Ignoring duplicate name" since the rebuild |
| Hyprland plugins under `/etc` | holds | both links present; rules name the `/etc` paths |
| NYX-APP-INSTALLER-002 leftovers | **new problem** | NYX-APP-INSTALLER-005 |
| NYX-APP-INSTALLER-004 4K sectors | holds (code) | `plan.rs` and `disks.rs` tests read |
| NYX-APP-ARCHIVE-002 extraction | partly | NYX-APP-ARCHIVE-004; not yet pinned in nyx-packages |
| NYX-APP-NOTEPAD-001/002, PDF-001/002, PHOTOS-002 | not in NyxOS yet | fixed on each app's `main`; nyx-packages still pins the commit before |
| App launches (smoke) | holds | 44 of 47 entries open from the dock; the 3 are Foot Server, Foot Client and uuctl, hidden per user (the script reads only the system's entries). No core dumps, no failed units |
| "Unable to acquire bus name" on launch | still there | Containers, Lyra, Passwords and Weather each leave a failed `dbus-…@.service` (first audit, reliability.md) |
