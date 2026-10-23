# PROJECT_CONTEXT.md — Ramala

> **Purpose**: Provides a complete, verified reference for AI coding assistants working on this codebase. Read this before making any changes to the project.
> **Last updated**: 2026-10-23
> **Coverage**: All files under `lib/`, `pubspec.yaml`, and all six `docs/` files inspected.

---

## 1. Project Overview

**Ramala** is an Android prediction market application styled after Kalshi/Polymarket, built with Flutter/Dart as a university final project (_Tugas Akhir_) for the course _Pemrograman Aplikasi Mobile_. All trading uses **dummy coins** — no real money. The app is intended for academic demonstration and written entirely in **Bahasa Indonesia** (UI text).

- **App name**: Ramala
- **Package ID**: `com.example.ramala` (applicationId in `build.gradle.kts`)
- **Version**: `1.0.0+1`
- **Primary platform**: Android (iOS not targeted; `flutter_launcher_icons` sets `ios: false`)
- **All backend services are free-tier**: Supabase, Cloudinary, Gemini Flash, CoinGecko, ExchangeRate-API, OpenStreetMap.

---

## 2. Requirements and Intended Behavior

Source: `docs/ketentuan_tugas_akhir.txt`

| Requirement | Status (verified from code) |
|---|---|
| Login with encryption (no Firebase) | ✅ Supabase Auth + `flutter_secure_storage` |
| Biometric login | ✅ `local_auth` with fallback PIN |
| Local + online database | ✅ sqflite (offline cache) + Supabase (online) |
| Web service / API (LBS, game, or multiplatform) | ✅ Supabase RPC, Cloudinary, Gemini, ExchangeRate-API, CoinGecko, OpenStreetMap |
| Navigation menu: profile (with image), feedback, logout | ✅ All present |
| Currency converter (min. 3) + time zone converter (WIB, WIT, WITA, London) | ✅ 5 fiat currencies + 3 crypto; 4 time zones |
| Min. 2 sensors (Accelerometer, Gyroscope, etc.) | ✅ Both used in game feature |
| AI/LLM feature | ✅ Gemini chatbot |
| Mini game | ✅ "Tangkap Uang" game with tilt controls |
| Search and selection facility | ✅ Market list search + category filter |
| Mobile notification feature | ✅ local notifications + Supabase Realtime + Workmanager |
| Simple blockchain feature | ✅ `ledger` table with SHA-256 chain, `verify_ledger()` RPC |

---

## 3. Technology Stack and Dependencies

### Core Framework
- **Flutter SDK**: `^3.13.5` (Dart)
- **State management**: `flutter_riverpod: ^3.4.3` — used **without codegen** (no `freezed`, no `build_runner`, no `riverpod_generator`)
- **Routing**: `go_router: ^18.1.0`

### Backend & Auth
- `supabase_flutter: ^2.18.3` — auth, database, realtime, RPC calls
- `flutter_secure_storage: ^11.2.0` — session token storage (Android Keystore)
- `local_auth: ^3.0.2` — biometric (fingerprint/face + PIN fallback)

### Storage
- `sqflite: ^2.4.4+2` — local SQLite cache (3 tables: `cache`, `chat_messages`, `search_history`)
- `path: ^1.9.1` — file path utilities for sqflite

### Networking
- `dio: ^5.11.1` — HTTP client for Gemini AI and Cloudinary (not used for Supabase)

### Media
- `image_picker: ^1.2.4` — gallery photo selection for avatar
- `flutter_image_compress: ^2.5.1` — JPEG compression before Cloudinary upload
- `cached_network_image: ^4.0.4` — network image caching

### Charts & Data
- `fl_chart: ^1.2.0` — `PriceChart` widget (line chart for YES price history)
- `crypto: ^3.0.7` — SHA-256 hash (available but actual chain verification done by Postgres `verify_ledger()` RPC)
- `intl: ^0.20.3` — date formatting, number formatting
- `timezone: ^0.11.2` — timezone conversions in converter
- `latlong2: ^0.10.1` — `LatLng` type for map coordinates

