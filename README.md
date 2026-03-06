# Aegis Auth

Aegis Auth is a Flutter-based authenticator app inspired by enterprise verification flows.

## Core features

- QR onboarding for `otpauth://` accounts
- RFC6238 TOTP generation (SHA1/SHA256/SHA512, 6-8 digits)
- Push sign-in approvals (Approve / Deny)
- Device lock (biometric / device authentication)
- Encrypted backup/restore (PBKDF2 + AES-256-GCM)
- Offline fallback for backup restore testing

## Run locally

```bash
flutter pub get
flutter run
```

## Build identifiers

- Android Application ID: `com.aegisauth.app`
- iOS Bundle ID: `com.aegisauth.app`

## Release docs

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

