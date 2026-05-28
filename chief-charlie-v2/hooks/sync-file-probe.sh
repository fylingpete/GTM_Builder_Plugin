#!/usr/bin/env bash
# Chief Charlie sync-file probe hook (PostToolUse — Write|Edit)
#
# This is a PROBE-ONLY version. It does not push anything to a server.
# It logs the full hook payload so we can verify three things in Co-Work:
#   1. PostToolUse hooks declared in a plugin manifest actually fire.
#   2. The payload format matches what we already observed in Conductor
#      (JSON via stdin with tool_input.file_path).
#   3. Plugin env vars CLAUDE_PLUGIN_ROOT and CLAUDE_PLUGIN_DATA are set
#      so the real sync hook can persist its auth token via them.
#
# Once the probe confirms the above, this script is replaced by the real
# sync logic (read auth token, walk up for project.json, PUT to backend).
#
# Failure mode: any error MUST exit 0 silently — never break the user's
# write/edit flow because of a sync hook bug.

set +e
LOG="$HOME/cc_sync_probe.log"
PAYLOAD="$(cat 2>/dev/null || true)"

{
  echo "=== $(date -u +%FT%TZ) ==="
  echo "--- argv (count=$#) ---"
  i=0; for a in "$@"; do echo "  [$i] $a"; i=$((i+1)); done
  echo "--- env: CLAUDE_PLUGIN_*, CLAUDE_PROJECT_DIR, PWD ---"
  echo "  CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT:-<unset>}"
  echo "  CLAUDE_PLUGIN_DATA=${CLAUDE_PLUGIN_DATA:-<unset>}"
  echo "  CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-<unset>}"
  echo "  PWD=${PWD:-<unset>}"
  echo "--- env: full CLAUDE_*, TOOL_*, HOOK_* ---"
  env | grep -E '^(CLAUDE_|TOOL_|HOOK_)' | sort || echo "  (none)"
  echo "--- stdin payload ---"
  echo "$PAYLOAD"
  echo "--- parsed (best-effort) ---"
  if command -v jq >/dev/null 2>&1; then
    echo "  tool_name        : $(printf '%s' "$PAYLOAD" | jq -r '.tool_name // "<missing>"' 2>/dev/null)"
    echo "  tool_input.file_path : $(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // "<missing>"' 2>/dev/null)"
    echo "  cwd (from payload)   : $(printf '%s' "$PAYLOAD" | jq -r '.cwd // "<missing>"' 2>/dev/null)"
  else
    echo "  (jq not installed — skipping parse)"
  fi
  echo "--- walk-up for .chiefcharlie/project.json ---"
  FP="$(printf '%s' "$PAYLOAD" | (command -v jq >/dev/null 2>&1 && jq -r '.tool_input.file_path // empty' 2>/dev/null))"
  if [ -n "$FP" ] && [ -e "$FP" ]; then
    DIR="$(cd "$(dirname "$FP")" 2>/dev/null && pwd || echo /)"
    FOUND=""
    while [ "$DIR" != "/" ] && [ -n "$DIR" ]; do
      if [ -f "$DIR/.chiefcharlie/project.json" ]; then
        FOUND="$DIR/.chiefcharlie/project.json"
        break
      fi
      DIR="$(dirname "$DIR")"
    done
    if [ -n "$FOUND" ]; then
      echo "  found: $FOUND"
    else
      echo "  not found above $FP (this is expected for the probe)"
    fi
  else
    echo "  skipped (no resolvable file_path)"
  fi
  echo "--- end ---"
  echo
} >> "$LOG" 2>&1
chmod 600 "$LOG" 2>/dev/null

# Emit empty hookSpecificOutput so Co-Work knows we ran cleanly.
# (Returning nothing is also OK, but explicit is friendlier in logs.)
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse"
  }
}
EOF
exit 0
