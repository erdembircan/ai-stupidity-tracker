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

@test "--version prints version number" {
  run "$AST" --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-.+)?$ ]]
}

@test "--json version matches --version output" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  json_version=$(echo "$output" | jq -r '.version')
  script_version=$("$AST" --version)
  [ "$json_version" = "$script_version" ]
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

# ── --section Flag ─────────────────────────────────

@test "--section=rankings shows only rankings" {
  run "$AST" --section=rankings
  [ "$status" -eq 0 ]
  [[ "$output" == *"Rankings"* ]]
  [[ "$output" != *"Global AI Index"* ]]
  [[ "$output" != *"Alerts"* ]]
}

@test "--section=coder shows only best coder" {
  run "$AST" --section=coder
  [ "$status" -eq 0 ]
  [[ "$output" == *"Best Coder"* ]]
  [[ "$output" != *"Rankings"* ]]
  [[ "$output" != *"Alerts"* ]]
}

@test "--section=rankings,alerts shows both" {
  run "$AST" --section=rankings,alerts
  [ "$status" -eq 0 ]
  [[ "$output" == *"Rankings"* ]]
  [[ "$output" == *"Alerts"* ]]
  [[ "$output" != *"Global AI Index"* ]]
}

@test "--section with invalid name exits with error" {
  run "$AST" --section=bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown section: bogus"* ]]
}

@test "--section without value exits with error" {
  run "$AST" --section
  [ "$status" -eq 1 ]
  [[ "$output" == *"--section requires a value"* ]]
}

@test "--section=global shows only global index" {
  run "$AST" --section=global
  [ "$status" -eq 0 ]
  [[ "$output" == *"Global AI Index"* ]]
  [[ "$output" != *"Rankings"* ]]
}

@test "default output shows all sections" {
  run "$AST"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Global AI Index"* ]]
  [[ "$output" == *"Rankings"* ]]
  [[ "$output" == *"Alerts"* ]]
}

# ── API Retry ───────────────────────────────────────

@test "retry gives up after max retries with error message" {
  export AST_CURL_FAIL=1 AST_RETRY_INTERVAL=1 AST_MAX_RETRIES=2
  run bash -c '"$0" 2>&1' "$AST"
  [ "$status" -eq 1 ]
  [[ "$output" == *"API unreachable after 2 retries"* ]]
  [[ "$output" == *"Giving up"* ]]
}

@test "retry message shows attempt count" {
  export AST_CURL_FAIL=1 AST_RETRY_INTERVAL=1 AST_MAX_RETRIES=2
  run bash -c '"$0" 2>&1' "$AST"
  [[ "$output" == *"retry 1/2"* ]]
  [[ "$output" == *"retry 2/2"* ]]
}

@test "retry message shows countdown seconds" {
  export AST_CURL_FAIL=1 AST_RETRY_INTERVAL=1 AST_MAX_RETRIES=1
  run bash -c '"$0" 2>&1' "$AST"
  [[ "$output" == *"(1s)"* ]]
}

@test "retry recovers after transient API failure" {
  local fail_file
  fail_file=$(mktemp "${BATS_TMPDIR}/curl_fail.XXXXXX")
  printf '0' >"$fail_file"
  export AST_CURL_FAIL_COUNT=2 AST_CURL_FAIL_FILE="$fail_file"
  export AST_RETRY_INTERVAL=1 AST_MAX_RETRIES=5
  run bash -c '"$0" --section=global 2>&1' "$AST"
  rm -f "$fail_file"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Global AI Index"* ]]
}

@test "retry works with --json mode" {
  export AST_CURL_FAIL=1 AST_RETRY_INTERVAL=1 AST_MAX_RETRIES=2
  run bash -c '"$0" --json 2>&1' "$AST"
  [ "$status" -eq 1 ]
  [[ "$output" == *"API unreachable"* ]]
}

# ── Graph Trimming ─────────────────────────────────

@test "graph start time updates after cap trims old entries" {
  # Simulate the graph trimming logic from watch_loop:
  # BOX_WIDTH=54, so max_samples = 54 - 10 = 44
  # Build GRAPH_DATA with exactly max_samples + 3 entries
  # After trimming, the first 3 entries (10:00, 10:01, 10:02) should be gone
  # and first_time should be 10:03, not 10:00
  local BOX_WIDTH=54
  local max_samples=$((BOX_WIDTH - 10))
  local GRAPH_DATA=""

  # Seed max_samples + 3 entries (timestamps 10:00 through 10:46)
  for i in $(seq 0 $((max_samples + 2))); do
    local ts
    ts=$(printf '10:%02d' "$i")
    local score=$((50 + (i % 10)))
    if [[ -z "$GRAPH_DATA" ]]; then
      GRAPH_DATA="${ts}@${score}"
    else
      GRAPH_DATA="${GRAPH_DATA} ${ts}@${score}"
    fi
  done

  # Apply the same trimming logic as watch_loop
  local -a _gd
  read -ra _gd <<<"$GRAPH_DATA"
  if ((${#_gd[@]} > max_samples)); then
    GRAPH_DATA="${_gd[*]:(-${max_samples})}"
  fi

  # Parse first entry (same as render_graph does)
  local -a entries
  read -ra entries <<<"$GRAPH_DATA"
  local first_time="${entries[0]%%@*}"
  local last_time="${entries[$((${#entries[@]} - 1))]%%@*}"

  # first_time must NOT be 10:00 — it should be 10:03 (4th entry)
  [ "$first_time" != "10:00" ]
  [ "$first_time" != "10:01" ]
  [ "$first_time" != "10:02" ]
  [ "$first_time" = "10:03" ]
  [ "$last_time" = "10:46" ]
  [ "${#entries[@]}" -eq "$max_samples" ]
}
