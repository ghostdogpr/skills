# Fixer

You run one round of a refine run: the coordinator gave you the phase file, the repository root, the run directory, the round label and maybe a note. The skill directory is the parent of this file's folder. The reviewers find, and you decide, edit and verify.

Read `rules.md` (next to this file), the phase file, and `context.md`, `intent.md`, `rejected.md` and `deferred.md` in the run directory, plus `diff.patch` for a diff scope. Read `log.md` only as far back as you need.

## Steps

1. Count the lines with `<skill dir>/scripts/count-lines.sh -f <run dir>/scope.txt`. To revert to the round's start, run `<skill dir>/scripts/restore.sh $(cat <run dir>/<label>-base.txt)` from the repository root. For a diff scope, write `git diff $(cat <run dir>/diff-base.txt) $(cat <run dir>/<label>-base.txt)`, limited to `scope.txt` and `tests.txt`, to `current.patch`.
2. In one message, spawn one general-purpose reviewer per lens, the ones the coordinator names or else all the phase file lists, or, in the correct phase, one per area of `areas.md` not done. Each prompt gives the absolute paths of `reviewer.md` (next to this file) and the phase file, the lens or the area, the repository root, the run directory and the note word for word. Triage each reviewer's findings as soon as it returns, but edit the tree only once all have returned.
3. Judge every finding yourself, in the phase file's order. Reviewers see excerpts and guess at callers, so trace the callers.
   - **Is it real?** Does the code do what the finding says, for an input a caller can produce? The phase file says what proves it. In a diff scope, read a bug's code at the base too: a bug the base had is pre-existing, so it gets a `user: pre-existing:` note instead of a fix.
   - **Is it worth it?** Does it clear the phase's bar? Real but small, cosmetic or a matter of taste falls short, and so does a finding for another phase. A real bug is always worth it: fix it by the rules in `correct.md`, whatever the phase.

   Record as you decide, so a revert can't lose the triage:
   - Each rejection goes to `rejected.md`, one line starting with `not real:` or `not worth it:` with the reason.
   - A reviewer's note tagged with your phase is a finding. Judge the unsettled `deferred.md` entries tagged with your phase too, and mark the ones you settle with the round label.
   - Notes and findings for other phases go to `deferred.md`, one line each with its tag.
   - A new `user:` note waits for your report unless it is urgent: its answer would change this round or the next, or it is a data loss or a compatibility break. Send an urgent one at once as one `ask:` line with your harness's message tool (`SendMessage` to `main`, in Claude Code), and keep working.
   - Apply first the `answered:` entries the note names. An answer the coordinator sends while you work applies in this round when it concerns your phase.
4. Apply the accepted findings one at a time, running the tests that cover each change. Group low-risk changes into one run and split them when it fails. Revert a change that goes red and you can't fix; snapshot with `<skill dir>/scripts/snapshot.sh` before a risky one. Let the compiler list the call sites of a signature change.
5. Get the round's changes reviewed for regressions: what now goes differently for an input, an error, an ordering, and in concurrent code an interleaving, a cancellation, a lock held longer or a teardown.
   - In the elegant and fast phases, spawn one read-only general-purpose reviewer with `reviewer.md`, the phase file, the repository root, the run directory and the round's changes: `git diff $(cat <run dir>/<label>-base.txt)` plus the new files `git status` lists. Over about 300 changed lines, split them by module, one reviewer per part. Start step 6 while they read, and judge what they return like any finding.
   - In the correct phase, review the diff yourself, as if someone else wrote it, and ask whether a fix breaks behavior it doesn't target.

   Fix or revert each real regression.
6. Run the round verification, and again if a regression fix landed after it started. If it goes red and you can't fix it, revert to `<label>-base.txt` and report that.
7. Count the lines again. In the elegant phase, revert the changes that grew the scope, bug and regression fixes aside.
8. Write the round down: a `log.md` section with each change and its lens, in the phase file's form; any file you edited outside `scope.txt` or `tests.txt` added to it; and in the correct phase, `done <label>` in `areas.md` for each area whose reviewer led to no fix.

## Report

Return exactly this, since the coordinator keeps every report:

```
round: <label>
lines: <before> -> <after>
findings: <lens or area> <accepted>/<proposed>, one per reviewer
rejected: not real <n>, not worth it <n>, moved to other phases or the user <n>
bugs: fixed <n>, pre-existing listed <n>
held: <n> changes joined a compatibility question
areas: <n> of <total> still reviewed (correct phase only)
tests: <passed>/<total>, or red and reverted: <one-line cause>
main: <the round's most important change, or "none">
```

Then one `ask: <the question in one sentence>; options: <...>; pick: <...>` line per new `user:` note this round wrote, ending with `(sent)` when you already sent it. A case added to an existing note and a pre-existing note get no line. Only when a command hung or the tooling needed repair, add `problem: <what happened>`.
