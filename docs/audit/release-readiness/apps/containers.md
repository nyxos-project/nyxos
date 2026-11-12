# Nyx Containers scorecard

- **Repository:** design-nexus/nyx-containers at `bd049445a4` (pinned in nyx-packages: yes, 0 commits behind origin/main)
- **Release tier:** welcome ("Manage Podman and Docker containers."; note "Works with Podman or Docker")
- **Purpose:** manage Incus VMs/system containers and Docker containers/Compose stacks locally and on one remote host
- **Stack:** Rust/GTK4, Bollard (Docker Engine API over a Unix socket), Incus over its Unix socket or HTTPS with TLS pinning, VTE (terminals), spice-gtk (VM display), GtkSourceView (Compose editor), `secret-tool` for remote credentials, nyx-actions (API 2)
- **Binaries / services:** `nyx-containers` (`nyx-packages/pkgs/nyx-containers.nix`: `actions = [ "nyx-containers" ]`, `vte-gtk4`, `gtksourceview5`, `spice-gtk`; runtime `libsecret`, `openssh`). Engines and pkexec come from the system (`virtualisation.docker` / `virtualisation.incus`, comment in the package); option `nyx.containers.enable` (`modules/nixos/default.nix:35`) adds no engine configuration

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Incus and Docker are deep (hardware, snapshots, SPICE display, Compose); no Podman backend although the catalog advertises it |
| UX | 2 | Cards, tabs, filters; Diagnostics offers Arch commands on NyxOS |
| Accessibility | 2 | 21 tooltips on 13 icon sites, 4 explicit labels |
| Reliability | 3 | 1 unwrap and 2 expects outside tests; SSH host key and TLS pin required before remote traffic |
| Integration | 2 | Actions manifest and Glimpse `containers` panel; engine setup doesn't fit NixOS |
| Packaging | 2 | App packaged; engines left to the catalog's Docker/Incus items with no link from the Containers item |
| Maintainability | 2 | 43 tests, check.yml CI; README install is Arch-only; source header says Omarchy |

## Functionality

- Backends: Incus (`apps/containers/src/engines/incus.rs`) and Docker (`engines/docker.rs:1`, "Docker Engine API via Bollard"). No Podman, no libvirt.
- Docker socket candidates: `DOCKER_HOST` (unauthenticated TCP refused, `docker.rs:28-34`), `$XDG_RUNTIME_DIR/docker.sock` (`docker.rs:43`), `/var/run/docker.sock` (`prefs.rs:34`). Podman's `$XDG_RUNTIME_DIR/podman/podman.sock` is not probed.
- Remote: Docker over SSH with host-key check (`security/ssh.rs`), Incus over HTTPS with SHA-256 certificate pinning (`security/tls.rs:1-44`); secrets in the Secret Service with a redacting `Debug` (`services/credentials.rs:1-33`).
- Persistence: prefs (`prefs.rs`), history (`history.rs`).
- Limits documented: one remote, no SPICE USB redirection, no clipboard sync (README "Limits").

## UX and accessibility (static)

- Keyboard: Ctrl+Tab, Ctrl+W, Ctrl+1…9 for tabs (README); VM display grab released with Ctrl+Alt.
- Icon buttons mostly tooltipped; `cards.rs:829`, `create.rs:312,368`, `tabs/hardware.rs:404` flagged by the heuristic.
- Hard-coded colours only in `mockups/proposal-b/*.css` (not shipped).

## Reliability

- Worker thread for engine calls (`worker.rs`); live stats (`services/live.rs`).
- Privilege model: the app talks to root daemons through their sockets, so access requires `docker` or `incus-admin` group membership, both root-equivalent. The app requests nothing itself, but Diagnostics' Fix runs `usermod -aG docker $USER` and others through `pkexec` (`services/diagnose.rs:55-67,169-193`).

## Integration and packaging

- Desktop entry `apps/containers/data/io.github.design_nexus.nyx.Containers.desktop` (System;Monitor); icon in `data/icons` and `crates/nyx-icons`.
- Actions: `control.rs:56`, `main.rs:52`; Glimpse panel `nyx-glimpse/quickshell/Glimpse/panels/containers`.
- Catalog: the Docker item installs `docker-compose`, turns on `docker` and asks to add the `docker` group; Incus asks for `incus-admin` (`catalog.toml:963-991`). The consent line reads "Adds you to the docker group: Docker" (`nyx-system/crates/nyx-catalog/src/lib.rs:200`), with no root-equivalence warning.
- Omarchy: `main.rs:1` comment; `engines/incus.rs:278` maps an "omarchy" image name (harmless).

## Maintenance

- Tests: 43; CI `check.yml`, `release.yml`.
- Pins: nyx-core `4f05fb8`, nyx-design `cf39397`.
- Docs: README describes `install.sh` with sudo and Arch packages; "Suite registration and a public GitHub repo stay off until you ask" is stale (the app is in nyx-packages and the catalog).

## Runtime results

- Smoke test (Containers): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-CONTAINERS-001: Catalog advertises Podman, but the app has no Podman backend

