---
name: conejo
description: arthrod's coding philosophy and dispatcher. Universal red-green TDD, stacked PRs, test-always, evidence-before-claims. Routes to conejo-code (active coding), conejo-frontend (strict UI), conejo-merge (calm PR/merge). Use when starting any coding work or deciding how to approach a task.
---

# Conejo — the coding philosophy

Conejo is how we build. It is small on purpose: it states the non-negotiables and
routes you to the focused skill for the task at hand.

## Non-negotiables

1. **Red-green TDD, always — backend and frontend alike.** Write the failing test,
   watch it fail for the right reason, write the minimum to pass, refactor under green.
   No implementation before a failing test. See [[test-driven-development]].
2. **Test always. No exceptions.** If you cannot write a test, you do not yet
   understand the problem.
3. **Stacked PRs.** Branch over branch; PR often; each PR over its predecessor.
4. **Brainstorm before building** anything non-trivial. See [[brainstorming]].
5. **Debug systematically**, never by guessing. See [[systematic-debugging]].
6. **Evidence before claims.** Never say "done/fixed/passing" without running the
   verification and showing output. See [[verification-before-completion]].

## Dispatch

| You are… | Use |
|---|---|
| Writing/changing code (logic, services, APIs, libraries, CLIs) | **[[conejo-code]]** |
| Building or changing any web UI | **[[conejo-frontend]]** (strict; it includes the conejo-code base) |
| Reviewing, interrogating, implementing, or merging PRs | **[[conejo-merge]]** |

The testing doctrine is authored once in `conejo-code/references/testing-doctrine.md`;
conejo-frontend adds the UI superset. Read the doctrine before writing any test.

## Example
- Brainstorm (Specs) → run "opencode run $PROMPT --model zai-coding-plan/glm-5.1 --dangerously-skip-permissions --dir  path/to/this/dir" to review your specs → Plan "opencode run $PROMPT --model deepseek/deepseek-v4-pro --dangerously-skip-permissions --dir  path/to/this/dir" to review your plan (glm-5.1 is smarter but slow, deepseek is a bit faster) → Interface → "opencode run $PROMPT --model deepseek/deepseek-v4-pro --dangerously-skip-permissions --dir  path/to/a/clone/of/this/dir" to create tests **failing tests** → "opencode run $PROMPT --model deepseek/deepseek-v4-pro --dangerously-skip-permissions --dir  path/to/a/clone/of/this/dir" to Implement → Improve tests → Code review  → (loop).
- Full stage notes: `references/feature-stages.md`. UI stages (design/UIUX-review) and any
visual work are owned by [[conejo-frontend]].
- Attention! Don't be afraid of sending several agents: split the tasks as much as possible. 
- PR over PR ALWAYS. Push. After it is at Github, clean their mess.
- PRESERVE your context no matter what! Send these other agents first, so we can have different perspectives, but if you need to do the work, send your agents. Don't pollute your context.
