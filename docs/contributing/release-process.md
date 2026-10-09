# Release process

Maintainer checklist, one version at a time. The version number lives in
`nimproj.nimble` and must match the git tag — nimble reads both.

## Before tagging

1. **Gate:** CI green on all matrix entries; `nimble test` and
   `mkdocs build --strict` green locally.
2. **Fixtures:** if the local PROJ moved, regenerate them
   (`bash tests/tools/gen_fixtures.sh`) and commit with the PROJ release string
   in the fixture header. Never edit a fixture by hand.
3. **Version bump:** set `version` in `nimproj.nimble`.
4. **Changelog:** move `## [Unreleased]` into `## [x.y.z] - YYYY-MM-DD`, in the
   [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) form. One entry per
   user-visible change; no entry for internal refactors.
5. **Docs:** every new exported symbol has a doc comment — `nimble docs` warns
   otherwise, and `--strict` on the site build is the gate.
6. **Flip the "in progress" notices.** Three places claim the release has not
   happened, and all three lie once the tag exists:
   - `README.md` — the status blockquote
   - `docs/index.md` — the `!!! warning "v0.1.0 in progress"` admonition
   - `CHANGELOG.md` — `[Unreleased]` becomes `## [x.y.z] - YYYY-MM-DD`

   `grep -rn "in progress" README.md docs/` is the check.

## Tag and publish

7. Tag and push:

   ```sh
   git tag vX.Y.Z
   git push origin main vX.Y.Z
   ```

7. Create the GitHub release from that tag, with the changelog section as the
   notes. The docs workflow deploys on `release: published`.
8. Publish to nimble — `nimble publish`, which reads the `.nimble` version and
   opens the PR. **First release only:** the index entry in
   `nim-lang/packages` must be added or updated (`nimproj` was verified free on
   2026-10-08); afterwards `nimble publish` updates it.

## Prove the release

9. In a clean environment, install from the index and run the README quick
   start verbatim:

   ```sh
   nimble install nimproj
   ```

   A release that only works from a checkout is not released.

Do not re-tag a published version. Ship the fix as the next patch — a moved tag
makes every downstream lockfile a lie.
