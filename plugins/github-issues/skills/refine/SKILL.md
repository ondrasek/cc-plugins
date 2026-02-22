---
name: refine
description: Progressively refine GitHub issues from rough ideas into well-structured epics and user stories. Use when user says "refine issue #42", "make this an epic", "split this into stories", "write acceptance criteria", "this issue needs more detail", "break down this epic", or wants to apply INVEST criteria to issues.
---

# Refine

Transforms rough or incomplete issues into well-structured epics and user stories using proven techniques.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always read the current issue content** before refining — never assume
- **Ask clarifying questions** when information is missing — don't guess at requirements
- **Preview all changes** with the user before updating the issue
- **Add a refinement comment** to every refined issue explaining what changed
- **NEVER create priority labels** — see `skills/shared/references/label-taxonomy.md`
- **Use GitHub sub-issues** for epic decomposition (not task-list checkboxes)

## Prerequisites Check

```bash
gh auth status
```

## Reference Files

Read these on demand based on the refinement type:

- `references/epic-guide.md` — epic structure, scope definition, decomposition heuristics
- `references/user-story-guide.md` — user story format, INVEST criteria, acceptance criteria patterns
- `references/splitting-techniques.md` — 9 SPIDR techniques for breaking down stories

## Capabilities

### 1. Refine to User Story

Take a rough or empty issue and refine it into a well-structured user story.

**Workflow**:

1. **Read the issue**:
   ```bash
   gh issue view NUMBER --json number,title,body,labels,assignees,comments
   ```

2. **Assess completeness** — identify what's missing:
   - Who is the user/persona?
   - What do they want to achieve?
   - Why does it matter (business value)?
   - What are the boundaries (in-scope vs out-of-scope)?
   - What does "done" look like?

3. **Ask clarifying questions** — present gaps to the user and ask for input. Do not fabricate requirements.

4. **Draft the refined issue body** (read `references/user-story-guide.md` for format):
   - User story statement: "As a [user], I want [goal], so that [benefit]"
   - Context and background
   - Acceptance criteria (Given/When/Then or checklist)
   - Out of scope (explicitly state what this does NOT cover)
   - Technical notes (if relevant)
   - Related issues (from cross-cutting search)

5. **Validate against INVEST** (read `references/user-story-guide.md` for criteria):
   - **I**ndependent — can be developed without other stories?
   - **N**egotiable — details can be discussed?
   - **V**aluable — delivers value to someone?
   - **E**stimable — team can roughly size it?
   - **S**mall — fits in a single iteration?
   - **T**estable — can verify it works?
   Flag any criteria that fail and suggest adjustments.

6. **Search for related issues**:
   ```bash
   gh issue list --search "keyword" --state all --json number,title,state --limit 10
   ```

7. **Suggest labels** from existing set:
   ```bash
   gh label list --json name,description --limit 100
   ```

8. **Preview with user** — show the refined body and wait for approval

9. **Update the issue**:
   ```bash
   gh issue edit NUMBER --body "refined body"
   gh issue comment NUMBER --body "Refined: added user story format and acceptance criteria. Changes: [summary of what was added/changed]."
   ```

### 2. Refine to Epic

Take a rough or empty issue and structure it as an epic with sub-issues.

**Workflow**:

1. **Read the issue**:
   ```bash
   gh issue view NUMBER --json number,title,body,labels,comments
   ```

2. **Define the epic** (read `references/epic-guide.md`):
   - Business goal / problem statement
   - Scope: what's in, what's out
   - High-level acceptance criteria
   - Success metrics (if applicable)

3. **Ask clarifying questions** — scope and boundaries are critical for epics

4. **Propose decomposition** — suggest 3-15 child stories using techniques from `references/splitting-techniques.md`:
   - Present each proposed story with a title and one-line description
   - Note dependencies between stories
   - Wait for user approval before creating

5. **Update the epic issue**:
   ```bash
   gh issue edit NUMBER --body "epic body"
   gh issue edit NUMBER --add-label "type: epic"
   ```

6. **Create sub-issues** — for each approved child story:
   ```bash
   gh issue create \
     --title "Story title" \
     --body "Story body with references" \
     --label "appropriate-labels"
   ```
   Then link as sub-issue:
   ```bash
   gh issue edit CHILD_NUMBER --add-parent NUMBER
   ```

7. **Cross-reference siblings** — in each child issue body, include:
   "Part of epic #NUMBER. See also: #A, #B, #C (sibling stories)."

8. **Add refinement comment to the epic**:
   ```bash
   gh issue comment NUMBER --body "Decomposed into N stories: #A, #B, #C, ... Scope: [summary]. Dependencies noted between #X and #Y."
   ```

### 3. Split Epic into Stories

Decompose an existing epic into user stories.

**Workflow**:

1. **Read the epic and existing sub-issues**:
   ```bash
   gh issue view NUMBER --json number,title,body,labels,comments
   # Check for existing sub-issues
   gh issue list --search "parent:NUMBER" --json number,title,state
   ```

2. **Apply splitting techniques** — read `references/splitting-techniques.md` for SPIDR:
   - Workflow steps
   - CRUD operations
   - Business rule variations
   - Data variations
   - Interface complexity
   - Major effort isolation
   - Simple/complex split
   - Defer performance
   - Spike first

3. **For each story** — apply user story format + INVEST validation (read `references/user-story-guide.md`)

4. **Preview the decomposition** with the user

5. **Create sub-issues and cross-reference** (same as "Refine to Epic" steps 6-8)

### 4. Split Large Story

Take an oversized user story and split it into smaller stories.

**Workflow**:

1. **Read the story**:
   ```bash
   gh issue view NUMBER --json number,title,body,labels
   ```

2. **Evaluate against INVEST** — identify which criteria fail (usually "Small")

3. **Choose splitting technique** from `references/splitting-techniques.md` based on the story content

4. **Propose new stories** — present to user for approval

5. **Create new issues as sub-issues**:
   ```bash
   gh issue create --title "Split story title" --body "body"
   gh issue edit NEW_NUMBER --add-parent NUMBER
   ```

6. **Update original issue** — add a comment and optionally convert it to an epic:
   ```bash
   gh issue comment NUMBER --body "Split into smaller stories: #A, #B, #C. This issue now serves as the parent epic."
   gh issue edit NUMBER --add-label "type: epic"
   ```

## Troubleshooting

**Sub-issues not supported**:
- GitHub sub-issues are GA but require the repository to have the feature enabled. If `--add-parent` fails, fall back to referencing the parent in the issue body: "Part of #NUMBER".

**Issue body too long**:
- Move detailed technical notes to a comment instead of the body. Keep the body focused on the user story and acceptance criteria.

**User can't answer clarifying questions**:
- Make reasonable assumptions, mark them explicitly as assumptions in the issue body, and note them in the refinement comment. The issue can be refined again later.
