# Repository Audit — TStore → Fashion App Foundation

Source: https://github.com/mahmoodhamdi/TStore.git @ `1294310` (clean tree, checkpoint).
Date: 2026-09-27. Method: full static inspection (lib, test, android, assets, configs, SQL, plans, git log). No code modified before this document.

## Original architecture

- Flutter 3.38.4 / Dart 3.10.3 (`TStore/pubspec.yaml:8-9`, `README.md:95-108`), `t_store` package (`pubspec.yaml:1`).
- Clean Architecture per feature: `data/{models,repositories(,data_sources)}` → `domain/{entities,repositories,usecases}` → `presentation/{cubit,views,widgets}` (`TStore/CLAUDE.md:38-83`, `lib/`).
- State: `flutter_bloc ^9.1.1` Cubits; DI: `get_it ^9.2.0`; errors: `dartz Either<String,T>`; backend: `supabase_flutter ^2.8.3` via `SupabaseService` singleton (`lib/core/supabase/supabase_service.dart`).
- Entry: `lib/main_development.dart` + `lib/main_production.dart` → `lib/t_store.dart` (`MultiBlocProvider` + `MaterialApp`, home `OnBoardingView`).
- Navigation: bottom `NavigationBar` Home/Store/Wishlist/Profile (`lib/core/common/widgets/navigation_menu.dart`).

## Current features (verified in source)

Auth (Supabase email/password + reset), OnBoarding, Home + banner carousel, product listing grid/list, search/filter/sort, product details + variations, categories + brands, wishlist, cart, checkout view, orders, profile + addresses, reviews/ratings, realtime chat support, notifications, coupons (`features/shop/presentation/widgets/coupon_code.dart`), light/dark theme, shimmer/loading/empty/error states.

## Classification

### KEEP
Auth (new Supabase stack: `features/auth/{data/repositories,domain/repositories,presentation/cubit}`), shop Supabase stack (product/category/brand/banner repos + cubits), cart, wishlist, orders, reviews, personalization (profile/addresses), notifications, coupons, theme (`core/utils/theme/`), common widgets, `SupabaseService`, new DI (`core/dependency_injection/service_locator.dart`), network (`core/network/dio_client.dart`), tests, `supabase_schema.sql` RLS core.

### MODIFY
- Generic catalog → fashion: categories, products, brands, banners, filters (size/color/brand/price), product cards, home campaigns, profile.
- `products.attributes JSONB` (`supabase_schema.sql:83`) → fashion attributes (size, color, material, fit, pattern, occasion, season, gender) without new tables.
- Sample data: generic Electronics/Clothes/Shoes (`supabase_sample_data.sql:7-10`, 29 products e.g. headphones/laptops) → fictional fashion seed (50–100).
- App identity: `appName "T-Store"` (`lib/core/utils/constants/text_strings.dart:7`), `applicationId "com.example.t_store"` (`android/app/build.gradle:24`), T-Store logos/splash (`splash.yaml`, `flutter_launcher_icons.yaml`, `assets/logos/`).
- Navigation: add Cart tab (currently Home/Store/Wishlist/Profile; cart only via icon) → Home/Explore/Wishlist/Cart/Profile.
- Product entity: fix Arabic-only `availabilityStatus` (`lib/features/shop/domain/entities/product_entity.dart`) → localized strings.

### REPLACE
- Old DummyJSON auth stack (`core/depandancy_injection/service_locator.dart` [typo dir], `features/auth/data/repository/auth_repo_impl.dart`, `domain/repository/auth_repo.dart`, `data_sources/auth_*`, req/res models, `presentation/logic/*` legacy cubits using `sl` from typo path) — both stacks wired simultaneously in `main_*.dart` (new `setupServiceLocator()` + deprecated `setupOldServiceLocator()`). Exception: `presentation/logic/on_boarding/` is self-contained UI state with no legacy deps — kept (it was removed in error and restored; `flutter analyze` caught it).
- Old DummyJSON shop stack (`core/utils/service_locator/service_locator.dart` marked `@deprecated`, `features/shop/data/repository_impl/shop_repository_impl.dart`, `domain/repository/shop_repository.dart`, old usecases `get_products_list/by_search/by_category/sorted`, `presentation/controller/shop_cubit.dart`, `shop_local/remote_data_source.dart` if DummyJSON-bound, `core/utils/constants/api_constants.dart` if Platzi URLs).
- Duplicate base usecase (`core/usecase/usecase.dart` vs `core/usecases/usecase.dart` — different signatures `Future<T>` vs `Either<String,T>`).
- `flutter_launcher_icons.yaml` self-reference (`flutter_launcher_icons: "^0.13.1"` under `dev_dependencies:` key — malformed) and `min_sdk_android: 21` vs AGP default; `splash.yaml` `web: false` + dev_deps typo.
- `availabilityStatus` hardcoded Arabic strings (see above).

