# Short demonstration

Start in the repository root with Racket installed. Keep the source and terminal visible side by side.

1. Open `examples/lexical-scope.java`. Point out the three different bindings named `b` and the two named `a`. Run `racket interpreter.rkt examples/lexical-scope.java`; the result is `115`. Explain that `bmethod` reads global `a`, even though its caller declares another `a`.
2. Open `examples/closure-counter.java`. Run it to show `121`. Explain that `first` and `second` capture different counter cells, and that `first` retains its state after `counter()` returns.
3. Run `racket interpreter.rkt examples/finally.java` to show `45`. Explain that the return captures `4`, while `finally` observes the updated `x` and writes `5` to `g`.
4. Run `raco test tests`. Open one named regression fixture and its corresponding row in `docs/repairs.md`. Explain the observed failure and the design decision that repaired it.

Describe the original course work as a team project. Distinguish the original submission from the later showcase refactor and tests. Discuss personal module ownership only where it can be confirmed.
