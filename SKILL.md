---
name: model-crew
description: Coordinate coding work from the current main task across Luna, Astra, Opus, and Sol when explicitly invoked. Route implementation and focused reviews, preserve useful worker sessions, and verify completed slices.
---

# Model Crew

Use only when explicitly called. After invocation, keep this workflow active for follow-up work and subsequent tickets in the same task until the user changes it; do not require repeated invocation. Preserve that choice and worker ownership in task handoffs. Optimize for accepted work, including correction and review overhead. Preserve the user's model choices and existing authorization.

**The main user-facing task is the coordinator, regardless of its selected model.** Keep decomposition, dispatch, consolidation, acceptance, and user communication there. Do not spawn a coordinator subagent or create a replacement coordinator task to match a model preference. Delegate bounded investigation, planning, implementation, or review directly to workers. A worker follows its assigned scope and reports back; reading this skill does not make it another coordinator.

**The coordinator does not implement.** Delegate source code, tests, migrations, dependency/lockfile changes, configuration, and implementation documentation, including small fixes and review corrections. There is no tiny-edit or quick-ticket exception. The main task may inspect code/diffs, run verification as the designated gate owner, and maintain handoffs, execution metadata, and project status. Only an explicit user instruction to implement in the main task overrides this boundary. If a worker is unavailable or blocked, repair the delegation or use an available implementation worker; do not silently take over its edits.

Keep ownership clear in updates: name the worker making changes and distinguish its work from the coordinator's checks. A correction such as “you should not be writing code; use your crew” changes who performs the work, not the authorized objective. Continue through the assigned implementer; do not interpret it as cancellation or interrupt the worker without a separate reason.

## Routing

| Role | Default | Use |
| --- | --- | --- |
| Coordinator | Current main task; Luna 6 Max, Fast is a suggested user-selected setup | Break down work, find relevant files and examples, dispatch, consolidate findings, track acceptance. No implementation edits. |
| Targeted reviewer | Luna 6 Medium | Investigate a named concern in a specific diff, subsystem, or behavior; return concrete evidence. |
| Planner and difficult reasoning | Astra Xhigh, Standard | Consequential architecture, ambiguity, interacting risks, difficult diagnosis, and substantive review decisions. Implement a hard piece directly when useful. |
| Feature implementer | Opus 5.5 through Claude Code | Feature construction, integration, UI implementation, and visual polish. Use the configured Claude subscription; preserve configured effort rather than forcing Max. |
| Bounded implementer | Sol 6, Standard | Mechanical edits, established patterns, straightforward refactors, and well-specified changes with clear checks. Long duration alone is not a reason to choose Sol. |
| Conditional specialist | Daybreak Blue, when available to subagents | Security-focused review, vulnerability triage, remediation, and patch validation; also a bounded task the user explicitly assigns to it. |

The Luna coordinator preference is not a prerequisite: continue coordinating in the current main task with its selected model and settings. Do not propagate Fast to expensive workers. Preserve explicitly requested effort settings. If the current task or tools cannot express a preference, disclose the actual setting instead of claiming a model switch.

Prefer Daybreak Blue for the specialist work above when the current approved runtime exposes it through the subagent interface. Resolve its exact model ID and supported effort from that interface; do not infer subagent access from a UI picker or another product surface. Confirm the reported model when available. If unavailable, use the existing role's model within the authorized scope and state the fallback; if the user requires Daybreak specifically, report the limitation instead of substituting. Do not relabel Sol as Daybreak or invent a model alias. [Official Daybreak role guidance](https://learn.chatgpt.com/docs/cyber-safety#choose-the-right-model).

**Luna is cheap enough that its cache retention is not an optimization target.** Choose fresh or resumed Luna workers for context, independence, and ownership. Do not keep Luna alive, send warming turns, or complicate its lifecycle for cache savings. Use distinct targeted reviewers when the questions justify them.

