# URLShortenerBackend

Spring Boot 3.3 (Java 21) REST API for the deep-link URL shortener platform. Provides
authentication, URL shortening + redirection, click analytics, app/SDK-key management,
and deferred-deep-link (DDL) resolution.

## Stack

- **Spring Boot 3.3** — Web, Security, Validation, Data JPA, Data Redis
- **PostgreSQL** — primary store; schema managed by **Flyway** (`db/migration/V1..V7`)
- **Redis** — redirect cache, async click buffer, click counters, DDL fingerprints
- **JJWT 0.12** — stateless JWT auth (HS256)
- Runs on `:8082` under context path `/api`

## Running locally

```bash
docker compose up -d      # Postgres + Redis (dev credentials, see docker-compose.yml)
./mvnw spring-boot:run    # boots on http://localhost:8082/api
```

Flyway builds the schema on first boot (`ddl-auto=validate`), so the database only needs
to exist — the bundled `docker-compose.yml` creates it (`urlshortener`) automatically.

## Configuration

All settings resolve from environment variables with local-dev defaults. Copy
`.env.example` to `.env` (git-ignored) and adjust, or export the variables directly.

| Variable | Default | Purpose |
|----------|---------|---------|
| `SERVER_PORT` | `8082` | HTTP port |
| `APP_BASE_URL` | `http://localhost:8082/api` | Base used to build returned short URLs |
| `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` | local docker values | Postgres connection |
| `REDIS_HOST` / `REDIS_PORT` | `localhost` / `6379` | Redis connection |
| `JWT_SECRET` | dev placeholder | HS256 signing key — **must** be overridden in prod (≥ 32 bytes) |
| `JWT_EXPIRY_MS` | `86400000` | Token lifetime |
| `APP_CORS_ALLOWED_ORIGINS` | `localhost:8080,localhost:3000` | Comma-separated browser origins |

> Production must set a strong `JWT_SECRET`, real DB credentials, and an explicit CORS
> allow-list. The committed defaults are for local development only.

## Key endpoints

All paths are prefixed with the `/api` context path.

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/auth/signup`, `/auth/login` | public | Register / obtain JWT |
| POST | `/shorten` | JWT | Create a short link |
| GET | `/r/{code}` | public | Redirect (cache-first) + record click |
| GET | `/links`, DELETE `/links/{id}` | JWT | List / delete own links |
| GET | `/analytics/{code}`, `/analytics/summary` | JWT | Click analytics |
| POST/GET/PUT/DELETE | `/admin/apps`, `/admin/links` | JWT | App + link management |
| POST | `/admin/apps/{appId}/keys/regenerate` | JWT | Rotate SDK key |
| POST | `/ddl/register` | public | Register a fingerprint→code mapping |
| POST/GET | `/ddl/resolve`, `/ddl/resolve-direct/{code}`, `/ddl/resolve-referrer` | X-SDK-Key | SDK deep-link resolution |
| GET | `/.well-known/assetlinks.json`, `/apple-app-site-association` | public | App-link association files |

## How deferred deep linking works

1. A short link carries a deep-link config (`UrlMapping.deep_link_cfg`, stored as JSONB).
2. The SDK, on first launch, sends a device fingerprint (or install-referrer token) to
   `/ddl/resolve*`.
3. The backend matches it against a short-lived Redis entry and returns the destination,
   so the app can route the user to the right screen even though the link was tapped
   before install.

## Notable implementation details

- **Click pipeline**: clicks are pushed to a Redis list asynchronously and flushed to
  Postgres on a schedule, with per-link counters synced separately — keeps redirects fast.
- **Redirect cache**: `GET /r/{code}` serves from a 1-hour Redis cache, falling back to
  Postgres and back-filling the cache.

## Known limitations / demo scope

- Some `/system/status` figures (version string, cache hit-rate fallback, memory) are
  illustrative rather than live metrics.
- This is a demo/portfolio backend: rate limiting, per-tenant scoping of well-known files,
  and fine-grained roles are intentionally minimal.