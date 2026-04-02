#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  AST="$DIR/ast"
}

# ── Arg Parsing ──────────────────────────────────────

@test "unknown flag exits with error" {
  run "$AST" --foo
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option: --foo"* ]]
}

@test "unknown flag shows usage hint" {
  run "$AST" --foo
  [[ "$output" == *"Usage: ast"* ]]
}

@test "--watch=abc rejects non-numeric interval" {
  run "$AST" --watch=abc
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid watch interval: abc"* ]]
}

@test "--watch=<special chars> rejects non-numeric interval" {
  run "$AST" --watch=10s
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid watch interval"* ]]
}

# ── JSON Output ──────────────────────────────────────

@test "--json produces valid JSON" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  echo "$output" | jq empty
}

@test "--json output has expected top-level keys" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.version' >/dev/null
  echo "$output" | jq -e '.timestamp' >/dev/null
  echo "$output" | jq -e '.globalIndex' >/dev/null
  echo "$output" | jq -e '.claudeRankings' >/dev/null
  echo "$output" | jq -e '.bestFor' >/dev/null
  echo "$output" | jq -e '.alerts' >/dev/null
  echo "$output" | jq -e '.providerTrust' >/dev/null
  echo "$output" | jq -e '.driftIncidents' >/dev/null
}

@test "--json claudeRankings contains only anthropic models" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  non_claude=$(echo "$output" | jq '[.claudeRankings[] | select(.name | test("claude"; "i") | not)] | length')
  [ "$non_claude" -eq 0 ]
}

@test "--json claudeRankings entries have rank, name, score, status" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  count=$(echo "$output" | jq '.claudeRankings | length')
  if [ "$count" -gt 0 ]; then
    echo "$output" | jq -e '.claudeRankings[0] | .rank and .name and .score and .status' >/dev/null
  fi
}

@test "--json globalIndex has score and trend" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.globalIndex.score' >/dev/null
  echo "$output" | jq -e '.globalIndex.trend' >/dev/null
}

@test "--json version matches script VERSION" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  version=$(echo "$output" | jq -r '.version')
  [ "$version" = "1.0.0" ]
}

# ── NO_COLOR ─────────────────────────────────────────

@test "NO_COLOR output contains no ANSI escape sequences" {
  run env NO_COLOR=1 "$AST"
  [ "$status" -eq 0 ]
  ! printf '%s' "$output" | grep -q $'\033'
}

@test "NO_COLOR output still contains section headers" {
  run env NO_COLOR=1 "$AST"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Claude Rankings"* ]]
  [[ "$output" == *"Global AI Index"* ]]
}

# ── Normal Output ────────────────────────────────────

@test "default output contains header with AST" {
  run "$AST"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AST"* ]]
}

@test "default output contains Global AI Index section" {
  run "$AST"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Global AI Index"* ]]
}

@test "default output contains Claude Rankings section" {
  run "$AST"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Claude Rankings"* ]]
}

@test "default output contains Alerts section" {
  run "$AST"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Alerts"* ]]
}

@test "default output contains box drawing characters" {
  run "$AST"
  [ "$status" -eq 0 ]
  [[ "$output" == *"╭"* ]]
  [[ "$output" == *"╰"* ]]
}