### Location & Map
- `geolocator: ^14.1.2` — GPS location
- `flutter_map: ^8.3.2` — OpenStreetMap tile map
- `permission_handler: ^13.0.2` — runtime permission management

### Notifications & Background
- `flutter_local_notifications: ^22.3.2` — on-device notifications
- `workmanager: ^0.10.10` — background polling (min 15 min interval on Android)

### Sensors
- `sensors_plus: ^7.1.1` — accelerometer and gyroscope streams

### UI
- `google_fonts: ^8.2.1` — Inter and Cinzel fonts

### Dev Dependencies
- `flutter_lints: ^6.0.0`
- `flutter_launcher_icons: ^0.14.4` — custom launcher icon from `assets/gambar/logo_ramala_icon.png`

---

## 4. Directory Structure and Important Files

```
ramala/
├── lib/
│   ├── main.dart                     # App entry point
│   ├── app.dart                      # RamalaApp (MaterialApp.router)
│   ├── template.dart                 # ENTIRE design system (1131 lines)
│   ├── core/
│   │   ├── config/env.dart           # String.fromEnvironment() constants
│   │   ├── error/app_error.dart      # Error → Indonesian message mapping
│   │   ├── router/app_router.dart    # GoRouter config + auth redirect
│   │   ├── storage/
│   │   │   ├── local_db.dart         # sqflite helper (cache, chat, search)
│   │   │   └── secure_session.dart   # SecureLocalStorage for Supabase session
│   │   ├── validators/validators.dart # Input validation + sanitization
│   │   └── widgets/input_sheet.dart  # askInput() bottom sheet helper
│   ├── shell/
│   │   ├── main_shell.dart           # StatefulNavigationShell + Realtime + bottom nav
│   │   ├── features_page.dart        # "Fitur" tab — menu launcher for extra features
│   │   └── placeholder_page.dart     # Unused placeholder (commented out in router)
│   └── features/
│       ├── auth/{data,presentation}
│       ├── chatbot/{data,presentation}
│       ├── converter/{data,presentation}
│       ├── feedback/presentation
│       ├── game/presentation
│       ├── ledger/presentation
│       ├── market/{data,domain,presentation}
│       ├── nearby/presentation
│       ├── notification/{data,domain,presentation}
│       ├── portfolio/{data,presentation}
│       ├── profile/{data,presentation}
│       ├── admin/presentation         # Admin-only panel
│       ├── contoh_struktur/           # Reference template folder (gitkeep only)
│       ├── trading/                   # Empty (gitkeep only) — trading logic in market feature
│       └── wallet/                    # Empty (gitkeep only)
├── docs/                             # 6 documentation files (all in Indonesian)
├── assets/gambar/                    # Image assets (logo_ramala.png, logo_ramala_icon.png)
├── android/
│   └── app/
│       ├── build.gradle.kts          # compileSdk=37, coreLibraryDesugaring enabled
│       └── src/main/
│           ├── AndroidManifest.xml   # Permissions declared
│           └── kotlin/.../MainActivity.kt  # extends FlutterFragmentActivity (required for biometric)
├── pubspec.yaml
└── env.json                          # ⚠️ CONTAINS REAL API KEYS — do not commit
```

> **Note**: `features/trading/` and `features/wallet/` contain only `.gitkeep` files. Trading logic lives in `features/market/`.

---

## 5. Architecture and Application Startup

