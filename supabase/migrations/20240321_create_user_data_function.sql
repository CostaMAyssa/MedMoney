-- Função para criar tabela personalizada do usuário
CREATE OR REPLACE FUNCTION create_user_data_table(user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    table_name TEXT;
BEGIN
    -- Definir nome da tabela
    table_name := 'dados_usuario_' || user_id::text;
    
    -- Criar tabela se não existir
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS public.%I (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            descricao TEXT,
            valor DECIMAL(10,2),
            data TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )', table_name);
    
    -- Criar política de segurança para a tabela
    EXECUTE format('
        DROP POLICY IF EXISTS "Usuários podem ver seus próprios dados" ON public.%I;
        CREATE POLICY "Usuários podem ver seus próprios dados"
        ON public.%I
        FOR ALL
        USING (auth.uid() = %L);', 
        table_name, table_name, user_id);
    
    -- Habilitar RLS na tabela
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', table_name);
    
    -- Criar trigger para atualizar updated_at
    EXECUTE format('
        CREATE OR REPLACE FUNCTION public.update_%I_updated_at()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;', table_name);
    
    EXECUTE format('
        DROP TRIGGER IF EXISTS update_%I_updated_at ON public.%I;
        CREATE TRIGGER update_%I_updated_at
        BEFORE UPDATE ON public.%I
        FOR EACH ROW
        EXECUTE FUNCTION public.update_%I_updated_at();',
        table_name, table_name, table_name, table_name, table_name);
END;
$$; 