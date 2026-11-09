# skills

Agent skills I use day to day.

## refine

`/refine` improves code that already works: it fixes the bugs your tests missed, removes complexity, and speeds up the parts that need it. Point it at some code or a branch, let it run on its own, and you get back uncommitted changes and a report of what changed and why.

```
/refine the changes on this branch
/refine the query planner, see PR #123
```

The idea comes from the old advice "make it work, make it right, make it fast". Once code works, improving it is three jobs that get in each other's way: they have different goals and different ways of knowing you're done, and a single pass does each of them halfway. So refine gives each one its own phase:

1. **Make it correct.** Find where the code doesn't do what it is meant to, and fix it. Behavior changes here and only here. A bug counts when a failing test reproduces it.
2. **Make it elegant.** Same behavior, less code. Success is source lines that disappear, found through three lenses:
   - **Constraints** (Bjarnason, "Constraints Liberate, Liberties Constrain"). What freedom can we remove so fewer incorrect implementations are possible?
   - **Simplicity** (Hickey, "Simple Made Easy"). Which independent concerns have become entangled?
   - **Parametricity** (Wadler, "Theorems for free!"). What does the type guarantee, and what still depends on discipline?
3. **Make it fast.** Same behavior, less work per call on the hot paths, and nowhere else. Skipped when nothing in the scope is hot.

The order matters: there is no point simplifying behavior that is wrong, and speedups are easier to find in simple code.

Each phase repeats until there is nothing left worth doing, with your tests run along the way.

### What you tell it

**What to refine.** Either a part of the code (`/refine the query planner`) or a set of changes (`/refine the changes on this branch`). With a set of changes, refine stays on those lines: bugs that were already there are listed at the end but not fixed, and other code is changed only where those lines require it.

**What the code should do.** Optional, and often the most useful thing you can add: a sentence, a pull request link, the name of a protocol it implements.

**Decisions along the way.** Refine never stops to wait for you. When a choice is really yours, such as whether a public API may change, it asks in its progress updates with its own pick and keeps going. Answer any time and the next round applies it, or leave it for the final report.

### What it needs

A git repository, a test suite, and an agent that can start subagents (I use Claude Code). It reads your `AGENTS.md` or `CLAUDE.md` to learn how to build and test your project.

## Install

```sh
git clone https://github.com/ghostdogpr/skills.git
ln -s "$PWD/skills/skills/refine" ~/.claude/skills/refine
```