### Startup Sequence (`lib/main.dart`)
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Supabase.initialize(url, anonKey, authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()))` — stores session in Android Keystore
3. `NotificationService.init()` — registers `flutter_local_notifications` plugin
4. `Workmanager().initialize(callbackDispatcher)` — registers background isolate entry point
5. `tz.initializeTimeZones()` — loads timezone database
6. `runApp(ProviderScope(child: RamalaApp()))`

### Architecture Pattern
- **Feature-first** structure: `lib/features/<feature>/{data,domain,presentation}/`
- **Riverpod without codegen**: `FutureProvider.autoDispose`, `FutureProvider.autoDispose.family`, `Provider` — all created manually
- No use of `freezed`, `json_serializable`, or `build_runner`
- Models are plain Dart classes with `factory fromMap()` constructors
- Repositories are plain classes instantiated directly in providers

---

## 6. Navigation and Screen Inventory

### Route Configuration (`lib/core/router/app_router.dart`)

**Auth guard**: `_AuthRefresh` listens to `Supabase.instance.client.auth.onAuthStateChange`. The `redirect` function:
- Unauthenticated → redirects any route to `/login`
- Authenticated on login/register → redirects to `/pasar`

**Shell routes (5 tabs — bottom nav)**:
| Tab | Route | Widget | Description |
|---|---|---|---|
| 0 | `/pasar` | `MarketListPage` | Market list with search and filter |
| 1 | `/portofolio` | `PortfolioPage` | Positions, trade history, balance |
| 2 | `/fitur` | `FeaturesPage` | Launcher menu for extra features |
| 3 | `/saran` | `FeedbackPage` | Course feedback form |
| 4 | `/profil` | `ProfilePage` | User profile, avatar, biometric toggle, logout |

**Detail routes (outside shell, full-screen)**:
| Route | Widget | Notes |
|---|---|---|
| `/login` | `LoginPage` | Auth-gated |
| `/register` | `RegisterPage` | Auth-gated |
| `/market/:id` | `MarketDetailPage` | Takes `id` path parameter |
| `/konverter` | `ConverterPage` | Currency + crypto + time zone |
| `/nearby` | `NearbyPage` | LBS map + sorted list |
| `/game` | `GamePage` | Sensor game |
| `/chatbot` | `ChatPage` | Gemini AI chat |
| `/notifikasi` | `NotificationPage` | Notification list |
| `/ledger` | `LedgerPage` | Blockchain ledger |
| `/admin` | `AdminPage` | Admin-only (no route guard — server RPCs enforce access) |

---

## 7. Feature-by-Feature Implementation

### 7.1 Authentication (`features/auth/`)

**Login (`login_page.dart`)**:
- Email/password form using `Validators.email` and a simpler required check for password
- Biometric button shown only if `BiometricService.supported && enabled`
- On biometric login: authenticates → reads stored credentials → calls `AuthRepository.login()`
- If biometric credentials are invalid (password changed), auto-disables biometric and shows guidance
- Router redirect handles navigation after successful login

**Register (`register_page.dart`)**:
- Username, email, password fields
- `Validators.username` (3–20 chars, lowercase letters, digits, underscore only)
- `Validators.password` (8–64 chars, must contain letter AND digit)
- On success, router redirects automatically; no manual navigation

**AuthRepository (`auth/data/auth_repository.dart`)**:
- `login()` → `_auth.signInWithPassword()`
- `register()` → `_auth.signUp()` with `data: {'username': username}` as user metadata
- `logout()`: **critical order** — `signOut(scope: SignOutScope.local)` first (no network), then `NotificationService.stopBackground()` and `LocalDb.clear()` as best-effort

**BiometricService (`auth/data/biometric_service.dart`)**:
- Stores `bio_email` and `bio_pass` in `FlutterSecureStorage` (separate from session token)
- `authenticate()` uses `biometricOnly: false` → allows PIN/pattern fallback
- `enabledFor(email)` checks that stored email matches current user to prevent cross-account use
- Enabling: requires successful `authenticate()` + explicit password confirmation via `AuthRepository.login()`

### 7.2 Market (`features/market/`)

**Market model (`domain/market.dart`)**:
```dart
class Market {
  final String id, title, category, status;
  final String? description, imageUrl, outcome;
  final DateTime closeAt;
  final double b, qYes, qNo, priceYes, volume;
  bool get isOpen => status == 'open' && closeAt.isAfter(DateTime.now());
}
```
- `isOpen` is computed client-side using `closeAt` vs current time
- `MarketStatus.from(status, closeAt)` in `template.dart` adds a `closed` computed state

**Market list (`market_list_page.dart`)**:
- Active markets sorted by `closeAt` ascending (soonest to close first)
- Resolved/cancelled markets in a collapsible section, sorted by `closeAt` descending
- Category filter chips generated dynamically from available categories
- `AppSearchBar` with 400ms debounce → updates `_q` state → re-watches `marketListProvider(_q)`
- Offline cache: only when `query.isEmpty` (via `LocalDb.cachedList`)

**MarketRepository (`market/data/market_repository.dart`)**:
- `list(query)`: uses `ilike` with `Validators.likeEscape()` for wildcard safety, limit 100
- `get(id)`: single market by UUID
- `history(id)`: last 100 price snapshots from `price_history` (reversed to chronological)
- `trade()`: calls `trade_market` RPC, returns `amount` from response

**LMSR pricing (`domain/lmsr.dart`)**:
- `cost(qy, qn, b)` uses numerically stable log-sum-exp
- `price(qy, qn, b)` = `1 / (1 + e^((qn-qy)/b))`
- `quote(...)` returns `(amount, priceYes)` — buy rounds up 4 decimals, sell rounds down
- **Client-side preview only.** Authoritative amount comes from server RPC.

**Trade sheet (`market/presentation/trade_sheet.dart`)**:
- Selects Beli/Jual and YES/NO via `AppSegmented`
- `AppAmountStepper` for share count (1–1000, step 1)
- Client validation: disables submit button if balance or shares insufficient
- After successful trade: invalidates `marketProvider`, `priceHistoryProvider`, `marketListProvider`, `portfolioProvider`, `tradesProvider`, `balanceProvider`

### 7.3 Portfolio (`features/portfolio/`)

**PortfolioPosition model** (defined in `portfolio_repository.dart`):
- Holds reference to full `Market` object (joined in query)
- `value` = `shares × (priceYes if side=yes, else 1-priceYes)`
- `unrealized` = `value - cost` (only when shares > 0)
- Positions with `shares == 0` included for realized PnL calculation

**PortfolioRepository**:
- `positions()`: joins `markets` table with all market columns
- `trades()`: last 20 trades hardcoded limit

### 7.4 Profile (`features/profile/`)

**ProfileRepository**:
- `_uid` getter throws `AuthException('not_authenticated')` if `currentUser == null` — prevents crash on logout race
- `update()`: partial update, only sends non-null fields
- `avatarUrl` restricted to `https://res.cloudinary.com/` prefix by server constraint

