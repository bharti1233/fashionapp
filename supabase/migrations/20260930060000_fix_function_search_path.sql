-- Fix trigger functions broken by empty search_path hardening.
--
-- Root cause: the earlier hardening migration added `SET search_path TO ''`
-- to these functions without schema-qualifying table references. In Postgres,
-- an empty search_path means unqualified names like `profiles` resolve to
-- nothing, so EVERY row written through them failed with:
--   ERROR 42P01: relation "profiles" does not exist
-- For handle_new_user() this aborted the auth.users INSERT, which Supabase
-- Auth surfaced as: {"code":"unexpected_failure",
--                     "message":"Database error saving new user"}.
--
-- Fix: schema-qualify all table references (public.*). The secure posture
-- (SECURITY DEFINER where needed + empty search_path) is preserved.
-- Non-destructive: CREATE OR REPLACE only, no data touched.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_product_rating()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
DECLARE
  product_id_var UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    product_id_var := OLD.product_id;
  ELSE
    product_id_var := NEW.product_id;
  END IF;
  UPDATE public.products
  SET
    rating = COALESCE((SELECT AVG(rating)::DECIMAL(2,1) FROM public.reviews WHERE product_id = product_id_var), 0),
    reviews_count = (SELECT COUNT(*) FROM public.reviews WHERE product_id = product_id_var)
  WHERE id = product_id_var;
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$function$;
