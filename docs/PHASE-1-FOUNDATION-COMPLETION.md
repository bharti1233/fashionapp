# Phase 1 — Foundation Completion

## Changed

- Legacy removal: DummyJSON auth + shop stacks, typo `depandancy_injection`, deprecated locator, `api_constants.dart`, realtime chat demo + `chat_messages`, unused deps (`image_picker`, `lottie`, `capped_progress_indicator`).
- Fashion domain: 76-product fictional seed with attributes JSONB, 6 categories + 6 brands + 5 banners + 3 coupons; `supabase_fashion_migration.sql` (indexes, coupons RLS, order-cancel policy, chat retirement, storage notes). Seed UUIDs validated; explicit jeans range added.
- UI/identity: app name `Fashion`, Android `com.fashionapp.store`, iOS `com.fashionapp.store`, bottom nav Home/Explore/Wishlist/Cart/Profile, `SortableProducts` migrated to `ProductsCubit`, login flow provisions `ProductsCubit`, `availabilityStatus` localized.
- Deps: splash/icons → dev deps; lock + registrants regenerated.
- Supabase config: `--dart-define` first (`SUPABASE_PUBLISHABLE_KEY` preferred, `SUPABASE_ANON_KEY` compat), `.env` fallback, clear failure when missing; hardcoded fallback credentials removed.
- Live Supabase `ttjpmsgmmnvyyzbesoda`: base schema + fashion migration + advisor hardening applied via MCP; 76/6/6/5/3 catalog rows, 6 storage buckets + image policies, query-verified (category filter, search, detail join, price filter).
- CI: `.github/workflows/flutter.yml` (format → analyze → test → **release** APK → `fashion-app-release-apk`, secrets via dart-define).
- **Runtime startup fix**: infinite splash screen resolved
  - Add INTERNET and ACCESS_NETWORK_STATE permissions to AndroidManifest.xml
  - Move `flutter_native_splash` to dependencies (was dev_dependency)
  - Fix FlutterNativeSplash API usage (preserve/remove with widgetsBinding)
  - Add 15-second timeout to Supabase initialization to prevent indefinite hang
  - Add error handling to main() - logs errors but continues to show error UI
  - Add startup error screen in TStore for graceful failure display
  - SupabaseConfig now wraps config errors with helpful context
  - SupabaseService.initialize() is now idempotent and wraps errors with context
- Push protection initially blocked an upstream Firebase refresh token + API key in history (`android/fastlane/Fastfile`, `lib/firebase_options.dart`); redacted, verified absent with `git log -S`, then pushed cleanly.

## Verification status

- Analyze: **clean — No issues found (exit 0)**
- Tests: **202/202 passed (exit 0)**
- Format: clean (`style: apply dart format` committed; CI gate covers future changes)
- APK: CI release build successful; artifact `fashion-app-release-apk` (68.3 MB) uploaded

## Known issues (genuine)

1. Seed/product images are `picsum.photos` placeholders until Phase 8 licensed catalog.
2. CI release APK uses the debug keystore (documented as CI release APK, not Play Store signing).
3. Local FS lacks symlink support (documented; CI unaffected).

## Next phase

Phase 2 — Personal Wardrobe. DO NOT start automatically.