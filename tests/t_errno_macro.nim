import unittest
import nimproj

# ── C macro collision guard ───────────────────────────────────────────────────
#
# `errno` is a macro in C's <errno.h> (`#define errno (*__errno_location ())`
# on glibc, a similar expansion on MSVC). A Nim object field named `errno`
# therefore emits `int errno;` into the generated C, which the preprocessor
# rewrites into a function call — the struct member becomes a syntax error.
#
# This is invisible on Linux and macOS, where nothing in the translation unit
# pulls in <errno.h>: the field compiles fine and the tests pass. It surfaces
# the moment any header does — MSVC's <stdlib.h> does, which is why the Windows
# CI entry failed with C2032/C2059 while Linux and macOS were green.
#
# The guard forces <errno.h> into the translation unit on every platform, so
# the collision is a local failure rather than a Windows-only one. If a future
# field, parameter or variable is named after a C macro, this file is where it
# breaks first.
#
# `-include` is gcc/clang; MSVC spells it `/FI`. Both are passed so the guard
# runs on the full CI matrix.
{.passC: "-include errno.h".}
when defined(vcc) or defined(clang_cl):
  {.passC: "/FIerrno.h".}

suite "C macro collisions":
  test "the error hierarchy compiles with <errno.h> in the translation unit":
    ## The compile is the assertion. Deliberately no field access here: naming
    ## the field would make a rename fail at the Nim level with "undeclared
    ## field", which hides the C-level collision this file exists to catch.
    ## Constructing through `newException` still emits the full struct layout,
    ## so a macro-colliding field name breaks the C compile.
    expect ProjError:
      raise newException(ProjInitError, "context creation failed")
    expect ProjError:
      raise newException(CrsError, "a CRS failure")
    expect ProjError:
      raise newException(TransformError, "a transform failure")
    expect ProjError:
      raise newException(GeodError, "a geodesic failure")