**Profile page (`profile_page.dart`)**:
- Avatar upload: `ImagePicker → CloudinaryService.uploadAvatar → ProfileRepository.update`
- Name editing: via `askInput()` bottom sheet
- Biometric toggle: enables after re-authenticating + password confirmation; disables after confirmation
- Admin users see "Panel admin" → `/admin`
- Logout: confirmation dialog → `AuthRepository.logout()` → `GoRouter.go('/login')`

**CloudinaryService**:
- Compresses to JPEG 512×512 min, 80% quality
- Rejects if compressed size > 3MB (`FormatException('image')`)

### 7.5 Notifications (`features/notification/`)

**Three-layer notification system**:
1. **Realtime (foreground)**: `MainShell._start()` subscribes to Supabase Realtime `notif_<uid>` channel. On INSERT in `notifications` table → `NotificationService.show()` + invalidate `notificationsProvider`.
2. **Background polling**: Workmanager periodic task (min 15 min), re-initializes Supabase in isolate, calls `NotificationService.pollBackground()`.
3. **Deduplication**: `notif_last` in `FlutterSecureStorage` — only newer notifications shown.

**AppNotification model** contains `marketId` from `data->>'market_id'` JSONB — used for notification tap navigation.

### 7.6 Chatbot (`features/chatbot/`)

**GeminiService**:
- Model: `gemini-3.8-flash` (⚠️ verify this exists)
- System prompt: Bahasa Indonesia, max 120 words, no real investment advice, explains LMSR
- Injects up to 10 active markets with YES prices as context
- `maxOutputTokens: 600`, `temperature: 0.7`, `thinkingBudget: 0`

