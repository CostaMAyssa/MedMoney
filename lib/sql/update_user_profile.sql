-- Script para atualizar o perfil do usuário para teste
-- Substitua o ID do usuário pelo ID real do usuário que você está testando

-- ID do usuário a ser atualizado (substitua pelo ID real)
UPDATE public.profiles
SET 
  cpf = '123.456.789-00',
  phone = '(11) 98765-4321'
WHERE id = '341b04ca-9004-4b40-aefd-53735210df86'; -- Substitua pelo ID do usuário

-- Verificar se a atualização foi bem-sucedida
SELECT id, name, email, phone, cpf
FROM public.profiles
WHERE id = '341b04ca-9004-4b40-aefd-53735210df86'; -- Substitua pelo ID do usuário 