import unittest
import std/strutils
import std/os
import std/osproc

import nimproj

let ctx = initProjContext()

suite "Crs construction and predicates":
  test "a projected CRS is projected but not geographic":
    let c = initCrs(ctx, "EPSG:32633")
    check c.isProjected
    check not c.isGeographic
    check c.crsType == ProjectedCrs
    check c.idAuth == "EPSG"
    check c.idCode == "32633"

  test "a compound CRS is compound and not geographic, and its parts are":
    let c = initCrs(ctx, "EPSG:4326+3855")
    check c.isCompound
    check not c.isGeographic   # shallow, by decision
    check initCrs(ctx, "EPSG:4326+3855").subCrs(0).isGeographic  # the deep answer, composed
    check c.idAuth == ""    # no identifier: measured

  test "a bad definition raises rather than returning a dead handle":
    expect CrsError:
      discard initCrs(ctx, "not-a-crs")

  test "toWkt survives its object going out of scope":
    var w = ""
    block:
      let c = initCrs(ctx, "EPSG:4326")
      w = c.toWkt()
    check w.startsWith("GEOGCRS")

suite "Crs ownership":
  test "a copied Crs is destroyed independently of its source":
    let a = initCrs(ctx, "EPSG:4326")
    let b = a
    check b.name == a.name
    check b.crsType == a.crsType
    block:
      let c = initCrs(ctx, "EPSG:4326")
      let d = c
      check d.name == c.name
    # If =copy were a bitwise copy sharing the PJ*, the two destroys above
    # would double-free and this test would crash.

suite "Crs output matches the projinfo CLI":
  # The CLI is the oracle, invoked at run time. PROJ's textual output is a
  # function of the EPSG database bundled with the installed PROJ: the WGS 84
  # datum ensemble, for instance, gains members between releases (G2296 lands
  # in newer databases). A checked-in golden file would pin one PROJ version,
  # but the project supports any system PROJ >= 9.0 (ADR-0006), so the expected
  # text has to come from whatever PROJ is actually linked here.
  proc projinfo(code, fmt: string): string =
    if findExe("projinfo").len == 0:
      return ""
    let (output, status) = execCmdEx("projinfo -q -o " & fmt & " " & code)
    if status != 0:
      return ""
    # projinfo appends one trailing newline; the C API does not emit it.
    if output.endsWith("\n"): output[0 ..< output.len - 1] else: output

  # (code, format) pairs where the projinfo CLI and the C API genuinely differ;
  # pinned in the test below instead of compared here.
  const knownDivergent = [("EPSG:4326+3855", "PROJ")]

  for code in ["EPSG:4326", "EPSG:32633", "EPSG:3857", "EPSG:4326+3855"]:
    for fmt in ["WKT2_2019", "PROJJSON", "PROJ"]:
      test "output matches projinfo: " & code & " " & fmt:
        if (code, fmt) in knownDivergent:
          check true  # covered by "known divergence" test below
        else:
          let expected = projinfo(code, fmt)
          if expected.len == 0:
            echo "SKIP: projinfo unavailable (Ubuntu: apt-get install proj-bin)"
            check true
          else:
            let c = initCrs(ctx, code)
            case fmt
            of "WKT2_2019": check c.toWkt(Wkt2_2019) == expected
            of "PROJJSON": check c.toProjJson() == expected
            of "PROJ": check c.toProjString(Proj5) == expected
            else: check false

  test "known divergence: the CLI emits the geoid model, the C API does not":
    # Measured against PROJ 9.7.1, 2026-10-13. For EPSG:4326+3855 the projinfo
    # CLI exports `+geoidgrids=... +geoid_crs=WGS84 ...`, while
    # proj_as_proj_string returns the grid-less
    # `+proj=longlat +datum=WGS84 +vunits=m +no_defs +type=crs`. No C-API
    # creation path (proj_create, proj_create_from_database, a WKT2 round-trip,
    # proj_clone) reproduces the CLI output. If PROJ ever aligns the two, this
    # test fails loudly and the pair can leave knownDivergent above.
    let c = initCrs(ctx, "EPSG:4326+3855")
    check c.toProjString(Proj5) == "+proj=longlat +datum=WGS84 +vunits=m +no_defs +type=crs"
    check not c.toProjString(Proj5).contains("+geoidgrids")
    let cli = projinfo("EPSG:4326+3855", "PROJ")
    if cli.len == 0:
      echo "SKIP: projinfo unavailable (Ubuntu: apt-get install proj-bin)"
    else:
      check cli.contains("+geoidgrids=")
