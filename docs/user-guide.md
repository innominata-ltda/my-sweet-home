# User Guide

This guide walks through the core modules of **My Sweet Home** and how they work together offline-first.

## 1. Finances & Monthly Budget

- **Expenses & Fixed Bills**: Record daily expenses and recurring household bills with due dates and payment tracking.
- **Monthly Balance**: View spent vs. budgeted totals per category with charts (`fl_chart`) and historical comparisons.
- **Precision**: Monetary amounts are stored internally as integer cents (`int`) to prevent floating-point rounding errors.

## 2. Shopping Lists & Receipt OCR

- **Smart Shopping Lists**: Organize items by category, mark purchases in real time, and track historical item prices across stores.
- **On-Device Receipt OCR**: Point the camera at a physical supermarket receipt to parse store name, line items, and totals locally via ML Kit Text Recognition. No receipt image leaves your device.

## 3. Tasks, Routines & Mascot (Momo)

- **Chores & Schedules**: Create one-off or recurring household tasks with local notifications (`flutter_local_notifications`).
- **Mascot (Momo)**: Provides friendly contextual alerts, budget summaries, and onboarding tips without intrusive pop-ups.

## 4. Recipes, Stock & First-Home Checklist

- **Pantry Stock**: Track quantities of staple items at home and move low-stock items directly to your shopping list.
- **Recipes**: Save household recipes and link required ingredients to your pantry and shopping lists.
- **First-Home Checklist**: Built-in checklist to help people moving into their first home track essentials.

## 5. LAN Household P2P Sync

Share a **Household** with roommates or family members on the same local Wi-Fi network without a central server:

1. Open **Household** settings on Device A and display the local pairing QR code.
2. Scan the QR code from Device B to establish a local peer-to-peer **Sync Transport** session.
3. Changes to shared expenses, bills, shopping lists, and products merge deterministically using the **Column-based CRDT** engine.

## 6. Encrypted Backups

- **Local Encrypted Archive**: Export a password-protected backup file containing your encrypted database snapshot and restore it on another device.
- **Optional Google Drive Sync**: Optionally store the encrypted archive in your own Google Drive account. The archive stays encrypted with your passphrase before upload.
