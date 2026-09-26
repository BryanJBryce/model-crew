#!/usr/bin/env bash
# Session bookkeeping for Claude subscription work. Requires Bash, jq, uuidgen.
# jq programs passed through update_state intentionally use literal dollar signs.
# shellcheck disable=SC2016
set -euo pipefail
umask 077

die() { printf 'model-crew: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'USAGE'
Usage: claude.sh start WORKSTREAM PROMPT
       claude.sh followup WORKSTREAM PROMPT
       claude.sh fork WORKSTREAM NEW_WORKSTREAM PROMPT
       claude.sh status [WORKSTREAM]
       claude.sh end WORKSTREAM
Use PROMPT "-" to read stdin verbatim. Run from the target repository/worktree.
USAGE
}
now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
valid_name() { [[ "$1" =~ ^[a-z0-9][a-z0-9_-]{0,79}$ ]] || die "Invalid workstream name: $1"; }
command -v jq >/dev/null || die "jq is required."
op=${1:-}
case "$op" in
  -h|--help|help) usage; exit 0 ;;
  start|followup) [[ $# == 3 ]] || { usage >&2; exit 2; } ;;
  fork) [[ $# == 4 ]] || { usage >&2; exit 2; } ;;
  status) [[ $# == 1 || $# == 2 ]] || { usage >&2; exit 2; } ;;
  end) [[ $# == 2 ]] || { usage >&2; exit 2; } ;;
  *) usage >&2; exit 2 ;;
esac
if repo=$(git rev-parse --show-toplevel 2>/dev/null); then
  repo=$(cd "$repo" && pwd -P)
else
  repo=$(pwd -P)
fi
root="$repo/.model-crew"
ws=${2:-}
[[ -z "$ws" ]] || valid_name "$ws"
state=""
child=""
running=0
locks=()

# Atomic updates never truncate a valid state file in place.
update_state() {
  local tmp
  tmp=$(mktemp "$state.tmp.XXXXXX")
  if jq "$@" "$state" > "$tmp"; then mv "$tmp" "$state"
  else rm -f "$tmp"; return 1; fi
}
cleanup() {
  local rc=$? lock
  trap - EXIT
  if [[ "$running" == 1 && -f "$state" ]]; then
    update_state --arg t "$(now)" '.status="interrupted" | .finished_at=$t' || true
  fi
  for lock in "${locks[@]-}"; do
    [[ -n "$lock" ]] || continue
    rm -f "$lock/pid"
    rmdir "$lock" 2>/dev/null || true
  done
  exit "$rc"
}
interrupt() {
  if [[ -n "$child" ]]; then
    kill -TERM "$child" 2>/dev/null || true
    wait "$child" 2>/dev/null || true
  fi
  exit "$1"
}
trap cleanup EXIT
trap 'interrupt 130' INT
trap 'interrupt 143' TERM
lock_stream() {
  local lock="$root/.locks/$1"
  if ! mkdir "$lock" 2>/dev/null; then
    die "Workstream $1 is locked. Inspect $lock/pid and the recorded child PID; do not steal a live lock."
  fi
  locks+=("$lock")
  printf '%s\n' "$$" > "$lock/pid"
}
check_state() {
  local f="$1"
  [[ -f "$f" ]] || die "Missing session. Use start with a summary and a new workstream name."
  jq -es --arg repo "$repo" 'length == 1 and (.[0] |
    .schema == 1 and .repository == $repo and
    (.session_id | type == "string" and length > 0) and
    (.working_directory | type == "string") and
    (.settings.model | type == "string") and .status != "ended")
  ' "$f" >/dev/null || die "Session is ended, incomplete, or belongs elsewhere; inspect $f. No replacement was started."
}
show_status() {
  local files=() f name pid="" alive=false locked=false
  if [[ -n "$ws" ]]; then
    [[ -f "$root/$ws/sessions.json" ]] || die "Missing workstream: $ws"
    files+=("$root/$ws/sessions.json")
  else
    for f in "$root"/*/sessions.json; do [[ ! -f "$f" ]] || files+=("$f"); done
  fi
  {
    for f in "${files[@]-}"; do
      [[ -n "$f" ]] || continue
      name=$(basename "$(dirname "$f")")
      alive=false; locked=false; pid=""
      if [[ -d "$root/.locks/$name" ]]; then
        locked=true
        [[ ! -f "$root/.locks/$name/pid" ]] || pid=$(cat "$root/.locks/$name/pid")
        if [[ "$pid" =~ ^[1-9][0-9]*$ ]] && kill -0 "$pid" 2>/dev/null; then alive=true; fi
      fi
      jq --arg pid "$pid" --argjson alive "$alive" --argjson locked "$locked" '
        . + {lock_present:$locked, lock_owner_pid:$pid, lock_owner_alive:$alive,
             api_equivalent_cost_scope:"reported_session_total_may_include_history",
             cache_expiry_estimate:null}
      ' "$f"
    done
  } | jq -s .
}
if [[ "$op" == status ]]; then show_status; exit 0; fi
mkdir -p "$root/.locks"
if [[ ! -f "$root/.gitignore" ]]; then printf '*\n' > "$root/.gitignore"; fi
lock_stream "$ws"
state="$root/$ws/sessions.json"
if [[ "$op" == end ]]; then
  [[ -f "$state" ]] || die "Missing workstream: $ws"
  update_state --arg t "$(now)" '.status="ended" | .ended_at=$t'
  jq . "$state"
  exit 0
fi

bin=${MODEL_CREW_CLAUDE_BIN:-claude}
command -v "$bin" >/dev/null || die "Claude CLI not found: $bin"
for var in ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY; do
  [[ -z "${!var:-}" ]] || die "$var is set; refusing a possible subscription-to-API/provider billing change."
done
help=$("$bin" --help)
for flag in --print --output-format --model --session-id --resume --fork-session --permission-prompts; do
  [[ "$help" == *"$flag"* ]] || die "Installed Claude help does not confirm $flag."
done
auth=$("$bin" auth status) || die "Cannot confirm Claude subscription authentication."
jq -es 'length == 1 and (.[0] | .loggedIn == true and .authMethod == "claude.ai" and .apiProvider == "firstParty")' <<<"$auth" >/dev/null ||
  die "Expected Claude subscription authentication. No API fallback was attempted."
version=$("$bin" --version)
source_id=""
expected_id=""
if [[ "$op" == start ]]; then
  [[ ! -e "$state" ]] || die "Workstream exists; use followup or choose a new name."
  command -v uuidgen >/dev/null || die "uuidgen is required."
  expected_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
  settings=$(jq -n --arg model "${MODEL_CREW_MODEL:-claude-opus-5-5}" \
    --arg effort "${MODEL_CREW_EFFORT:-}" --arg permission "${MODEL_CREW_PERMISSION_MODE:-}" \
    --arg tools "${MODEL_CREW_DISABLE_TOOLS:-0}" \
    '{model:$model, effort_override:$effort, permission_mode_override:$permission, disable_tools:($tools=="1")}')
  workdir=$(pwd -P)
else
  check_state "$state"
  source_id=$(jq -r .session_id "$state")
  settings=$(jq -c .settings "$state")
  workdir=$(jq -r .working_directory "$state")
  [[ -d "$workdir" ]] || die "Saved working directory is missing: $workdir"
  expected_id="$source_id"
fi
if [[ "$op" == fork ]]; then
  new_ws="$3"
  valid_name "$new_ws"
  [[ "$new_ws" != "$ws" ]] || die "Fork destination must be a different workstream."
  lock_stream "$new_ws"
  state="$root/$new_ws/sessions.json"
  [[ ! -e "$state" ]] || die "Fork destination already exists: $new_ws"
  ws="$new_ws"
  command -v uuidgen >/dev/null || die "uuidgen is required."
  expected_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
  prompt="$4"
else
  prompt="$3"
fi
model=$(jq -r .model <<<"$settings")
effort=$(jq -r .effort_override <<<"$settings")
permission=$(jq -r .permission_mode_override <<<"$settings")
case "$effort" in ""|low|medium|high|xhigh|max) ;; *) die "Unsupported effort: $effort" ;; esac
case "$permission" in ""|manual|acceptEdits|auto|dontAsk|plan) ;; *) die "Unsupported permission mode: $permission" ;; esac
args=(--print --output-format json --model "$model" --permission-prompts none)
if [[ -n "$effort" ]]; then
  [[ "$help" == *"--effort"* ]] || die "Installed Claude help does not confirm --effort."
  args+=(--effort "$effort")
fi
if [[ -n "$permission" ]]; then
  [[ "$help" == *"--permission-mode"* ]] || die "Installed Claude help does not confirm --permission-mode."
  args+=(--permission-mode "$permission")
fi
if [[ $(jq -r .disable_tools <<<"$settings") == true ]]; then
  for flag in --tools --strict-mcp-config --mcp-config; do
    [[ "$help" == *"$flag"* ]] || die "Installed Claude help does not confirm $flag."
  done
  args+=(--tools "" --strict-mcp-config --mcp-config '{"mcpServers":{}}')
fi
case "$op" in
  start) args+=(--session-id "$expected_id") ;;
  followup) args+=(--resume "$source_id") ;;
  fork) args+=(--resume "$source_id" --fork-session --session-id "$expected_id") ;;
esac
mkdir -p "$root/$ws/runs"
run=$(mktemp -d "$root/$ws/runs/$(date -u '+%Y%m%dT%H%M%SZ').XXXXXX")
if [[ "$prompt" == "-" ]]; then cat > "$run/prompt.txt"
else printf '%s' "$prompt" > "$run/prompt.txt"; fi
[[ -s "$run/prompt.txt" ]] || die "Prompt is empty."
started=$(now)
if [[ "$op" != followup ]]; then
  tmp=$(mktemp "$state.tmp.XXXXXX")
  jq -n --arg ws "$ws" --arg repo "$repo" --arg wd "$workdir" \
    --arg id "$expected_id" --arg source "$source_id" --arg t "$started" --argjson settings "$settings" \
    '{schema:1,workstream:$ws,repository:$repo,working_directory:$wd,
      session_id:(if $id=="" then null else $id end),
      forked_from:(if $source=="" then null else $source end),
      created_at:$t,settings:$settings}' > "$tmp"
  mv "$tmp" "$state"
fi
update_state --arg t "$started" --arg op "$op" --arg run "$run" \
  --arg version "$version" --argjson pid "$$" '
  .status="running" | .last_operation=$op | .started_at=$t | .last_run=$run |
  .cli_version=$version | .wrapper_pid=$pid | .child_pid=null |
  .finished_at=null | .exit_code=null | .last_usage=null |
  .last_model_usage=null | .api_equivalent_cost_usd=null |
  .api_equivalent_cost_scope="reported_session_total_may_include_history" |
  .permission_denials=null | .reported_session_id=null | .error=null'
running=1
(
  cd "$workdir"
  exec "$bin" "${args[@]}" < "$run/prompt.txt"
) > "$run/result.json" 2> "$run/stderr.log" &
child=$!
update_state --argjson pid "$child" '.child_pid=$pid'
rc=0
wait "$child" || rc=$?
child=""
result_valid=false
if jq -es 'length==1 and (.[0] | type=="object" and .type=="result" and (.session_id|type=="string" and length>0))' \
  "$run/result.json" >/dev/null 2>&1; then result_valid=true; fi
outcome=failed
error="CLI did not return a valid result; inspect the retained logs. No replacement session was started."
if [[ "$result_valid" == true ]]; then
  reported=$(jq -r .session_id "$run/result.json")
  identity_ok=false
  if [[ "$reported" == "$expected_id" && ( "$op" != fork || "$reported" != "$source_id" ) ]]; then identity_ok=true; fi
  if [[ "$identity_ok" == true ]]; then
    update_state --arg id "$reported" '.session_id=$id'
    if [[ "$rc" == 0 ]] && jq -e '.is_error == false and .subtype == "success"' "$run/result.json" >/dev/null; then
      outcome=ready
      error=""
    else
      error="Claude returned an error or incomplete result. Inspect the result before deliberately resuming this ID."
    fi
  else
    error="Returned session ID did not match the requested operation. Inspect the evidence before recovery."
  fi
  update_state --slurpfile result "$run/result.json" '
    .reported_session_id=$result[0].session_id |
    .last_usage=($result[0].usage // null) |
    .last_model_usage=($result[0].modelUsage // null) |
    .api_equivalent_cost_usd=($result[0].total_cost_usd // null) |
    .permission_denials=($result[0].permission_denials // [])'
fi
update_state --arg t "$(now)" --arg status "$outcome" --arg error "$error" --argjson rc "$rc" '
  .finished_at=$t | .status=$status | .exit_code=$rc |
  .error=(if $error=="" then null else $error end)'
running=0
jq -c '{workstream,last_operation,status,session_id,started_at,finished_at,
  last_run,last_usage,api_equivalent_cost_usd,api_equivalent_cost_scope,exit_code,error}' "$state" >> "$root/$ws/events.jsonl"
if [[ "$result_valid" == true ]]; then cat "$run/result.json"; fi
if [[ "$outcome" != ready ]]; then
  printf 'model-crew: %s Logs: %s\n' "$error" "$run" >&2
  [[ "$rc" != 0 ]] || rc=1
  exit "$rc"
fi
