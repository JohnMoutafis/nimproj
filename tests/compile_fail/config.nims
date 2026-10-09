# Same rule as every other directory holding .nim files that import the package:
# Nim reads config.nims from the main file's own directory, not its ancestors.
switch("path", "$projectDir/../../src")
