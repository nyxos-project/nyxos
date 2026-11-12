# Nyx <App> scorecard

- **Repository:** design-nexus/nyx-<app> at `<commit>` (pinned in nyx-packages: yes/no)
- **Release tier:** base | welcome | store | not offered
- **Purpose:** one line
- **Stack:** Rust/GTK4 (+ QML, daemons, D-Bus names)
- **Binaries / services:** from the package (`nyx-packages/pkgs/nyx-<app>.nix`)

## Scores

Each 0 to 3: 0 broken or missing, 1 poor (major gaps), 2 adequate (minor gaps), 3 good
(no significant gaps found). "n/v" when the evidence doesn't exist yet. Static scores come
from source inspection; runtime scores from Phases D to F.

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | | |
| UX | | |
| Accessibility | | |
| Reliability | | |
| Integration | | |
| Packaging | | |
| Maintainability | | |

## Functionality

Core workflows and whether the code implements them (implemented / partial / stub);
error handling; persistence (where data lives); import/export.

## UX and accessibility (static)

Navigation, keyboard shortcuts, empty/error/loading states, accessible names on
icon-only buttons (`set_tooltip_text` / `update_property(Label)`), hard-coded colours
outside the theme.

## Reliability

Startup and shutdown paths, panics (`unwrap()`/`expect()` on runtime data), offline
behaviour, background daemons and their restart policy.

## Integration and packaging

Desktop entry, icon, D-Bus activation, systemd user units, actions manifest, Glimpse
provider, Share, Omarchy leftovers (`omarchy-*` calls, `~/.config/omarchy`).

## Maintenance

Tests (count), docs, dependency pins (nyx-core / nyx-design revisions), notable
dependencies.

## Runtime results

Filled from Phase D to F: smoke launch, screenshots, startup time, memory.

## Findings

Findings in the format of [../evidence/FINDINGS-FORMAT.md](../evidence/FINDINGS-FORMAT.md).
