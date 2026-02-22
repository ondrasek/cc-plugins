---
name: organize
description: Administrative operations on GitHub issues — lock, unlock, pin, unpin, transfer. Use when user says "lock issue", "pin this issue", "transfer to another repo", "unlock conversation", "archive issue", or wants to perform administrative issue operations.
---

# Organize

Administrative issue operations that manage visibility and access.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always add a comment** explaining the administrative action and why
- **Warn before destructive actions** — transfers change issue numbers, locking prevents comments
- **Check pin count** before pinning (max 3 per repo)

## Prerequisites Check

```bash
gh auth status
```

## Capabilities

### 1. Lock Conversation

Prevent further comments on an issue.

**Workflow**:

1. **View the issue** to understand context:
   ```bash
   gh issue view NUMBER --json number,title,state,comments
   ```

2. **Add a comment explaining why** (before locking):
   ```bash
   gh issue comment NUMBER --body "Locking this conversation — REASON. Decision has been recorded above."
   ```

3. **Lock with reason**:
   ```bash
   gh issue lock NUMBER --reason "resolved|off-topic|spam|too heated"
   ```

**Valid lock reasons**: `resolved`, `off-topic`, `spam`, `too heated`

### 2. Unlock Conversation

Re-enable comments on a locked issue.

```bash
gh issue unlock NUMBER
gh issue comment NUMBER --body "Unlocked conversation — REASON."
```

### 3. Pin Issue

Pin an issue to the top of the issues list for visibility.

**Workflow**:

1. **Check current pins** (max 3 per repo):
   ```bash
   gh issue list --search "is:pinned" --json number,title
   ```

2. If already at 3 pins, ask the user which to unpin first.

3. **Pin the issue**:
   ```bash
   gh issue pin NUMBER
   ```

4. **Add a comment**:
   ```bash
   gh issue comment NUMBER --body "Pinned this issue for visibility — REASON."
   ```

### 4. Unpin Issue

Remove an issue from pinned status.

```bash
gh issue unpin NUMBER
gh issue comment NUMBER --body "Unpinned — REASON."
```

### 5. Transfer Issue

Move an issue to a different repository.

**Warnings**:
- The issue number will change in the destination repo
- Links and references to the old number may break
- Labels must exist in the destination repo (they are not transferred)

**Workflow**:

1. **Warn the user** about the implications

2. **Check for references** to this issue in other issues:
   ```bash
   gh issue list --search "#NUMBER" --state all --json number,title
   ```

3. **Transfer**:
   ```bash
   gh issue transfer NUMBER DESTINATION_REPO
   ```

4. **Update references** — comment on issues that referenced the old number:
   ```bash
   gh issue comment REFERENCING_NUMBER --body "Note: #OLD_NUMBER has been transferred to DESTINATION_REPO. New reference: DESTINATION_REPO#NEW_NUMBER."
   ```

## Troubleshooting

**Permission denied**:
- Lock, pin, and transfer operations require maintainer or admin access. Check permissions:
  ```bash
  gh repo view --json viewerPermission
  ```

**Pin limit reached**:
- Repos can have at most 3 pinned issues. List current pins and ask the user which to unpin.

**Transfer destination not found**:
- Verify the destination repo exists and the user has write access:
  ```bash
  gh repo view DESTINATION_REPO --json name,viewerPermission
  ```

**Labels lost after transfer**:
- Labels don't transfer between repos. After transfer, re-apply labels that exist in the destination repo.
