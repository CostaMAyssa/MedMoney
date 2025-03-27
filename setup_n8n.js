// Script para configurar a tabela de logs do n8n no Supabase
// Execute com: node setup_n8n.js

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

// Configuração do Supabase
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('Erro: Variáveis de ambiente SUPABASE_URL e SUPABASE_SERVICE_KEY são obrigatórias.');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function setupN8nTable() {
  console.log('Configurando tabela de logs do n8n...');
  
  try {
    // Verificar se a tabela já existe
    const { error: checkError } = await supabase
      .from('n8n_logs')
      .select('id')
      .limit(1);
    
    if (!checkError) {
      console.log('Tabela n8n_logs já existe.');
      return;
    }
    
    // Criar tabela de logs do n8n
    const { error } = await supabase.rpc('create_n8n_logs_table');
    
    if (error) {
      // Se a função RPC não existir, criar a tabela manualmente
      console.log('Criando tabela manualmente...');
      
      // SQL para criar a tabela
      const createTableSQL = `
      CREATE TABLE IF NOT EXISTS n8n_logs (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        plan_id UUID REFERENCES plans(id) ON DELETE SET NULL,
        request_data JSONB NOT NULL,
        response_data JSONB,
        success BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
      
      -- Políticas de segurança RLS
      ALTER TABLE n8n_logs ENABLE ROW LEVEL SECURITY;
      
      -- Apenas o serviço pode inserir registros
      CREATE POLICY "Service can insert n8n_logs"
        ON n8n_logs FOR INSERT
        TO service_role
        WITH CHECK (true);
        
      -- Usuários podem ver apenas seus próprios logs
      CREATE POLICY "Users can view their own n8n_logs"
        ON n8n_logs FOR SELECT
        TO authenticated
        USING (auth.uid() = user_id);
        
      -- Função trigger para atualizar o campo updated_at
      CREATE OR REPLACE FUNCTION update_n8n_logs_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = now();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      
      -- Trigger para atualizar o campo updated_at
      CREATE TRIGGER update_n8n_logs_updated_at
        BEFORE UPDATE ON n8n_logs
        FOR EACH ROW
        EXECUTE FUNCTION update_n8n_logs_updated_at();
      `;
      
      const { error: sqlError } = await supabase.rpc('exec_sql', { sql: createTableSQL });
      
      if (sqlError) {
        console.error('Erro ao criar tabela manualmente:', sqlError);
        return;
      }
    }
    
    console.log('Tabela n8n_logs criada com sucesso!');
    
  } catch (error) {
    console.error('Erro ao configurar tabela n8n_logs:', error.message);
  }
}

async function main() {
  try {
    await setupN8nTable();
    console.log('Configuração concluída com sucesso!');
  } catch (error) {
    console.error('Erro na configuração:', error);
  }
}

main();
