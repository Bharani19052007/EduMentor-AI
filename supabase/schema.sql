-- ==============================================================================
-- EduMentor AI — Supabase Database Schema & Security Definition
-- ==============================================================================
-- This script contains safe, idempotent SQL definitions for EduMentor AI.
-- Compatible with PostgreSQL 15+ and Supabase Hosted Platform.
--
-- SAFETY GUARANTEES:
-- - NO destructive statements (NO DROP TABLE / NO TRUNCATE).
-- - Tables created with IF NOT EXISTS.
-- - Incremental column additions via ALTER TABLE ... ADD COLUMN IF NOT EXISTS.
-- - Constraints, triggers, and policies use idempotent guards.
-- - Role protection prevents privilege escalation via client metadata tampering.
-- - Row Level Security (RLS) protects student test data and private profile data.
-- ==============================================================================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. Tables & Idempotent Column Definitions
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Table: public.profiles
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name text,
  role text NOT NULL DEFAULT 'student',
  target_exam text DEFAULT 'NEET Aspirant',
  grade text DEFAULT '12th Grade',
  notifications_enabled boolean NOT NULL DEFAULT true,
  dark_mode boolean NOT NULL DEFAULT false,
  avatar_url text,
  streak_count integer NOT NULL DEFAULT 0,
  overall_rank_percentile integer NOT NULL DEFAULT 100,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Idempotent column additions for pre-existing profiles tables
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS first_name text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'student';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS target_exam text DEFAULT 'NEET Aspirant';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS grade text DEFAULT '12th Grade';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS notifications_enabled boolean NOT NULL DEFAULT true;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS dark_mode boolean NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS streak_count integer NOT NULL DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS overall_rank_percentile integer NOT NULL DEFAULT 100;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- Constraint: role check
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_role_check'
  ) THEN
    ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check CHECK (role IN ('student', 'admin'));
  END IF;
END $$;

-- Index for streak count and sorting
CREATE INDEX IF NOT EXISTS idx_profiles_streak_count ON public.profiles(streak_count DESC);

-- ------------------------------------------------------------------------------
-- Table: public.mock_tests
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.mock_tests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  category text NOT NULL,
  description text,
  duration_mins integer NOT NULL DEFAULT 180,
  is_recommended boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Idempotent column additions for pre-existing mock_tests tables
ALTER TABLE public.mock_tests ADD COLUMN IF NOT EXISTS title text;
ALTER TABLE public.mock_tests ADD COLUMN IF NOT EXISTS category text;
ALTER TABLE public.mock_tests ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE public.mock_tests ADD COLUMN IF NOT EXISTS duration_mins integer NOT NULL DEFAULT 180;
ALTER TABLE public.mock_tests ADD COLUMN IF NOT EXISTS is_recommended boolean NOT NULL DEFAULT false;
ALTER TABLE public.mock_tests ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_mock_tests_category ON public.mock_tests(category);
CREATE INDEX IF NOT EXISTS idx_mock_tests_recommended ON public.mock_tests(is_recommended);
CREATE INDEX IF NOT EXISTS idx_mock_tests_created_at ON public.mock_tests(created_at DESC);

-- ------------------------------------------------------------------------------
-- Table: public.mock_test_questions
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.mock_test_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id uuid NOT NULL REFERENCES public.mock_tests(id) ON DELETE CASCADE,
  question_text text NOT NULL,
  option_a text NOT NULL,
  option_b text NOT NULL,
  option_c text NOT NULL,
  option_d text NOT NULL,
  correct_option text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Idempotent column additions for pre-existing mock_test_questions tables
ALTER TABLE public.mock_test_questions ADD COLUMN IF NOT EXISTS test_id uuid REFERENCES public.mock_tests(id) ON DELETE CASCADE;
ALTER TABLE public.mock_test_questions ADD COLUMN IF NOT EXISTS question_text text;
ALTER TABLE public.mock_test_questions ADD COLUMN IF NOT EXISTS option_a text;
ALTER TABLE public.mock_test_questions ADD COLUMN IF NOT EXISTS option_b text;
ALTER TABLE public.mock_test_questions ADD COLUMN IF NOT EXISTS option_c text;
ALTER TABLE public.mock_test_questions ADD COLUMN IF NOT EXISTS option_d text;
ALTER TABLE public.mock_test_questions ADD COLUMN IF NOT EXISTS correct_option text;
ALTER TABLE public.mock_test_questions ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

