#!/usr/bin/env bash
# Update the GitHub Pages formula page for a new release.
#
# Usage: update-docs.sh <version> <changelog-md> <index-html>
#
# Rewrites two regions of <index-html>:
#   1. the stable-version cell tagged with <!-- auto-updated by CI -->
#   2. the block between <!-- CHANGELOG:START --> and <!-- CHANGELOG:END -->,
#      regenerated from the <version> section of <changelog-md>
#
# Deterministic and idempotent: same inputs always produce the same output.

set -euo pipefail

REPO_URL="https://github.com/erdembircan/ai-stupidity-tracker"
START_MARKER="<!-- CHANGELOG:START -->"
END_MARKER="<!-- CHANGELOG:END -->"

die() {
  printf 'update-docs: %s\n' "$*" >&2
  exit 1
}

[[ $# -eq 3 ]] || die "usage: update-docs.sh <version> <changelog-md> <index-html>"

VERSION="$1"
CHANGELOG="$2"
INDEX="$3"

[[ -f "$CHANGELOG" ]] || die "changelog not found: $CHANGELOG"
[[ -f "$INDEX" ]] || die "index not found: $INDEX"
grep -qF -- "$START_MARKER" "$INDEX" || die "missing $START_MARKER in $INDEX"
grep -qF -- "$END_MARKER" "$INDEX" || die "missing $END_MARKER in $INDEX"

# ── Inline markdown → HTML ────────────────────────────
inline_html() {
  local line="$1" before rest code after full text url
  line="${line//&/&amp;}"
  line="${line//</&lt;}"
  line="${line//>/&gt;}"
  while [[ "$line" == *'`'*'`'* ]]; do
    before="${line%%\`*}"
    rest="${line#*\`}"
    code="${rest%%\`*}"
    after="${rest#*\`}"
    line="${before}<code>${code}</code>${after}"
  done
  while [[ "$line" =~ \[([^][]*)\]\(([^()]*)\) ]]; do
    full="${BASH_REMATCH[0]}"
    text="${BASH_REMATCH[1]}"
    url="${BASH_REMATCH[2]}"
    line="${line//"$full"/<a href=\"$url\">$text</a>}"
  done
  printf '%s' "$line"
}

# ── Parse the section for $VERSION ────────────────────
LINES=()
release_date=""
found=0
in_section=0
in_list=0
item=""

flush_item() {
  [[ -n "$item" ]] || return 0
  LINES+=("        <li>$(inline_html "$item")</li>")
  item=""
}

close_list() {
  [[ $in_list -eq 1 ]] || return 0
  LINES+=("      </ul>")
  in_list=0
}

while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
  "## ["*)
    if [[ $in_section -eq 1 ]]; then
      break
    fi
    if [[ "$line" == "## [$VERSION]"* ]]; then
      in_section=1
      found=1
      if [[ "$line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        release_date="${BASH_REMATCH[1]}"
      fi
    fi
    ;;
  "### "*)
    [[ $in_section -eq 1 ]] || continue
    flush_item
    close_list
    LINES+=("      <h3 class=\"changelog-kind\">${line#\#\#\# }</h3>")
    ;;
  "- "*)
    [[ $in_section -eq 1 ]] || continue
    flush_item
    if [[ $in_list -eq 0 ]]; then
      LINES+=("      <ul class=\"changelog-list\">")
      in_list=1
    fi
    item="${line#- }"
    ;;
  "")
    [[ $in_section -eq 1 ]] || continue
    flush_item
    ;;
  *)
    [[ $in_section -eq 1 ]] || continue
    if [[ -n "$item" ]]; then
      item+=" ${line#"${line%%[![:space:]]*}"}"
    fi
    ;;
  esac
done <"$CHANGELOG"
flush_item
close_list

[[ $found -eq 1 ]] || die "no section for version $VERSION in $CHANGELOG"
[[ ${#LINES[@]} -gt 0 ]] || die "section for version $VERSION in $CHANGELOG has no entries"

# ── Render ────────────────────────────────────────────
header="      <p class=\"section-label\">What's new in v${VERSION}"
if [[ -n "$release_date" ]]; then
  header+=" <span class=\"changelog-date\">${release_date}</span>"
fi
header+="</p>"

block="$(mktemp)"
out="$(mktemp)"
trap 'rm -f "$block" "$out"' EXIT

{
  printf '%s\n' '    <section class="changelog">'
  printf '%s\n' "$header"
  printf '%s\n' "${LINES[@]}"
  printf '%s\n' "      <p class=\"changelog-more\"><a href=\"${REPO_URL}/blob/master/CHANGELOG.md\">Full changelog</a></p>"
  printf '%s\n' '    </section>'
} >"$block"

awk -v startm="$START_MARKER" -v endm="$END_MARKER" -v blockfile="$block" '
  index($0, startm) {
    print
    while ((getline l < blockfile) > 0) print l
    close(blockfile)
    skip = 1
    next
  }
  index($0, endm) { skip = 0 }
  !skip { print }
' "$INDEX" >"$out"

sed -E "s|(<!-- auto-updated by CI --> <td>)[^<]*(</td>)|\1${VERSION}\2|" "$out" >"$INDEX"