**ChatPage**:
- Rate limit: 15 messages per 10-minute rolling window (client-side)
- History window: last 10 messages sent to Gemini
- Chat history persisted in sqflite
- `maxLength: 300` for input
- No retry logic — errors displayed via `AppToast`

### 7.7 Converter (`features/converter/`)

**Three tabs**: Fiat, Crypto, Time

- **Fiat**: `open.er-api.com`, 5 currencies + KOIN (1 KOIN = 1 USD dummy), cache 1 hour
- **Crypto**: CoinGecko, BTC/ETH/SOL vs USD + IDR, cache 2 minutes
- **Time zones**: WIB, WITA, WIT, London using `timezone` package
- Time zone tab can use market `closeAt` as the time to convert

### 7.8 Nearby / LBS (`features/nearby/`)

- Requests GPS via `geolocator`
- Fetches open markets with non-null `latitude`/`longitude`
- Calculates and sorts by distance client-side
- Map: `flutter_map` with OpenStreetMap tiles
- `userAgentPackageName: 'com.example.ramala'` must match `applicationId`

### 7.9 Game — "Tebak Arah" (`features/game/`)

- 10 rounds, 3 seconds each
- Directions: kiri, kanan, maju, mundur, putar (5 options)
- **Accelerometer**: ±5 m/s² threshold on X/Y axis
- **Gyroscope**: `|z| > 5` rad/s for rotation
- Scoring: 100 base + speed bonus per correct answer
- 400ms debounce prevents carry-over from previous gesture
- Scores saved to `game_scores` table; leaderboard shows top 10

### 7.10 Blockchain Ledger (`features/ledger/`)

- Reads last 50 entries from `ledger` table
- `hash = SHA-256("<idx>|<prev_hash>|<data>")` computed in Postgres
- "Verifikasi rantai" button calls `verify_ledger()` RPC → returns corrupted `idx` or null
- Corrupted blocks highlighted with red border (`AppCard(borderColor: AppColors.no)`)

### 7.11 Admin Panel (`features/admin/`)

- **No client-side route guard** — security enforced by Supabase RPCs
- Create market: fields for title, description, category, b parameter, optional lat/lng, close datetime
- Calls `admin_create_market` RPC directly (no repository layer)
- Resolve market: shows open markets → YES/NO choice → confirmation → `admin_resolve_market` RPC
- **⚠️ `p_image_url` parameter is in the RPC signature but NOT in the admin form**

### 7.12 Feedback (`features/feedback/`)

- Star rating 1–5 (required), impression + suggestion fields (min 5, max 500 chars)
- Inserts into `feedback` table directly (no repository layer)

---

## 8. State Management and Data Flow

### Riverpod Providers

All providers: `FutureProvider.autoDispose` with `retry: (_, __) => null` (no auto-retry).

| Provider | Location | Notes |
|---|---|---|
| `routerProvider` | `core/router/app_router.dart` | Includes `_AuthRefresh` auth listenable |
| `marketListProvider(q)` | `market/presentation/market_providers.dart` | Family by search query |
| `marketProvider(id)` | same | Family by market UUID |
| `priceHistoryProvider(id)` | same | Family by market UUID |
| `portfolioProvider` | `portfolio/presentation/portfolio_providers.dart` | |
| `tradesProvider` | same | |
| `profileProvider` | `profile/presentation/profile_providers.dart` | |
| `balanceProvider` | same | |
| `notificationsProvider` | `notification/presentation/notification_page.dart` | Also invalidated by Realtime in `MainShell` |
| `ledgerProvider` | `ledger/presentation/ledger_page.dart` | Defined inline |
| `_boardProvider` | `game/presentation/game_page.dart` | Defined inline |
| `_fiatProvider`, `_cryptoProvider` | `converter/presentation/converter_page.dart` | Defined inline |
| `_nearbyProvider` | `nearby/presentation/nearby_page.dart` | Returns named record |