Use available native subagent tools for bounded internal delegation. Create separate sidebar tasks only when the user explicitly requests them. Reuse existing tasks within their authorized scope. On this installation, Codex model IDs are `gpt-6-luna`, `gpt-6-astra`, and `gpt-6-sol`; request `model` and `reasoning_effort` through native agent tools, or `model` and `thinking` through app task tools as their actual schemas allow. Speed is a separate setting; these model/effort arguments alone do not set Fast. Do not invent CLI profiles or provider commands. Follow the runtime's rules for model overrides and history forks.

## Work through a slice

1. Locate the canonical plan and current repository/worktree state. Route small clear changes directly to an implementation worker; ask Astra to plan only where consequential decisions or uncertainty warrant it. Reuse a sufficient existing plan.
2. The main task prepares the short handoff below: inspect likely entry points and supply working examples so an expensive implementer starts with useful context. A bounded repository investigation may be delegated when useful; its worker returns files and evidence without taking over coordination. File hints are verified starting points, not a ban on necessary discovery.
3. Assign one owner for changes to a given area. Allow parallel independent work without overlapping edits or duplicate full-suite runs. Use the Claude helper for Opus; read [Claude sessions](references/claude-code.md) when doing so.
4. Review where useful with Luna Medium. Give each reviewer a distinct question and the current diff, expected behavior, and relevant files. Avoid anchoring an independent reviewer on the implementer's conclusions.
5. The main task deduplicates findings. The implementer reproduces plausible issues and fixes confirmed problems. Use Astra for consequential, cross-cutting, or disputed questions requiring broader judgment, not for routine consolidation of every review.
6. Send related corrections to the same implementation session; the coordinator must not patch them itself. After two unsuccessful attempts at the same issue, obtain a concrete reproduction and change the approach; use Astra diagnosis when needed instead of repeating guesses.
7. Verify acceptance and actual user-visible behavior. Follow repository checks, including database queues where required. Keep one full-gate owner per repository. UI work needs inspection of the running interface. A separate polish pass is optional, not a mandatory final handoff.
8. Update canonical project state with the verified result and remaining limits. Close the workstream when appropriate; preserve recovery information.

### Handoff

- Deliverable and acceptance criteria.
- Exact repository, worktree, branch/revision, and canonical plan pointer.
- Relevant files/symbols, inspected facts, and a working neighboring example.
- Known failure or reproduction; constraints and scope boundaries.
- Verification commands and who owns the full gate.
- Unresolved decisions, explicitly labeled assumptions, and stopping point.

Implementers report changes, verification evidence, deviations, and unmet criteria. Send concise results back; do not copy complete conversation histories or repeated tool logs into every worker.

### Targeted review

For each actionable finding, identify the file/line, trigger, expected versus actual behavior, impact, and supporting evidence. State whether it was reproduced or remains a hypothesis. Return “no actionable findings within this scope” when appropriate. Do not present preferences as defects or a narrow clean review as whole-application approval.

Astra's substantive review should identify pass, required fixes, or missing evidence against the relevant acceptance criteria, with severity and concrete reasons. Include layout/flow judgment when it is part of the change.

Preserve any designated final reviewer across follow-ups. A Luna focused review does not replace a requested Astra final review. Review the completed diff and ensure required checks cover the final changes before reporting acceptance.

## State and cost

Keep the project's existing roadmap or issue as the source of truth. Store local session IDs, invocation settings, handoffs, usage, and execution status under `.model-crew/<workstream>/`. Link to the canonical plan; do not put the only copy of durable requirements or decisions in ignored metadata. The helper creates `.model-crew/.gitignore` to ignore this local execution state.

Reuse context while useful. Start a summarized session or compact at a natural boundary when irrelevant history outweighs continuity. Judge total usage through acceptance, including coordination, reviews, reproductions, and fixes; cached input is still charged. API-equivalent estimates are not subscription bills or exact included-allowance consumption.

Automatic warming is off. For an expensive Astra or Sol worker waiting on known follow-up work, consult [cache decisions](references/cache-decisions.md) only if observed cold resumes justify investigation. Do not spend Luna turns or engineering effort managing Luna caches. Do not create background automations merely to preserve sessions.
