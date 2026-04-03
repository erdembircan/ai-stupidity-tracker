#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  AST="$DIR/ast"
  # Use mock curl (test/curl) so tests run offline against fixtures
  if [[ -z "${AST_LIVE:-}" ]]; then
    export PATH="$DIR/test:$PATH"
  fi
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
  echo "$output" | jq -e '.provider' >/dev/null
  echo "$output" | jq -e '.globalIndex' >/dev/null
  echo "$output" | jq -e '.rankings' >/dev/null
  echo "$output" | jq -e '.bestFor' >/dev/null
  echo "$output" | jq -e '.alerts' >/dev/null
  echo "$output" | jq -e '.providerTrust' >/dev/null
  echo "$output" | jq -e '.driftIncidents' >/dev/null
}

@test "--json default provider is anthropic" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  provider=$(echo "$output" | jq -r '.provider')
  [ "$provider" = "anthropic" ]
}

@test "--json rankings contains only anthropic models by default" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  non_claude=$(echo "$output" | jq '[.rankings[] | select(.name | test("claude"; "i") | not)] | length')
  [ "$non_claude" -eq 0 ]
}

@test "--json rankings entries have rank, name, score, status" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  count=$(echo "$output" | jq '.rankings | length')
  if [ "$count" -gt 0 ]; then
    echo "$output" | jq -e '.rankings[0] | .rank and .name and .score and .status' >/dev/null
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
  [ "$version" = "1.0.1" ]
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

@test "default output contains Claude Rankings section header" {
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

# ── --claude Flag ───────────────────────────────────

@test "--claude flag produces Claude Rankings header" {
  run "$AST" --claude
  [ "$status" -eq 0 ]
  [[ "$output" == *"Claude Rankings"* ]]
}

@test "--claude --json sets provider to anthropic" {
  run "$AST" --claude --json
  [ "$status" -eq 0 ]
  provider=$(echo "$output" | jq -r '.provider')
  [ "$provider" = "anthropic" ]
}

# ── --openai Flag ───────────────────────────────────

@test "--openai output contains OpenAI Rankings header" {
  run "$AST" --openai
  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenAI Rankings"* ]]
}

@test "--openai output does not contain Claude Rankings" {
  run "$AST" --openai
  [ "$status" -eq 0 ]
  [[ "$output" != *"Claude Rankings"* ]]
}

@test "--openai output shows OpenAI Provider Trust header" {
  run "$AST" --openai
  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenAI Provider Trust"* ]]
}

@test "--openai --json sets provider to openai" {
  run "$AST" --openai --json
  [ "$status" -eq 0 ]
  provider=$(echo "$output" | jq -r '.provider')
  [ "$provider" = "openai" ]
}

@test "--openai --json produces valid JSON" {
  run "$AST" --openai --json
  [ "$status" -eq 0 ]
  echo "$output" | jq empty
}

@test "--openai --json rankings contain only openai models" {
  run "$AST" --openai --json
  [ "$status" -eq 0 ]
  non_openai=$(echo "$output" | jq '[.rankings[] | select(.name | test("gpt"; "i") | not)] | length')
  [ "$non_openai" -eq 0 ]
}

@test "--openai --json rankings entries have expected fields" {
  run "$AST" --openai --json
  [ "$status" -eq 0 ]
  count=$(echo "$output" | jq '.rankings | length')
  [ "$count" -gt 0 ]
  echo "$output" | jq -e '.rankings[0] | .rank and .name and .score and .status' >/dev/null
}

@test "--openai --json bestFor reflects openai vendor" {
  run "$AST" --openai --json
  [ "$status" -eq 0 ]
  # In the fixture, openai holds bestForCode
  echo "$output" | jq -e '.bestFor.code' >/dev/null
  code_name=$(echo "$output" | jq -r '.bestFor.code.name')
  [[ "$code_name" == gpt* ]]
}

@test "--openai --json providerTrust is populated" {
  run "$AST" --openai --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.providerTrust.score' >/dev/null
}

@test "--openai NO_COLOR output contains OpenAI Rankings" {
  run env NO_COLOR=1 "$AST" --openai
  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenAI Rankings"* ]]
  [[ "$output" == *"OpenAI Provider Trust"* ]]
}

# ── Flag Combinations ──────────────────────────────

@test "last provider flag wins" {
  run "$AST" --claude --openai --json
  [ "$status" -eq 0 ]
  provider=$(echo "$output" | jq -r '.provider')
  [ "$provider" = "openai" ]
}

@test "--openai can combine with --json" {
  run "$AST" --openai --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.rankings' >/dev/null
}
