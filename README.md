# Java-Subset Interpreter in Racket

A Racket interpreter for a small Java-like language, developed as a team project for CSDS 345: Programming Language Concepts at Case Western Reserve University.

## Origin and history

This showcase repository is a copy of the original [CSDS345-proj repository](https://github.com/Des1d3rium/CSDS345-proj), based on its [part3 branch](https://github.com/Des1d3rium/CSDS345-proj/tree/part3) at commit [`5faf614`](https://github.com/Des1d3rium/CSDS345-proj/commit/5faf61446c7fe3203e0c89a653739eb7ce9ff76f). The original commit history and source-file credits are preserved.

The original repository records the course project. This copy provides a separate place to document, test, and present that work. Its default branch starts from Part 3. Part 4 remains unfinished development work and is reserved for a later update.

## Current status

The Part 3 interpreter source is unchanged in this initial showcase copy. This update adds documentation and excludes generated compilation files from the current tree. Runtime behavior has not yet been revalidated in this copy; no test pass rate, coverage percentage, or performance results are claimed.

## Implementation

The interpreter evaluates parser-generated syntax trees using environment frames and continuations. The Part 3 source contains evaluation and control-flow handlers for:

- Variable declarations, assignment, arithmetic, and Boolean expressions.
- Conditionals, blocks, and loops.
- Function declarations, calls, parameter binding, and closure representations.
- Environment lookup and scope handling.
- `return`, `break`, `continue`, and exception handling.

These describe the code structure. Behavioral guarantees will be documented alongside reproducible tests as the showcase version is validated.

The language uses Java/C-style syntax. The parser is a recursive-descent parser for the course language and excludes objects. Object-oriented extensions are outside this Part 3 showcase.

## Files

| File | Purpose |
| --- | --- |
| `interpreter.rkt` | Part 3 interpreter and the entry file for the bundled example |
| `functionParser.rkt` | Parser used by the Part 3 interpreter |
| `lex.rkt` | Lexical analysis |
| `test.java` | Bundled function and scope example |
| `simpleParser.rkt` | Earlier parser retained from the source repository |
| `interpreter2.rkt` | Additional interpreter retained from the original repository, with separate author credits in its header |

## Running the bundled example

Install [Racket](https://racket-lang.org/), then run the following command from the repository root:

```sh
racket interpreter.rkt
```

Alternatively, open `interpreter.rkt` in DrRacket and select **Run**. The file ends with `(interpret "test.java")`, which invokes the bundled example. The working directory must be the repository root so that the relative input path resolves.

These instructions follow the current source entry point; they have not yet been executed as part of preparing this showcase copy. A configurable command-line entry point and an automated test command are planned.

## Scope example

`test.java` uses the same variable names in global and function scopes. Under lexical scoping, the expected values are:

| Call | Expected evaluation | Value |
| --- | --- | --- |
| `bmethod()` | Global `a` plus local `b`: `10 + 30` | `40` |
| `cmethod()` | `bmethod()` plus local `a` and global `b`: `40 + 40 + 20` | `100` |
| `main()` | `cmethod()` plus global `a` and local `b`: `100 + 10 + 5` | `115` |

The final value of **115 is an expectation derived from lexical scoping**, pending a fresh run of the implementation. It is not a recorded test result.

## Validation and next steps

The first showcase milestone is a reproducible Part 3 version with a documented entry point and tests for expressions, variable errors, scope, function calls, recursion, loop control, and exceptions. The source comments about side effects and closure environments identify behavior to examine during that validation.

After that baseline is stable, Part 4 can be completed and evaluated as a separate extension. Coverage and performance measurements will be added only when their inputs, methods, and results can be reproduced.

## Contributors and source credits

The Part 3 interpreter header credits **Zeyu Chen, Andrej Antunovikj, and Dasheng Lin**. Their names and the original commit authors remain in the source and history. The project is presented as team work; individual module ownership is not inferred from this repository copy.

`interpreter2.rkt` has separate header credits to **Reed Bower, Haocheng He, and Walter Graham**. It is retained with those credits and is not the designated Part 3 entry point. Parser and lexer files retain their original source notices. Their presence does not imply that the Part 3 team independently authored every file.

For the original course version and its development record, see [Des1d3rium/CSDS345-proj](https://github.com/Des1d3rium/CSDS345-proj).
