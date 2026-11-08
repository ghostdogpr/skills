# Rules

Every agent in a refine run follows these rules. Each phase file adds its goal and its bar for a finding worth fixing.

`context.md` in the run directory holds the project's side of these rules: the scope kind, compatibility, the hot paths, the conventions and the verification procedures. `intent.md` lists where the code's intent is written down. Their `## User rules` and `## User corrections` sections override anything here.

## Scope

- **An area scope** decides where reviewers look, not where changes stop. A change may reshape consumers of a type, callers of a function or a neighboring module when the removal is worth it.
- **A diff scope** opens only the lines the frozen `diff.patch` added or changed. Every phase reviews those lines and the code they reach, not what the base already had. A change may touch other code only to serve a change to the diff's lines: a call site of a signature the diff introduced, code the change leaves dead, a fix of a bug the diff caused, or, in the elegant phase, existing code that removing the diff's complexity has to reshape, such as a definition the diff duplicated.
- **A pre-existing bug** is one the code at `diff-base.txt` already had, with the same failure, even on lines the diff rewrote, renamed or moved. Nobody looks for one or fixes one. One met anyway gets a `user: pre-existing:` note in `deferred.md` with the input that triggers it, for a list in the report. A bug the base had that the diff makes reachable or worse is the diff's. Complexity and slowness the base already had are left alone.

## Behavior

The elegant and fast phases keep behavior, except to fix a bug, by the rules in `correct.md`. The correct phase changes it only where the code contradicts its intent.

- What users and clients can observe stays the same: every feature and every result. Internal structure, types, call order and intermediate representations may change. The unit suite and any conformance suite define that behavior; when they miss something a user would notice, pin it with a characterization test before changing the code around it.
- Behavior is what the sources of intent and clients rely on, not everything a test pins. A detail they leave open, such as the order of entries in an error list, may change when the result is at least as good; update the tests that pin it.
- Input the code accepted stays accepted: a value that parsed, a request that succeeded, data already stored. A stricter rule goes to `deferred.md` as `user:`, unless `context.md` says that input needn't stay compatible.
- The public API, with its doc comments, is behavior unless `context.md` says it is free to change. A change updates a doc sentence it makes false.
- Tests keep running everywhere they ran. Never narrow a test to the configuration CI happens to run, and never delete a test whose case nothing else covers: before removing or merging one, name the test that still covers its case.
- When the scope implements a standard, read its text before reshaping code it drives.
- A change on a hot path adds no work per call, such as an allocation, a scan instead of a lookup, an extra pass or a dropped fast path, unless it fixes a bug no cheaper fix can. Argue it from the change; run a benchmark only when the argument can't settle it.

## Deferred notes

`deferred.md` holds one line per note, tagged with who handles it: `elegant:` or `fast:` for a later phase's reviewers, `user:` for the user. A phase never acts on a note tagged for another. A bug gets no note, since whichever phase meets it fixes it, except a pre-existing one.

A `user:` note asks the user for a decision, so write one only for:
- a choice between at least two reasonable answers that users or callers would see differently, which the sources of intent and the callers don't settle;
- a change worth making that a rule here forbids, such as a public API change or a stricter input rule. When a compatibility question to the user already covers that rule, the change joins that question's note.

Make a choice with a clear answer yourself. An observation that the code is right, a finding you couldn't reproduce and a risk too small to act on go to `rejected.md` with the reason. When an existing `user:` note would be settled by the same answer, add your case to it.

## No partial calls

Never save lines with a partial call, an operation that fails on input its type allows: the first element of a list that may be empty, a lookup that throws on a missing key, an unchecked unwrap (`Option.get`, `unwrap()`, `!`), a cast, or a match that misses a case. Make the type prove it, for example with a non-empty type from where the list is built, or handle the missing case. Don't replace an optional value with a sentinel callers must check. A partial call already in the scope is an elegant finding, except on a hot path where the safe form adds work per call.

## Keep type signatures

Never save lines by dropping a type annotation: a return type, a field's type, a type hint. New functions and helpers get explicit return types too.

## Verification

`context.md` has the procedures.

- The round verification ends every round: the unit suite in the default configuration.
- A verification passes only when its log shows the tests ran. A run that reports no tests, or far fewer than the last one, is a tooling failure.
- The final verification runs once, after the last phase: the unit suite in every configuration CI builds, every conformance suite in full, the compatibility checks and the docs build.
- Run the formatter whenever it helps.
- Keep one verification run alive at a time: suites that bind ports or share a build daemon fail against each other. A tooling failure, such as a port in use or suites with no result, says nothing about the code: fix the tooling and rerun.
- When you poll a log for a marker, match it anywhere on the line: build tools start lines with escape codes.

## Bounded commands

- Give every command a timeout: a few minutes for a probe or a targeted test, 30 minutes for a build or a full suite. Use `timeout`, or on macOS `perl -e 'alarm shift; exec @ARGV' <seconds> <command>`. A background command ignores your tool's timeout setting, so put the timeout inside the command.
- The timeout kills the whole process tree. Killing a build client often leaves its forked test process running inside the build daemon: kill that too.
- On a hang, kill the process, and write the command, how long it ran and the test it was on to `progress.log` and your report.
- A test that fails once and passes on a rerun is a bug, in the test or the code: keep its output, and fix it or report it.
- A test or probe that waits on another thread, process or server uses a bounded wait, so a broken change fails it instead of hanging it.
- Before you return, stop every process and container you started, except the shared build daemon.

## Progress

Agents that run commands append one line to `progress.log` when they start a step and before any command longer than a minute: the time, the role and label, and the step, such as `14:02 elegant-3 unit suite`.

## Style

- New code reads like its neighbors: the project's formatter, imports, naming and idioms.
- Existing comments stay and move with their code.
- Write a new comment only where the code alone would mislead, following the project's doc-comment conventions.
- If a writing skill such as `unslop` is installed, load it before writing a comment.