### DELETE
- `lib/core/common/view_models/` (20 files mirroring widgets — over-abstraction; verify unused then remove).
- `lib/features/chat/` (realtime support chat + `chat_messages` table usage; not in target product; removes 17 coupled tests `test/unit/chat/chat_cubit_test.dart`).
- `lib/core/common/widgets/curverd_edges/curverd_edges.dart` if duplicate of `curved_widget.dart`.
- Unused assets after fashion reseed (electronics/generic product images, reviews placeholders).
- `plans/` Arabic drafts are superseded by `docs/` (keep file, mark historical).

### FUTURE / RESERVED
Wardrobe, clothing upload/classification/metadata, outfit builder, AI stylist, weather-aware + outfit recommendations, photo/live try-on, fashion mirror, wear tracking, style profile, personalization engine, FastAPI layer (`Flutter → Repository → Supabase` kept seam-ready; see `docs/FASHION-APP-ARCHITECTURE.md`).

## Dependency findings (`pubspec.yaml`)

Used & keep: `flutter_bloc`, `get_it`, `equatable`, `supabase_flutter`, `dartz`, `dio`, `cached_network_image`, `shared_preferences`, `image_picker`, `intl`, `logger`, `url_launcher`, `flutter_dotenv`, `permission_handler`, `geolocator`, `geocoding`, UI (iconsax, carousel_slider, shimmer, readmore, rating_bar, smooth_indicator, lottie, capped_progress).
Verify-then-remove candidates: `http ^1.3.0` (if Dio covers all), `flutter_native_splash`/`flutter_launcher_icons` (dev-use packages under `dependencies` — should be dev), location stack (if unused by commerce flows).
Do not add: Stripe, OpenAI/Gemini/Claude, VTON/Decart/Replicate/FASHN, WebRTC (all deferred; no such deps present — verified).

## Security findings

- No committed secrets: `.env` absent (only `.env.example` with placeholders), secret scan clean (`service_role|sk_live|AKIA|AIza|ghp_` → 0 hits outside `.git/`).
- `SupabaseConfig` reads `dotenv` anon key only (client-safe). No service-role in Flutter (verified).
- RLS present on all 14 tables (`supabase_schema.sql:263-307`): user tables owner-checked (`auth.uid()=user_id`), catalog public-read gated `is_active=true`, reviews owner-write. Gaps to fix: missing UPDATE/DELETE on orders (users can't cancel), no UPDATE on profiles? (present), `order_items` SELECT policy join check, coupons public-read? (verify), storage policies live in dashboard not SQL (must document bucket policies for `avatars,products,reviews,chat` → fashion buckets).
- Risks carried: chat realtime exposure (removed with feature), public storage buckets (must be read-public/write-owner).

## Database findings

14 tables: profiles, categories, brands, products (+`attributes JSONB`), addresses, wishlist, cart_items, orders, order_items, reviews, banners, chat_messages, notifications, coupons. Verdict: evolve, don't rebuild. Migrations: add fashion attribute conventions (JSONB, no schema change), fashion seed replaces sample data (fictional, no retailer copying; existing images hotlink `i.imgur.com` + Platzi — replace with owned/placeholder assets), drop `chat_messages` (after code removal).

## UI findings

Sound commerce UI (cards, carousel, shimmer, themes Poppins/Coolvetica). Fashion gaps: generic electronics imagery, "T-Store" branding, no size/color variant selectors wired to data (check `product_details_view`), Store tab doubles Home (Explore/Search redesign), missing Cart tab.

## Build findings (static; no local run/build per constraint — APK via CI)

- `android/app/build.gradle`: `compileSdk=36`, `targetSdk=36`, `minSdk=flutter.minSdkVersion`, Kotlin `2.1.0`, `applicationId "com.example.t_store"` (+`.dev` suffix flavor). Must rename applicationId (e.g. `com.fashionapp.store`).
- `analysis_options.yaml`, tests claimed 219 (13 files in `test/`). Verification via `flutter analyze`/`flutter test`/CI (see `docs/BUILD-AND-CI.md`).

## Test findings (claimed → to verify)

`test/unit/*` (auth 45, shop 32, cart 23, wishlist 20, orders 16, reviews 16, chat 17, notifications 17, personalization 22) + `test/integration/auth_flow_test.dart` (11) + `widget_test.dart`. Risks: chat tests die with feature; old-stack tests (`auth_repository_test`, `auth_usecases_test`, `shop_usecases_test`) may target deleted code → rewrite against new stack, never delete-to-green.
