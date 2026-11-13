# Privacy Policy

**Effective Date**: 2026-11-13
**Application**: My Sweet Home (`com.innominata.my_sweet_home`)
**Publisher**: Innominata Ltda

## 1. Summary

**My Sweet Home is offline-first.** Your financial records, shopping lists, receipts, tasks, and recipes remain on your device inside an encrypted local SQLite database. We do not operate central user-data servers, we do not display ads, and we do not collect analytics or behavioral telemetry.

## 2. Data Storage and Security

- **Local Storage**: All application data is stored locally on your device using Drift (SQLite) protected by local encryption keys managed by the `Vault` layer.
- **Money & Timestamps**: Financial amounts are stored locally as integer cents and timestamps in UTC.
- **No Account Required**: You do not need to create an online account, provide an email address, or sign in to use the application.

## 3. Device Permissions

The application requests only the permissions required for explicit user-triggered features:

- **Camera (`android.permission.CAMERA`)**: Used strictly on-device for:
  1. **Receipt OCR**: Extracting store names, items, and prices from physical receipts using on-device ML Kit text recognition. Images and parsed text are never uploaded to our servers.
  2. **LAN Household Pairing**: Scanning a local pairing QR code to connect two devices on the same Wi-Fi network.
- **Local Network / Wi-Fi**: Used only when you explicitly start a **Household** peer-to-peer sync session on your local network.
- **Notifications**: Used to deliver local reminders for recurring bills and household tasks.

## 4. Optional Backups and External Links

- **Encrypted Local Backups**: You can export and restore password-protected encrypted backup archives directly on your device.
- **Optional Cloud Backup (User-Owned)**: If you choose to enable Google Drive backup, the encrypted backup file is stored in your own Google Drive account under your direct control. The publisher has no access to your Drive files or encryption passphrase.
- **Google Play Updates**: On Google Play installations, the app checks Google Play Services solely to offer official app updates. On sideloaded or GitHub Release builds, this check is disabled.

## 5. Data Deletion

Because all data lives on your device, you have complete control over it:

- Delete individual items or reset data inside the application, or
- Uninstall the application to remove all local database and `Vault` data from your device.

## 6. Contact

For privacy questions or security reports, please open an issue or review [SECURITY.md](https://github.com/innominata-ltda/my-sweet-home/blob/main/SECURITY.md) in the public repository.
