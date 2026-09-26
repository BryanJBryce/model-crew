---
name: model-crew
description: Coordinate coding work from the current main task when explicitly invoked. Default to Opus implementation, Luna focused reviews, and Astra consequential planning/review; reserve Sol for mechanical work.
---

# Model Crew

Use only when explicitly called. After invocation, keep this workflow active for follow-up work and subsequent tickets in the same task until the user changes it; do not require repeated invocation. Preserve that choice and worker ownership in task handoffs. Optimize for accepted work, including correction and review overhead. Preserve the user's model choices and existing authorization.

**The task where the user invokes Crew is the coordinator. The user chooses its model for the task.** Keep decomposition, dispatch, consolidation, acceptance, and user communication there. Do not spawn a coordinator subagent or create a replacement coordinator task. Delegate bounded investigation, planning, implementation, or review directly to workers. A worker follows its assigned scope and reports back; reading this skill does not make it another coordinator.

**The coordinator does not implement.** Delegate source code, tests, migrations, dependency/lockfile changes, configuration, and implementation documentation, including small fixes and review corrections. There is no tiny-edit or quick-ticket exception; verification, code generation, UI polish, and deployment preparation do not grant an editing exception either. The main task may inspect code/diffs and run verification as the designated gate owner. Record test results, acceptance status, and contributor details directly in project status, handoffs, or execution metadata; do not resume an implementer solely for these updates. Only an explicit user instruction to implement in the main task overrides this boundary. If a worker is unavailable or blocked, repair the delegation or select another worker under the routing rules below; do not silently take over its edits.

Keep ownership clear in updates: name the worker making changes and distinguish its work from the coordinator's checks. A correction such as “you should not be writing code; use your crew” changes who performs the work, not the authorized objective. Continue through the assigned implementer; do not interpret it as cancellation or interrupt the worker without a separate reason.

## Routing

| Role | Default | Use |
| --- | --- | --- |
| Coordinator | Invoking task; model chosen by the user | Break down work, find relevant files and examples, dispatch, consolidate findings, track acceptance. No implementation edits. |
| Targeted reviewer | Luna 6 Medium | Investigate a named concern in a specific diff, subsystem, or behavior; return concrete evidence. |
| Planner and difficult reasoning | Astra Xhigh, Standard | Consequential architecture, ambiguity, interacting risks, difficult diagnosis, and substantive review decisions. Implement only when explicitly assigned by the user. |
| Default implementation owner | Opus 5.5 through Claude Code | Own tickets, feature construction, bug fixes, integration, UI, tests, and related corrections. Use the configured Claude subscription; preserve configured effort rather than forcing Max. |
| Mechanical worker only | Sol 6, Standard | Execute an exact, settled transformation with no remaining behavior or design decisions, such as an approved symbol rename or deterministic codemod. Do not assign integrated tickets to Sol. |
| Conditional specialist | Daybreak Blue, when available to subagents | Security-focused review, vulnerability triage, remediation, and patch validation; also a bounded task the user explicitly assigns to it. |

**Choose Opus before implementation starts.** “Bounded,” “quick,” known file locations, existing patterns, a detailed Astra plan, and clear acceptance tests do not by themselves qualify work for Sol. Work that changes authentication/authorization, payment behavior, security policy, data lifecycles, external contracts, or a user flow belongs to Opus, including when only a few files need edits. For Sol, the handoff must name the exact mechanical transformation and explain why no implementation judgment remains; if uncertain, use Opus. A specialist review does not replace the implementation owner.

Opus runs through the shell using this skill's [Claude helper](scripts/claude.sh); read [Claude sessions](references/claude-code.md) for invocation and recovery. Its absence from native subagent models or MCP/tool search results says nothing about this CLI path. Before declaring Opus unavailable, check the helper and local Claude CLI and retain the concrete filesystem, CLI, authentication, or invocation error. Without that evidence, availability is unverified. If blocked, diagnose and repair that path first; do not downgrade integrated implementation to Sol for tool convenience. An explicit user choice of a different implementer takes precedence.

If an in-progress ticket was misrouted, stop overlapping edits, preserve the existing diff, and transfer implementation ownership to Opus. Have Opus inspect, complete, and verify the patch; do not request a ceremonial extra pass or discard valid work merely to change its author. Keep the same owner through review corrections and retain the designated final reviewer. For already completed work, report the actual contributors; do not reopen it solely to claim the preferred model participated.

Preserve the main task's selected model and settings. Apply worker defaults unless the user specifies otherwise; do not automatically propagate Fast to expensive workers. If the interface cannot set or confirm a model, effort, or speed preference, state that limitation and report unobserved settings as unknown.

Prefer Daybreak Blue for the specialist work above when the current approved runtime exposes it through the subagent interface. Resolve its exact model ID and supported effort from that interface; do not infer subagent access from a UI picker or another product surface. Confirm the reported model when available. If unavailable, use the existing role's model within the authorized scope and state the fallback; if the user requires Daybreak specifically, report the limitation instead of substituting. Do not relabel Sol as Daybreak or invent a model alias. [Official Daybreak role guidance](https://learn.chatgpt.com/docs/cyber-safety#choose-the-right-model).

