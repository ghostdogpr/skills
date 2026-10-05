---
name: refine
description: Refine a scope of code through constraints, simplicity and parametricity reviews until it converges on a smaller design, keeping features and speed.
disable-model-invocation: true
argument-hint: <scope, e.g. "the planner module" or "the changes on this branch">
---

# Refine

Scope: $ARGUMENTS

Success is measured in lines that disappear while every feature stays, every bug found gets fixed and no hot path gets slower. A bug shows where the design lets a wrong state through, and the best fix takes that state away.

## Roles

A run has three roles, and each works in its own context.

- **You are the orchestrator.** You never read source code, diffs or review findings. You set up the run, spawn one iteration agent at a time, measure the scope after each one, report the numbers and decide when to stop. This keeps your context small for the whole run.
- **The iteration agent** is a fresh subagent for every iteration. It spawns the three lens reviewers, triages their findings, applies and verifies the accepted ones, logs them and returns a short report. Spawn a new one each time and never resume a previous one, so no iteration inherits the last one's line of thought.
- **The lens reviewers** are three read-only subagents per iteration, one per lens. The iteration agent spawns them.

## Scope kinds

The scope is one of two kinds, and the setup agent records which in `context.md`.

- **An area**, such as a module, a package or a set of paths. Changes may reach past it when the removal is worth it.
- **A diff**, such as pending changes, a branch or a pull request. Only the lines the diff added or changed are open to change, and the code around them stays as it is. Treat any scope that names changes rather than code as a diff.

## Files

The skill's folder holds the briefs. Pass their absolute paths to the subagents, since subagents don't know where this skill lives.

- `references/rules.md` has the rules every agent follows.
- `references/iteration.md` is the iteration agent's brief.
- `references/reviewer.md` is the lens reviewers' brief, with the three lenses.
- `references/regressions.md` is the brief for the regression passes.
- `references/final.md` is the brief for the final verification and report.
- `scripts/count-lines.sh` counts non-blank, non-comment lines. With `--at <commit>` it counts the files as they are in that commit.
- `scripts/snapshot.sh` prints the id of a commit holding the current working tree, untracked files included, without touching the index or the branch. Run it from the repository root.
- `scripts/restore.sh <commit>` puts the working tree back to such a snapshot, untracked files included, and leaves the index and the branch alone. Agents revert with it.

The run's state lives in a `refine/` directory in your scratchpad, or in a temporary directory outside the repository if you have no scratchpad. The agents write it, and you read only `scoreboard.tsv`, the tail of `progress.log` and the reports they return.

- `run-base.txt` holds a snapshot of the tree when the run starts. The final regression sweep diffs against it.
- `iter<N>-base.txt` holds a snapshot of the tree before iteration N. The regression passes diff against it.
- `context.md` holds the scope kind, the scope's files, their consumers, the specs the scope implements, the hot paths, the project's conventions and the verification procedures. The setup agent writes it.
- `diff-base.txt` and `diff.patch` exist for a diff scope only. They hold the commit the diff starts from and the diff itself, frozen at setup.
- `scope.txt` lists the paths to count, one per line. Agents add files split out of the scope to it.
- `scoreboard.tsv` gets one row per iteration. You write it.
- `progress.log` gets one line per step from every agent, so you can tell a slow step from a hung one.
- `log.md` has each iteration's changes and what they removed. Iteration agents append to it.
- `rejected.md` has one line per rejected finding with its reason, so no reviewer proposes it again.
- `regressions.md` has one line per regression candidate with its verdict, so no later pass reports it again.
- `report.md` is the final report. The final agent returns it, and you save it.

## Loop

1. **Setup.** Spawn one general-purpose subagent with the scope, the run directory, the path of `references/rules.md` and the path of your memory directory if you keep one, since subagents don't see your memory. It reads the project's agent instructions (`AGENTS.md`, `CLAUDE.md` or similar), its contributing guide, its CI configuration and the memory notes that bear on the scope. Then it writes `scope.txt` and `context.md`, plus `diff-base.txt` and `diff.patch` for a diff scope. `context.md` holds:
   - the scope kind, and for a diff scope how to read the frozen diff;
   - the hot paths in the scope: code that runs per request, per entity, per item or per field;
   - whether the public API is free to change, which holds only when the project's instructions say so or the code is unreleased;
   - the conventions a change must follow: formatting, imports, comment and doc-comment style, test layout;
   - full verification procedures, not just command names: running the unit suite, repairing the build tooling, and every step of the final verification, including each conformance or audit suite and every configuration CI builds. Each procedure records its normal duration, so agents can size their timeouts.

   The agent returns the paths in `scope.txt` and a one-line list of the final verification steps. Send it back if the list misses something you know the project needs. Then run `scripts/snapshot.sh > run-base.txt` and `scripts/count-lines.sh $(cat scope.txt)`, and write row 0 of the scoreboard. For a diff scope, also run `scripts/count-lines.sh --at $(cat diff-base.txt) $(cat scope.txt)` once. The difference between the two totals is the diff's net size, and each row records it. When you tell the user setup is done, give the scope's size and leave the verification steps out.
