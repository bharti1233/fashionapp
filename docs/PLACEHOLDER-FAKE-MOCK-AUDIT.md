# PLACEHOLDER / FAKE / MOCK / STUB / DEMO FORENSIC AUDIT

Date: 2026-09-30. Scope: entire `TStore/` Flutter repo + live Supabase
project (via MCP inspection). Method: keyword sweeps, DI trace, per-screen
runtime-path tracing (UI → cubit → use case → repository → Supabase),
live schema/data/object-name inspection. No fixes applied. No secrets printed.

Severity: CRITICAL = fake reachable from production flow appearing real.
HIGH = backend/config gap that breaks production. MEDIUM = incomplete.
LOW = cosmetic. INFO = intentional/test/docs-only.

## CRITICAL — fake UI reachable from production flows

| File | Line/area | Feature | Finding | Actual behavior | Expected behavior | Production reachable? | Severity | Recommended action |
|---|---|---|---|---|---|---|---|---|
| `lib/features/shop/presentation/views/wishlist_view.dart` | 53–68 | Wishlist tab | Entire list fabricated: `Product $index`, price 100, picsum image, fake ids/brands | Bottom-nav Wishlist tab shows 10 fake cards; real `WishlistCubit`/repo exist but are never read here | Bind to `WishlistCubit` + Supabase wishlist rows | YES (bottom nav) | CRITICAL | Rebind to real cubit; delete fabrication |
| `lib/core/common/widgets/category_tab.dart` | 44–62 | Store tab | Same fabrication (`Product $index`, price 100, picsum) driven by `categoryTabModel.products` | Store tab category content is fake regardless of backend | Bind categories/products to `CategoriesCubit`/`ProductsCubit` | YES (bottom nav → Store) | CRITICAL | Rebind to real cubits |
| `lib/features/shop/presentation/widgets/cart_items_list.dart` | 14–35 | Cart tab | Static `CartItem()` + hardcoded price `"175"`; no cubit read | Cart tab never shows the user's real cart; real `CartCubit` unwired | Bind to `CartCubit` | YES (bottom nav) | CRITICAL | Rebind to real cubit |
| `lib/features/shop/presentation/views/checkout_view.dart` | 28–50 | Checkout | `Checkout $175` button navigates straight to `SuccessView("Payment Successful")`; no order insert, no payment SDK | Fake payment success; zero records created | Create order via `OrdersCubit`, then real payment step or explicit NOT-IMPLEMENTED gate | YES | CRITICAL | Implement or gate; never show success without a transaction |
| `lib/features/shop/presentation/widgets/orders_list.dart` | 15 | Orders | `itemCount: 6` × `const OrderListItem()` | Order history is 6 static cards; real `OrdersCubit` unwired | Bind to `OrdersCubit` | YES (via orders view) | CRITICAL | Rebind to real cubit |
| `lib/features/personalization/presentation/views/profile_view.dart` | 17–30 | Profile | Hardcoded identity: "John Doe", "Elashwah Hamdi" (original author), ID "21-02064", `hmdy7486@gmail.com`, `+201019793768` (Egypt) | Settings → Profile shows someone else's data for every user | Bind to session + `ProfileCubit` | YES (Settings) | CRITICAL | Rebind; purge PII-looking constants |
| `lib/features/auth/presentation/views/signup/verify_email_view.dart` | 64–79 | Email verification | Continue navigates to success with no OTP check; Resend `onPressed: {}` | Verification faked; resend dead | Verify via session/OTP state; wire resend to `resendConfirmation` | YES (post-signup) | CRITICAL | Implement real verification gate |
| `lib/features/personalization/presentation/views/user_addresses_view.dart` | 46, 54 | Addresses | `phoneNumber: "0123456789"` twice | Placeholder numbers in address UI | Bind to `AddressesCubit` rows | YES | CRITICAL | Rebind |
| `lib/features/shop/presentation/widgets/billing_address_section.dart` | 28 | Checkout address | `"+20-123456789"` (Egypt code; app is India-first) | Wrong-region placeholder shown at checkout | Bind to selected address | YES | CRITICAL | Rebind |

## HIGH — broken backend/config paths

