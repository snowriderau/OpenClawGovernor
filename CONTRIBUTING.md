# Contributing to OpenClaw Governor

This is a template repo. Contributions improve the template — they don't patch a running system. When you fork and deploy, your instance diverges from this repo. That's intentional.

## How to contribute

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-change`
3. Make your changes
4. Open a PR against `main`

Keep PRs focused. One thing per PR is easier to review and harder to break.

## What makes a good PR

**Follows the autonomous-first philosophy.** The Governor handles config — users never touch JSON directly. If your change requires a user to manually edit `openclaw.json`, it's not ready. The right pattern is: Governor reads a spec, Governor writes the config.

**Uses `{{PLACEHOLDER}}` format for environment-specific values.** Any value that differs between deployments (IPs, usernames, model names, paths) must use a `{{PLACEHOLDER}}` token that `scripts/init.sh` can replace. Hard-coded values break other people's setups.

**Platform agnostic.** The template runs on Ubuntu, Debian, Arch, Pop!_OS, and anything else. Avoid distro-specific package managers, paths, or assumptions unless they're behind a clearly labeled conditional.

**Doesn't add complexity without payoff.** Ask: would someone setting this up for the first time benefit from this change? If the answer requires a paragraph to explain, simplify.

## Areas that need help

- **New workspace examples** — real-world `IDENTITY.md`, `TOOLS.md`, and `INSTRUCTIONS.md` examples for domains not yet covered (finance, media, home automation, etc.)
- **Additional specs** — Governor command specs for common setup tasks (`specs/` directory)
- **Better `init.sh` defaults** — smarter defaults, better validation, cleaner output for edge cases
- **Documentation improvements** — clearer explanations, better FAQ answers, updated architecture notes

## Testing

Before opening a PR, run `scripts/init.sh` with test values and verify:

1. No `{{PLACEHOLDER}}` tokens remain in non-optional sections after a full run
2. The `.env` file is written correctly and is gitignored
3. Any file you modified still parses correctly (JSON is valid, shell scripts pass `bash -n`)

Quick check for remaining placeholders after a test run:

```bash
grep -r '{{[A-Z_]*}}' . --include="*.md" --include="*.json" --include="*.sh" \
  --exclude-dir=.git --exclude-dir=_source
```

Optional placeholders (Tailscale, NAS, Telegram) are expected to remain if those sections were skipped.

## Style

Match the existing file tone: confident, practical, no hand-holding. Short sentences. No filler. If a sentence doesn't add information, cut it.

Documentation lives in `docs/`. Specs live in `specs/`. Agent memory (`active_state.md`, `failures.md`) is runtime state — don't modify it in PRs.
