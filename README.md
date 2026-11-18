# 🔗 URLShortener Platform

> **A production-grade, mobile-first URL Shortening & Deferred Deep Linking (DDL) platform.**
>
> Built with Spring Boot 3 (Java 21) on the backend and Flutter 3.8 on the frontend, it supports short link creation, click analytics, QR code generation, multi-app SDK key management, Android App Links, and full deferred deep link resolution — all in a mono-repo.

---

## 📦 Repository Structure

```
URLShortener/
├── URLShortenerBackend/        # ① Spring Boot 3.3 REST API (Java 21)
├── URLShortenerFlutterApp/     # ② Flutter mobile client (Android / iOS / macOS)
├── go_india_tracker/           # ③ Flutter DDL SDK (Dart package)
└── go_india_tracker_admin/     # ④ Flutter web admin dashboard
```

---

## 🏗️ System Architecture

```
┌───────────────────────────────┐   JWT Bearer Token    ┌──────────────────────────────┐
│   URLShortenerFlutterApp      │──────────────────────►│                              │
│   (Mobile: Android/iOS/macOS) │                       │   URLShortenerBackend        │
└───────────────────────────────┘                       │   Spring Boot 3.3            │
                                                        │   Port :8082  /api           │
┌───────────────────────────────┐   JWT Bearer Token    │                              │
│   go_india_tracker_admin      │──────────────────────►│   ┌────────────┐             │
│   (Flutter Web Dashboard)     │                       │   │ PostgreSQL │  (Flyway)   │
└───────────────────────────────┘                       │   └────────────┘             │
                                                        │   ┌────────────┐             │
┌───────────────────────────────┐   X-SDK-Key Header    │   │   Redis    │  (Cache)    │
│   go_india_tracker            │──────────────────────►│   └────────────┘             │
│   (Flutter DDL SDK)           │   DDL fingerprint /   │                              │
└───────────────────────────────┘   resolve             └──────────────────────────────┘
                                                                     │
                                                        Any HTTP client (browser, curl…)
                                                        GET /api/r/{shortCode}  ──► 302 Redirect
```

---

## ① URLShortenerBackend — Spring Boot REST API

### What it does

The backend is the core of the platform. It provides:

- **User authentication** — sign up, log in, and stateless JWT-based sessions
- **URL shortening** — convert any long URL into a short code with an optional custom slug, link expiry, and click counter
- **Redirection** — `GET /r/{shortCode}` looks up the short code (Redis-first, then PostgreSQL) and issues a `302` redirect, recording a click event
- **Click analytics** — per-link total clicks, 7-day traffic trends (clicks per day), device distribution (Desktop / iOS / Android), UTM parameter breakdown
- **Deferred Deep Linking (DDL)** — register a device fingerprint before app-install, then resolve it on first launch to route users to specific in-app content
- **Multi-app SDK key management** — register mobile apps (Android & iOS), issue per-app SDK keys used to authenticate the DDL SDK
- **Android App Links** — serves `/.well-known/assetlinks.json` for verified deep link routing (no browser interstitial)

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Spring Boot 3.3 |
| Language | Java 21 |
| Database | PostgreSQL 16 |
| Migrations | Flyway (V1 → V7) |
| Cache / Buffer | Redis 7 |
| Auth | JJWT 0.12 · HS256 |
| Build | Maven (Maven Wrapper included) |
| Dev infra | Docker Compose |

### Database Schema

Flyway manages schema evolution automatically on startup.

| Migration | Tables Created / Changed | Purpose |
|-----------|--------------------------|---------|
| `V1` | `users` | Email + password accounts (UUID PK) |
| `V2` | `url_mappings` | Short links — short code, long URL, user, status (`ACTIVE/BROKEN/EXPIRED`), expiry, `deep_link_cfg` (JSONB), click counter |
| `V3` | `clicks` | Per-click events — device type, country, referer, timestamp |
| `V4` | `ddl_logs` | DDL resolver audit log (device fingerprints, sessions) |
| `V5–V6` | `apps`, `sdk_keys` | Multi-app registry and per-app SDK keys |
| `V7` | — | Schema refinement — adds `ios_bundle_id`, `app_store_url`; unifies Android/iOS into one `apps` table |

### API Endpoints

All paths are prefixed with the `/api` context path.

#### Auth

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/auth/signup` | Public | Register — `{name, email, password}` → `{token, user}` |
| `POST` | `/auth/login` | Public | Login — `{email, password}` → `{token, user}` |

#### Links

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/shorten` | JWT | Create short link — `{longUrl, customSlug?, expiryDate?, deepLinkCfg?}` |
| `GET` | `/r/{shortCode}` | Public | Redirect to long URL (302). Records click event |
| `GET` | `/links` | JWT | List all links for the authenticated user |
| `DELETE` | `/links/{id}` | JWT | Delete a short link |

