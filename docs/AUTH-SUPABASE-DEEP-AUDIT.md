# AUTH–SUPABASE DEEP AUDIT

Date: 2026-09-30. Method: source inspection + live database queries
(`information_schema`, `pg_proc`/`pg_get_functiondef`, `pg_policies`,
`storage.buckets`) via Supabase MCP. No secrets printed anywhere.

## 1. Architecture map

```
SignUpView / LoginView (BlocListener on AuthCubit)
  → SignInMethodsSection (Google/Facebook buttons)
  → AuthCubit (signUp/signIn/signOut/resetPassword/checkAuthStatus,
               + NEW signInWithGoogle/signInWithFacebook)
  → UseCases (SignUpUsecase, …, + NEW SignInWithGoogle/FacebookUsecase)
  → AuthRepositoryImpl (Either<String, T>; friendly UI strings)
  → SupabaseService (thin client wrapper, now lifecycle-logged)
  → Supabase Auth (GoTrue) / PostgREST
  → Postgres: auth.users --trigger--> public.profiles (handle_new_user)
```

DI: `setupServiceLocator()` lazy singletons, AuthCubit factory. No
GoRouter — `home: OnBoardingView()` directly; login/signup views navigate
via BlocListener states. No `authStateChanges` UI listener exists
(session screens rely on explicit states, not the stream).

## 2. Email/password flow

Create Account → validation → `AuthCubit.signUp` → `SignUpUsecase` →
`AuthRepositoryImpl.signUp` → `SupabaseService.signUp` →
`client.auth.signUp(email, password, data:{full_name, phone})` →
GoTrue inserts `auth.users` → trigger `on_auth_user_created` fires →
`handle_new_user()` inserts `public.profiles` → response user returned →
`AuthEmailConfirmationRequired(email)` → verify-email view.

The exact catch converting the failure to the red snackbar:
`AuthRepositoryImpl.signUp` → `on AuthException` → `Left(friendly)` →
`AuthCubit` emits `AuthError` → view snackbar. The exception object and
stack died there (now logged at every layer).

## 3. Google OAuth flow

App uses `signInWithOAuth` (NOT `signInWithIdToken`) with
`redirectTo: io.supabase.tstore://login-callback/` and PKCE flow.
`supabase_flutter` (with bundled `app_links`) handles the return —
provided the OS can route the deep link back into the app.

## 4. Supabase Auth configuration (dashboard — verify by operator)

Provider enablement / client IDs / secrets / Site URL / redirect
allowlist are GoTrue settings, not visible over SQL. See matrix (§14).

## 5. Database schema (live, abridged to auth-relevant)

`public.profiles`: id uuid PK → `auth.users.id` (FK),
email text NOT NULL UNIQUE, full_name/phone/avatar_url nullable,
created_at/updated_at defaults now(). Rows: 0.
User tables (`addresses`, `wishlist`, `cart_items`, `orders`,
`order_items`, `reviews`, `notifications`) all key users via
`user_id → auth.users.id` (nullable). Catalog tables
(products 76 rows, categories 6, brands 6, banners 5, coupons 3)
populated. `UserModel.fromJson` fields match `profiles` columns 1:1.

## 6. Triggers

`auth.users → on_auth_user_created (AFTER INSERT) → handle_new_user()`.
Plus `update_*_updated_at` (BEFORE UPDATE, benign) and review-rating
triggers (same disease as below, fixed together).

## 7. Functions (ROOT CAUSE — proven live)

`public.handle_new_user()` is `SECURITY DEFINER` with
`SET search_path TO ''` but referenced **unqualified** `profiles`.
Proof (read-only, zero writes): with empty search_path,
`EXPLAIN INSERT INTO profiles …` fails with
`ERROR 42P01: relation "profiles" does not exist` — the exact failure
the trigger hits on every signup, aborting the `auth.users` INSERT,
which GoTrue reports as `unexpected_failure / Database error saving
new user`. NOT an RLS problem (DEFINER bypasses RLS; policies are
correct: insert own profile `WITH CHECK (auth.uid() = id)`).
`update_product_rating()` had the identical defect (unqualified
`products`/`reviews`) — review writes would fail the same way.

