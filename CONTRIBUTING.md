# Contributing

Thanks for your interest in improving Smart TV Remote Control. This guide
covers local setup, tests, code style, commits, and the PR process.

## Setup

Prerequisites:

- Flutter `>= 3.47.0`
- A real Android or iOS device on the same Wi-Fi as a supported TV
  (emulators rarely work — UPnP / mDNS need real local-network access)

Looking for something to pick up? Issues labelled
[`good first issue`](https://github.com/mazen-salah/Smart-TV-Remote-Control/labels/good%20first%20issue)
are scoped for newcomers, and
[`help wanted`](https://github.com/mazen-salah/Smart-TV-Remote-Control/labels/help%20wanted)
marks work where a maintainer needs hardware or expertise they do not have.
Please read the [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

Clone and bootstrap:

```bash
git clone https://github.com/mazen-salah/Smart-TV-Remote-Control.git
cd Smart-TV-Remote-Control
flutter pub get
flutter run
```

If you are touching the localization files, regenerate the bindings:

```bash
flutter gen-l10n
```

## Tests

Run the full suite before opening a PR:

```bash
flutter test
```

Bloc tests use `bloc_test` and `mocktail`. When adding a new bloc, add a
test file under `test/blocs/` with the same shape as the existing ones.

The suite mirrors `lib/`:

| Directory | What it covers |
| --- | --- |
| `test/blocs/` | bloc transitions with a mocked repository |
| `test/core/` | models, storages, and the repository (real storages, mocked services) |
| `test/services/` | protocol and classification logic |
| `test/ui/` | widget tests for the picker and dialogs |

`test/services/lg/` drives the real webOS client against `FakeWebOsTv`, a
local stand-in TV that speaks the protocol over a genuine WebSocket. Use it
when changing pairing, transport, or key handling — it covers the paths that
are otherwise only reachable with hardware. Its TLS mode needs `openssl` on
the PATH.

Every CI run prints a coverage summary in its job summary on the Actions
tab, with the least-covered files listed. New code should come with tests;
`flutter test --coverage` writes `coverage/lcov.info` locally.

Coverage is also uploaded to Codecov when a `CODECOV_TOKEN` secret is
configured; without it that step is skipped and CI is unaffected.

## Code style

- **Lints**: `very_good_analysis` is enforced via `analysis_options.yaml`
  (a few rules are relaxed there, each with a comment saying why). CI fails
  on any reported issue, including infos.
- **Format**: run `dart format .` before committing. CI will reject
  unformatted code.
- **Static analysis**: `flutter analyze` must pass with zero issues.

Layering rules (do not break these):

- UI talks to **blocs** only.
- Blocs talk to **repositories** only.
- Repositories talk to **services**.
- Services talk to the network / OS.

Do not import a service directly from a widget.

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/).
Format:

```
<type>(<scope>): <short summary>
```

Common types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`.

Examples:

```
feat(samsung): persist pairing token across launches
fix(discovery): handle mDNS responses with missing TXT records
refactor(blocs): split TvConnectionBloc state into sealed classes
docs(readme): document Wake-on-LAN troubleshooting
```

## Pull requests

1. Fork the repo and create a branch off `main`:
   `git checkout -b feat/my-change`
2. Make your change. Add or update tests.
3. Run `dart format .`, `flutter analyze`, and `flutter test` — all must
   pass cleanly.
4. Update `CHANGELOG.md` under `## [Unreleased]` describing what changed.
5. Open a PR with:
   - A clear description of the problem and the fix
   - Screenshots or a screen recording for any UI change
   - The TV model(s) you tested against, if relevant
6. Address review feedback by pushing additional commits — do not
   force-push during review.

## Reporting bugs

Please include:

- Phone OS and version
- TV brand, model, and firmware year
- Whether discovery, connect, or control is failing
- Relevant logs from `flutter logs`

Thanks for contributing.
