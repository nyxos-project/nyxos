# Nyx News scorecard

- **Repository:** design-nexus/nyx-news at `f7604d2092` (pinned in nyx-packages: yes, current with `origin/main`)
- **Release tier:** welcome (installed per user)
- **Purpose:** local RSS/Atom/JSON Feed reader
- **Stack:** Rust/GTK4; `nyx-news-core` (reqwest rustls blocking, ammonia, SQLite); nyx-glimpse SDK `6f9f732`
- **Binaries / services:** `nyx-news`, `nyx-news-glimpse` (plugin in `share/nyx-news/glimpse`) (`nyx-packages/pkgs/nyx-news.nix`); no units

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 3 | Subscribe, folders, read/star/save, search, OPML import/export, offline reading |
| UX | 2 | Keyboard map; sync, discovery and summaries visible in settings but off |
| Accessibility | 2 | 3 icon-only buttons, 5 tooltips, 1 explicit label |
| Reliability | 3 | 4 non-test `unwrap()` on invariants; backoff for failing feeds |
| Integration | 3 | Glimpse plugin with a read-only library mount; Assistant tools |
| Packaging | 3 | Simple recipe, plugin installed |
| Maintainability | 2 | 41 tests; README describes Omarchy |

## Functionality

Add feed by URL (http only when typed), folders, All/Unread/Starred/Saved, search over
titles/authors/excerpts, OPML import/export, list and compact layouts (README.md:15-24).
Articles render as plain text from the feed (`apps/news/src/reader.rs:302-357`, `html_text`),
not HTML. Refresh about hourly with backoff. Data: `~/.local/share/nyx-news/news.sqlite`,
cache `~/.cache/nyx-news/`. Sync, publication discovery and local summaries are reserved
and off (README.md:37-38).

## UX and accessibility (static)

Ctrl+F/N/I/E, J/K, Enter, M/S/B/R, F1. No hard-coded colours.

## Reliability

Fetch has timeouts, a size cap and per-hop checks against private, loopback and link-local
addresses, with redirects followed by hand (`crates/nyx-news-core/src/fetch.rs:1-31, 73-113`).
`unwrap()`s are list-item downcasts and a lookup after a membership check
(`timeline.rs:54, 82`, `paper.rs:60`).

## Integration and packaging

`io.github.design_nexus.nyx.News.desktop` (no MIME types; feeds aren't opened from files),
icon present. Glimpse mounts only the News library read-only for its plugin
(nyx-glimpse `apps/glimpse/src/plugins.rs:398-414`); per-user linking gap as
NYX-APP-MAIL-002. Control interface, no action manifest. Omarchy: theme default only.

## Maintenance

41 tests. CI: check + release. README.md:3 "for Omarchy".

## Runtime results

- Smoke test (News): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).

## Findings

### NYX-APP-NEWS-001: Reserved features shown but off

- **Component:** nyx-news `README.md`, `apps/news/src/discover_page.rs`, settings page
- **Category:** functionality
- **Severity:** P3
- **Status of feature:** approved, not implemented
- **Description:** Sync, publication discovery and local summaries are "reserved in the schema and the settings card" and off in this version.
- **Expected:** Unavailable features hidden or clearly labelled.
- **Actual:** README.md:37-38; `discover_page.rs` present.
- **Reproduce / verify:** Open News settings (runtime).
- **Evidence:** `nyx-news/README.md:37-38`
- **Affected versions:** f7604d2092
- **User impact:** Controls that do nothing.
- **Recommended correction:** Hide until implemented.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No inert controls in settings.

### NYX-APP-NEWS-002: README describes Omarchy

- **Component:** nyx-news `README.md`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** README.md:3 "for Omarchy", curl install.
- **Expected:** NyxOS documented.
- **Actual:** README.md:3.
- **Reproduce / verify:** `rg -n Omarchy nyx-news/README.md`
- **Evidence:** `nyx-news/README.md:3`
- **Affected versions:** f7604d2092
- **User impact:** Minor.
- **Recommended correction:** Add NyxOS section.
- **Effort:** S
- **Dependencies:** NYX-DOC findings
- **Verification criteria:** README covers NyxOS.
