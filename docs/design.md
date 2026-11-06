# Language and evaluator design

The examples and tests define the showcase language behavior. The parser retains the course grammar; the evaluator implements the following rules.

## Values and evaluation

Values are integers, Booleans, or functions. `main()` must return an integer or Boolean. The public `interpret` function returns Boolean results as the symbols `true` and `false`; the evaluator uses Racket Booleans internally. A function may finish without a return when called as a statement. Using such a call as a value is an error.

Arithmetic and ordered comparisons require integers. Division truncates toward zero; remainder has the dividend's sign. Equality accepts integer and Boolean operands; values of different types are unequal. Conditions, `!`, `&&`, and `||` require Booleans. Logical operators short-circuit. Operands and call arguments are evaluated left to right. Assignment updates a binding and evaluates to the assigned value.

## Lexical environments

An environment is a list of frames. A frame maps names to boxes containing values. A declaration creates a cell in the current frame, and assignment finds the nearest cell in the lexical chain. Declaring the same name twice in one frame is an error; a child block can shadow it. An uninitialized binding has a dedicated sentinel distinct from false.

A closure contains the function's parameters, body, and definition environment. Invoking it adds a fresh parameter frame to the captured environment, not the caller environment. Parameter values are copied into new cells. Captured outer cells are shared, which preserves mutation and makes escaping closures work without reconstructing environments by variable name.

Global functions are registered before global variable initializers run. Global variables are initialized in source order. Nested function declarations execute in statement order. Capturing a frame retains the frame itself: later declarations in that same frame become visible when executed. This behavior is explicitly different from a compiler that resolves every name to a declaration position before execution.

## Control flow and cleanup

Function return and loop break/continue use `call/cc`. Each function supplies its own invalid-loop-control handlers, so a callee cannot break or continue a caller's loop.

A `try` evaluates its body using continuations that capture a pending transfer: normal completion, return, break, continue, or throw. A throw with a catch clause enters a new catch frame. The catch body is captured separately, so a rethrow is not handled by the same catch again. The evaluator then runs `finally` in a fresh block frame and propagates the pending transfer. A new transfer from `finally` takes precedence.

The shared binding cells preserve state across transfers. A return expression is evaluated before cleanup; assigning a new value to its variable in `finally` does not change the already captured return value.

Language-level exceptions are values produced by explicit `throw`. Interpreter diagnostics (such as invalid types or undefined names) terminate interpretation through a Racket exception and are not catchable by the teaching language. The `finally` guarantee above applies to the language's normal completion and control transfers, not host diagnostics.

## Parser boundaries

The recursive-descent parser produces list-shaped syntax trees. The lexer recognizes only valid two-character operators together, allowing forms such as `x=-1` and `true&&!false`. It skips `//` and `/* ... */` comments. EOF checks prevent character operations on EOF values and report missing braces. Parser cleanup closes input ports on success and failure; lexer buffers reset for each input.

The parser still uses shared mutable lexer state and is intended for sequential invocations. Each `interpret` call creates a fresh global environment. The suite verifies that malformed input and runtime failures do not contaminate later sequential calls.
