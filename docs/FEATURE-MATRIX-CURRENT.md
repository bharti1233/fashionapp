# Current Feature Matrix (actual `TStore/` state)

| Feature | Current Status | Source | Notes |
|---|---|---|---|
| Home / banners | IMPLEMENTED | `lib/features/shop/presentation/views/home_view.dart` | Fashion campaign banners seeded |
| Categories / brands | IMPLEMENTED | `shop/.../categories_cubit.dart`, `brands_cubit.dart` | 6 fashion categories, 6 fictional brands |
| Search / filter / sort | IMPLEMENTED | `products_cubit.dart`, `sortable_products.dart` | Migrated to `ProductsCubit`; size/color via attributes |
| Product listing / details | IMPLEMENTED | `all_products_view.dart`, `product_details_view.dart` | Fashion cards, discount, stock states |
| Sizes / colors / variants | PARTIAL | `product_entity.attributes` + seed JSONB | Data present; variant selectors to be verified on device |
| Wishlist / cart / checkout | IMPLEMENTED | `features/wishlist`, `features/cart`, `cart_view.dart`, `checkout_view.dart` | Cart added to bottom nav |
| Orders / history / cancel | IMPLEMENTED | `features/orders` + cancel-own-pending RLS | `supabase_fashion_migration.sql` |
| Addresses / profile | IMPLEMENTED | `features/personalization` | Kept |
| Reviews / ratings | IMPLEMENTED | `features/reviews` | Kept |
| Notifications / coupons | IMPLEMENTED | `features/notifications`, `coupon_code.dart` | Coupons RLS added |
| Auth / onboarding / theme | IMPLEMENTED | `features/auth` (single Supabase stack) | Legacy stacks removed |
| Support chat | REMOVED | (deleted) | Not in target product |
| Wardrobe / outfit / stylist | PLANNED | Phase 2–4 | Extension points documented, no code |
| Photo / live try-on / mirror | PLANNED | Phase 5–7 | No AI/VTON deps in app |
| Catalog integrations | PLANNED | Phase 8 | Seed is fictional; no scraping |
| FastAPI layer | PLANNED | Architecture doc | Repository seam ready |
| CI (`flutter.yml`) | IMPLEMENTED | `.github/workflows/flutter.yml` | Awaiting first green run after push |
