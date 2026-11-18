# GoIndiaTracker — Admin Console

Flutter **web** admin panel for the [deep-link URL shortener platform](../README.md).
Register mobile apps, issue and rotate per-app SDK keys, create and manage tracked deep
links, and view click/attribution metrics.

## Stack

- **Flutter Web** with **Riverpod** state and **go_router** (auth-gated routing)
- **Dio** HTTP client with a JWT `Authorization` interceptor
- Talks to the same backend as the mobile app and SDK (`URLShortenerBackend`)

## Running

```bash
flutter pub get
flutter run -d chrome --web-port=8080     # defaults to http://localhost:8082/api
```

Override the backend for other environments:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://api.example.com/api
```

## Configuration

The backend base URL lives in [`lib/config/app_config.dart`](./lib/config/app_config.dart)
and is injected via `--dart-define=API_BASE_URL` (default `http://localhost:8082/api`).
Note: because this is a web build, the URL is visible to any browser client — keep it a
public API host, and enforce all authorization server-side.

## Structure

```
lib/
├── config/app_config.dart   # runtime configuration
├── models/                  # app_model, deep_link_model
├── providers/providers.dart # apiService, auth, apps, links providers
├── router/router.dart       # go_router with auth redirect
├── screens/                 # auth, dashboard, overview, apps, links, link_details
└── services/api_service.dart# single Dio client (admin endpoints)
```

## Authentication

JWT-based: `POST /auth/login` (or `/signup`) returns a token stored in
`shared_preferences` and attached as `Authorization: Bearer …`. Access control is enforced
by the backend — the console only gates routing on token presence.

## Known limitations / demo scope

- Some overview figures are illustrative: "attributed installs" is estimated as
  `clicks × 0.25` and the per-link match rate is a static placeholder.
- Token validity is checked lazily (on the next API call), not proactively refreshed.