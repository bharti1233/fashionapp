# Fashion App Architecture (current + future)

## Current (implemented)

```
Flutter (BLoC/Cubit + GetIt + dartz Either)
  → Repository interfaces (domain) → Supabase implementations (data)
    → SupabaseService singleton → Supabase (Postgres + Auth + Storage)
```

- Features: auth, shop (products/categories/brands/banners), cart, wishlist, orders, reviews, personalization (profile/addresses), notifications, coupons. Chat removed (see `docs/REPOSITORY-AUDIT.md`).
- Backend access is isolated behind `domain/repositories/*` + use cases; widgets consume Cubits only. No Supabase calls in widgets (verified during audit; `SupabaseService` is the single seam).
- Env: `.env` with `SUPABASE_URL` + `SUPABASE_ANON_KEY` only (see `.env.example`). No service-role in app.

## Database (Supabase Postgres)

`supabase_schema.sql` + `supabase_fashion_migration.sql` + `supabase_sample_data.sql` (72 fictional products, 6 categories, 6 brands, fashion `attributes` JSONB: gender/sizes/colors/material/fit/pattern/occasion/season). RLS owner-checked on user tables, public-read on active catalog, active coupons readable, users can cancel own pending orders. `chat_messages` retired.

## Future AI extension points (reserved, not implemented)

- `lib/features/wardrobe/` (new): clothing upload → classify → `wardrobe_items` table; reuse upload + `ProductsCubit` filter patterns.
- `lib/features/outfits/` (new): outfit builder canvas → `outfits` + `outfit_items{position}` tables.
- `lib/features/stylist/` (new): AI stylist + recommendations; persist to `recommendations`.
- `lib/features/tryon/` (new): photo try-on (`tryon_sessions`, `tryon_results`) then live WebRTC + mirror.
- No AI/VTON/WebRTC/LLM dependencies in `pubspec.yaml` by design.

## Future FastAPI integration point (planned, not implemented)

```
Flutter → FastAPI → Supabase/PostgreSQL (+ Redis/ARQ + AI/VTON providers)
```

Migration path (no full rewrite): keep repository interfaces; add `*ApiDataSource` implementations beside Supabase ones calling FastAPI (`dio` via `core/network/dio_client.dart`); switch DI bindings per flavor (`main_development.dart` vs `main_production.dart`); move secrets (AI/VTON keys) to FastAPI env. FastAPI owns: AI services, VTON providers, background jobs, complex business logic. Supabase remains for Auth/Postgres/Storage.
