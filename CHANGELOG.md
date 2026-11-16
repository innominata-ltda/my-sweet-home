# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-16

### Added
- Personal finance tracking, monthly budgets, fixed bills, and CSV/PDF expense export.
- Shopping lists, pantry stock, price comparison, and on-device receipt OCR.
- Recurring household tasks, local reminders, and Fibonacci retention notifications.
- Encrypted local backup export/restore and peer-to-peer LAN household sync via `mshsync://invite`.
- Clean Architecture foundation with Drift encrypted storage and `make check` quality gate.
- Full English (`app_en.arb`) and Portuguese (`app_pt.arb`) localization parity across presentation screens.

### Fixed
- Backup import file picker accepting `.mshbak` backup files alongside onboarding copy cleanup.
- Distinct icons across economy mode, expenses, and budget screens, plus responsive header layout without button overlap.
