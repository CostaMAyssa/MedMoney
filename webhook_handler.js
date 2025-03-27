// Webhook Handler para o MedMoney
// Este script processa notificações do Asaas e atualiza o Supabase

const express = require('express');
const bodyParser = require('body-parser');
const { createClient } = require('@supabase/supabase-js');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();
const axios = require('axios');
const cors = require('cors');

// Importar o módulo de integração com n8n
const n8nWebhook = require('./n8n_webhook');

const app = express();
const PORT = process.env.PORT || 82;
const HOSTNAME = process.env.HOSTNAME || '0.0.0.0';
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://rwotvxqknrjurqrhxhjv.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const ASAAS_API_KEY = process.env.ASAAS_API_KEY;
const ASAAS_API_URL = process.env.ASAAS_API_URL || 'https://sandbox.asaas.com/api/v3';
const IS_DEVELOPMENT = process.env.NODE_ENV === 'development';
const SITE_URL = process.env.SITE_URL || 'https://medmoney.me';

// Verificar se estamos em ambiente de produção ou desenvolvimento
const isProduction = process.env.NODE_ENV === 'production';

// Logs para depuração em ambiente de desenvolvimento
console.log(`Ambiente: ${isProduction ? 'Produção' : 'Desenvolvimento'}`);
console.log(`URL da API Asaas: ${ASAAS_API_URL}`);
console.log(`URL do Supabase: ${SUPABASE_URL}`);
console.log(`URL do site: ${SITE_URL}`);

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

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Middleware para CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Middleware para processar JSON
app.use(bodyParser.json());

// Middleware para logging
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// Rota para health check
app.get('/health', async (req, res) => {
  const supabaseStatus = await testSupabaseConnection();
  res.json({ 
    status: supabaseStatus ? 'ok' : 'error',
    supabase: supabaseStatus ? 'connected' : 'error',
    timestamp: new Date().toISOString()
  });
});