## 8. RLS policies

profiles: SELECT/UPDATE own (`auth.uid() = id`), INSERT own with check.
addresses/orders: owner-only (`auth.uid() = user_id`). Correct and
untouched. No global disable, no `USING (true)`.

## 9. Storage

Buckets live: avatars, banner-images, brand-logos, category-images,
product-images, review-images — all public, matching `SupabaseConfig`
names exactly. No mismatch.

## 10. Repository migrations

Repo previously had NO version-controlled migrations (live schema was
built outside the repo). Added:
`supabase/migrations/20260930060000_fix_function_search_path.sql`
(same SQL applied live). Past migrations listed live:
tstore_base_tables, tstore_indexes_rls, tstore_functions_triggers,
fashion_foundation, storage_image_policies, harden_functions
(the hardening migration introduced the defect).

## 11. Live database differences

Only the two function bodies changed (schema-qualified references).
No tables/columns/policies/data touched.

## 12. Flutter/Supabase mismatches (all addressed)

- Trigger search_path bug → fixed live + migration file.
- OAuth buttons dead (`onPressed: () {}`), no cubit path → wired
  Google/Facebook buttons → new use cases → cubit → repo (all logged).
- Missing Android deep-link intent-filter → added
  (`io.supabase.tstore` / `login-callback`).
- No other table/column/type mismatches found on auth/profile paths.

## 13. Root cause of signup failure

`handle_new_user()` + empty `search_path` + unqualified `profiles`
→ 42P01 on every signup → GoTrue `unexpected_failure`.
Responsible object: FUNCTION `public.handle_new_user()` (trigger
`on_auth_user_created`). Fixed and verified (definition re-read;
EXPLAIN plans under empty search_path).

## 14. Google OAuth matrix

| Item | Flutter | Supabase | Google | Android |
|---|---|---|---|---|
| Provider enabled | n/a (client) | UNKNOWN — verify in Dashboard → Auth → Providers | UNKNOWN — needs OAuth client + consent | n/a |
| Redirect URI `io.supabase.tstore://login-callback/` | CORRECT (redirectTo) | UNKNOWN — must be in Auth → URL Configuration → Redirect URLs | n/a (custom scheme) | FIXED (intent-filter added) |
| Application ID | n/a | n/a | must match consent-screen package if Android client used | CORRECT (`com.fashionapp.store`, `.dev` suffix dev) |
| Session handling | CORRECT (PKCE + checkAuthStatus after launch) | n/a | n/a | CORRECT after fix |
| Buttons | FIXED (were dead) | n/a | n/a | n/a |

Operator actions (dashboard, cannot be done from repo):
1. Enable Google provider with Client ID/Secret.
2. Add `io.supabase.tstore://login-callback/` to Redirect URLs.
Facebook/Apple buttons: kept (not removed per constraints); Facebook
wired identically, needs provider enablement too.

## 15. Logging gaps (closed)

Previously: repo/cubit catch boundaries never logged. Now: service
guard (START/SUCCESS/FAILURE) → repo technical error + stack →
cubit operation error; snackbar text unchanged (friendly).
Global `AppBlocObserver` safety net in both mains. Full sequence for
signup failure is now in App Logs with COPY LOG; secrets redacted
(passwords/tokens never passed as log arguments).

## 16. Remediation plan (status)

1. ✅ Fix trigger functions (live + migration file).
2. ✅ Wire OAuth buttons + cubit + use cases + DI.
3. ✅ Add Android OAuth intent-filter.
4. ✅ Logging integration (service/repo/cubit/observer) + tests.
5. ⏳ Operator: Supabase dashboard provider + redirect URLs.
6. ⏳ Device: install new artifact, test signup + Google + App Logs.
