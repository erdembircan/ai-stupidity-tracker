# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.4]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/erdembircan/ai-stupidity-tracker/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/erdembircan/ai-stupidity-tracker/releases/tag/v1.0.0
