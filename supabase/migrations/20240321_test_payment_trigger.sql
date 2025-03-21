-- Script de teste para a criação da tabela personalizada do usuário

-- 0. Criar schema user_data se não existir
CREATE SCHEMA IF NOT EXISTS user_data;

-- 0.1 Criar tabela de registro se não existir
CREATE TABLE IF NOT EXISTS user_data.user_tables_registry (
    user_id UUID PRIMARY KEY,
    table_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1. Primeiro, vamos inserir um pagamento pendente
INSERT INTO public.payments (
    user_id,
    amount,
    payment_method,
    status,
    description
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000', -- ID de usuário de teste
    99.90,
    'pix',
    'pending',
    'Assinatura Premium'
) RETURNING id;

-- 2. Aguardar um segundo
SELECT pg_sleep(1);

-- 3. Atualizar o status do pagamento para confirmado
UPDATE public.payments 
SET status = 'confirmed',
    payment_date = NOW()
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'
AND status = 'pending';

-- 4. Verificar se a tabela foi criada
SELECT EXISTS (
    SELECT FROM user_data.user_tables_registry
    WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'
) as tabela_registrada;

-- 5. Tentar inserir um dado na tabela do usuário
DO $$
DECLARE
    table_name TEXT;
BEGIN
    -- Obter o nome da tabela do registro
    SELECT ut.table_name INTO table_name
    FROM user_data.user_tables_registry ut
    WHERE ut.user_id = '550e8400-e29b-41d4-a716-446655440000';

    IF table_name IS NOT NULL THEN
        EXECUTE format('
            INSERT INTO %s (
                data,
                valor,
                categoria,
                descricao,
                message_text,
                message_type
            ) VALUES (
                CURRENT_DATE,
                150.00,
                ''Teste'',
                ''Lançamento de teste'',
                ''Mensagem de teste'',
                ''test''
            )
        ', table_name);
    END IF;
END $$; 