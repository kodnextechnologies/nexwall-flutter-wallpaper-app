# Flutter Wallpaper App using a Free Wallpaper API (NexWall)

A minimal, open-source Flutter wallpaper app built on the [NexWall **free wallpaper API**](https://nexwall.kodnextech.com/wallpaper-api/free-wallpaper-api). It browses wallpaper categories, shows a paginated wallpaper grid with infinite scroll, opens a full-screen preview, and sets the wallpaper on Android. Use it as a starting point for your own wallpaper app, or as a reference for calling a REST API from Flutter.

> Step-by-step tutorial: [Build a Flutter wallpaper app with the NexWall API](https://nexwall.kodnextech.com/wallpaper-api/guides/flutter-wallpaper-app-tutorial)

## Features

- Category list with cover images and wallpaper counts (`GET /categories`)
- Wallpaper grid with **infinite scroll pagination** (`page` / `per_page`)
- Sort by newest, popular, random or oldest
- Full-screen preview with pinch-to-zoom (thumbnail shown while the full image loads)
- **Set as wallpaper** on Android: home screen, lock screen or both
- Image caching with [`cached_network_image`](https://pub.dev/packages/cached_network_image)
- Shows your **remaining daily API quota** in the app bar
- Handles `401`, `404`, `422` and `429` (quota exceeded, with `Retry-After`) without retry loops
- API key passed with `--dart-define`, so it is never in source code
- Small codebase: one HTTP client, two models, three screens, two unit tests

## What it does

1. **Categories screen**: a grid of the categories your plan can access. The grid icon in the app bar opens "All wallpapers".
2. **Wallpapers screen**: a 9:16 thumbnail grid that loads the next page as you scroll. The sort menu reloads the list.
3. **Preview screen**: the full-resolution image. On Android a "Set as wallpaper" button asks for home, lock or both.

Setting the wallpaper uses the [`async_wallpaper`](https://pub.dev/packages/async_wallpaper) plugin (v3.x). It is actively maintained, works with current Flutter stable, and supports static wallpapers from a URL on Android. On iOS, apps cannot set the wallpaper, so the button is hidden there; the rest of the app works on iOS.

## Quick start

### 1. Get a free API key

Sign up at **https://nexwall.kodnextech.com/developers/register**. The free plan needs no credit card.

### 2. Configure

You need Flutter stable (tested with Flutter 3.47 / Dart 3.13). Pass the key at build time:

```bash
git clone https://github.com/kodnextechnologies/nexwall-flutter-wallpaper-app.git
cd nexwall-flutter-wallpaper-app
flutter pub get
```

Or keep the key in a file that git ignores:

```bash
cp env.example.json env.json      # then edit env.json
```

### 3. Run

```bash
flutter run --dart-define=NEXWALL_API_KEY=your_key_here
# or
flutter run --dart-define-from-file=env.json
```

Release build:

```bash
flutter build apk --dart-define-from-file=env.json
```

Run the tests (they use a mock HTTP client and make no network calls):

```bash
flutter test
```

## Project structure

```
lib/
├── main.dart                      # MaterialApp + theme
└── src/
    ├── config.dart                # NEXWALL_API_KEY / base URL from --dart-define
    ├── models.dart                # WallpaperCategory, Wallpaper, WallpaperPage
    ├── nexwall_api.dart           # HTTP client, error handling, quota tracking
    ├── screens/
    │   ├── categories_screen.dart
    │   ├── wallpapers_screen.dart # paginated grid + infinite scroll
    │   └── preview_screen.dart    # full screen + set as wallpaper
    └── widgets/common.dart        # quota chip, error view
test/api_test.dart                 # parsing + 429 handling
env.example.json                   # template for --dart-define-from-file
```

## API endpoints used

Base URL: `https://nexwall.kodnextech.com/api/developer/v1`

Every request sends `Authorization: Bearer <API_KEY>` and `Accept: application/json`.

| Endpoint | Used for |
| --- | --- |
| `GET /categories` | Category grid |
| `GET /wallpapers?page=&per_page=&category_id=&sort=&type=image` | Paginated wallpaper grid |
| `GET /wallpapers/{id}` | Single wallpaper (available in `NexWallApi.getWallpaper`) |

`/wallpapers` also accepts `search` (2-100 characters, matches tags). The API has `GET /categories/{categoryId}/wallpapers` as well; this app uses `category_id` on `/wallpapers` instead.

Full reference: [API docs](https://nexwall.kodnextech.com/wallpaper-api/docs) · [OpenAPI spec](https://nexwall.kodnextech.com/openapi.json) · [Try requests in the sandbox](https://nexwall.kodnextech.com/wallpaper-api/sandbox)

## Rate limits & plans

| Plan | Price | Requests per day | Content |
| --- | --- | --- | --- |
| Free | Free, no credit card | 100 | Non-premium categories |
| Pro | ₹399 / $4.99 per month | 10,000 | |
| Ultra | ₹899 / $10.99 per month | 50,000 | Includes live (video) wallpapers |

- The free plan also allows up to 60 requests per minute.
- Responses include `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` and `X-Developer-Api-Plan` headers. The JSON body includes `plan` and `remaining_requests_today`.
- When the quota is used up the API returns **HTTP 429** with a `Retry-After` header. This app stops paging, shows the wait time, and only retries when the user taps Retry.
- Get more requests or premium categories on the [plans page](https://nexwall.kodnextech.com/wallpaper-api/free-wallpaper-api).

## Production note

A `--dart-define` value is compiled into the app, and anyone can extract it from the APK. That is fine for development and personal projects. For a published app, put a small **backend proxy** in front of NexWall: the app calls your server, your server adds the API key and forwards the request. This keeps the key secret and lets you cache responses, which saves quota. Point the app at your proxy with `--dart-define=NEXWALL_BASE_URL=https://your-server.example.com/nexwall` and leave out `NEXWALL_API_KEY`; when a custom base URL is set, the client does not require a key and sends no `Authorization` header (see `lib/src/config.dart`).

## Related starters

- [Android Kotlin wallpaper app (Jetpack Compose)](https://github.com/kodnextechnologies/nexwall-android-kotlin-wallpaper-app)
- [React Native / Expo wallpaper app](https://github.com/kodnextechnologies/nexwall-react-native-expo-wallpaper-app)
- [Python client and CLI with a daily wallpaper changer](https://github.com/kodnextechnologies/nexwall-python)

## License

The source code is released under the [MIT License](LICENSE).

Wallpaper images and videos returned by the API are **not** covered by the MIT license. Their use is governed by the [NexWall Developer API License](https://nexwall.kodnextech.com/wallpaper-api/license).
