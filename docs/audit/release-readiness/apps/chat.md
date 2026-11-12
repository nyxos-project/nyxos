# Nyx Chat scorecard

- **Repository:** design-nexus/nyx-chat at `38a8bae0c6` (pinned in nyx-packages: yes, 0 behind origin)
- **Release tier:** welcome (`catalog.toml:427-432`; per-user install)
- **Purpose:** desktop chat client for local models in Nyx AI Core (and optional Ollama/remote llama.cpp servers), with tools, knowledge bases and a Hugging Face model marketplace
- **Stack:** Rust/GTK4 (18.7k lines), SQLite, `nyx-ai-client`; no daemons or D-Bus names of its own
- **Binaries / services:** `nyx-chat` (window, `--quick`, `--section`); runtime PATH adds wl-clipboard, grim, slurp, pipewire, poppler-utils, xdg-utils (`nyx-packages/pkgs/nyx-chat.nix`). AI Core is on for every install (`nyxos/modules/nixos/apps.nix`, `nyx.ai.enable`).

## Scores

| Area | Score | Basis |
| --- | --- | --- |
| Functionality | 2 | Broad, implemented chat/tools/knowledge/marketplace; voice depends on unpackaged whisper.cpp and Piper |
| UX | 3 | Rich keyboard shortcuts, temporary chats, compare, clear "model missing" states |
| Accessibility | 2 | 58 tooltips for 30 icon uses; one explicit accessible property |
| Reliability | 3 | 15 unwrap/expect in non-test code; SQLite WAL; no silent model swaps |
| Integration | 2 | Uses AI Core; not Nyx Voice; no action manifest packaged |
| Packaging | 2 | Desktop entry with actions and icon; voice runtimes missing |
| Maintainability | 2 | 78 tests, CI; README Omarchy wording; nyx-ai pin `da5b6f6` differs from the suite's |

## Functionality

- **AI Core:** a llama.cpp address on localhost always means Nyx AI Core (`apps/chat/README.md`, `src/llama/core.rs`); Ollama only if the user runs it ("Chat never starts or stops Ollama"). Implemented.
- **External providers:** no cloud LLM providers (no OpenAI/Anthropic keys); "online" means user-added remote llama.cpp/Ollama servers. Web search tools: DuckDuckGo default, SearXNG, Brave, Tavily (`src/tools/web.rs:1-35`).
- **Tools:** `web_search`, `web_fetch`, `calculator` on by default for new chats (`src/prefs.rs:197`); `run_shell` and memories ask every time (`src/tools/mod.rs:176-209`); file reading only inside allowed folders; location off by default.
- **History:** one SQLite file `~/.local/share/nyx-chat/chat.db` (WAL, message tree) plus `attachments/` (`src/paths.rs`, `src/store.rs:1-30`); temporary chats aren't saved. Import/export JSON and Open WebUI import.
- **Voice:** own whisper.cpp + Piper subprocesses (`src/voice.rs:1-40`), not Nyx Voice (NYX-APP-CHAT-001).
- No TODO/`unimplemented!` markers.

## UX and accessibility (static)

Esc stops a reply, Ctrl+Shift+N temporary chat, Ctrl+Shift+S region screenshot (slurp), Ctrl+Space dictation, `/`, `@`, `#` pickers (README). 4 hard-coded colours in `style.css`. Icon-only buttons mostly carry tooltips.

## Reliability

Single-process GTK app; errors surface as messages ("Dictation needs whisper.cpp…", model not installed). Offline: local models work; web tools and marketplace fail with messages. `nvidia-smi` only on demand (battery note in README).

## Integration and packaging

Desktop entry with New Chat/Quick Ask/Models/Marketplace actions and icon (`apps/chat/data/io.github.design_nexus.nyx.Chat.desktop`, `crates/nyx-icons/apps/…Chat.svg`). Control interface `src/control.rs` is used by the Assistant's `nyx-apps` ability, but the package installs no actions manifest. 11 Omarchy references are wording and theme fallback only.

## Maintenance

