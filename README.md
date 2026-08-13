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

The scheduled `brew bump` workflow checks npm for new Oring releases and opens
formula update pull requests automatically. To prepare the same update locally:

```bash
./scripts/update-oring.sh 0.0.7
```

The script updates the npm tarball URL and checksum, then runs Homebrew's style
check. Open a pull request with the resulting formula change; the test workflow
will audit and install it on macOS and Linux.
