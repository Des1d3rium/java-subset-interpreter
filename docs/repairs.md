# Repairs from the Part 3 baseline

The baseline is the unchanged original commit `5faf614`. It was executed with Racket 9.3; the raw selected results are in [original-baseline.json](original-baseline.json). Reproduce with `python3 scripts/check-original.py`.

| Issue | Observed original behavior | Current behavior | Regression fixture |
| --- | --- | --- | --- |
| Caller bindings used instead of definition bindings | Original example returned `130`; a global lookup selected caller-local `a = 20` | Definition environment is captured; original example returns `115` | Original scope example; `lexical rather than caller scope` |
| Escaping closure loses its environment | Reported undefined `add` | Returned closure retains its defining frame | `escaping closure`; `independent closure state` |
| Mutation discarded by expression calls | Counter expression returned `2` | Updates stay visible through shared cells; returns `5` | `global mutation in expression call` |
| Expression exception bypasses outer catch | Printed `Uncaught exception thrown`, exiting successfully | Caller catch receives the thrown value; returns `10` | `expression call exception reaches caller catch` |
| Finally uses stale state during return | Returned `40` instead of `45` | Cleanup reads the latest binding cells | `return executes finally with current state` |
| Return from catch skips finally | Returned `3` instead of `10` | Catch completion is captured before cleanup | `catch return executes finally` |
| Adjacent operators merged | `x=-1` caused a parser error | Only valid two-character operators combine | `no whitespace before unary minus` |
| Uninitialized values leak as a sentinel | Printed `'novalue` with exit status 0 | Distinct uninitialized-variable diagnostic | `uninitialized variable` |
| Extra arguments silently ignored | A one-parameter function accepted two arguments and returned `1` | Explicit arity error | `too many arguments`; `too few arguments` |

The environment bug affected several operations, so the showcase revision replaces deferred environment reconstruction with lexical frames and shared cells. This is an evaluator refactor, not a claim that the original submission already implemented the repaired behavior. The original code and authors remain available in Git history.

Additional tests cover argument ordering, block cleanup, nested recursion, each language-level exit through finally, malformed input, type diagnostics, file-path handling, and CLI exit status. The suite contains 106 checks as documented in the README. Passing them establishes those specific behaviors; it does not establish complete Java compatibility, full coverage, or a performance improvement.