-- Constraint: correct_option check
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'mock_test_questions_correct_option_check'
  ) THEN
    ALTER TABLE public.mock_test_questions ADD CONSTRAINT mock_test_questions_correct_option_check CHECK (correct_option IN ('A', 'B', 'C', 'D'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_mock_test_questions_test_id ON public.mock_test_questions(test_id);

-- ------------------------------------------------------------------------------
-- Table: public.test_attempts
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.test_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  test_id uuid NOT NULL REFERENCES public.mock_tests(id) ON DELETE CASCADE,
  score integer NOT NULL DEFAULT 0,
  total_questions integer NOT NULL DEFAULT 0,
  time_taken_seconds integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Idempotent column additions for pre-existing test_attempts tables
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS test_id uuid REFERENCES public.mock_tests(id) ON DELETE CASCADE;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS score integer NOT NULL DEFAULT 0;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS total_questions integer NOT NULL DEFAULT 0;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS time_taken_seconds integer NOT NULL DEFAULT 0;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_test_attempts_user_id ON public.test_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_test_attempts_test_id ON public.test_attempts(test_id);
CREATE INDEX IF NOT EXISTS idx_test_attempts_created_at ON public.test_attempts(created_at DESC);

-- ------------------------------------------------------------------------------
-- Table: public.learning_resources
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.learning_resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  category text NOT NULL,
  type text NOT NULL,
  file_size_or_duration text NOT NULL,
  file_url text NOT NULL,
  is_premium boolean NOT NULL DEFAULT false,
  target_exam text NOT NULL DEFAULT 'Both',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Idempotent column additions for pre-existing learning_resources tables
ALTER TABLE public.learning_resources ADD COLUMN IF NOT EXISTS title text;
ALTER TABLE public.learning_resources ADD COLUMN IF NOT EXISTS category text;
ALTER TABLE public.learning_resources ADD COLUMN IF NOT EXISTS type text;
ALTER TABLE public.learning_resources ADD COLUMN IF NOT EXISTS file_size_or_duration text;
ALTER TABLE public.learning_resources ADD COLUMN IF NOT EXISTS file_url text;
ALTER TABLE public.learning_resources ADD COLUMN IF NOT EXISTS is_premium boolean NOT NULL DEFAULT false;
ALTER TABLE public.learning_resources ADD COLUMN IF NOT EXISTS target_exam text NOT NULL DEFAULT 'Both';
ALTER TABLE public.learning_resources ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_learning_resources_category ON public.learning_resources(category);
CREATE INDEX IF NOT EXISTS idx_learning_resources_target_exam ON public.learning_resources(target_exam);
CREATE INDEX IF NOT EXISTS idx_learning_resources_created_at ON public.learning_resources(created_at DESC);

-- ==============================================================================
-- 2. Authorization Helper Functions
-- ==============================================================================

-- Authoritative admin check:
-- 1. Evaluates trusted auth.jwt()->'app_metadata' (server-managed claim; user-immutable).
-- 2. Queries public.profiles.role directly using SECURITY DEFINER (bypasses RLS to avoid recursion).
-- 3. NEVER trusts user-editable auth.jwt()->'user_metadata' or raw_user_meta_data.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_role text;
BEGIN
  -- 1. Check server-managed app_metadata claim in JWT (if configured via Supabase Auth Admin)
  IF (COALESCE(auth.jwt()->'app_metadata'->>'role', '') = 'admin') THEN
    RETURN true;
  END IF;

  -- 2. Fallback: Check authoritative role column in public.profiles table
  -- SECURITY DEFINER executes with owner privileges, preventing infinite RLS recursion
  SELECT p.role INTO v_role
  FROM public.profiles p
  WHERE p.id = auth.uid();

  RETURN COALESCE(v_role = 'admin', false);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;

-- ==============================================================================
-- 3. Profile Integrity & Role Escalation Protection
-- ==============================================================================

-- Trigger function: Prevents non-administrators from tampering with the role column
CREATE OR REPLACE FUNCTION public.protect_profile_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- INSERT: If a non-admin attempts to insert an admin profile, force it to 'student'
  IF TG_OP = 'INSERT' THEN
    IF NEW.role = 'admin' AND NOT (public.is_admin() OR auth.jwt()->>'role' = 'service_role') THEN
      NEW.role := 'student';
    END IF;
  -- UPDATE: If role is being modified, verify administrator or service_role privileges
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      IF NOT (public.is_admin() OR auth.jwt()->>'role' = 'service_role') THEN
        RAISE EXCEPTION 'Unauthorized: Only administrators can modify user roles.';
      END IF;
    END IF;
    NEW.updated_at := now();
  END IF;
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.protect_profile_role() FROM PUBLIC;

-- Attach role protection trigger to public.profiles
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_protect_profile_role'
  ) THEN
    CREATE TRIGGER trg_protect_profile_role
      BEFORE INSERT OR UPDATE ON public.profiles
      FOR EACH ROW
      EXECUTE FUNCTION public.protect_profile_role();
  END IF;
END $$;

-- Trigger function: Creates initial student profile on auth.users registration
-- Always forces role = 'student' regardless of any client-supplied metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    first_name,
    role,
    target_exam
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Student'),
    'student', -- Enforce student role on signup; never trust client-supplied role metadata
    COALESCE(NEW.raw_user_meta_data->>'preparation_path', 'NEET Aspirant')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC;

-- Attach signup trigger to auth.users
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_new_user();
  END IF;
END $$;

-- Dedicated administrative function to update user roles
CREATE OR REPLACE FUNCTION public.set_user_role(p_user_id uuid, p_role text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Strict administrative check
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied. Administrator privileges required.';
  END IF;

  IF p_role NOT IN ('student', 'admin') THEN
    RAISE EXCEPTION 'Invalid role. Allowed values: student, admin.';
  END IF;

  UPDATE public.profiles
  SET role = p_role, updated_at = now()
  WHERE id = p_user_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_user_role(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_user_role(uuid, text) TO authenticated;

-- ==============================================================================
-- 4. Row Level Security (RLS) Policies
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mock_test_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_resources ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- RLS: public.profiles
-- ------------------------------------------------------------------------------

-- SELECT: Students can view their own profile; administrators can view all profiles
DO $$ BEGIN
  DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Users can view own profile or admins view all" ON public.profiles;
  CREATE POLICY "Users can view own profile or admins view all"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id OR public.is_admin());
END $$;

-- INSERT: Students can insert their own initial profile (role restricted to 'student' unless admin)
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
  CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id AND (role = 'student' OR public.is_admin()));
END $$;

-- UPDATE: Students can update their own profile; administrators can update any profile
-- (Note: role column tampering is independently guarded by trg_protect_profile_role)
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Users and admins can update profiles" ON public.profiles;
  CREATE POLICY "Users and admins can update profiles"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id OR public.is_admin())
    WITH CHECK (auth.uid() = id OR public.is_admin());