### Cache Strategy

`LocalDb.cachedList(key, fetch)` — network-first, falls back to cache only for network errors. Supabase errors are NOT cached-over — re-thrown. All cache cleared on logout.

Cache keys: `markets:list`, `portfolio:<uid>`, `notif:<uid>`, `rates:fiat`, `rates:crypto`

---

## 9. Data Models, Persistence, and External Services

### Supabase Database Tables

| Table | Key Columns | Client Access |
|---|---|---|
| `profiles` | `id, username, display_name, avatar_url, role, created_at` | SELECT all; UPDATE `username, display_name, avatar_url` |
| `wallets` | `user_id, balance` | SELECT own |
| `markets` | `id, title, description, category, image_url, latitude, longitude, close_at, status, outcome, b, q_yes, q_no, price_yes, volume, created_by, created_at, resolved_at` | SELECT all |
| `positions` | `user_id, market_id, side, shares, cost, realized_pnl` | SELECT own |
| `trades` | `id, user_id, market_id, side, action, shares, amount, price_yes_after, created_at` | SELECT own |
| `price_history` | `market_id, price_yes, created_at` | SELECT |
| `ledger` | `idx, prev_hash, data, hash, created_at` | SELECT only |
| `notifications` | `id, user_id, type, title, body, data (JSONB), is_read, created_at` | SELECT own; UPDATE `is_read` |
| `feedback` | `impression, suggestion, rating` | INSERT |
| `game_scores` | `game, score, user_id, created_at` | INSERT; SELECT |

### Supabase RPCs

| RPC | Parameters | Returns |
|---|---|---|
| `trade_market` | `p_market uuid, p_side, p_action, p_shares numeric 0.01–1000` | `{trade_id, shares, amount, price_yes, balance}` |
| `admin_create_market` | `p_title, p_close_at, p_description, p_category, p_b, p_image_url?, p_lat?, p_lng?` | uuid |
| `admin_resolve_market` | `p_market uuid, p_outcome 'yes'\|'no'` | void |
| `verify_ledger` | none | `int?` (corrupted idx) or null |
| `is_admin` | none | bool |

### sqflite Tables (`ramala.db`)

1. `cache(key TEXT PK, json TEXT, updated_at INTEGER)`
2. `chat_messages(id INTEGER AUTOINCREMENT PK, role TEXT, content TEXT, created_at INTEGER)`
3. `search_history(query TEXT PK, used_at INTEGER)` — structure exists, not actively used in UI

---

## 10. UI Conventions and Design System

**Single file**: `lib/template.dart` — imported by ALL pages as `import 'package:ramala/template.dart'`.

**Design concept**: "séance / crystal ball" — deep dark purple-black with orange-pumpkin accents.

### Color System (`AppColors`)

| Name | Hex | Use |
|---|---|---|
| `bg` | `#0B0710` | Page background |
| `surface` | `#150E1C` | Inputs, nav bar, bottom sheets |
| `card` | `#1E1428` | Card backgrounds |
| `border` | `#2E2140` | Borders |
| `primary` | `#FF7A1A` | Actions, brand (orange) |
| `accent` | `#FFC24A` | Coin values, highlights (amber) |
| `arcane` | `#8B5CF6` | Info, empty states (purple) |
| `yes` | `#7EE08A` | YES direction, profit (green) |
| `no` | `#F0455A` | NO direction, loss, errors (red) |

### Typography (`AppText`)

- **Cinzel**: `display` (28px bold), `title` (20px bold) — page titles, logo
- **Inter**: all other styles — `heading`, `body`, `bodyDim`, `label`, `caption`, `number`, `numberSm`
- Numbers use tabular figures (`FontFeature.tabularFigures()`)

### Spacing and Radius

- `AppSpace`: xs=4, sm=8, md=12, lg=16, xl=24, xxl=32
- `AppRadius`: sm=8, md=12, lg=16, xl=24, pill=999

### Key Widget Rules

