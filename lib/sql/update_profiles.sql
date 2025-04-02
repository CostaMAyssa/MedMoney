-- Script para atualizar a tabela de perfis no Supabase
-- Adiciona campos CPF e asaas_customer_id se não existirem

-- Adicionar coluna CPF se ela não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'cpf'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN cpf TEXT;
    RAISE NOTICE 'Coluna CPF adicionada com sucesso';
  ELSE
    RAISE NOTICE 'Coluna CPF já existe';
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
    RAISE NOTICE 'Coluna asaas_customer_id adicionada com sucesso';
  ELSE
    RAISE NOTICE 'Coluna asaas_customer_id já existe';
  END IF;
END $$;

-- Atualizar perfis existentes para adicionar mensagem padrão
UPDATE public.profiles
SET cpf = 'CPF não informado'
WHERE cpf IS NULL OR cpf = '';

UPDATE public.profiles
SET phone = 'Telefone não informado'
WHERE phone IS NULL OR phone = '';

-- Verificar as colunas na tabela
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles'; 