**Luna is cheap enough that its cache retention is not an optimization target.** Choose fresh or resumed Luna workers for context, independence, and ownership. Do not keep Luna alive, send warming turns, or complicate its lifecycle for cache savings. Use distinct targeted reviewers when the questions justify them.

Use available native subagent tools for bounded internal delegation. Create separate sidebar tasks only when the user explicitly requests them. Reuse existing tasks within their authorized scope. On this installation, Codex model IDs are `gpt-6-luna`, `gpt-6-astra`, and `gpt-6-sol`; request `model` and `reasoning_effort` through native agent tools, or `model` and `thinking` through app task tools as their actual schemas allow. Speed is a separate setting; these model/effort arguments alone do not set Fast. Do not invent CLI profiles or provider commands. Follow the runtime's rules for model overrides and history forks.

## Work through a slice

1. Locate the canonical plan and current repository/worktree state. Choose Opus as implementation owner, using Sol only for the mechanical exception above. Small clear tickets can skip a planning pass; they still go to Opus. Ask Astra to plan only where consequential decisions or uncertainty warrant it. Reuse a sufficient existing plan.
2. The main task prepares the short handoff below: inspect likely entry points and supply working examples so an expensive implementer starts with useful context. A bounded repository investigation may be delegated when useful; its worker returns files and evidence without taking over coordination. File hints are verified starting points, not a ban on necessary discovery.
3. Assign one owner for changes to a given area. Allow parallel independent work without overlapping edits or duplicate full-suite runs. Use the Claude helper for Opus; read [Claude sessions](references/claude-code.md) when doing so.
4. Review a stable candidate where useful with Luna Medium. Give each reviewer a distinct question and the current diff, expected behavior, and relevant files. Avoid anchoring an independent reviewer on the implementer's conclusions.
5. The main task deduplicates findings and batches related corrections. The implementer reproduces plausible issues and fixes confirmed problems. Use Astra for consequential, cross-cutting, or disputed questions requiring broader judgment, not for routine consolidation of every review.
6. Keep related corrections in the same implementation session while its context remains useful; the coordinator must not patch them itself. Rerun affected checks before the next review. After two unsuccessful attempts at the same issue, obtain a concrete reproduction and change the approach; use Astra diagnosis when needed instead of repeating guesses.
7. Verify acceptance and actual user-visible behavior. Follow repository checks, including database queues where required. Keep one full-gate owner per repository. UI work needs inspection of the running interface. A separate polish pass is optional, not a mandatory final handoff.
8. Update canonical project state with the verified result and remaining limits. Close the workstream when appropriate; preserve recovery information.

### Handoff

- Deliverable and acceptance criteria.
- Implementation owner and model; for Sol, the exact mechanical transformation and why it qualifies.
- Exact repository, worktree, branch/revision, and canonical plan pointer.
- Relevant files/symbols, inspected facts, and a working neighboring example.
- Known failure or reproduction; constraints and scope boundaries.
- Verification commands split between implementer and coordinator, with one full-gate owner.
- Unresolved decisions, explicitly labeled assumptions, and stopping point.

Implementers report changes, verification evidence, deviations, and unmet criteria. Send concise results back; do not copy complete conversation histories or repeated tool logs into every worker.

Record each actual contributor's role, observed model, agent/session ID, and result pointer for this workstream in its handoff. Distinguish planned, running, completed, and unused roles. Base completion summaries on those records: an earlier feature's Opus review, a launch without a result, or an Astra planning memo is not evidence of current implementation or final review. Name actual substitutions and omissions instead of claiming the requested crew sequence occurred. Do not launch unnecessary workers just to fill a roster.

### Targeted review

For each actionable finding, identify the file/line, trigger, expected versus actual behavior, impact, and supporting evidence. State whether it was reproduced or remains a hypothesis. Return “no actionable findings within this scope” when appropriate. Do not present preferences as defects or a narrow clean review as whole-application approval.

Astra's substantive review should identify pass, required fixes, or missing evidence against the relevant acceptance criteria, with severity and concrete reasons. Include layout/flow judgment when it is part of the change.

Preserve any designated final reviewer across follow-ups. A Luna focused review does not replace a requested Astra final review. Review the completed diff and ensure required checks cover the final changes before reporting acceptance.

## State and cost

Keep the project's existing roadmap or issue as the source of truth. Store local session IDs, invocation settings, handoffs, usage, and execution status under `.model-crew/<workstream>/`. Link to the canonical plan; do not put the only copy of durable requirements or decisions in ignored metadata. The helper creates `.model-crew/.gitignore` to ignore this local execution state.

Reuse context while useful. When history grows unwieldy, checkpoint the existing diff, decisions, unresolved findings, and test evidence in the handoff, then continue from that summary in a fresh session without overlapping writers. Use the same approach after a context-limit failure; resuming or forking oversized history does not solve it. Judge total usage through acceptance, including coordination, reviews, reproductions, and fixes; cached input is still charged. API-equivalent estimates are not subscription bills or exact included-allowance consumption.

Automatic warming is off. For an expensive Astra or Sol worker waiting on known follow-up work, consult [cache decisions](references/cache-decisions.md) only if observed cold resumes justify investigation. Do not spend Luna turns or engineering effort managing Luna caches. Do not create background automations merely to preserve sessions.
