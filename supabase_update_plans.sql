-- Script para atualizar planos no banco de dados do MedMoney
-- Execute este script no Editor SQL do Supabase

-- Verifique quais planos existem atualmente
-- Comentários na saída: 
-- Se você ver planos na saída abaixo, é melhor usar UPDATE para atualizá-los
-- Se a tabela estiver vazia, iremos inserir novos planos

SELECT * FROM plans;

-- Remover planos existentes se necessário (cuidado, use apenas se quiser recriar tudo do zero)
-- DELETE FROM plans WHERE true;

-- IMPORTANTE: Vamos atualizar os planos para os novos valores
-- 1. "Essencial" - R$ 15,90/mês ou R$ 163,00/ano
-- 2. "Premium" - R$ 24,90/mês ou R$ 254,00/ano

-- Primeiro, excluir planos existentes que não são mais usados
DELETE FROM plans WHERE LOWER(name) = 'enterprise' OR LOWER(name) = 'básico' OR LOWER(name) = 'basico';

-- Atualizar ou inserir o plano Essencial
UPDATE plans
SET name = 'Essencial',
    type = 'essencial',
    price = 15.90,
    price_monthly = 15.90,
    price_annual = 163.00,
    setup_fee = 0,
    features = '["Acesso ao bot no WhatsApp", "Controle de despesas", "Alertas financeiros"]'::jsonb,
    description = 'Bot no WhatsApp para controle financeiro',
    active = true,
    is_active = true
WHERE LOWER(name) IN ('basic', 'essencial');

-- Se o plano Essencial não existir, inserir
INSERT INTO plans (name, type, price, price_monthly, price_annual, setup_fee, features, description, active, is_active)
SELECT 'Essencial', 'essencial', 15.90, 15.90, 163.00, 0, 
       '["Acesso ao bot no WhatsApp", "Controle de despesas", "Alertas financeiros"]'::jsonb,
       'Bot no WhatsApp para controle financeiro', true, true
WHERE NOT EXISTS (SELECT 1 FROM plans WHERE LOWER(name) = 'essencial');

-- Atualizar ou inserir o plano Premium
UPDATE plans
SET name = 'Premium',
    type = 'premium',
    price = 24.90,
    price_monthly = 24.90,
    price_annual = 254.00,
    setup_fee = 0,
    features = '["Acesso ao dashboard completo", "Controle de despesas e receitas", "Alertas financeiros personalizados", "Relatórios detalhados", "Consultas financeiras mensais"]'::jsonb,
    description = 'Bot no WhatsApp + Dashboard completo',
    active = true,
    is_active = true
WHERE LOWER(name) = 'premium';

-- Se o plano Premium não existir, inserir
INSERT INTO plans (name, type, price, price_monthly, price_annual, setup_fee, features, description, active, is_active)
SELECT 'Premium', 'premium', 24.90, 24.90, 254.00, 0, 
       '["Acesso ao dashboard completo", "Controle de despesas e receitas", "Alertas financeiros personalizados", "Relatórios detalhados", "Consultas financeiras mensais"]'::jsonb,
       'Bot no WhatsApp + Dashboard completo', true, true
WHERE NOT EXISTS (SELECT 1 FROM plans WHERE LOWER(name) = 'premium');

-- Verificar os planos após a atualização
SELECT * FROM plans;