END $$;

-- DELETE: Users can delete their own profile; administrators can delete any profile
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users and admins can delete profiles" ON public.profiles;
  CREATE POLICY "Users and admins can delete profiles"
    ON public.profiles FOR DELETE
    TO authenticated
    USING (auth.uid() = id OR public.is_admin());
END $$;

-- ------------------------------------------------------------------------------
-- RLS: public.mock_tests
-- ------------------------------------------------------------------------------

-- SELECT: Authenticated users can view all mock tests
DO $$ BEGIN
  DROP POLICY IF EXISTS "Authenticated users can view mock tests" ON public.mock_tests;
  CREATE POLICY "Authenticated users can view mock tests"
    ON public.mock_tests FOR SELECT
    TO authenticated
    USING (true);
END $$;

-- INSERT: Only admins can insert mock tests
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can insert mock tests" ON public.mock_tests;
  CREATE POLICY "Admins can insert mock tests"
    ON public.mock_tests FOR INSERT
    TO authenticated
    WITH CHECK (public.is_admin());
END $$;

-- UPDATE: Only admins can update mock tests
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can update mock tests" ON public.mock_tests;
  CREATE POLICY "Admins can update mock tests"
    ON public.mock_tests FOR UPDATE
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());
END $$;

-- DELETE: Only admins can delete mock tests
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can delete mock tests" ON public.mock_tests;
  CREATE POLICY "Admins can delete mock tests"
    ON public.mock_tests FOR DELETE
    TO authenticated
    USING (public.is_admin());
END $$;

-- ------------------------------------------------------------------------------
-- RLS: public.mock_test_questions
-- ------------------------------------------------------------------------------

-- SELECT: Authenticated users can view test questions
DO $$ BEGIN
  DROP POLICY IF EXISTS "Authenticated users can view test questions" ON public.mock_test_questions;
  CREATE POLICY "Authenticated users can view test questions"
    ON public.mock_test_questions FOR SELECT
    TO authenticated
    USING (true);
END $$;

-- INSERT: Only admins can insert questions
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can insert test questions" ON public.mock_test_questions;
  CREATE POLICY "Admins can insert test questions"
    ON public.mock_test_questions FOR INSERT
    TO authenticated
    WITH CHECK (public.is_admin());
