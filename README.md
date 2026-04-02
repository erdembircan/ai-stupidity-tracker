# AST - AI Stupidity Tracker

[![CI](https://github.com/erdembircan/ai-stupidity-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/erdembircan/ai-stupidity-tracker/actions/workflows/ci.yml)

A CLI tool that checks how Claude/Anthropic models are performing on [aistupidlevel.info](https://aistupidlevel.info/) — right from your terminal.

![AST screenshot](assets/screenshot.png)

## What it shows

- **Global Index** — overall AI health score and trend
- **Claude Rankings** — where all Claude models rank on the leaderboard
- **Best For Categories** — whether Claude is best for code, most reliable, fastest, or best value
- **Alerts** — active degradations, instability warnings, and models to avoid
- **Anthropic Provider Trust** — trust score, trend, and incident count
- **Drift Incidents** — detected performance drift for Claude models

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
ast              # Claude status report
ast --watch      # Live dashboard, refreshes every 60s
ast --watch 300  # Live dashboard, custom interval (300s)
ast --json       # Machine-readable JSON output
ast --help       # Show usage info
NO_COLOR=1 ast   # Disable colors
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
