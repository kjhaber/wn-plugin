#!/usr/bin/env bash
# tests/test-session-start.sh
# Tests for the session ID recording behavior in session-start.sh

set -euo pipefail

PASS=0
FAIL=0
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/session-start.sh"

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; echo "    $2"; FAIL=$((FAIL + 1)); }

assert_file_contains() {
  local label="$1" file="$2" pattern="$3"
  if [ -f "$file" ] && grep -qF "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label" "pattern '$pattern' not found in ${file:-<missing file>}"
  fi
}

assert_file_not_exists() {
  local label="$1" file="$2"
  if [ ! -f "$file" ]; then
    pass "$label"
  else
    fail "$label" "file '$file' exists but should not"
  fi
}

assert_exit_zero() {
  local label="$1" exit_code="$2"
  if [ "$exit_code" -eq 0 ]; then
    pass "$label"
  else
    fail "$label" "expected exit code 0, got $exit_code"
  fi
}

# Create a temp dir with a mock wn that logs note-add calls.
# $1: item_id to return from 'wn show --json' (empty = no current item)
make_mock_dir() {
  local item_id="$1"
  local tmpdir
  tmpdir=$(mktemp -d)
  local note_log="$tmpdir/note_calls.txt"

  # Use a quoted heredoc so we control which variables expand now vs. at runtime.
  # Variables we want expanded NOW: $item_id, $note_log
  # Variables that must stay as shell vars in the script: $1, $2, $@
  cat > "$tmpdir/wn" << ENDMOCK
#!/usr/bin/env bash
_ITEM_ID="$item_id"
_NOTE_LOG="$note_log"
if [ "\$1" = "show" ] && [ "\$2" = "--json" ]; then
  if [ -n "\$_ITEM_ID" ]; then
    printf '{"id":"%s","description":"test item"}\n' "\$_ITEM_ID"
    exit 0
  else
    echo "no current item" >&2
    exit 1
  fi
elif [ "\$1" = "note" ] && [ "\$2" = "add" ]; then
  printf '%s\n' "\$@" >> "\$_NOTE_LOG"
  exit 0
fi
exit 0
ENDMOCK
  chmod +x "$tmpdir/wn"
  echo "$tmpdir"
}

# Run session-start.sh with controlled env:
#   $1: mock bin dir (prepended to PATH; /usr/bin:/bin appended so jq is found)
#   $2: stdin JSON string
run_script() {
  local mock_dir="$1" stdin_json="$2"
  EXIT_CODE=0
  PATH="$mock_dir:/usr/bin:/usr/local/bin:/opt/homebrew/bin:/bin" \
    CLAUDE_PLUGIN_ROOT="" \
    CLAUDE_PLUGIN_DATA="" \
    bash "$SCRIPT" <<< "$stdin_json" 2>/dev/null || EXIT_CODE=$?
}

# ---------------------------------------------------------------------------
echo "=== session-start.sh: session ID recording ==="

echo ""
echo "-- Test 1: session_id present + current item → note added with correct fields --"
M1=$(make_mock_dir "fea001")
run_script "$M1" '{"session_id":"test-session-abc123","transcript_path":"/tmp/t.jsonl"}'
assert_file_contains "note add was called"            "$M1/note_calls.txt" "coding-session"
assert_file_contains "note targets correct item"      "$M1/note_calls.txt" "fea001"
assert_file_contains "note body contains session-id"  "$M1/note_calls.txt" "test-session-abc123"
assert_file_contains "note body contains harness name" "$M1/note_calls.txt" "claude"
rm -rf "$M1"

echo ""
echo "-- Test 2: session_id present but no current item → note add NOT called --"
M2=$(make_mock_dir "")
run_script "$M2" '{"session_id":"test-session-abc123","transcript_path":"/tmp/t.jsonl"}'
assert_file_not_exists "note add was not called" "$M2/note_calls.txt"
rm -rf "$M2"

echo ""
echo "-- Test 3: stdin has no session_id field → note add NOT called --"
M3=$(make_mock_dir "fea002")
run_script "$M3" '{"transcript_path":"/tmp/t.jsonl"}'
assert_file_not_exists "note add was not called" "$M3/note_calls.txt"
rm -rf "$M3"

echo ""
echo "-- Test 4: empty stdin → no crash, note add NOT called --"
M4=$(make_mock_dir "fea003")
run_script "$M4" ''
assert_exit_zero "exits cleanly" "$EXIT_CODE"
assert_file_not_exists "note add was not called" "$M4/note_calls.txt"
rm -rf "$M4"

echo ""
echo "-- Test 5: wn not in PATH → exits cleanly, no crash --"
M5=$(mktemp -d)  # empty dir — no wn binary
run_script "$M5" '{"session_id":"test-session-abc123"}'
assert_exit_zero "exits cleanly when wn absent" "$EXIT_CODE"
rm -rf "$M5"

# ---------------------------------------------------------------------------
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
