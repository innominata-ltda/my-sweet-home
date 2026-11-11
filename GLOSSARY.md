# Glossary

Canonical domain and architectural terms used across `my-sweet-home`.

## Architecture & Framework
- **Column-based CRDT**: Conflict-free replicated data type engine tracking row identity and per-column timestamps to merge distributed peer updates deterministically.
- **Drift**: Type-safe reactive SQLite persistence framework for Dart and Flutter.
- **Riverpod**: Declarative reactive state management and dependency injection framework.
- **GoRouter**: Declarative URL-based routing system handling app navigation and nested tab routes.

## Domain Concepts
- **Household**: Collaborative household unit sharing products, shopping lists, expenses, and fixed bills across peer devices.
- **Sync Transport**: Transport abstraction responsible for synchronization (CompositeSyncTransport composing local LAN pairing and optional remote cloud storage adapters).
- **Mascot (Momo)**: Contextual assistant character delivering friendly household alerts, budget summaries, and onboarding guidance.
- **Receipt OCR**: Optical character recognition pipeline parsing physical receipt images into structured line items and prices.
- **Vault**: Local encrypted storage layer securing sensitive application credentials and database encryption keys.
