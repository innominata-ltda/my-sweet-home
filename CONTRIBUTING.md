# Contributing to My Sweet Home

Thank you for your interest in contributing to `my-sweet-home`. This project is offline-first, 100% free, and built with clean architecture and high test coverage.

## Getting Started

1. Follow [SETUP.md](SETUP.md) to install Flutter, Java 17, and the Android SDK.
2. Run `make setup` to fetch dependencies and generate code (`freezed`, `drift`, `riverpod`).
3. Review [GLOSSARY.md](GLOSSARY.md) for canonical domain and architecture terms.

## Architecture Boundaries

Source code under `lib/` is organized into four layers:

- `core/`: Shared primitives, domain utilities, `Vault` encryption, and base abstractions.
- `data/`: Drift (SQLite) database, repositories, and `Sync Transport` implementations.
- `features/`: Feature modules with domain logic, Riverpod state, and UI screens.
- `design_system/`: Reusable UI components, theme tokens, and Mascot (Momo) assets.

Key rules:
- External integrations must be isolated behind ports with deterministic fakes.
- Money values are stored as integer cents (`int`); timestamps are stored in UTC.
- User-facing strings must be localized via ARB files (no hardcoded UI literals).
- Enforce layer boundaries with `make arch`.

## Quality Gate

Run the full verification suite before opening a pull request:

```bash
make check
```

`make check` verifies formatting (`make format`), generated code sync (`make check-gen`), static analysis (`make analyze`), unit/widget tests (`make test`), and code coverage thresholds (`make coverage`, >= 90%).

## Branching, Commits, and Pull Requests

- **Branching (Gitflow)**: Branch `feature/<issue>/<slug>` or `bugfix/<issue>/<slug>` from `develop`, and target `develop` in pull requests.
- **Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/) in English, GPG-signed, with at most 200 changed lines per commit.
- **Pull Requests**: Fill out all sections of `.github/PULL_REQUEST_TEMPLATE.md`, including `make check` evidence.
- **Public Readiness**: Never commit secrets, `.env` files, credentials, or personal data.

## Adding a Language or Receipt Format

Regionalization is registry-driven so new languages and receipt parsers can be added without modifying UI plumbing:

1. **New App Language**:
   - Create `lib/app/l10n/app_<lang>.arb` matching all keys in `lib/app/l10n/app_pt.arb` and run `flutter gen-l10n`.
   - Append an `AppLocaleDescriptor` entry in `AppLocaleRegistry.supportedLocales` (`lib/core/regionalization/regionalization_models.dart`).
   - Verify the new option appears in Settings (`SettingsPage`) and passes `make check`.
2. **New Regional Receipt Format (OCR)**:
   - Implement `ReceiptParser` (`lib/features/ocr/domain/receipt_parser.dart`) in `lib/features/ocr/domain/` using pure Dart (no Flutter/Drift imports).
   - Register its `ReceiptFormatDescriptor` in `ReceiptFormatCatalog.descriptors` (`lib/core/regionalization/regionalization_models.dart`).
   - Register the parser instance under the same key in `ReceiptFormatRegistry.parsers` (`lib/features/ocr/domain/receipt_format_registry.dart`).
   - Add unit tests in `test/features/ocr/` covering sample OCR documents and `CompositeReceiptParser` scoring.
