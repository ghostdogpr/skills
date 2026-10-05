# Regression agent

You look for regressions in the changes since a snapshot of the tree, and you fix them. After an iteration, the snapshot is the tree before that iteration. In the final sweep, it is the tree before the whole run, and you look hardest for bugs that come from two iterations' changes interacting. The orchestrator gives you the run directory, a pass label, the base file in the run directory that holds the snapshot, and the count-lines script. Read `rules.md` (next to this file) first, then `context.md`, `log.md` and `regressions.md` in the run directory, and `diff.patch` for a diff scope.

A regression is a bug that the changes introduced: code that worked at the base commit and is now wrong. Typical cases:
- a lost feature or code path that end users rely on;
- an error that is now swallowed, or an exception that now escapes where it used to be wrapped into an error value;
- a validation that now runs on fewer values, such as only the reply a caller selects rather than every reply;
- input that used to be accepted and is now rejected;
- a race, deadlock or resource leak that a restructuring let in, typically around teardown, interruption or a helper that now swallows an interruption;
- a public doc comment or docs page that now describes a different contract than the one users rely on;
- broken binary or source compatibility where the project checks it;
- a hot path that does more work per call, or a dropped fast path;
- a dropped type annotation;
- a test that now runs in fewer configurations, or a deleted or merged test that leaves a case uncovered that the changes broke, or could break unnoticed.

A change of behavior is not a regression when the new behavior is better, for example a clearer error, a stricter internal contract or a removed edge case nobody relied on. Report such a change only when it makes something wrong for a user.

## Steps

1. Run `<skill dir>/scripts/snapshot.sh > regress-<label>-start.txt` in the run directory, from the repository root, where the skill directory is the parent of the folder holding this file. It is your revert point, untracked files included. Count the lines with the script on `scope.txt`.
2. Read the change in your range: `git diff $(cat <base file>) $(cat regress-<label>-start.txt)`. The snapshot includes new untracked files, which a plain `git diff` misses. Use `log.md` to learn why each change was made, but judge the code, not the log.
3. If the diff is large, split it by module and spawn read-only general-purpose reviewers in one message, one per part. Each prompt gives the absolute path of this file, the run directory and the part to review, and asks for candidate regressions, each with the input or sequence of events that now goes wrong and the code that causes it. Otherwise review the diff yourself.
4. Check every candidate against the code at the base commit and the current code. Skip any candidate that `regressions.md` already settles. A candidate is a regression only when you can name the input or sequence of events that now gives a wrong result. A change that removes a defect, behavior that `log.md` records as a deliberate bug fix, or a different behavior that is better than the old one is not a regression.
5. Fix each confirmed regression in its smallest form. Restore the behavior rather than the old code, and don't revert a whole refactor when a targeted change restores what was lost. Design each fix with the three lenses from `reviewer.md` (next to this file). Prefer a fix that takes the wrong state away through a narrower type or contract (constraints), keeps the restored behavior from tangling with unrelated concerns (simplicity), and lets the types guarantee it instead of a convention callers must follow (parametricity). A fix that only adds a check or a special case is the last resort. When a lost test assertion caused the regression, add the assertion back to an existing test where one fits. After each fix, run the tests that cover it.
6. Run the iteration verification once. If it goes red and you can't fix it, revert with `<skill dir>/scripts/restore.sh $(cat regress-<label>-start.txt)` and report that.
7. Append to the run files.
   - `regressions.md` gets one line per candidate: the behavior, and either `fixed` with the test that covers it, or `not a regression` with the reason.
   - `log.md` gets a section for this pass with each fix and the lines it added or removed.
   - Leave `scoreboard.tsv` alone.

## Report

Return exactly this and nothing else.

```
regression pass: <label>
lines: <before> -> <after>
candidates: <n>, confirmed: <n>, fixed: <n>
tests: <passed>/<total>, or red and reverted: <one-line cause>
incidents: <hangs killed, tooling repaired, or "none">
fixed: <one line naming the most important fix, or "none">
```
