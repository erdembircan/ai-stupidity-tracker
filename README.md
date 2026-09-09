# AST - AI Stupidity Tracker

[![CI](https://github.com/erdembircan/ai-stupidity-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/erdembircan/ai-stupidity-tracker/actions/workflows/ci.yml)

A CLI tool that tracks AI model performance on [aistupidlevel.info](https://aistupidlevel.info/) — supports Claude/Anthropic and OpenAI, right from your terminal.

![AST screenshot](assets/screenshot.png)

## What it shows

- **Global Index** — overall AI health score and trend
- **Model Rankings** — where all tracked models rank on the leaderboard
- **Recommendations (7d)** — 7-day rolling picks: best for code, most reliable, fastest, best value
- **Best Coder** — provider's top model for coding, scored from the latest 7-axis code-benchmark run using the site's published axis weights
- **Alerts** — active degradations, instability warnings, and models to avoid
- **Provider Trust** — trust score, trend, and incident count
- **Drift Incidents** — detected performance drift for tracked models

## Requirements

- **macOS** (Sequoia 15+ ships with both dependencies)
- `curl` — built-in
- `jq` — built-in on macOS Sequoia+, otherwise `brew install jq`

## Installation

### Homebrew

```bash
brew install erdembircan/tap/ast
```

### Manual

```bash
git clone git@github.com:erdembircan/ai-stupidity-tracker.git
cd ai-stupidity-tracker
chmod +x ast
ln -s "$(pwd)/ast" /usr/local/bin/ast
```

## Usage

```bash
ast                              # Claude status report (default)
ast --openai                     # OpenAI status report
ast --claude                     # Claude status report (explicit)
ast --watch                      # Live dashboard, refreshes every 1800s (30 min)
ast --watch 300                  # Live dashboard, custom interval (300s)
ast --graph=claude-opus-4-6      # Live score graph for a model (implies --watch)
ast --track=claude-opus-4-6      # Highlight a model and show the switch suggestion
ast --json                       # Machine-readable JSON output
ast --section=coder              # Show only Best Coder section
ast --section=rankings,alerts    # Show specific sections in order
ast --version                    # Show version number
ast --help                       # Show usage info
NO_COLOR=1 ast                   # Disable colors
```

Valid sections: `global`, `rankings`, `recommendations`, `coder`, `alerts`, `trust`, `drift`, `graph`

Provider and section flags can be combined with any other option:

```bash
ast --openai --json            # OpenAI data as JSON
ast --openai --watch           # Live OpenAI dashboard
ast --openai --section=coder   # OpenAI best coder only
```

## Switching models live

When you run watch mode with `--track` or `--graph`, press `m` to open the model picker: use the arrow keys to move through the current provider's models — each shown with its score and status — and press `Enter` to switch. `Esc` cancels. The dashboard footer shows an `m switch model` hint whenever the picker is available.

The newly selected model becomes the tracked and graphed target immediately, no restart required. Switching resets the score graph so it starts collecting fresh history for the new model.

```bash
ast --graph=claude-opus-4-6      # start graphing one model...
                                 # ...then press m to switch to another
```

## Switch suggestion

`--track` also turns on a **Switch Suggestion** box at the top of the report. It answers one question: should you keep using the model you track, or move to the provider's current top model?

The decision uses the model's *tier* — the base level the API assigns to each model, exposed on the per-model endpoint `/api/models/<id>` — not the leaderboard score. Scores move from run to run; the tier does not. Models sharing the top tier are treated as equivalent, so the box says `KEEP` even when another top-tier model happens to hold a higher score at that moment. It says `SWITCH` only when the tracked model sits below the top tier, and it names the top-tier model with the highest current score as the target.

```
  ╭── Switch Suggestion ────────────────────────────────╮
  │ ⚠ SWITCH  claude-opus-4-8                           │
  │   → claude-fable-5 (tier 80, score 72)              │
  │   Tracked tier 79 · top tier 80                     │
  ╰─────────────────────────────────────────────────────╯
```

Other outcomes: `UNKNOWN` when the API has no tier for the tracked model, `NOT FOUND` when no model of the selected provider matches the tracked name, and `UNAVAILABLE` when the tier data could not be fetched.

The box is tied to `--track` only. `--graph` does not show it, and `--section` neither adds nor removes it. In watch mode it is re-evaluated on every refresh, and when you switch the tracked model with `m` it follows the new selection.

```bash
ast --track=claude-opus-4-8          # one-shot report with the suggestion box
ast --watch --track=claude-opus-4-8  # live; press m to track another model
```

## Development

```bash
make check      # Run lint + format check + tests
make test       # Run tests offline (mock API fixtures)
make test-live  # Run tests against the live API
make lint       # ShellCheck
make fmt        # shfmt format check
```

## Data source

All data is fetched from the [aistupidlevel.info](https://aistupidlevel.info/) REST API. No scraping, no headless browser — just clean JSON endpoints.

## License

[Apache-2.0](LICENSE)
