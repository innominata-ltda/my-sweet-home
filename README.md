# My Sweet Home (`my-sweet-home`)

[![Flutter CI](https://github.com/innominata-ltda/my-sweet-home/actions/workflows/flutter.yml/badge.svg?branch=develop)](https://github.com/innominata-ltda/my-sweet-home/actions/workflows/flutter.yml)
[![Validate](https://github.com/innominata-ltda/my-sweet-home/actions/workflows/validate.yml/badge.svg?branch=develop)](https://github.com/innominata-ltda/my-sweet-home/actions/workflows/validate.yml)
[![GitHub Pages](https://github.com/innominata-ltda/my-sweet-home/actions/workflows/pages.yml/badge.svg?branch=develop)](https://github.com/innominata-ltda/my-sweet-home/actions/workflows/pages.yml)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.47.5-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.13.4-0175C2?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-2048%20passing-2ea44f)](#quality--test-coverage)
[![License](https://img.shields.io/badge/License-MIT%20%2F%20CC%20BY%204.0-blue)](#license)

Mobile application **100% free, no ads, and no subscriptions** designed for people living on their own: personal finances, grocery shopping, price comparison, chores, recurring bills, and recipes -- **offline-first** with all personal data stored directly on the device.

---

## Overview & Features

My Sweet Home is built with a focus on privacy, determinism, and reliability:

- **Personal Finances & Recurring Bills**: Track expenses in integer cents, categorize spending, set budgets, and manage due dates with local notifications.
- **Shopping Lists & Price Comparison**: Maintain pantry and grocery lists, compare unit prices across stores, and log receipts.
- **On-Device Receipt OCR & QR Parsing**: Scan receipts locally using ML Kit Text Recognition and extensible regional receipt parser templates -- zero cloud uploads.
- **Household Chores & Recipes**: Schedule recurring home tasks and organize personal recipes offline.
- **Encrypted Backup & LAN Sync**: Export/restore encrypted archives and sync across local devices on the same network without third-party servers.
- **Privacy by Design**: Encrypted local SQLite database (Drift), Android Auto Backup disabled (`allowBackup="false"`), and no telemetry or unconsented network calls.

---

## Tech Stack

| Area | Technology |
|---|---|
| Framework | Flutter (`>=3.47.5`) & Dart (`>=3.13.4`) |
| State Management | Riverpod (`flutter_riverpod`) |
| Routing | `go_router` |
| Persistence | Drift (SQLite) with encrypted local storage |
| Data Modeling | `freezed` & `json_serializable` |
| On-Device OCR | `google_mlkit_text_recognition` & `mobile_scanner` |
| Notifications | `flutter_local_notifications` |
| Charts & UI | `fl_chart`, Material Symbols |

---

## Quality & Test Coverage

Every pull request must pass `make check` (formatting, generated code verification, static analysis, architecture rules, full test suite, and per-layer coverage thresholds).

Verified baseline on `develop` (`2048` tests passing):

| Architectural Layer | Measured Coverage | Minimum Threshold | Status |
|---|---|---|---|
| `lib/core/` | `95.8%` | `95%` | Pass |
| `lib/data/` | `86.9%` | `85%` | Pass |
| `lib/design_system/` | `95.3%` | `60%` | Pass |
| `lib/features/*/data/` | `87.7%` | `85%` | Pass |
| `lib/features/*/domain/` | `90.8%` | `90%` | Pass |
| `lib/features/*/presentation/` | `76.8%` | `60%` | Pass |

Run locally via `make check` or `make coverage`.

---

## Quick Start

### Prerequisites

Follow the step-by-step setup guide in [SETUP.md](SETUP.md) to configure Flutter, Java 17, and the Android SDK.

### Common Commands

All common development and verification tasks are automated via `make`:

| Command | Description |
|---|---|
| `make check` | **Primary quality gate**: format, codegen check, analyze, tests, and coverage |
| `make test` | Run all unit and widget tests |
| `make coverage` | Verify per-layer test coverage thresholds |
| `make analyze` | Run static analysis (`dart analyze lib test`) |
| `make format` | Check Dart code formatting |
| `make gen` | Generate code with `build_runner` |
| `make e2e` | Run end-to-end integration tests on an emulator or device |

---

## Repository Structure

```text
lib/                 Application source code (core, data, features, design system)
test/                Unit, widget, architecture, and fake tests
integration_test/    End-to-end integration tests for physical devices/emulators
scripts/             Verification, coverage, and development automation scripts
android/             Android runner and Fastlane release automation
ios/                 iOS runner
assets/              Fonts, initial database seed data, and license attributions
```

### Key Conventions

- **Money is represented as an integer in cents** (`int`).
- **Timestamps are stored in UTC**.
- **External integrations are isolated behind ports** with deterministic fakes for offline testability.
- **No unconsented network calls**: The application is strictly offline-first.

For detailed domain terminology, see [GLOSSARY.md](GLOSSARY.md).

---

## Regionalization & Contributing

Contributions are welcome -- especially new languages (`lib/l10n/`), currency/locale formats, and regional receipt parser templates!

- **Contribution Guide**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Local Environment Setup**: [SETUP.md](SETUP.md)
- **Security Policy**: [SECURITY.md](SECURITY.md)
- **Domain Glossary**: [GLOSSARY.md](GLOSSARY.md)

---

## Documentation & Privacy Policy

- **Project Wiki & User Guide**: [innominata-ltda.github.io/my-sweet-home](https://innominata-ltda.github.io/my-sweet-home/)
- **Privacy Policy**: [innominata-ltda.github.io/my-sweet-home/privacy](https://innominata-ltda.github.io/my-sweet-home/privacy/)
- **Architecture & Security**: [innominata-ltda.github.io/my-sweet-home/architecture](https://innominata-ltda.github.io/my-sweet-home/architecture/)

---

## License

- Source code is licensed under the **MIT License** (see [LICENSE](LICENSE)).
- Documentation and the regional synonym seed dataset in `assets/seed/` are licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**.
