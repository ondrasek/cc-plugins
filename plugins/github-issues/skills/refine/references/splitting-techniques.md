---
type: reference
used_by: refine
description: Nine SPIDR techniques for splitting large user stories and epics, with examples and a meta-pattern for finding the right split.
---

# Splitting Techniques

## The Meta-Pattern

Before applying a specific technique, find the **core complexity** in the story:

1. What makes this story large?
2. Where is the uncertainty?
3. What could the team deliver first that would teach them the most?

Start with the simplest version that delivers value, then layer on complexity.

## The 9 SPIDR Techniques

### 1. Workflow Steps

**When to use**: The story describes a multi-step process.

**How**: Create one story per step in the workflow.

**Example**: "User can purchase a product"
- Story A: "User can add a product to the cart"
- Story B: "User can enter shipping address"
- Story C: "User can enter payment information"
- Story D: "User can review and confirm the order"
- Story E: "User receives order confirmation email"

### 2. CRUD Operations

**When to use**: The story involves creating, reading, updating, and deleting a resource.

**How**: Create one story per operation (or combine trivial ones).

**Example**: "Admin can manage user accounts"
- Story A: "Admin can view list of user accounts"
- Story B: "Admin can create a new user account"
- Story C: "Admin can edit user account details"
- Story D: "Admin can deactivate a user account"

### 3. Business Rule Variations

**When to use**: The story has complex conditional logic or multiple business rules.

**How**: Start with the simplest/most common rule. Add others as separate stories.

**Example**: "System calculates shipping cost"
- Story A: "System applies flat-rate domestic shipping ($5.99)"
- Story B: "System applies free shipping for orders over $50"
- Story C: "System calculates weight-based shipping for heavy items"
- Story D: "System calculates international shipping rates by country"

### 4. Data Variations

**When to use**: The story handles multiple types of input or data formats.

**How**: Start with one data type. Add others as separate stories.

**Example**: "User can import contacts"
- Story A: "User can import contacts from a CSV file"
- Story B: "User can import contacts from a vCard file"
- Story C: "User can import contacts from Google Contacts API"

### 5. Interface Complexity

**When to use**: The story has both simple and complex interface requirements.

**How**: Start with a basic interface. Enhance in subsequent stories.

**Example**: "User can search for products"
- Story A: "User can search by product name (text input)"
- Story B: "User can filter search results by category"
- Story C: "User can filter by price range with a slider"
- Story D: "User sees search suggestions as they type (autocomplete)"

### 6. Major Effort Isolation

**When to use**: One aspect of the story requires significantly more work than the others.

**How**: Isolate the hard part into its own story. Ship the easy parts first.

**Example**: "User can view a dashboard with charts and real-time data"
- Story A: "User can view a dashboard with static summary cards"
- Story B: "Dashboard displays charts for key metrics"
- Story C: "Dashboard updates in real-time without page refresh"

### 7. Simple/Complex Split

**When to use**: There's an obvious "simple version" and a "full version."

**How**: Build the simple version first. Add complexity incrementally.

**Example**: "User can configure notification preferences"
- Story A: "User can enable or disable all notifications (single toggle)"
- Story B: "User can choose notification channels (email, SMS, push)"
- Story C: "User can set per-category notification preferences"
- Story D: "User can set quiet hours for notifications"

### 8. Defer Performance

**When to use**: The story includes both functionality and performance requirements.

**How**: Make it work first, make it fast later.

**Example**: "System processes batch imports of 100,000 records"
- Story A: "System processes batch imports of up to 1,000 records"
- Story B: "System processes batch imports of 100,000+ records within 5 minutes"

### 9. Spike

**When to use**: The story has significant unknowns or requires research before implementation.

**How**: Create a time-boxed spike (research) story, then write implementation stories based on findings.

**Example**: "System integrates with third-party payment provider"
- Spike: "Research payment provider APIs and determine integration approach (2 days)"
- Story A: "System processes one-time payments via Provider" (written after spike)
- Story B: "System handles subscription billing via Provider" (written after spike)

## Choosing a Technique

| Story characteristic | Try this technique |
|---------------------|-------------------|
| Multi-step process | Workflow Steps |
| Data management feature | CRUD Operations |
| Complex business logic | Business Rule Variations |
| Multiple input formats | Data Variations |
| Rich UI requirements | Interface Complexity |
| One hard part, several easy parts | Major Effort Isolation |
| Obvious "v1" and "v2" | Simple/Complex Split |
| Includes "must be fast" requirements | Defer Performance |
| Too many unknowns to estimate | Spike |

## Validation After Splitting

After splitting, validate each resulting story:

1. **INVEST check** — each story passes all 6 criteria (see `user-story-guide.md`)
2. **Value check** — each story delivers value on its own (not just "half a feature")
3. **Size check** — each story can be completed in a single iteration
4. **Dependency check** — note any dependencies between stories, but minimize them
5. **Completeness check** — all stories together cover the original scope (nothing lost in the split)