78 tests; CI `check.yml`, `release.yml`. Pins nyx-core `4f05fb8`, nyx-design `cf39397`, nyx-ai `da5b6f6` (Assistant/Glimpse use `9633690`; origin `d325462`). `CLAUDE.md` in the app folder.

## Runtime results

- Smoke test (Chat): dock launch **ok**, Glimpse/GIO launch **ok** (evidence/smoke-dock, smoke-glimpse).
- Start to first window 643 / 529 ms (two warm runs), RSS 146 MB 4 s after start (logs/perf-app-startup.txt, dev VM).
- AI Core endpoint answered without a key from any local user (NYX-SEC-001 confirmed); Chat UI opened; inference in the VM is not representative.

## Findings

### NYX-APP-CHAT-001: Voice input and read-aloud use private whisper.cpp/Piper runners that NyxOS doesn't ship

- **Component:** nyx-chat `apps/chat/src/voice.rs:1-40`; `nyx-packages/pkgs/nyx-chat.nix`
- **Category:** functionality
- **Severity:** P2
- **Status of feature:** partial
- **Description:** Dictation shells out to `whisper-cli` with a user-chosen ggml model and reading aloud to Piper; neither is in the package's runtime inputs or Nyx Voice.
- **Expected:** Chat dictates and speaks through Nyx Voice (H05: Nyx Voice serves dictation, listening and speaking for Nyx apps).
- **Actual:** `dictation_problem()` returns "Dictation needs whisper.cpp" / "Choose a whisper model file" on a stock install.
- **Reproduce / verify:** Press Ctrl+Space in Chat on NyxOS. Static; confirm at runtime.
- **Evidence:** as above; `nyx-packages/modules/nixos/default.nix:164-171`
- **Affected versions:** `38a8bae0c6`
- **User impact:** Advertised voice features don't work without manual installs and model downloads.
- **Recommended correction:** Use `nyx-voice-proto`/`nyx-voiced` for dictation and TTS; keep whisper/Piper as optional fallbacks.
- **Effort:** M
- **Dependencies:** Nyx Voice client API
- **Verification criteria:** Dictation works on a fresh install with Nyx Voice models only.

### NYX-APP-CHAT-002: Web tools on by default; search API keys kept in plain settings file

- **Component:** nyx-chat `apps/chat/src/prefs.rs:125-129,197-203`
- **Category:** privacy
- **Severity:** P3
- **Status of feature:** implemented, not verified
- **Description:** New chats enable `web_search`/`web_fetch`, so a model can send queries to DuckDuckGo without a per-chat choice; Brave/Tavily keys are stored in `~/.config/nyx-chat/settings.toml`.
- **Expected:** Local-first default (handoff 10 privacy); secrets in the Secret Service like Transfer and Accounts.
- **Actual:** As cited; the composer shows a toggle and citations.
- **Reproduce / verify:** Fresh profile, ask a current-events question, observe network.
- **Evidence:** as above
- **Affected versions:** `38a8bae0c6`
- **User impact:** Queries leave the computer by default; API keys readable by any same-user process.
- **Recommended correction:** Ask once on first web use; move keys to the Secret Service.
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** No outbound search before opt-in; keys absent from settings.toml.

### NYX-APP-CHAT-003: README and catalog text out of date

- **Component:** nyx-chat `apps/chat/README.md:1-6`; `nyx-system/crates/nyx-catalog/catalog.toml:429`
- **Category:** docs
- **Severity:** P3
- **Status of feature:** verified
- **Description:** README says it takes colours "from your Omarchy theme"; catalog says "local or online" though no online providers exist beyond self-hosted servers.
- **Expected:** NyxOS wording; catalog matches capability.
- **Actual:** As cited.
- **Reproduce / verify:** Read the files.
- **Evidence:** as above
- **Affected versions:** `38a8bae0c6`
- **User impact:** Wrong expectations (cloud models).
- **Recommended correction:** "Chat with AI models on this computer or your own servers."
- **Effort:** S
- **Dependencies:** none
- **Verification criteria:** Text matches behaviour.
