# OAuth Production Checklist

## Web

- Create Web OAuth client.
- Register production redirect URIs.
- Restrict JavaScript origins to deployed domains only.

## Desktop (macOS/Windows)

- Choose one strategy:
  - loopback redirect
  - custom URI scheme
- Register per-platform app identifiers.
- Validate token refresh flow across app restart.

## iOS

- Create iOS OAuth client linked to bundle ID.
- Configure URL types in Xcode project.
- Verify sign-in flow on device.

## Shared controls

- Separate staging and production OAuth clients.
- Restrict test users during staging.
- Rotate compromised secrets immediately.