#### Analytics

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/analytics/{shortCode}` | JWT | Per-link analytics: total clicks, 7d trend, device split, UTM breakdown, DDL config |
| `GET` | `/analytics/summary` | JWT | User-level summary: total links, total clicks |

#### Admin — Apps & SDK Keys

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/admin/apps` | JWT | Register a mobile app (Android pkg + SHA256, iOS bundle + team ID) |
| `GET` | `/admin/apps` | JWT | List all registered apps and their SDK keys |
| `POST` | `/admin/apps/{appId}/shorten` | JWT | Create a short link scoped to a specific app |

#### Deferred Deep Linking (DDL) — SDK Endpoints

> These endpoints require the `X-SDK-Key` header with a valid per-app SDK key.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/ddl/register` | SDK Key | Register a device fingerprint before install |
| `POST` | `/ddl/resolve` | SDK Key | On first app launch — match device fingerprint to a pending DDL and return destination |

#### System

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/status` | Public | API health, Redis status, DB connectivity |
| `GET` | `/.well-known/assetlinks.json` | Public | Android App Links verification file |

### How to Run

#### Prerequisites

- Java 21+
- Maven (or use the included `./mvnw`)
- Docker & Docker Compose

#### Steps

```bash
# 1. Clone and enter backend directory
cd URLShortenerBackend

# 2. Start PostgreSQL and Redis (dev credentials — local only)
docker compose up -d

# 3. Run the app (Flyway builds the schema automatically on first boot)
./mvnw spring-boot:run

# API is live at http://localhost:8082/api
```

#### Android Emulator Override

```bash
# Point the API to 10.0.2.2 so an Android emulator can reach localhost
./mvnw spring-boot:run \
  -Dspring-boot.run.jvmArguments="-DAPP_BASE_URL=http://10.0.2.2:8082/api"
```

### Environment Variables

Override at runtime — no source changes needed.

| Variable | Default (dev only) | Purpose |
|----------|--------------------|---------|
| `SERVER_PORT` | `8082` | HTTP port |
| `APP_BASE_URL` | `http://localhost:8082/api` | Base used when building returned short URLs |
| `DB_URL` | `jdbc:postgresql://localhost:5432/urlshortener` | Postgres JDBC URL |
| `DB_USERNAME` | `adda247` | Postgres user |
| `DB_PASSWORD` | `secret` | Postgres password |
| `REDIS_HOST` | `localhost` | Redis hostname |
| `REDIS_PORT` | `6379` | Redis port |
| `JWT_SECRET` | `dev-only-insecure-…` | HS256 signing key — **must be ≥ 32 bytes in production** |
| `JWT_EXPIRY_MS` | `86400000` (24 h) | JWT token lifetime |
| `APP_CORS_ALLOWED_ORIGINS` | `localhost:8080,localhost:3000` | Comma-separated CORS origins |
| `LOG_LEVEL` | `INFO` | Log level for `com.goindiainfotech` |

> [!CAUTION]
> Never deploy with the default `JWT_SECRET` or database credentials. Set strong values via environment variables or a secrets manager.

---

## ② URLShortenerFlutterApp — Mobile Client

### What it does

A dark-themed Flutter mobile application that lets authenticated users:

- **Sign up / Log in** with email and password
- **Shorten URLs** — paste any long URL, optionally set a custom slug, link expiry date, and enable Deferred Deep Linking with an in-app route destination
- **View history** — paginated list of all created short links with click counters, relative timestamps, copy-to-clipboard and native share
- **Analytics dashboard** — per-link stats: total clicks, 7-day bar chart traffic trend, device distribution (Desktop / iOS / Android) progress bars, and DDL protocol config card
- **QR code generation** — generate and share a QR code for any short link
- **System status** — live API health, Redis and database connectivity indicators
- **Deep link handling** — the app listens for both direct and deferred deep links via the `go_india_tracker` SDK and shows an in-app dialog with the resolved destination

### Tech Stack

| Concern | Package | Version |
|---------|---------|---------|
| State management | `flutter_riverpod` | ^3.3.2 |
| Navigation | `go_router` | ^17.0.0 |
| HTTP client | `dio` | ^5.10.0 |
| Local cache | `hive` + `hive_flutter` | ^2.2.3 / ^1.1.0 |
| Persistent prefs (token) | `shared_preferences` | ^2.5.3 |
| Charts | `fl_chart` | ^0.69.0 |
| QR code | `qr_flutter` | ^4.1.0 |
| Native share | `share_plus` | ^12.0.2 |
| Deep linking | `app_links` | ^6.3.0 |
| Device info | `device_info_plus` | ^12.4.0 |
| Connectivity | `connectivity_plus` | ^6.0.3 |
| Crypto | `crypto` | ^3.0.7 |
| DDL SDK | `go_india_tracker` | local path |

