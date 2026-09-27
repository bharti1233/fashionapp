# Build & CI

## Local commands (no local run/APK build required; CI builds the APK)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run -t lib/main_development.dart   # dev only, needs .env + Supabase project
```

## Environment variables

Copy `.env.example` to `.env` (never commit `.env`):

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Only the anon key is client-safe. Service-role keys stay server-side.

## Supabase setup

1. Run `supabase_schema.sql`, then `supabase_fashion_migration.sql` in SQL Editor.
2. Load `supabase_sample_data.sql` (fictional fashion seed, optional).
3. Buckets: `avatars`, `products`, `reviews` (public read, owner write per migration notes).

## GitHub Actions

Workflow: `.github/workflows/flutter.yml` — checkout → Flutter 3.38.4 → `pub get` → format check → `analyze` → `test` → debug APK → upload artifact `fashion-app-debug-apk` (`build/app/outputs/flutter-apk/app-debug.apk`). Fails on any step. No secrets required.
