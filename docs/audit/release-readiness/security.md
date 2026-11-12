# Security

Handoff 10 §12. Static review on 2026-11-12 of the checkouts in `~/Projects` (no builds,
no VM changes); runtime facts are quoted only from [evidence/runtime-notes.md](evidence/runtime-notes.md)
and `evidence/logs/runtime-*.txt`, collected earlier in the dev VM. Revisions: nyxos
`97f1573`, nyx-packages `d69e87e`, nyx-system `6f0c47c`, nyx-core `9187295`,
nyx-greeter `6c4cce1`, nyx-biometrics `1fe62af`, nyx-ai `d325462`, nyx-voice `1ebd749`,
nyx-installer `1ea97f2`, nyx-assistant `58ed80e`, nyx-clipboard `0389ee0`, nyx-cloud
`ba6385f`, nyx-pulse `799f1b7`, flux tag `v0.19.1` (`c0c831b`, the revision
nyx-packages' `flake.lock` pins; the local checkout's HEAD is newer and was not used).
No credentials are reproduced here.

## Summary

| Area | Assessment | Worst |
| --- | --- | --- |
| Installed-system login | No autologin and no preset password reach installs: the installer writes neither (`nyx-installer/crates/nyx-install/src/plan.rs:391-435`) and sets the password with `chpasswd` on stdin (`plan.rs:333-337`); `nixos-install --no-root-passwd` leaves root locked. Disk encryption is on by default (`apps/installer/src/choices.rs:42`). The dev VM's autologin and known password live only in `hosts/incus-dev/default.nix:12-22`, used by the `incus-dev` output and check alone (`flake.nix:161-178`) | — |
| Lock screen | Nyx Locker on ext-session-lock, each method its own PAM service, password always present (`nyx-greeter/crates/nyx-lock-core/src/lib.rs:28-77`). Crash path is sound in config: wrapper falls back to hyprlock (`nyxos/modules/home/lock.nix:19-39`), unit restarts at once (`lock.nix:148-161`), Hyprland keeps the session locked and allows a new locker (`modules/home/hyprland.nix:50-51`). Locked keybinds are media keys only (`hyprland.nix:197-210`). Sleep waits for the lock (`lock.nix:60-66`) | P3 (SEC-011) |
| Polkit agent | Standard `polkit-agent-helper-1` socket conversation; the agent never decides the result (`nyx-greeter/apps/prompt/src/helper.rs:72-109`, `agent.rs:197-206`). No custom polkit rules or sudo `NOPASSWD` outside the live ISO (`iso/live-image.nix:187-190`) | — |
| Biometrics | PAM rules are `sufficient` ahead of the password with a gate for remote/inactive/lid-closed (`nyx-packages/modules/nixos/biometrics.nix:115-158`). Webcam face (Gaze) is accepted for every surface | P2 (SEC-006) |
| Recovery | Passwordless root console on the boot menu | P2 (SEC-005) |
| System Manager (root D-Bus) | Good: one polkit action per kind of change (`nyx-system/data/io.github.nyxos_project.system.policy`), subject is the caller's bus name (`apps/system-manager/src/main.rs:96-153`), changes are typed JSON with strict validators (`crates/nyx-system-proto/src/lib.rs:240-272,558-640,770-890`), never Nix text; passwords never enter the configuration (`main.rs:253-267`). Read-only methods are open to every account | P3 (SEC-012) |
| Caller identity (nyx-peer) | Program-path identity is spoofable by same-user code; the root key service also trusts `~/.local/bin` | P2 (SEC-002) |
| Privileges / root daemons | Root: `nyx-system-manager` (D-Bus activated, unsandboxed by necessity: it runs `nixos-rebuild`, `nyx-packages/modules/nixos/default.nix:497-517`), `nyx-auth-keyd@` (per-connection, well sandboxed, `nyx-biometrics/crates/nyx-auth-keyd/data/nyx-auth-keyd@.service`), snapper (`nyxos/modules/nixos/snapshots.nix:43,66`), plus NixOS services. Arch-only root helpers are removed from packages (`pkgs/nyx-settings.nix:34`, `pkgs/nyx-store.nix:14`, `pkgs/nyx-assistant.nix:6`). Every shell unit is a user unit. Primary user gets the `input` group | P2 (SEC-004) |
| Network exposure | Firewall on, SSH off and key-only (`modules/nixos/network.nix:1-20`), sysctl hardening (`security.nix:27-58`). Open by default: fluxd 12100 TCP/UDP on every interface; mDNS. Loopback: unauthenticated AI endpoint 127.0.0.1:8080 (runtime-confirmed). Assistant HTTP is bearer-token protected (`nyx-assistant/.../assistant-ipc/src/http.rs:200-228`); Cloud's rclone RC is on private Unix sockets (`nyx-cloud/src/main.rs:1261-1266`) | P2 (SEC-001, SEC-003) |
| Secrets | Accounts in the Secret Service (`nyx-accounts/src/store.rs`), user-supplied OAuth clients (no client secrets in source). Mail via Accounts, Home Assistant and Pulse via the keyring. HF token and rclone config are 0600 files (`nyx-chat/apps/chat/src/hf.rs:157-165`, `nyx-cloud/src/main.rs:1283`). No secret logging found (`rg` over `src/` for format strings naming password/token/secret: no hits). One shared third-party API credential in source | P3 (SEC-014) |
| Supply chain | All inputs pinned by `flake.lock`; fetchurl with fixed hashes; prebuilt third-party binaries limited to ntgcalls and opt-in CUDA llama (`pkgs/ntgcalls.nix:15-16`, `pkgs/llama-prism-cuda.nix:19-20`). AI model downloads are SHA-256 checked (`nyx-ai/.../downloads.rs:212-236`); plugin artifacts too (`nyx-core/crates/nyx-plugin/src/install.rs:131-187`); tool pins verify upstream digests (`nyxos/scripts/update-tool:92,110,157-174,199`). Voice models aren't checked. No release signing; user apps auto-update | P2 (SEC-007, SEC-008) |
| CI | Actions pinned by SHA, `contents: read` defaults, tool-update `propose` job has no secrets (`nyxos/.github/workflows/tool-updates.yml`). Both repositories push same-repo PR builds to the trusted cache | P3 (SEC-009) |