| File / area | Finding | Severity | Recommended action |
|---|---|---|---|
| Forgot → reset password flow (`forget_password_form_section.dart:25`, `reset_password_view.dart:57,65`) | Forgot navigates without sending reset email; reset buttons dead | HIGH | Wire `resetPasswordUsecase` + confirmation states |
| Session restoration | `checkAuthStatus()` has zero UI callers; no `onAuthStateChange` listener in UI | HIGH | Call on startup when session exists; route accordingly |
| Google/Facebook provider config (Supabase dashboard) | App side now wired + deep link added; provider enablement, client IDs, redirect allowlist unverifiable over SQL | HIGH | Operator: enable providers, allowlist `io.supabase.tstore://login-callback/` |
| `product_reviews_view.dart:34` + unwired `ReviewsCubit` | Hardcoded `"12,611"` count; submit path has no UI consumers | HIGH | Bind list + submit to cubit or gate |
| Notifications | Full backend (repo/cubit/table) but zero UI files | HIGH | Add UI or officially descope |
| Coupons | Live table + 3 rows; zero app usage (only `coupon_code` field passthrough) | HIGH | Implement or descope |
| Product images | DB `thumbnail` values are `picsum.photos/seed/…`; Supabase buckets exist but hold no product images; only `avatars` bucket is used in code | HIGH | Upload catalog to Storage buckets; update URLs |

## MEDIUM — incomplete but non-deceptive

| File / area | Finding | Severity |
|---|---|---|
| `promo_banner_carousel_slider.dart:31-37` | Real `BannersCubit` with static `TImages.promoBannerImages` fallback when DB empty | MEDIUM (legitimate fallback; document) |
| Avatar update | `uploadAvatar` repo method exists; no UI caller found | MEDIUM |
| Apple sign-in | Repo method exists; no UI button (acceptable; note as unsupported) | MEDIUM |
| `sign_in_methods` Facebook | Wired to cubit; provider enablement unverified | MEDIUM |

## LOW / INFO — benign or intentional

| Area | Finding | Severity |
|---|---|---|
| `device_utility.dart:98` `InternetAddress.lookup('example.com')` | Standard connectivity check, no data involved | INFO (benign) |
| `android/app/build.gradle:23` TODO comment | Boilerplate; applicationId already set (`com.fashionapp.store`) | INFO |
| Package name `t_store`, `TImages` demo assets, onboarding static pages | Leftover branding / intentional static content | INFO |
| Live seed catalog (76 products, 6 categories/brands, 5 banners, 3 coupons) | Coherent fictional fashion data = intentional Phase 1 seed, NOT a bug | INFO |
| `test/` mocks (mocktail) | Test-only, never imported by `lib/` | INFO (safe) |
| Shimmer `placeholder:` in `rounded_image.dart` | Legitimate image loading state | INFO |
| `cart_cubit orElse: throw` | Legitimate local error propagation | INFO |
| Docs (`FEATURE-MATRIX`, `PHASE-1-FOUNDATION`, etc.) claim wishlist/cart/checkout/orders/profile/reviews/notifications "IMPLEMENTED" and reference nonexistent `supabase_fashion_migration.sql` | FALSE/PARTIALLY TRUE — backends exist, UIs disconnected or fake | HIGH (docs) — rewrite after UI fixes |

## Supabase live objects

- No test/demo/mock/dummy/sample/temp objects (tables, functions, buckets): **none found**.
- `auth.users` rows not counted (auth schema not enumerated — PII safe).
- User tables (`profiles`, `addresses`, `wishlist`, `cart_items`, `orders`, `reviews`, `notifications`): 0 rows — no fake user data server-side. Clean.
- Functions/triggers audited separately (`AUTH-SUPABASE-DEEP-AUDIT.md`): no hardcoded IDs/emails/URLs, no static-JSON stubs, no exception swallowing (trigger failure correctly aborts — that WAS the surfaced signup error, now fixed).
- Auth provider enablement: NOT verifiable over SQL — UNKNOWN, see OAuth matrix in deep-audit doc.

## Classification summary

- Intentional Phase 1 placeholders: seed catalog, onboarding, banner fallback, shimmer states.
- Accidental production placeholders: all CRITICAL rows above (inherited TStore demo UI never rebound after the Supabase backend was built).
- Fake reachable from production: wishlist/store/cart/orders/profile/checkout/verify-email/address UI.
- Mocks in production DI: **none** — `service_locator.dart` resolves 100% real `*RepositoryImpl` (verified file-wide). Auth is real Supabase Auth; no fake sessions/tokens/bypass found anywhere.
- Network: zero `localhost`/`127.0.0.1`/DummyJSON/JSONPlaceholder references in `lib/` or Android config. Production calls Supabase only.

AWAITING APPROVAL before any cleanup/replacement.
