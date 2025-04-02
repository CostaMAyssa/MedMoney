-- Função para criar a tabela de perfis
CREATE OR REPLACE FUNCTION create_profiles_table()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Criar tabela de perfis se não existir
  CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    cpf TEXT,
    city TEXT,
    state TEXT,
    specialty TEXT,
    bio TEXT,
    avatar_url TEXT,
    asaas_customer_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  );

  -- Adicionar coluna CPF se ela não existir
  DO $$
  BEGIN
    IF NOT EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'cpf'
    ) THEN
      ALTER TABLE public.profiles ADD COLUMN cpf TEXT;
    END IF;
  END $$;

  -- Adicionar coluna asaas_customer_id se ela não existir
  DO $$
  BEGIN
    IF NOT EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'asaas_customer_id'
    ) THEN
      ALTER TABLE public.profiles ADD COLUMN asaas_customer_id TEXT;
    END IF;
  END $$;

  -- Criar política de segurança para a tabela de perfis
  DROP POLICY IF EXISTS "Usuários podem ver seus próprios perfis" ON public.profiles;
  CREATE POLICY "Usuários podem ver seus próprios perfis"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

  DROP POLICY IF EXISTS "Usuários podem atualizar seus próprios perfis" ON public.profiles;
  CREATE POLICY "Usuários podem atualizar seus próprios perfis"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id);

  DROP POLICY IF EXISTS "Usuários podem inserir seus próprios perfis" ON public.profiles;
  CREATE POLICY "Usuários podem inserir seus próprios perfis"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

  -- Habilitar RLS na tabela
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
END;
$$;

-- Função para criar a tabela de planos
CREATE OR REPLACE FUNCTION create_plans_table()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Criar tabela de planos se não existir
  CREATE TABLE IF NOT EXISTS public.plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('monthly', 'annual')),
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    features JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  );

  -- Criar política de segurança para a tabela de planos
  DROP POLICY IF EXISTS "Todos podem ver planos" ON public.plans;
  CREATE POLICY "Todos podem ver planos"
    ON public.plans
    FOR SELECT
    USING (true);

  -- Habilitar RLS na tabela
  ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
END;
$$;

-- Função para criar a tabela de assinaturas
CREATE OR REPLACE FUNCTION create_subscriptions_table()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Criar tabela de assinaturas se não existir
  CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_name TEXT NOT NULL,
    plan_type TEXT NOT NULL CHECK (plan_type IN ('monthly', 'annual')),
    price DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'cancelled', 'pending')),
    payment_method TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    next_billing_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  );

  -- Criar política de segurança para a tabela de assinaturas
  DROP POLICY IF EXISTS "Usuários podem ver suas próprias assinaturas" ON public.subscriptions;
  CREATE POLICY "Usuários podem ver suas próprias assinaturas"
    ON public.subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

  DROP POLICY IF EXISTS "Usuários podem inserir suas próprias assinaturas" ON public.subscriptions;
  CREATE POLICY "Usuários podem inserir suas próprias assinaturas"
    ON public.subscriptions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

  DROP POLICY IF EXISTS "Usuários podem atualizar suas próprias assinaturas" ON public.subscriptions;
  CREATE POLICY "Usuários podem atualizar suas próprias assinaturas"
    ON public.subscriptions
    FOR UPDATE
    USING (auth.uid() = user_id);

  -- Habilitar RLS na tabela
  ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
END;
$$;

-- Função para criar a tabela de transações
CREATE OR REPLACE FUNCTION create_transactions_table()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Criar tabela de transações se não existir
  CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    category TEXT,
    date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  );

  -- Criar política de segurança para a tabela de transações
  DROP POLICY IF EXISTS "Usuários podem ver suas próprias transações" ON public.transactions;
  CREATE POLICY "Usuários podem ver suas próprias transações"
    ON public.transactions
    FOR SELECT
    USING (auth.uid() = user_id);

  DROP POLICY IF EXISTS "Usuários podem inserir suas próprias transações" ON public.transactions;
  CREATE POLICY "Usuários podem inserir suas próprias transações"
    ON public.transactions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

  DROP POLICY IF EXISTS "Usuários podem atualizar suas próprias transações" ON public.transactions;
  CREATE POLICY "Usuários podem atualizar suas próprias transações"
    ON public.transactions
    FOR UPDATE
    USING (auth.uid() = user_id);

  DROP POLICY IF EXISTS "Usuários podem excluir suas próprias transações" ON public.transactions;
  CREATE POLICY "Usuários podem excluir suas próprias transações"
    ON public.transactions
    FOR DELETE
    USING (auth.uid() = user_id);

  -- Habilitar RLS na tabela
  ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
END;
$$; 