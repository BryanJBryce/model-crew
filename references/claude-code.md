# Claude sessions

Use `../scripts/claude.sh` from the target repository/worktree. It stores local state under `.model-crew/<workstream>/sessions.json`, with per-call JSON results and stderr under `runs/`. The directory ignores itself in Git. Durable plans belong in the project's canonical records.

The helper uses the installed `claude` command (override with `MODEL_CREW_CLAUDE_BIN` for testing). It checks required flags and subscription authentication before a model call. It refuses environment overrides that could silently route subscription work to API/cloud billing. It does not alter global settings or authentication.

```sh
"$HOME/.codex/skills/model-crew/scripts/claude.sh" start feature-a - < order.txt
"$HOME/.codex/skills/model-crew/scripts/claude.sh" followup feature-a "Fix the reproduced issue and rerun the focused check."
"$HOME/.codex/skills/model-crew/scripts/claude.sh" fork feature-a alternative-a "Explore this bounded alternative."
"$HOME/.codex/skills/model-crew/scripts/claude.sh" status
"$HOME/.codex/skills/model-crew/scripts/claude.sh" end feature-a
```

Workstream names contain lowercase letters, digits, hyphens, and underscores. `-` reads the prompt from stdin verbatim. Otherwise pass one quoted prompt argument. Do not assemble shell code from prompt text.

New sessions default to `claude-opus-5-5`. `MODEL_CREW_MODEL`, `MODEL_CREW_EFFORT`, and `MODEL_CREW_PERMISSION_MODE` explicitly select startup settings. With effort unset, Claude's configured effort is used and recorded as not explicitly overridden; the helper cannot claim to have observed the effective effort. Startup settings are saved for follow-ups/forks; later environment changes do not silently change existing workstreams. The CLI settings it inherits can still change externally.

Permission mode is inherited unless explicitly selected; supported overrides exclude bypassPermissions. `--permission-prompts none` makes a headless call deny actions requiring an interactive decision. Existing allowed actions and the selected permission mode still apply. Record denials and resolve the specific missing authority/configuration instead of enabling a blanket bypass. Set `MODEL_CREW_PERMISSION_MODE=acceptEdits` when file edits are already authorized and that mode is suitable.

`MODEL_CREW_DISABLE_TOOLS=1` starts a no-tools session with an empty strict MCP configuration for conversational smoke tests. This choice persists with that workstream. It is not the normal implementation configuration.

## Continuation and recovery

- `start` allocates and records an explicit UUID before calling Claude. Existing workstreams are never overwritten, including ended ones.
- `followup` resumes only the saved ID and working directory, within the same repository/worktree. It never starts a replacement on failure.
- `fork` copies saved invocation settings, allocates a new UUID before the call, and combines `--resume`, `--fork-session`, and `--session-id`. Both source and destination are locked during the call. After a failed/interrupted fork, inspect retained evidence and confirm whether the allocated ID exists in Claude's session inventory; use `followup` only when that session exists. An allocated ID alone does not prove the fork was created. Do not blindly retry as a new fork.
- Lock contention returns an error immediately. Locks include the owning PID. After an uncatchable process death, inspect the PID and recorded run before manually removing a stale lock; do not steal a live lock. A killed wrapper can leave a child process, so check both recorded PIDs.
- A failed or interrupted run retains its ID and evidence. Read its last result before deliberately using `followup`; session continuity does not imply the previous task completed.
- `end` marks local bookkeeping ended. It preserves session IDs/logs and neither deletes Claude history nor flushes caches. A new workstream uses a new name.
- Do not use `--continue` for parallel jobs. Avoid simultaneous direct CLI activity against a session managed by this helper; its locks coordinate helper invocations, not unrelated programs.

JSON status includes the last observed usage, model usage, permission denials, and result location. `api_equivalent_cost_usd` is Claude's reported cost estimate, not a Max subscription bill. TTL is unknown unless exposed by observed usage; the helper does not provide a fabricated countdown. `running` with no live lock should be investigated as interrupted.

Live resume checks showed that `total_cost_usd` and `modelUsage` can include prior turns, while `usage` describes the latest call. Do not sum the stored reported cost totals across follow-ups or forks. Use per-call token usage with the applicable rates, or a verified cumulative accounting method that excludes inherited history. The helper preserves the raw observations rather than claiming a per-call dollar charge.

## Verified surface

Claude Code 2.1.281 exposes `--print`, `--output-format json`, `--session-id`, `--resume`, `--fork-session`, `--model`, `--effort`, `--permission-mode`, `--permission-prompts`, `--tools`, and `--strict-mcp-config`/`--mcp-config`. The wrapper checks the required surface on use. The model ID is also present in inspected local Opus 5.5 session logs.

`--max-turns` is absent from this installed help and is not used. No warm/keepwarm command or background service is implemented. For cache-specific analysis, read [cache decisions](cache-decisions.md).
