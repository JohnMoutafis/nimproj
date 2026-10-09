# Package
version       = "0.1.0"
author        = "John Moutafis"
description   = "Nim binding for the PROJ coordinate transformation library (libproj)"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"

# System dependencies: libproj >= 9.0 and its proj.db, in addition to Nim.
# See docs/getting-started/installation.md.

import strutils

proc baseName(path: string): string =
  ## nimscript's stdlib has no `extractFilename`; handle both separators so the
  ## Windows matrix entry behaves.
  path.rsplit({'/', '\\'}, maxsplit = 1)[^1]

proc findTestFiles(dir: string): seq[string] =
  for file in listFiles(dir):
    # Match the *basename*: `listFiles` returns a path, and every path under
    # tests/ starts with "t", so testing the whole path matches every file.
    if baseName(file).startsWith("t") and file.endsWith(".nim"):
      result.add(file)
  for subdir in listDirs(dir):
    if baseName(subdir) == "compile_fail":
      continue   # these must fail to compile; asserted separately below
    result.add(findTestFiles(subdir))

task test, "Run all tests":
  # Read this output rather than trusting `$?`: nimble 0.22.2 exits 0 even when
  # a task raises, so CI runs the same files through a shell loop that has a real
  # exit code. See .github/workflows/ci.yml.
  #
  # `nim r` on an empty module exits 0, so a scaffolded test file that was never
  # written would report a green run. Count what actually ran instead.
  var ran = 0
  var failed = 0
  for file in findTestFiles("tests"):
    if readFile(file).strip.len == 0:
      echo "WARNING: " & file & " is empty - nothing was tested by it"
      continue
    echo "Running: " & file
    try:
      exec "nim r --hints:off " & file
      inc ran
    except OSError:
      echo "FAILED: " & file
      inc failed

  # Negative compile checks: these files MUST fail to compile. `exec` raises when
  # the command exits non-zero, so a harness-free "did it fail" is a try/except.
  # The compiler output is printed either way, which is how you confirm it failed
  # for the intended reason rather than a typo.
  #
  # It must be a full `nim c`, not `nim check`: the `=copy is not available`
  # diagnostic comes from the destructor-injection pass, which `nim check` never
  # reaches (the same reason `compiles()` cannot observe it).
  for file in ["tests/compile_fail/noncopyable.nim"]:
    var failedAsExpected = false
    try:
      exec "nim c --hints:off " & file
    except OSError:
      failedAsExpected = true
    if not failedAsExpected:
      echo "FAILED: " & file & " compiled, but it must not"
      inc failed
    else:
      echo "compile-fail OK: " & file

  if failed > 0 or ran == 0:
    echo "TESTS FAILED: " & $failed & " file(s) failed, " & $ran & " passed"
    quit(1)
  echo "ALL TESTS PASSED (" & $ran & " files)"

task docs, "Build the API reference (src/htmldocs/), needs libproj present":
  exec "nim doc --project --index:on --hints:off src/nimproj.nim"

task docsSite, "Build the documentation site (needs: pip install mkdocs-material)":
  exec "mkdocs build --strict"
