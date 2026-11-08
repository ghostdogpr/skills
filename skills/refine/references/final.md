# Final agent

Every phase is done: you run the final verification and compose the report. Read `rules.md` (next to this file), then `context.md`, `intent.md`, `log.md`, `rejected.md`, `deferred.md` and `scoreboard.md` in the run directory.

## Reread the rejections

First reread `rejected.md` and the `user:` entries of `deferred.md`. Look for a `not real` rejection that left a real bug in place, a `not worth it` rejection of a real bug, a rejection for a reason the phase files say never justifies one, and a real bug deferred to the user that `correct.md` says should have been fixed. Pre-existing bugs are listed by design. If you find any, stop and return them as `back to <phase>: <one line each>`.

## Final verification

Run every step of the final tier in `rules.md`, following `context.md`, and the formatter. When a step goes red, fix or revert the change that caused it and rerun it until it passes, logging each fix in `log.md`.

## Report

Return the report in Markdown, without writing `report.md`: the coordinator saves it. It covers:
- the scoreboard;
- each phase's changes, condensed from `log.md`: the bugs fixed with their tests, what the elegant phase removed, the work the fast phase took off each hot path;
- the judgment calls;
- the verification results, command by command;
- the rejected findings with their reasons;
- the questions the user answered, and what the run changed for each;
- the decisions left for the user, from the unanswered `user:` entries other than pre-existing ones, and the `fast:` entries left when the fast phase was skipped:
  - merge the entries one answer settles into one decision, such as the cleanups a closed public API held back: may the run make them?
  - drop the entries the run settled, those with a clear answer and those that ask nothing, and list them in one line each at the end;
  - each decision gives the question in one sentence, the options, your pick, and what the run would change on a yes;
  - number them by urgency: data loss, wrong results and compatibility breaks first, then choices to settle before the next release, then the rest;
- for a diff scope, the pre-existing bugs, one line each;
- every hang, kill and tooling repair.

Count `tests.txt` with `count-lines.sh` in the skill's `scripts` folder, next to this file's folder, now and `--at` the commit in `run-base.txt`. Return a summary of at most ten lines first: start and end source and test lines, bugs fixed, verification results, and the decisions by number in one line each. Then a `---` line and the full report.
