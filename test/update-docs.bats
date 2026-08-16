#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$DIR/.github/scripts/update-docs.sh"
  FIXTURES="$DIR/test/fixtures/docs"
  INDEX="$BATS_TEST_TMPDIR/index.html"
  cp "$FIXTURES/index.html" "$INDEX"
}

# ── Rendering ────────────────────────────────────────

@test "exits 0 on the fixture pair" {
  run "$SCRIPT" 2.0.0 "$FIXTURES/CHANGELOG.md" "$INDEX"
  [ "$status" -eq 0 ]
}

@test "output matches expected.html byte-for-byte" {
  "$SCRIPT" 2.0.0 "$FIXTURES/CHANGELOG.md" "$INDEX"
  run diff -u "$FIXTURES/expected.html" "$INDEX"
  [ "$status" -eq 0 ]
}

@test "running it twice produces the same file as running it once" {
  "$SCRIPT" 2.0.0 "$FIXTURES/CHANGELOG.md" "$INDEX"
  cp "$INDEX" "$BATS_TEST_TMPDIR/once.html"
  "$SCRIPT" 2.0.0 "$FIXTURES/CHANGELOG.md" "$INDEX"
  run diff -u "$BATS_TEST_TMPDIR/once.html" "$INDEX"
  [ "$status" -eq 0 ]
}

@test "the version cell is updated" {
  "$SCRIPT" 2.0.0 "$FIXTURES/CHANGELOG.md" "$INDEX"
  run cat "$INDEX"
  [[ "$output" != *"0.0.0"* ]]
  [[ "$output" == *"2.0.0"* ]]
}

@test "rendering the older 1.0.0 section works and yields only its entries" {
  "$SCRIPT" 1.0.0 "$FIXTURES/CHANGELOG.md" "$INDEX"
  run cat "$INDEX"
  [[ "$output" == *"First release"* ]]
  [[ "$output" != *"--flag"* ]]
  [[ "$output" != *"What's new in v2.0.0"* ]]
}

# ── Failure modes ────────────────────────────────────

@test "missing CHANGELOG:START marker exits non-zero and stderr mentions the marker" {
  local broken="$BATS_TEST_TMPDIR/broken.html"
  grep -v 'CHANGELOG:START' "$FIXTURES/index.html" >"$broken"
  run "$SCRIPT" 2.0.0 "$FIXTURES/CHANGELOG.md" "$broken"
  [ "$status" -ne 0 ]
  [[ "$output" == *"CHANGELOG:START"* ]]
}

@test "a version with no section in the changelog exits non-zero and mentions the version" {
  run "$SCRIPT" 9.9.9 "$FIXTURES/CHANGELOG.md" "$INDEX"
  [ "$status" -ne 0 ]
  [[ "$output" == *"9.9.9"* ]]
}

@test "a nonexistent changelog path exits non-zero" {
  run "$SCRIPT" 2.0.0 "$FIXTURES/does-not-exist.md" "$INDEX"
  [ "$status" -ne 0 ]
}

@test "wrong argument count exits non-zero" {
  run "$SCRIPT" 2.0.0 "$FIXTURES/CHANGELOG.md"
  [ "$status" -ne 0 ]
}

# ── Smoke ────────────────────────────────────────────

@test "smoke test against the repo's real CHANGELOG.md" {
  local version
  version="$(grep -m1 '^readonly VERSION=' "$DIR/ast" | sed -E 's/.*"([^"]+)".*/\1/')"
  run "$SCRIPT" "$version" "$DIR/CHANGELOG.md" "$INDEX"
  [ "$status" -eq 0 ]
  grep -q '<li>' "$INDEX"
}
