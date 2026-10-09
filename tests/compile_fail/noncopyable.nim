## Compile-FAIL check — this file is EXPECTED to fail compilation.
##
## `nimble test` asserts that it does. Purpose: `ProjContext` must not be
## copyable, because a copied context means two owners and a double free.
##
## Why a whole file instead of `static: assert(not compiles(...))`: Nim's
## "'=copy' is not available" diagnostic is raised in a later pass than the one
## `compiles()` consults, so `compiles()` reports `true` for a real copy. A
## `notCompiles` probe for this guarantee passes vacuously. Verified on 2.2.10.
##
## Keep this file short: the check is "it failed to compile", and a short file is
## one you can read to confirm it failed for the intended reason.

import nimproj/context

proc returnsItsArg(ctx: ProjContext): ProjContext = ctx   # a non-sink param returned by value needs a copy

let ctx = initProjContext()
discard returnsItsArg(ctx)
