---
name: recommend
description: Analyze open issues against codebase activity, severity, and project trends to recommend what to work on next. Use when user says "what should I work on", "recommend an issue", "pick my next task", "what's most impactful", "suggest something to work on", or wants an opinionated recommendation of which issues to tackle.
---

# Recommend

Analyzes open issues against codebase activity, severity, and external project trends, then recommends the 3 most impactful issues to work on next.

## Critical Rules

- **Read-only** — never create, modify, or close issues
- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always show scoring transparency** — every recommendation includes the score breakdown
- **Diversify categories** — top 3 must come from at least 2 categories
- **Exclude issues assigned to others** — only recommend unassigned issues or issues assigned to the current user
- **Cross-reference develop skill** — after presenting recommendations, offer to start work via the develop skill

## Prerequisites Check

```bash
gh auth status
```

If this fails, tell the user to run `gh auth login` first.

## Workflow

### Phase 1: Gather Context

Collect baseline information about the current user and repository.

```bash
# Current user
gh api user --jq '.login'

# Repo metadata
gh repo view --json nameWithOwner,description,defaultBranchRef

# Issues already assigned to me
gh issue list --assignee @me --state open --json number,title,labels,updatedAt --limit 50

# Local branches (to detect in-progress work)
git branch --list | head -30
```

**If the user already has 3+ assigned issues**, note this and suggest they may want to finish existing work first (but still proceed with recommendations if asked).

### Phase 2: Scan Open Issues

Gather the full set of open issues to score.

```bash
# All open issues (capped at 100)
gh issue list --state open --json number,title,labels,assignees,createdAt,updatedAt,comments,author --limit 100

# Targeted queries for high-signal subsets
gh issue list --state open --label "bug" --json number,title,labels,updatedAt --limit 30
gh issue list --state open --search "no:label" --json number,title,createdAt --limit 20
gh issue list --state open --search "no:assignee" --json number,title,labels,createdAt --limit 30
```

**If the repo has 0 open issues**, tell the user and suggest the create skill.

**If the repo has fewer than 3 open issues**, recommend all of them with scoring but note the limited pool.

### Phase 3: Assess Codebase Activity

Identify recently active code areas to score codebase alignment.

```bash
# Recent commits (last 2 weeks)
git log --oneline --since="2 weeks ago" --no-merges --format="%h %s" | head -30

# Hotspot files — most frequently changed in last 2 weeks
git log --since="2 weeks ago" --no-merges --name-only --format="" | sort | uniq -c | sort -rn | head -20

# Hotspot directories — most active areas
git log --since="2 weeks ago" --no-merges --name-only --format="" | xargs -I{} dirname {} 2>/dev/null | sort | uniq -c | sort -rn | head -15
```

Record the top hotspot files and directories for Phase 5 scoring.

### Phase 4: Research Project Trends

Search the web for recent news, vulnerabilities, or community activity related to the project.

```bash
# Get repo owner/name for search
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

Use **WebSearch** to search for:
- `"{owner/repo}" bug OR vulnerability OR issue` (recent problems)
- `"{owner/repo}" release OR changelog` (recent releases that may introduce work)

**For private repos or when no web results are found**: skip gracefully. Note "External signal: not available" in the scoring and set the External Signal dimension to 0 for all issues.

### Phase 5: Score and Present

Read the full scoring rubric from `references/scoring-rubric.md`, then apply it to each candidate issue.

#### Scoring Dimensions (summary)

| Dimension | Weight | What it measures |
|-----------|--------|-----------------|
| Severity Signal | 0.25 | Bug labels, crash/error keywords, blocking references |
| Codebase Alignment | 0.20 | Issue touches recently active code areas |
| Effort Estimate | 0.15 | Quick wins score high, epics score low |
| Freshness | 0.15 | Recently active issues preferred |
| Availability | 0.15 | Unassigned and no open PRs preferred |
| External Signal | 0.10 | Web research matches (vulnerabilities, community demand) |

Score each open issue on all 6 dimensions (0-10 scale each), compute the weighted sum, then rank.

#### Category Diversification

Classify each issue into one of these categories:
- **Blocking Bug** — has `bug` label + blocking/crash keywords
- **Quick Win** — small scope, clear acceptance criteria, no dependencies
- **Documentation** — has `docs` label or mentions docs/readme
- **Feature** — has `feature` label or is a feature request
- **Maintenance** — has `chore` label, dependency updates, refactoring

**Rule**: The top 3 recommendations must come from at least 2 different categories. If all 3 are the same category, demote #3 and promote the highest-scoring issue from a different category.

#### Output Format

Present the recommendations as:

**1. Summary Table**

| Rank | Issue | Category | Score | Key Signal |
|------|-------|----------|-------|-----------|
| 1 | #N: Title | Blocking Bug | 8.2 | Recently active area, crash keyword |
| 2 | #M: Title | Quick Win | 7.5 | Unassigned, small scope, fresh |
| 3 | #K: Title | Feature | 6.9 | Community demand, aligns with hotspot |

**2. Per-Issue Detail**

For each recommended issue, show:
- **Why this issue**: 2-3 sentence plain English rationale
- **Score breakdown**: table with each dimension's raw score and weighted contribution
- **Risk/caveat**: anything to watch out for (dependencies, unclear scope, etc.)

**3. Next Steps**

- "Want me to start working on one of these? I can use the develop skill to create a branch and begin."
- "Need more detail on any issue? I can use the triage skill for a deep dive."
- "None of these fit? I can narrow the search (e.g., only bugs, only docs) or create a new issue."

## Edge Cases

**All issues are stale** (no activity in 30+ days):
- Note this in the report. Recommend the most impactful stale issues but suggest the user may want to verify they're still relevant.

**All issues are assigned to others**:
- Tell the user there are no available issues. Suggest creating a new issue or asking a teammate for pair work.

**No labels on any issues**:
- Fall back to keyword analysis of titles and bodies. Note that labeling would improve future recommendations and offer the manage skill.

**No web search results**:
- Set External Signal to 0 for all issues. Note this in the output.

**User narrows scope** (e.g., "recommend a bug to fix"):
- Filter to matching issues before scoring. Relax the diversification rule if the user explicitly wants a single category.

**500+ open issues**:
- The 100-issue cap applies. Note that recommendations are based on the most recent 100 issues. Suggest the user filter with labels or keywords for better results.

## Cross-References

- **develop** — start working on a recommended issue
- **refine** — if a recommended issue needs more detail before starting
- **create** — if no good candidates exist and the user wants to file something new
- **triage** — for deeper exploration of the issue landscape

## Troubleshooting

**`gh` not found**:
- Tell the user to install it: `brew install gh` (macOS) or see https://cli.github.com

**Not in a git repository**:
- Ask the user to navigate to a repository or specify the repo with `--repo owner/name`.

**Rate limiting**:
- If API calls fail with rate limit errors, wait and retry. Inform the user about the limitation.

**Very few issues**:
- If fewer than 3 issues exist, recommend all of them. Note the small pool.