No P0 or P1 found statically. Nothing found lets a remote or unprivileged-other-user
attacker become root or unlock a session.

## Findings

### NYX-SEC-001: AI Core's OpenAI endpoint has no authentication and no Host/Origin check

- **Component:** nyx-ai `crates/nyx-ai-core/src/openai.rs`, `data/nyx-aid.socket`; nyx-packages `modules/nixos/default.nix:638-657`
- **Category:** security
- **Severity:** P2
- **Status of feature:** verified (static and dev-VM runtime)
- **Description:** `nyx-aid.socket` holds 127.0.0.1:8080 for every user session on every install (`nyx.ai.enable` defaults on, `nyxos/modules/nixos/apps.nix:79`). The endpoint answers any loopback peer, checks no token, `Host` or `Origin`, and ignores `Content-Type`. Any local account (other people, system services) can use the first user's models, and a web page can trigger model loads and inference with a "simple" cross-origin POST, or read replies via DNS rebinding. The Unix socket next to it does refuse other users (`server.rs:176-180`), so the TCP path is the weaker twin. The worker (`llama-server`) also inherits the listening socket (`evidence/logs/runtime-listening.txt`: llama-server holds fd 4 on 8080).
- **Expected:** §12 "Protected privileged IPC"; local APIs that start GPU work should require a per-user token or at least reject non-local `Host`/`Origin`.
- **Actual:** `openai.rs:42-51` routes `GET /health`, `/v1/models` and any `POST /v1/*`; `openai.rs:118-120` only checks `peer.ip().is_loopback()`; default address `config.rs:44`; `nyx-aid.socket` `ListenStream=127.0.0.1:8080`. Runtime: uid `nobody` got HTTP 200; a foreign `Host` and a `text/plain` POST with foreign `Origin` ran inference (`evidence/runtime-notes.md`, `logs/runtime-ai-core-api.txt`, `logs/runtime-ai-core-web.txt`).
- **Reproduce / verify:** `sudo -u nobody curl -s http://127.0.0.1:8080/v1/models`; `curl -s -H 'Host: evil.example' -H 'Origin: http://evil.example' -H 'Content-Type: text/plain' -d '{"messages":[{"role":"user","content":"hi"}],"max_tokens":4}' http://127.0.0.1:8080/v1/chat/completions`
- **Evidence:** above; runtime logs in `evidence/logs/`.
- **Affected versions:** nyx-ai `d325462`, nyx-packages `d69e87e`
- **User impact:** GPU/RAM exhaustion from any web page; other local users consume the owner's AI; model list disclosure. No user data or tools are reachable through this path (`service.rs:1059-1086` forwards inference only, as caller `openai`, untrusted).
- **Recommended correction:** Off by default (opt-in in Settings › AI for coding tools), or require `Authorization: Bearer` with a 0600 token in `$XDG_RUNTIME_DIR/nyx-ai/` that coding-tool setup reads; reject `Host` other than `127.0.0.1:PORT`/`localhost:PORT` and any `Origin` header; require `application/json`; mark the inherited fd close-on-exec for the worker.
- **Effort:** S
- **Dependencies:** AI audit (§14)
- **Verification criteria:** both curl commands above get 401/403; coding tools still work with the token.

