# PLACEHOLDER EXECUTION MAP — actual runtime paths

Legend: [REAL] backend-backed · [FAKE] fabricated UI · [DEAD] exists but
unreached · [MISSING] no implementation · [SIM] simulated success.

## Bottom navigation (all reachable)

- Home tab → `HomeView` → `ProductsCubit.getProducts` → Supabase `products`
  [REAL]; `PromoBannerCarouselSlider` → `BannersCubit` → Supabase `banners`
  with static fallback [REAL + fallback]
- Store tab → `StoreView` → `CategoryTab` → fabricated `ProductEntity`
  list [FAKE] (real `Categories`/`Products` cubits never read)
- Wishlist tab → `WishlistView` → fabricated list [FAKE]
  (`WishlistCubit`→Supabase `wishlist` exists [DEAD])
- Cart tab → `CartView` → `CartItemsList` → static `CartItem` + "175"
  [FAKE] (`CartCubit`→Supabase `cart_items` exists [DEAD])
- Settings tab → `SettingsView` [REAL shell] → Profile [FAKE constants];
  App Logs [REAL]; Logout [REAL]

## Auth

- Register → `AuthCubit.signUp` → `SignUpUsecase` → `AuthRepositoryImpl`
  → `SupabaseService.signUp` → GoTrue → trigger → `profiles` [REAL,
  trigger fixed]; Verify-email Continue [SIM], Resend [MISSING]
- Login → `AuthCubit.signIn` → Supabase [REAL]
- Google/Facebook buttons → cubit → repo → `signInWithOAuth` + deep link
  [REAL app-side; dashboard provider config UNKNOWN]
- Forgot → navigates only [MISSING send]; Reset view buttons [MISSING]
- Session restore: `checkAuthStatus` [DEAD — zero callers]; no
  `onAuthStateChange` listener [MISSING]
- Logout → `signOut` → Supabase [REAL]

## Commerce

- Product details (from Home) [REAL data]; brand view header hardcoded
  "Nike" + real `SortableProducts` below [FAKE header + REAL list];
  all-products/sort/search-use-case [REAL]
- Checkout → `SuccessView("Payment Successful")` [SIM]; no order insert
  (real `OrdersCubit.createOrder` [DEAD]), no payment SDK [MISSING]
- Orders history → 6× static cards [FAKE] (`OrdersCubit` [DEAD])
- Reviews display/submit [FAKE static count + DEAD cubit]
- Coupons table+rows exist; app usage [MISSING]
- Notifications backend, zero UI [DEAD]
- Addresses: form→`AddressesCubit`→Supabase [REAL]; list view contains
  hardcoded phones [FAKE constants]; profile repo avatar upload [DEAD UI]

## DI (production): 100% real `*RepositoryImpl`; zero Mock/Fake/Demo/Test
## registrations. Test mocks isolated under `test/` (mocktail), never
## imported by `lib/`.
