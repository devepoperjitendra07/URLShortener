# URLShortener — Mobile App

Flutter client for the [deep-link URL shortener platform](../README.md). Sign up, shorten
URLs (with custom slug, expiry and deep-link config), browse link history, view per-link
click analytics, and inspect a live backend/system-status dashboard. It also bundles the
[`go_india_tracker`](../go_india_tracker) SDK to demonstrate deferred + direct deep linking.

## Stack

- **Flutter** with **Riverpod** (`Notifier`/`NotifierProvider`) for state
- **Dio** HTTP client with a JWT `Authorization` interceptor
- **fl_chart** analytics, **qr_flutter** device-fingerprint QR, `share_plus`, `intl`
- `go_india_tracker` (local path dependency) for deep-link resolution

## Running

```bash
flutter pub get
flutter run                     # defaults to http://localhost:8082/api
```

Point it at a different backend without editing code:

```bash
# Android emulator (host loopback)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8082/api

# Production build
flutter build apk \
  --dart-define=API_BASE_URL=https://api.example.com/api \
  --dart-define=SDK_KEY=git_live_xxxxx \
  -PdeepLinkHost=links.example.com
```

## Configuration

All environment-specific values live in [`lib/config/app_config.dart`](./lib/config/app_config.dart)
and are injected via `--dart-define` — nothing is hardcoded:

| Define | Default | Purpose |
|--------|---------|---------|
| `API_BASE_URL` | `http://localhost:8082/api` | Backend REST base |
| `SDK_KEY` | `sdk_test_12345` (demo) | Key passed to the tracker SDK |
| `deepLinkHost` (gradle `-P`) | `links.example.com` | App Links host in the Android manifest |

## Structure

```
lib/
├── config/app_config.dart   # runtime configuration
├── models/                  # user, short_link, deep_link_config, system_status, ddl_log
├── providers/providers.dart # auth + history Riverpod notifiers
├── screens/                 # auth, home, shorten, history, analytics, system_status
└── services/api_service.dart# single Dio client (all endpoints)
```

## Tests

```bash
flutter test
```

Covers the auth and history providers (mocked `ApiService`) and the auth screen widget.

## Notes

- The app targets `localhost` by default; a real device/emulator needs `API_BASE_URL`
  pointed at a reachable host (see above).
- The release build currently signs with the debug keystore — add a real signing config
  before publishing.
