# Elegant phase

The goal is less complexity with the same behavior, measured in source lines that disappear while every feature stays. Test lines count separately. In a diff scope, look for complexity the diff added; removing it may reshape existing code.

The findings worth the most are ambitious: a core data model in which invalid states can't be written, two passes merged into one, a module that turns out unnecessary, a contract changed across ten files so the checks on both sides disappear. When `log.md` shows several bug fixes of one kind, look for the mechanism that makes that kind impossible.

## Lenses

Each lens asks one question and counts a different kind of complexity as removed.

### Constraints (Bjarnason, "Constraints Liberate, Liberties Constrain")

What freedom can we remove so fewer incorrect implementations are possible?

The more a piece of code can do, the less a reader can predict what it will do. Freedom at one level becomes constraint at the next. A function allowed to return an empty list forces every caller to handle one; a function allowed to mutate shared state forces every reader to track it. Pick the least powerful type, signature or abstraction that still does the job, and put the constraint where the value is created, so the checks it replaces disappear downstream.

A change removes complexity here when a state or implementation that used to compile no longer does, and the check that guarded against it goes away. Hunt invalid states the types allow, invariants held up by runtime checks or convention (taking the first element after an emptiness guard, flags that must agree with other fields), types wider than the values they carry, functions handed more capability than they use, and defensive branches nothing can reach.

### Simplicity (Hickey, "Simple Made Easy")

Which independent concerns have become entangled? Can they be understood separately?

Simple means one fold, not braided with anything else. It is objective, and it is a different axis from easy, which only means familiar or close at hand. Two concerns are complected when a reader can't think about one without the other. Separate files don't fix that on their own, because modules can still be braided through shared state, flags or conventions. Judge the running artifact, not how pleasant the code was to write.

A change removes complexity here when a question about one concern no longer needs the other concern's code to answer it. Hunt one concept defined twice, including one the scope reimplements from elsewhere in the repository, caches and side maps kept apart from the data they describe, fast paths woven into logic, stored fields that could be derived, state threaded through code that only needs a value, and conditionals that encode a decision made elsewhere.

### Parametricity (Wadler, "Theorems for free!")

What does the type actually guarantee, and what still depends on implementation discipline?

Read a type as a theorem. A function from a list of `A` to a list of `A`, for any `A`, can only drop, repeat or reorder elements, because it has no operations on `A`. So mapping a function over the input before or after calling it gives the same result, for every such function. The more general and precise the type, the more it proves. Concrete types like strings, integers and booleans prove almost nothing, and escape hatches like `null`, casts, runtime type tests, reflection, exceptions and side effects weaken whatever the type did prove.

A change removes complexity here when a property that held by discipline now holds by signature, and the comment, convention or caller check that kept it true goes away. Hunt unnamed tuples whose order matters, strings standing in for closed sets, cached results that depend on arguments missing from the cache key, functions that take a concrete type they never inspect, and invariants a signature could enforce that only a comment states.

## Worth fixing

A finding is worth it when it names what goes away: a runtime check, a branch, a partial call, a parameter, a stored field, a duplicate definition, a dependency between two components, or a convention the reader had to remember. A new type or abstraction is welcome when the removals it enables outweigh it. Prefer the change that removes a class of problems over the one that removes an instance.

Reject:
- a change that only moves, renames, reformats, wraps or rewords code, or trades one form for another of the same complexity;
- a change that adds a check, a table entry or a branch to handle one more case;
- a change that grows net source lines;
- a change that adds work per call on a hot path, however many lines it saves.

These never justify a rejection: the finding reaches outside an area scope, changes a detail the sources of intent leave open, is large, churns tests on internal details, or makes a comment false, which it then updates.

A bug met here is fixed by the rules in `correct.md`, and its lines don't count against the round's removal.

## Ranking

Reviewers rank findings by estimated net source lines removed, redesigns first. A test-only cleanup ranks below any source removal. A redesign finding gives:
- the essential problem in a few sentences: inputs, outputs and rules;
- the core types and the functions over them, as a sketch;
- where each current file and function lands, or why it disappears;
- the estimated size of the result against the current size;
- the features and the behavior its sources of intent promise, and how the sketch keeps each one.

The fixer accepts a redesign when its estimate is clearly smaller and its sketch keeps every feature, and rewrites toward it in steps that pass the tests, or wholesale where old and new can't coexist.

## Log

Each `log.md` entry names the lens and what went away. A removed or merged test names the test that still covers its case.
