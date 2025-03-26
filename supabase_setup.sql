-- Script de configuração do banco de dados para o MedMoney
-- Execute este script no SQL Editor do Supabase

-- Habilitar a extensão UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Configurar o esquema de segurança
ALTER DATABASE postgres SET "app.jwt_secret" TO 'sua_jwt_secret';

-- Criação da tabela de perfis
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    name TEXT,
    email TEXT,
    phone TEXT,
    full_name TEXT,
    username TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Criação da tabela de planos
CREATE TABLE IF NOT EXISTS plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    price_monthly NUMERIC NOT NULL,
    price_annual NUMERIC NOT NULL,
    setup_fee NUMERIC DEFAULT 0,
    features JSONB,
    description TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Criação da tabela de assinaturas
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    plan_type TEXT NOT NULL,
    billing_frequency TEXT NOT NULL, -- 'monthly' ou 'annual'
    amount NUMERIC NOT NULL,
    status TEXT NOT NULL, -- 'pending', 'active', 'overdue', 'cancelled'
    start_date TIMESTAMPTZ DEFAULT NOW(),
    next_billing_date TIMESTAMPTZ,
    expiration_date TIMESTAMPTZ,
    payment_id TEXT, -- ID do pagamento no Asaas
    external_reference TEXT, -- Referência externa para o pagamento
    payment_status TEXT, -- Status do pagamento no Asaas
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Criação da tabela de logs Asaas
CREATE TABLE IF NOT EXISTS asaas_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    payment_id TEXT,
    external_reference TEXT,
    status TEXT,
    subscription_id UUID,
    webhook_data JSONB,
    processed BOOLEAN DEFAULT FALSE,
    error TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de pagamentos
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES public.subscriptions(id),
    amount DECIMAL(10, 2) NOT NULL,
    payment_method TEXT NOT NULL,
    status TEXT NOT NULL, -- 'pending', 'completed', 'failed'
    transaction_id TEXT,
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de transações financeiras
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id),
    description TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    type TEXT NOT NULL, -- 'income' ou 'expense'
    date DATE NOT NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_frequency TEXT, -- 'daily', 'weekly', 'monthly', 'yearly'
    recurrence_end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de categorias
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'income' ou 'expense'
    color TEXT,
    icon TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de plantões
CREATE TABLE IF NOT EXISTS public.shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    hospital TEXT NOT NULL,
    specialty TEXT,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    hourly_rate DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de consultas
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    patient_name TEXT NOT NULL,
    specialty TEXT,
    date DATE NOT NULL,
    time TIME NOT NULL,
    duration INTEGER, -- em minutos
    fee DECIMAL(10, 2),
    status TEXT NOT NULL, -- 'scheduled', 'completed', 'canceled'
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de configurações do usuário
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    theme TEXT DEFAULT 'dark',
    language TEXT DEFAULT 'pt-BR',
    notification_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir planos padrão
INSERT INTO plans (name, type, price_monthly, price_annual, setup_fee, features, description, active)
VALUES
    ('Basic', 'basic', 29.90, 299.90, 0, 
     '["Acesso ao dashboard básico", "Controle de despesas", "Alertas financeiros"]'::jsonb, 
     'Plano básico para controle financeiro', true),
    
    ('Premium', 'premium', 59.90, 599.90, 19.90,
     '["Acesso ao dashboard completo", "Controle de despesas e receitas", "Alertas financeiros personalizados", "Relatórios detalhados", "Consultas financeiras mensais"]'::jsonb,
     'Plano premium com recursos avançados', true),
     
    ('Enterprise', 'enterprise', 99.90, 999.90, 0,
     '["Acesso a todos os recursos", "Suporte prioritário", "Relatórios avançados", "Integração com outros sistemas", "Consultoria financeira completa", "Acesso multi-usuário"]'::jsonb,
     'Plano completo para clínicas e consultórios', true);

-- Inserir categorias padrão
INSERT INTO public.categories (name, type, color, icon, is_default)
VALUES 
('Salário', 'income', '#4CAF50', 'work', true),
('Plantão', 'income', '#2196F3', 'medical_services', true),
('Consulta', 'income', '#9C27B0', 'healing', true),
('Moradia', 'expense', '#F44336', 'home', true),
('Alimentação', 'expense', '#FF9800', 'restaurant', true),
('Transporte', 'expense', '#795548', 'directions_car', true),
('Saúde', 'expense', '#E91E63', 'favorite', true),
('Educação', 'expense', '#3F51B5', 'school', true),
('Lazer', 'expense', '#009688', 'sports_esports', true),
('Outros', 'expense', '#607D8B', 'more_horiz', true)
ON CONFLICT (id) DO NOTHING;

-- Configurar políticas de segurança (RLS)
-- Habilitar RLS em todas as tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Políticas para perfis
CREATE POLICY "Usuários podem ver seus próprios perfis" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Usuários podem atualizar seus próprios perfis" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Usuários podem inserir seus próprios perfis" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Políticas para planos (visíveis para todos)
CREATE POLICY "Planos são visíveis para todos" ON public.plans
    FOR SELECT USING (true);

-- Políticas para assinaturas
CREATE POLICY "Usuários podem ver suas próprias assinaturas" ON public.subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir suas próprias assinaturas" ON public.subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias assinaturas" ON public.subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para pagamentos
CREATE POLICY "Usuários podem ver seus próprios pagamentos" ON public.payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir seus próprios pagamentos" ON public.payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Políticas para transações
CREATE POLICY "Usuários podem ver suas próprias transações" ON public.transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir suas próprias transações" ON public.transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias transações" ON public.transactions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem excluir suas próprias transações" ON public.transactions
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para categorias
CREATE POLICY "Categorias padrão são visíveis para todos" ON public.categories
    FOR SELECT USING (is_default OR auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir suas próprias categorias" ON public.categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias categorias" ON public.categories
    FOR UPDATE USING (auth.uid() = user_id AND NOT is_default);

CREATE POLICY "Usuários podem excluir suas próprias categorias" ON public.categories
    FOR DELETE USING (auth.uid() = user_id AND NOT is_default);

-- Políticas para plantões
CREATE POLICY "Usuários podem ver seus próprios plantões" ON public.shifts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir seus próprios plantões" ON public.shifts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar seus próprios plantões" ON public.shifts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem excluir seus próprios plantões" ON public.shifts
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para consultas
CREATE POLICY "Usuários podem ver suas próprias consultas" ON public.appointments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir suas próprias consultas" ON public.appointments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias consultas" ON public.appointments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem excluir suas próprias consultas" ON public.appointments
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para configurações do usuário
CREATE POLICY "Usuários podem ver suas próprias configurações" ON public.user_settings
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Usuários podem atualizar suas próprias configurações" ON public.user_settings
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Usuários podem inserir suas próprias configurações" ON public.user_settings
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Função para criar perfil automaticamente quando um novo usuário é criado
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'name', NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para criar perfil automaticamente
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Criar função para atualizar o campo updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar o trigger para as tabelas
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plans_updated_at
BEFORE UPDATE ON plans
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
BEFORE UPDATE ON subscriptions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

CREATE TRIGGER update_shifts_updated_at
  BEFORE UPDATE ON public.shifts
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at
  BEFORE UPDATE ON public.appointments
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at
  BEFORE UPDATE ON public.user_settings
  FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column(); 