### NYX-SEC-002: Caller identity by program path is spoofable; the root key service trusts `~/.local/bin`

- **Component:** nyx-biometrics `crates/nyx-auth-core/src/system.rs:38-42`, `crates/nyx-auth-keyd/src/{lib.rs,main.rs}`, `data/nyx-auth-keyd.socket`; nyx-core `crates/nyx-peer/src/lib.rs`
- **Category:** security
- **Severity:** P2
- **Status of feature:** implemented, not verified (static; confirm at runtime)
- **Description:** Services decide what a caller may do from `/proc/<pid>/exe` (Clipboard, Accounts, Passwords, Voice, AI Core, Shell Core, the key service). nyx-system's TrustApps carefully admits only cache-signed store paths "so nobody adds a program of their own by building something called nyx-mail" (`nyx-system/apps/system-manager/src/trust.rs:1-6`). But `suite_program`, which the root `nyx-auth-keyd` and the session broker use, also accepts any file in the caller's own `~/.local/bin` (`system.rs:38-42`), which every program of that user can write. keyd's comment says the opposite (`nyx-auth-keyd/src/lib.rs:17-19`). A same-user program copied to `~/.local/bin/nyx-passwordsd` passes the `CLIENTS` check (`lib.rs:15,71-73`), can `Clear` the face-unlock secret without any prompt (`lib.rs:78-82`), and can `Load` it with a polkit message it chooses (`lib.rs:106-119`, `purpose` is client text, `main.rs:20-36`); one fingerprint or face match then hands it the vault unlock secret. More generally, a same-user process can start a trusted binary under `LD_PRELOAD` or `ptrace` its own child, and trusted CLIs (`nyx-actions`, `nyx-glimpse`) act for whoever runs them (`nyx-peer/src/lib.rs:10-11` acknowledges this).
- **Expected:** §12 "Protected privileged IPC", "Correct authorization checks". A root service should not trust user-writable paths; prompts should carry text the service, not the caller, controls.
- **Actual:** as above; socket is `SocketMode=0666` (`nyx-auth-keyd.socket:6`), so every account can reach it (scoped per uid).
- **Reproduce / verify:** in the VM (biometrics on): `cp "$(command -v socat)" ~/.local/bin/nyx-passwordsd && echo '{"op":"exists","name":"vault"}' | ~/.local/bin/nyx-passwordsd - UNIX-CONNECT:/run/nyx-biometrics/keyd.sock` — expected today: `"ok":true`; after the fix: `"refused"`.
- **Evidence:** file references above.
- **Affected versions:** nyx-biometrics `1fe62af`, nyx-core `9187295`
- **User impact:** malware running as the user can obtain the Passwords unlock secret with one biometric confirmation it disguises, or silently disable face unlock. Requires prior code execution as the user.
- **Recommended correction:** On NixOS (`nixos()`), drop `~/.local/bin` (and `/usr/*`) from `suite_program`; use only `/etc/nyx/trusted-bin`. In keyd, build the polkit message from the program's identity ("Nyx Passwords wants to unlock your vault") and show `purpose` only as a detail; require a prompt for `Clear` or rate-limit it. Document the same-user limit in one place and consider `kernel.yama.ptrace_scope=1` explicitly in `security.nix`.
- **Effort:** S (path list, message); M (broader identity model)
- **Dependencies:** ARCH NYX-ARCH-010 (same-user IPC boundaries)
- **Verification criteria:** the command above returns `refused`; Passwords face unlock still works from its store path.

