# Build & CI

## Supabase project

- Project ref: `ttjpmsgmmnvyyzbesoda` → `https://ttjpmsgmmnvyyzbesoda.supabase.co`
- Schema: `supabase_schema.sql` + `supabase_fashion_migration.sql` applied via
  MCP migrations (`tstore_base_tables`, `tstore_indexes_rls`,
  `tstore_functions_triggers`, `fashion_foundation`, `harden_functions`,
  `storage_image_policies`). Seed: `supabase_sample_data.sql` (76 fictional
  products, 6 categories, 6 brands, 5 banners, 3 coupons).
- Buckets (public read, authenticated write, owner update/delete):
  `product-images`, `category-images`, `brand-logos`, `banner-images`,
  `avatars`, `review-images`.

## Local commands (no local run/APK build required; CI builds the APK)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run -t lib/main_development.dart   # dev only, needs config below
```

## Configuration (build-time, never committed)

Preferred (works everywhere, including CI):

```bash
flutter run -t lib/main_development.dart \
  --dart-define=SUPABASE_URL=https://ttjpmsgmmnvyyzbesoda.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Local-dev alternative: copy `.env.example` to `.env` (never commit `.env`):

```env
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
```

`lib/core/supabase/supabase_config.dart` reads `--dart-define` first
(`SUPABASE_PUBLISHABLE_KEY`, falling back to legacy `SUPABASE_ANON_KEY`),
then `.env`, and fails clearly if all are missing. Only the publishable/
anon key may ship in the app — RLS protects the data. Never put a
service_role / secret key in Flutter.

## GitHub Actions

Workflow: `.github/workflows/flutter.yml` — checkout → Flutter 3.38.4 →
`pub get` → `.env` from example → format check → `analyze` → `test` →
**release** APK → upload artifact `fashion-app-release-apk`
(`build/app/outputs/flutter-apk/app-production-release.apk`). Fails on any step.

Required repository secrets (names only; values live in GitHub):

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

They are passed as `--dart-define` flags. Secrets are never printed,
logged, or committed. The APK is signed with the debug keystore (CI
release APK); Play Store production signing is a separate setup.