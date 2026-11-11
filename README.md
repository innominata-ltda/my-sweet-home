# My Sweet Home (`my-sweet-home`)

Mobile application **100% free, no ads, and no subscriptions** designed for people living on their own for the first time: finances, grocery shopping, price tracking, chores, recurring bills, and recipes — **offline-first** with all personal data stored directly on the device.

---

## Overview

My Sweet Home is an offline-first Flutter application built with a focus on privacy, determinism, and reliability:
- **Local-first & private**: All data resides in an encrypted SQLite database on the device. No remote accounts or telemetry required.
- **Spec-driven & clean architecture**: Separation of domain entities, ports, repositories, and UI state. External integrations are isolated behind ports with deterministic fakes.
- **Tested & reliable**: Strict architecture rules, high test coverage, and comprehensive unit, widget, and integration test suites.

## Tech Stack

- **Framework**: Flutter & Dart
- **State Management**: Riverpod
- **Routing**: `go_router`
- **Persistence**: Drift (SQLite) with encrypted storage
- **Data Modeling**: `freezed` & `json_serializable`
- **On-Device OCR**: ML Kit Text Recognition
- **Notifications**: `flutter_local_notifications`
- **Charts & UI**: `fl_chart`, Material Symbols

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

## Quick Start

### Prerequisites

Follow the step-by-step setup guide in [SETUP.md](SETUP.md) to configure Flutter, Java 17, and the Android SDK.

### Common Commands

All common tasks are automated via `make`:

| Command | Description |
|---|---|
| `make check` | **Primary quality gate**: format, codegen check, analyze, tests, and coverage |
| `make test` | Run all unit and widget tests |
| `make coverage` | Verify test coverage thresholds |
| `make analyze` | Run static analysis (`dart analyze lib test`) |
| `make format` | Check Dart code formatting |
| `make gen` | Generate code with `build_runner` |
| `make e2e` | Run end-to-end integration tests on an emulator or device |

## Key Conventions

- **Money is represented as an integer in cents** (`int`).
- **Timestamps are stored in UTC**.
- **External integrations are isolated behind ports** with deterministic fakes, enabling complete testability without a physical device or network.
- **No unconsented network calls**: The application is offline-first.

For detailed domain terms, see [GLOSSARY.md](GLOSSARY.md).

## License

Source code is licensed under the **MIT License** (see [LICENSE](LICENSE)).
Documentation and the regional synonym seed dataset in `assets/seed/` are licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**.
