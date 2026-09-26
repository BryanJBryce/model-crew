# Cache decisions

Read when investigating expensive idle resumes, not for ordinary Luna coordination or review. Luna cache management is intentionally out of scope: its cost is too small to justify lifecycle complexity.

## Codex

- Keep warming off by default. Useful requests in an active conversation already reuse eligible context. An open task, running process, or status poll does not itself refresh the model's prompt cache.
- Reuse an expensive worker for related follow-ups. A cheaper model cannot refresh another model's cache. Model, rendered prefix, breakpoint eligibility, and routing matter; retaining a task ID is not a cache guarantee.
- Official API/model guidance checked September 25, 2026 describes a minimum 30-minute lifetime after the latest write or reuse for GPT-5.6 and later, with possible longer retention. This is not a verified per-task TTL promise for the signed-in Codex app. Do not invent a Codex configuration knob from API fields.
- Codex credit billing has no separate cache-write charge. Its listed cached input rates for Astra/Sol/Luna are 0.1× input rates; direct API billing has different cache-write treatment. Keep the billing paths distinct.

A useful candidate for measurement is Astra planning, waiting for an Opus build, then reviewing. Compare first-request cache ratios after similar idle gaps with the same model and substantially unchanged context. Separate expiry from compaction, changed instructions/tools, and model switches. An aggregate 96–97% hit rate does not isolate idle-resume costs.

Before introducing any bounded warming experiment, estimate:

`expected avoided cold-resume cost > all warming input + output + new-context cost`

Include the chance that the follow-up never occurs or the cache remains warm anyway. For example, 150k Astra input tokens at Standard cost 37.5 credits uncached or 3.75 cached; one fully cached warming request plus a fully cached real request costs 7.5 input credits, before output/new context. This saves only if the real request would otherwise miss. It does not establish that a warming loop is worthwhile.

If justified, scope an experiment to a known paused expensive worker, record actual cache counters and total usage, set a stop time, and stop on real follow-up, cancellation, model/context change, or loss of expected benefit. Use the app's supported automation tooling for any requested scheduled behavior. No warming automation is installed by this skill.

## Claude

Claude Code manages its server-side cache. A local authentication command may retain an older plan label than the effective account plan. Check effective billing and observed counters rather than treating that label as a TTL measurement.

At the checked documentation version, included subscription main conversations, including `claude -p`, normally use one hour. API/paid usage credits and most helper/subagent requests default to five minutes, subject to settings and request type. Existing inspected local Opus sessions reported one-hour cache writes. This supports ordinary session reuse, not background pinging.

Opus 5.5 reads are 0.05× ordinary input; five-minute writes are 1.25× and one-hour writes 2×. Recheck rates before cost calculations. A matching prefix in a fork can reuse cache without appending to the original conversation, but a fork is still a model request and is not free maintenance.

Do not assume repository edits or every CLAUDE.md/MCP change invalidate the whole cache: the effective request prefix determines reuse. A new working directory/model or changed prefix can prevent reuse. Session expiry estimates are not guarantees.

Sources, checked September 25, 2026:
- [OpenAI prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching)
- [Codex credit rates](https://learn.chatgpt.com/docs/pricing#token-rates)
- [Claude Code caching](https://code.claude.com/docs/en/prompt-caching)
- [Anthropic cache pricing](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#pricing)
