-- Configuração das tabelas para o MedMoney no Supabase
-- Execute este script diretamente no Editor SQL do Supabase

-- Tabela de perfis de usuários (estende a tabela auth.users do Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT,
  phone TEXT,
  city TEXT,
  state TEXT,
  cpf_cnpj TEXT,
  asaas_customer_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de planos disponíveis
CREATE TABLE IF NOT EXISTS public.plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  features JSONB,
  monthly_price DECIMAL(10, 2) NOT NULL,
  annual_price DECIMAL(10, 2) NOT NULL,
  setup_fee DECIMAL(10, 2) DEFAULT 49.90,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir planos padrão
INSERT INTO public.plans (name, description, features, monthly_price, annual_price, setup_fee)
VALUES 
  ('Básico', 'Bot no WhatsApp', '["Registro de transações via WhatsApp", "Alertas de pagamentos", "Relatórios básicos"]', 13.90, 142.00, 49.90),
  ('Premium', 'Bot no WhatsApp + Dashboard', '["Tudo do plano Básico", "Dashboard completo", "Integração com Google Calendar", "Relatórios avançados"]', 22.90, 228.00, 49.90);

-- Função para criar automaticamente um perfil quando um novo usuário se registra
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, created_at, updated_at)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'name', NEW.email, NOW(), NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para chamar a função quando um novo usuário é criado
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Tabela de assinaturas
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES public.plans(id),
  plan_name TEXT NOT NULL,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('monthly', 'annual')),
  price DECIMAL(10, 2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'active', 'canceled', 'overdue')),
  start_date TIMESTAMP WITH TIME ZONE,
  next_billing_date TIMESTAMP WITH TIME ZONE,
  asaas_subscription_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de pagamentos
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id),
  payment_method TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  description TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending', 'confirmed', 'canceled', 'overdue')),
  due_date TIMESTAMP WITH TIME ZONE,
  payment_date TIMESTAMP WITH TIME ZONE,
  asaas_payment_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de transações financeiras (entradas e saídas)
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  category TEXT NOT NULL,
  description TEXT,
  amount DECIMAL(10, 2) NOT NULL,
  date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de categorias de transações
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  color TEXT,
  icon TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir categorias padrão
INSERT INTO public.categories (name, type, color, icon, is_default)
VALUES 
  ('Plantão', 'income', '#4CAF50', 'medical_services', TRUE),
  ('Consulta', 'income', '#2196F3', 'person', TRUE),
  ('Salário', 'income', '#9C27B0', 'work', TRUE),
  ('Outros', 'income', '#607D8B', 'attach_money', TRUE),
  ('Alimentação', 'expense', '#F44336', 'restaurant', TRUE),
  ('Transporte', 'expense', '#FF9800', 'directions_car', TRUE),
  ('Moradia', 'expense', '#795548', 'home', TRUE),
  ('Saúde', 'expense', '#E91E63', 'favorite', TRUE),
  ('Educação', 'expense', '#3F51B5', 'school', TRUE),
  ('Lazer', 'expense', '#009688', 'sports_esports', TRUE),
  ('Outros', 'expense', '#607D8B', 'shopping_bag', TRUE);

-- Tabela de plantões
CREATE TABLE IF NOT EXISTS public.shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  location TEXT NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  expected_payment DECIMAL(10, 2),
  status TEXT NOT NULL CHECK (status IN ('scheduled', 'completed', 'canceled')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de consultas
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  patient_name TEXT NOT NULL,
  appointment_time TIMESTAMP WITH TIME ZONE NOT NULL,
  duration INTEGER, -- em minutos
  expected_payment DECIMAL(10, 2),
  status TEXT NOT NULL CHECK (status IN ('scheduled', 'completed', 'canceled')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de configurações do usuário
CREATE TABLE IF NOT EXISTS public.user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  whatsapp_integration BOOLEAN DEFAULT FALSE,
  whatsapp_number TEXT,
  google_calendar_integration BOOLEAN DEFAULT FALSE,
  notification_preferences JSONB DEFAULT '{"email": true, "push": true, "whatsapp": false}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Configurar políticas de segurança (RLS - Row Level Security)

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
CREATE POLICY "Usuários podem ver apenas seu próprio perfil" 
  ON public.profiles FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Usuários podem atualizar apenas seu próprio perfil" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

-- Políticas para planos (visíveis para todos)
CREATE POLICY "Planos são visíveis para todos" 
  ON public.plans FOR SELECT 
  USING (true);

-- Políticas para assinaturas
CREATE POLICY "Usuários podem ver apenas suas próprias assinaturas" 
  ON public.subscriptions FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir suas próprias assinaturas" 
  ON public.subscriptions FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias assinaturas" 
  ON public.subscriptions FOR UPDATE 
  USING (auth.uid() = user_id);

-- Políticas para pagamentos
CREATE POLICY "Usuários podem ver apenas seus próprios pagamentos" 
  ON public.payments FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir seus próprios pagamentos" 
  ON public.payments FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Políticas para transações
CREATE POLICY "Usuários podem ver apenas suas próprias transações" 
  ON public.transactions FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir suas próprias transações" 
  ON public.transactions FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias transações" 
  ON public.transactions FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem excluir suas próprias transações" 
  ON public.transactions FOR DELETE 
  USING (auth.uid() = user_id);

-- Políticas para categorias
CREATE POLICY "Categorias padrão são visíveis para todos" 
  ON public.categories FOR SELECT 
  USING (is_default OR auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir suas próprias categorias" 
  ON public.categories FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias categorias" 
  ON public.categories FOR UPDATE 
  USING (auth.uid() = user_id AND NOT is_default);

CREATE POLICY "Usuários podem excluir suas próprias categorias" 
  ON public.categories FOR DELETE 
  USING (auth.uid() = user_id AND NOT is_default);

-- Políticas para plantões
CREATE POLICY "Usuários podem ver apenas seus próprios plantões" 
  ON public.shifts FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir seus próprios plantões" 
  ON public.shifts FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar seus próprios plantões" 
  ON public.shifts FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem excluir seus próprios plantões" 
  ON public.shifts FOR DELETE 
  USING (auth.uid() = user_id);

-- Políticas para consultas
CREATE POLICY "Usuários podem ver apenas suas próprias consultas" 
  ON public.appointments FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir suas próprias consultas" 
  ON public.appointments FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias consultas" 
  ON public.appointments FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem excluir suas próprias consultas" 
  ON public.appointments FOR DELETE 
  USING (auth.uid() = user_id);

-- Políticas para configurações do usuário
CREATE POLICY "Usuários podem ver apenas suas próprias configurações" 
  ON public.user_settings FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir suas próprias configurações" 
  ON public.user_settings FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar suas próprias configurações" 
  ON public.user_settings FOR UPDATE 
  USING (auth.uid() = user_id); 