# Platform Roadmap

## Phase 1: macOS

1. Validate app behavior on `flutter run -d macos`.
2. Confirm key flows:
   - login
   - mailbox list/detail
   - reply/reply-all/forward
   - attachment send
3. Prepare release signing:
   - Apple Developer certificate
   - App ID + entitlements
4. Notarize package and generate `.dmg`.

## Phase 2: Windows

1. Build on Windows machine or CI:
   - `flutter build windows`
2. Verify IMAP/SMTP + AI flows.
3. Sign installer/binary.
4. Package with MSIX or signed EXE installer.

## Phase 3: iOS

1. Split OAuth config for iOS-specific client.
2. Add proper URL schemes + bundle identifiers.
3. Verify login and mail actions on physical device.
4. Archive and distribute via TestFlight.

