# Link against libproj is declared in src/nimproj/private/proj_abi.nim, not here:
# the ABI layer owns its own linking requirements.

# Tests resolve `import nimproj/...` via tests/config.nims, not from here.

when defined(windows):
  # MSVC is the only toolchain that reliably finds the vcpkg proj.lib layout.
  switch("cc", "vcc")
