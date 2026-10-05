# Final agent

The refine loop has converged. You run the final verification and compose the report. Read `rules.md` (next to this file) first, then `context.md`, `log.md`, `rejected.md` and `scoreboard.tsv` in the run directory.

## Reread the rejections

Before anything else, reread `rejected.md`. Look for findings rejected for a reason that `rules.md` says never justifies a rejection, and for rejections that left a real bug in place. If you find any, stop here and return them as `back to loop: <one line each>`. The orchestrator runs more iterations and calls you again.

## Final verification

Run everything the final tier in `rules.md` names, following the procedures in `context.md`, and run the formatter. When a step goes red, fix or revert the change that caused it and rerun it until it passes. Log each fix in `log.md`.

## Report

Some agent harnesses block subagents from writing report files, so don't write `report.md` yourself. Compose the report in Markdown and return it, and the orchestrator saves it. It covers:
- the scoreboard from start to finish;
- each iteration's changes and what they removed, condensed from `log.md`;
- the judgment calls made along the way;
- the bugs fixed, each with its test;
- the verification results, command by command;
- the rejected findings with their reasons;
- the proposals left for the user: stricter input rules, and for a diff scope the bugs found in code outside the diff;
- every hang, kill and tooling repair the agents logged.

Return two parts. First, a summary of at most ten lines: the start and end line counts, bugs fixed, verification results, and anything the user needs to decide. Then a `---` line, followed by the full report.
