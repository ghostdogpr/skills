---
name: refine
description: Take working code through make it correct, make it elegant and make it fast, each a loop of reviewers and a fixer.
disable-model-invocation: true
argument-hint: <scope, and optionally what it must do, e.g. "the changes on this branch, implements RFC 6455" or "the planner module, see PR #123">
---

# Refine

Scope: $ARGUMENTS

The code already works. Refine takes it through the three steps that follow "make it work", in order:

1. **Make it correct.** Find where the code doesn't do what it is meant to, and fix it. Behavior changes here, and only here.
2. **Make it elegant.** Remove complexity and keep the behavior. Success is measured in source lines that disappear.
3. **Make it fast.** Make the hot paths do less work, and keep the behavior. Skipped when nothing in the scope is hot.

A problem that belongs to another phase is noted for that phase. A bug is the exception: whichever phase meets it fixes it, except in a diff scope a bug the diff didn't cause, which is only listed.

## Roles

- **You are the coordinator.** You never read source code, diffs or findings. You gather the user's hints, spawn one agent at a time, measure, report after every round and decide when a phase ends.
- **The fixer** is a fresh subagent for every round, never resumed. It spawns the reviewers, judges each finding, applies the ones worth it, verifies, logs and returns a short report.
- **The reviewers** only read: one per area in the correct phase, one per lens in the others, and one for each elegant or fast round's changes, for regressions.
- **The setup and final agents** prepare the run and close it.

## Scope kinds

- **An area**, such as a module, a package or a set of paths.
- **A diff**, such as pending changes, a branch or a pull request: any scope that names changes rather than code. Every phase reviews what the diff changed, not what the base already had.

## Files

The `references` folder holds the briefs: `rules.md` for every agent, `correct.md`, `elegant.md` and `fast.md` for the phases, and `setup.md`, `fixer.md`, `reviewer.md` and `final.md` for the agents. Pass their absolute paths to subagents, with the repository root and the run directory, also absolute; every agent passes both on. Run the scripts from the repository root, with the run's files by full path:

- `scripts/count-lines.sh` counts non-blank, non-comment lines: `-f <file>` reads the paths from a list file, `--at <commit>` counts them as of that commit.
- `scripts/snapshot.sh` prints the id of a commit holding the working tree, untracked files included, without touching the index or the branch. `scripts/restore.sh <commit>` puts the tree back.

The run directory is `refine/` in your scratchpad, or a temporary directory outside the repository. You read only `scoreboard.md`, the tail of `progress.log` and the agents' reports. The agents write the rest:

- `context.md`: the project facts agents need, including compatibility, hot paths and verification procedures.
- `intent.md`: the user's words on what the code should do, and where else that is written down.
- `scope.txt` and `tests.txt`: the source and test paths to count.
- for a diff scope, `diff-base.txt`, `diff.patch` and `scope-base.txt`: the base commit, the diff frozen at setup, and the scope's paths at the base, so renamed files count on both sides and deleted files on the base side.
- `areas.md`: the correct phase's areas, and which are done.
- `log.md`, `rejected.md` and `deferred.md`: every change, every rejected finding with its reason, and the notes one phase leaves for another or for the user.
- `run-base.txt` and `<label>-base.txt`: snapshots before the run and before each round.
- `scoreboard.md`, which you write, `progress.log`, one line per step from agents that run commands, and `report.md`.

Rounds are labelled by phase and number: `correct-1`, `elegant-3`, `fast-1`.

## Start

1. **Find the code.** Use the repository the scope names. For another repository, such as a link to a remote branch, use the user's local clone if it is clean, or clone it into your scratchpad. Fetch a base that lives in another remote into a local ref. Never switch the branch of a clone the user works in.
2. **Gather.** Write down every hint about what the code should do and about speed, from the invocation text and the conversation before it: a description, a pull request or issue, a protocol or RFC, a design doc, a remark that a path must be fast. Copy words and links verbatim. With no hint, write "none given".
3. **Set up.** Note the time with `date +%H:%M` and spawn one general-purpose agent with `setup.md`, the scope, the repository root, the run directory, your notes and your memory directory if you keep one. Send it back if its final verification misses a step you know the project needs.
4. **Measure.** Run `scripts/snapshot.sh > run-base.txt` and `scripts/count-lines.sh -f scope.txt`, and for a diff scope `--at $(cat diff-base.txt) -f scope-base.txt`; the difference is the diff's net size. Write the scoreboard header and row 0 with setup's duration. Tell the user in a few lines what will be refined, where its intent comes from, with the path of `intent.md` and any source setup couldn't reach, and whether "make it fast" will run. Ask setup's questions, and pass on its notes that bear on the run. Then go straight on to the first round.