1. Every page uses `AppScaffold`. `children:` for scrollable; `body:` for custom layouts.
2. Loading: `AppSkeleton` for placeholders; `AppLoading` for spinners.
3. States: `EmptyState` (no data), `ErrorState` (always include `onRetry`).
4. Feedback: `AppToast.show(context, message, type: ToastType.*)`.
5. Risky actions: `AppConfirmDialog.show(context, ...)` returns `Future<bool>`.
6. Bottom panels: `AppBottomSheet.show<T>(context, title, child)` returns `Future<T?>`.
7. **Only one glowing card (`AppCard(glow: true)`) per screen**.
8. **Only one primary `AppButton` per screen/panel**.
9. `AppNavItem(icon, label, [activeIcon])` — **positional constructor**.
10. `MarketStatus.from(status, closeAt)` — always use this, not raw `status` string.

---

## 11. Validation and Error Handling

### Client-side Validation

| Validator | Rules |
|---|---|
| `Validators.clean(s)` | Trim + remove control characters |
| `Validators.email(v)` | Required, max 100 chars, basic format regex |
| `Validators.password(v)` | 8–64 chars, must contain letter AND digit |
| `Validators.username(v)` | `^[a-z0-9_]{3,20}$` |
| `Validators.displayName(v)` | Required, max 40 chars |
| `Validators.required(v, {min, max})` | min=1 (default), max=500 (default) |
| `Validators.searchTerm(s)` | Clean + truncate to 60 chars |
| `Validators.likeEscape(s)` | Escapes `\`, `%`, `_` for `ilike` queries |

### Error Mapping (`AppError.message(Object e)`)

Maps `SocketException`, `AuthException` (by code), `PostgrestException` (by RPC error code), `DioException` (by HTTP status) to Indonesian messages. Raw server messages are never shown.

---

## 12. Configuration, Testing, and Build Instructions

### Running

```bash
flutter pub get
# Create env.json at project root with:
# SUPABASE_URL, SUPABASE_ANON_KEY, CLOUDINARY_CLOUD_NAME, CLOUDINARY_UPLOAD_PRESET, GEMINI_API_KEY
flutter run --dart-define-from-file=env.json
```

### Key Notes

- Changes to `env.json`, `AndroidManifest.xml`, or Gradle require **full stop + restart**
- Game sensor and GPS require a **physical device**
- Admin access: SQL Editor on Supabase: `UPDATE public.profiles SET role = 'admin' WHERE username = 'name';`

### Build Config

- `compileSdk = 37`, `minSdk = flutter.minSdkVersion`
- `isCoreLibraryDesugaringEnabled = true` (required for timezone)
- Release build uses debug signing key — replace before production
- `MainActivity.kt` extends `FlutterFragmentActivity` (required for `local_auth`)

---

## 13. Known Issues, Incomplete Work, and Technical Debt

1. **Gemini model `gemini-3.8-flash`**: Likely invalid model name — verify against Gemini API docs before relying on chatbot
2. **`env.json` is in the repo with real keys** — significant security risk
3. **Admin route has no client-side guard** — any authenticated user can navigate to `/admin`; server RPCs enforce access
4. **`p_image_url` missing from admin form** — RPC supports it but UI doesn't expose the field
5. **`features/trading/` and `features/wallet/`** — empty placeholder folders
6. **`search_history` table** — exists in sqflite but no autocomplete UI reads it
7. **`PortfolioRepository.trades()` limit 20** and **`MarketRepository.list()` limit 100** — no pagination
8. **Logout race condition** — may reappear after hot reload; use full restart
9. **Release signing** — uses debug keystore
10. **Background notifications not fully tested** — only "after resolve" notification confirmed working
11. **Trailing slash in `SUPABASE_URL`** in `env.json` — remove trailing slash per `catatan_rencana.md` guidance

---

## 14. Documentation-versus-Code Discrepancies

| Documentation claim | Code reality |
|---|---|
| `catatan_rencana.md`: hash computed in client (`crypto` package) | `verify_ledger()` RPC does all computation server-side; `crypto` package imported but not used for ledger |
| `catatan_rencana.md`: retry 2× with delays for chatbot | Not implemented; `GeminiService` has no retry logic |
| `prompt_context.md`: `admin_create_market` includes `p_image_url` | `AdminPage._create()` never passes `p_image_url` — field missing from form |
| `struktur_folder_sementara.txt`: nested state widget folders under `core/widgets/` | Only `input_sheet.dart` exists; nested folders do not exist |
| `koteks_percakapan_pengerjaan_mvp.md`: retry 2×/delays for 503/429 | Not implemented in current code |

---

## 15. Constraints and Instructions for Future AI Assistants

### Mandatory Code Rules

1. **All UI via `import 'package:ramala/template.dart'`** — never hardcode colors, sizes, or fonts
2. **Every page wrapped in `AppScaffold`**
3. **All inputs**: use `Validators.*`, set `maxLength`, use `inputFormatters`, call `Validators.clean()`
4. **No retry auto**: all `FutureProvider` use `retry: (_, __) => null`
5. **No client-side balance/role mutations**: all through RPC
6. **Error display**: always use `AppError.message(e)` — never show raw server messages
7. **Language**: all UI text in Bahasa Indonesia
8. **No codegen**: do not add `build_runner`, `freezed`, or `riverpod_generator`

### Widget Signature Traps

- `AppNavItem(icon, label, [activeIcon])` — **positional, not named**
- `AppScaffold` requires either `children` or `body` (assert will throw otherwise)
- `AppCard(glow: true)` — only one per screen
- `AppButton(variant: AppButtonVariant.primary)` — only one per screen/panel
- `MarketCard` — `footer` is **required**
- `AppBottomSheet.show<T>` returns `Future<T?>` — always handle `null`
- `TradeSheet` requires `market`, `heldYes`, `heldNo`

### Provider Patterns

- `FutureProvider.autoDispose` for all data providers
- Place feature-shared providers in `<feature>/presentation/<feature>_providers.dart`
- Page-only providers may be defined at file top
- After mutations: invalidate all affected providers (market + price history + portfolio + balance)

---

## 16. Unresolved Questions and Confidence Limitations

1. **`gemini-3.8-flash` model name**: Unknown if valid — must verify against Gemini API before using chatbot
2. **Trailing slash in `SUPABASE_URL`**: `env.json` has `https://...supabase.co/`; docs say use base URL without trailing path — verify SDK behavior
3. **`admin_create_market` `p_image_url`**: Whether RPC accepts null for this required/optional parameter
4. **`search_history` table**: Intended use for autocomplete is unimplemented
5. **Workmanager on OEM phones**: Background task may be delayed well beyond 15 min on battery-saving modes
6. **`minSdk` effective value**: `flutter.minSdkVersion` default; some packages (`local_auth`, `workmanager`) may require higher
7. **`supabase/` directory**: Could not inspect (binary/directory); likely contains Supabase CLI migration files

---

## 17. Source Coverage and Files Inspected

### Fully Inspected

All Dart source files under `lib/` (49 files, including `template.dart` at 1131 lines), `pubspec.yaml`, all 6 docs files, `AndroidManifest.xml`, `build.gradle.kts`, and `env.json`. `MainActivity.kt` inspected via grep (confirms `FlutterFragmentActivity`).

### Not Inspected

- `lib/features/contoh_struktur/`, `lib/features/trading/`, `lib/features/wallet/` — gitkeep only
- `lib/shell/placeholder_page.dart` — exists, commented out in router
- `test/` directory — expected empty per docs
- `supabase/` directory — could not read (OS error)
- Binary assets (`assets/gambar/`)

### Completeness

**High confidence**: Architecture, routing, auth, all feature implementations, database schema, LMSR formula, error handling, design system.  
**Medium confidence**: Supabase RLS rules (server-side), Workmanager behavior per Android version.  
**Low confidence**: `gemini-3.8-flash` model validity; `supabase/` directory contents.
