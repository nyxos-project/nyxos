# NyxOS security model

What NyxOS 0.1 trusts, what it protects, and where the limits are. The
[architecture](architecture.md) describes the parts named here; the user-facing caveats
are in [known limitations](guide/known-limitations.md#security-and-privacy). Components
with their own models: [Nyx Biometrics](https://github.com/design-nexus/nyx-biometrics/blob/main/docs/THREAT_MODEL.md),
[Nyx Shell](https://github.com/design-nexus/nyx-shell/blob/main/docs/SECURITY.md),
[Nyx Backup](https://github.com/design-nexus/nyx-backup/blob/main/docs/SECURITY-REVIEW.md),
[Nyx Online Accounts](https://github.com/design-nexus/nyx-accounts/blob/main/docs/SECURITY.md).

## Boundaries

- **Between people on one computer:** ordinary Unix accounts. Each person's apps,
  settings, keyring and Nix profile are theirs.
- **Between a person and the system:** only administrators (the `wheel` group) can run
  `sudo`, and Nix trusts only root, so a person can't build or install for everyone
  except through the Nyx System Manager, which asks polkit for each kind of change.
- **Between programs one person runs:** not a boundary in 0.1. A program running as you
  can read your files and talk to your session. NyxOS narrows the worst cases (below), but
  install only software you trust.

## The Nyx System Manager

A root D-Bus service, started on demand. It takes typed requests only (no commands or
paths to run), and each kind is its own polkit action: reading state, settings, packages
for everyone, services, defaults, updates, rollback, groups, applying changes, the
firewall, cleaning, accounts, passwords and mounts (14 in all,
`io.github.nyxos_project.system.policy`). Changes are written to the journal. It writes
the overrides layer; nothing else does.

## Software you get

- **Packages** come from cache.nixos.org and NyxOS's binary cache, `nyxos.cachix.org`,
  each checked against its public key in `nix.settings`. CI pushes to the cache only from
  `main` and `stable`; builds of proposed tool updates get no cache token.
- **The stable channel is signed.** `scripts/promote-stable` tags each promoted revision
  `known-good/<n>` with the release key, and `nyx update` moves a stable machine only to
  a tag signed by a key in `/etc/nyxos/release-signers`. The testing channel (`main`)
  isn't signed.
- **Installer images** come with `SHA256SUMS`, its SSH signature by the same key
  (`ssh-keygen -Y verify -f release-signers -I nyxos-release -n file -s SHA256SUMS.sig < SHA256SUMS`)
  and a GitHub build provenance attestation. The USB stick isn't signed for Secure Boot.
- **Coding agents and tools** outside nixpkgs are pinned by hash in
  `pkgs/tools/sources.json`; an update is a pull request whose hash is checked against
  what the vendor published.

## On the network

- The firewall is on. Nothing listens by default except what a feature turned on needs:
  Nyx Share (53317, TCP and UDP; it asks before receiving from a device it doesn't
  trust), and Nyx Connect's ports, opened only on connections in NetworkManager's home,
  work or trusted zone, with fluxd started only once a phone is paired.
- SSH is off unless turned on in Settings › Services; it takes keys only, never root.
- Kernel network defaults for a desktop: no redirects or source routing, SYN cookies;
  DCCP, SCTP, RDS and TIPC aren't loaded.

## On the computer

- **Disk:** the installer encrypts the disk (LUKS), unlocked with its passphrase. TPM
  unlock isn't there yet.
- **Secure Boot:** optional. NyxOS can sign its own boot with the computer's own keys,
  keeping Microsoft's so Windows still starts (`nyxos.boot.secureBoot`).
- **Kernel:** kernel addresses and its log are root's, no kexec, no line disciplines on
  demand, protected FIFOs and files in sticky folders, and a program may debug only its
  own children (`kernel.yama.ptrace_scope = 1`).
- **Recovery:** the NyxOS Recovery boot entry starts without the desktop or network, and
  its console asks for an administrator's password first.
- **Snapshots:** Btrfs snapshots before and after each system change, and hourly and
  daily, so a change can be undone from the file system as well as the boot menu.

## Inside a session

- **Screen capture:** Hyprland's permission system is on. Only the screen-sharing
  portal and Nyx's own capture tools may capture directly; everything else goes through
  the portal, which asks. Hyprland also asks before loading a plugin.
- **Nyx services that trust callers** (Clipboard, Online Accounts, Passwords, app
  actions) check the calling program's executable against the Nyx apps' folders listed
  in `/etc/nyx/trusted-bin`, the ones NyxOS's cache built. A program in your home
  folder can't pass as one of them.
- **The local AI endpoint** (Nyx AI Core's OpenAI-compatible API) is off until turned
  on (`nyx-ai service openai=on`). It then listens on loopback only and needs the API
  key it writes to `~/.config/nyx-ai/api-key`. Apps reach AI Core over its own socket.
- **Sign-in with Nyx Biometrics** is off until turned on in Settings › Sign-in &
  Security. The password always works. Face matching with an ordinary webcam only
  unlocks the lock screen, and only when allowed. No face images are kept. With face
  unlock on in Passwords, the vault key is sealed to the TPM by a root key service, which
  releases it after a polkit sign-in.
- **Secrets** (account tokens, Backup's repository passwords, Share's NAS passwords)
  are kept in the keyring (the Secret Service), not in settings files.

## Known gaps

- Same-user programs aren't isolated from each other (see Boundaries).
- The testing channel isn't signed; the USB stick isn't signed for Secure Boot.
- Disk unlock uses the passphrase, not the TPM.
- No physical hardware has been through a full test yet.
