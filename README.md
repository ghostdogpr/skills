# skills

Agent skills I use day to day.

## refine

`/refine <scope>` shrinks code while keeping every feature and hot-path speed, and fixes the bugs it finds along the way. Each round, three reviewers look at the code through one lens each:

- **Constraints** (Bjarnason, "Constraints Liberate, Liberties Constrain"). What freedom can we remove so fewer incorrect implementations are possible?
- **Simplicity** (Hickey, "Simple Made Easy"). Which independent concerns have become entangled?
- **Parametricity** (Wadler, "Theorems for free!"). What does the type guarantee, and what still depends on discipline?

A fresh agent applies the accepted findings, another checks them for regressions, and rounds continue until one finds nothing to remove. A final pass runs your full verification and writes a report.

The scope can be an area (`/refine the query planner`) or a diff (`/refine the changes on this branch`), which only touches the lines the diff changed.

It needs a git repository, a test suite, and an agent with subagents (I use Claude Code). Runs are long and spawn many agents, so start with a small scope. The setup agent reads your `AGENTS.md` or `CLAUDE.md` to learn how to build and test your project.

## Install

```sh
git clone https://github.com/ghostdogpr/skills.git
ln -s "$PWD/skills/skills/refine" ~/.claude/skills/refine
```
