# Architecture & Security

**My Sweet Home** follows **Clean Architecture** with **Ports & Adapters** so domain rules remain independent from Flutter, SQLite, and platform SDKs.

## Layered Architecture

```mermaid
flowchart LR
  UI["Presentation (Riverpod + GoRouter)"] --> Domain["Domain (Entities, Use Cases, Ports)"]
  Domain --> Data["Data (Drift SQLite, Vault, Sync Transport)"]
  Data --> Platform["Platform Adapters (ML Kit, Camera, Play Updates)"]
```

- **Presentation**: Riverpod state providers/controllers and `GoRouter` declarative navigation (`lib/features/*/presentation`, `lib/app/`).
- **Domain**: Pure Dart entities (`freezed`), `Result<T, Failure>` error handling, and abstract **Ports** (`lib/core/`, `lib/features/*/domain`).
- **Data**: **Drift** (reactive SQLite) repositories, local encrypted **Vault**, and **Sync Transport** (`CompositeSyncTransport` for LAN P2P and optional user-owned cloud storage).

## Security & Privacy Controls

| Control | Implementation |
|---|---|
| **Encrypted Local Database** | SQLite persistence protected by encryption keys managed via the `Vault` layer |
| **Deterministic Money & Time** | Money stored as integer cents (`int`); all timestamps persisted in **UTC** |
| **Offline-First Network Policy** | Zero unconsented network calls; external integrations sit behind testable ports |
| **Play Store Install Isolation** | Auto-update checks run only when installed from Google Play (`com.android.vending`) |

## Column-based CRDT Sync

When devices in a **Household** sync over LAN:

- Every shared table row tracks a stable row identity and per-column UTC timestamps.
- Concurrent offline edits on separate columns merge without conflict; edits to the same column resolve deterministically by timestamp and peer tie-breaker.

## Quality Gate (`make check`)

Every pull request and release runs the automated verification pipeline:

```bash
make check
```

`make check` enforces formatting (`make format`), up-to-date `build_runner` code generation, static analysis (`make analyze`), unit/widget/architecture tests (`make test`), and coverage thresholds (`make coverage`). See [CI/CD & Fastlane](infra/fastlane-deploy.md) for release automation details.
