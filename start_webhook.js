// Script para iniciar o webhook com localtunnel
const { spawn } = require('child_process');
const localtunnel = require('localtunnel');
require('dotenv').config();

const PORT = process.env.PORT || 3000;

// Iniciar o servidor webhook
console.log('Iniciando o servidor webhook...');
const webhookProcess = spawn('node', ['webhook_handler.js'], { stdio: 'inherit' });

webhookProcess.on('error', (error) => {
  console.error('Erro ao iniciar o servidor webhook:', error);
  process.exit(1);
});

// Iniciar o localtunnel após 2 segundos (para dar tempo do servidor iniciar)
setTimeout(async () => {
  try {
    console.log(`Criando túnel para a porta ${PORT}...`);
    const tunnel = await localtunnel({ port: PORT });
    
    console.log('\n=== CONFIGURAÇÃO DO WEBHOOK NO ASAAS ===');
    console.log(`1. Acesse o painel do Asaas: ${process.env.ASAAS_SANDBOX === 'true' ? 'https://sandbox.asaas.com' : 'https://www.asaas.com'}`);
    console.log('2. Vá para Configurações > Integrações > Webhooks');
    console.log('3. Clique em "Adicionar Webhook"');
    console.log(`4. URL do Webhook: ${tunnel.url}/webhook/asaas`);
    console.log('5. Selecione os eventos:');
    console.log('   - PAYMENT_RECEIVED');
    console.log('   - PAYMENT_CONFIRMED');
    console.log('   - PAYMENT_OVERDUE');
    console.log('   - PAYMENT_DELETED');
    console.log('   - PAYMENT_REFUNDED');
    console.log('   - PAYMENT_CANCELED');
    console.log('   - SUBSCRIPTION_CREATED');
    console.log('   - SUBSCRIPTION_RENEWED');
    console.log('   - SUBSCRIPTION_CANCELED');
    console.log('6. Clique em "Salvar"');
    console.log('\nO webhook está pronto para receber notificações do Asaas!');
    console.log('Pressione Ctrl+C para encerrar o servidor.\n');

    tunnel.on('close', () => {
      console.log('Túnel fechado');
      webhookProcess.kill();
      process.exit(0);
    });
  } catch (error) {
    console.error('Erro ao iniciar o túnel:', error);
    webhookProcess.kill();
    process.exit(1);
  }
}, 2000);

// Encerrar tudo quando o processo for terminado
process.on('SIGINT', () => {
  console.log('Encerrando o servidor webhook e o túnel...');
  webhookProcess.kill();
  process.exit(0);
}); 