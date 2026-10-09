# Code Style

Follow the official [Nim style guide](https://nim-lang.org/docs/nep1.html) as used throughout the codebase:

- 2-space indentation, `camelCase` for procs and variables, `PascalCase` for types.
- Mark public API symbols with `*`; keep implementation details unexported.

## House style

NEP-1 sets the floor — indentation, casing, exports — and stops there. Everything below is this project's own convention, the part NEP-1 leaves open, and it is what makes the codebase read as one piece.

- **Section separators** — `# ── Label ────…` with box-drawing characters, one blank line after. Used in source and tests alike; nested sections inside a suite are indented.
- **Module headers** — a one-line summary, then the fact a reader needs, ending with `## See also: \`docs/<page>.md\`.` pointing at a user-guide page. The header says where to *use* this, not why it is shaped that way.
- **Doc comments** — every exported symbol, sentence case, ending in a period: `## Returns the PROJ version number, e.g. "9.7.1".` / `## Raises \`ProjInitError\` if PROJ returns a nil handle.` / `.. code-block:: nim` for examples.
- **Fields** — a single-line fact goes inline (`handle*: PROJContextHandle  ## Internal — not part of the stable API.`); a longer one goes on its own line under the type.
- **Value-producing procs** end with an explicit `return`, as in `version()`.
- **Test suites** are named for the area they cover, as a PascalCase phrase with a trailing colon (`suite "ProjContext lifecycle":`); test names are sentences with a lowercase initial and a trailing colon (`test "=destroy fires cleanly at scope exit":`).
- **Nimble tasks** are camelCase and named for the surface they cover (`testTransform`, `testEdgeCases`).

## PROJ binding rules

- Declare raw `libproj` bindings **only** in `src/nimproj/private/proj_abi.nim` (and `private/geodesic_abi.nim` for the `geod_*` family) — feature modules import it but never re-declare bindings elsewhere.
- Declare every binding with the **C symbol name verbatim** — `proj_context_create`, not `projContextCreate`. `importc` with no rename emits the Nim name as the C symbol, so a renamed declaration cannot link: the C compiler would look for a function that `proj.h` does not have.
- **Handle types are Nim-named**, not C-named: `PROJContextHandle`, `PROJ`, `PROJInfo`. The C spelling is not an option for the context handle — `PROJContext` and `PROJ_CONTEXT` are the *same identifier* as the public `ProjContext`, because Nim ignores case and underscores after the first letter, so either one is a redefinition. A type whose Nim name differs from its C name carries an explicit `importc` (as `PROJInfo` does).
- Every declaration carries `header` (directly or via `{.push.}`), so the C compiler checks the ABI against the real prototype. No exceptions — a declaration without it is a declaration nothing verifies.
- Guard the layer above: feature modules raise, the ABI layer never does. Raise only error types from `src/nimproj/errors.nim`, with messages naming the failing call. See [Error Types](../patterns/error-types.md).
