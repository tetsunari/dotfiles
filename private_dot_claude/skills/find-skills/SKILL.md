---
name: find-skills
description: This skill should be used when the user asks "how do I do X", "find a skill for X", "is there a skill for X", "can you do X", or expresses interest in extending agent capabilities, discovering tools, templates, or workflows from the open skills ecosystem.
---

# Find Skills

Discover and install skills from the open agent skills ecosystem to extend agent capabilities with specialized knowledge, workflows, and tools.

## When to Activate

- The user asks "how do I do X" where X might be a common task with an existing skill
- The user says "find a skill for X" or "is there a skill for X"
- The user asks "can you do X" where X is a specialized capability
- The user expresses interest in extending agent capabilities
- The user wants to search for tools, templates, or workflows
- The user mentions needing help with a specific domain (design, testing, deployment, etc.)

## Skills CLI Overview

The Skills CLI (`npx skills`) is the package manager for the open agent skills ecosystem. Skills are modular packages that extend agent capabilities with specialized knowledge, workflows, and tools.

### Core Commands

| Command | Description |
|---------|-------------|
| `npx skills find [query]` | Search for skills interactively or by keyword |
| `npx skills add <package>` | Install a skill from GitHub or other sources |
| `npx skills add <package> -g -y` | Install globally, skip confirmation |
| `npx skills remove [skills]` | Remove installed skills |
| `npx skills list` | List installed skills |
| `npx skills check` | Check for skill updates |
| `npx skills update` | Update all installed skills |
| `npx skills init [name]` | Initialize a new skill |

**Browse skills at:** https://skills.sh/

### Installation Options

| Flag | Description |
|------|-------------|
| `-g, --global` | Install at user-level instead of project-level |
| `-a, --agent <agents>` | Specify target agents (use `*` for all) |
| `-s, --skill <skills>` | Specify skill names (use `*` for all) |
| `-y, --yes` | Skip confirmation prompts |
| `--all` | Shorthand for `--skill '*' --agent '*' -y` |

## Skill Discovery Workflow

### Step 1: Identify the Need

When a user asks for help, identify:

1. **Domain** - e.g., React, testing, design, deployment
2. **Specific task** - e.g., writing tests, creating animations, reviewing PRs
3. **Likelihood of existing skill** - common tasks likely have skills available

### Step 2: Search for Skills

Run the find command with a relevant query:

```bash
npx skills find [query]
```

Query mapping examples:

| User Request | Search Query |
|--------------|-------------|
| "How do I make my React app faster?" | `npx skills find react performance` |
| "Can you help me with PR reviews?" | `npx skills find pr review` |
| "I need to create a changelog" | `npx skills find changelog` |
| "Help me with TypeScript types" | `npx skills find typescript` |
| "I want better testing" | `npx skills find testing` |
| "Help with deployment" | `npx skills find deploy` |

### Step 3: Present Results

When relevant skills are found, present each with:

1. The skill name and what it does
2. The install command
3. A link to learn more at skills.sh

Response template:

```
Found a skill that might help:

**[skill-name]** - [brief description]

Install: `npx skills add <owner/repo@skill>`
Details: https://skills.sh/<owner/repo/skill>
```

### Step 4: Install on Request

If the user wants to proceed, install the skill:

```bash
npx skills add <owner/repo@skill> -g -y
```

- `-g` installs globally (user-level)
- `-y` skips confirmation prompts

After installation, verify with `npx skills list -g`.

## Common Skill Categories

| Category | Example Queries |
|----------|----------------|
| Web Development | react, nextjs, typescript, css, tailwind |
| Testing | testing, jest, playwright, e2e, vitest |
| DevOps | deploy, docker, kubernetes, ci-cd |
| Documentation | docs, readme, changelog, api-docs |
| Code Quality | review, lint, refactor, best-practices |
| Design | ui, ux, design-system, accessibility |
| Productivity | workflow, automation, git |
| Database | sql, postgres, prisma, drizzle |
| Security | auth, security, encryption |
| AI/ML | prompt, llm, agent, embeddings |

## Search Tips

1. **Use specific keywords** - "react testing" is better than just "testing"
2. **Try alternative terms** - If "deploy" yields no results, try "deployment" or "ci-cd"
3. **Check popular sources** - Many skills come from:
   - `vercel-labs/agent-skills`
   - `vercel-labs/next-skills`
   - `anthropics/skills`
   - `obra/superpowers`
4. **Combine domain + task** - "nextjs performance", "typescript advanced types"

## When No Skills Are Found

If no relevant skills exist:

1. Acknowledge that no existing skill was found
2. Offer to help with the task directly using general capabilities
3. Suggest creating a custom skill if the task is recurring

Response template:

```
No skills found for "[query]".
Proceeding with general capabilities to help directly.

For recurring tasks, consider creating a custom skill:
  npx skills init my-skill-name
```

## Creating Custom Skills

When a user wants to create their own skill:

```bash
npx skills init <skill-name>
```

This creates a `<skill-name>/SKILL.md` template. A valid skill requires:

1. **YAML frontmatter** with `name` and `description`
2. **Markdown body** with instructions and workflows

Minimal structure:

```
skill-name/
└── SKILL.md
```

Standard structure:

```
skill-name/
├── SKILL.md
├── references/
│   └── detailed-guide.md
└── examples/
    └── working-example.sh
```

### SKILL.md Format

```yaml
---
name: skill-name
description: This skill should be used when the user asks to "specific phrase 1", "specific phrase 2". Provide concrete trigger phrases.
---

# Skill Title

[Core instructions in imperative form, 1,500-2,000 words]

## Additional Resources

- **`references/patterns.md`** - Detailed patterns
- **`examples/example.sh`** - Working example
```

### Key Guidelines

- **Description**: Use third-person with specific trigger phrases
- **Body**: Write in imperative/infinitive form, not second person
- **Size**: Keep SKILL.md lean (1,500-2,000 words), move details to `references/`
- **Progressive disclosure**: Core concepts in SKILL.md, details in references/
