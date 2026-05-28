#!/usr/bin/env bash
# Chief Charlie file sync hook (PostToolUse — Write|Edit)
#
# Reads auth + project config from the user's workspace and PUTs the
# written file to the chiefcharlie backend so it lands in workspace_files.
#
# Setup (one-time, per workspace, done by the init_workspace MCP tool —
# until that tool exists, the user / our test helper creates these manually):
#   <workspace>/.chiefcharlie/auth.json    { "device_token": "..." }
#   <workspace>/.chiefcharlie/project.json { "project_id": "...", "project_name": "..." }
#
# Both files MUST be in .gitignore (we add a .gitignore in the same dir).
#
# Architecture proven by:
#   - rc2: PostToolUse hook fires in Co-Work plugin manifests (async:false)
#   - rc3: payload.tool_input.file_path points to real user workspace,
#          $CLAUDE_PLUGIN_DATA is set+writable, walk-up logic works
#   - Conductor light test: PUT /workspace/files accepts Bearer auth and
#          writes file to DB
#
# All diagnostics go to stderr (captured in session JSONL under
# hook_success.stderr). Grep for "[cc-sync]" in the JSONL to debug.
#
# Failure mode: every error path exits 0 — never break the user's
# write/edit flow because of a sync bug.

set +e
PAYLOAD="$(cat 2>/dev/null || true)"

log() { echo "[cc-sync] $*" >&2; }

BACKEND_URL="${CC_SYNC_BACKEND_URL:-https://api.chiefcharlie.ai}"

# 1. Parse payload
if ! command -v jq >/dev/null 2>&1; then
  log "jq missing — cannot parse payload, skip"
  exit 0
fi

TOOL_NAME="$(printf '%s' "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null)"
FILE_PATH="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

if [ -z "$FILE_PATH" ]; then
  log "no file_path in payload (tool=$TOOL_NAME), skip"
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  log "file does not exist: $FILE_PATH, skip"
  exit 0
fi

# 2. Walk up to find .chiefcharlie/ config dir
DIR="$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd || echo /)"
CC_DIR=""
while [ "$DIR" != "/" ] && [ -n "$DIR" ]; do
  if [ -d "$DIR/.chiefcharlie" ] && [ -f "$DIR/.chiefcharlie/project.json" ]; then
    CC_DIR="$DIR/.chiefcharlie"
    break
  fi
  DIR="$(dirname "$DIR")"
done

if [ -z "$CC_DIR" ]; then
  log "no .chiefcharlie/project.json above $FILE_PATH — workspace not initialized, skip"
  exit 0
fi

# 3. Read auth + project
if [ ! -f "$CC_DIR/auth.json" ]; then
  log "no auth.json in $CC_DIR — run init_workspace first, skip"
  exit 0
fi

TOKEN="$(jq -r '.device_token // empty' "$CC_DIR/auth.json" 2>/dev/null)"
PROJECT_ID="$(jq -r '.project_id // empty' "$CC_DIR/project.json" 2>/dev/null)"

if [ -z "$TOKEN" ] || [ -z "$PROJECT_ID" ]; then
  log "auth.json or project.json incomplete in $CC_DIR, skip"
  exit 0
fi

# 4. Safety: only sync files inside the workspace this CC_DIR belongs to
WORKSPACE_ROOT="$(dirname "$CC_DIR")"
case "$FILE_PATH" in
  "$WORKSPACE_ROOT"/*) ;;  # OK
  *)
    log "file $FILE_PATH is outside workspace $WORKSPACE_ROOT, skip"
    exit 0
    ;;
esac

# 5. Skip our own config files
case "$(basename "$FILE_PATH")" in
  auth.json|project.json)
    case "$FILE_PATH" in
      "$CC_DIR"/*)
        log "skipping our own config file: $(basename "$FILE_PATH")"
        exit 0
        ;;
    esac
    ;;
esac

# 6. Infer file_type from filename
FN="$(basename "$FILE_PATH")"
case "$FN" in
  USER.md|IDENTITY.md|SOUL.md) FILE_TYPE="identity"; PROJECT_ARG="null" ;;
  *.jsonl)                     FILE_TYPE="data"    ; PROJECT_ARG="\"$PROJECT_ID\"" ;;
  *)                           FILE_TYPE="project" ; PROJECT_ARG="\"$PROJECT_ID\"" ;;
esac

# 7. Build payload + PUT
PUT_BODY="$(jq -n \
  --arg name "$FN" \
  --rawfile content "$FILE_PATH" \
  --arg ftype "$FILE_TYPE" \
  --argjson pid "$PROJECT_ARG" \
  '{file_name:$name, content:$content, file_type:$ftype, project_id:$pid}')"

HTTP_CODE="$(curl -sS -o /tmp/cc-sync-resp.$$ -w '%{http_code}' \
  --max-time 4 \
  -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PUT_BODY" \
  "$BACKEND_URL/workspace/files" 2>/dev/null)"
RESP_BODY="$(cat /tmp/cc-sync-resp.$$ 2>/dev/null)"
rm -f /tmp/cc-sync-resp.$$

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  log "synced $FN (tool=$TOOL_NAME, type=$FILE_TYPE, project=$PROJECT_ID, http=$HTTP_CODE)"
else
  log "sync FAILED $FN (tool=$TOOL_NAME, http=$HTTP_CODE) body=${RESP_BODY:0:200}"
fi

# Bonus: log if CC_USERCONFIG_* env vars appear (for future migration to userConfig auth)
USERCONFIG_KEYS="$(env | grep -E '^CC_USERCONFIG_' | cut -d= -f1 | tr '\n' ',' | sed 's/,$//')"
if [ -n "$USERCONFIG_KEYS" ]; then
  log "userConfig env present: $USERCONFIG_KEYS"
fi

# Clean stdout
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse"
  }
}
EOF
exit 0