- **Component:** `nyx-system/crates/nyx-catalog/catalog.toml:374-381`; nyx-containers `apps/containers/src/engines/`
- **Category:** functionality
- **Severity:** P1
- **Status of feature:** approved, not implemented
- **Description:** Welcome and Store describe Nyx Containers as "Manage Podman and Docker containers" and say it "Works with Podman or Docker". The app supports Incus and Docker only; the Docker engine probes Docker sockets only, and the catalog's Podman item doesn't enable Podman's Docker-compatible socket.
- **Expected:** The advertised workflow works: choosing Podman in Welcome gives a working Containers.
- **Actual:** No `podman` string anywhere in `apps/`; socket candidates at `engines/docker.rs:21-43`, `prefs.rs:34`.
- **Reproduce / verify:** Install Podman and Nyx Containers from Welcome; open Containers (static; confirm at runtime: expect "Docker is not available").
- **Evidence:** as cited; `catalog.toml:974-981` (Podman item: `services = ["podman"]`, no `dockerSocket`)
- **Affected versions:** nyx-containers `bd049445a4`; catalog at nyx-system `6f0c47c`
- **User impact:** A user following Welcome's advice gets an empty manager.
- **Recommended correction:** Short term: change the catalog text to "Incus and Docker". Longer term: add the rootless Podman socket as a Docker candidate (or enable `virtualisation.podman.dockerSocket`).
- **Effort:** S (text) / M (Podman support)
- **Dependencies:** NYX-APP-CONTAINERS-002
- **Verification criteria:** Catalog text matches the backends, or Containers lists Podman containers.

### NYX-APP-CONTAINERS-002: Diagnostics "Fix" runs Arch commands through pkexec on NyxOS

- **Component:** nyx-containers `apps/containers/src/services/diagnose.rs:55-67,144-158,169-193`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Fix runs `pacman -S --needed docker docker-compose`, `pacman -S --needed incus|vte4`, `systemctl enable --now docker.socket …` and `usermod -aG …` as root via pkexec. On NyxOS there's no pacman, units don't exist unless the NixOS module is on, and imperative group changes bypass the system configuration. The VTE check looks for `/usr/lib/pkgconfig/vte-2.91-gtk4.pc` or `pkg-config`, neither present on NyxOS, so it reports a false failure although VTE is linked in.
- **Expected:** NyxOS-aware fixes: open Store/Welcome for the Docker or Incus item (which handles services, groups and consent), and no VTE check in a packaged build.
- **Actual:** as cited.
- **Reproduce / verify:** Settings → Diagnostics on NyxOS without Docker (static; confirm at runtime).
- **Evidence:** as cited
- **Affected versions:** `bd049445a4`
- **User impact:** Password prompts for commands that fail; a permanent false "Fail".
- **Recommended correction:** Detect NixOS (`/etc/NIXOS`) and link to the catalog items; drop the VTE check when built by Nix.
- **Effort:** S
- **Dependencies:** NYX-APP-CONTAINERS-003
- **Verification criteria:** On NyxOS no pacman/usermod commands are offered and VTE shows OK.

### NYX-APP-CONTAINERS-003: Root-equivalent group access isn't explained

- **Component:** `nyx-system/crates/nyx-catalog/src/lib.rs:200` (`Consent::Group`); nyx-containers `services/diagnose.rs:58-62`
- **Category:** security
- **Severity:** P2
- **Status of feature:** implemented, not verified
- **Description:** Using Containers requires `docker` or `incus-admin` membership, which grants root on the machine. Welcome asks "Adds you to the docker group: Docker" with an "I agree" box but doesn't say it amounts to admin rights, and the app's Fix path adds the groups via pkexec without the catalog's consent step.
- **Expected:** Consent text states the group gives full control of the computer (as Docker's own docs say); one consent path.
- **Actual:** as cited.
- **Reproduce / verify:** Select Docker in Welcome; read the agreement row.
- **Evidence:** `nyx-welcome/apps/welcome/src/steps/review.rs:114-133`
- **Affected versions:** nyx-containers `bd049445a4`; catalog at nyx-system `6f0c47c`
- **User impact:** Users grant root-equivalent access unknowingly; malware running as the user can become root.
- **Recommended correction:** Add a per-group risk sentence to `Consent::Group`; route Fix through the catalog; mention rootless Podman as the safer option once supported.
- **Effort:** S
- **Dependencies:** NYX-SEC, NYX-APP-CONTAINERS-001
- **Verification criteria:** Agreement text names the risk; Containers no longer runs usermod.

### NYX-APP-CONTAINERS-004: Hard-coded developer username fallback

- **Component:** nyx-containers `apps/containers/src/services/diagnose.rs:8-10`
- **Category:** reliability
- **Severity:** P3
- **Status of feature:** verified
- **Description:** `user()` falls back to `"ken"` when `$USER` is unset; Fix would then run `usermod -aG docker ken`.
- **Expected:** Use `getuid()`/`getpwuid` or fail.
- **Actual:** `std::env::var("USER").unwrap_or_else(|_| "ken".into())`.
- **Reproduce / verify:** read the line
- **Evidence:** as cited
- **Affected versions:** `bd049445a4`
- **User impact:** Wrong account changed in rare environments (D-Bus activation without `USER`).
- **Recommended correction:** Resolve the user from the UID.
- **Effort:** S
- **Dependencies:** NYX-APP-CONTAINERS-002
- **Verification criteria:** No literal username in source.

### NYX-APP-CONTAINERS-005: README and source header are Arch/Omarchy-specific and stale

- **Component:** nyx-containers `README.md` ("Install", last line), `apps/containers/src/main.rs:1`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** Install covers `install.sh` with sudo and Arch packages; the closing line says suite registration and a public repo are off, but the app is packaged and in the catalog.
- **Expected:** NyxOS install path (Welcome: Containers + Docker/Incus) and current status.
- **Actual:** as cited.
- **Reproduce / verify:** read README
- **Evidence:** as cited
- **Affected versions:** `bd049445a4`
- **User impact:** Misleading setup instructions.
- **Recommended correction:** Add a NyxOS section; remove the stale line.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** README describes the NyxOS path.
