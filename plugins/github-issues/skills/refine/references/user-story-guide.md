---
type: reference
used_by: refine
description: User story format, INVEST criteria with practical tests, acceptance criteria patterns, and common anti-patterns.
---

# User Story Guide

## User Story Format

### The statement

```
As a [type of user],
I want [goal/desire],
So that [benefit/value].
```

Each part has a purpose:
- **As a** — identifies who benefits (use specific personas, not "a user")
- **I want** — describes the goal in the user's language (not technical implementation)
- **So that** — explains the business value (why this matters)

### Good examples

- "As a **customer**, I want **to save my cart across devices**, so that **I can start shopping on my phone and finish on my laptop**."
- "As a **team admin**, I want **to bulk-invite users via CSV upload**, so that **I don't have to add 50 team members one by one**."

### Bad examples

- "As a user, I want a database migration, so that the schema is updated." (technical task, not user value)
- "As a developer, I want to refactor the auth module." (no "so that" — no stated value)
- "As a user, I want the app to work." (not specific)

## Issue Body Template

```markdown
## User Story

As a [user type],
I want [goal],
So that [benefit].

## Context

[Background information, motivation, links to designs or discussions]

## Acceptance Criteria

### Scenario: [happy path]
- Given [precondition]
- When [action]
- Then [expected result]

### Scenario: [edge case]
- Given [precondition]
- When [action]
- Then [expected result]

### Additional criteria
- [ ] [Criterion that doesn't fit Given/When/Then]
- [ ] [Non-functional requirement]

## Out of Scope

- [What this story explicitly does NOT cover]

## Technical Notes (optional)

- [Implementation hints, relevant code areas, API contracts]

## Related Issues

- Related to #N
- See also #M
```

## INVEST Criteria

Use INVEST to validate story quality. Each criterion has a practical test.

### I — Independent

**Test**: Can this story be developed, tested, and released without waiting for another story?

- **Pass**: Story has no dependencies, or dependencies are already completed
- **Fail**: "We need story #A done first before we can start this"
- **Fix**: Restructure to include the minimum needed from the dependency, or combine the stories

### N — Negotiable

**Test**: Can the team discuss alternatives to how this is implemented?

- **Pass**: Story describes the outcome, not the solution
- **Fail**: "Use Redis for caching with a TTL of 300 seconds" (prescribes implementation)
- **Fix**: Rewrite to focus on the need: "Response times for product listings should be under 200ms"

### V — Valuable

**Test**: Does this story deliver value that a user or stakeholder would recognize?

- **Pass**: A non-technical person can understand why this matters
- **Fail**: "Upgrade to PostgreSQL 16" (no stated user value)
- **Fix**: Frame it in terms of user impact: "As an admin, I want reliable backup restoration, so that we don't lose customer data"

### E — Estimable

**Test**: Can the team give a rough size estimate (small/medium/large)?

- **Pass**: Team understands the scope well enough to estimate
- **Fail**: "Improve performance" (unclear scope)
- **Fix**: Add specific boundaries: "Reduce API response time for /products endpoint from 800ms to under 200ms"

### S — Small

**Test**: Can this story be completed in a single iteration/sprint?

- **Pass**: Team estimates 1-5 days of work
- **Fail**: Team estimates weeks of work
- **Fix**: Split using techniques from `splitting-techniques.md`

### T — Testable

**Test**: Can you write a specific test or scenario that proves this story works?

- **Pass**: Clear acceptance criteria that can be verified
- **Fail**: "The UI should feel fast" (subjective)
- **Fix**: Add measurable criteria: "Page load completes within 2 seconds on 3G connection"

## Acceptance Criteria Patterns

### Given/When/Then (preferred for behavior)

```markdown
### Scenario: successful login
- Given I am on the login page
- When I enter valid credentials and click "Sign In"
- Then I am redirected to the dashboard
- And I see a welcome message with my name
```

### Checklist (good for mixed criteria)

```markdown
- [ ] Email validation rejects addresses without @ symbol
- [ ] Password must be at least 8 characters
- [ ] Failed login shows specific error message (not generic)
- [ ] Account locks after 5 failed attempts
- [ ] Locked account shows unlock instructions
```

### Combined approach (recommended)

Use Given/When/Then for the main scenarios and a checklist for additional constraints, non-functional requirements, and edge cases.

## Common Anti-Patterns

| Anti-pattern | Problem | Fix |
|-------------|---------|-----|
| Technical story | "Migrate database to PostgreSQL 16" — no user value | Frame as user benefit |
| Compound story | "As a user, I want to search, filter, AND sort products" — too many things | Split into separate stories |
| Vague story | "As a user, I want the app to be better" — not actionable | Identify specific improvement |
| No acceptance criteria | How do you know it's done? | Add Given/When/Then scenarios |
| Implementation-prescriptive | "Use React and Redux to build..." — locks in approach | Describe the outcome, not the how |
| Epic disguised as story | Has 10+ acceptance criteria or weeks of work | Promote to epic and decompose |
