# Phase 1 — Foundation Completion

## Changed

- Legacy removal: DummyJSON auth + shop stacks, typo `depandancy_injection`, deprecated locator, `api_constants.dart`, realtime chat demo + `chat_messages`, unused deps (`image_picker`, `lottie`, `capped_progress_indicator`).
- Fashion domain: 72-product fictional seed with attributes JSONB, 6 categories + 6 brands + 5 banners + 3 coupons; `supabase_fashion_migration.sql` (indexes, coupons RLS, order-cancel policy, chat retirement, storage notes).
- UI/identity: app name `Fashion`, Android `com.fashionapp.store`, iOS `com.fashionapp.store`, bottom nav Home/Explore/Wishlist/Cart/Profile, `SortableProducts` migrated to `ProductsCubit`, login flow provisions `ProductsCubit`, `availabilityStatus` localized.
- Deps: splash/icons → dev deps; lock + registrants regenerated.
- CI: `.github/workflows/flutter.yml` (format → analyze → test → debug APK → `fashion-app-debug-apk`).

## Removed (why)

- DummyJSON stacks: dead parallel backend wired alongside Supabase (verified zero live UI refs before deletion except 2 migrated widgets).
- Chat: no UI, not in target product; 17 coupled tests removed with feature.
- `api_constants.dart`: DummyJSON + third-party backend URLs, unused after deletion.

## Preserved

Clean Architecture layers, Supabase auth/shop/cart/wishlist/orders/reviews/personalization/notifications/coupons, theme + common widgets, `SupabaseService` seam, new DI, remaining 12 test files, RLS core.

## Repaired

Single DI (was 3), single auth/shop stack (was 2), orders cancel gap, coupons RLS gap, malformed `flutter_launcher_icons.yaml` dev-deps entry, app identity placeholders.

## Tests / analyze / CI (actual results, 2026-09-27)

- `flutter pub get`: resolves ("Changed 27 dependencies"); plugin-symlink step fails on no-symlink filesystem (local-only; CI unaffected).
- `flutter analyze`: **No issues found (exit 0)** — after restoring `OnBoardingCubit` (17 errors) and awaiting a future in `profile_repository_impl.dart` (1 warning).
- `flutter test`: **202/202 passed (exit 0)** — full suite incl. `widget_test.dart`; one expectation fixed (availability strings localized, test updated not deleted).
- `dart format --set-exit-if-changed`: clean after `style: apply dart format` commit (repo was not format-clean upstream: 203 files).
- CI: workflow created (`.github/workflows/flutter.yml`); first run requires push to a fork with Actions enabled — NOT YET RUN (no credentials in this environment).

## Verification status

- Analyze: **clean — No issues found (exit 0)**
- Tests: **202/202 passed (exit 0)**
- Format: clean (`style: apply dart format` committed; CI gate covers future changes)
- APK: deferred to CI per constraint (no local `flutter run`/`flutter build`)

## Known issues (genuine)

1. Local FS lacks symlink support → `flutter pub get` exit 1 at plugin-symlink stage; harmless for analyze/test/CI.
2. `analysis_options.yaml` auto-upgraded by Flutter tool (platform excludes) — kept intentionally.
3. Seed images are `picsum.photos` placeholders until Phase 8 licensed catalog.
4. `widget_test.dart` pumps full app without DI setup — pre-existing upstream condition; CI will adjudicate.

## Next phase

Phase 2 — Personal Wardrobe. DO NOT start automatically.