### NYX-SEC-003: Nyx Connect opens port 12100 on every network and interface by default

- **Component:** nyx-packages `modules/nixos/default.nix:362-381`; nyxos `modules/nixos/apps.nix:82-83`; flux `v0.19.1` `internal/lan/provider.go:168,179`
- **Category:** security
- **Severity:** P2
- **Status of feature:** verified (config and dev-VM listening sockets)
- **Description:** `nyx.connect.enable` defaults on, which opens 12100 TCP and UDP in the global firewall and enables Avahi publishing. fluxd binds `:12100` on all interfaces (runtime: `*:12100`, `logs/runtime-listening.txt`), so on café or hotel Wi-Fi any host can reach a Go TLS service, browse discovery and send pair requests (rate-limited: `pairing.go` `maxIncoming = 4`, `maxIncomingPerIP = 2`, 30 s retry). Pairing itself is sound (user-confirmed key over a pinned certificate). The remaining risk is attack surface and discovery on untrusted networks, with no per-network control.
- **Expected:** §12 least exposure; a phone link should listen only on networks the person marks as trusted, or only while Settings › Devices is open for pairing.
- **Actual:** global `networking.firewall.allowedTCPPorts/UDPPorts = [ 12100 ]`; no NetworkManager zone or trusted-network gate.
- **Reproduce / verify:** in the VM `ss -tulpn | grep 12100`; `sudo nft list ruleset | grep 12100`; from the host `nc -vz <vm-ip> 12100`.
- **Evidence:** above.
- **Affected versions:** nyx-packages `d69e87e`, nyxos `97f1573`
- **User impact:** reachable network service and hostname announcement on every network the laptop joins, even for people who never pair a phone.
- **Recommended correction:** Don't start fluxd or open the port until a device is paired or pairing is started; then open it only on trusted connections (firewalld zones or an NM dispatcher toggling an nft set), and stop mDNS publishing on public networks.
- **Effort:** M
- **Dependencies:** CONN audit (§15)
- **Verification criteria:** a fresh install with no paired device has no listener on 12100 and no firewall hole.

### NYX-SEC-004: Every primary user is in the `input` group

- **Component:** nyxos `modules/nixos/base.nix:64-75`
- **Category:** security
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The installer's account gets `input`, which grants raw read access to `/dev/input/event*`. Any program the user runs can read every keystroke, including passwords typed into Nyx Locker, the polkit prompt, `sudo`, and the greeter for other accounts if the user's processes linger. That defeats Wayland's input isolation and turns any user-level compromise into an easy root escalation via the admin password. No Nyx component needing it was found (`rg '/dev/input|uinput'` over Nyx sources: none outside tests); Settings itself warns "Can read keyboards and mice directly" (`nyx-settings/apps/settings/src/sections/accounts.rs:35`).
- **Expected:** §12 least privilege.
- **Actual:** `extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ]`.
- **Reproduce / verify:** `id` in the VM; `python3 -c "open('/dev/input/event0','rb').read(24)"` as the user succeeds.
- **Evidence:** above.
- **Affected versions:** nyxos `97f1573`
- **User impact:** keylogging of secrets by any user-level program.
- **Recommended correction:** Remove `input` (and review `video`/`audio`, which logind ACLs already cover for the active seat); grant per-device access via udev `uaccess` if a feature needs it.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** `id` shows no `input`; reading `/dev/input/event0` as the user fails with EACCES; keyboard, gestures and dictation still work.

