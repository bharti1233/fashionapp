-- Fashion App Foundation migration (additive, non-destructive).
-- Run AFTER supabase_schema.sql. Run seed via supabase_sample_data.sql.
-- 1) fashion query indexes  2) coupons RLS  3) order cancel policy
-- 4) retire chat_messages (feature removed; see docs/REPOSITORY-AUDIT.md)

-- ---------- 1. Fashion indexes (products.attributes JSONB holds
-- gender/sizes/colors/material/fit/pattern/occasion/season) ----------
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_rating ON products(rating DESC);
CREATE INDEX IF NOT EXISTS idx_products_attrs ON products USING GIN (attributes);
CREATE INDEX IF NOT EXISTS idx_products_category_active
  ON products(category_id) WHERE is_active = true;

-- ---------- 2. Coupons: enable RLS, public read of active offers ----------
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read active coupons" ON coupons;
CREATE POLICY "Public read active coupons" ON coupons FOR SELECT
  USING (is_active = true);

-- ---------- 3. Orders: allow users to cancel their own pending orders ----------
DROP POLICY IF EXISTS "Users can cancel own pending orders" ON orders;
CREATE POLICY "Users can cancel own pending orders" ON orders FOR UPDATE
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id AND status IN ('pending', 'cancelled'));

-- ---------- 4. Retire realtime support chat (not in target product) ----------
DROP POLICY IF EXISTS "Users can view own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update received messages" ON chat_messages;
DROP INDEX IF EXISTS idx_chat_sender;
DROP INDEX IF EXISTS idx_chat_receiver;
DROP TABLE IF EXISTS chat_messages;

-- ---------- Storage (apply in Supabase Dashboard → Storage → Policies) ----------
-- Buckets: avatars, products, reviews (public read; write owner-only).
-- Example products policy (SELECT): bucket_id = 'products' (public).
-- Example write policy: bucket_id = 'products' AND auth.role() = 'authenticated'.
-- Never expose service_role keys to Flutter (see docs/REPOSITORY-AUDIT.md).
