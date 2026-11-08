# skills

Agent skills I use day to day.

## refine

`/refine <scope>` takes code that already works through the three steps after "make it work", each a loop of reviewers and a fixer:

1. **Correct.** Reviewers check the code against what it is meant to do, from your words and the pull requests and docs setup lists, one per area, which setup picks along the code's modules and concerns, splitting any over about 1,000 lines, up to five, each reading its area from that intent and bottom-up from the inputs callers can produce. The fixer fixes each bug it can reproduce with a failing test, and keeps the test only when nothing else would catch the bug coming back. A reviewer that finds nothing worth fixing isn't run again, so rounds shrink until no reviewer is left.
2. **Elegant.** Three reviewers look for less code with the same behavior, through one lens each:
   - **Constraints** (Bjarnason, "Constraints Liberate, Liberties Constrain"). What freedom can we remove so fewer incorrect implementations are possible?
   - **Simplicity** (Hickey, "Simple Made Easy"). Which independent concerns have become entangled?
   - **Parametricity** (Wadler, "Theorems for free!"). What does the type guarantee, and what still depends on discipline?

   A lens whose reviewer finds nothing worth applying isn't run again. Rounds continue until no lens is left or they stop removing code.
3. **Fast.** One reviewer looks for work to take off the hot paths, and only those. Skipped when nothing in the scope is hot.

Each phase has one goal. The fixer rejects findings that aren't real or aren't worth it, and has its own changes reviewed for regressions before it verifies a round. A problem that belongs to another phase is noted for that phase rather than fixed, except a bug, which is fixed wherever it turns up. What the code is meant to do and the hot paths come from what you pass along with the scope, such as a sentence, a pull request link or a protocol name, from the conversation if there is one, and from the repository for the rest. When a decision is really yours, the run asks it in its round report and keeps going: answer any time and the next round applies it, or leave it for the final report. A final pass runs your full verification and writes a report.

The scope can be an area (`/refine the query planner`) or a diff (`/refine the changes on this branch`), which only touches the lines the diff changed. In a diff, every phase stays on what the diff changed: bugs the base already had are listed at the end, not looked for or fixed, and older complexity or slow code is left alone.

It needs a git repository, a test suite, and an agent with subagents (I use Claude Code). Runs are long and spawn many agents, so start with a small scope. The setup agent reads your `AGENTS.md` or `CLAUDE.md` to learn how to build and test your project.

## Install

```sh
git clone https://github.com/ghostdogpr/skills.git
ln -s "$PWD/skills/skills/refine" ~/.claude/skills/refine
```
