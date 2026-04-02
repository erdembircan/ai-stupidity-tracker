# AST - AI Stupidity Tracker

[![CI](https://github.com/erdembircan/ai-stupidity-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/erdembircan/ai-stupidity-tracker/actions/workflows/ci.yml)

A CLI tool that checks how Claude/Anthropic and OpenAI models are performing on [aistupidlevel.info](https://aistupidlevel.info/) — right from your terminal.

![AST screenshot](assets/screenshot.png)

## What it shows

- **Global Index** — overall AI health score and trend
- **Model Rankings** — where all tracked models rank on the leaderboard
- **Best For Categories** — whether the provider is best for code, most reliable, fastest, or best value
- **Alerts** — active degradations, instability warnings, and models to avoid
- **Provider Trust** — trust score, trend, and incident count
- **Drift Incidents** — detected performance drift for tracked models

## Requirements

- **macOS** (Sequoia 15+ ships with both dependencies)
- `curl` — built-in
- `jq` — built-in on macOS Sequoia+, otherwise `brew install jq`

## Installation

```bash
# Clone the repo
git clone git@github.com:erdembircan/ai-stupidity-tracker.git
cd ai-stupidity-tracker

# Make it executable and add to PATH
chmod +x ast
ln -s "$(pwd)/ast" /usr/local/bin/ast
```

## Usage

```bash
ast              # Claude status report (default)
ast --openai     # OpenAI status report
ast --claude     # Claude status report (explicit)
ast --watch      # Live dashboard, refreshes every 60s
ast --watch 300  # Live dashboard, custom interval (300s)
ast --json       # Machine-readable JSON output
ast --help       # Show usage info
NO_COLOR=1 ast   # Disable colors
```

Provider flags can be combined with any other option:

```bash
ast --openai --json       # OpenAI data as JSON
ast --openai --watch      # Live OpenAI dashboard
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
