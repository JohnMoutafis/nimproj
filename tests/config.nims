# Makes `nimble test` and a bare `nim c tests/t_x.nim` resolve
# `import nimproj/...` from this repo's src/, never from an installed copy of the
# package.
switch("path", "$projectDir/../src")
