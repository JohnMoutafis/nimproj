import unittest
import std/strutils

import nimproj
# One thing needs the layer below: a PROJ call that fails, so `lastError` has
# something to report. Everything else here goes through the public API.
import nimproj/private/proj_abi

# ── ProjContext lifecycle ─────────────────────────────────────────────────────

suite "ProjContext lifecycle":
  test "context init returns a live handle":
    let ctx = initProjContext()
    check cast[pointer](ctx.handle) != nil

  test "a moved-from context does not free the handle it gave away":
    ## Both values leave scope here. If =destroy does not tolerate the
    ## moved-from side, this double-frees PROJ's context and the test crashes.
    proc scoped() =
      var a = initProjContext()
      let b = move(a)
      check cast[pointer](b.handle) != nil
    scoped()

  test "repeated create and drop is stable":
    ## Exercises =destroy in a loop; a leak or double-free shows up as a crash
    ## or as runaway memory in CI.
    for i in 0 ..< 200:
      let ctx = initProjContext()
      check cast[pointer](ctx.handle) != nil

  test "projVersion reports the runtime library, at least 9.0":
    check projVersion().len > 0
    check parseInt(projVersion().split('.')[0]) >= 9
    echo "PROJ runtime version: ", projVersion()

  test "projVersionString contains the version number":
    check projVersionString().len > 0
    check projVersion() in projVersionString()

  # ── Non-copyability ─────────────────────────────────────────────────────────
  # NOT tested here: `compiles()` cannot observe Nim's "'=copy' is not
  # available" diagnostic, so a `notCompiles` probe would pass vacuously. It is a
  # compile-fail check instead — `tests/compile_fail/noncopyable.nim`, run by
  # `nimble test`.

  # ── lastError ───────────────────────────────────────────────────────────────
  test "lastError is empty before anything fails":
    let ctx = initProjContext()
    check ctx.lastError() == ""

  test "lastError reports PROJ's message after a failure":
    let ctx = initProjContext()
    let bogus = proj_create(ctx.handle, "not-a-crs")
    check cast[pointer](bogus) == nil
    check ctx.lastError().len > 0
    echo "lastError: ", ctx.lastError()

  test "lastError clears once an operation succeeds":
    ## PROJ clears its error code on success (verified against 9.7.1).
    let ctx = initProjContext()
    discard proj_create(ctx.handle, "not-a-crs")
    check ctx.lastError().len > 0

    let good = proj_create(ctx.handle, "+proj=utm +zone=33 +ellps=WGS84 +type=crs")
    check cast[pointer](good) != nil
    check ctx.lastError() == ""

# ── ProjError hierarchy ───────────────────────────────────────────────────────

suite "ProjError hierarchy":
  test "every subtype is catchable as ProjError":
    expect ProjError:
      raise newException(ProjInitError, "context creation failed")
    expect ProjError:
      raise newException(CrsError, "a CRS failure")
    expect ProjError:
      raise newException(TransformError, "a transform failure")
    expect ProjError:
      raise newException(GeodError, "a geodesic failure")

  test "the numeric code survives when there is one":
    try:
      raise (ref CrsError)(msg: "Invalid PROJ string syntax", errno: 1025)
    except ProjError as e:
      check e.errno == 1025
      check e.msg == "Invalid PROJ string syntax"
