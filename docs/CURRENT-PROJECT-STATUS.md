# Current Project Status

## Product

Fashion commerce + AI fashion platform (commerce foundation complete; AI phases planned).

## Current Phase

Phase 1 — Fashion Commerce Foundation: COMPLETE (implementation + live Supabase + CI + runtime startup fixed).

## Completed (verified in `TStore/`)

- Flutter Clean Architecture foundation, Supabase Auth, onboarding, Home/Explore/Wishlist/Cart/Profile nav.
- Fashion catalog: 6 categories, 6 fictional brands, 76 seeded products with size/color/material/fit/pattern/occasion/season/gender attributes, search, filter, sort, product details, variants via attributes.
- Wishlist, cart, checkout view, orders (+cancel own pending), addresses, reviews/ratings, notifications, coupons, theme, shimmer/loading/empty/error states.
- Security: RLS on all tables (+ owner-scoped user data, public active catalog, coupon/RLS hardening, function search_path pinning, trigger-function RPC revoked), no committed secrets (`.env.example` placeholders only), publishable-key-only client via `--dart-define`.
- Legacy removal: DummyJSON stacks, chat demo, unused deps; single DI; `flutter_launcher_icons`/`flutter_native_splash` → dev deps.
- Live Supabase project `ttjpmsgmmnvyyzbesoda`: schema + RLS + 76 products + 6 buckets + image policies applied and query-verified.
- GitHub repo `bharti1233/fashionapp` (branch `main`, TStore content only) with release-APK CI.
- Runtime startup fix: splash screen hang resolved (15s timeout + error UI, native splash removed properly).
- Docs: `docs/{REPOSITORY-AUDIT,FASHION-APP-ARCHITECTURE,BUILD-AND-CI,PHASE-1-FOUNDATION-COMPLETION}.md`, Phase-0 addendum.

## In Progress

None — Phase 1 complete.

## Planned

Phase 2 Wardrobe → 3 Outfit Builder → 4 AI Stylist → 5 Photo Try-On → 6 Live Try-On → 7 Mirror → 8 Legal Catalog → 9 Personalization → 10 Hardening (see `docs/PHASE-ROADMAP.md`).

## Architecture

Current: Flutter → Repository/Data layer → Supabase (Postgres/Auth/Storage).
Future: Flutter → FastAPI → Supabase/Postgres (+ Redis/ARQ + AI/VTON providers). FastAPI is planned, NOT implemented.

## Build / Test / CI Status

- `flutter pub get`: resolves locally; CI installs clean.
- `flutter analyze`: **clean — No issues found (exit 0)** locally and in CI.
- `flutter test`: **202/202 passed (exit 0)** locally; CI runs the same suite.
- CI (`.github/workflows/flutter.yml`): release APK + `fashion-app-release-apk` artifact; secrets `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`.
- **Latest CI run #6 (commit 35a1e81): SUCCESS** — format ✓, analyze ✓, tests ✓ (202/202), release APK ✓, artifact `fashion-app-release-apk` (68 MB) ✓.

## Known Issues

- Seed/product images are `picsum.photos` placeholders until licensed catalog arrives (Phase 8).
- CI release APK uses the debug keystore (documented as CI release APK, not Play Store signing).
- Local FS lacks symlink support (documented; CI unaffected).

## Next Phase

Phase 2 — Personal Wardrobe (not started).