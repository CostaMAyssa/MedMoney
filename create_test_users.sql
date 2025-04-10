-- Script para criar usuários de teste no Supabase

-- NOTA: Primeiro, você precisa criar os usuários manualmente no Supabase Admin ou pela API
-- Este script assume que você já criou os usuários:
-- 1. teste.essencial@medmoney.me (senha: Teste@123)
-- 2. teste.premium@medmoney.me (senha: Teste@123)

-- Obter os IDs dos usuários (execute esta consulta primeiro para obter os IDs)
SELECT id FROM auth.users WHERE email = 'teste.essencial@medmoney.me';
SELECT id FROM auth.users WHERE email = 'teste.premium@medmoney.me';

-- Inserir perfis para os usuários
-- IMPORTANTE: Após executar as consultas acima, substitua os UUIDs abaixo pelos IDs reais obtidos
INSERT INTO profiles (id, name, email, phone, city, state, cpf_cnpj)
VALUES 
  ('UUID_DO_USUARIO_ESSENCIAL', 'Usuário Teste Essencial', 'teste.essencial@medmoney.me', '11999998888', 'São Paulo', 'SP', '123.456.789-00');

INSERT INTO profiles (id, name, email, phone, city, state, cpf_cnpj)
VALUES 
  ('UUID_DO_USUARIO_PREMIUM', 'Usuário Teste Premium', 'teste.premium@medmoney.me', '11977776666', 'São Paulo', 'SP', '987.654.321-00');

-- Obter IDs dos planos (execute esta consulta para obter os IDs dos planos)
SELECT id, name FROM plans WHERE LOWER(name) IN ('essencial', 'premium');

-- Criar assinaturas para os usuários
-- Para o usuário Essencial (substitua o UUID abaixo pelo ID real do usuário)
INSERT INTO subscriptions (
  user_id,
  plan_type,
  billing_frequency,
  amount,
  status,
  start_date,
  next_billing_date,
  payment_status
)
VALUES (
  'UUID_DO_USUARIO_ESSENCIAL',
  'essencial',
  'monthly',
  15.90,
  'active',
  NOW(),
  NOW() + INTERVAL '1 month',
  'confirmed'
);

-- Para o usuário Premium (substitua o UUID abaixo pelo ID real do usuário)
INSERT INTO subscriptions (
  user_id,
  plan_type,
  billing_frequency,
  amount,
  status,
  start_date,
  next_billing_date,
  payment_status
)
VALUES (
  'UUID_DO_USUARIO_PREMIUM',
  'premium',
  'monthly',
  24.90,
  'active',
  NOW(),
  NOW() + INTERVAL '1 month',
  'confirmed'
);

-- Verificar os usuários criados
SELECT * FROM profiles 
WHERE email IN ('teste.essencial@medmoney.me', 'teste.premium@medmoney.me');

-- Verificar as assinaturas criadas
SELECT s.*, p.name 
FROM subscriptions s
JOIN auth.users u ON s.user_id = u.id
JOIN profiles pr ON u.id = pr.id
JOIN plans p ON s.plan_type = p.type
WHERE pr.email IN ('teste.essencial@medmoney.me', 'teste.premium@medmoney.me'); 