# Rules

Every agent in a refine run follows these rules. The goal is less complexity with the same behavior. Fewer bugs follow from that, because a design with no room for a wrong state has nowhere for a bug to live.

`context.md` in the run directory holds what these rules leave to the project: the scope kind, the hot paths, the public API status, the conventions and the verification procedures. Its `## User rules` section, when present, overrides anything here.

## Scope

- **An area scope** decides where the reviewers look, not where changes stop. A finding may reshape consumers of a type, callers of a function or a neighboring module when the removal is worth it. A contract change across ten files is often the one that removes a whole class of bugs.
- **A diff scope** opens only the lines the frozen `diff.patch` added or changed. The code around them stays as it is, even in the files the diff touches. A change may reach that code only when a change to the diff's lines forces it, such as a call site of a signature the diff introduced or code the change leaves dead. A bug in that code which the diff neither causes nor exposes goes into the final report for the user to decide.

## Behavior

- End-user behavior stays the same: every feature and every result a user or client can observe. Internal structure, data types, call order and intermediate representations are free to change. The unit suite and any conformance or audit suite define that behavior. When the unit suite misses something a user would notice, pin it with a characterization test before changing the code around it.
- Behavior is what the spec and clients can rely on, not everything a test happens to pin. A detail the spec leaves open, such as the order of entries in an error list, may change when the result is at least as good for the reader; update the tests that pin it. Keep what clients see: values, error messages, paths and counts.
- Input the code accepted before stays accepted: a value that parsed, a request that succeeded, data already stored. A stricter rule breaks the users who sent or stored that input, however clean it is. Leave such a change out of the run and list it in the final report as a proposal.
- The public API is behavior unless `context.md` says it is free to change: the signatures users compile against, and their doc comments, which state the contract. A change updates a doc sentence it makes false, and the updated sentence still describes what users rely on.
- Tests keep running everywhere they ran before. A change never narrows a test to the configuration CI happens to run, such as one backend or one platform, and never deletes a test whose case no other test covers.
- When the scope implements a spec, read the spec text before reshaping anything spec-driven, and check reference implementations where the text is ambiguous. A redesign may shrink the code a spec requires, never the behavior.
- Runtime stays as fast or faster, and fewer lines never pays for a slower hot path. A change on a hot path adds no work per call, such as a new allocation, a scan where there was a lookup, an extra pass or a dropped fast path. Argue it from the change itself. Benchmarks are slow and noisy, so run one only when that argument can't settle the question.

## Every change removes complexity

Name what went away: a runtime check, a branch, a partial call, a parameter, a stored field, a duplicate definition, a dependency between two components, or a convention the reader had to remember. A change that only moves, renames or wraps code removes none of these and gets rejected. A new type or abstraction is welcome when the removals it enables outweigh it. Prefer the change that removes a class of problems over the one that removes an instance.

These never justify a rejection: the finding reaches outside an area scope, changes a detail the spec leaves open, is large, churns tests on internal details, or makes an existing comment false. Update the comment.

## No partial calls

A change never saves lines by trading a type guarantee for a partial call, an operation that fails on some input its type allows: the first element of a list that may be empty, a map or dictionary lookup that throws on a missing key, an unchecked unwrap of an optional value (`Option.get`, `unwrap()`, a `!` non-null assertion), a cast, or a match or switch that misses a case. Make the type prove it instead, for example with a non-empty type from where the list is built or the looked-up value instead of its key, or handle the missing case explicitly. Don't swap an optional value for a sentinel default that code must remember to check. A partial call already in the scope is a finding, except on a hot path where the safe form would add work per call.

## Keep type signatures

A change never saves lines by dropping a type annotation, such as the return type of a function, a local helper or a lambda, the declared type of a field, or a type hint in a language where hints are optional. An annotation states the contract to the reader and the compiler, so removing it removes no complexity. New functions and helpers get explicit return types too, even when that wraps a line.

## Bugs

A bug is a finding like any other, and its fix removes the structure that let the bug happen.

- Write a test that fails on the bug, then fix it in the iteration that finds it, never later.
- Aim for a fix that makes the wrong input impossible to represent, or routes it through a mechanism that already handles its kind. Several bugs with one cause get one fix. One more `if` is the last resort, but when no structural fix exists the direct fix goes in, even if it adds lines.
- Code that deviates from the spec is a bug unless the project documents the deviation. Where the spec leaves an input undefined, two parts of the code handling it differently is a bug too, and the output clients see decides which one is right.

## Verification

`context.md` has the procedures for both tiers.

- The iteration verification runs at the end of every iteration, and of every regression pass that changed code: the unit suite in the default configuration.
- The final verification runs once, on the converged state: the unit suite in every configuration CI builds (language versions, platforms, backends), every conformance or audit suite in full, the compatibility checks, and the docs build. None of it runs before convergence.
- Run the formatter whenever it helps; it's fast.
- Keep one verification run alive at a time, because suites that bind ports or share a build daemon fail against each other. A failure for tooling reasons, such as a port in use or suites with no result, says nothing about the code. Fix the tooling and rerun.
- When you poll a log for a completion marker, match it anywhere on the line. Build tools often start lines with terminal escape codes, and a `^`-anchored pattern then waits forever.

## Bounded commands

Every command ends on its own or gets killed.

- Give every command a timeout of about twice its normal duration from `context.md`. Use your tool's timeout setting, or `timeout` where it exists. macOS lacks it, so use `perl -e 'alarm shift; exec @ARGV' <seconds> <command>` there. Never run a command unbounded because a tool is missing.
- The timeout kills the whole process tree. Killing a build client often leaves the test process it forked running inside the build daemon, so check for that process and kill it too.
- On a hang, kill the stuck process, then write the command, how long it ran and the test it was on to `progress.log` and to your report. Never wait on a hung process.
- A test that waits on another thread, process or server uses a bounded wait, so a broken change fails it instead of hanging it. This matters most when you revert a fix to watch its test fail.
- Before you return, stop every process and container you started, except the shared build daemon.

## Progress

Append one line to `progress.log` in the run directory when you start a step and before any command that runs longer than a minute: the time, your role and label, the step, and its normal duration when you know it. For example: `14:02 iter3 unit suite, normal ~4 min`. The orchestrator reads it to tell a slow step from a hung one.

## Style

- New code reads like its neighbors: the project's formatter, import style, naming and idioms.
- Existing comments stay and move with their code.
- Write a new comment only where the code alone would mislead. A comment that restates a name doesn't meet that bar.
- Follow the project's conventions for comments and doc comments: which declarations get doc comments, their syntax and their layout. Read nearby code before writing one.
- If a writing skill such as `unslop` is installed, load it before writing any comment.
