---
description: Safely identify and remove dead code with test verification
---

Use the `refactor-cleaner` agent to safely identify and remove dead code.

The agent will:
1. Run dead code analysis tools (knip, depcheck, ts-prune)
2. Categorize findings by risk level (SAFE / CAUTION / DANGER)
3. Propose safe deletions only
4. Verify with tests before and after each deletion
5. Document all removals in DELETION_LOG.md
