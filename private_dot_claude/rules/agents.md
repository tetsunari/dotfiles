# Agent Orchestration

## Available Agents

Located in `~/.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| code-reviewer | Code review for quality and security | After code changes, all PRs |
| doc-updater | Documentation and codemap updates | Updating docs, READMEs, codemaps |
| refactor-cleaner | Dead code cleanup and consolidation | Code maintenance, removing unused code |
| security-reviewer | Security vulnerability detection | User input handling, auth, API endpoints |
| spec-researcher | Latest specs and best practices research | Project setup, adding dependencies, config |
| web-researcher | Web search via Gemini | Latest tech info, best practices |
| review-quiz-generator | 復習問題生成 | Claude Code履歴から学習問題を生成 |

## Immediate Agent Usage

No user prompt needed:
1. Code just written/modified - Use **code-reviewer** agent
2. Security-sensitive code - Use **security-reviewer** agent
3. New library/framework setup - Use **spec-researcher** agent
4. Documentation updates needed - Use **doc-updater** agent

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth.ts
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utils.ts

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
