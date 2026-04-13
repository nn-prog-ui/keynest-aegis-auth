# Nemokey

Nemokey is a Flutter-based authenticator app focused on TOTP, push approvals, and secure restore.

## Positioning

Nemokey is designed to work in two modes:

- Individual use: a lightweight authenticator with QR onboarding, code display, and restore
- Team / business use: a branded sign-in approval app with push approvals and recovery flows

## Core features

- QR onboarding for `otpauth://` accounts
- RFC6238 TOTP generation (SHA1/SHA256/SHA512, 6-8 digits)
- Push sign-in approvals (Approve / Deny)
- Device lock (biometric / device authentication)
- Encrypted backup / restore (PBKDF2 + AES-256-GCM)
- Offline fallback for backup restore testing

## Current identifiers

- Android Application ID: `com.aegisauth.app`
- iOS Bundle ID: `com.nnprogui.keynestauth`
- macOS Bundle ID: `com.aegisauth.app.macos`

## Run locally

```bash
flutter pub get
flutter run
```

## Release docs

- GTM / positioning: `docs/release/GTM_POSITIONING_KEYNEST.md`
- Store copy: `docs/release/STORE_COPY_KEYNEST.md`
- Landing page copy: `docs/release/LP_COPY_KEYNEST.md`
- Launch playbook: `docs/release/LAUNCH_PLAYBOOK_KEYNEST.md`
- Outreach templates: `docs/release/OUTREACH_TEMPLATES_KEYNEST.md`
- Device flow QA: `docs/release/AEGIS_DEVICE_FLOW_QA.md`
- Permissions copy: `docs/release/PERMISSIONS_COPY_AEGIS.md`
- Privacy policy: `docs/PRIVACY_POLICY_AEGIS_AUTH.md`
- Screenshot guide: `docs/release/STORE_SCREENSHOT_GUIDE_AEGIS.md`
- Signing setup: `docs/release/SIGNING_SETUP_AEGIS.md`

## Backend endpoints (current)

- `POST /api/keynest/push/register`
- `POST /api/keynest/push/send-test`
- `POST /api/keynest/backup/save`
- `POST /api/keynest/backup/load`