### NYX-SEC-005: The Recovery boot entry is a passwordless root console

- **Component:** nyxos `modules/nixos/recovery.nix:40-82`, `boot.nix:84-145`; nyx-installer `crates/nyx-install/src/plan.rs:46-47`
- **Category:** security
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Every generation has a "recovery" specialisation in the Limine menu that autologins root on every console (`recovery.nix:50-52`) and runs `nyx-recovery` as root. With disk encryption off (an installer choice, `plan.rs:46-47`) anyone at the keyboard gets root in one menu selection. With encryption on, anyone who knows the disk passphrase (often shared in a household) bypasses the account password. Secure Boot is off by default (`boot.nix:47-55`) and there's no boot-menu password. The TPM2 unlock the header comment promises doesn't exist (SEC-013); if it's added, this entry becomes root for anyone with physical access.
- **Expected:** §12 authentication; recovery should ask for an administrator's password (systemd `rescue`/`sulogin` behaviour) unless no account has one.
- **Actual:** `services.getty.autologinUser = lib.mkForce "root"` in the specialisation.
- **Reproduce / verify:** reboot the VM, choose the recovery entry; observe a root prompt without a password.
- **Evidence:** above.
- **Affected versions:** nyxos `97f1573`
- **User impact:** physical-access root on unencrypted machines; login-password bypass on encrypted ones.
- **Recommended correction:** Require an admin's password (`sulogin`-style check in `nyx-recovery`, falling back to open only if root and every wheel account lack a password); warn in the installer when encryption is turned off; never pair with TPM-only unlock without this.
- **Effort:** S–M
- **Dependencies:** INST, REL audits
- **Verification criteria:** recovery asks for an administrator password; the documented "forgot my password" path still works from the installer USB.

### NYX-SEC-006: Webcam face matching (Gaze) can be a sufficient factor for sudo, polkit, login and unlock

- **Component:** nyx-packages `modules/nixos/biometrics.nix:174-184,248-266,115-158`
- **Category:** security
- **Severity:** P2
- **Status of feature:** implemented, not verified (opt-in per machine)
- **Description:** `nyx.biometrics.face = "gaze"` uses an ordinary RGB webcam, which the option text itself says "only shows someone is present" (`biometrics.nix:183`), i.e. a photo can pass. The module still lets it be `sufficient` on any surface, including `sudo` and `polkit`; the assertions only check that some face backend is set (`:254-257`).
- **Expected:** §12 "Face unlock where implemented"; presence-only factors shouldn't grant administrator rights.
- **Actual:** no restriction by backend.
- **Reproduce / verify:** evaluate a config with `face = "gaze"; surfaces.sudo = [ "face" ];` — it builds without warning.
- **Evidence:** above.
- **Affected versions:** nyx-packages `d69e87e`
- **User impact:** photo spoof can grant root or unlock when an admin chooses Gaze.
- **Recommended correction:** Assert `face != "gaze"` for `sudo`, `polkit` and `login` (allow `lock` only with an explicit `allowWebcamFace = true` and a warning), or require Irlume (IR) for those surfaces.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** the config above fails evaluation with a clear message.

### NYX-SEC-007: Voice models are downloaded at runtime without integrity checks