### Screens

| Screen | File | Description |
|--------|------|-------------|
| **Auth** | `auth_screen.dart` | Sign-up and Login form with toggle |
| **Home** | `home_screen.dart` | Bottom-nav shell: Shorten / History / Analytics / Status |
| **Shorten** | `shorten_screen.dart` | URL input, custom slug, expiry picker, DDL toggle + route input, result card with copy/share/stats |
| **History** | `history_screen.dart` | List of all created links — click count stats, relative time, delete, copy, share |
| **Analytics** | `analytics_screen.dart` | Dropdown to select a link; total clicks, 7-day bar chart, device split, DDL protocol card |
| **System Status** | `system_status_screen.dart` | API ping, Redis status, DB status indicators |

### Configuration

No secrets are hardcoded. All environment values are injected via `--dart-define` at build/run time.

| `--dart-define` key | Default | Purpose |
|---------------------|---------|---------|
| `API_BASE_URL` | `http://localhost:8082/api` | Backend REST base URL |
| `SDK_KEY` | `sdk_test_12345` | DDL SDK key |

### How to Run

#### Prerequisites

- Flutter SDK ≥ 3.8.1 (`flutter --version`)
- Android emulator / physical device **or** iOS simulator / device

```bash
cd URLShortenerFlutterApp

# Install dependencies
flutter pub get

# Run with defaults (backend on localhost)
flutter run

# Android emulator — backend on host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8082/api

# Point to production backend
flutter run \
  --dart-define=API_BASE_URL=https://api.yourserver.com/api \
  --dart-define=SDK_KEY=your_sdk_key_here

# Build release APK
flutter build apk \
  --dart-define=API_BASE_URL=https://api.yourserver.com/api \
  --dart-define=SDK_KEY=your_sdk_key_here
```

> [!NOTE]
> The app automatically picks up the `go_india_tracker` SDK from the sibling `../go_india_tracker` directory via a local path dependency.

---

## ③ go_india_tracker — Flutter DDL SDK

### What it does

A standalone, embeddable Flutter Dart package that adds **Deferred Deep Linking** and **attribution analytics** to any Flutter app. Integrate it in 3 lines of code.

**How Deferred Deep Linking works:**

1. User clicks a marketing short link (e.g. `https://short.example.com/r/promo42`) on a device that doesn't have the app installed.
2. The browser redirects them to the Play Store / App Store. The backend records a device fingerprint.
3. User installs and opens the app. The SDK calls `/ddl/resolve` with the same fingerprint.
4. The backend matches the fingerprint to the pending DDL and returns the original destination (e.g. `app://product/442`).
5. The app navigates the user directly to that content — seamless first experience.

### Key Features

| Feature | Detail |
|---------|--------|
| Deferred deep link resolution | Device fingerprint → server match → in-app navigation |
| Google Play Install Referrer | Reads `click_token` / UTM params from Android install referrer string |
| Direct App Links listener | Streams live `app_links` URI events for direct deep link handling |
| Device fingerprinting | `Fingerprinter` utility builds a stable device fingerprint from `device_info_plus` |
| UTM parameter passthrough | `utmSource`, `utmMedium`, `utmCampaign`, `utmTerm`, `utmContent` in `DeepLinkData` |
| Zero hardcoded hosts | Domain resolved from `customDomain` arg or `--dart-define=TRACKER_DOMAIN` |

### SDK Files

```
go_india_tracker/lib/
├── go_india_tracker.dart       # Public API: GoIndiaTracker.init(), onDeepLinkReceived stream
└── src/
    ├── api_client.dart         # HTTP client for /ddl/register and /ddl/resolve
    └── fingerprinter.dart      # Device fingerprint builder
```

### How to Integrate

**1. Add to `pubspec.yaml`:**

```yaml
dependencies:
  go_india_tracker:
    path: ../go_india_tracker   # local sibling; or publish to pub.dev for a hosted reference
```

**2. Initialize once in `main.dart`:**

```dart
import 'package:go_india_tracker/go_india_tracker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoIndiaTracker.init(
    sdkKey: 'YOUR_SDK_KEY',               // issued from the admin dashboard
    customDomain: 'https://api.example.com', // your backend host (no /api suffix)
  );

  runApp(MyApp());
}
```

**3. Listen for resolved deep links:**

```dart
GoIndiaTracker.onDeepLinkReceived.listen((DeepLinkData data) {
  if (data.matchFound && data.targetDestination != null) {
    // Navigate the user to data.targetDestination
    // e.g. GoRouter.of(context).go(data.targetDestination!)
    print('UTM source: ${data.utmSource}');
  }
});
```