END $$;

-- UPDATE: Only admins can update questions
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can update test questions" ON public.mock_test_questions;
  CREATE POLICY "Admins can update test questions"
    ON public.mock_test_questions FOR UPDATE
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());
END $$;

-- DELETE: Only admins can delete questions
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can delete test questions" ON public.mock_test_questions;
  CREATE POLICY "Admins can delete test questions"
    ON public.mock_test_questions FOR DELETE
    TO authenticated
    USING (public.is_admin());
END $$;

-- ------------------------------------------------------------------------------
-- RLS: public.test_attempts
-- ------------------------------------------------------------------------------

-- SELECT: Users can only view their own test attempts; administrators can view all attempts
-- Prevents unauthorized disclosure of individual student exam history
DO $$ BEGIN
  DROP POLICY IF EXISTS "Authenticated users can view test attempts" ON public.test_attempts;
  DROP POLICY IF EXISTS "Users and admins can view relevant test attempts" ON public.test_attempts;
  CREATE POLICY "Users and admins can view relevant test attempts"
    ON public.test_attempts FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());
END $$;

-- INSERT: Authenticated users can only record their own test attempts
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can insert their own test attempts" ON public.test_attempts;
  CREATE POLICY "Users can insert their own test attempts"
    ON public.test_attempts FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
END $$;

-- DELETE: Only administrators can delete test attempts
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can delete test attempts" ON public.test_attempts;
  CREATE POLICY "Admins can delete test attempts"
    ON public.test_attempts FOR DELETE
    TO authenticated
    USING (public.is_admin());
END $$;

-- ------------------------------------------------------------------------------
-- RLS: public.learning_resources
-- ------------------------------------------------------------------------------

-- SELECT: Authenticated users can view all learning resources
DO $$ BEGIN
  DROP POLICY IF EXISTS "Authenticated users can view resources" ON public.learning_resources;
  CREATE POLICY "Authenticated users can view resources"
    ON public.learning_resources FOR SELECT
    TO authenticated
    USING (true);
END $$;

-- INSERT: Only admins can insert resources
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can insert resources" ON public.learning_resources;
  CREATE POLICY "Admins can insert resources"
    ON public.learning_resources FOR INSERT
    TO authenticated
    WITH CHECK (public.is_admin());
END $$;

-- UPDATE: Only admins can update resources
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can update resources" ON public.learning_resources;
  CREATE POLICY "Admins can update resources"
    ON public.learning_resources FOR UPDATE
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());
END $$;

-- DELETE: Only admins can delete resources
DO $$ BEGIN
  DROP POLICY IF EXISTS "Admins can delete resources" ON public.learning_resources;
  CREATE POLICY "Admins can delete resources"
    ON public.learning_resources FOR DELETE
    TO authenticated
    USING (public.is_admin());
END $$;

