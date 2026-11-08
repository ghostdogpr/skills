# Correct phase

The goal is code that does what it is meant to do, as its sources of intent say: first the user's words in `intent.md`, then the pull requests, docs, doc comments, tests and callers it lists. Behavior changes here, where the code is wrong. Structure, naming, duplication, style and speed belong to the later phases.

## What a bug is

- Code that does what a source of intent says it shouldn't, or doesn't do what one says it should, for an input or a sequence of events a caller can produce.
- A crash, hang, leak, data loss or swallowed error on input a caller can send.
- Two parts of the code that handle an input differently where the sources say nothing, so clients see inconsistent results. What clients see most decides which is right.

Not bugs:
- behavior no source asks for, even when another design would be nicer;
- an input no caller can produce: trace the callers before you claim one can;
- a deviation the project documents;
- behavior only the code under review shows: the implementation alone is not a source of intent;
- a question the sources leave open with more than one reasonable answer: it goes to `deferred.md` as `user:`, and nobody guesses. When the callers or docs leave one reasonable answer, that answer is the intent.

## Reviewers

Each reviewer takes one area of `areas.md`. An area whose reviewer led to no fix is marked `done <label>` there and isn't reviewed again. A file the scope gains joins the area that uses it.

## How to review an area

Read all of the area's code and the sources `areas.md` names for it, two ways:

- **From intent.** For each thing the sources say the code does, find the code and check that it holds, in every variant and configuration they name. Where a source cites a standard, read its text, and reference implementations where it is ambiguous. Something a source promises and the code doesn't do is a bug.
- **From the code.** For each function, ask which inputs and states its callers can produce, and what it does with them: empty, single and maximal values, boundaries, duplicates, encodings, errors and timeouts from dependencies, retries, concurrent calls, cancellation, teardown and partial failure.

Follow calls into other areas as far as a finding needs.

In a diff scope, review what the diff added or changed and the code a change reaches, such as the callers of a contract it changed. For each change, ask whether it does what it was meant to, and whether it breaks something the base did right. Before you report a bug, read its code at the base: a bug the base had gets a one-line `user: pre-existing:` note, not a finding.

## Worth fixing

A real bug is always worth fixing, whatever the fix costs.

- A bug is real when a test fails on it before the fix. A race or teardown bug that won't reproduce deterministically is real when the finding names the interleaving and the fixer confirms it in the code.
- Reject a finding that can't be reproduced, with the reason: no caller produces the input, the code handles it elsewhere, or no source asks for the behavior.
- A finding about structure or style goes to `deferred.md` as `elegant:`, one about speed as `fast:`.

## Fixing

- Write the test first and watch it fail, then fix the code and watch it pass. Start from an existing test that drives the code to the bug, adding the failing input or assertion, and write a new test only when none comes close.
- Keep a new test only when no existing test covers that path and a later change could plausibly break it again. When the fix makes the wrong state impossible to build, drop the test once the fix passes. `log.md` names the dropped tests.
- A kept test is the shortest one that fails, reusing the file's fixtures and helpers. Bugs with one cause share one test. Add no test no bug needs.
- Aim for a fix that makes the wrong state impossible to represent, or routes the input through a mechanism that already handles its kind. Bugs with one cause get one fix. One more `if` is the last resort, but when nothing structural exists, the direct fix goes in, even if it adds lines. Don't rebuild a module: the elegant phase looks for the mechanism behind bugs of one kind in `log.md`.
- A test that pins behavior a source calls wrong gets updated, and `log.md` names the source.
- A real bug goes to the user instead of being fixed only when every fix needs a public API change or a stricter input rule `context.md` doesn't allow, or a choice the sources leave open. The `user:` entry names the bug, the input, the options and your pick. A large, spread or hard-to-test fix is never a reason to defer: make it.
- A pre-existing bug in a diff scope is never fixed and gets no test.

## Ranking and log

Reviewers rank findings by how much a user would notice: data loss and wrong results first, then crashes and hangs, then missing features. Each `log.md` entry names the source or implicit requirement the bug breaks, the input and the test.