**4. Standalone run (for development/testing):**

```bash
cd go_india_tracker
flutter pub get
flutter test
```

---

## ④ go_india_tracker_admin — Flutter Web Admin Dashboard

### What it does

A Flutter web application for platform administrators. It connects to the same backend REST API and provides:

- **Login** — JWT auth, session stored in `shared_preferences`
- **Dashboard Overview** — platform-wide stats: total apps, total links, total clicks
- **Apps management** — create new registered apps (Android package name, SHA256 fingerprint, iOS bundle ID, App Store URL), view SDK keys, copy key to clipboard
- **Links management** — view all shortened URLs across all apps, link status, click counts
- **Link detail** — per-link analytics, DDL configuration status

### Tech Stack

| Concern | Package | Version |
|---------|---------|---------|
| State management | `flutter_riverpod` | ^2.5.1 |
| Navigation | `go_router` | ^14.2.1 |
| HTTP client | `dio` | ^5.5.0 |
| Session storage | `shared_preferences` | ^2.2.3 |

### Admin Dashboard Routes

| Route | Screen | Description |
|-------|--------|-------------|
| `/` | Auth redirect | Auto-redirect based on login state |
| `/auth` | `AuthScreen` | Login form |
| `/dashboard` | `DashboardScreen → OverviewView` | Platform stats |
| `/apps` | `DashboardScreen → AppsView` | App registry & SDK keys |
| `/links` | `DashboardScreen → LinksView` | All short links |
| `/links/:code` | `LinkDetailsScreen` | Per-link analytics & DDL config |

### How to Run

```bash
cd go_india_tracker_admin

# Install dependencies
flutter pub get

# Run in Chrome (web)
flutter run -d chrome

# Point to a specific backend
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://api.yourserver.com/api

# Build for web deployment
flutter build web
# Output: go_india_tracker_admin/build/web/
```

---

## 🚀 Running the Full Platform Locally

Follow these steps in order to bring up the entire stack:

### Step 1 — Start the Backend

```bash
cd URLShortenerBackend
docker compose up -d          # Starts PostgreSQL on :5432 and Redis on :6379
./mvnw spring-boot:run        # API live at http://localhost:8082/api
```

### Step 2 — Run the Mobile App (Android emulator)

```bash
cd URLShortenerFlutterApp
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8082/api \
            --dart-define=SDK_KEY=sdk_test_12345
```

### Step 3 — Run the Admin Dashboard

```bash
cd go_india_tracker_admin
flutter pub get
flutter run -d chrome
```

> [!TIP]
> Open **two terminal tabs** — one for the backend (`./mvnw spring-boot:run`) and one for the Flutter app (`flutter run`). The admin web dashboard can run in a third tab.

---

## 🔐 Security

| Concern | Implementation |
|---------|---------------|
| User authentication | Stateless JWT (HS256, JJWT 0.12) with 24-hour expiry |
| SDK authentication | Per-app SDK key in `X-SDK-Key` header; validated by `SdkAuthFilter` |
| Android App Links | `/.well-known/assetlinks.json` served statically from the backend |
| CORS | Explicit allowlist via `APP_CORS_ALLOWED_ORIGINS` env var |
| Secrets | All credentials via environment variables — no secrets in source |

> [!CAUTION]
> Change `JWT_SECRET`, `DB_PASSWORD`, and all SDK keys before any public deployment. The committed defaults are **dev-only placeholders**.

---

## 🗂️ Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| Backend language | Java 21 |
| Backend framework | Spring Boot 3.3 |
| Build tool | Maven (wrapper included) |
| Primary database | PostgreSQL 16 |
| Schema migrations | Flyway (7 migrations) |
| Cache / async buffer | Redis 7 |
| Auth | JJWT 0.12 · HS256 JWT |
| Mobile / web UI | Flutter 3.8 · Dart 3.5+ |
| State management | Riverpod (flutter_riverpod) |
| Navigation | go_router |
| HTTP (Flutter) | Dio |
| Local storage | Hive + shared_preferences |
| Analytics charts | fl_chart |
| Dev infrastructure | Docker Compose |

---

## 🤝 Contributing

```bash
# 1. Fork the repository and clone
git clone https://github.com/YOUR_USERNAME/URLShortener.git
cd URLShortener

# 2. Create a feature branch
git checkout -b feature/your-feature-name

# 3. Make your changes, then commit
git add .
git commit -m "feat: describe your change"

# 4. Push and open a Pull Request
git push origin feature/your-feature-name
```

**Branch naming conventions:**
- `feature/` — new features
- `fix/` — bug fixes
- `chore/` — maintenance, deps, refactoring

---

## 📄 License

Proprietary software. All rights reserved © GoIndia Infotech.
