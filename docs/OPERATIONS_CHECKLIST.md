# Operations Checklist

## Error Monitoring

- Add Sentry SDK for Flutter app.
- Add Sentry SDK for Node backend.
- Set release + environment tags.

## Testing

- Add integration tests for:
  - mailbox load
  - search
  - reply + AI generation
  - attachment send
- Add backend API smoke tests.

## Release Controls

- CI pipeline:
  - flutter analyze
  - flutter test
  - server startup smoke test
- Build artifacts:
  - macOS signed package
  - Windows signed installer

## Updates

- Introduce desktop auto-update strategy:
  - staged rollout channels
  - rollback version policy

