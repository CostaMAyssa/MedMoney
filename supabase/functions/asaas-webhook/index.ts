// supabase/functions/asaas-webhook/index.ts

// Importamos o cliente do Supabase
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.33.1'

// Tipos para as notificações do Asaas
interface AsaasWebhookPayment {
  id: string;
  event: string;
  payment: {
    id: string;
    customer: string;
    value: number;
    netValue: number;
    billingType: string;
    status: string;
    dueDate: string;
    paymentDate?: string;
    clientPaymentDate?: string;
    invoiceUrl?: string;
    invoiceNumber?: string;
    externalReference?: string;
    deleted: boolean;
    dateCreated: string;
    subscription?: string;
  };
}

// Função para processar o webhook
Deno.serve(async (req) => {
  try {
    // Verificar o método HTTP
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Método não permitido' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Obter os dados do webhook
    const webhookData = await req.json();
    
    // Registros para depuração
    console.log('Webhook do Asaas recebido:', JSON.stringify(webhookData, null, 2));
    
    // Criar cliente Supabase usando variáveis de ambiente
    // Essas variáveis serão configuradas no dashboard do Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
    
    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Variáveis de ambiente do Supabase não configuradas');
    }
    
    const supabase = createClient(supabaseUrl, supabaseKey);
    
    // Processar diferentes tipos de eventos
    // Aqui definimos a lógica para cada tipo de evento do Asaas
    switch (webhookData.event) {
      case 'PAYMENT_CREATED':
      case 'PAYMENT_UPDATED':
      case 'PAYMENT_CONFIRMED':
      case 'PAYMENT_RECEIVED':
      case 'PAYMENT_OVERDUE':
      case 'PAYMENT_DELETED':
        await processPaymentEvent(webhookData, supabase);
        break;
        
      default:
        console.log(`Evento não processado: ${webhookData.event}`);
        break;
    }
    
    // Responder com sucesso
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Webhook processado com sucesso',
        received: new Date().toISOString()
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('Erro ao processar webhook:', error);
    
    return new Response(
      JSON.stringify({
        error: 'Erro interno do servidor',
        message: error.message
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});

// Função para processar eventos de pagamento
async function processPaymentEvent(data: AsaasWebhookPayment, supabase: any) {
  try {
    // Verificar se já existe uma registro com esse ID de pagamento
    const { data: existingPayment } = await supabase
      .from('payments')
      .select('id')
      .eq('external_id', data.payment.id)
      .maybeSingle();
    
    const paymentData = {
      external_id: data.payment.id,
      customer_id: data.payment.customer,
      value: data.payment.value,
      net_value: data.payment.netValue,
      billing_type: data.payment.billingType,
      status: data.payment.status,
      due_date: data.payment.dueDate,
      payment_date: data.payment.paymentDate || null,
      client_payment_date: data.payment.clientPaymentDate || null,
      invoice_url: data.payment.invoiceUrl || null,
      invoice_number: data.payment.invoiceNumber || null,
      external_reference: data.payment.externalReference || null,
      deleted: data.payment.deleted,
      subscription_id: data.payment.subscription || null,
      event_type: data.event,
      updated_at: new Date().toISOString()
    };
    
    if (existingPayment) {
      // Atualizar pagamento existente
      const { error } = await supabase
        .from('payments')
        .update(paymentData)
        .eq('external_id', data.payment.id);
        
      if (error) throw error;
      console.log(`Pagamento atualizado: ${data.payment.id}`);
    } else {
      // Inserir novo pagamento
      const { error } = await supabase
        .from('payments')
        .insert({
          ...paymentData,
          created_at: new Date().toISOString()
        });
        
      if (error) throw error;
      console.log(`Novo pagamento registrado: ${data.payment.id}`);
    }
    
    // Se for pagamento de assinatura, atualizar a assinatura também
    if (data.payment.subscription) {
      await updateSubscriptionFromPayment(data, supabase);
    }
    
  } catch (error) {
    console.error('Erro ao processar evento de pagamento:', error);
    throw error;
  }
}

// Função para atualizar assinatura com base no pagamento
async function updateSubscriptionFromPayment(data: AsaasWebhookPayment, supabase: any) {
  if (!data.payment.subscription) return;
  
  try {
    // Buscar a assinatura pelo ID externo
    const { data: subscription } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('external_id', data.payment.subscription)
      .maybeSingle();
    
    if (!subscription) {
      console.log(`Assinatura não encontrada: ${data.payment.subscription}`);
      return;
    }
    
    // Atualizar status da assinatura com base no evento do pagamento
    let newStatus = subscription.status;
    
    if (data.event === 'PAYMENT_RECEIVED' || data.event === 'PAYMENT_CONFIRMED') {
      newStatus = 'active';
    } else if (data.event === 'PAYMENT_OVERDUE') {
      newStatus = 'overdue';
    }
    
    // Atualizar a assinatura
    const { error } = await supabase
      .from('subscriptions')
      .update({
        status: newStatus,
        last_payment_date: data.payment.paymentDate || data.payment.clientPaymentDate,
        updated_at: new Date().toISOString()
      })
      .eq('external_id', data.payment.subscription);
      
    if (error) throw error;
    console.log(`Assinatura atualizada: ${data.payment.subscription}`);
    
  } catch (error) {
    console.error('Erro ao atualizar assinatura:', error);
    throw error;
  }
} 