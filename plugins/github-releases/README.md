# github-releases

Intelligent GitHub release management for Claude Code via the `gh` CLI.

## What It Does

Gives Claude Code natural language access to GitHub releases — creating releases with intelligent versioning, generating release notes, managing assets, and configuring release note automation.

## Prerequisites

- [GitHub CLI](https://cli.github.com) (`gh`) installed and authenticated (`gh auth login`)

## Skills

| Skill | Trigger examples | What it does |
|-------|-----------------|--------------|
| **create** | "create a release", "cut a release", "ship it", "release v1.2.0" | Create releases with version detection, notes generation, and preview |
| **browse** | "show releases", "latest release", "what changed in v2.0", "compare releases" | List, view, and compare releases with natural language |
| **manage** | "edit release notes", "publish the draft", "upload assets", "delete release" | Edit, publish, delete releases and manage assets |
| **configure** | "configure release notes", "create release.yml", "set up release categories" | Generate `.github/release.yml` for automated release note categorization |

## Hooks

| Hook | Event | Blocking? | What it does |
|------|-------|-----------|--------------|
| **session-start** | SessionStart | No | Displays latest release tag, unreleased commit count, and draft release count |

## Cross-Cutting Behaviors

All skills automatically:

- **Detect tag conventions** — match the repo's existing tag prefix pattern (v-prefix or not)
- **Gather release context** — check latest tag, `.github/release.yml` existence, default branch
- **Follow semver** — analyze commits/PRs before suggesting version bumps, always explain reasoning
- **Draft by default** — releases are created as drafts since they trigger webhooks and CI/CD

## Installation

```bash
# From the cc-plugins marketplace
/plugin install github-releases@cc-plugins
```

## Local Development

```bash
cd /path/to/your-project
claude --plugin-dir /path/to/cc-plugins/plugins/github-releases
```
