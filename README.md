# 🔗 URLShortener Platform

> A full-stack URL shortening & **Deferred Deep Linking (DDL)** platform built for mobile-first use cases.  
> It combines a Spring Boot REST API, two Flutter applications, and a Flutter SDK — all in one mono-repo.

---

## 📦 Repository Structure

```
URLShortener/
├── URLShortenerBackend/        # Spring Boot 3.3 (Java 21) REST API
├── URLShortenerFlutterApp/     # Flutter mobile app (end-user client)
├── go_india_tracker/           # Flutter SDK — Deferred Deep Linking & analytics
└── go_india_tracker_admin/     # Flutter web admin dashboard
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────┐     JWT / SDK-Key      ┌──────────────────────────┐
│  Flutter Mobile App │ ─────────────────────► │   Spring Boot REST API   │
│  (URLShortenerApp)  │                         │   :8082/api              │
└─────────────────────┘                         │                          │
                                                │  ┌──────────┐           │
┌─────────────────────┐     JWT Auth            │  │PostgreSQL│ (Flyway)  │
│  Flutter Admin Web  │ ─────────────────────►  │  └──────────┘           │
│  (go_india_tracker_ │                         │  ┌──────────┐           │
│   admin)            │                         │  │  Redis   │ (cache)   │
└─────────────────────┘                         │  └──────────┘           │
                                                └──────────────────────────┘
┌─────────────────────┐     HTTP (SDK Key)              ▲
│  go_india_tracker   │ ───────────────────────────────-┘
│  (Flutter DDL SDK)  │   DDL resolve / fingerprint
└─────────────────────┘
```

---

## 🚀 Components

### 1. `URLShortenerBackend` — Spring Boot API

| Property | Value |
|----------|-------|
| Framework | Spring Boot 3.3 |
| Language | Java 21 |
| Database | PostgreSQL 16 (Flyway migrations V1–V7) |
| Cache | Redis 7 (redirect cache, click buffer, DDL fingerprints) |
| Auth | JWT (JJWT 0.12 · HS256) + SDK-Key filter |
| Port | `:8082`, context path `/api` |

#### Key API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/auth/signup` | Public | Register a new user |
| `POST` | `/auth/login` | Public | Login and receive JWT |
| `POST` | `/shorten` | JWT | Create a short link |
| `GET` | `/{shortCode}` | Public | Redirect to long URL |
| `GET` | `/links` | JWT | List user's links |
| `GET` | `/analytics/{shortCode}` | JWT | Per-link analytics |
| `POST` | `/admin/apps` | JWT | Register a mobile app |
| `GET` | `/admin/apps` | JWT | List apps & SDK keys |
| `POST` | `/ddl/register` | SDK Key | Register DDL fingerprint |
| `POST` | `/ddl/resolve` | SDK Key | Resolve deferred deep link |
| `GET` | `/.well-known/assetlinks.json` | Public | Android App Links verification |

#### Database Schema (Flyway)

| Migration | Table | Purpose |
|-----------|-------|---------|
| V1 | `users` | Auth — email/password accounts |
| V2 | `url_mappings` | Short links with deep-link config |
| V3 | `clicks` | Per-click analytics events |
| V4 | `ddl_logs` | DDL resolver audit log |
| V5–V7 | `apps`, `sdk_keys` | Multi-app SDK key management |

#### Running Locally

```bash
# 1. Start infrastructure
cd URLShortenerBackend
docker compose up -d          # PostgreSQL + Redis

# 2. Run the API
./mvnw spring-boot:run        # → http://localhost:8082/api
```

#### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SERVER_PORT` | `8082` | HTTP port |
| `APP_BASE_URL` | `http://localhost:8082/api` | Short URL base |
| `DB_URL` | `jdbc:postgresql://localhost:5432/urlshortener` | Postgres URL |
| `DB_USERNAME` / `DB_PASSWORD` | `adda247` / `secret` | Postgres creds |
| `REDIS_HOST` / `REDIS_PORT` | `localhost` / `6379` | Redis |
| `JWT_SECRET` | *(dev placeholder)* | HS256 key — **override in prod** |
| `JWT_EXPIRY_MS` | `86400000` | Token TTL (24 h) |
| `APP_CORS_ALLOWED_ORIGINS` | `localhost:8080,localhost:3000` | CORS whitelist |

