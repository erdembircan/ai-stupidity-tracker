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

@test "--json preserves the excellent status verbatim" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  count=$(echo "$output" | jq '[.rankings[] | select(.status == "excellent")] | length')
  [ "$count" -eq 2 ]
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

@test "NO_COLOR keeps the excellent star without escapes" {
  run env NO_COLOR=1 "$AST" --section=rankings
  [ "$status" -eq 0 ]
  [[ "$output" == *"★ EXCELLENT"* ]]
  ! printf '%s' "$output" | grep -q $'\033'
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

@test "rankings render excellent models with a filled star" {
  run "$AST" --section=rankings
  [ "$status" -eq 0 ]
  [[ "$output" == *"★ EXCELLENT"* ]]
}

@test "excellent status renders in gold" {
  run "$AST" --section=rankings
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\033[38;5;220m★ EXCELLENT'* ]]
}

@test "--section=coder shows only best coder" {
  run "$AST" --section=coder
  [ "$status" -eq 0 ]
  [[ "$output" == *"Best Coder"* ]]
  [[ "$output" == *"claude-opus-4-8"* ]]
  [[ "$output" == *"90.2"* ]]
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

@test "global index good-models list includes excellent models" {
  run "$AST" --section=global
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude-opus-5"* ]]
}

@test "default output shows all sections" {
  run "$AST"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Global AI Index"* ]]
  [[ "$output" == *"Rankings"* ]]
  [[ "$output" == *"Alerts"* ]]
}

# ── Best Coder ──────────────────────────────────────

@test "--section=coder shows the 7-axis breakdown row" {
  run "$AST" --section=coder
  [ "$status" -eq 0 ]
  [[ "$output" == *"Correctness 96%  Spec 90%  Quality 84%"* ]]
  [[ "$output" != *"Complexity"* ]]
}

@test "--json bestCoder reflects the 7-axis score and fields" {
  run "$AST" --json
  [ "$status" -eq 0 ]
  name=$(echo "$output" | jq -r '.bestCoder.name')
  score=$(echo "$output" | jq -r '.bestCoder.score')
  correctness=$(echo "$output" | jq -r '.bestCoder.correctness')
  spec=$(echo "$output" | jq -r '.bestCoder.spec')
  codeQuality=$(echo "$output" | jq -r '.bestCoder.codeQuality')
  [ "$name" = "claude-opus-4-8" ]
  [ "$score" = "90.2" ]
  [ "$correctness" = "96" ]
  [ "$spec" = "90" ]
  [ "$codeQuality" = "84" ]
  has_complexity=$(echo "$output" | jq '.bestCoder | has("complexity")')
  [ "$has_complexity" = "false" ]
}

@test "fetch_coding_scores scores the 7-axis hourly data and skips models missing an axis" {
  run bash -c '
    PROVIDER=anthropic
    source "'"$AST"'"
    fetch_coding_scores "$(cat "'"$DIR"'/test/fixtures/dashboard.json")"
  '
  [ "$status" -eq 0 ]
  first_line=$(printf '%s\n' "$output" | sed -n '1p')
  second_line=$(printf '%s\n' "$output" | sed -n '2p')
  [[ "$first_line" == "90.2|claude-opus-4-8|"* ]]
  [[ "$second_line" == "83.5|claude-opus-5|"* ]]
  [[ "$output" != *"claude-sonnet-4-20250514"* ]]
  remaining=$(printf '%s\n' "$output" | tail -n +3)
  not_default=$(printf '%s\n' "$remaining" | grep -cv '^73\.5|' || true)
  [ "$not_default" -eq 0 ]
}

@test "calc_coding_score computes the linear weighted sum of the 7 axes" {
  run bash -c '
    source "'"$AST"'"
    calc_coding_score 1 1 1 1 1 1 1
  '
  [ "$status" -eq 0 ]
  [ "$output" = "100.0" ]

  run bash -c '
    source "'"$AST"'"
    calc_coding_score 0 0 0 0 0 0 0
  '
  [ "$status" -eq 0 ]
  [ "$output" = "0.0" ]

  run bash -c '
    source "'"$AST"'"
    calc_coding_score 0.96 0.90 0.84 0.80 0.90 1.0 0.70
  '
  [ "$status" -eq 0 ]
  [ "$output" = "90.2" ]
}

@test "--openai --section=coder scores from the default hourly fixture" {
  run "$AST" --openai --section=coder
  [ "$status" -eq 0 ]
  [[ "$output" == *"Best Coder (OpenAI)"* ]]
  [[ "$output" == *"73.5"* ]]
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

@test "retry delay ramps up linearly instead of staying flat" {
  export AST_CURL_FAIL=1 AST_RETRY_INTERVAL=3 AST_MAX_RETRIES=3
  run bash -c '"$0" 2>&1' "$AST"
  [ "$status" -eq 1 ]
  # ceil(3*N/3) => 1s, 2s, 3s
  [[ "$output" == *"retry 1/3 (1s)"* ]]
  [[ "$output" == *"retry 2/3 (2s)"* ]]
  [[ "$output" == *"retry 3/3 (3s)"* ]]
  # A flat interval would have started the first retry at the full 3s
  [[ "$output" != *"retry 1/3 (3s)"* ]]
}

@test "give-up message reports actual time waited" {
  export AST_CURL_FAIL=1 AST_RETRY_INTERVAL=2 AST_MAX_RETRIES=2
  run bash -c '"$0" 2>&1' "$AST"
  [ "$status" -eq 1 ]
  # ceil(2*1/2)=1 plus ceil(2*2/2)=2 => 3s total
  [[ "$output" == *"API unreachable after 2 retries (3s)"* ]]
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

# ── Model Switcher ─────────────────────────────────

@test "provider_model_rows lists only anthropic selectable models" {
  run bash -c '
    PROVIDER=anthropic
    source "'"$AST"'"
    provider_model_rows "$(cat "'"$DIR"'/test/fixtures/dashboard.json")" | cut -f1
  '
  [ "$status" -eq 0 ]
  # 8 selectable anthropic models in the fixture
  [ "$(printf '%s\n' "$output" | grep -c .)" -eq 8 ]
  # all are claude
  [ "$(printf '%s\n' "$output" | grep -cv claude)" -eq 0 ]
  # the unavailable model is excluded
  [[ "$output" != *"claude-opus-4-7"* ]]
}

@test "provider_model_rows excludes unavailable models and emits score+status" {
  run bash -c '
    PROVIDER=anthropic
    source "'"$AST"'"
    provider_model_rows "$(cat "'"$DIR"'/test/fixtures/dashboard.json")"
  '
  [ "$status" -eq 0 ]
  # tab-separated name<TAB>score<TAB>status — check a known row
  [[ "$output" == *$'claude-opus-5\t82\texcellent'* ]]
}

@test "provider_model_rows respects provider selection" {
  run bash -c '
    PROVIDER=openai
    source "'"$AST"'"
    provider_model_rows "$(cat "'"$DIR"'/test/fixtures/dashboard.json")" | cut -f1
  '
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | grep -cv gpt)" -eq 0 ]
}

@test "provider_model_rows sorts models alphabetically by name" {
  run bash -c '
    PROVIDER=anthropic
    source "'"$AST"'"
    provider_model_rows "$(cat "'"$DIR"'/test/fixtures/dashboard.json")" | cut -f1
  '
  [ "$status" -eq 0 ]
  sorted=$(printf '%s\n' "$output" | LC_ALL=C sort)
  [ "$output" = "$sorted" ]
}

@test "apply_model_selection repoints graph and resets graph data" {
  run bash -c '
    source "'"$AST"'"
    GRAPH_MODEL="claude-opus-5"
    GRAPH_DATA="10:00@80 10:01@81"
    TRACK_MODEL=""
    apply_model_selection "claude-sonnet-4-6"
    echo "$GRAPH_MODEL|$GRAPH_DATA"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "claude-sonnet-4-6|" ]
}

@test "apply_model_selection keeps graph history when model unchanged" {
  run bash -c '
    source "'"$AST"'"
    GRAPH_MODEL="claude-opus-5"
    GRAPH_DATA="10:00@80 10:01@81"
    apply_model_selection "claude-opus-5"
    echo "$GRAPH_MODEL|$GRAPH_DATA"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "claude-opus-5|10:00@80 10:01@81" ]
}

@test "apply_model_selection repoints track target" {
  run bash -c '
    source "'"$AST"'"
    GRAPH_MODEL=""
    TRACK_MODEL="claude-opus-5"
    apply_model_selection "claude-sonnet-4-6"
    echo "$TRACK_MODEL"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "claude-sonnet-4-6" ]
}

@test "picker_busy_start with a selection announces the switch" {
  run bash -c '
    source "'"$AST"'"
    picker_busy_start "claude-sonnet-4-6" 2>"'"$BATS_TEST_TMPDIR"'/spinner.out"
    sleep 0.2
    spinner_stop 2>/dev/null
    cat "'"$BATS_TEST_TMPDIR"'/spinner.out"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Switching to claude-sonnet-4-6"* ]]
}

@test "picker_busy_start with no selection announces a refresh" {
  run bash -c '
    source "'"$AST"'"
    picker_busy_start "" 2>"'"$BATS_TEST_TMPDIR"'/spinner.out"
    sleep 0.2
    spinner_stop 2>/dev/null
    cat "'"$BATS_TEST_TMPDIR"'/spinner.out"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"Refreshing"* ]]
}

