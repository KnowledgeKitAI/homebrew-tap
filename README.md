# KnowledgeKitAI Homebrew Tap

Official Homebrew formulae for KnowledgeKitAI tools.

## Oring

Install the current stable Oring release directly:

```bash
brew install KnowledgeKitAI/tap/oring
```

Or add the tap first and then use the short formula name:

```bash
brew tap KnowledgeKitAI/tap
brew install oring
```

Verify the installation:

```bash
oring --version
oring --help
```

Upgrade or remove it with normal Homebrew commands:

```bash
brew upgrade oring
brew uninstall oring
```

Oring documentation and source live in the
[KnowledgeKitAI/oring](https://github.com/KnowledgeKitAI/oring) repository.

## Maintaining the formula

The live `0.0.6` formula still installs the npm package and Node. Its legacy npm
bump workflow is manual-only so it cannot race the planned switch to
self-contained binaries.

After a reviewed Oring release publishes all four public GitHub assets and
checksum sidecars, prepare the binary formula atomically with:

```bash
./scripts/update-oring.sh 0.0.7
```

The updater downloads macOS ARM64/x64 and Linux ARM64/x64 archives, validates
their provided SHA-256 checksums, verifies that each archive contains exactly
the expected `oring` executable, and only then replaces the formula. The new
formula installs that executable directly and has no Node or Bun dependency.

The updater never commits, pushes, merges, tags, or publishes. Review its diff
and open a pull request; CI audits, installs, and tests the formula on native
runners for all four supported host combinations. The live formula must not be
switched until the assets are anonymously downloadable. The Oring source
repository is currently private, so either that repository must become public
or the release pipeline must provide another public immutable asset origin.

Test the updater itself without network access or formula changes:

```bash
./scripts/test-update-oring.sh
```

Formula upgrades and rollbacks do not remove Oring user configuration,
credentials, state, backups, or synchronized data. Roll back the executable by
reverting the formula commit to an earlier immutable release; do not overwrite
published assets or reuse a version number.
