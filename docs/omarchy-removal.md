# Omarchy removal: where the Nyx sources still depend on Omarchy

Generated 2026-11-18 by `scripts/omarchy-inventory` from 63 repositories (checkouts in `/home/ken/Projects` where present, otherwise the revisions nyx-packages pins). Run it again after each cleanup; don't edit this file by hand.

Omarchy/Arch support is being dropped. For each item: do the job natively (a `nyx-platform` job, or the app's own code), then delete the Omarchy branch. Don't keep two paths.

- **230** distinct `omarchy-*` commands, at **806** places; `nyx-platform` already has a job for **26** of them
- **159** places that behave differently on Omarchy
- **239** references to Omarchy's files and folders

## By repository

| Repository | Command uses | Distinct commands | Omarchy gates | Omarchy paths |
|---|---:|---:|---:|---:|
| nyx-settings | 372 | 169 | 43 | 16 |
| nyx-control-center | 56 | 23 | 29 | 2 |
| nyx-assistant | 53 | 14 | 3 | 22 |
| nyx-notification-center | 65 | 14 | 2 | 2 |
| nyx-design | 17 | 10 | 20 | 9 |
| nyx-biometrics | 35 | 14 | 3 | 4 |
| nyx-glimpse | 10 | 5 | 8 | 7 |
| nyx-files | 21 | 2 | 1 | 2 |
| nyx-core | 17 | 9 | 2 | 1 |
| nyx | 9 | 7 | 0 | 10 |
| nyx-activity | 8 | 4 | 1 | 7 |
| nyx-passwords | 5 | 2 | 5 | 6 |
| nyx-dock | 10 | 5 | 3 | 2 |
| nyx-git | 7 | 3 | 1 | 6 |
| nyx-photos | 6 | 3 | 1 | 6 |
| nyx-weather | 5 | 2 | 2 | 6 |
| nyx-archive | 5 | 2 | 1 | 6 |
| nyx-calendar | 5 | 2 | 1 | 6 |
| nyx-capture | 5 | 2 | 1 | 6 |
| nyx-chat | 5 | 2 | 1 | 6 |
| nyx-contacts | 5 | 2 | 1 | 6 |
| nyx-fonts | 5 | 2 | 1 | 6 |
| nyx-lyra | 5 | 2 | 1 | 6 |
| nyx-mail | 5 | 2 | 1 | 6 |
| nyx-media-player | 5 | 2 | 1 | 6 |
| nyx-music | 5 | 2 | 1 | 6 |
| nyx-news | 5 | 2 | 1 | 6 |
| nyx-notepad | 5 | 2 | 1 | 6 |
| nyx-office | 5 | 2 | 1 | 6 |
| nyx-pdf | 5 | 2 | 1 | 6 |
| nyx-pulse | 5 | 2 | 1 | 6 |
| nyx-reminders | 5 | 2 | 1 | 6 |
| nyx-store | 5 | 2 | 1 | 6 |
| nyx-theater | 5 | 2 | 1 | 6 |
| nyx-torrents | 5 | 2 | 1 | 6 |
| nyx-bar | 8 | 4 | 1 | 0 |
| nyx-shell | 3 | 1 | 1 | 5 |
| nyx-agents | 1 | 1 | 2 | 3 |
| nyx-notes | 1 | 1 | 1 | 3 |
| nyx-accounts | 0 | 0 | 0 | 4 |
| nyx-backup | 1 | 1 | 1 | 1 |
| nyx-clipboard | 0 | 0 | 2 | 0 |
| nyx-packages | 1 | 1 | 0 | 0 |
| nyx-calculator | 0 | 0 | 1 | 0 |
| nyx-containers | 0 | 0 | 1 | 0 |
| nyx-desktop-widgets | 0 | 0 | 1 | 0 |
| nyx-home | 0 | 0 | 1 | 0 |
| nyx-maps | 0 | 0 | 1 | 0 |
| nyx-share | 0 | 0 | 1 | 0 |
| nyx-switcher | 0 | 0 | 1 | 0 |
| nyx-transfer | 0 | 0 | 1 | 0 |
| umbra-icons | 0 | 0 | 0 | 1 |

## Commands

`job` means `nyx-platform` already does it, so the call can switch over now. Places in tests are marked *(test)*.

| Command | nyx-platform | Uses | Where |
|---|---|---:|---|
| `omarchy-shell` |  | 136 | nyx:`uninstall.sh:159`, nyx:`docs/desktop/bench/services.sh:7`, nyx-activity:`install.sh:394`, nyx-activity:`install.sh:399`, nyx-activity:`install.sh:411`, nyx-activity:`uninstall.sh:106`, and 130 more |
| `omarchy-plugin-enable` |  | 36 | nyx-activity:`install.sh:412`, nyx-archive:`install.sh:413`, nyx-assistant:`install.sh:411`, nyx-calendar:`install.sh:443`, nyx-capture:`install.sh:411`, nyx-chat:`install.sh:423`, and 30 more |
| `omarchy-assistant` |  | 16 | nyx-assistant:`apps/assistant/scripts/install.sh:14`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:2`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:9`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:9`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:10`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:15`, and 10 more |
| `omarchy-network-band` | job | 16 | nyx-control-center:`crates/nyx-providers/src/dns.rs:3`, nyx-control-center:`crates/nyx-providers/src/dns.rs:36`, nyx-control-center:`crates/nyx-providers/src/dns.rs:67`, nyx-control-center:`crates/nyx-providers/src/dns.rs:93`, nyx-core:`crates/nyx-platform/src/lib.rs:3`, nyx-core:`crates/nyx-platform/src/lib.rs:128`, and 10 more |
| `omarchy-bar` |  | 14 | nyx-assistant:`apps/assistant/crates/assistant-visual/src/main.rs:133`, nyx-assistant:`apps/assistant/crates/assistant-visual/src/main.rs:484`, nyx-settings:`apps/settings/src/capability.rs:43`, nyx-settings:`apps/settings/src/sections/bar.rs:179`, nyx-settings:`apps/settings/src/sections/bar.rs:253`, nyx-settings:`apps/settings/src/sections/bar.rs:268`, and 8 more |
| `omarchy-brightness-display` | job | 14 | nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:887`, nyx-control-center:`crates/nyx-providers/src/brightness.rs:2`, nyx-control-center:`crates/nyx-providers/src/brightness.rs:93`, nyx-control-center:`crates/nyx-providers/src/brightness.rs:103`, nyx-control-center:`crates/nyx-providers/src/brightness.rs:122`, nyx-control-center:`crates/nyx-providers/src/display.rs:143`, and 8 more |
| `omarchy-lock-face` |  | 14 | nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:27`, nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:669`, nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:1010`, nyx-biometrics:`crates/nyx-authctl/src/pam.rs:137`, nyx-biometrics:`crates/nyx-auth-pam/src/check.rs:298`, nyx-biometrics:`crates/nyx-auth-pam/src/generate.rs:289`, and 8 more |
| `omarchy-update` |  | 14 | nyx-bar:`plugins/updates/plugin.toml:27`, nyx-bar:`plugins/updates/src/main.rs:51`, nyx-bar:`plugins/updates/src/main.rs:52`, nyx-notification-center:`crates/nyx-notify-store/src/lib.rs:1268`, nyx-notification-center:`crates/nyx-notify-store/src/lib.rs:1272`, nyx-notification-center:`apps/notifyd/src/fdo.rs:241`, and 8 more |
| `omarchy-dns` | job | 13 | nyx-control-center:`crates/nyx-providers/src/dns.rs:1`, nyx-control-center:`crates/nyx-providers/src/dns.rs:66`, nyx-control-center:`crates/nyx-providers/src/dns.rs:78`, nyx-control-center:`crates/nyx-providers/src/dns.rs:85`, nyx-control-center:`crates/nyx-providers/src/lib.rs:17`, nyx-core:`crates/nyx-platform/src/lib.rs:4`, and 7 more |
| `omarchy-action` |  | 12 | nyx-notification-center:`crates/nyx-notify-store/src/lib.rs:768`, nyx-notification-center:`crates/nyx-notify-store/src/lib.rs:997`, nyx-notification-center:`crates/nyx-notify-store/src/lib.rs:1219`, nyx-notification-center:`crates/nyx-notify-store/src/omarchy.rs:44`, nyx-notification-center:`apps/notifyd/tests/compat.rs:319` *(test)*, nyx-notification-center:`apps/notification-center-backend/src/main.rs:54`, and 6 more |
| `omarchy-plugin-disable` |  | 12 | nyx:`uninstall.sh:79`, nyx:`uninstall.sh:89`, nyx-control-center:`uninstall.sh:14`, nyx-dock:`apps/dock/src/handover.rs:64`, nyx-dock:`apps/dock/src/handover.rs:65`, nyx-notification-center:`uninstall.sh:28`, and 6 more |
| `omarchy-variant` |  | 12 | nyx-files:`data/locales/de.json:1348`, nyx-files:`data/locales/en.json:1348`, nyx-files:`data/locales/es.json:1348`, nyx-files:`data/locales/fr.json:1348`, nyx-files:`data/locales/it.json:1348`, nyx-files:`data/locales/ja.json:1348`, and 6 more |
| `omarchy-launch-terminal` |  | 11 | nyx-assistant:`apps/assistant/config/config.toml:179`, nyx-assistant:`apps/assistant/crates/assistant-tools/src/agent.rs:162`, nyx-assistant:`apps/assistant/crates/assistant-tools/src/agent.rs:163`, nyx-assistant:`apps/assistant/crates/assistant-tools/src/agent.rs:166`, nyx-assistant:`apps/assistant/crates/assistant-tools/src/agent.rs:167`, nyx-assistant:`apps/assistant/crates/assistant-tools/src/agent.rs:170`, and 5 more |
| `omarchy-popups` |  | 11 | nyx-notification-center:`uninstall.sh:12`, nyx-notification-center:`apps/notifyd/src/main.rs:15`, nyx-notification-center:`apps/notification-center/shell-plugin/manifest.json:8`, nyx-notification-center:`apps/notification-center/src/main.rs:6`, nyx-notification-center:`apps/notification-center/src/main.rs:118`, nyx-notification-center:`apps/notification-center/src/main.rs:150`, and 5 more |
| `omarchy-cmd-terminal-cwd` |  | 9 | nyx-files:`src/portal_setup/omarchy.rs:109`, nyx-files:`src/portal_setup/omarchy.rs:113`, nyx-files:`src/portal_setup/omarchy.rs:217`, nyx-files:`src/portal_setup/omarchy.rs:226`, nyx-files:`src/portal_setup/omarchy.rs:234`, nyx-files:`src/portal_setup/omarchy.rs:236`, and 3 more |
| `omarchy-menu` |  | 9 | nyx-control-center:`crates/nyx-providers/src/toggles.rs:29`, nyx-control-center:`apps/control-center/src/panel.rs:903`, nyx-control-center:`apps/control-center-backend/src/main.rs:143`, nyx-control-center:`apps/control-center-backend/src/ops.rs:150`, nyx-glimpse:`apps/glimpse/src/omarchy.rs:47`, nyx-glimpse:`apps/glimpse/src/omarchy.rs:190`, and 3 more |
| `omarchy-reminder` |  | 9 | nyx-settings:`apps/settings/src/sections/capture.rs:694`, nyx-settings:`apps/settings/src/sections/capture.rs:697`, nyx-settings:`apps/settings/src/sections/capture.rs:706`, nyx-settings:`apps/settings/src/sections/capture.rs:756`, nyx-settings:`apps/settings/src/sections/capture.rs:763`, nyx-settings:`apps/settings/src/sections/capture.rs:1068`, and 3 more |
| `omarchy-actions` |  | 8 | nyx-glimpse:`apps/glimpse/src/cli.rs:18`, nyx-glimpse:`apps/glimpse/src/cli.rs:159`, nyx-notification-center:`crates/nyx-notify-store/src/lib.rs:324`, nyx-notification-center:`crates/nyx-notify-store/src/omarchy.rs:23`, nyx-notification-center:`apps/notifyd/src/fdo.rs:88`, nyx-notification-center:`apps/notifyd/src/fdo.rs:164`, and 2 more |
| `omarchy-hyprland-monitor-internal` | job | 8 | nyx-control-center:`crates/nyx-providers/src/display.rs:186`, nyx-settings:`apps/settings/src/sections/displays.rs:537`, nyx-settings:`apps/settings/src/sections/displays.rs:545`, nyx-settings:`apps/settings/src/sections/displays.rs:552`, nyx-settings:`apps/settings/src/sections/displays.rs:1027`, nyx-settings:`apps/settings/src/sections/displays.rs:1044`, and 2 more |
| `omarchy-backup` |  | 7 | nyx:`docs/migration/attribution-cleanup.json:149`, nyx-design:`mockups/activity-pages/pages/services.js:12`, nyx-design:`mockups/activity-pages/pages/startup.js:5`, nyx-design:`mockups/activity-pages/pages/startup.js:19`, nyx-design:`mockups/activity-pages/pages/startup.js:24`, nyx-design:`mockups/activity-pages/pages/startup.js:29`, and 1 more |
| `omarchy-capture-screenrecording` |  | 7 | nyx-settings:`apps/settings/src/capability.rs:58`, nyx-settings:`apps/settings/src/sections/capture.rs:468`, nyx-settings:`apps/settings/src/sections/capture.rs:596`, nyx-settings:`apps/settings/src/sections/capture.rs:602`, nyx-settings:`apps/settings/src/sections/capture.rs:1122`, nyx-settings:`apps/settings/src/sections/capture.rs:1198`, and 1 more |
| `omarchy-hyprland-monitor-internal-mirror` |  | 7 | nyx-settings:`apps/settings/src/sections/displays.rs:521`, nyx-settings:`apps/settings/src/sections/displays.rs:539`, nyx-settings:`apps/settings/src/sections/displays.rs:543`, nyx-settings:`apps/settings/src/sections/displays.rs:549`, nyx-settings:`apps/settings/src/sections/displays.rs:1049`, nyx-settings:`apps/settings/src/sections/displays.rs:1056`, and 1 more |
| `omarchy-network-speedtest` | job | 7 | nyx-settings:`apps/settings/src/capability.rs:52`, nyx-settings:`apps/settings/src/sections/network.rs:20`, nyx-settings:`apps/settings/src/sections/network.rs:370`, nyx-settings:`apps/settings/src/sections/network.rs:370`, nyx-settings:`apps/settings/src/sections/network.rs:694`, nyx-settings:`apps/settings/src/sections/network.rs:738`, and 1 more |
| `omarchy-assistantd` |  | 6 | nyx-assistant:`apps/assistant/scripts/install.sh:13`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:12`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:28`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:29`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:31`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:33` |
| `omarchy-bluetooth-device` |  | 6 | nyx-control-center:`crates/nyx-providers/src/bluetooth.rs:3`, nyx-control-center:`crates/nyx-providers/src/bluetooth.rs:215`, nyx-control-center:`crates/nyx-providers/src/bluetooth.rs:225`, nyx-settings:`apps/settings/src/capability.rs:46`, nyx-settings:`apps/settings/src/backend/bt.rs:125`, nyx-settings:`apps/settings/src/backend/bt.rs:126` |
| `omarchy-exec-argv` |  | 6 | nyx-notification-center:`crates/nyx-notify-store/src/lib.rs:322`, nyx-notification-center:`crates/nyx-notify-store/src/omarchy.rs:21`, nyx-notification-center:`apps/notifyd/src/fdo.rs:80`, nyx-notification-center:`apps/notifyd/src/fdo.rs:163`, nyx-notification-center:`apps/notifyd/tests/compat.rs:316` *(test)*, nyx-notification-center:`apps/notifyd/tests/compat.rs:324` *(test)* |
| `omarchy-notification-send` |  | 6 | nyx-notification-center:`apps/notifyd/tests/compat.rs:3` *(test)*, nyx-notification-center:`apps/notifyd/tests/compat.rs:354` *(test)*, nyx-notification-center:`apps/notifyd/tests/compat.rs:355` *(test)*, nyx-notification-center:`apps/notifyd/tests/compat.rs:360` *(test)*, nyx-notification-center:`apps/notifyd/tests/compat.rs:374` *(test)*, nyx-notification-center:`apps/notifyd/tests/compat.rs:382` *(test)* |
| `omarchy-toggle-idle` | job | 6 | nyx-bar:`plugins/keepawake/src/main.rs:17`, nyx-bar:`plugins/keepawake/src/main.rs:37`, nyx-control-center:`crates/nyx-providers/src/toggles.rs:7`, nyx-control-center:`crates/nyx-providers/src/toggles.rs:150`, nyx-settings:`apps/settings/src/sections/idle.rs:399`, nyx-settings:`apps/settings/src/sections/idle.rs:405` |
| `omarchy-toggle-nightlight` | job | 6 | nyx-control-center:`crates/nyx-providers/src/toggles.rs:8`, nyx-control-center:`crates/nyx-providers/src/toggles.rs:180`, nyx-settings:`apps/settings/src/capability.rs:48`, nyx-settings:`apps/settings/src/sections/nightlight.rs:84`, nyx-settings:`apps/settings/src/sections/nightlight.rs:89`, nyx-settings:`apps/settings/src/sections/nightlight.rs:99` |
| `omarchy-toggle-notification-silencing` | job | 6 | nyx-bar:`plugins/panels/src/main.rs:77`, nyx-bar:`plugins/panels/src/main.rs:78`, nyx-control-center:`crates/nyx-providers/src/toggles.rs:6`, nyx-control-center:`crates/nyx-providers/src/toggles.rs:141`, nyx-notification-center:`apps/notification-center/plugin/BarWidget.qml:31`, nyx-notification-center:`apps/notification-center/shell-plugin/Service.qml:6` |
| `omarchy-bluetooth-power` |  | 5 | nyx-settings:`apps/settings/src/capability.rs:45`, nyx-settings:`apps/settings/src/backend/bt.rs:102`, nyx-settings:`apps/settings/src/backend/bt.rs:103`, nyx-settings:`apps/settings/src/backend/bt.rs:109`, nyx-settings:`apps/settings/src/backend/bt.rs:110` |
| `omarchy-hyprland-window-minimize` |  | 5 | nyx-core:`crates/nyx-desktop/src/actions.rs:96`, nyx-design:`crates/nyx-ui/src/chrome.rs:701`, nyx-shell:`crates/nyx-shell-core/src/compositor.rs:264`, nyx-shell:`crates/nyx-shell-core/src/window.rs:11`, nyx-shell:`crates/nyx-shell-core/src/core/tests.rs:231` |
| `omarchy-restart-shell` |  | 5 | nyx-biometrics:`scripts/install-shell.sh:24`, nyx-notification-center:`apps/notification-center/src/switch.rs:126`, nyx-notification-center:`apps/notification-center/src/switch.rs:149`, nyx-notification-center:`apps/notification-center/src/switch.rs:154`, nyx-settings:`apps/settings/src/sections/capture.rs:1038` |
| `omarchy-snapshot` |  | 5 | nyx-settings:`apps/settings/src/platform/omarchy.rs:39`, nyx-settings:`apps/settings/src/sections/boot.rs:385`, nyx-settings:`apps/settings/src/sections/boot.rs:404`, nyx-settings:`apps/settings/src/sections/boot.rs:410`, nyx-settings:`apps/settings/src/sections/home.rs:720` |
| `omarchy-tailscale-send` | job | 5 | nyx-control-center:`qml/ControlCenter/details/TailscaleDetail.qml:173`, nyx-control-center:`apps/control-center/src/route_tiles.rs:277`, nyx-control-center:`apps/control-center/src/route_tiles.rs:279`, nyx-control-center:`apps/control-center-backend/src/main.rs:146`, nyx-control-center:`apps/control-center-backend/src/ops.rs:193` |
| `omarchy-theme-set` |  | 5 | nyx-core:`crates/nyx-platform/src/lib.rs:130`, nyx-core:`crates/nyx-platform/src/lib.rs:137`, nyx-core:`crates/nyx-platform/src/lib.rs:137`, nyx-settings:`apps/settings/src/backend/themehook.rs:55`, nyx-settings:`apps/settings/src/sections/theme.rs:788` |
| `omarchy-toggle-touchpad` | job | 5 | nyx-settings:`apps/settings/src/capability.rs:53`, nyx-settings:`apps/settings/src/sections/trackpad.rs:280`, nyx-settings:`apps/settings/src/sections/trackpad.rs:592`, nyx-settings:`apps/settings/src/sections/trackpad.rs:596`, nyx-settings:`apps/settings/src/sections/trackpad.rs:608` |
| `omarchy-tui-install` |  | 5 | nyx-settings:`apps/settings/src/sections/software.rs:27`, nyx-settings:`apps/settings/src/sections/software.rs:150`, nyx-settings:`apps/settings/src/sections/software.rs:353`, nyx-settings:`apps/settings/src/sections/software.rs:394`, nyx-settings:`apps/settings/src/sections/software.rs:574` |
| `omarchy-version` |  | 5 | nyx-core:`crates/nyx-capability/examples/probe.rs:9`, nyx-settings:`apps/settings/src/capability.rs:41`, nyx-settings:`apps/settings/src/platform/omarchy.rs:11`, nyx-settings:`apps/settings/src/sections/about.rs:134`, nyx-settings:`apps/settings/src/sections/home.rs:121` |
| `omarchy-webapp-install` |  | 5 | nyx-settings:`apps/settings/src/sections/software.rs:26`, nyx-settings:`apps/settings/src/sections/software.rs:329`, nyx-settings:`apps/settings/src/sections/software.rs:392`, nyx-settings:`apps/settings/src/sections/software.rs:566`, nyx-settings:`apps/settings/src/sections/software.rs:633` |
| `omarchy-battery-status` | job | 4 | nyx-control-center:`crates/nyx-providers/src/power.rs:189`, nyx-control-center:`crates/nyx-providers/src/power.rs:242`, nyx-settings:`apps/settings/src/platform/mod.rs:315`, nyx-settings:`apps/settings/src/sections/power.rs:45` |
| `omarchy-capture-screenshot` |  | 4 | nyx-settings:`apps/settings/src/capability.rs:57`, nyx-settings:`apps/settings/src/backend/gestures.rs:226`, nyx-settings:`apps/settings/src/sections/capture.rs:417`, nyx-settings:`apps/settings/src/sections/capture.rs:1121` |
| `omarchy-cmd-screenshot` |  | 4 | nyx-settings:`extensions/streamdeck/elgato.py:51`, nyx-settings:`extensions/streamdeck/galleon_page.py:700`, nyx-settings:`extensions/streamdeck/pretend.py:50`, nyx-settings:`extensions/streamdeck/pretend.py:230` |
| `omarchy-default-agent` |  | 4 | nyx-assistant:`apps/assistant/crates/assistant-tools/src/agent.rs:4`, nyx-settings:`apps/settings/src/sections/apps.rs:347`, nyx-settings:`apps/settings/src/sections/capture.rs:988`, nyx-settings:`apps/settings/src/sections/capture.rs:1009` |
| `omarchy-hyprland-workspace-layout-toggle` |  | 4 | nyx-core:`crates/nyx-desktop/src/omarchy.rs:69`, nyx-core:`crates/nyx-desktop/src/omarchy.rs:130`, nyx-core:`crates/nyx-desktop/src/omarchy.rs:145`, nyx-core:`crates/nyx-desktop/src/omarchy.rs:147` |
| `omarchy-launch-browser` |  | 4 | nyx-dock:`apps/dock/src/launch.rs:155`, nyx-dock:`apps/dock/src/launch.rs:159`, nyx-settings:`extensions/streamdeck/elgato.py:48`, nyx-settings:`extensions/streamdeck/galleon_page.py:697` |
| `omarchy-launch-editor` |  | 4 | nyx-core:`crates/nyx-core/src/cmd.rs:92`, nyx-core:`crates/nyx-core/src/cmd.rs:93`, nyx-git:`apps/git/src/ui/workspace.rs:143`, nyx-git:`apps/git/src/ui/workspace.rs:144` |
| `omarchy-launch-floating-terminal-with-presentation` |  | 4 | nyx-bar:`plugins/updates/src/main.rs:52`, nyx-control-center:`crates/nyx-providers/src/dns.rs:78`, nyx-settings:`apps/settings/src/platform/mod.rs:361`, nyx-settings:`apps/settings/src/sections/home.rs:630` |
| `omarchy-launch-webapp` |  | 4 | nyx-core:`crates/nyx-desktop/src/apps.rs:117`, nyx-settings:`apps/settings/src/sections/software.rs:74`, nyx-settings:`apps/settings/src/sections/software.rs:81`, nyx-settings:`apps/settings/src/sections/software.rs:1261` |
| `omarchy-lock-password` |  | 4 | nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:647`, nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:970`, nyx-biometrics:`crates/nyx-auth-pam/src/generate.rs:288`, nyx-biometrics:`crates/nyx-auth-pam/src/generate.rs:491` |
| `omarchy-plymouth-reset` |  | 4 | nyx-settings:`apps/settings/src/sections/boot.rs:437`, nyx-settings:`apps/settings/src/sections/boot.rs:497`, nyx-settings:`apps/settings/src/sections/boot.rs:511`, nyx-settings:`apps/settings/src/sections/boot.rs:516` |
| `omarchy-setup-security-sshd` |  | 4 | nyx-settings:`apps/settings/src/sections/accounts.rs:1242`, nyx-settings:`apps/settings/src/sections/accounts.rs:1244`, nyx-settings:`apps/settings/src/sections/accounts.rs:1345`, nyx-settings:`apps/settings/src/sections/accounts.rs:1360` |
| `omarchy-toggle-touchscreen` | job | 4 | nyx-settings:`apps/settings/src/capability.rs:54`, nyx-settings:`apps/settings/src/sections/trackpad.rs:592`, nyx-settings:`apps/settings/src/sections/trackpad.rs:598`, nyx-settings:`apps/settings/src/sections/trackpad.rs:618` |
| `omarchy-hibernation-available` |  | 3 | nyx-settings:`apps/settings/src/platform/mod.rs:95`, nyx-settings:`apps/settings/src/sections/boot.rs:116`, nyx-settings:`apps/settings/src/sections/boot.rs:116` |
| `omarchy-hw-laptop-closed` |  | 3 | nyx-biometrics:`shell/design-nexus.auth-polkit/PolkitAgent.qml:221`, nyx-biometrics:`crates/nyx-auth-pam/src/block.rs:56`, nyx-biometrics:`crates/nyx-auth-pam/src/block.rs:115` |
| `omarchy-launch-docker-tui` |  | 3 | nyx-settings:`apps/settings/src/sections/software.rs:1275`, nyx-settings:`apps/settings/src/sections/software.rs:1276`, nyx-settings:`apps/settings/src/sections/software.rs:1278` |
| `omarchy-launch-tui` |  | 3 | nyx-dock:`apps/dock/src/launch.rs:5`, nyx-dock:`apps/dock/src/launch.rs:51`, nyx-dock:`apps/dock/src/launch.rs:57` |
| `omarchy-lock-fingerprint` |  | 3 | nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:688`, nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:850`, nyx-biometrics:`crates/nyx-auth-pam/src/generate.rs:288` |
| `omarchy-plugin-list` |  | 3 | nyx-settings:`apps/settings/src/capability.rs:44`, nyx-settings:`apps/settings/src/sections/barlayout.rs:117`, nyx-settings:`apps/settings/src/sections/plugins.rs:102` |
| `omarchy-refresh-limine` |  | 3 | nyx-settings:`apps/settings/src/sections/boot.rs:497`, nyx-settings:`apps/settings/src/sections/boot.rs:529`, nyx-settings:`apps/settings/src/sections/boot.rs:532` |
| `omarchy-refresh-sddm` |  | 3 | nyx-settings:`apps/settings/src/sections/boot.rs:497`, nyx-settings:`apps/settings/src/sections/boot.rs:520`, nyx-settings:`apps/settings/src/sections/boot.rs:525` |
| `omarchy-restart-bluetooth` | job | 3 | nyx-settings:`apps/settings/src/sections/network.rs:701`, nyx-settings:`apps/settings/src/sections/network.rs:786`, nyx-settings:`apps/settings/src/sections/network.rs:788` |
| `omarchy-restart-hyprsunset` | job | 3 | nyx-settings:`apps/settings/src/capability.rs:49`, nyx-settings:`apps/settings/src/sections/nightlight.rs:68`, nyx-settings:`apps/settings/src/sections/nightlight.rs:69` |
| `omarchy-restart-wifi` | job | 3 | nyx-settings:`apps/settings/src/sections/network.rs:695`, nyx-settings:`apps/settings/src/sections/network.rs:786`, nyx-settings:`apps/settings/src/sections/network.rs:788` |
| `omarchy-settings-backup` |  | 3 | nyx-settings:`apps/settings/src/backend/backup.rs:10`, nyx-settings:`apps/settings/src/backend/backup.rs:99`, nyx-settings:`apps/settings/src/backend/backup.rs:101` |
| `omarchy-setup-direct-boot` |  | 3 | nyx-settings:`apps/settings/src/sections/boot.rs:385`, nyx-settings:`apps/settings/src/sections/boot.rs:390`, nyx-settings:`apps/settings/src/sections/boot.rs:398` |
| `omarchy-setup-security-sudoless-docker` |  | 3 | nyx-settings:`apps/settings/src/sections/accounts.rs:1440`, nyx-settings:`apps/settings/src/sections/accounts.rs:1443`, nyx-settings:`apps/settings/src/sections/accounts.rs:1457` |
| `omarchy-system-lock` |  | 3 | nyx-settings:`apps/settings/src/backend/gestures.rs:236`, nyx-settings:`apps/settings/src/platform/mod.rs:340`, nyx-settings:`apps/settings/src/sections/idle.rs:418` |
| `omarchy-toggle-enabled` |  | 3 | nyx-glimpse:`apps/glimpse/src/omarchy.rs:180`, nyx-settings:`apps/settings/src/sections/capture.rs:1018`, nyx-settings:`apps/settings/src/sections/power.rs:510` |
| `omarchy-update-available` |  | 3 | nyx-settings:`apps/settings/src/backend/pkgupdates.rs:26`, nyx-settings:`apps/settings/src/backend/pkgupdates.rs:96`, nyx-settings:`apps/settings/src/backend/pkgupdates.rs:97` |
| `omarchy-update-orphan-pkgs` |  | 3 | nyx-settings:`apps/settings/src/sections/software.rs:1209`, nyx-settings:`apps/settings/src/sections/software.rs:1218`, nyx-settings:`apps/settings/src/sections/software.rs:1234` |
| `omarchy-weather-location` |  | 3 | nyx-settings:`apps/settings/src/sections/capture.rs:785`, nyx-settings:`apps/settings/src/sections/capture.rs:787`, nyx-settings:`apps/settings/src/sections/capture.rs:1092` |
| `omarchy-webapp-remove` |  | 3 | nyx-settings:`apps/settings/src/sections/software.rs:382`, nyx-settings:`apps/settings/src/sections/software.rs:564`, nyx-settings:`apps/settings/src/sections/software.rs:631` |
| `omarchy-assistant-hud` |  | 2 | nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:12`, nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:31` |
| `omarchy-audio-output-sink` |  | 2 | nyx-settings:`apps/settings/src/backend/audio.rs:266`, nyx-settings:`apps/settings/src/backend/audio.rs:267` |
| `omarchy-audio-output-volume` |  | 2 | nyx-settings:`apps/settings/src/backend/gestures.rs:229`, nyx-settings:`apps/settings/src/backend/gestures.rs:232` |
| `omarchy-channel-set` |  | 2 | nyx-settings:`apps/settings/src/sections/software.rs:813`, nyx-settings:`apps/settings/src/sections/software.rs:1180` |
| `omarchy-disk-speedtest` |  | 2 | nyx-settings:`apps/settings/src/sections/capture.rs:1030`, nyx-settings:`apps/settings/src/sections/capture.rs:1032` |
| `omarchy-display-text-size` |  | 2 | nyx-control-center:`crates/nyx-providers/src/display.rs:149`, nyx-control-center:`crates/nyx-providers/src/display.rs:181` |
| `omarchy-drive-password` |  | 2 | nyx-settings:`apps/settings/src/sections/accounts.rs:1459`, nyx-settings:`apps/settings/src/sections/accounts.rs:1510` |
| `omarchy-floating-workspace` |  | 2 | nyx-settings:`apps/settings/src/backend/titlebars.rs:32`, nyx-settings:`apps/settings/src/backend/titlebars.rs:132` |
| `omarchy-font-current` |  | 2 | nyx-settings:`apps/settings/src/sections/theme.rs:701`, nyx-settings:`apps/settings/src/sections/theme.rs:1055` |
| `omarchy-glyph` |  | 2 | nyx-notification-center:`apps/notifyd/src/fdo.rs:151`, nyx-notification-center:`apps/notifyd/tests/compat.rs:305` *(test)* |
| `omarchy-hibernation-setup` |  | 2 | nyx-settings:`apps/settings/src/sections/boot.rs:115`, nyx-settings:`apps/settings/src/sections/boot.rs:479` |
| `omarchy-hw-display` | job | 2 | nyx-control-center:`crates/nyx-providers/src/brightness.rs:4`, nyx-control-center:`crates/nyx-providers/src/brightness.rs:111` |
| `omarchy-hw-touchpad` | job | 2 | nyx-settings:`apps/settings/src/capability.rs:55`, nyx-settings:`apps/settings/src/sections/trackpad.rs:596` |
| `omarchy-hw-touchscreen` | job | 2 | nyx-settings:`apps/settings/src/capability.rs:56`, nyx-settings:`apps/settings/src/sections/trackpad.rs:598` |
| `omarchy-hyprland-monitor-scaling` | job | 2 | nyx-control-center:`crates/nyx-providers/src/display.rs:148`, nyx-control-center:`crates/nyx-providers/src/display.rs:176` |
| `omarchy-install-preinstalls` |  | 2 | nyx-settings:`apps/settings/src/sections/software.rs:772`, nyx-settings:`apps/settings/src/sections/software.rs:1126` |
| `omarchy-launch-openclaw` |  | 2 | nyx-assistant:`apps/assistant/crates/assistant-tools/src/agent.rs:96`, nyx-assistant:`apps/assistant/crates/assistant-tools/src/agent.rs:96` |
| `omarchy-launch-shell` |  | 2 | nyx-activity:`apps/activity/src/startup.rs:562`, nyx-activity:`apps/activity/src/startup.rs:571` |
| `omarchy-login` |  | 2 | nyx-biometrics:`crates/nyx-auth-helper/src/login_theme.rs:9`, nyx-biometrics:`crates/nyx-auth-helper/src/login_theme.rs:100` |
| `omarchy-monitor-state` |  | 2 | nyx-control-center:`crates/nyx-providers/src/display.rs:53`, nyx-control-center:`crates/nyx-providers/src/display.rs:141` |
| `omarchy-network-status` | job | 2 | nyx-control-center:`crates/nyx-providers/src/dns.rs:164`, nyx-control-center:`crates/nyx-providers/src/dns.rs:222` |
| `omarchy-nyx` |  | 2 | nyx-design:`crates/nyx-theme-core/src/resolver.rs:255`, nyx-design:`crates/nyx-theme-core/src/resolver.rs:256` |
| `omarchy-osd` |  | 2 | nyx-settings:`apps/settings/src/backend/audio.rs:439`, nyx-settings:`apps/settings/src/backend/audio.rs:441` |
| `omarchy-plugin-remove` |  | 2 | nyx-settings:`apps/settings/src/sections/plugins.rs:410`, nyx-settings:`apps/settings/src/sections/theme.rs:1322` |
| `omarchy-plugin-update` |  | 2 | nyx-settings:`apps/settings/src/sections/plugins.rs:211`, nyx-settings:`apps/settings/src/sections/plugins.rs:383` |
| `omarchy-plymouth-set-by-theme` |  | 2 | nyx-settings:`apps/settings/src/sections/boot.rs:110`, nyx-settings:`apps/settings/src/sections/boot.rs:439` |
| `omarchy-remove-preinstalls` |  | 2 | nyx-settings:`apps/settings/src/sections/software.rs:772`, nyx-settings:`apps/settings/src/sections/software.rs:1126` |
| `omarchy-settings` |  | 2 | nyx-biometrics:`shell/sddm/nyx-biometrics/Main.qml:4`, nyx-settings:`apps/settings/src/sections/about.rs:699` |
| `omarchy-setup-security-fido2` |  | 2 | nyx-settings:`apps/settings/src/sections/accounts.rs:1424`, nyx-settings:`apps/settings/src/sections/accounts.rs:1427` |
| `omarchy-setup-security-fingerprint` |  | 2 | nyx-settings:`apps/settings/src/sections/accounts.rs:1432`, nyx-settings:`apps/settings/src/sections/accounts.rs:1435` |
| `omarchy-setup-security-ssh-agent` |  | 2 | nyx-settings:`apps/settings/src/sections/accounts.rs:1367`, nyx-settings:`apps/settings/src/sections/accounts.rs:1372` |
| `omarchy-sudo-passwordless` |  | 2 | nyx-settings:`apps/settings/src/sections/accounts.rs:856`, nyx-settings:`apps/settings/src/sections/accounts.rs:862` |
| `omarchy-test` |  | 2 | nyx-design:`crates/nyx-theme-core/src/omarchy.rs:396`, nyx-design:`crates/nyx-theme-core/src/omarchy.rs:404` |
| `omarchy-theme-bg-next` |  | 2 | nyx-settings:`extensions/streamdeck/pretend.py:55`, nyx-settings:`apps/settings/src/sections/theme.rs:1010` |
| `omarchy-theme-bg-set` |  | 2 | nyx-photos:`apps/gallery/src/actions.rs:11`, nyx-settings:`apps/settings/src/sections/theme.rs:992` |
| `omarchy-theme-dir` |  | 2 | nyx-settings:`apps/settings/src/sections/boot.rs:66`, nyx-settings:`apps/settings/src/sections/boot.rs:68` |
| `omarchy-toggle-crash-capture` |  | 2 | nyx-settings:`apps/settings/src/sections/capture.rs:1017`, nyx-settings:`apps/settings/src/sections/capture.rs:1021` |
| `omarchy-tui-remove` |  | 2 | nyx-settings:`apps/settings/src/sections/software.rs:383`, nyx-settings:`apps/settings/src/sections/software.rs:572` |
| `omarchy-update-aur-pkgs` |  | 2 | nyx-settings:`apps/settings/src/sections/software.rs:1202`, nyx-settings:`apps/settings/src/sections/software.rs:1216` |
| `omarchy-update-firmware` |  | 2 | nyx-settings:`apps/settings/src/sections/software.rs:1201`, nyx-settings:`apps/settings/src/sections/software.rs:1215` |
| `omarchy-update-keyring` |  | 2 | nyx-settings:`apps/settings/src/sections/software.rs:1204`, nyx-settings:`apps/settings/src/sections/software.rs:1217` |
| `omarchy-version-channel` |  | 2 | nyx-settings:`apps/settings/src/platform/omarchy.rs:13`, nyx-settings:`apps/settings/src/sections/home.rs:122` |
| `omarchy-voxtype-remove` |  | 2 | nyx-settings:`apps/settings/src/sections/capture.rs:836`, nyx-settings:`apps/settings/src/sections/capture.rs:838` |
| `omarchy-ai-hub` |  | 1 | nyx:`docs/migration/attribution-cleanup.json:122` |
| `omarchy-assistant-browser` |  | 1 | nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:33` |
| `omarchy-assistant-node` |  | 1 | nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:33` |
| `omarchy-assistant-plugin-worker` |  | 1 | nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:33` |
| `omarchy-assistant-tui` |  | 1 | nyx-assistant:`apps/assistant/scripts/migrate-from-omarchy.sh:33` |
| `omarchy-battery-present` | job | 1 | nyx-settings:`apps/settings/src/platform/mod.rs:305` |
| `omarchy-brightness-keyboard` |  | 1 | nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:887` |
| `omarchy-capture-qr` |  | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:435` |
| `omarchy-capture-text` |  | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:432` |
| `omarchy-channel-current` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:814` |
| `omarchy-cmd-default-browser` |  | 1 | nyx-dock:`apps/dock/src/launch.rs:162` |
| `omarchy-default` |  | 1 | nyx-settings:`apps/settings/src/sections/apps.rs:124` |
| `omarchy-default-browser` |  | 1 | nyx-settings:`apps/settings/src/sections/apps.rs:166` |
| `omarchy-default-editor` |  | 1 | nyx-settings:`apps/settings/src/sections/apps.rs:225` |
| `omarchy-default-terminal` |  | 1 | nyx-settings:`apps/settings/src/sections/apps.rs:211` |
| `omarchy-dev` |  | 1 | nyx-backup:`tools/migration-smoke.py:118` |
| `omarchy-dracula-theme` |  | 1 | nyx-design:`crates/nyx-theme-core/themes/dracula/colors.toml:1` |
| `omarchy-emacs` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:948` |
| `omarchy-font-list` |  | 1 | nyx-settings:`apps/settings/src/sections/theme.rs:1048` |
| `omarchy-font-set` |  | 1 | nyx-settings:`apps/settings/src/sections/theme.rs:1058` |
| `omarchy-hibernation-remove` |  | 1 | nyx-settings:`apps/settings/src/sections/boot.rs:479` |
| `omarchy-hook` |  | 1 | nyx-activity:`apps/activity/src/sections/startup.rs:39` |
| `omarchy-hw-hybrid-gpu` |  | 1 | nyx-settings:`apps/settings/src/sections/power.rs:285` |
| `omarchy-hw-laptop` |  | 1 | nyx-settings:`apps/settings/src/sections/displays.rs:1027` |
| `omarchy-hyprland-monitor-focused` | job | 1 | nyx-control-center:`crates/nyx-providers/src/brightness.rs:104` |
| `omarchy-hyprland-session-lock-stranded` |  | 1 | nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:867` |
| `omarchy-hyprland-workspace-layout-current` |  | 1 | nyx-core:`crates/nyx-desktop/src/omarchy.rs:6` |
| `omarchy-install-ai-chatgpt` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1000` |
| `omarchy-install-ai-claude` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:999` |
| `omarchy-install-ai-hermes` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1001` |
| `omarchy-install-ai-openclaw` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1002` |
| `omarchy-install-ai-t3-code` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1003` |
| `omarchy-install-dictation-voxtype` |  | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:824` |
| `omarchy-install-editor-emacs` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:948` |
| `omarchy-install-editor-helix` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:947` |
| `omarchy-install-editor-vscode` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:945` |
| `omarchy-install-editor-zed` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:946` |
| `omarchy-install-gaming-battlenet` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:972` |
| `omarchy-install-gaming-geforce-now` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:978` |
| `omarchy-install-gaming-heroic` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:960` |
| `omarchy-install-gaming-lutris` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:956` |
| `omarchy-install-gaming-retroarch` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:966` |
| `omarchy-install-gaming-steam` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:955` |
| `omarchy-install-gaming-xbox-cloud` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:984` |
| `omarchy-install-gaming-xbox-controllers` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:990` |
| `omarchy-install-service-1password` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1020` |
| `omarchy-install-service-dropbox` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1023` |
| `omarchy-install-service-nordvpn` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1033` |
| `omarchy-install-service-signal` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1024` |
| `omarchy-install-service-spotify` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1025` |
| `omarchy-install-service-sunshine` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1026` |
| `omarchy-install-service-tailscale` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1030` |
| `omarchy-keyring` |  | 1 | nyx-assistant:`apps/assistant/crates/assistant-privileged/src/lib.rs:326` |
| `omarchy-launch-walker` |  | 1 | nyx-settings:`extensions/streamdeck/pretend.py:53` |
| `omarchy-lock-preview` |  | 1 | nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:618` |
| `omarchy-mocha` |  | 1 | nyx-design:`crates/nyx-theme-core/src/omarchy.rs:377` |
| `omarchy-network-captive-portal` | job | 1 | nyx-control-center:`crates/nyx-providers/src/dns.rs:102` |
| `omarchy-notification-battery` |  | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:800` |
| `omarchy-notification-time` |  | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:799` |
| `omarchy-notification-wait` |  | 1 | nyx-notification-center:`apps/notifyd/tests/compat.rs:392` *(test)* |
| `omarchy-notification-weather` |  | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:801` |
| `omarchy-obsidian-notes` |  | 1 | nyx:`docs/migration/attribution-cleanup.json:107` |
| `omarchy-plymouth-current` |  | 1 | nyx-settings:`apps/settings/src/sections/boot.rs:112` |
| `omarchy-plymouth-list` |  | 1 | nyx-settings:`apps/settings/src/sections/boot.rs:418` |
| `omarchy-polkit` |  | 1 | nyx-biometrics:`shell/design-nexus.auth-polkit/PolkitAgent.qml:298` |
| `omarchy-powerprofiles-set` | job | 1 | nyx-settings:`apps/settings/src/platform/mod.rs:290` |
| `omarchy-privacy-route` |  | 1 | nyx:`docs/migration/attribution-cleanup.json:117` |
| `omarchy-remove-ai-chatgpt` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1000` |
| `omarchy-remove-ai-claude` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:999` |
| `omarchy-remove-ai-hermes` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1001` |
| `omarchy-remove-ai-lm-studio` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1010` |
| `omarchy-remove-ai-ollama` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1008` |
| `omarchy-remove-ai-openclaw` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1002` |
| `omarchy-remove-ai-t3-code` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1003` |
| `omarchy-remove-gaming-battlenet` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:973` |
| `omarchy-remove-gaming-geforce-now` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:979` |
| `omarchy-remove-gaming-heroic` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:961` |
| `omarchy-remove-gaming-lutris` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:956` |
| `omarchy-remove-gaming-retroarch` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:967` |
| `omarchy-remove-gaming-steam` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:955` |
| `omarchy-remove-gaming-xbox-cloud` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:985` |
| `omarchy-remove-gaming-xbox-controllers` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:991` |
| `omarchy-remove-security-fido2` |  | 1 | nyx-settings:`apps/settings/src/sections/accounts.rs:1428` |
| `omarchy-remove-security-fingerprint` |  | 1 | nyx-settings:`apps/settings/src/sections/accounts.rs:1436` |
| `omarchy-remove-security-sshd` |  | 1 | nyx-settings:`apps/settings/src/sections/accounts.rs:1244` |
| `omarchy-remove-security-sudoless-docker` |  | 1 | nyx-settings:`apps/settings/src/sections/accounts.rs:1444` |
| `omarchy-remove-service-1password` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1021` |
| `omarchy-remove-service-dropbox` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1023` |
| `omarchy-remove-service-sunshine` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1026` |
| `omarchy-remove-service-tailscale` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1031` |
| `omarchy-restart-audio` | job | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:1038` |
| `omarchy-send` |  | 1 | nyx-notification-center:`apps/notifyd/tests/compat.rs:353` *(test)* |
| `omarchy-sunrise` |  | 1 | nyx-design:`crates/nyx-theme-core/src/installer.rs:820` |
| `omarchy-sunrise-theme` |  | 1 | nyx-design:`crates/nyx-theme-core/src/installer.rs:814` |
| `omarchy-system-logout` |  | 1 | nyx-settings:`apps/settings/src/platform/mod.rs:350` |
| `omarchy-system-reboot` |  | 1 | nyx-settings:`apps/settings/src/platform/mod.rs:351` |
| `omarchy-system-shutdown` |  | 1 | nyx-settings:`apps/settings/src/platform/mod.rs:352` |
| `omarchy-system-sleep-lock` |  | 1 | nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:1041` |
| `omarchy-system-wake` |  | 1 | nyx-biometrics:`shell/design-nexus.auth-lock/Service.qml:882` |
| `omarchy-tailscale-receive` | job | 1 | nyx-control-center:`crates/nyx-providers/src/tailscale.rs:181` |
| `omarchy-theme-current` |  | 1 | nyx-settings:`apps/settings/src/sections/theme.rs:114` |
| `omarchy-theme-list` |  | 1 | nyx-settings:`apps/settings/src/sections/theme.rs:115` |
| `omarchy-ticktick-plus` |  | 1 | nyx:`docs/migration/attribution-cleanup.json:112` |
| `omarchy-toggle` |  | 1 | nyx-settings:`apps/settings/src/sections/trackpad.rs:283` |
| `omarchy-toggle-bar` |  | 1 | nyx-settings:`apps/settings/src/sections/bar.rs:286` |
| `omarchy-toggle-hybrid-gpu` |  | 1 | nyx-settings:`apps/settings/src/sections/power.rs:540` |
| `omarchy-toggle-screensaver` |  | 1 | nyx-settings:`apps/settings/src/sections/idle.rs:335` |
| `omarchy-toggle-suspend` |  | 1 | nyx-settings:`apps/settings/src/sections/idle.rs:426` |
| `omarchy-tokyo-night` |  | 1 | nyx-design:`crates/nyx-theme-core/src/installer.rs:728` |
| `omarchy-tokyo-night-theme` |  | 1 | nyx-design:`crates/nyx-theme-core/src/installer.rs:728` |
| `omarchy-update-analyze-logs` |  | 1 | nyx-settings:`apps/settings/src/sections/software.rs:1210` |
| `omarchy-voxtype-config` |  | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:829` |
| `omarchy-voxtype-install` |  | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:824` |
| `omarchy-voxtype-model` |  | 1 | nyx-settings:`apps/settings/src/sections/capture.rs:829` |

## Omarchy gates


### nyx-activity

- `apps/activity/src/prefs.rs:82`: `mode: ThemeMode::Omarchy,`

### nyx-agents

- `tools/aihub-mockup/src/main.rs:36`: `mode: suite.as_ref().map(|s| s.mode.clone()).unwrap_or(nyx_theme::ThemeMode::Omarchy),`
- `apps/nyx-agents/src/ui/prefs.rs:37`: `mode: ThemeMode::Omarchy,`

### nyx-archive

- `apps/archive/src/prefs.rs:31`: `mode: ThemeMode::Omarchy,`

### nyx-assistant

- `apps/assistant/crates/assistant-visual/src/main.rs:1420`: `mode: nyx_theme::ThemeMode::Omarchy,`
- `apps/assistant/crates/assistant-tui/src/input.rs:872`: `r#"{"phrases":["my command"],"tool":"system.lock","reply":"Locking.","omarchy":["system","lock"]}"#`
- `apps/assistant/crates/assistant-tui/src/theme/mod.rs:1`: `mod omarchy;`

### nyx-backup

- `apps/backup/src/main.rs:35`: `nyx_theme::ThemeMode::Omarchy`

### nyx-bar

- `apps/bar/src/theme.rs:22`: `mode: suite.as_ref().map(|s| s.mode.clone()).unwrap_or(ThemeMode::Omarchy),`

### nyx-biometrics

- `shell/design-nexus.auth-lock/manifest.json:8`: `"omarchy": {`
- `shell/design-nexus.auth-polkit/manifest.json:8`: `"omarchy": {`
- `shell/design-nexus.auth-prompt/manifest.json:8`: `"omarchy": {`

### nyx-calculator

- `crates/calculator-app/src/prefs.rs:25`: `mode: ThemeMode::Omarchy,`

### nyx-calendar

- `apps/calendar/src/prefs.rs:60`: `mode: ThemeMode::Omarchy,`

### nyx-capture

- `apps/capture/src/prefs.rs:63`: `mode: ThemeMode::Omarchy,`

### nyx-chat

- `apps/chat/src/prefs.rs:174`: `mode: ThemeMode::Omarchy,`

### nyx-clipboard

- `crates/nyx-clipboard-core/src/lib.rs:21`: `pub mod omarchy;`
- `apps/popup/src/theme.rs:17`: `mode: suite.as_ref().map(|s| s.mode.clone()).unwrap_or(ThemeMode::Omarchy),`

### nyx-contacts

- `apps/contacts/src/prefs.rs:27`: `mode: ThemeMode::Omarchy,`

### nyx-containers

- `apps/containers/src/prefs.rs:76`: `mode: ThemeMode::Omarchy,`

### nyx-control-center

- `qml/ControlCenter/Panel.qml:147`: `if (p.ctx.env.omarchy) {`
- `qml/ControlCenter/details/DisplayDetail.qml:55`: `visible: v.ctx.env.omarchy`
- `crates/nyx-providers/src/bluetooth.rs:214`: `if crate::omarchy::here() {`
- `crates/nyx-providers/src/bluetooth.rs:224`: `if crate::omarchy::here() {`
- `crates/nyx-providers/src/display.rs:127`: `if !crate::omarchy::here() {`
- `crates/nyx-providers/src/display.rs:161`: `let r = if crate::omarchy::here() {`
- `crates/nyx-providers/src/dns.rs:77`: `if crate::omarchy::here() {`
- `crates/nyx-providers/src/dns.rs:101`: `if crate::omarchy::here() {`
- `crates/nyx-providers/src/dns.rs:111`: `if crate::omarchy::here() {`
- `crates/nyx-providers/src/dns.rs:120`: `if crate::omarchy::here() {`
- `crates/nyx-providers/src/lib.rs:34`: `pub mod omarchy {`
- `crates/nyx-providers/src/tailscale.rs:181`: `if crate::omarchy::here() { "omarchy-tailscale-receive.service" } else { "nyx-tailscale-receive.service" }`
- `crates/nyx-providers/src/tailscale.rs:187`: `if crate::omarchy::here() {`
- `crates/nyx-providers/src/toggles.rs:9`: `//! - Workspace mode: see nyx_desktop::omarchy (read in the app, which has the desktop).`
- `apps/control-center/src/details.rs:809`: `if !nyx_providers::omarchy::here() {`
- `apps/control-center/src/panel.rs:526`: `mode: Some(nyx_desktop::omarchy::workspace_mode(m.active_workspace, layout.as_deref().unwrap_or(""))),`
- `apps/control-center/src/panel.rs:530`: `let dir = nyx_desktop::omarchy::layouts_dir();`
- `apps/control-center/src/panel.rs:537`: `s.set(Mode { mode: Some(nyx_desktop::omarchy::workspace_mode(cur.workspace, "")), ..cur });`
- `apps/control-center/src/panel.rs:901`: `if nyx_providers::omarchy::here() {`
- `apps/control-center/src/theme.rs:18`: `mode: suite.as_ref().map(|s| s.mode.clone()).unwrap_or(ThemeMode::Omarchy),`
- `apps/control-center/src/tiles.rs:63`: `pub mode: Option<nyx_desktop::omarchy::Mode>,`
- `apps/control-center/src/tiles.rs:553`: `use nyx_desktop::omarchy::Mode as M;`
- `apps/control-center/src/tiles.rs:555`: `if let Err(e) = nyx_desktop::omarchy::cycle(false) {`
- `apps/control-center-backend/src/main.rs:155`: `json!({"omarchy": nyx_providers::omarchy::here(), "name": name, "have": have})`
- `apps/control-center-backend/src/topics.rs:120`: `use nyx_desktop::omarchy::Mode as M;`
- `apps/control-center-backend/src/topics.rs:124`: `let mode = nyx_desktop::omarchy::workspace_mode(ws, &layout);`
- `apps/control-center-backend/src/topics.rs:130`: `let modes: Vec<&str> = nyx_desktop::omarchy::modes().iter().map(|m| m.label()).collect();`
- `apps/control-center-backend/src/topics.rs:196`: `let dir = nyx_desktop::omarchy::layouts_dir();`
- `apps/control-center-backend/src/ops.rs:284`: `let r = gio::spawn_blocking(|| nyx_desktop::omarchy::cycle(false).map_err(|e| e.to_string())).await;`

### nyx-core

- `crates/nyx-desktop/src/lib.rs:31`: `pub mod omarchy;`
- `crates/nyx-desktop/src/model.rs:201`: `/// isn't a layout; read it with [crate::omarchy::workspace_mode].`

### nyx-design

- `crates/nyx-ui/src/chrome.rs:770`: `&& nyx_desktop::omarchy::workspace_mode(h.workspace, layout) == nyx_desktop::omarchy::Mode::Floating;`
- `crates/nyx-theme-core/src/config.rs:86`: `mode: if crate::omarchy::live().is_some() { ThemeMode::Omarchy } else { ThemeMode::Theme },`
- `crates/nyx-theme-core/src/installer.rs:110`: `Format::Omarchy => "omarchy",`
- `crates/nyx-theme-core/src/installer.rs:310`: `Format::Omarchy => {`
- `crates/nyx-theme-core/src/installer.rs:311`: `let name = crate::omarchy::pretty_name(id_hint.strip_prefix("omarchy-").unwrap_or(id_hint));`
- `crates/nyx-theme-core/src/installer.rs:312`: `let conversion = match crate::omarchy::convert_dir(src, id_hint, &name, origin) {`
- `crates/nyx-theme-core/src/installer.rs:406`: `Origin::User | Origin::Omarchy => "one of your own themes".into(),`
- `crates/nyx-theme-core/src/lib.rs:21`: `pub mod omarchy;`
- `crates/nyx-theme-core/src/lib.rs:52`: `if s.mode == ThemeMode::Omarchy && omarchy::live().is_some() { "omarchy".into() } else { s.theme }`
- `crates/nyx-theme-core/src/lib.rs:95`: `update_suite(|s| s.mode = ThemeMode::Omarchy).map_err(|e| e.to_string())?;`
- `crates/nyx-theme-core/src/lib.rs:156`: `s.mode = if omarchy::live().is_some() { ThemeMode::Omarchy } else { ThemeMode::Theme };`
- `crates/nyx-theme-core/src/registry.rs:148`: `let pkg = toml::from_str::<toml::Table>(text).ok().and_then(|t| crate::omarchy::package_for(&t, id, name, fals`
- `crates/nyx-theme-core/src/resolver.rs:137`: `if mode == ThemeMode::Omarchy`
- `crates/nyx-theme-core/src/resolver.rs:138`: `&& let Some((meta, layer)) = crate::omarchy::live()`
- `crates/nyx-theme-core/src/resolver.rs:213`: `let pkg = crate::omarchy::package_for(&table, "omarchy", "Omarchy", false).unwrap();`
- `crates/nyx-theme/src/lib.rs:251`: `pub fn omarchy_available() -> bool {`
- `crates/nyx-theme/src/lib.rs:451`: `mode: ThemeMode::Omarchy,`
- `crates/nyx-theme/src/lib.rs:601`: `None => set(ThemeMode::Omarchy, String::new()),`
- `crates/nyx-theme/src/lib.rs:607`: `/// The settings card's theme choice: [ThemeMode::Omarchy] follows the system,`
- `crates/nyx-theme/src/lib.rs:611`: `ThemeMode::Omarchy => set_app_theme(None),`

### nyx-desktop-widgets

- `apps/desktop-widgets/src/theme.rs:18`: `mode: suite.as_ref().map(|s| s.mode.clone()).unwrap_or(ThemeMode::Omarchy),`

### nyx-dock

- `apps/dock-backend/src/main.rs:334`: `nyx_desktop::omarchy::workspace_mode(workspace, layout) == nyx_desktop::omarchy::Mode::Floating`
- `apps/dock/src/dock.rs:2002`: `nyx_desktop::omarchy::workspace_mode(workspace, layout) == nyx_desktop::omarchy::Mode::Floating`
- `apps/dock/src/theme.rs:18`: `mode: suite.as_ref().map(|s| s.mode.clone()).unwrap_or(ThemeMode::Omarchy),`

### nyx-files

- `src/portal_setup.rs:6`: `mod omarchy;`

### nyx-fonts

- `apps/fonts/src/prefs.rs:50`: `mode: ThemeMode::Omarchy,`

### nyx-git

- `apps/git/src/prefs.rs:36`: `mode: ThemeMode::Omarchy,`

### nyx-glimpse

- `apps/glimpse/src/backend.rs:442`: `let _ = slow.register(crate::omarchy::Omarchy::default());`
- `apps/glimpse/src/cli.rs:160`: `let mut source = crate::omarchy::Omarchy::default();`
- `apps/glimpse/src/lib.rs:28`: `pub mod omarchy;`
- `apps/glimpse/src/providers.rs:261`: `let entry = crate::omarchy::Omarchy::resolve(id)?;`
- `apps/glimpse/src/settings.rs:84`: `let omarchy = nyx_theme::omarchy_available();`
- `apps/glimpse/src/settings.rs:85`: `let follow = omarchy && matches!(suite.mode, nyx_theme::ThemeMode::Omarchy);`
- `apps/glimpse/src/settings.rs:427`: `"omarchy" => nyx_theme::ThemeMode::Omarchy,`
- `apps/glimpse/src/ui.rs:147`: `mode: if c.mode == "theme" { nyx_theme::ThemeMode::Theme } else { nyx_theme::ThemeMode::Omarchy },`

### nyx-home

- `src/prefs.rs:40`: `mode: ThemeMode::Omarchy,`

### nyx-lyra

- `apps/lyra/src/prefs.rs:45`: `mode: ThemeMode::Omarchy,`

### nyx-mail

- `apps/mail/src/prefs.rs:62`: `mode: ThemeMode::Omarchy,`

### nyx-maps

- `src/settings.rs:105`: `mode: ThemeMode::Omarchy,`

### nyx-media-player

- `apps/media-player/src/prefs.rs:90`: `mode: ThemeMode::Omarchy,`

### nyx-music

- `apps/music/src/prefs.rs:83`: `mode: ThemeMode::Omarchy,`

### nyx-news

- `apps/news/src/prefs.rs:56`: `mode: ThemeMode::Omarchy,`

### nyx-notepad

- `apps/notepad/src/prefs.rs:50`: `mode: ThemeMode::Omarchy,`

### nyx-notes

- `crates/notes-app/src/prefs.rs:66`: `mode: nyx_theme::ThemeMode::Omarchy,`

### nyx-notification-center

- `crates/nyx-notify-store/src/lib.rs:16`: `pub mod omarchy;`
- `apps/notification-center/src/theme.rs:18`: `mode: suite.as_ref().map(|s| s.mode.clone()).unwrap_or(ThemeMode::Omarchy),`

### nyx-office

- `apps/office/src/prefs.rs:38`: `mode: ThemeMode::Omarchy,`

### nyx-passwords

- `apps/passwords/src/app/prefs.rs:28`: `mode: ThemeMode::Omarchy,`
- `apps/passwords/src/app/settings.rs:966`: `dd.set_sensitive(p.mode == prefs::ThemeMode::Theme || !theme::omarchy_available());`
- `apps/passwords/src/app/settings.rs:967`: `if theme::omarchy_available() {`
- `apps/passwords/src/app/settings.rs:971`: `p.mode == prefs::ThemeMode::Omarchy,`
- `apps/passwords/src/app/settings.rs:973`: `prefs::update(|p| p.mode = if on { prefs::ThemeMode::Omarchy } else { prefs::ThemeMode::Theme });`

### nyx-pdf

- `apps/pdf/src/prefs.rs:53`: `mode: ThemeMode::Omarchy,`

### nyx-photos

- `apps/gallery/src/prefs.rs:49`: `mode: ThemeMode::Omarchy,`

### nyx-pulse

- `apps/pulse/src/prefs.rs:36`: `mode: ThemeMode::Omarchy,`

### nyx-reminders

- `apps/reminders/src/prefs.rs:39`: `mode: ThemeMode::Omarchy,`

### nyx-settings

- `apps/settings/src/prefs.rs:53`: `mode: ThemeMode::Omarchy,`
- `apps/settings/src/widgets.rs:1171`: `crate::platform::Platform::Omarchy => "Reset — use the value from your own config or Omarchy's default",`
- `apps/settings/src/backend/themehook.rs:31`: `|| nyx_theme::engine::suite().mode == nyx_theme::ThemeMode::Omarchy`
- `apps/settings/src/platform/mod.rs:7`: `mod omarchy;`
- `apps/settings/src/platform/mod.rs:38`: `Platform::Omarchy => group,`
- `apps/settings/src/platform/mod.rs:63`: `Platform::Omarchy => crate::sections::home::updates_group(page, hero),`
- `apps/settings/src/platform/mod.rs:72`: `Platform::Omarchy => crate::sections::accounts::helper_notice(section, what),`
- `apps/settings/src/platform/mod.rs:80`: `Platform::Omarchy => crate::sections::accounts::run_admin(&["logind", key, action], None, "Saved", section),`
- `apps/settings/src/platform/mod.rs:88`: `Platform::Omarchy => crate::sections::accounts::run_admin(&["sleep-delay", secs], None, "Saved", section),`
- `apps/settings/src/platform/mod.rs:95`: `Platform::Omarchy => crate::cmd::run(&["omarchy-hibernation-available"]).is_ok(),`
- `apps/settings/src/platform/mod.rs:109`: `Platform::Omarchy => crate::sections::network::ufw_group(page),`
- `apps/settings/src/platform/mod.rs:119`: `Platform::Omarchy => active("cups.service"),`
- `apps/settings/src/platform/mod.rs:127`: `Platform::Omarchy => crate::sections::accounts::run_admin(`
- `apps/settings/src/platform/mod.rs:140`: `Platform::Omarchy => crate::sections::accounts::run_admin(&["printer-add", queue, uri], None, "Printer added",`
- `apps/settings/src/platform/mod.rs:147`: `Platform::Omarchy => crate::sections::accounts::run_admin(&["printer-remove", queue], None, "Printer removed",`
- `apps/settings/src/platform/mod.rs:154`: `Platform::Omarchy => {`
- `apps/settings/src/platform/mod.rs:172`: `Platform::Omarchy => {`
- `apps/settings/src/platform/mod.rs:187`: `Platform::Omarchy => {`
- `apps/settings/src/platform/mod.rs:197`: `Platform::Omarchy => crate::backend::accounts::helper_installed(),`
- `apps/settings/src/platform/mod.rs:205`: `Platform::Omarchy => crate::backend::mounts::fstab(),`
- `apps/settings/src/platform/mod.rs:214`: `Platform::Omarchy => crate::backend::accounts::helper(&["mount-add-drive", id, uuid, dir, fs, options], None),`
- `apps/settings/src/platform/mod.rs:222`: `Platform::Omarchy => crate::backend::accounts::helper(&["mount-add-net", id, fstype, source, dir, options], So`
- `apps/settings/src/platform/mod.rs:229`: `Platform::Omarchy => crate::backend::accounts::helper(&["mount-remove", id], None),`
- `apps/settings/src/platform/mod.rs:239`: `Platform::Omarchy => crate::backend::accounts::helper(&["mount-test", fstype, source, options], Some(login)),`
- `apps/settings/src/platform/mod.rs:247`: `Platform::Omarchy => crate::sections::cleanup::omarchy_rows(g),`
- `apps/settings/src/platform/mod.rs:255`: `Platform::Omarchy => omarchy::about(page),`
- `apps/settings/src/platform/mod.rs:281`: `Platform::Omarchy => std::env::var_os("OMARCHY_POWERPROFILES_STATE_DIR")`
- `apps/settings/src/platform/mod.rs:304`: `Platform::Omarchy => {`
- `apps/settings/src/platform/mod.rs:315`: `Platform::Omarchy => crate::cmd::output(&["omarchy-battery-status", "--shell"]).unwrap_or_default(),`
- `apps/settings/src/platform/mod.rs:323`: `Platform::Omarchy => {`
- `apps/settings/src/platform/mod.rs:332`: `Platform::Omarchy => crate::cmd::spawn(&["omarchy-brightness-display", "--no-osd", &format!("{percent}%")]),`
- `apps/settings/src/platform/mod.rs:340`: `Platform::Omarchy => &["omarchy-system-lock"],`
- `apps/settings/src/platform/mod.rs:361`: `Platform::Omarchy => crate::cmd::spawn(&["omarchy-launch-floating-terminal-with-presentation", command]),`
- `apps/settings/src/sections/about.rs:629`: `crate::platform::Platform::Omarchy => "Omarchy's defaults",`
- `apps/settings/src/sections/apps.rs:161`: `Platform::Omarchy => g.add(&default_row(`
- `apps/settings/src/sections/apps.rs:205`: `Platform::Omarchy => {`
- `apps/settings/src/sections/nyx.rs:426`: `let theme = if suite.mode == ThemeMode::Omarchy && nyx_theme::omarchy_available() {`
- `apps/settings/src/sections/nyx.rs:562`: `let follow = suite.mode == ThemeMode::Omarchy;`
- `apps/settings/src/sections/nyx.rs:573`: `theme_dd.set_sensitive(!follow || !nyx_theme::omarchy_available());`
- `apps/settings/src/sections/nyx.rs:575`: `if nyx_theme::omarchy_available() {`
- `apps/settings/src/sections/themes.rs:43`: `nyx_theme::omarchy_available()`
- `apps/settings/src/sections/themes.rs:196`: `Origin::Omarchy => "Omarchy".into(),`
- `apps/settings/src/sections/themes.rs:599`: `crate::platform::Platform::Omarchy => {`

### nyx-share

- `apps/share-sheet/src/prefs.rs:17`: `Self { mode: ThemeMode::Omarchy, theme: "nyx-dark".into(), reduce_motion: false, glow: false, last_folder: Non`

### nyx-shell

- `crates/nyx-shell-core/src/compositor.rs:102`: `use nyx_desktop::omarchy::{Mode, workspace_mode};`

### nyx-store

- `apps/store/src/prefs.rs:17`: `mode: nyx_theme::ThemeMode::Omarchy,`

### nyx-switcher

- `apps/switcher/src/theme.rs:18`: `mode: suite.as_ref().map(|s| s.mode.clone()).unwrap_or(ThemeMode::Omarchy),`

### nyx-theater

- `apps/theater/src/prefs.rs:44`: `mode: ThemeMode::Omarchy,`

### nyx-torrents

- `apps/torrents/src/prefs.rs:118`: `mode: ThemeMode::Omarchy,`

### nyx-transfer

- `apps/nyx-transfer/src/settings.rs:31`: `mode: nyx_theme::ThemeMode::Omarchy,`

### nyx-weather

- `apps/weather/src/prefs.rs:77`: `mode: ThemeMode::Omarchy,`
- `apps/weather/src/theme.rs:96`: `if prefs::get().mode == ThemeMode::Omarchy`

## Omarchy paths


### nyx

- `uninstall.sh:80`: `rm -rf "$config/omarchy/plugins/$p"`
- `uninstall.sh:90`: `rm -rf "$config/omarchy/plugins/design-nexus.notification-center"`
- `uninstall.sh:134`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:157`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:158`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`
- `tests/test_icons.py:158` *(test)*: `colors = Path(self.temp.name) / 'state/omarchy/current/theme/colors.toml'`
- `tools/migrate_desktop.py:110`: `plugins = CONFIG / "omarchy/plugins"`
- `tools/migrate_desktop.py:164`: `for p in sorted((CONFIG / "omarchy/plugins").glob("*nixe*")) if (CONFIG / "omarchy/plugins").is_dir() else []:`
- `tools/theme.py:160`: `table = read_toml(STATE / 'omarchy/current/theme/colors.toml')`
- `tools/theme.py:173`: `paths = [CONFIG / 'nyx/theme.toml', STATE / 'omarchy/current/theme/colors.toml', SNAPSHOT]`

### nyx-accounts

- `tests/preview.py:19` *(test)*: `(config/'nyx').mkdir(parents=True);(state/'omarchy/current/theme').mkdir(parents=True)`
- `tests/preview.py:22` *(test)*: `(state/'omarchy/current/theme/colors.toml').write_text('accent = "#123456"\n')`
- `tests/preview.py:30` *(test)*: `copied_colors=base/'home/.local/share/nyx-online-accounts-preview/state/omarchy/current/theme/colors.toml'`
- `tests/preview.py:34` *(test)*: `assert copied_colors.read_text()==(state/'omarchy/current/theme/colors.toml').read_text()`

### nyx-activity

- `install.sh:395`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:396`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:408`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`
- `apps/activity/src/paths.rs:30`: `let root = std::env::var_os("OMARCHY_PATH").map(PathBuf::from).unwrap_or_else(|| PathBuf::from("/usr/share/oma`

### nyx-agents

- `install-ai-lens.sh:20`: `if [[ -d ${OMARCHY_PATH:-/usr/share/omarchy}/shell || -f $config/omarchy/shell.json ]]; then`
- `install-ai-lens.sh:21`: `mkdir -p "$config/omarchy/plugins/design-nexus.ai-lens"`
- `install-ai-lens.sh:22`: `cp -a "$root/apps/ai-lens/qml/." "$config/omarchy/plugins/design-nexus.ai-lens/"`

### nyx-archive

- `install.sh:396`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:397`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:409`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-assistant

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`
- `apps/assistant/scripts/install-plugin.sh:7`: `for manifest in "$HOME"/.config/omarchy/plugins/*.nyx-assistant/manifest.json; do`
- `apps/assistant/scripts/install-plugin.sh:12`: `target="$HOME/.config/omarchy/plugins/$plugin_id"`
- `apps/assistant/scripts/install.sh:14`: `if [[ ! -e $HOME/.config/nyx-assistant && ! -e $HOME/.config/omarchy-assistant ]]; then :; fi`
- `apps/assistant/scripts/install.sh:34`: `assets=(.local/bin/nyx-assistant-plugin-worker .local/bin/nyx-assistant-helper .local/bin/nyx-assistant-visual`
- `apps/assistant/scripts/migrate-from-omarchy.sh:9`: `[[ -d $HOME/.config/omarchy-assistant && ! -L $HOME/.config/omarchy-assistant && ! -e $HOME/.config/nyx-assist`
- `apps/assistant/scripts/migrate-from-omarchy.sh:45`: `shell_json="$HOME/.config/omarchy/shell.json"`
- `apps/assistant/scripts/migrate-from-omarchy.sh:46`: `for dir in "$HOME"/.config/omarchy/plugins/*.omarchy-assistant; do`
- `apps/assistant/scripts/migrate-from-omarchy.sh:50`: `[[ -e $HOME/.config/omarchy/plugins/$new_id ]] && continue`
- `apps/assistant/scripts/migrate-from-omarchy.sh:51`: `mv "$dir" "$HOME/.config/omarchy/plugins/$new_id"`
- `apps/assistant/scripts/migrate-from-omarchy.sh:52`: `rm -f "$HOME/.config/omarchy/plugins/$new_id/bin/nyx-bar-action"`
- `apps/assistant/scripts/migrate-from-omarchy.sh:53`: `grep -rl "$old_id\|omarchy-assistant" "$HOME/.config/omarchy/plugins/$new_id" 2>/dev/null |`
- `apps/assistant/crates/assistant-tui/src/theme/omarchy.rs:13`: `dirs.push(home.join(".local/state/omarchy/current"));`
- `apps/assistant/crates/assistant-tui/src/theme/omarchy.rs:14`: `dirs.push(home.join(".config/omarchy/current"));`
- `apps/assistant/crates/assistant-tools/src/fs.rs:68`: `".local/share/omarchy",`
- `apps/assistant/crates/assistant-tools/src/fs.rs:107`: `".config/omarchy/hooks",`
- `apps/assistant/crates/assistant-core/src/persona.rs:615`: `.join("omarchy/plugins");`

### nyx-backup

- `crates/backup-system/src/migration_inventory.rs:75`: `} else if Path::new("/usr/share/omarchy/config/hypr/monitors.lua").exists() {`

### nyx-biometrics

- `scripts/install-shell.sh:5`: `# ~/.config/omarchy/shell.json. For the administrator prompt, disable omarchy.polkit first and`
- `scripts/install-shell.sh:11`: `plugins="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"`
- `shell/design-nexus.auth-lock/Service.qml:19`: `readonly property string currentBackgroundLink: stateHome + "/omarchy/current/background"`
- `crates/nyx-auth-pam/src/notify.rs:6`: `pub const SHELL_CONFIG: &str = "/usr/share/omarchy/shell";`

### nyx-calendar

- `install.sh:426`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:427`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:439`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:87`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:110`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:111`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-capture

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-chat

- `install.sh:406`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:419`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:87`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:110`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:111`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-contacts

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-control-center

- `install.sh:73`: `plugins="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"`
- `uninstall.sh:15`: `rm -rf "$config/omarchy/plugins/$p"`

### nyx-core

- `crates/nyx-core/src/paths.rs:65`: `state_home().join("omarchy/current/theme")`

### nyx-design

- `mockups/bar/render.sh:14`: `bg=$(ls "${XDG_STATE_HOME:-$HOME/.local/state}"/omarchy/current/theme/backgrounds/* 2>/dev/null | grep -v omar`
- `mockups/desktop/render.sh:10`: `bg=$(ls "${XDG_STATE_HOME:-$HOME/.local/state}"/omarchy/current/theme/backgrounds/* 2>/dev/null | grep -v omar`
- `mockups/dock/render.sh:14`: `bg=$(ls "${XDG_STATE_HOME:-$HOME/.local/state}"/omarchy/current/theme/backgrounds/* 2>/dev/null | grep -v omar`
- `mockups/icon-sets/render.py:29`: `OMARCHY = Path("/usr/share/omarchy/themes")`
- `mockups/lyra/render.sh:13`: `bg=$(ls "${XDG_STATE_HOME:-$HOME/.local/state}"/omarchy/current/theme/backgrounds/* 2>/dev/null | grep -v omar`
- `crates/nyx-theme-core/previews/render.sh:21`: `src=/usr/share/omarchy/themes/${omarchy[$id]:-none}/preview.png`
- `crates/nyx-theme-core/src/omarchy.rs:178`: `let theme_name = std::fs::read_to_string(nyx_core::paths::state_home().join("omarchy/current/theme.name"))`
- `crates/nyx-theme-core/src/omarchy.rs:322`: `let dirs = [PathBuf::from("/usr/share/omarchy/themes"), nyx_core::paths::config_home().join("omarchy/themes")]`
- `crates/nyx-theme-core/src/paths.rs:83`: `dirs.push(paths::state_home().join("omarchy/current"));`

### nyx-dock

- `apps/dock/src/dock.rs:319`: `/// The pins in ~/.config/omarchy/shell.json, if the user set their own.`
- `apps/dock/src/handover.rs:2`: `//! Omarchy's own command (it records the choice in ~/.config/omarchy/shell.json), so`

### nyx-files

- `src/portal_setup/omarchy.rs:164`: `let mut paths = vec![PathBuf::from("/usr/share/omarchy/version")];`
- `src/portal_setup/omarchy.rs:166`: `paths.push(PathBuf::from(home).join(".local/share/omarchy/version"));`

### nyx-fonts

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-git

- `install.sh:414`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:415`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:427`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:82`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:105`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:106`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-glimpse

- `install.sh:409`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:410`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:422`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:84`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:107`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:108`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`
- `apps/glimpse/src/omarchy.rs:41`: `std::env::var_os("OMARCHY_PATH").map(PathBuf::from).unwrap_or_else(|| "/usr/share/omarchy".into())`

### nyx-lyra

- `install.sh:411`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:412`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:424`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:82`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:105`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:106`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-mail

- `install.sh:412`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:413`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:425`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:86`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:109`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:110`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-media-player

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-music

- `install.sh:410`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:411`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:423`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:82`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:105`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:106`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-news

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-notepad

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-notes

- `install-panel.sh:20`: `if [[ -d ${OMARCHY_PATH:-/usr/share/omarchy}/shell || -f $config/omarchy/shell.json ]]; then`
- `install-panel.sh:21`: `mkdir -p "$config/omarchy/plugins/design-nexus.notes"`
- `install-panel.sh:22`: `cp -a "$root/qml/panel/." "$config/omarchy/plugins/design-nexus.notes/"`

### nyx-notification-center

- `install.sh:83`: `plugins="$config/omarchy/plugins"`
- `uninstall.sh:29`: `rm -rf "$config/omarchy/plugins/$p"`

### nyx-office

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:105`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:106`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-passwords

- `install.sh:410`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:411`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:423`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:82`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:105`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:106`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-pdf

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-photos

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-pulse

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-reminders

- `install.sh:426`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:427`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:439`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:87`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:110`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:111`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-settings

- `install.sh:409`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:410`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:422`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:82`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:105`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:106`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`
- `extensions/streamdeck/galleon_draw.py:509`: `omarchy = os.path.expanduser("~/.config/omarchy/current/background")`
- `extensions/streamdeck/galleon_page.py:161`: `image = os.path.join(HOME, ".config/omarchy/current/background")`
- `extensions/logitech/src/paths.rs:34`: `state_home().join("omarchy/current/theme/colors.toml")`
- `extensions/common/src/sys.rs:59`: `let text = std::fs::read_to_string(state.join("omarchy/current/theme/colors.toml"))`
- `extensions/common/src/sys.rs:60`: `.or_else(|_| std::fs::read_to_string(home().join(".config/omarchy/current/theme/colors.toml")))`
- `extensions/asus/src/paths.rs:18`: `xdg("XDG_STATE_HOME", ".local/state").join("omarchy/current/theme")`
- `apps/settings/src/backend/shell.rs:1`: `//! Omarchy shell config (~/.config/omarchy/shell.json) and toggle flags.`
- `apps/settings/src/sections/apps.rs:351`: `home.join(".config/omarchy/defaults/agent")`
- `apps/settings/src/sections/keybindings.rs:294`: `dirs.push("/usr/share/omarchy/default/hypr/bindings".into());`
- `apps/settings/src/sections/theme.rs:53`: `[paths::omarchy_config().join("themes").join(&slug), PathBuf::from("/usr/share/omarchy/themes").join(&slug)]`

### nyx-shell

- `crates/nyx-shell-core/src/theme.rs:21`: `/// ~/.local/state/omarchy/current/theme: what Follow Omarchy reads.`
- `crates/nyx-shell-core/src/theme.rs:44`: `omarchy_dir: xdg("XDG_STATE_HOME", ".local/state").join("omarchy/current/theme"),`
- `crates/nyx-shell-core/src/theme.rs:185`: `omarchy_dir: dir.join("omarchy/current/theme"),`
- `crates/nyx-shell-core/tests/fake_hyprland.rs:52` *(test)*: `omarchy_dir: tmp.path().join("state/omarchy/current/theme"),`
- `crates/nyx-shell-core/src/core/tests.rs:21`: `omarchy_dir: dir.path().join("omarchy/current/theme"),`

### nyx-store

- `install.sh:396`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:397`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:409`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-theater

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-torrents

- `install.sh:394`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:395`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:407`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:81`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:104`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:105`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### nyx-weather

- `install.sh:410`: `if printf '%s\n' "${apps[@]}" | grep -qx weather && [[ -d $config/omarchy/plugins && -f $src/apps/weather/plug`
- `install.sh:411`: `dest="$config/omarchy/plugins/design-nexus.weather"`
- `install.sh:423`: `dest="$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:82`: `[[ $a == settings ]] && rm -rf "$config/omarchy/plugins/design-nexus.settings-gear"`
- `uninstall.sh:105`: `if [[ ! -x $bin/nyx-weather && -d $config/omarchy/plugins/design-nexus.weather ]]; then`
- `uninstall.sh:106`: `rm -rf "$config/omarchy/plugins/design-nexus.weather"`

### umbra-icons

- `umbra/palette.py:81`: `for path in (state / "omarchy/current/theme/colors.toml", config / "omarchy/current/theme/colors.toml"):`
