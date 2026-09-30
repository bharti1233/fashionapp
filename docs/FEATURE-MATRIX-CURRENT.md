# Current Feature Matrix (actual `TStore/` state)

Status values: REAL = backend-backed runtime path · PARTIAL = works with
known gaps · FALLBACK = real data with documented static fallback ·
SEED DATA = intentional fictional Phase 1 catalog · NOT IMPLEMENTED =
honestly gated, no fake behavior · PLANNED = future work, no code.

| Feature | Current Status | Source | Notes |
|---|---|---|---|
| Home / banners | REAL + FALLBACK | `home_view.dart`, `promo_banner_carousel_slider.dart` | Supabase banners; static images only when DB empty |
| Categories / brands | REAL | `categories_cubit.dart`, `brands_cubit.dart`, `home_categories.dart` | Live categories drive home rail + store tabs; icons fall back to bundled assets |
| Search / filter / sort | REAL | `products_cubit.dart`, `sortable_products.dart` | Variants from `attributes` JSONB |
| Product listing | REAL | `store_view.dart`, `all_products_view.dart`, `sub_category_view.dart` | Real rows; honest empty states; no fabricated cards |
| Product details | REAL | `product_details_view.dart` + sections | Real price/stock/brand/description/attributes/images; variant selection flows into cart |
| Wishlist | REAL | `wishlist_view.dart` → `WishlistCubit` | Loading/empty/error/retry; remove + toggle wired |
| Cart | REAL | `cart_view.dart` → `CartCubit` | Real lines, quantities, subtotal/total in ₹ |
| Checkout / orders | REAL (COD only) | `checkout_view.dart` → `OrdersCubit` | Real pending orders; coupon validated live; online payment NOT IMPLEMENTED (stated in UI) |
| Orders / history / cancel | REAL | `orders_view.dart` → `OrdersCubit` | Cancel where backend allows; empty state |
| Addresses / profile | REAL | `user_addresses_view.dart`, `profile_view.dart` | Real rows; honest empty states; delete-account honestly gated |
| Reviews / ratings | REAL | `product_reviews_view.dart` → `ReviewsCubit` | Real list/count/average; submit form NOT IMPLEMENTED |
| Coupons | REAL | `validate_coupon_usecase.dart` → live `coupons` | Active-only public read; expiry/min/cap rules enforced |
| Notifications | NOT IMPLEMENTED | `features/notifications` (backend only) | No UI; backend retained, nothing fabricated |
| Auth / onboarding / session | REAL | `features/auth`, `on_boarding_view.dart` | Register/login/logout/restore/verify/forgot/reset all wired; Google/Facebook need dashboard provider enablement |
| Product images | SEED DATA | Live `products.thumbnail` | Fictional picsum-seed catalog; Storage buckets exist for merchant assets |
| Support chat | REMOVED | (deleted) | Not in target product |
| Wardrobe / outfit / stylist | PLANNED | Phase 2–4 | Extension points documented, no code |
| Photo / live try-on / mirror | PLANNED | Phase 5–7 | No AI/VTON deps in app |
| Catalog integrations | PLANNED | Phase 8 | Seed is fictional; no scraping |
| FastAPI layer | PLANNED | Architecture doc | Repository seam ready |
| CI (`flutter.yml`) | REAL | `.github/workflows/flutter.yml` | Format → validate → analyze → tests → release APK |
