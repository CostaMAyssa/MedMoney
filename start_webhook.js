// start_webhook.js - Script para iniciar o servidor de webhook do MedMoney
//
// Este script inicia um servidor Node.js para receber e processar os webhooks
// enviados pelo Asaas para notificação de eventos de pagamento e assinatura.
//
// Para executar este script:
//   1. Certifique-se de ter Node.js instalado (v14 ou superior)
//   2. Instale as dependências com: npm install
//   3. Execute o script com: node start_webhook.js
//
// O servidor será iniciado na porta definida no arquivo .env (WEBHOOK_PORT)
// ou na porta 3000 por padrão.

// Carregar variáveis de ambiente
require('dotenv').config();

// Importar dependências
const express = require('express');
const bodyParser = require('body-parser');
const { createClient } = require('@supabase/supabase-js');
const cors = require('cors');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');

// Criar aplicação Express
const app = express();
const PORT = process.env.WEBHOOK_PORT || process.env.PORT || 3000;

// Verificar variáveis de ambiente obrigatórias
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('ERRO: Variáveis de ambiente SUPABASE_URL e SUPABASE_SERVICE_KEY/SUPABASE_ANON_KEY são obrigatórias');
  console.error('Por favor, verifique o arquivo .env');
  process.exit(1);
}

// Configurar cliente Supabase
const supabase = createClient(supabaseUrl, supabaseKey);

// Configurar middlewares
app.use(bodyParser.json());
app.use(cors());

// Configurar logging
// Criar diretório de logs se não existir
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)){
  fs.mkdirSync(logsDir);
}

// Arquivo de log
const accessLogStream = fs.createWriteStream(
  path.join(logsDir, 'webhook.log'), 
  { flags: 'a' }
);

// Usar Morgan para logging
app.use(morgan('combined', { stream: accessLogStream }));
app.use(morgan('dev')); // Log no console também

// Importar a lógica de processamento de webhooks
const { 
  handlePaymentReceived, 
  handlePaymentConfirmed,
  handlePaymentOverdue,
  handlePaymentCanceled,
  handleSubscriptionCreated,
  handleSubscriptionRenewed,
  handleSubscriptionCanceled
} = require('./webhook_handler.js');

// Rota para health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    supabase: supabaseUrl ? 'configured' : 'not_configured'
  });
});

// Rota para receber webhooks do Asaas
app.post('/api/webhook/asaas', async (req, res) => {
  try {
    const event = req.body;
    console.log('Webhook recebido:', JSON.stringify(event).substring(0, 200) + '...');
    
    // Registrar evento no Supabase para auditoria
    try {
      const { error } = await supabase
        .from('asaas_logs')
        .insert({
          event_type: event.event,
          payload: event,
          processed: false
        });
        
      if (error) {
        console.error('Erro ao registrar evento no Supabase:', error);
      }
    } catch (logError) {
      console.error('Exceção ao registrar evento no Supabase:', logError);
    }

    // Verificar o tipo de evento
    switch (event.event) {
      case 'PAYMENT_RECEIVED':
        await handlePaymentReceived(event.payment, supabase);
        break;
      case 'PAYMENT_CONFIRMED':
        await handlePaymentConfirmed(event.payment, supabase);
        break;
      case 'PAYMENT_OVERDUE':
        await handlePaymentOverdue(event.payment, supabase);
        break;
      case 'PAYMENT_DELETED':
      case 'PAYMENT_REFUNDED':
      case 'PAYMENT_CANCELED':
        await handlePaymentCanceled(event.payment, supabase);
        break;
      case 'SUBSCRIPTION_CREATED':
        await handleSubscriptionCreated(event.subscription, supabase);
        break;
      case 'SUBSCRIPTION_RENEWED':
        await handleSubscriptionRenewed(event.subscription, supabase);
        break;
      case 'SUBSCRIPTION_CANCELED':
        await handleSubscriptionCanceled(event.subscription, supabase);
        break;
      default:
        console.log(`Evento não processado: ${event.event}`);
    }
    
    // Marcar evento como processado
    try {
      const { error } = await supabase
        .from('asaas_logs')
        .update({ processed: true })
        .eq('event_type', event.event)
        .eq('payload->id', event.payment?.id || event.subscription?.id);
        
      if (error) {
        console.error('Erro ao atualizar status do evento no Supabase:', error);
      }
    } catch (updateError) {
      console.error('Exceção ao atualizar status do evento no Supabase:', updateError);
    }

    // Responder com sucesso
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Erro ao processar webhook:', error);
    res.status(500).json({ error: 'Erro ao processar webhook' });
  }
});

// Iniciar o servidor
app.listen(PORT, () => {
  console.log(`
========================================
  SERVIDOR DE WEBHOOK MEDMONEY
========================================
  
Servidor iniciado na porta ${PORT}
URL: http://localhost:${PORT}
Health check: http://localhost:${PORT}/health
Webhook URL: http://localhost:${PORT}/api/webhook/asaas

IMPORTANTE: Para produção, use um domínio público 
com HTTPS e configure-o no painel do Asaas.

Consulte WEBHOOK_SETUP.md para mais instruções.
========================================
  `);
});

// Tratamento de exceções não capturadas
process.on('uncaughtException', (error) => {
  console.error('Exceção não capturada:', error);
  // Não encerrar o processo, apenas registrar o erro
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Promessa rejeitada não tratada:', reason);
  // Não encerrar o processo, apenas registrar o erro
}); 