- **Component:** nyx-voice `crates/nyx-voice-engine/src/asr.rs:314-336`, `src/silero.rs:196-219`, `crates/nyx-voice-proto/src/settings.rs:111-113`, `src/asr.rs:26-28`
- **Category:** security
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** The Silero VAD model is fetched with `curl` from the mutable `master` branch of a third-party GitHub repository, automatically on first use, and loaded into ONNX Runtime with no hash. The ~650 MB ASR archive (`nyx-voice models fetch asr`, also run for the Assistant) is fetched and `tar xjf`-extracted with no hash and no path check. AI Core does verify models against Hugging Face's SHA-256 (`nyx-ai/crates/nyx-ai-core/src/downloads.rs:212-236`), so Voice is the outlier.
- **Expected:** §12 "Hash verification", "Third-party binaries".
- **Actual:** as above.
- **Reproduce / verify:** read the functions above; at runtime `strace -f -e trace=execve nyx-voice models fetch asr` shows bare `curl`/`tar`.
- **Evidence:** above.
- **Affected versions:** nyx-voice `1ebd749`
- **User impact:** a changed upstream file (repo compromise or branch change) is loaded into a parser running in the user's session with microphone access.
- **Recommended correction:** Pin both URLs to immutable revisions and embed SHA-256 sums; verify before use; extract with `--no-same-owner` into a temp dir and reject links and `..` (as nyx-plugin's `unpack_checked` does); or package the models in Nix.
- **Effort:** S
- **Dependencies:** VOICE audit (§14)
- **Verification criteria:** a tampered archive is refused with a checksum error.

### NYX-SEC-008: No release signing; user-level apps update automatically from the channel branch

- **Component:** nyx-installer `plan.rs:349-388` (`nyxos.url = "github:nyxos-project/nyxos/{channel}"`); nyx-packages `modules/nixos/default.nix:518-548`; nyxos `modules/nixos/base.nix:18-20`
- **Category:** security
- **Severity:** P2
- **Status of feature:** approved, not implemented (signing)
- **Description:** Installed systems follow a GitHub branch with no signed tags or commit verification. Integrity rests on GitHub account security and the `nyxos.cachix.org` signing key, which every install trusts as a substituter. System updates only notify, but per-user apps and tools "install themselves when set to auto, the default" from a daily timer (`default.nix:518-548`), so a malicious push to `stable` reaches every machine's user sessions without a click.
- **Expected:** §12 "Release signing where implemented", "Dependency pinning".
- **Actual:** no signing found in nyxos, nyx-packages or nyx-system's updater.
- **Reproduce / verify:** `rg -i 'gpg|minisign|cosign|verify-commit|signed' nyx-system/crates/nyx-update` finds nothing.
- **Evidence:** above.
- **Affected versions:** all
- **User impact:** a single compromised maintainer account or CI token can ship code to all users automatically.
- **Recommended correction:** Release tags signed (SSH or minisign) and verified by `nyx-update` before switching the channel pin; require 2FA and branch protection with reviews on `stable`; consider "notify" as the default for apps until signing exists.
- **Effort:** M
- **Dependencies:** UPD, REL audits; SEC-009
- **Verification criteria:** `nyx update` refuses an unsigned or wrongly signed channel revision.

### NYX-SEC-009: CI pushes pull-request builds to the trusted binary cache

- **Component:** nyx-packages `.github/workflows/ci.yml:3-7,75-79`; nyxos `.github/workflows/ci.yml:84-88`
- **Category:** CI
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** On `pull_request` from branches in the same repository the cachix action gets `CACHIX_AUTH_TOKEN` and pushes everything built, signed with the cache key all installs trust. The PR's workflow file runs with the token, so any collaborator branch can exfiltrate it before review. nyxos withholds the token only from `tool-update/` branches (`nyxos/.github/workflows/ci.yml:87-88`); every other PR branch gets it. nyx-packages has no gate at all. The cache signature is also what nyx-system's TrustApps uses to trust user-profile apps (`nyx-system/apps/system-manager/src/trust.rs:14-17`).
- **Expected:** §12 "CI permissions".
- **Actual:** nyx-packages: `authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}` unconditionally; nyxos: unless the branch is `tool-update/*`.
- **Reproduce / verify:** read the workflow.
- **Evidence:** above.
- **Affected versions:** nyx-packages `d69e87e`, nyxos `97f1573`
- **User impact:** limited to repository collaborators today; grows with contributors.
- **Recommended correction:** push only on `push` to `main`/`stable` (`authToken: ${{ github.event_name == 'push' && secrets.CACHIX_AUTH_TOKEN || '' }}`); use a GitHub environment with required reviewers for the token.
- **Effort:** S
- **Dependencies:** CI audit
- **Verification criteria:** PR runs show read-only cache access.

### NYX-SEC-010: Biometrics' entry in `/etc/nyx/trusted-bin` is overwritten by the activation script

- **Component:** nyx-packages `modules/nixos/biometrics.nix:276`, `modules/nixos/default.nix:259-283`
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** implemented, not verified (static; confirm at runtime)
- **Description:** biometrics.nix adds `${bio}/bin` through `environment.etc."nyx/trusted-bin".text`, but the `nyx-trust-bin` activation script runs after `etc` and replaces `/etc/nyx/trusted-bin` with `trusted-bin.system` plus profile folders, which don't include the biometrics folder. Two writers own one security-relevant file; the result depends on activation order.
- **Expected:** one owner for the trust list.
- **Actual:** as above.
- **Reproduce / verify:** in the VM `ls -l /etc/nyx/trusted-bin; grep -c nyx-biometrics /etc/nyx/trusted-bin`.
- **Evidence:** above.
- **Affected versions:** nyx-packages `d69e87e`
- **User impact:** biometrics' own programs may not be recognised by services that check the list; confusing to audit.
- **Recommended correction:** add the biometrics package to `enabledPackages` (or append to `trusted-bin.system`) and drop the `environment.etc` entry.
- **Effort:** S
- **Dependencies:** SEC-002
- **Verification criteria:** the grep finds the folder after `nixos-rebuild switch`.

### NYX-SEC-011: Nyx Locker authenticates the user named by `$USER`, not the session's uid

- **Component:** nyx-greeter `crates/nyx-lock-core/src/lib.rs:180-198`
- **Category:** security
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `user()` prefers the `USER` environment variable and falls back to the uid only when it's empty. The user manager's environment (imported by uwsm) decides whose password unlocks the session. Only same-user code can change it, but the lock screen shouldn't trust its environment for identity.
- **Expected:** §12 lock screen integrity.
- **Actual:** as above.
- **Reproduce / verify:** `systemctl --user set-environment USER=<other>` then lock: the locker asks for the other account's password (confirm at runtime; revert afterwards).
- **Evidence:** above.
- **Affected versions:** nyx-greeter `6c4cce1`
- **User impact:** low; hardening.
- **Recommended correction:** resolve the name from `getuid()` with `getpwuid_r` always.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** a changed `USER` has no effect.

### NYX-SEC-012: System Manager's read methods are open to every local account

- **Component:** nyx-system `apps/system-manager/src/main.rs:295-299,410-419`; `data/io.github.nyxos_project.System.conf`
- **Category:** privacy
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** `Settings`, `History` and `Generations` need no polkit check, and the bus policy lets anyone call. `system.json` includes the people NyxOS created, mounts (share addresses) and hostname; history includes who changed what.
- **Expected:** §12 least privilege for IPC.
- **Actual:** as above.
- **Reproduce / verify:** `sudo -u nobody busctl --system call io.github.nyxos_project.System /io/github/nyxos_project/System io.github.nyxos_project.System1 Settings`
- **Evidence:** above.
- **Affected versions:** nyx-system `6f0c47c`
- **User impact:** low on single-user machines; information disclosure on shared ones.
- **Recommended correction:** restrict reads to active local sessions (`allow_active yes` polkit read action) or to wheel.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** the call above is denied for `nobody`.

### NYX-SEC-013: Security documentation claims features that don't ship

- **Component:** nyxos `modules/nixos/security.nix:1-2`; nyx-packages `pkgs/nyx-passwords.nix:3-4`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** approved, not implemented (TPM2 unlock)
- **Description:** security.nix says "TPM2 unlock … come with the installer"; nothing in the installer, nyxos or nyx-system enrolls TPM2 (`rg -i 'cryptenroll|tpm2-device'`: none). nyx-passwords.nix says Nyx Biometrics "isn't packaged yet" though it is (`pkgs/nyx-biometrics.nix`).
- **Expected:** docs match behaviour (§2 evidence over assumptions).
- **Actual:** as above.
- **Reproduce / verify:** the `rg` above.
- **Evidence:** above.
- **Affected versions:** current
- **User impact:** misleading for reviewers; SEC-005's risk changes if TPM2 is added.
- **Recommended correction:** fix both comments; track TPM2 unlock as a planned feature with SEC-005 as a prerequisite.
- **Effort:** S
- **Dependencies:** SEC-005
- **Verification criteria:** comments accurate.

### NYX-SEC-014: Nyx Pulse ships a shared Telegram API credential in source

- **Component:** nyx-pulse `crates/nyx-telegram-core/src/auth.rs:28-29`, `apps/pulse/src/service.rs:85`
- **Category:** security
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** A Telegram API ID and hash (TDLib's public example pair, value not reproduced here) are the default for every install. Telegram's terms require each client to use its own; shared example IDs are rate-limited and accounts using them risk restrictions.
- **Expected:** §12 secrets: no shared credentials in source.
- **Actual:** defaults used unless the user sets `api_hash` in prefs (`apps/pulse/src/prefs.rs:23`).
- **Reproduce / verify:** read the lines.
- **Evidence:** above.
- **Affected versions:** nyx-pulse `799f1b7`
- **User impact:** login failures or account flags for Pulse users.
- **Recommended correction:** register a NyxOS API ID, inject it at build time (not in git), keep the user override.
- **Effort:** S
- **Dependencies:** APP-PULSE scorecard
- **Verification criteria:** no credential literal in the repository.

## Verified OK (static)

- SSH: off by default, keys only, no root (`network.nix:9-19`); Settings can turn it on (`overrides.nix:131`) and then it opens 22 (`openFirewall = true`).
- Live ISO: passwordless root/`nyxos` and passwordless sudo, no SSH (`iso/live-image.nix:169-190`). Expected for live media.
- Mount logins go to root-only files, never the Nix store (`nyx-system/apps/system-manager/src/main.rs:436-474`); mount options are character-limited (`proto/lib.rs:265-271`); groups are allow-listed and need `auth_admin` (`proto/lib.rs:590-592`, policy `system.groups`).
- Clipboard (`nyx-clipboard`) and Passwords honour `x-kde-passwordManagerHint`; fluxd does too (`flux v0.19.1 internal/desktop/clipboard.go:72-81`).
- No telemetry or analytics libraries in any Nyx repository.

## Runtime confirmation (Phase D, dev VM and installed VM)

| Finding | Runtime result | Evidence |
| --- | --- | --- |
| NYX-SEC-001 | **Confirmed.** 127.0.0.1:8080 served `/v1/models` and a chat completion with no key, to uid 65534 (`nobody`) as well as the user; a foreign `Host:` header is accepted (no DNS-rebinding defence); a `text/plain` POST with a foreign `Origin` (a browser "simple request") ran inference; no CORS headers are sent | logs/runtime-ai-core-api.txt, runtime-ai-core-web.txt |
| NYX-SEC-002 | **Confirmed.** A copy of socat saved as `~/.local/bin/nyx-passwordsd` got `{"ok":true,…}` from the root key service `/run/nyx-biometrics/keyd.sock` (mode 0666); the same binary under its own name was refused. Only the harmless `exists` query was sent | logs/runtime-security-probes.txt |
| NYX-SEC-003 | **Confirmed** on the dev VM and the installed system: firewall accepts 12100/tcp+udp and 5353/udp on every interface | logs/runtime-security-probes.txt, installed-state.txt |
| NYX-SEC-004 | **Confirmed on a fresh install:** the installer's user `amy` is in `input` | logs/installed-state.txt |
| NYX-SEC-005 | Not exercised (needs the boot menu) | |
| NYX-SEC-011 | Lock chain tested: crash of the locker → hyprlock; crash of hyprlock → locker restarted; LockedHint stayed yes; no window appeared over the lock; no bypass found | logs/lock-crash.txt |
| Installed defaults | No autologin and no preset password on the installed system (password set by the installer via chpasswd); SSH off by default (22 not open) | logs/installed-state.txt, install-plan-steps.txt |
