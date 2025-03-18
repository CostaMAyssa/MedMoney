// Webhook Handler para o MedMoney
// Este script processa notificações do Asaas e atualiza o Supabase

const express = require('express');
const bodyParser = require('body-parser');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Configuração do Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Middleware para processar JSON
app.use(bodyParser.json());

// Rota para receber webhooks do Asaas
app.post('/webhook/asaas', async (req, res) => {
  try {
    const event = req.body;
    console.log('Webhook recebido:', JSON.stringify(event));

    // Verificar o tipo de evento
    switch (event.event) {
      case 'PAYMENT_RECEIVED':
        await handlePaymentReceived(event.payment);
        break;
      case 'PAYMENT_CONFIRMED':
        await handlePaymentConfirmed(event.payment);
        break;
      case 'PAYMENT_OVERDUE':
        await handlePaymentOverdue(event.payment);
        break;
      case 'PAYMENT_DELETED':
      case 'PAYMENT_REFUNDED':
      case 'PAYMENT_CANCELED':
        await handlePaymentCanceled(event.payment);
        break;
      case 'SUBSCRIPTION_CREATED':
        await handleSubscriptionCreated(event.subscription);
        break;
      case 'SUBSCRIPTION_RENEWED':
        await handleSubscriptionRenewed(event.subscription);
        break;
      case 'SUBSCRIPTION_CANCELED':
        await handleSubscriptionCanceled(event.subscription);
        break;
      default:
        console.log(`Evento não processado: ${event.event}`);
    }

    // Responder com sucesso
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Erro ao processar webhook:', error);
    res.status(500).json({ error: 'Erro ao processar webhook' });
  }
});

// Manipuladores de eventos

async function handlePaymentReceived(payment) {
  await updatePayment(payment, 'confirmed');
  
  // Se for um pagamento de assinatura, atualizar a assinatura também
  if (payment.subscription) {
    await updateSubscriptionStatus(payment.subscription, 'active');
  }
}

async function handlePaymentConfirmed(payment) {
  await updatePayment(payment, 'confirmed');
  
  // Se for um pagamento de assinatura, atualizar a assinatura também
  if (payment.subscription) {
    await updateSubscriptionStatus(payment.subscription, 'active');
  }
}

async function handlePaymentOverdue(payment) {
  await updatePayment(payment, 'overdue');
  
  // Se for um pagamento de assinatura, atualizar a assinatura também
  if (payment.subscription) {
    await updateSubscriptionStatus(payment.subscription, 'overdue');
  }
}

async function handlePaymentCanceled(payment) {
  await updatePayment(payment, 'canceled');
}

async function handleSubscriptionCreated(subscription) {
  await updateSubscriptionStatus(subscription.id, 'pending');
}

async function handleSubscriptionRenewed(subscription) {
  await updateSubscriptionStatus(subscription.id, 'active');
}

async function handleSubscriptionCanceled(subscription) {
  await updateSubscriptionStatus(subscription.id, 'canceled');
}

// Funções auxiliares

async function updatePayment(payment, status) {
  try {
    // Buscar o pagamento pelo ID do Asaas
    const { data: existingPayment, error: findError } = await supabase
      .from('payments')
      .select('id')
      .eq('asaas_payment_id', payment.id)
      .single();
    
    if (findError && findError.code !== 'PGRST116') {
      throw findError;
    }
    
    if (existingPayment) {
      // Atualizar pagamento existente
      const { error } = await supabase
        .from('payments')
        .update({
          status,
          payment_date: status === 'confirmed' ? new Date().toISOString() : null,
          updated_at: new Date().toISOString()
        })
        .eq('asaas_payment_id', payment.id);
      
      if (error) throw error;
      console.log(`Pagamento ${payment.id} atualizado para ${status}`);
    } else {
      // Buscar o usuário pelo ID do cliente no Asaas
      const { data: userProfile, error: userError } = await supabase
        .from('profiles')
        .select('id')
        .eq('asaas_customer_id', payment.customer)
        .single();
      
      if (userError) throw userError;
      
      // Criar novo registro de pagamento
      const { error } = await supabase
        .from('payments')
        .insert({
          user_id: userProfile.id,
          payment_method: payment.billingType,
          amount: payment.value,
          description: payment.description,
          status,
          due_date: payment.dueDate,
          payment_date: status === 'confirmed' ? new Date().toISOString() : null,
          asaas_payment_id: payment.id,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
      
      if (error) throw error;
      console.log(`Novo pagamento ${payment.id} registrado com status ${status}`);
    }
  } catch (error) {
    console.error('Erro ao atualizar pagamento:', error);
    throw error;
  }
}

async function updateSubscriptionStatus(subscriptionId, status) {
  try {
    const { error } = await supabase
      .from('subscriptions')
      .update({
        status,
        updated_at: new Date().toISOString()
      })
      .eq('asaas_subscription_id', subscriptionId);
    
    if (error) throw error;
    console.log(`Assinatura ${subscriptionId} atualizada para ${status}`);
  } catch (error) {
    console.error('Erro ao atualizar assinatura:', error);
    throw error;
  }
}

// Iniciar o servidor
app.listen(PORT, () => {
  console.log(`Servidor webhook rodando na porta ${PORT}`);
}); 