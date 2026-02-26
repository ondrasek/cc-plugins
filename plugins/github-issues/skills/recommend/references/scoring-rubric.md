---
type: reference
used_by: recommend
description: Detailed scoring rubric with dimension weights, signal-to-score mappings, and category diversification rules for issue recommendations.
---

# Scoring Rubric

## Weighted Sum Formula

```
total = (severity * 0.25) + (alignment * 0.20) + (effort * 0.15)
      + (freshness * 0.15) + (availability * 0.15) + (external * 0.10)
```

All dimensions use a 0-10 scale. Maximum possible score: 10.0.

## Dimension 1: Severity Signal (weight 0.25)

Measures how critical the issue is based on labels, keywords, and references.

| Signal | Score |
|--------|-------|
| `bug` label + crash/error/panic/fatal keyword in title or body | 10 |
| `bug` label + "blocking" or "blocks #N" reference | 9 |
| `bug` label alone | 7 |
| `breaking-change` label | 8 |
| `feature` label with user-facing impact keywords | 5 |
| `chore` or `docs` label | 3 |
| No labels — title contains error/bug/fix/broken keywords | 6 |
| No labels — no severity keywords | 2 |

Take the highest matching signal. Do not sum.

## Dimension 2: Codebase Alignment (weight 0.20)

Measures whether the issue touches code areas that have been recently active.

| Signal | Score |
|--------|-------|
| Issue body or title references a top-5 hotspot file | 10 |
| Issue body or title references a top-5 hotspot directory | 8 |
| Issue references files/directories in the top-20 hotspot list | 6 |
| Issue references code areas but they are not recent hotspots | 3 |
| Issue does not reference any specific code areas | 1 |

**How to match**: Extract file paths, directory names, module names, and function names from the issue title and body. Compare against the hotspot lists from Phase 3.

## Dimension 3: Effort Estimate (weight 0.15)

Measures likely effort — quick wins score higher.

| Signal | Score |
|--------|-------|
| Title suggests a typo, config change, or one-line fix | 10 |
| Issue body is short, clear acceptance criteria, no sub-tasks | 8 |
| `good first issue` or `help wanted` label | 8 |
| Moderate scope — single feature or fix with a few files | 5 |
| `epic` label or has sub-issues | 2 |
| Vague description, unclear scope, no acceptance criteria | 3 |

Take the highest matching signal.

## Dimension 4: Freshness (weight 0.15)

Measures recent activity — fresher issues are more likely to be relevant.

| Signal | Score |
|--------|-------|
| Updated in the last 24 hours | 10 |
| Updated in the last 3 days | 8 |
| Updated in the last 7 days | 6 |
| Updated in the last 14 days | 4 |
| Updated in the last 30 days | 2 |
| No update in 30+ days | 1 |

Use the `updatedAt` field from the GitHub API.

## Dimension 5: Availability (weight 0.15)

Measures whether the issue is free to work on.

| Signal | Score |
|--------|-------|
| Unassigned, no linked PRs | 10 |
| Assigned to current user, no linked PRs | 8 |
| Unassigned, has linked PRs (someone may be working on it) | 4 |
| Assigned to current user, has linked PRs | 3 |
| Assigned to someone else | 0 (exclude from results) |

**Exclude issues assigned to others entirely** — do not score or rank them.

To check for linked PRs:
```bash
gh issue develop NUMBER --list 2>/dev/null
```

## Dimension 6: External Signal (weight 0.10)

Measures whether web research supports the issue's importance.

| Signal | Score |
|--------|-------|
| Web search reveals a CVE or security advisory related to the issue | 10 |
| Web search shows community discussion or feature demand | 7 |
| Web search shows a related upstream bug or release note | 5 |
| Web search returns vaguely related results | 2 |
| No web results or web search unavailable | 0 |

**If web search is unavailable** (private repo, no results, rate limited): set to 0 for all issues and note it in the output. This dimension is intentionally low-weight to avoid penalizing private repos.

## Category Classification

Classify each issue into exactly one category (first match wins):

1. **Blocking Bug** — has `bug` label AND (title/body contains crash/error/panic/fatal/blocking OR references another issue with "blocks")
2. **Quick Win** — body is under 500 characters AND (has `good first issue`/`help wanted` label OR title suggests small change)
3. **Documentation** — has `docs` label OR title/body primarily discusses documentation, README, or guides
4. **Feature** — has `feature` label OR title contains "add", "implement", "support", "enable"
5. **Maintenance** — has `chore` label OR title contains "update", "upgrade", "refactor", "migrate", "dependency"
6. **Uncategorized** — none of the above match

## Diversification Algorithm

After ranking all issues by total score:

1. Take the top 3 issues
2. Check their categories — at least 2 distinct categories must be represented
3. If all 3 share the same category:
   - Keep #1 and #2
   - Replace #3 with the highest-scoring issue from a different category
4. If no issue from a different category exists (e.g., all issues are bugs), keep the original top 3 and note the lack of diversity

## Tie-Breaking Rules

When two issues have the same total score:

1. Prefer the issue with higher Severity Signal
2. If still tied, prefer the issue with higher Freshness
3. If still tied, prefer the issue with the lower issue number (older issue)
