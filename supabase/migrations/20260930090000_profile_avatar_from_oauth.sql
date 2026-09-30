-- Capture OAuth provider avatars (e.g. Google picture) into profiles.
--
-- Non-destructive: CREATE OR REPLACE only. Both metadata keys are read
-- with COALESCE and the column is nullable, so email/password signups
-- (no avatar in metadata) are unaffected. No fabricated values: when
-- the provider supplies no avatar, avatar_url stays NULL.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, phone, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'phone',
    COALESCE(
      NEW.raw_user_meta_data->>'avatar_url',
      NEW.raw_user_meta_data->>'picture'
    )
  );
  RETURN NEW;
END;
$function$;
