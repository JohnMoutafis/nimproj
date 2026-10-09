# Context Lifecycle

Every PROJ call that can report an error runs inside a `ProjContext`. The context holds PROJ's error state and logging configuration, and it must outlive every object created from it.

## Creating a context

```nim
import nimproj

let ctx = initProjContext()   # one owner, one thread
# ... use ctx ...
# =destroy runs at the end of the scope and frees the context
```

`initProjContext()` raises `ProjInitError` if PROJ hands back a nil handle — in practice `libproj` is not installed, or a different one than expected was linked.

## One owner, enforced by the compiler

`ProjContext` cannot be copied: `=copy` is declared `{.error.}`, so a copy is a compile error rather than a comment asking you not to make one. Pass it by `var`, or move it explicitly.

```nim
proc process(ctx: var ProjContext) =
  echo ctx.projVersion()

var ctx = initProjContext()
process(ctx)
```

Two owners would mean two `proj_context_destroy` calls on one handle. That is why the guarantee is checked by a compile-fail test (`tests/compile_fail/noncopyable.nim`) and not by a `compiles()` probe — Nim raises this diagnostic in a later pass than `compiles()` can observe, so the obvious probe passes even when the guarantee is broken.

## The context must outlive what it made

Every object created from a context — a CRS, a coordinate operation — belongs to that context and must not outlive it. Later versions take a non-owning back-reference to the context for exactly this reason: it makes the requirement structural instead of documented.

## Thread safety

A `ProjContext` is not thread-safe when shared. Create one per thread, and never pass one across a thread boundary.

## Library information

`projVersion()` and `projVersionString()` are library-level and need no context:

```nim
echo projVersion()         # "9.7.1"
echo projVersionString()   # "Rel. 9.7.1, December 1st, 2025"
```

## Reading the last error

`lastError()` returns PROJ's message for the most recent failure recorded on that context, or `""` when the last operation succeeded — PROJ clears its error code on success, so it means "the last operation", not "any operation ever".

```nim
let ctx = initProjContext()
echo ctx.lastError()   # "" — nothing has failed yet
# ... an operation fails ...
echo ctx.lastError()   # "Invalid PROJ string syntax"
```

See also [Error types](../patterns/error-types.md) for how a failure becomes a typed exception.
