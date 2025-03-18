// Script para configurar o Supabase para o MedMoney
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Configurações do Supabase
const supabaseUrl = 'https://rwotvxqknrjurqrhxhjv.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_KEY; // Chave de serviço (não a chave anônima)

if (!supabaseKey) {
  console.error('Erro: SUPABASE_SERVICE_KEY não encontrada no arquivo .env');
  console.error('Por favor, crie um arquivo .env com a chave de serviço do Supabase');
  process.exit(1);
}

// Criar cliente Supabase
const supabase = createClient(supabaseUrl, supabaseKey);

// Ler o arquivo SQL
const sqlFilePath = path.join(__dirname, 'supabase_setup.sql');
const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');

// Dividir o conteúdo SQL em comandos individuais
const sqlCommands = sqlContent
  .split(';')
  .map(command => command.trim())
  .filter(command => command.length > 0);

// Executar cada comando SQL
async function executeSQL() {
  console.log(`Executando ${sqlCommands.length} comandos SQL...`);
  
  for (let i = 0; i < sqlCommands.length; i++) {
    const command = sqlCommands[i];
    try {
      console.log(`Executando comando ${i + 1}/${sqlCommands.length}`);
      const { error } = await supabase.rpc('exec_sql', { sql_query: command + ';' });
      
      if (error) {
        console.error(`Erro ao executar comando ${i + 1}:`, error);
      }
    } catch (err) {
      console.error(`Exceção ao executar comando ${i + 1}:`, err);
    }
  }
  
  console.log('Configuração do Supabase concluída!');
}

// Executar o script
executeSQL().catch(err => {
  console.error('Erro ao executar script:', err);
}); 