# My Sweet Home

**My Sweet Home** is a 100% free, ad-free, offline-first Flutter application built for people managing a home on their own or sharing a **Household** with family and roommates.

## Core Principles

- **Offline-first & private**: All personal data is stored locally in an encrypted SQLite database (`Vault` + Drift). No mandatory cloud account, no ads, and no telemetry.
- **Zero-cost & open source**: Released under the MIT License (`assets/seed/` under CC BY 4.0) with full source transparency on [GitHub](https://github.com/innominata-ltda/my-sweet-home).
- **Deterministic & tested**: Clean Architecture with Ports & Adapters, deterministic fakes, and a strict quality gate (`make check`).

## What You Can Manage

- **Finances & Budget**: Track expenses, fixed bills, and monthly budgets (stored as integer cents).
- **Shopping & Receipt OCR**: Maintain shopping lists, track price history, and scan physical receipts on-device with ML Kit.
- **Tasks & Routines**: Organize daily chores and recurring household schedules with local notifications.
- **Recipes & Stock**: Plan meals, track pantry stock, and use the first-home checklist.
- **LAN Household Sync**: Pair nearby devices over local Wi-Fi using QR codes and merge updates via a `Column-based CRDT`.

## Installation Options

| Channel | Update Mechanism | Best For |
|---|---|---|
| **Google Play Store** | Automatic In-App Updates via Play Store | Most Android users wanting automatic updates |
| **GitHub Releases** | Manual APK download + SHA-256 verification | Users without Google Play Services or auditing builds |

!!! note "Update Behavior on GitHub Release Builds"
    Builds installed outside Google Play (`com.android.vending`) automatically disable Play Store update prompts. You can always verify downloaded APKs against `SHA256SUMS.txt` attached to each [GitHub Release](https://github.com/innominata-ltda/my-sweet-home/releases):

    ```bash
    sha256sum -c SHA256SUMS.txt
    ```

## Next Steps

- Read the [User Guide](user-guide.md) to explore each module.
- Review [Architecture & Security](architecture.md) for technical internals.
- Read the [Privacy Policy](privacy.md) for data and permission details.
