# skills

Agent skills I use day to day. Each one is a folder under `skills/` with a `SKILL.md` and the files it points to.

## refine

`/refine <scope>` shrinks a piece of code while it keeps every feature, fixes the bugs it finds and keeps hot paths as fast. It runs review rounds until a round finds nothing left to remove.

Each round looks at the code through three lenses, one reviewer per lens:

- **Constraints** (Rúnar Bjarnason, "Constraints Liberate, Liberties Constrain"). What freedom can we remove so fewer incorrect implementations are possible?
- **Simplicity** (Rich Hickey, "Simple Made Easy"). Which independent concerns have become entangled, and can they be understood separately?
- **Parametricity** (Philip Wadler, "Theorems for free!"). What does the type actually guarantee, and what still depends on discipline?

A change has to name what it removes, such as a runtime check, a branch, a stored field or a convention the reader had to remember. Moving or renaming code doesn't count. A bug gets a failing test and a fix in the round that finds it, and the preferred fix makes the wrong state impossible to represent.

### How a run works

The session you type `/refine` in becomes the orchestrator. It never reads code, so its context stays small however long the run gets.

1. A setup agent maps the scope and writes down how to verify it: test commands, CI configurations, conformance suites, hot paths, project conventions.
2. Each iteration is a fresh agent. It spawns three read-only reviewers, one per lens, triages their findings against the code, applies the accepted ones and runs the unit suite.
3. After each iteration, a fresh agent hunts for regressions in that iteration's diff and fixes them.
4. The orchestrator counts lines itself, prints one scoreboard row and steers the next round. When lines go up, the next round accepts nothing that grows the code. When a round removes nothing, the next one asks for redesigns only. Two empty rounds in a row end the loop.
5. A final regression sweep reviews the whole run's diff at once. Then a final agent runs the full verification (every CI configuration, conformance suites, docs build) and writes the report.

All run state lives in a scratch directory outside the repository: the scoreboard, a change log, rejected findings with their reasons, regression verdicts and a progress log.

### Scope

The scope is free text. It is one of two kinds:

- **An area**, such as `/refine the query planner` or `/refine src/parser`. Changes may reach past the area when that removes more, for example a contract change across its callers.
- **A diff**, such as `/refine the changes on this branch`, `/refine pending changes` or `/refine PR 123`. Only the lines the diff added or changed are open to change. The code around them stays as it is.

### Requirements

- A git repository. The skill snapshots the working tree with git plumbing and never touches your index or branch.
- An agent that supports skills and subagents. I use it with Claude Code. Other agents that read `SKILL.md` folders may work, but I haven't tested them.
- A test suite. The loop is only as safe as the tests that check each step.

A run spawns many subagents and can take hours on a large scope, so it uses a lot of tokens. Start with a small scope, or a diff scope, to get a feel for it.

### Tell it about your project

The setup agent reads your project's agent instructions (`AGENTS.md`, `CLAUDE.md` or similar), its contributing guide and its CI configuration. Put these there and every run picks them up:

- how to run the unit suite, and how long it normally takes;
- the full verification: every configuration CI builds, conformance or audit suites, the docs build, compatibility checks;
- how to repair the build tooling when it hangs;
- whether the public API is free to change;
- conventions for comments, doc comments and test layout.

While a run goes, you can still correct it. The orchestrator writes your correction into the run's context, so every later agent follows it.

## Install

Clone the repository and link the skill into your skills directory. For Claude Code:

```sh
git clone https://github.com/ghostdogpr/skills.git
ln -s "$PWD/skills/skills/refine" ~/.claude/skills/refine
```

Use `.claude/skills/` inside a project instead to install it for that project only.