## Rounds

1. Run `scripts/snapshot.sh > <label>-base.txt` and note the time.
2. Spawn one general-purpose fixer with `fixer.md` and the phase file, the repository root, the run directory, the round label and your steering note. Wait for its report, and when it still has background work running, stop it. Never run two agents that edit the tree at once.
3. Note the time. Count `scope.txt` yourself, "before" with `--at $(cat <label>-base.txt)` on the current list, and recount the diff's net size the same way.
4. Append the row to `scoreboard.md`, report, and go straight on to the next round without waiting for the user.

The user needn't know how refine works, so talk to them in plain words, naming the phases "make it correct", "make it elegant" and "make it fast", without fixers, reviewers, areas, lenses or round labels. After every round, show the whole scoreboard as one table, its columns the phase and round number, the duration in minutes, source lines before → after (and the diff's net size), and findings applied/proposed. Under it, two lines at most: what changed, in user terms, and what runs next, plus any question, any red test or `problem:` line, and a note when the round added files to the count.

A fixer that reports red tests it couldn't fix has reverted to `<label>-base.txt`: run the round again with a note naming what failed. A reverted round doesn't count toward ending a phase.

## Phases

### Correct

The fixer runs one reviewer per area of `areas.md` that isn't done. An area whose reviewer led to no fix is done, so rounds shrink, and the phase ends when every area is done.

### Elegant

The fixer runs the `constraints`, `simplicity` and `parametricity` reviewers. A lens whose reviewer led to nothing accepted is dropped for the rest of the phase: name the lenses still running in each fixer's prompt. The phase ends when no lens is left, or after a thin round: one whose net source removal is under max(5 lines, 1% of the diff's net size), or of the scope's source lines for an area scope.

### Fast

Skip this phase when `context.md` lists no hot paths. The fixer runs the `hot-paths` reviewer, and the phase ends after a round that applies no speed change: bug and regression fixes don't count.

## Finish

Spawn one general-purpose agent with `final.md`, the repository root and the run directory, and tell the user which verification steps it runs. If it returns `back to <phase>:` lines, run one round of that phase with them as the note, then the final agent again. Otherwise save the report part verbatim as `report.md`, and give the user the scoreboard, the summary and its path.

## Questions

The run never waits for the user. Never use a tool that blocks on an answer, such as a question dialog: ask in your report and keep going.

- Number the questions across the run, with the options and the pick, and say the run goes on and an answer at any time still counts. If you can notify the user, do.
- A fixer sends an urgent question as soon as it meets one: relay it at once. Don't ask it again when the report marks it `(sent)`.
- A report's `held:` count joins the open compatibility questions: say how many changes each now holds, without asking anything new.
- Write an answer under its `user:` entry in `deferred.md` as `answered: <answer>`, and in `## User corrections` of `intent.md` or `## User rules` of `context.md`. Send it to a running fixer at once with your harness's message tool (`SendMessage` to the id its spawn returned, in Claude Code), or put it in the next fixer's note. An answer that lifts a compatibility rule frees the entries that rule held back: name them too.
- If the answer's phase is over, run one round of it before the next phase or the final agent.

## While the run goes

When tooling breaks, the agent that hit it repairs it as `context.md` says. If it couldn't, repair it yourself the same way, without reading code, and rerun the step.

Add the user's corrections to what the code should do to `## User corrections` in `intent.md`, and any other correction to `## User rules` in `context.md`. If one concerns code the run already changed, the next agent that edits the tree applies it first.

When the user asks how the run is going, look first: the tail of `progress.log`, when the running agent last wrote, and the processes it started with their elapsed time. Report the step, how long it has run, and anything that looks hung, or say you can't tell. Pass on every hang, kill and tooling repair an agent reports.
