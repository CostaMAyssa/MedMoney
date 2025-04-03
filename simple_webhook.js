require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

// Configurações
const PORT = process.env.PORT || 82;
const HOSTNAME = process.env.HOSTNAME || '0.0.0.0';
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Inicializar Supabase
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Inicializar Express
const app = express();

// Middlewares
app.use(bodyParser.json());
app.use(cors());

// Rotas
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', time: new Date().toISOString() });
});

app.get('/api/webhook/asaas/health', (req, res) => {
  res.status(200).json({ status: 'ok', time: new Date().toISOString() });
});

// Webhook do Asaas
app.post('/api/webhook/asaas', async (req, res) => {
  try {
    const event = req.body;
    
    console.log('Webhook recebido:', JSON.stringify(event, null, 2));
    
    // Registrar o webhook no Supabase
    try {
      await supabase
        .from('asaas_logs')
        .insert({
          event_type: event.event || 'UNKNOWN',
          webhook_data: event,
          processed: true,
          created_at: new Date().toISOString()
        });
      
      console.log('Webhook registrado no Supabase com sucesso');
    } catch (error) {
      console.error('Erro ao registrar webhook:', error);
    }
    
    // Responder com sucesso
    res.status(200).json({ 
      success: true,
      message: 'Webhook processado com sucesso',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erro ao processar webhook:', error);
    res.status(500).json({ 
      error: 'Erro ao processar webhook',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Iniciar o servidor
app.listen(PORT, HOSTNAME, () => {
  console.log(`Servidor webhook rodando em http://${HOSTNAME}:${PORT}`);
  console.log(`Health check: http://${HOSTNAME}:${PORT}/health`);
  console.log(`Webhook URL: http://${HOSTNAME}:${PORT}/api/webhook/asaas`);
  
  console.log('Configurações do ambiente:');
  console.log(`- PORT: ${PORT}`);
  console.log(`- HOSTNAME: ${HOSTNAME}`);
  console.log(`- SUPABASE_URL: ${SUPABASE_URL}`);
}); 