> [!CAUTION]
> Never deploy with the default `JWT_SECRET` or database credentials. Set strong values via environment variables or a secrets manager.

---

### 2. `URLShortenerFlutterApp` — Mobile Client

A Flutter mobile application that lets end-users authenticate, create/manage short links, view click analytics, and inspect system status.

| Property | Value |
|----------|-------|
| Flutter SDK | `^3.8.1` |
| State management | `flutter_riverpod ^3.3.2` |
| Navigation | `go_router ^17.0.0` |
| HTTP | `dio ^5.10.0` |
| Local storage | `hive ^2.2.3` + `shared_preferences` |
| Charts | `fl_chart ^0.69.0` |
| QR code | `qr_flutter ^4.1.0` |
| Sharing | `share_plus ^12.0.2` |
| Deep linking | `app_links ^6.3.0` |

#### Screens

| Screen | Description |
|--------|-------------|
| `auth_screen.dart` | Login / Sign-up |
| `home_screen.dart` | Main navigation shell |
| `shorten_screen.dart` | Create / customize a short link |
| `history_screen.dart` | List of all created links |
| `analytics_screen.dart` | Per-link charts — clicks, devices, UTM |
| `system_status_screen.dart` | API & infrastructure health |

#### Running

```bash
cd URLShortenerFlutterApp
flutter pub get
flutter run
```

> [!NOTE]
> Update `lib/config/app_config.dart` to point to your backend URL before running.

---

### 3. `go_india_tracker` — Flutter DDL SDK

A standalone Flutter package that integrates Deferred Deep Linking and attribution analytics into any Flutter app.

| Property | Value |
|----------|-------|
| Version | `0.0.1` |
| Dart SDK | `^3.5.4` |

#### Features

- **Deferred Deep Linking** — resolves the original deep-link even after a fresh app install via device fingerprinting
- **Install referrer** — reads Google Play Install Referrer on Android
- **App Links listener** — streams incoming deep links at runtime
- **Device fingerprinting** — submits a device fingerprint on first launch; matched server-side to a pending DDL

#### Quick Start

```dart
import 'package:go_india_tracker/go_india_tracker.dart';

await GoIndiaTracker.initialize(
  sdkKey: 'YOUR_SDK_KEY',
  baseUrl: 'https://your-api-host/api',
);

// Listen for resolved deep links
GoIndiaTracker.onDeepLink.listen((DeepLinkData data) {
  if (data.matchFound) {
    // navigate to data.targetDestination
  }
});
```

#### Use as a local dependency

```yaml
# pubspec.yaml
dependencies:
  go_india_tracker:
    path: ../go_india_tracker
```

---

### 4. `go_india_tracker_admin` — Flutter Web Admin Dashboard

A Flutter web application for platform administrators to manage apps, SDK keys, links, and view an analytics overview.

| Property | Value |
|----------|-------|
| Flutter SDK | `^3.8.1` |
| State management | `flutter_riverpod ^2.5.1` |
| Navigation | `go_router ^14.2.1` |
| HTTP | `dio ^5.5.0` |

#### Screens / Views

| Screen | Description |
|--------|-------------|
| `auth_screen.dart` | Admin login |
| `dashboard_screen.dart` | Main shell with tabs |
| `overview_view.dart` | Platform-wide stats |
| `links_view.dart` | All short links management |
| `apps_view.dart` | Registered apps & SDK keys |
| `link_details_screen.dart` | Deep-link analytics detail |

#### Running

```bash
cd go_india_tracker_admin
flutter pub get
flutter run -d chrome
```

---

## 🔐 Security Notes

- All write endpoints require a valid **JWT** (obtained via `/auth/login`).
- SDK endpoints are protected by a per-app **SDK Key** passed in the `X-SDK-Key` header.
- Android App Links verified via `/.well-known/assetlinks.json`.
- CORS is locked to an explicit allowlist — extend `APP_CORS_ALLOWED_ORIGINS` as needed.

---

## 🧰 Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| Backend | Spring Boot 3.3 · Java 21 · Maven |
| Database | PostgreSQL 16 · Flyway |
| Cache | Redis 7 |
| Auth | JWT (JJWT 0.12) · HS256 |
| Mobile / Web | Flutter 3.8 · Dart 3.5+ |
| State | Riverpod |
| Navigation | go_router |
| HTTP | Dio |
| Infrastructure | Docker Compose (dev) |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is proprietary software. All rights reserved © GoIndia Infotech.
