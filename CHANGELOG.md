# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-04-25

### Added

- `Ctrl+R` keybind in watch mode to trigger an immediate forced refresh
- Braille spinner feedback during forced refresh
- Stdin flush to prevent stacked refresh requests

## [1.2.0] - 2026-04-21

### Added

- `--track=MODEL` flag to highlight a model name in the output with a bold white-on-magenta badge (substring match across all sections)

## [1.1.2] - 2026-04-17

### Fixed

- Render unavailable models (e.g. newly-added `claude-opus-4-7`) with aligned `×` markers instead of overflowing the rankings box
- Fall back to the most recent non-null history entry when `Global AI Index` score is transiently null, so the row no longer shows a blank/misaligned value

## [1.1.1] - 2026-04-14

### Fixed

- Retry on API failure instead of exiting silently — retries every 30s with live countdown, up to 10 attempts (5 minutes)

## [1.1.0] - 2026-04-05

### Added

- `--graph` flag to display a real-time score graph for individual models
- Graph section renders inline Braille-character sparkline charts

### Fixed

- Equal-width graph segments and cap samples to chart width
- ShellCheck and shfmt lint compliance for graph feature

## [1.0.9] - 2026-04-04

### Changed

- Add `.gitattributes` with `export-ignore` to slim down Homebrew tarball
- Move GitHub Pages to orphan `gh-pages` branch (docs removed from master)

## [1.0.8] - 2026-04-04

### Added

- `ast-hook` now shows a confirmation message when already using the best coding model

### Changed

- GitHub Pages deployment moved to dedicated `gh-pages` branch

## [1.0.7] - 2026-04-03

### Added

- `--section=LIST` flag for filtering and ordering sections (comma-separated)
- Valid sections: global, rankings, recommendations, coder, alerts, trust, drift

### Changed

- Refactored render into per-section functions with dispatch loop
- Buffered render output to eliminate flicker

## [1.0.6] - 2026-04-03

### Changed

- Rename "Best For Categories" to "Recommendations (7d)" to reflect 7-day rolling data source

## [1.0.5] - 2026-04-03

### Added

- Auto-update docs version on release via GitHub Actions

## [1.0.4] - 2026-04-03

### Added

- "Best Coder" section showing the provider's top model for coding
- Per-model coding score calculation using aistupidmeter's 9-axis formula
- `bestCoder` field in `--json` output with score, correctness, complexity, and code quality

### Changed

- `ast-hook` now recommends switching based on coding score instead of overall rank

## [1.0.3] - 2026-04-03

### Added

- `--version` flag
- GitHub Pages formulae site
- Automated Homebrew formula bump via GitHub Actions
- Reusable CI checks workflow

### Changed

- Removed `-h` short flag in favor of explicit `--help`
- Version tests are now version-agnostic with semver pattern matching

## [1.0.2] - 2026-04-03

### Added

- Apache 2.0 license

### Chores

- Add `.vscode/` to `.gitignore`

## [1.0.1] - 2026-04-03

### Fixed

- Rename `.claudeRankings` to `.rankings` in `ast-hook` to match renamed JSON output key after OpenAI support

## [1.0.0] - 2026-04-03

### Added

- Multi-provider support with `--claude` (default) and `--openai` flags
- Global AI Index section with score, trend, and performing models
- Model rankings with score and status indicators
- Best-for categories (code, reliable, fastest, value)
- Alerts section with degradation and avoid-now warnings
- Provider trust score, trend, and incident count
- Drift incident tracking per model
- `--json` flag for machine-readable output
- `--watch` flag for live dashboard with configurable interval
- Rank change arrows in watch mode
- Next update countdown in watch mode status line
- `ast-hook` for Claude Code model ranking notifications
- Braille loading spinner during data fetch
- `NO_COLOR` environment variable support
- Homebrew installation via `brew install erdembircan/tap/ast`
- CI workflow with ShellCheck, shfmt, and bats
- Offline test fixtures for deterministic testing

[1.3.0]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.9...v1.1.0
[1.0.9]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.8...v1.0.9
[1.0.8]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/erdembircan/ai-stupidity-tracker/releases/tag/v1.0.0