2. **Iterate.** Run `scripts/snapshot.sh > iter<N>-base.txt`, then spawn one general-purpose iteration agent. Its prompt names `references/iteration.md` and `references/rules.md` by absolute path, along with the run directory, the iteration number, the count-lines script path, the last three scoreboard rows, and your steering note if you have one. Wait for its completion notification. Never run two agents that edit the tree at once, because they share the working tree and the build tooling.
3. **Check for regressions.** Spawn one general-purpose regression agent. Its prompt names `references/regressions.md` and `references/rules.md` by absolute path, along with the run directory, the pass label `<N>.<k>`, the base file `iter<N>-base.txt` and the count-lines script path. A fresh agent reviews the iteration because the iteration agent is biased toward its own changes. If it confirms a regression, spawn another fresh one for pass `<N>.<k+1>`, and repeat until a pass confirms none. If a pass reports red tests it couldn't fix, run it again with a note naming what failed.
4. **Measure.** Count the lines yourself with the script instead of trusting the report's number, and append the scoreboard row. Count the "before" with `--at $(cat iter<N>-base.txt)` on the current `scope.txt`, so files an iteration added to it count on both sides.
5. **Report.** Go straight on to steer and spawn the next iteration in the same turn, without asking the user anything. The message that ends that turn is the iteration's report, and it always holds the whole scoreboard as a Markdown table, header and every row so far. The columns are iteration, lines before → after (and the diff's net size for a diff scope), findings proposed/accepted per lens, bugs fixed, regressions confirmed/fixed across the iteration's passes, and the test result. Under the table, write one line naming the iteration's largest removal and any tooling problem the reports name, such as a hung command or a repaired build server, then one line saying the next iteration is running and with which steering note. A one-line "iteration N is running" is not a report: this table is the user's only view of the run.
6. **Steer from the numbers.** The next iteration's note is your only lever.
   - If lines rose in the last iteration by more than the test lines its bug fixes added, the next note says: "The scope grew last iteration. This round accepts nothing that adds net lines, except a real bug fix with no structural alternative. Find the mechanism that absorbs the growth."
   - If the report says no accepted change removed lines, the next note says: "The last round found no removal. Reviewers propose only redesigns: a different core model, merged passes, a deleted module or a changed contract. No local cleanups." If that round is empty too, the loop has converged.
   - If an iteration reports red tests it couldn't fix, it reverted to `iter<N>-base.txt`. Run the iteration again with a note naming what failed.
7. **Sweep for regressions.** Once the loop converges, spawn a fresh regression agent with the base file `run-base.txt` and the pass label `final.<k>`, so one reviewer sees the whole run's diff at once. Bugs that come from two iterations interacting only show up here. Repeat with a fresh agent until a pass confirms none.
8. **Finish.** Spawn one general-purpose final agent with `references/final.md`, `references/rules.md` and the run directory, and tell the user which verification steps it runs. It runs the final verification and returns a summary followed by the full report. If it sends findings back into the loop, run more iterations, sweep again and finish again. Otherwise save the report part verbatim as `report.md` in the run directory, then give the user the scoreboard table, the summary and the path to `report.md`.

The scoreboard shows progress and sets no quota. Keep going as long as the iterations find real removals.

When tooling breaks, such as a dead build daemon, the agent that hit it repairs it the way `context.md` says. If an agent reports that it couldn't, repair it yourself the same way, without reading code, and rerun the step.

## While the run goes

When the user corrects something during the run, add the correction to a `## User rules` section in `context.md`, so every later agent reads it. If it concerns code the run already changed, the next agent that edits the tree applies it before its own work.

When the user asks how the run is going, look before you answer. Read the tail of `progress.log`, check when the running agent last wrote anything, and list the processes it started with their elapsed time. Report what you saw: the step, how long it has been running against its normal duration, and anything that looks hung. If you can't tell, say so. Pass on every hang, kill and tooling repair that an agent reports.
