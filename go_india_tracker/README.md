# go_india_tracker

A lightweight Flutter/Dart **SDK for deferred deep linking and install attribution** — a
minimal, self-hosted take on what Branch or AppsFlyer provide. Embed it in a mobile app to
route users to the right in-app destination even when they tapped a link *before*
installing the app.

## What it does

On first launch it resolves attribution using three strategies, in order:

1. **Deterministic** — reads the Android Play Install Referrer and extracts the
   `click_token` planted by the shortener.
2. **Probabilistic** — computes a device fingerprint (SHA-256 of timezone offset, language
   and platform) and asks the backend to match it against a recent click.
3. **Direct app links** — at runtime, listens for `app_links` and parses `/r/{code}` (or
   `/api/r/{code}`) URLs.

Matches are delivered to the host app through a broadcast stream of `DeepLinkData`.

## Usage

```dart
import 'package:go_india_tracker/go_india_tracker.dart';

await GoIndiaTracker.init(
  sdkKey: 'your-sdk-key',                 // issued by the admin console
  customDomain: 'https://api.example.com' // optional; overrides the default host
);

GoIndiaTracker.onDeepLinkReceived.listen((data) {
  if (data.matchFound) {
    // route to data.targetDestination / data.shortCode
  }
});
```

## Configuration

The backend host is resolved as: `customDomain` argument → `--dart-define=TRACKER_DOMAIN`
→ `http://localhost:8082` (default). No environment host is hardcoded in the source.

The SDK key is **always supplied by the host app** and sent as the `X-SDK-Key` header — it
is never embedded in this package.

## API surface

| Member | Description |
|--------|-------------|
| `GoIndiaTracker.init({sdkKey, customDomain})` | Initialize; runs deferred-link check on first launch and starts the direct-link listener |
| `GoIndiaTracker.onDeepLinkReceived` | `Stream<DeepLinkData>` of resolved matches |
| `DeepLinkData` | `{matchFound, shortCode, longUrl, targetDestination, params}` |

## Dependencies

`http`, `device_info_plus`, `shared_preferences`, `app_links`, `uuid`,
`android_play_install_referrer`. No Firebase or third-party attribution SDK.

## Privacy note

Fingerprinting is probabilistic device matching and should be disclosed in the host app's
privacy policy and gated behind consent where required by local regulation.