@test "picker_busy_start clears the stale picker frame" {
  run bash -c '
    source "'"$AST"'"
    picker_busy_start "" 2>/dev/null
    spinner_stop 2>/dev/null
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\033[2J\033[H'* ]]
}

@test "sourcing ast does not run main" {
  run bash -c 'source "'"$AST"'"; echo SOURCED_OK'
  [ "$status" -eq 0 ]
  [ "$output" = "SOURCED_OK" ]
}

# ── Switch Suggestion ──────────────────────────────

@test "switch suggestion: top-tier tracked model keeps" {
  run "$AST" --track=claude-opus-4-8
  [ "$status" -eq 0 ]
  [[ "$output" == *"Switch Suggestion"* ]]
  [[ "$output" == *"KEEP"* ]]
  [[ "$output" == *"Tier 80 matches the top tier"* ]]
}

@test "switch suggestion: top-tier model keeps even when another top-tier model scores higher" {
  run "$AST" --track=claude-opus-5
  [ "$status" -eq 0 ]
  [[ "$output" == *"KEEP"* ]]
}

@test "switch suggestion: below-top-tier tracked model switches to the top-tier target" {
  run "$AST" --track=claude-sonnet-4-6
  [ "$status" -eq 0 ]
  [[ "$output" == *"SWITCH"* ]]
  [[ "$output" == *"claude-opus-5"* ]]
  [[ "$output" == *"(tier 80, score 82)"* ]]
  [[ "$output" == *"Tracked tier 71 · top tier 80"* ]]
  [[ "$output" != *"KEEP"* ]]
}

@test "switch suggestion: missing tier data is UNKNOWN" {
  run "$AST" --track=claude-opus-4-7
  [ "$status" -eq 0 ]
  [[ "$output" == *"UNKNOWN"* ]]
  [[ "$output" == *"No tier data for this model"* ]]
}

@test "switch suggestion: unmatched track name is NOT FOUND" {
  run "$AST" --track=no-such-model
  [ "$status" -eq 0 ]
  [[ "$output" == *"NOT FOUND"* ]]
  [[ "$output" == *"No Claude model matches the tracked name"* ]]
}

@test "switch suggestion: failed tier fetch is UNAVAILABLE" {
  export AST_CURL_FAIL_MODELS=1
  run "$AST" --track=claude-opus-4-8
  [ "$status" -eq 0 ]
  [[ "$output" == *"UNAVAILABLE"* ]]
  [[ "$output" == *"Could not fetch tier data"* ]]
}

@test "switch suggestion: hidden without --track" {
  run "$AST"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Switch Suggestion"* ]]
}

@test "switch suggestion: shown regardless of --section, section filter still applies" {
  run "$AST" --section=rankings --track=claude-opus-4-8
  [ "$status" -eq 0 ]
  [[ "$output" == *"Switch Suggestion"* ]]
  [[ "$output" == *"Claude Rankings"* ]]
  [[ "$output" != *"Global AI Index"* ]]
}

@test "switch suggestion: is not a valid section" {
  run "$AST" --section=switch
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown section: switch"* ]]
}

@test "switch suggestion: --openai score tie-break picks the higher-scoring top-tier model" {
  run "$AST" --openai --track=gpt-5.3-codex
  [ "$status" -eq 0 ]
  [[ "$output" == *"SWITCH"* ]]
  [[ "$output" == *"gpt-5.4"* ]]
}

@test "switch suggestion: --openai top-tier tracked model keeps" {
  run "$AST" --openai --track=gpt-5.2
  [ "$status" -eq 0 ]
  [[ "$output" == *"KEEP"* ]]
}

@test "switch suggestion: NO_COLOR output has no ANSI escapes" {
  run env NO_COLOR=1 "$AST" --track=claude-opus-4-8
  [ "$status" -eq 0 ]
  [[ "$output" == *"Switch Suggestion"* ]]
  ! printf '%s' "$output" | grep -q $'\033'
}

@test "switch suggestion: box renders before Global AI Index" {
  run "$AST" --track=claude-opus-4-8
  [ "$status" -eq 0 ]
  switch_line=$(printf '%s\n' "$output" | awk '/Switch Suggestion/ { print NR; exit }')
  global_line=$(printf '%s\n' "$output" | awk '/Global AI Index/ { print NR; exit }')
  [ -n "$switch_line" ]
  [ -n "$global_line" ]
  [ "$switch_line" -lt "$global_line" ]
}

@test "compute_switch_suggestion: switches to the higher-scoring top-tier candidate" {
  run bash -c '
    source "'"$AST"'"
    rows=$(printf "a\t1\t70\tgood\t80\nb\t2\t75\tgood\t80\nc\t3\t60\tgood\t79\n")
    compute_switch_suggestion "$rows" "c"
  '
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r verdict tracked tracked_tier top_tier target target_score target_tier <<<"$output"
  [ "$verdict" = "SWITCH" ]
  [ "$target" = "b" ]
  [ "$top_tier" = "80" ]
}

@test "compute_switch_suggestion: top-tier tracked model keeps even though another scores higher" {
  run bash -c '
    source "'"$AST"'"
    rows=$(printf "a\t1\t70\tgood\t80\nb\t2\t75\tgood\t80\nc\t3\t60\tgood\t79\n")
    compute_switch_suggestion "$rows" "a"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "KEEP"* ]]
}

@test "compute_switch_suggestion: no tiered candidates is UNAVAILABLE" {
  run bash -c '
    source "'"$AST"'"
    rows=$(printf "a\t1\t70\tgood\t\nb\t2\t75\tgood\t\n")
    compute_switch_suggestion "$rows" "a"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "UNAVAILABLE"* ]]
}

@test "compute_switch_suggestion: resolves the tracked model by substring, first match wins" {
  run bash -c '
    source "'"$AST"'"
    rows=$(printf "claude-opus-5\t1\t70\tgood\t80\nclaude-opus-4-8\t2\t75\tgood\t80\n")
    compute_switch_suggestion "$rows" "claude-opus"
  '
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r verdict tracked _ <<<"$output"
  [ "$tracked" = "claude-opus-5" ]
}

@test "--json --track output is unchanged (no switchSuggestion key)" {
  run "$AST" --json --track=claude-opus-4-8
  [ "$status" -eq 0 ]
  echo "$output" | jq empty
  [ "$(echo "$output" | jq -e 'has("switchSuggestion")')" = "false" ]
}