// Rota para receber webhooks do Asaas
app.post('/api/webhook/asaas', async (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] Webhook recebido`);
  
  try {
    const event = req.body;
    
    // Validar payload
    if (!event || !event.event) {
      console.error('Payload inválido:', event);
      return res.status(400).json({ 
        error: 'Payload inválido',
        timestamp: new Date().toISOString()
      });
    }
    
    console.log('Payload do webhook:', JSON.stringify(event, null, 2));

    // Registrar o webhook no Supabase
    let webhookId;
    try {
      const { data, error } = await supabase
        .from('asaas_logs')
        .insert({
          event_type: event.event,
          webhook_data: event,
          processed: false,
          created_at: new Date().toISOString()
        })
        .select('id')
        .single();

      if (error) {
        console.error('Erro ao registrar webhook no Supabase:', error);
        throw error;
      }
      
      webhookId = data.id;
      console.log('Webhook registrado no Supabase com sucesso');
    } catch (logError) {
      console.error('Erro ao registrar log:', logError);
      throw logError;
    }

    // Verificar o tipo de evento
    let handled = false;
    switch (event.event) {
      case 'PAYMENT_RECEIVED':
        await handlePaymentReceived(event.payment);
        handled = true;
        break;
      case 'PAYMENT_CONFIRMED':
        await handlePaymentConfirmed(event.payment);
        handled = true;
        break;
      case 'PAYMENT_OVERDUE':
        await handlePaymentOverdue(event.payment);
        handled = true;
        break;
      case 'PAYMENT_DELETED':
      case 'PAYMENT_REFUNDED':
      case 'PAYMENT_CANCELED':
        await handlePaymentCanceled(event.payment);
        handled = true;
        break;
      case 'SUBSCRIPTION_CREATED':
        await handleSubscriptionCreated(event.subscription);
        handled = true;
        break;
      case 'SUBSCRIPTION_RENEWED':
        await handleSubscriptionRenewed(event.subscription);
        handled = true;
        break;
      case 'SUBSCRIPTION_CANCELED':
        await handleSubscriptionCanceled(event.subscription);
        handled = true;
        break;
      default:
        console.log(`Evento não processado: ${event.event}`);
    }

    // Atualizar o status do webhook para processado
    if (handled) {
      try {
        const { error } = await supabase
          .from('asaas_logs')
          .update({ processed: true })
          .eq('id', webhookId);

        if (error) {
          console.error('Erro ao atualizar status do webhook:', error);
          throw error;
        }
        
        console.log('Status do webhook atualizado com sucesso');
      } catch (updateError) {
        console.error('Erro ao atualizar status:', updateError);
        throw updateError;
      }
    }

    // Responder com sucesso
    res.status(200).json({ 
      success: true,
      message: 'Webhook processado com sucesso',
      event_type: event.event,
      handled,
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

// Rota para criar um cliente no Asaas
app.post('/api/create-customer', async (req, res) => {
  try {
    console.log('Recebida requisição para criar cliente:', JSON.stringify(req.body));
    const { name, email, cpfCnpj, phone, address } = req.body;
    
    // Validar campos obrigatórios
    if (!name || !email || !cpfCnpj) {
      console.log('Dados incompletos:', { name, email, cpfCnpj });
      return res.status(400).json({
        error: 'Dados incompletos',
        message: 'Nome, email e CPF/CNPJ são obrigatórios',
        timestamp: new Date().toISOString()
      });
    }
    
    // Em ambiente de produção, sempre enviar para o Asaas
    // Em desenvolvimento, verificar se a chave existe
    if (isProduction || ASAAS_API_KEY) {
      console.log('Enviando requisição para o Asaas (produção)...');
      console.log('URL:', `${ASAAS_API_URL}/customers`);
      
      // Enviar requisição para o Asaas (produção)
      const response = await axios.post(`${ASAAS_API_URL}/customers`, {
        name,
        email,
        cpfCnpj: cpfCnpj.replace(/\D/g, ''),
        phone,
        address: address?.street,
        addressNumber: address?.number,
        complement: address?.complement,
        province: address?.neighborhood,
        postalCode: address?.postalCode,
        externalReference: req.body.userId, // ID do usuário no seu sistema
        notificationDisabled: false
      }, {
        headers: {
          'Content-Type': 'application/json',
          'access_token': ASAAS_API_KEY
        }
      });
      
      console.log('Resposta do Asaas:', response.status);
      console.log('Dados da resposta:', JSON.stringify(response.data));
      
      // Se o cliente foi criado com sucesso, atualizar o perfil no Supabase
      if (response.data && response.data.id) {
        const { error } = await supabase
          .from('profiles')
          .update({
            asaas_customer_id: response.data.id,
            updated_at: new Date().toISOString()
          })
          .eq('id', req.body.userId);
          
        if (error) {
          console.error('Erro ao atualizar perfil:', error);
          // Não retornar erro, apenas logar
        }
      }
      
      return res.status(200).json({
        success: true,
        customer: response.data,
        timestamp: new Date().toISOString()
      });
    } else {
      console.log('Ambiente de desenvolvimento. Retornando cliente simulado.');
      const mockCustomer = {
        id: 'cus_000' + Math.floor(Math.random() * 1000000),
        name,
        email,
        cpfCnpj,
        phone,
        mobilePhone: phone,
        address: address?.street,
        addressNumber: address?.number,
        complement: address?.complement,
        province: address?.neighborhood,
        postalCode: address?.postalCode,
        externalReference: req.body.userId,
        notificationDisabled: false,
        dateCreated: new Date().toISOString()
      };
      
      // Também registramos no log de webhooks para ter um histórico
      try {
        await supabase.from('asaas_logs').insert({
          event_type: 'CUSTOMER_CREATED',
          webhook_data: mockCustomer,
          processed: true,
          created_at: new Date().toISOString()
        });
        console.log('Cliente simulado registrado no log de webhooks.');
      } catch (e) {
        console.error('Erro ao registrar cliente simulado no log:', e);
      }
      
      return res.status(200).json({
        success: true,
        customer: mockCustomer,
        timestamp: new Date().toISOString(),
        simulated: true
      });
    }
    
  } catch (error) {
    console.error('Erro ao criar cliente no Asaas:', error.response?.data || error.message);
    console.error('Stack trace:', error.stack);
    return res.status(500).json({
      error: 'Erro ao criar cliente',
      message: error.response?.data?.errors || error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Rota para criar um pagamento (cobrança)
app.post('/api/create-payment', async (req, res) => {
  try {
    const {
      customerId,
      value,
      billingType,
      description,
      dueDate,
      userId
    } = req.body;
    
    // Validar campos obrigatórios
    if (!customerId || !value || !billingType) {
      return res.status(400).json({
        error: 'Dados incompletos',
        message: 'ID do cliente, valor e tipo de cobrança são obrigatórios',
        timestamp: new Date().toISOString()
      });
    }
    
    console.log('Enviando requisição para o Asaas...');
    console.log('URL:', `${ASAAS_API_URL}/payments`);
    
    // Estruturando os dados conforme documentação do Asaas
    const paymentData = {
      customer: customerId,
      billingType: billingType, // PIX, BOLETO, CREDIT_CARD, etc
      value: value,
      dueDate: dueDate || new Date().toISOString().split('T')[0],
      description: description || 'Pagamento MedMoney',
      externalReference: userId || null,
      // Campos específicos para PIX
      ...(billingType === 'PIX' && {
        discount: {
          value: 0,
          dueDateLimitDays: 0
        },
        interest: {
          value: 0
        },
        fine: {
          value: 0
        },
        postalService: false
      })
    };
    
    // Em ambiente de desenvolvimento, retornar sucesso simulado
    if (process.env.NODE_ENV === 'development' || !ASAAS_API_KEY) {
      console.log('Ambiente de desenvolvimento. Retornando pagamento simulado.');
      console.log('Dados que seriam enviados:', JSON.stringify(paymentData));
      
      // Definir URL de pagamento baseado no tipo de cobrança
      let invoiceUrl = null;
      let status = 'PENDING';
      
      if (billingType === 'PIX') {
        invoiceUrl = 'https://sandbox.asaas.com/i/' + Math.random().toString(36).substring(2, 10);
        
        // Dados do PIX para desenvolvimento
        const mockPayment = {
          id: 'pay_' + Math.floor(Math.random() * 1000000),
          customer: customerId,
          value: value,
          netValue: value,
          billingType: billingType,
          status: status,
          dueDate: dueDate || new Date().toISOString().split('T')[0],
          description: description || 'Pagamento MedMoney',
          invoiceUrl: invoiceUrl,
          invoiceNumber: String(Math.floor(Math.random() * 100000)),
          externalReference: userId,
          deleted: false,
          postalService: false,
          dateCreated: new Date().toISOString()
        };
        
        // Gerar dados do QR code PIX
        const mockPixData = {
          encodedImage: 'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAMAAABrrFhUAAAABlBMVEX///8AAABVwtN+AAAF/UlEQVR4nO2dW5LsKAxEtf+/PmfwI+LeDrCFRCKVWXXHRN8qUJakBJ/Pzs7Ozs7Ozs7Ozs5f5PXy/Drw7/jj5/XA87e1Q358P1Wf98CvFSXg9YXP6/VQjuS1vgSM0lkCHrJbCMSAqzXotwKMB+LXr7HoFc+vNa9h9nuvGKgK1AsQCRDXbk0b5eD1jY9B8nPbXQJOgkzAnNYvLbgHmPxYL2GkJAJECYgCgOVA18J4HcSaXwOCBKRGTPL4nqpFSC2IWU8HXeaQhSQCkAaEEY8WnIPZ91eB5MnEAPKhVH0vJCmhkMICMBGQCJCvxmhvK/QgSUDsDVIfJgKidrcQELTwJQlQFaCuhQak5wcJ8DXAtSBmQCZgBzIB8fuJgHdX4DpRhL+hg1MIOt8tgJoOigasGU7BvRXgkrAjoGJPkPhYgLpXaKkCKQfdmQN7JeA0INoNnwdIGpC8QBwFpOpf1IKXAGwFfCMQCXg9rIGYGUC/FwyQlkSJL2gAB+Cth2fGnQnw1b+lgdgIqPcA3Hng5QWYF/CzHXdcC6s6aHc7IAqwkoD0/EKAN6LhfA+I1f+wEwBXA0zCIQVSE5YkQE0EuhYDpx2Iat9vB5oaaHmA5APiUBASECOQtYAaUNEAGIFnBaAH4MYFJAGYuAqoB+DHEeDcfpKAtgAmYdTBbgpgAeY1oDcDTOzJI1EoBNIb4D4haMBIwGgGqOugaPWHBsYzQTENXAtpRGaEB0Bd/PsrMJKAE+ApgDoQtTzA1P9sBAaNgNcCbkl4LoH+hRvkP58IvLqCKAGvdlBtBXTvQMOghoDvnQpAAlECJPAvlICsAYMWVN3fFYiK/I4KQBpokzBUgFbg9XBPwJ4GFnqANwJOA9YOOB1sjoL10dBmAVg/D0wdwZwNbGkgqMA8AdUU0AXYE2CtBk8J+FXwtwLeFAwNYAqyOaGLRyXgW3EPGGgYB+pWAAzAS8LeCMQUvCnB/K4YZAOxHRyQcHD/LoEwDXB9cOsFqVdNVQ1EvZ9X4Pb7AQVGRgCTqd6hwK0VqHnBMQLXQ/AIc4/A9RD8UPX+ywIkGVTXBE8VgCdKQH8/uJkCRhjQgPGCUIDxPeFFAVIXxFaAeoJBgZkRkB3BtAYOEwAjUCMAj0SxH4wE4NMlIBEgS8BAAJBAOeHHAsgORCdQCvDz/1ABsRGUErA9Eb4qQFwRbiRgCZAPSvNBQQKyBpICLAlADXhdHo4SkCTAjQHoAU4HwwvSGnCaE5AagVIBWvW/ZMCmBBgfULTgyHlASYG4EYAXJgJsGlCsQPEBZwmYNoC7gdSGcXF0NAKpBdQmRAqkHvjYeWCrgloCYAJiBMCBkxHIClBygFkNnBXAU0HPDWT1L4fFZyMwfRwfaMB0RThbARyCaAmAYYDXA6INgAPgE0FCtwTwVHC6E6hUwGnCiQB5LiDPCt2LU02Qdx5I08HJNWD1gTgPkDh+JFrXQPQANyMY3Z84C0gXRqMEtC5QPGD6MwH5mZjYBqY2AJaEuBoYuicGJGDsAvEsqDgZLK8JFQnAQSDZEXseCG5AdgPnxsQHR8SnXBKVFUA/gFHACeB3YlqsQJGAugL9kmiZEM4kIKwJ0dXRmgD6pGg0AqMCUwHqgZA2IWppIFoBuxpcCDCdDuICUFSAJCDGAO2BGC+MfSkBbRXgJcBrhJMPKAaAUXC7BpTCxwiAH3RLQnQtQB2K0BZALycHs3+fB3gvuCpAuz/OGiBmoAyLTUuC9/egHrjyAnEI7NOA/P0ZDYjNcJEAOSXqRqAswKQGuF8TgPvG8BI0fkPQfEKoJwDoAX0B9DQAj6MKqFpQVgBW/YgHvAgoZmB+JI7AJGAvCcsKgPKnVxTKBaiXRQkJqAmAJ8JrPpAkYDYaHhiQCDinAmjAfRYYe6Hog7IBoQAzGyArQN0MJAlgtwiA+/n80KKwuB8kAJaBKAEXGjBdHe9rYMUFBgagAbujgZvt4N9OQBaC8QPsn/8dXGNnZ2dnZ2dnZ2dn5+fyF7zlU+Vg0n2pAAAAAElFTkSuQmCC',
          payload: 'pix://https://sandbox.asaas.com/i/' + Math.random().toString(36).substring(2, 10),
          expirationDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        };
        
        mockPayment.pix = mockPixData;
        
        // Registrar no log
        try {
          await supabase.from('asaas_logs').insert({
            event_type: 'PAYMENT_CREATED',
            webhook_data: mockPayment,
            processed: true,
            created_at: new Date().toISOString()
          });
          console.log('Pagamento simulado registrado no log de webhooks.');
        } catch (e) {
          console.error('Erro ao registrar pagamento simulado no log:', e);
        }
        
        return res.status(200).json({
          success: true,
          payment: mockPayment,
          timestamp: new Date().toISOString(),
          simulated: true
        });
      }
      
      // Para outros tipos de pagamento
      // ... existing code para outros tipos de pagamento ...
    }
    
    // Enviar requisição para o Asaas (produção)
    console.log('Enviando dados reais para o Asaas:', JSON.stringify(paymentData));
    
    const response = await axios.post(`${ASAAS_API_URL}/payments`, paymentData, {
      headers: {
        'Content-Type': 'application/json',
        'access_token': ASAAS_API_KEY
      }
    });
    
    console.log('Resposta do Asaas:', response.status);
    console.log('Dados da resposta:', JSON.stringify(response.data));
    
    // Se for PIX, buscar o QR code
    if (billingType === 'PIX' && response.data && response.data.id) {
      try {
        const pixResponse = await axios.get(`${ASAAS_API_URL}/payments/${response.data.id}/pixQrCode`, {
          headers: {
            'Content-Type': 'application/json',
            'access_token': ASAAS_API_KEY
          }
        });
        
        if (pixResponse.data) {
          response.data.pix = pixResponse.data;
        }
      } catch (pixError) {
        console.error('Erro ao obter QR code PIX:', pixError.response?.data || pixError.message);
      }
    }
    
    // Registrar o pagamento no Supabase
    if (response.data && response.data.id) {
      try {
        // Registrar o log
        const { error: logError } = await supabase
          .from('asaas_logs')
          .insert({
            event_type: 'PAYMENT_CREATED',
            webhook_data: response.data,
            processed: true,
            created_at: new Date().toISOString()
          });
          
        if (logError) {
          console.error('Erro ao registrar log de pagamento:', logError);
        }
        
        // Aqui você pode adicionar código para salvar o pagamento em seu banco de dados se necessário
        
      } catch (dbError) {
        console.error('Erro ao registrar pagamento no banco:', dbError);
      }
    }
    
    return res.status(200).json({
      success: true,
      payment: response.data,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Erro ao criar pagamento no Asaas:', error.response?.data || error.message);
    console.error('Stack trace:', error.stack);
    return res.status(500).json({
      error: 'Erro ao criar pagamento',
      message: error.response?.data?.errors || error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Rota para criar uma assinatura
app.post('/api/create-subscription', async (req, res) => {
  try {
    const {
      customerId,
      value,
      billingType,
      cycle,
      description,
      nextDueDate,
      userId,
      planId
    } = req.body;
    
    // Validar campos obrigatórios
    if (!customerId || !value || !billingType || !cycle) {
      console.log('Dados incompletos:', { customerId, value, billingType, cycle });
      return res.status(400).json({
        error: 'Dados incompletos',
        message: 'ID do cliente, valor, ciclo e tipo de cobrança são obrigatórios',
        timestamp: new Date().toISOString()
      });
    }
    
    console.log('Enviando requisição para o Asaas...');
    console.log('URL:', `${ASAAS_API_URL}/subscriptions`);
    
    // Preparar dados para a API do Asaas conforme documentação
    const subscriptionData = {
      customer: customerId,
      billingType: billingType, // PIX, BOLETO, CREDIT_CARD
      value: value,
      nextDueDate: nextDueDate || new Date().toISOString().split('T')[0],
      cycle: cycle, // MONTHLY, YEARLY
      description: description || 'Assinatura MedMoney',
      ...(userId && { externalReference: userId }),
      ...((billingType === 'PIX' || billingType === 'BOLETO') && {
        discount: {
          value: 0,
          dueDateLimitDays: 0
        },
        interest: {
          value: 0
        },
        fine: {
          value: 0
        }
      })
    };
    
    // Em ambiente de desenvolvimento, retornar sucesso simulado
    if (process.env.NODE_ENV === 'development' || !ASAAS_API_KEY) {
      console.log('Ambiente de desenvolvimento. Retornando assinatura simulada.');
      console.log('Dados que seriam enviados:', JSON.stringify(subscriptionData));
      
      // Definir URL de pagamento baseado no tipo de cobrança
      let invoiceUrl = null;
      let status = 'ACTIVE';
      
      if (billingType === 'PIX' || billingType === 'BOLETO') {
        invoiceUrl = 'https://sandbox.asaas.com/i/' + Math.random().toString(36).substring(2, 10);
      }
      
      // Calcular próxima data de cobrança
      const today = new Date();
      const nextDate = nextDueDate ? new Date(nextDueDate) : new Date();
      if (cycle === 'MONTHLY') {
        nextDate.setMonth(today.getMonth() + 1);
      } else if (cycle === 'YEARLY') {
        nextDate.setFullYear(today.getFullYear() + 1);
      }
      
      const mockSubscription = {
        id: 'sub_' + Math.floor(Math.random() * 1000000),
        customer: customerId,
        value: value,
        nextDueDate: nextDate.toISOString().split('T')[0],
        billingType: billingType,
        cycle: cycle,
        description: description || 'Assinatura MedMoney',
        status: status,
        externalReference: userId,
        dateCreated: new Date().toISOString(),
        invoiceUrl: invoiceUrl
      };
      
      // Gerar um QR code PIX fictício para facilitar os testes
      if (billingType === 'PIX') {
        const mockPixData = {
          encodedImage: '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',
          payload: 'pix://https://sandbox.asaas.com/i/' + Math.random().toString(36).substring(2, 10),
          expirationDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        };
        
        mockSubscription.pix = mockPixData;
      }
      
      // Também registramos no log de webhooks para ter um histórico
      try {
        await supabase.from('asaas_logs').insert({
          event_type: 'SUBSCRIPTION_CREATED',
          webhook_data: mockSubscription,
          processed: true,
          created_at: new Date().toISOString()
        });
        console.log('Assinatura simulada registrada no log de webhooks.');
      } catch (e) {
        console.error('Erro ao registrar assinatura simulada no log:', e);
      }
      
      // Criar registro na tabela de assinaturas
      try {
        // Criar assinatura
        const { error: subError } = await supabase
          .from('subscriptions')
          .insert({
            user_id: userId,
            plan_id: planId,
            plan_name: description || 'Assinatura MedMoney',
            plan_type: cycle === 'YEARLY' ? 'annual' : 'monthly',
            price: value,
            status: 'pending',
            start_date: new Date().toISOString(),
            next_billing_date: nextDate.toISOString(),
            asaas_subscription_id: mockSubscription.id,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          });
          
        if (subError) {
          console.error('Erro ao criar assinatura no banco:', subError);
        } else {
          console.log('Assinatura criada no banco de dados com sucesso.');
        }
      } catch (dbError) {
        console.error('Erro ao registrar assinatura no banco:', dbError);
      }
      
      // Simular geração de cobrança (pagamento) para esta assinatura
      try {
        // Para assinaturas com PIX, já vamos criar um pagamento simulado
        if (billingType === 'PIX') {
          const mockPayment = {
            id: 'pay_' + Math.floor(Math.random() * 1000000),
            subscription: mockSubscription.id,
            customer: customerId,
            value: value,
            netValue: value,
            billingType: billingType,
            status: 'PENDING',
            dueDate: nextDueDate || new Date().toISOString().split('T')[0],
            description: description || 'Assinatura MedMoney',
            invoiceUrl: invoiceUrl,
            externalReference: userId,
            deleted: false,
            postalService: false,
            dateCreated: new Date().toISOString()
          };
          
          // Adicionar dados do PIX
          mockPayment.pix = mockSubscription.pix;
          
          await supabase.from('asaas_logs').insert({
            event_type: 'PAYMENT_CREATED',
            webhook_data: mockPayment,
            processed: true,
            created_at: new Date().toISOString()
          });
          
          console.log('Pagamento de assinatura simulado registrado no log.');
          
          // Adicionar o pagamento à resposta para facilitar o acesso ao QR code
          mockSubscription.firstPayment = mockPayment;
        }
      } catch (paymentError) {
        console.error('Erro ao criar pagamento simulado para assinatura:', paymentError);
      }
      
      return res.status(200).json({
        success: true,
        subscription: mockSubscription,
        timestamp: new Date().toISOString(),
        simulated: true
      });
    }
    
    // Enviar requisição para o Asaas (produção)
    console.log('Enviando dados reais para o Asaas:', JSON.stringify(subscriptionData));
    
    const response = await axios.post(`${ASAAS_API_URL}/subscriptions`, subscriptionData, {
      headers: {
        'Content-Type': 'application/json',
        'access_token': ASAAS_API_KEY
      }
    });
    
    console.log('Resposta do Asaas:', response.status);
    console.log('Dados da resposta:', JSON.stringify(response.data));
    
    // Se o tipo de pagamento for PIX, verificar se já temos um primeiro pagamento
    // e recuperar o QR code PIX para ele
    if (response.data && response.data.id && billingType === 'PIX') {
      try {
        // Buscar os pagamentos desta assinatura
        const paymentsResponse = await axios.get(`${ASAAS_API_URL}/subscriptions/${response.data.id}/payments`, {
          headers: {
            'Content-Type': 'application/json',
            'access_token': ASAAS_API_KEY
          }
        });
        
        if (paymentsResponse.data && paymentsResponse.data.data && paymentsResponse.data.data.length > 0) {
          const firstPayment = paymentsResponse.data.data[0];
          
          // Buscar o QR code PIX do primeiro pagamento
          const pixResponse = await axios.get(`${ASAAS_API_URL}/payments/${firstPayment.id}/pixQrCode`, {
            headers: {
              'Content-Type': 'application/json',
              'access_token': ASAAS_API_KEY
            }
          });
          
          if (pixResponse.data) {
            // Adicionar os dados do primeiro pagamento com QR code PIX à resposta
            response.data.firstPayment = {
              ...firstPayment,
              pix: pixResponse.data
            };
          }
        }
      } catch (paymentError) {
        console.error('Erro ao buscar pagamento ou QR code PIX:', paymentError.response?.data || paymentError.message);
      }
    }
    
    // Registrar a assinatura no Supabase
    if (response.data && response.data.id) {
      try {
        // Registrar o log
        const { error: logError } = await supabase
          .from('asaas_logs')
          .insert({
            event_type: 'SUBSCRIPTION_CREATED',
            webhook_data: response.data,
            processed: true,
            created_at: new Date().toISOString()
          });
          
        if (logError) {
          console.error('Erro ao registrar log de assinatura:', logError);
        }
        
        // Criar registro na tabela de assinaturas
        const { error: subError } = await supabase
          .from('subscriptions')
          .insert({
            user_id: userId,
            plan_id: planId,
            plan_name: description || 'Assinatura MedMoney',
            plan_type: cycle === 'YEARLY' ? 'annual' : 'monthly',
            price: value,
            status: 'pending',
            start_date: new Date().toISOString(),
            next_billing_date: nextDueDate || new Date().toISOString(),
            asaas_subscription_id: response.data.id,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          });
          
        if (subError) {
          console.error('Erro ao criar assinatura no banco:', subError);
        }
      } catch (dbError) {
        console.error('Erro ao registrar assinatura no banco:', dbError);
      }
    }
    
    return res.status(200).json({
      success: true,
      subscription: response.data,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Erro ao criar assinatura no Asaas:', error.response?.data || error.message);
    console.error('Stack trace:', error.stack);
    return res.status(500).json({
      error: 'Erro ao criar assinatura',
      message: error.response?.data?.errors || error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Rota para obter QR code PIX para uma assinatura
app.get('/api/subscription/:id/pix', async (req, res) => {
  try {
    const subscriptionId = req.params.id;
    
    console.log(`Buscando QR Code PIX para a assinatura ${subscriptionId}`);
    
    // Em ambiente de produção, sempre enviar para o Asaas
    // Em desenvolvimento, verificar se a chave existe
    if (isProduction || ASAAS_API_KEY) {
      console.log('Obtendo QR code PIX do Asaas...');
      
      try {
        // Buscar informações da assinatura
        const subscriptionResponse = await axios.get(`${ASAAS_API_URL}/subscriptions/${subscriptionId}`, {
          headers: {
            'Content-Type': 'application/json',
            'access_token': ASAAS_API_KEY
          }
        });
        
        // Se a assinatura tem um pagamento associado, buscar o QR code PIX desse pagamento
        if (subscriptionResponse.data && subscriptionResponse.data.nextPayment) {
          const paymentId = subscriptionResponse.data.nextPayment;
          
          // Buscar o QR code PIX do pagamento
          const pixResponse = await axios.get(`${ASAAS_API_URL}/payments/${paymentId}/pixQrCode`, {
            headers: {
              'Content-Type': 'application/json',
              'access_token': ASAAS_API_KEY
            }
          });
          
          if (pixResponse.data) {
            return res.status(200).json({
              success: true,
              pixQrCode: pixResponse.data,
              subscription_id: subscriptionId,
              payment_id: paymentId,
              timestamp: new Date().toISOString()
            });
          }
        }
        
        // Se não encontrou um pagamento ou QR code, retornar erro
        return res.status(404).json({
          error: 'QR Code PIX não encontrado',
          message: 'Não foi possível encontrar um QR Code PIX para esta assinatura',
          timestamp: new Date().toISOString()
        });
      } catch (asaasError) {
        console.error('Erro ao obter QR code PIX do Asaas:', asaasError.response?.data || asaasError.message);
        return res.status(500).json({
          error: 'Erro ao obter QR Code PIX',
          message: asaasError.response?.data?.errors || asaasError.message,
          timestamp: new Date().toISOString()
        });
      }
    } else {
      console.log('Ambiente de desenvolvimento. Retornando QR Code PIX simulado.');
      // ... existing code para simulação ...
    }
  } catch (error) {
    console.error('Erro ao obter QR Code PIX:', error);
    return res.status(500).json({
      error: 'Erro ao obter QR Code PIX',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Adicionar rotas para integração com n8n
n8nWebhook.addN8nRoutes(app, { supabase });

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
    // Simplificação máxima: apenas registrar o evento como JSON
    const { data, error } = await supabase
      .from('asaas_logs')
        .insert({
        event_type: `PAYMENT_${status.toUpperCase()}`,
        webhook_data: payment,
        processed: true,
        created_at: new Date().toISOString()
        });
      
      if (error) throw error;
    
    console.log(`Evento de pagamento ${payment.id} com status ${status} registrado com sucesso`);
    return true;
  } catch (error) {
    console.error('Erro ao registrar evento de pagamento:', error);
    throw error;
  }
}

async function updateSubscriptionStatus(subscriptionId, status) {
  try {
    // Simplificação máxima: apenas registrar o evento como JSON
    const { data, error } = await supabase
      .from('asaas_logs')
      .insert({
        event_type: `SUBSCRIPTION_${status.toUpperCase()}`,
        webhook_data: { id: subscriptionId, status: status },
        processed: true,
        created_at: new Date().toISOString()
      });
    
    if (error) throw error;
    
    console.log(`Assinatura ${subscriptionId} atualizada para ${status}`);
    return true;
  } catch (error) {
    console.error('Erro ao atualizar status da assinatura:', error);
    throw error;
  }
}

// Testar conexão com o Supabase
async function testSupabaseConnection() {
  try {
    const { data, error } = await supabase.from('asaas_logs').select('count').limit(1);
    if (error) throw error;
    console.log('Conexão com o Supabase estabelecida com sucesso!');
    return true;
  } catch (error) {
    console.error('Erro ao conectar com o Supabase:', error);
    return false;
  }
}

// Iniciar o servidor
(async () => {
  try {
    // Testar conexão com o Supabase antes de iniciar
    const connected = await testSupabaseConnection();
    if (!connected) {
      console.error('Não foi possível conectar ao Supabase. Encerrando...');
      process.exit(1);
    }
    
    app.listen(PORT, HOSTNAME, () => {
      console.log(`Servidor webhook rodando na porta ${PORT}`);
      console.log(`Health check: http://${HOSTNAME}:${PORT}/health`);
      console.log(`Webhook URL: ${SITE_URL}/api/webhook/asaas`);
    });
  } catch (error) {
    console.error('Erro ao iniciar servidor:', error);
    process.exit(1);
  }
})(); 