-- ==============================================================================
-- 5. Remote Procedure Call (RPC) Functions
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- RPC: get_student_count
-- Called by: AdminService.getDashboardStats()
-- Hardened: Requires admin privileges, fixed search path, revoked public execute
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_student_count()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Strict administrative authorization check
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied. Administrator privileges required.';
  END IF;

  RETURN (
    SELECT count(*)::integer
    FROM public.profiles
    WHERE role = 'student' OR role IS NULL
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_student_count() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_count() TO authenticated;

-- ------------------------------------------------------------------------------
-- RPC: get_all_users
-- Called by: AdminService.getUsers()
-- Hardened: Requires admin privileges, fixed search path, role metadata decoupling
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_all_users()
RETURNS TABLE (
  id uuid,
  email text,
  name text,
  role text,
  preparation_path text,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Strict administrative authorization check
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied. Administrator privileges required.';
  END IF;

  RETURN QUERY
  SELECT 
    u.id,
    u.email::text,
    COALESCE(p.first_name, (u.raw_user_meta_data->>'name')::text, 'Student')::text AS name,
    COALESCE(p.role, 'student')::text AS role,
    COALESCE(p.target_exam, (u.raw_user_meta_data->>'preparation_path')::text, 'NEET Aspirant')::text AS preparation_path,
    u.created_at
  FROM auth.users u
  LEFT JOIN public.profiles p ON u.id = p.id
  ORDER BY u.created_at DESC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_all_users() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_all_users() TO authenticated;

-- ------------------------------------------------------------------------------
-- RPC: get_test_analytics
-- Called by: AdminService.getTestAnalytics(testId)
-- Hardened: Requires admin privileges, fixed search path, revoked public execute
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_test_analytics(p_test_id uuid)
RETURNS TABLE (
  student_name text,
  student_email text,
  score integer,
  total_questions integer,
  time_taken_seconds integer,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Strict administrative authorization check
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied. Administrator privileges required.';
  END IF;

  RETURN QUERY
  SELECT 
    COALESCE(p.first_name, (u.raw_user_meta_data->>'name')::text, 'Student')::text AS student_name,
    u.email::text AS student_email,
    ta.score,
    ta.total_questions,
    ta.time_taken_seconds,
    ta.created_at
  FROM public.test_attempts ta
  JOIN auth.users u ON ta.user_id = u.id
  LEFT JOIN public.profiles p ON ta.user_id = p.id
  WHERE ta.test_id = p_test_id
  ORDER BY ta.score DESC, ta.time_taken_seconds ASC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_test_analytics(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_test_analytics(uuid) TO authenticated;

-- ------------------------------------------------------------------------------
-- RPC: get_leaderboard
-- Called by: DashboardService.getLeaderboard()
-- Purpose: Aggregates student test scores securely on the server without exposing
--          individual test attempt rows, timestamps, or private profile preferences.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_leaderboard()
RETURNS TABLE (
  user_id uuid,
  name text,
  avatar_url text,
  score bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT 
    ta.user_id,
    COALESCE(p.first_name, 'User')::text AS name,
    COALESCE(p.avatar_url, '')::text AS avatar_url,
    COALESCE(SUM(ta.score), 0)::bigint AS score
  FROM public.test_attempts ta
  LEFT JOIN public.profiles p ON ta.user_id = p.id
  GROUP BY ta.user_id, p.first_name, p.avatar_url
  ORDER BY score DESC;
$$;

REVOKE EXECUTE ON FUNCTION public.get_leaderboard() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_leaderboard() TO authenticated;

-- ==============================================================================
-- 6. Storage Buckets & Policies
-- ==============================================================================
-- Buckets:
--   1. 'avatars'   (Public read; authenticated users manage their own {userId}/* folder)
--   2. 'resources' (Public read; only administrators can upload/update/delete materials)

-- Ensure storage buckets exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('resources', 'resources', true)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- Storage: avatars
-- ------------------------------------------------------------------------------

-- Avatars: Public read access
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Public Access for Avatars') THEN
    CREATE POLICY "Public Access for Avatars"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'avatars');
  END IF;
END $$;

-- Avatars: Authenticated users can upload to their own folder ({userId}/*)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can upload own avatar') THEN
    CREATE POLICY "Users can upload own avatar"
      ON storage.objects FOR INSERT
      TO authenticated
      WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
  END IF;
END $$;

-- Avatars: Authenticated users can update/overwrite their own avatar
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can update own avatar') THEN
    CREATE POLICY "Users can update own avatar"
      ON storage.objects FOR UPDATE
      TO authenticated
      USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text)
      WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
  END IF;
END $$;

-- Avatars: Authenticated users can delete their own avatar
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can delete own avatar') THEN
    CREATE POLICY "Users can delete own avatar"
      ON storage.objects FOR DELETE
      TO authenticated
      USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
  END IF;
END $$;

-- ------------------------------------------------------------------------------
-- Storage: resources
-- ------------------------------------------------------------------------------

-- Resources: Public read access
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Public Access for Learning Resources') THEN
    CREATE POLICY "Public Access for Learning Resources"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'resources');
  END IF;
END $$;

-- Resources: Only admins can upload learning resources
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Admins can upload learning resources') THEN
    CREATE POLICY "Admins can upload learning resources"
      ON storage.objects FOR INSERT
      TO authenticated
      WITH CHECK (bucket_id = 'resources' AND public.is_admin());
  END IF;
END $$;

-- Resources: Only admins can update learning resources
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Admins can update learning resources') THEN
    CREATE POLICY "Admins can update learning resources"
      ON storage.objects FOR UPDATE
      TO authenticated
      USING (bucket_id = 'resources' AND public.is_admin())
      WITH CHECK (bucket_id = 'resources' AND public.is_admin());
  END IF;
END $$;

-- Resources: Only admins can delete learning resources
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Admins can delete learning resources') THEN
    CREATE POLICY "Admins can delete learning resources"
      ON storage.objects FOR DELETE
      TO authenticated
      USING (bucket_id = 'resources' AND public.is_admin());
  END IF;
END $$;
