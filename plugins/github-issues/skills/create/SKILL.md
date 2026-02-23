---
name: create
description: Create well-researched GitHub issues with immediate refinement. Use when user says "create issue", "new issue", "file a bug", "open an issue", "report a problem", "request a feature", or wants to create a GitHub issue from a rough idea.
---

# Create

Creates a new GitHub issue from a rough idea, immediately refining it into a well-structured issue with deep research.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Research before writing** — use every available tool to gather context
- **Always search for duplicates** before creating
- **Always preview** the issue with the user before submitting
- **NEVER create priority labels** — see `skills/shared/references/label-taxonomy.md`
- **Add a creation comment** summarizing research sources and decisions

## Prerequisites Check

```bash
gh auth status
```

If this fails, tell the user to run `gh auth login` first.

## Workflow

### Phase 1: Understand the Intent

Parse the user's request. Identify:
- Is this a bug report, feature request, task, or something else?
- What problem does it solve or what value does it add?
- Are there specific details (error messages, file paths, steps to reproduce)?

### Phase 2: Deep Research

Use **every available tool** to gather as much context as possible. The goal is to create an issue that is immediately actionable — not a placeholder.

#### 2a. Codebase Research

Scan the local codebase for relevant context:
- **Search for related code** — find files, functions, classes related to the issue topic
- **Read relevant files** — understand the current implementation
- **Check for TODOs/FIXMEs** — existing markers for known issues
- **Review recent commits** — has this area been recently changed?

```bash
# Recent changes in relevant area
git log --oneline -20 -- "path/to/area"
```

#### 2b. Web Research

Search the web for relevant context — this is critical for well-informed issues:
- **Error messages** — search for exact error text to find known issues, solutions
- **Library/framework issues** — check upstream bug trackers for related problems
- **Best practices** — search for recommended approaches to the problem
- **Documentation** — find official docs for relevant APIs, libraries, tools

Use WebSearch and WebFetch to gather information. Always verify information against the actual codebase.

#### 2c. Available Tools and Servers

Use any MCP servers and tools available in the current session:
- **Asana/project management** — check for related tasks or initiatives
- **Documentation tools** — search internal docs for context
- **API tools** — verify endpoint behavior, check schemas
- Any other connected service that might have relevant information

#### 2d. GitHub Research

```bash
# Search for duplicate or related issues
gh issue list --search "keyword1 keyword2" --state all --json number,title,state,labels --limit 20

# Check closed issues — has this been reported and closed before?
gh issue list --search "keyword" --state closed --json number,title,closedAt --limit 10

# Check PRs that might be related
gh pr list --search "keyword" --state all --json number,title,state --limit 10

# Check existing labels
gh label list --json name,color,description --limit 100
```

If duplicates are found, tell the user and ask whether to:
- Add a comment to the existing issue instead
- Create a new issue with a cross-reference
- Abort

### Phase 3: Draft the Issue

Based on all research, compose a well-structured issue.

**For bug reports**:
```markdown
## Problem

[Clear description of the defect]

## Steps to Reproduce

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected Behavior

[What should happen]

## Actual Behavior

[What actually happens, include error messages]

## Context

- [Relevant code: `path/to/file.py:42`]
- [Environment details if relevant]
- [Related: #N, upstream-repo#M]

## Acceptance Criteria

- [ ] [Specific testable criterion]
- [ ] [Edge case to handle]
```

**For feature requests / user stories**:
Read `skills/refine/references/user-story-guide.md` for the full template, then apply:

```markdown
## User Story

As a [user type],
I want [goal],
So that [benefit].

## Context

[Background, motivation, research findings, links to docs or discussions]

## Acceptance Criteria

### Scenario: [happy path]
- Given [precondition]
- When [action]
- Then [expected result]

### Additional criteria
- [ ] [Criterion]
- [ ] [Non-functional requirement]

## Out of Scope

- [What this does NOT cover]

## Technical Notes

- [Relevant code areas: `path/to/module/`]
- [Dependencies or constraints discovered during research]
- [Links to relevant documentation]

## Related Issues

- Related to #N
- See also #M
```

### Phase 4: Validate

Before presenting to the user, check the draft against:

1. **INVEST criteria** (read `skills/refine/references/user-story-guide.md`):
   - Independent, Negotiable, Valuable, Estimable, Small, Testable
   - If the issue is too large, suggest splitting into an epic with sub-issues

2. **Completeness** — does the issue have enough context to act on?
   - For bugs: can someone reproduce it from the description alone?
   - For features: are the acceptance criteria specific and testable?

3. **Labels** — suggest appropriate labels from the existing set

### Phase 5: Preview and Create

Present the complete draft to the user:
- Title
- Body
- Suggested labels
- Suggested assignee (if obvious)
- Any related issues found

Wait for user approval or feedback. Iterate if needed.

```bash
gh issue create \
  --title "Title" \
  --body "Body with markdown" \
  --label "type: feature,status: ready" \
  --assignee @me
```

**After creation**:
- Report the issue number and URL
- If the issue is large enough to be an epic, offer to decompose it using the refine skill

## Troubleshooting

**`gh` not found**:
- Tell the user to install it: `brew install gh` (macOS) or see https://cli.github.com

**Not in a git repository**:
- Ask the user to navigate to a repository or specify `--repo owner/name`

**Issue creation fails**:
- Verify the repo has issues enabled: `gh repo view --json hasIssuesEnabled`
- Check that labels exist before referencing them in create

**No web search results**:
- Fall back to codebase-only research. Note in the issue that external research was limited.
