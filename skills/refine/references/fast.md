# Fast phase

The goal is less work per call on the hot paths `context.md` lists, with the same behavior. Code off those paths is not this phase's business. In a diff scope, look for work the diff added on a hot path.

## Lens

### Hot paths

For each hot path, follow one call from entry to exit and count its work: allocations and copies, scans where a lookup fits, passes that could be one, values recomputed per call that could be computed once, boxing and conversions, formatting or logging whose output is dropped, locks held longer than needed, I/O inside a loop, and fast paths a recent change dropped. Read the `fast:` notes in `deferred.md`.

## Worth fixing

A finding is worth it when all of these hold:
- it is on a hot path from `context.md`;
- the gain follows from the change: fewer allocations, passes or calls per request, or a better complexity class. A constant-factor gain is measured with the project's benchmarks if it has any, and rejected without a clear gain;
- its cost to the code is in proportion to the gain;
- behavior holds, including for the inputs the correct phase fixed. A cache keys on everything its result depends on.

Reject a micro-optimization the compiler or runtime already makes, and a gain that is a guess. A change that adds a fiber, queue, lock, cache or hand-written replacement for a library call isn't applied: it goes to `deferred.md` as `user:`, with its measured gain and what it adds. A bug met here is fixed by the rules in `correct.md`. A structural cleanup goes to `deferred.md` as `user:`.

## Ranking and log

Reviewers rank findings by the work removed per call, hottest path first. Each finding and each `log.md` entry gives the work per call before and after.
