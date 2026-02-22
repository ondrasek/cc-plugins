---
type: reference
used_by: manage
description: Safety rules and loop patterns for batch operations across multiple GitHub issues.
---

# Batch Operations

## Safety Rules

1. **Confirm before executing** — always show the user the list of issues that will be affected and the operation to perform. Wait for explicit approval.
2. **Maximum batch size** — process at most **20 issues** per batch. For larger sets, break into batches and confirm each.
3. **No batch deletes** — deletion must be done one at a time with individual confirmation.
4. **Dry-run first** — list what would change before making changes.
5. **Add comments** — when batch-modifying issues, add a comment to each explaining the bulk change.

## Patterns

### Apply label to multiple issues

```bash
# Step 1: Find the issues
gh issue list --search "QUERY" --json number,title --limit 20

# Step 2: Show the user the list and confirm

# Step 3: Apply
for num in 1 2 3 4 5; do
  gh issue edit "$num" --add-label "label-name"
  gh issue comment "$num" --body "Added \`label-name\` as part of batch triage."
done
```

### Close multiple issues

```bash
# Step 1: Find the issues
gh issue list --search "QUERY" --state open --json number,title --limit 20

# Step 2: Show the user the list and confirm

# Step 3: Close with reason
for num in 1 2 3 4 5; do
  gh issue close "$num" --reason completed --comment "Closing as part of batch cleanup — REASON."
done
```

### Assign multiple issues

```bash
for num in 1 2 3 4 5; do
  gh issue edit "$num" --add-assignee USERNAME
  gh issue comment "$num" --body "Assigned to @USERNAME as part of sprint planning."
done
```

### Move issues to a milestone

```bash
for num in 1 2 3 4 5; do
  gh issue edit "$num" --milestone "v2.0"
  gh issue comment "$num" --body "Moved to v2.0 milestone — included in next release scope."
done
```

## Error Handling

- If any operation in a batch fails, **stop and report** which issues succeeded and which failed
- Do not retry failed operations automatically — let the user decide
- Common failures: permission denied, issue already closed, label doesn't exist
