// Logs para depuração em ambiente de desenvolvimento
console.log(`Ambiente: ${isProduction ? 'Produção' : 'Desenvolvimento'}`);
console.log(`URL da API Asaas: ${ASAAS_API_URL}`);
console.log(`URL do Supabase: ${SUPABASE_URL}`);
console.log(`URL do site: ${SITE_URL}`);

// Verificar variáveis de ambiente do Supabase
if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.warn('Aviso: Verificando variáveis alternativas...');
  
  // Tentar usar SUPABASE_SERVICE_ROLE_KEY se SUPABASE_SERVICE_KEY não estiver definido
  if (!SUPABASE_SERVICE_KEY && process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.warn('Usando SUPABASE_SERVICE_ROLE_KEY como alternativa');
    SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
  } else {
    console.error('Erro: Variáveis de ambiente do Supabase não configuradas!');
    process.exit(1);
  }
}

console.log('Iniciando servidor webhook com as seguintes configurações:');
console.log('Supabase URL:', SUPABASE_URL);
console.log('Supabase Key:', '***' + SUPABASE_SERVICE_KEY.slice(-4));
console.log('Porta:', PORT); 