---
type: reference
used_by: refine, issue-reviewer
description: How to structure an epic — scope definition, acceptance criteria patterns, and decomposition heuristics.
---

# Epic Guide

## What Is an Epic

An epic is a large body of work that can be broken down into smaller user stories. It represents a business goal or capability, not a technical task.

## Epic Structure

Use this template for the epic issue body:

```markdown
## Business Goal

[One paragraph: what problem does this solve and for whom?]

## Scope

### In Scope
- [Specific deliverable 1]
- [Specific deliverable 2]
- [Specific deliverable 3]

### Out of Scope
- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

## Acceptance Criteria

- [ ] [High-level criterion 1 — measurable]
- [ ] [High-level criterion 2 — measurable]
- [ ] [High-level criterion 3 — measurable]

## Success Metrics (optional)

- [Metric 1: baseline → target]
- [Metric 2: baseline → target]

## Stories

Sub-issues will be created for individual stories.

## Related Issues

- Related to #N — [brief context]
- See also #M — [brief context]
```

## Scope Definition

Good scope answers three questions:

1. **What's the minimum viable version?** — the smallest set of stories that delivers the business goal
2. **What's explicitly excluded?** — prevents scope creep by naming things you're NOT doing
3. **What are the boundaries?** — which users, platforms, data, or scenarios are covered?

### Scope definition heuristics

- If you can't list at least 3 "out of scope" items, the scope is probably too vague
- If the epic has more than 15 stories, consider splitting into multiple epics
- If the epic has fewer than 3 stories, it's probably a story, not an epic

## Acceptance Criteria for Epics

Epic-level acceptance criteria are **high-level and outcome-oriented**. They answer "how do we know this epic is done?" — not the detailed behavior specifications (those go in stories).

### Good epic acceptance criteria

- "Users can complete the checkout flow end-to-end"
- "API response times remain under 200ms at 1000 req/s"
- "All existing tests pass with the new architecture"

### Bad epic acceptance criteria

- "The buy button is blue" (too detailed — belongs in a story)
- "The code is clean" (unmeasurable)
- "Everything works" (not specific)

## Decomposition Heuristics

When breaking an epic into stories, consider these dimensions:

### By workflow step
Map the user journey and create one story per step:
- "User can search for products"
- "User can add products to cart"
- "User can enter shipping address"
- "User can complete payment"

### By CRUD operation
For data-centric epics:
- "Admin can create new products"
- "Admin can view product list"
- "Admin can edit product details"
- "Admin can archive products"

### By user role
When different users have different needs:
- "Customer can view their order history"
- "Support agent can view any order history"
- "Admin can export order data"

### By business rule
When the epic involves complex rules:
- "System applies standard shipping rates"
- "System applies free shipping for orders over $50"
- "System applies expedited shipping surcharge"

### Target: 3-15 stories per epic
- **Fewer than 3**: probably a story, not an epic
- **More than 15**: consider splitting into sub-epics
- **Sweet spot**: 5-8 stories
