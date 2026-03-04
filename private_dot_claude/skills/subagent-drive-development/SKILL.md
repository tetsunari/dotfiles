---
name: subagent-drive-development
description: Use when executing implementation plans with independent tasks in the current session or facing 3+ independent issues that can be investigated without shared state or dependencies - dispatches fresh subagent for each task with code review between tasks, enabling fast iteration with quality gates
context: fork
---

# Subagent-Driven Development

Create and execute plan by dispatching fresh subagent per task or issue, with code and output review after each or batch of tasks.

**Core principle:** Fresh subagent per task + review between or after tasks = high quality, fast iteration.

Executing Plans through agents:

- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Code review after each or batch of task (catch issues early)
- Faster iteration (no human-in-loop between tasks)

## Supported Types of Execution

### Sequential Execution

When you have tasks or issues that are related to each other and need to be executed in order. Dispatch one agent per task or issue, review output after each.

**When to use:** Tasks are tightly coupled or must be executed in order.

**Process summary:** Load plan -> create TaskCreate/TaskUpdate with all tasks -> for each task, dispatch fresh subagent -> dispatch code-reviewer -> apply feedback -> mark complete -> repeat -> final review -> complete development branch cleanup.

### Parallel Execution

When you have multiple unrelated tasks or issues (different files, different subsystems, different bugs), investigating or modifying them sequentially wastes time. Each task is independent and can happen in parallel.

**When to use:** Tasks are mostly independent and overall review can be done after all tasks are completed.

**Process summary:** Load and review plan critically -> execute tasks in batches (default: first 3) -> report for review between batches -> apply feedback -> continue until complete -> complete development branch cleanup.

### Parallel Investigation

Special case of parallel execution for multiple unrelated failures that can be investigated without shared state or dependencies.

**When to use:** 3+ independent failures across different files/subsystems.

**Process summary:** Group failures by independent domain -> create focused agent tasks with specific scope, clear goal, constraints, and expected output -> dispatch in parallel -> review and integrate results -> run full test suite.

See `references/execution-examples.md` for full process details, step-by-step instructions, prompt templates, and examples.

## Red Flags

**Never:**

- Skip code review between tasks
- Proceed with unfixed Critical issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Implement without reading plan task

**If subagent fails task:**

- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

**For Parallel Investigation - common mistakes:**

- Too broad scope ("Fix all the tests") - agent gets lost
- No context (missing error messages and test names)
- No constraints (agent might refactor everything)
- Vague output expectations ("Fix it")

**When NOT to use Parallel Investigation:**

- Related failures (fixing one might fix others)
- Need full context (understanding requires seeing entire system)
- Exploratory debugging (you don't know what's broken yet)
- Shared state (agents would interfere editing same files)
