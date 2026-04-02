# AI Stupidity Tracker (AST)

## Project Overview

A bash CLI tool (`ast`) that scrapes https://aistupidlevel.info/ REST API and displays Claude/Anthropic-specific performance data. **Completely Claude-focused** — all other providers are filtered out unless contextually relevant (e.g., global index).

## Architecture

- **Single bash script** — no Node.js, no Python, no build step
- **Dependencies:** `curl` (built-in macOS) + `jq` (built-in macOS Sequoia+)
- **jq check at startup** — if missing, print install instruction and exit. No fallback.
- **Command name:** `ast`

## API Endpoints

| Endpoint | Purpose |
|---|---|
| `/dashboard/cached?period=latest&sortBy=combined&analyticsPeriod=latest` | Main data: models, recommendations, degradations, provider trust |
| `/dashboard/global-index` | Global intelligence index + trend |

## Data Scope (Claude-Only)

What to extract and display:

1. **Best For categories** — Only if a Claude model is Best for Code, Most Reliable, Fastest Response, or Best Value
2. **Negative categories** — Only if a Claude model is flagged Unreliable or has Active Degradations
3. **Claude model rankings** — All Anthropic models from the leaderboard with score, rank, status
4. **Anthropic provider trust** — Trust score + trend
5. **Claude benchmark dimensions** — 9-axis scores: CORR, CMPL, QUAL, EFF, STBL, EDGE, DBG, FMT, SAFE
6. **Claude drift incidents** — If any drift detected for Claude models
7. **Global index** — Score + trend as context (is it a bad day for everyone or just Claude)

## CLI Output Styling

### Design Principles
- Modern, clean TUI aesthetic — not 1970s terminal
- Structured sections using Unicode box-drawing
- Semantic colors only (not decorative)
- Respect `NO_COLOR` env var

### Box Drawing
- Use **rounded corners**: `╭ ╮ ╰ ╯ │ ─`
- Borders rendered in DIM (`\033[2m`) for visual hierarchy
- Section titles in BOLD inline with top border

### Colors (256-color baseline for Terminal.app compatibility)
- Green (`\033[32m`) — good status, stable
- Yellow (`\033[33m`) — warning, volatile
- Red (`\033[31m`) — critical, degraded, errors
- Cyan (`\033[36m`) — accent, headers, branding
- Gray/DIM (`\033[90m` / `\033[2m`) — borders, secondary text, separators
- Bold white (`\033[1m`) — key values, emphasis

### Symbols (standard Unicode, no Nerd Fonts required)
- `✓` success/good
- `✗` failure/bad
- `⚠` warning
- `●` status indicator
- `→` arrow/pointer
- `◆` brand/accent marker
- `•` bullet
- Dot-leaders (`···`) between labels and values

### Layout
- `printf` over `echo` for escape sequences
- 2-space indent from terminal edge
- Blank lines between sections
- Dot-leaders for key-value alignment
- Compact — should fit on one screen without scrolling

### Example Layout
```
  ◆ AST  v0.1.0 · 2026-04-02 16:18 CET

  ╭── Global Index ─────────────────────────╮
  │  Score ·················· 84/100 STABLE  │
  ╰─────────────────────────────────────────╯

  ╭── Claude Rankings ──────────────────────╮
  │  #3  claude-sonnet-4      64  ⚠ VOLATILE│
  │  #4  claude-opus-4-5      64  ⚠ VOLATILE│
  ╰─────────────────────────────────────────╯

  ╭── Alerts ───────────────────────────────╮
  │  ✗ UNRELIABLE  claude-sonnet-4-20250514 │
  │  ⚠ DEGRADED   ±17pt swings, avg 58pts  │
  ╰─────────────────────────────────────────╯
```
