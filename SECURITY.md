# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| `0.1.x` | Yes |
| `< 0.1.0` | No |

## Security Scope

`my-sweet-home` is an offline-first application that stores all user data locally. Security reports are especially relevant for:

- Local SQLite database encryption and `Vault` credential storage
- Backup export/import key derivation (KDF) and authenticated encryption (AEAD)
- Local LAN `Household` pairing and `Sync Transport` message handling
- Receipt OCR or file import parsing boundaries

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Please report vulnerabilities privately using GitHub Private Vulnerability Reporting:

- https://github.com/innominata-ltda/my-sweet-home/security/advisories/new

### What to Include

- A clear description of the vulnerability and its potential impact
- Step-by-step reproduction instructions or a minimal proof of concept
- Affected version (`0.1.x`), platform (Android/iOS), and relevant configuration

We aim to acknowledge reports within 72 hours and coordinate a fix and advisory before public disclosure.
