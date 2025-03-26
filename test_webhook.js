// Script para testar o webhook do MedMoney
const axios = require('axios');
require('dotenv').config();

// Configuração
const webhookUrl = 'http://localhost:3000/api/webhook/asaas';

// Cores para o console
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  underscore: '\x1b[4m',
  blink: '\x1b[5m',
  reverse: '\x1b[7m',
  hidden: '\x1b[8m',
  
  fg: {
    black: '\x1b[30m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    white: '\x1b[37m'
  },
  
  bg: {
    black: '\x1b[40m',
    red: '\x1b[41m',
    green: '\x1b[42m',
    yellow: '\x1b[43m',
    blue: '\x1b[44m',
    magenta: '\x1b[45m',
    cyan: '\x1b[46m',
    white: '\x1b[47m'
  }
};

// Funções auxiliares
function log(message, type = 'info') {
  const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  
  switch (type) {
    case 'success':
      console.log(`${colors.fg.green}[${timestamp}] ✓ ${message}${colors.reset}`);
      break;
    case 'error':
      console.log(`${colors.fg.red}[${timestamp}] ✗ ${message}${colors.reset}`);
      break;
    case 'warning':
      console.log(`${colors.fg.yellow}[${timestamp}] ⚠ ${message}${colors.reset}`);
      break;
    case 'title':
      console.log(`\n${colors.fg.cyan}${colors.bright}${message}${colors.reset}\n`);
      break;
    default:
      console.log(`${colors.fg.white}[${timestamp}] ℹ ${message}${colors.reset}`);
  }
}

// Função para gerar um ID aleatório
function generateId() {
  return `test_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
}

// Função para testar o webhook com diferentes eventos
async function testWebhook() {
  log('TESTE DO WEBHOOK DO MEDMONEY', 'title');
  
  const testEvents = [
    {
      name: 'PAYMENT_RECEIVED',
      payload: {
        event: 'PAYMENT_RECEIVED',
        payment: {
          id: generateId(),
          customer: generateId(),
          value: 29.90,
          netValue: 29.90,
          billingType: 'PIX',
          status: 'RECEIVED',
          dueDate: new Date().toISOString().split('T')[0],
          paymentDate: new Date().toISOString().split('T')[0],
          description: 'Assinatura MedMoney Premium',
          invoiceUrl: 'https://sandbox.asaas.com/i/123456789',
          subscription: generateId()
        }
      }
    },
    {
      name: 'PAYMENT_CONFIRMED',
      payload: {
        event: 'PAYMENT_CONFIRMED',
        payment: {
          id: generateId(),
          customer: generateId(),
          value: 29.90,
          netValue: 29.90,
          billingType: 'CREDIT_CARD',
          status: 'CONFIRMED',
          dueDate: new Date().toISOString().split('T')[0],
          paymentDate: new Date().toISOString().split('T')[0],
          description: 'Assinatura MedMoney Premium',
          invoiceUrl: 'https://sandbox.asaas.com/i/123456789',
          subscription: generateId()
        }
      }
    },
    {
      name: 'PAYMENT_OVERDUE',
      payload: {
        event: 'PAYMENT_OVERDUE',
        payment: {
          id: generateId(),
          customer: generateId(),
          value: 29.90,
          netValue: 29.90,
          billingType: 'BOLETO',
          status: 'OVERDUE',
          dueDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          description: 'Assinatura MedMoney Premium',
          invoiceUrl: 'https://sandbox.asaas.com/i/123456789',
          subscription: generateId()
        }
      }
    },
    {
      name: 'PAYMENT_DELETED',
      payload: {
        event: 'PAYMENT_DELETED',
        payment: {
          id: generateId(),
          customer: generateId(),
          value: 29.90,
          netValue: 29.90,
          billingType: 'PIX',
          status: 'DELETED',
          dueDate: new Date().toISOString().split('T')[0],
          description: 'Assinatura MedMoney Premium',
          invoiceUrl: 'https://sandbox.asaas.com/i/123456789',
          subscription: generateId()
        }
      }
    },
    {
      name: 'SUBSCRIPTION_CREATED',
      payload: {
        event: 'SUBSCRIPTION_CREATED',
        subscription: {
          id: generateId(),
          customer: generateId(),
          value: 29.90,
          nextDueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          billingType: 'PIX',
          status: 'ACTIVE',
          description: 'Assinatura MedMoney Premium',
          cycle: 'MONTHLY'
        }
      }
    },
    {
      name: 'SUBSCRIPTION_RENEWED',
      payload: {
        event: 'SUBSCRIPTION_RENEWED',
        subscription: {
          id: generateId(),
          customer: generateId(),
          value: 29.90,
          nextDueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
          billingType: 'CREDIT_CARD',
          status: 'ACTIVE',
          description: 'Assinatura MedMoney Premium',
          cycle: 'MONTHLY'
        }
      }
    },
    {
      name: 'SUBSCRIPTION_CANCELED',
      payload: {
        event: 'SUBSCRIPTION_CANCELED',
        subscription: {
          id: generateId(),
          customer: generateId(),
          value: 29.90,
          nextDueDate: null,
          billingType: 'CREDIT_CARD',
          status: 'CANCELED',
          description: 'Assinatura MedMoney Premium',
          cycle: 'MONTHLY'
        }
      }
    }
  ];
  
  // Testar cada evento
  for (const testEvent of testEvents) {
    log(`Testando evento: ${testEvent.name}`);
    
    try {
      const response = await axios.post(webhookUrl, testEvent.payload, {
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      if (response.status === 200) {
        log(`Evento ${testEvent.name} processado com sucesso`, 'success');
      } else {
        log(`Evento ${testEvent.name} retornou status ${response.status}`, 'warning');
      }
    } catch (error) {
      log(`Erro ao processar evento ${testEvent.name}: ${error.message}`, 'error');
      
      if (error.response) {
        log(`Status: ${error.response.status}`, 'error');
        log(`Resposta: ${JSON.stringify(error.response.data)}`, 'error');
      }
    }
    
    // Aguardar um momento entre as requisições
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  log('TESTE DO WEBHOOK CONCLUÍDO', 'title');
}

// Verificar se o webhook está rodando
async function checkWebhookStatus() {
  try {
    // Tentar fazer uma requisição para o webhook
    await axios.get('http://localhost:3000');
    return true;
  } catch (error) {
    // Se o erro for de conexão recusada, o webhook não está rodando
    if (error.code === 'ECONNREFUSED') {
      return false;
    }
    
    // Se for outro tipo de erro, o webhook pode estar rodando
    return true;
  }
}

// Função principal
async function main() {
  // Verificar se o webhook está rodando
  const isWebhookRunning = await checkWebhookStatus();
  
  if (!isWebhookRunning) {
    log('O webhook não está rodando. Inicie o webhook antes de executar este teste.', 'error');
    log('Execute: node webhook_handler.js', 'info');
    return;
  }
  
  // Executar os testes
  await testWebhook();
}

// Executar o script
main().catch(error => {
  log(`Erro ao executar testes: ${error.message}`, 'error');
}); 