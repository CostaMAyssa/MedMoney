-- Script SQL para atualização de planos

-- Script para atualizar os planos no Supabase
-- Primeiro, verificamos quais planos existem atualmente
SELECT * FROM plans;

-- Atualizar plano Essencial
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
WHERE LOWER(name) = 'essencial' OR LOWER(name) = 'basico' OR LOWER(name) = 'básico';

-- Atualizar plano Premium
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

-- Se os planos não existirem, inserir
INSERT INTO plans (name, type, price, price_monthly, price_annual, setup_fee, features, description, active, is_active)
SELECT 'Essencial', 'essencial', 15.90, 15.90, 163.00, 0, 
       '["Acesso ao bot no WhatsApp", "Controle de despesas", "Alertas financeiros"]'::jsonb,
       'Bot no WhatsApp para controle financeiro', true, true
WHERE NOT EXISTS (SELECT 1 FROM plans WHERE LOWER(name) = 'essencial');

INSERT INTO plans (name, type, price, price_monthly, price_annual, setup_fee, features, description, active, is_active)
SELECT 'Premium', 'premium', 24.90, 24.90, 254.00, 0, 
       '["Acesso ao dashboard completo", "Controle de despesas e receitas", "Alertas financeiros personalizados", "Relatórios detalhados", "Consultas financeiras mensais"]'::jsonb,
       'Bot no WhatsApp + Dashboard completo', true, true
WHERE NOT EXISTS (SELECT 1 FROM plans WHERE LOWER(name) = 'premium');

-- Verificar os planos após a atualização
SELECT * FROM plans;
