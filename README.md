# Model Crew

A Codex skill for coordinating coding work across Luna, Astra, Opus, and Sol. It routes implementation and focused review work, preserves useful worker sessions, and verifies completed slices.

## Install

Clone this repository into your Codex skills directory:

```sh
mkdir -p "$HOME/.codex/skills"
git clone https://github.com/OWNER/model-crew.git "$HOME/.codex/skills/model-crew"
```

Replace `OWNER` with the GitHub account that hosts this repository.

If you already have a `model-crew` folder there, update it with `git pull` from that folder instead of cloning again. You can also place it in a repository's `.agents/skills` directory to make it available for that repository.

The skill is set to explicit invocation. Ask Codex to use `$model-crew` when you want it to coordinate a coding task.

## Contents

- `SKILL.md` — coordination contract and workflow
- `agents/openai.yaml` — Codex display metadata
- `scripts/claude.sh` — Claude subscription session helper
- `references/` — Claude session and cache guidance

## Scope

Use this skill only when explicitly invoked. It coordinates bounded implementation and review work; it does not replace the project's canonical plan or verification gates.
