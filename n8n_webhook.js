// Integracao com n8n webhook para MedMoney
// Este arquivo deve ser importado no webhook_handler.js

const axios = require('axios');

/**
 * Envia dados do usuário e plano para o n8n e recupera a URL de pagamento
 * @param {Object} data - Dados do usuário e plano
 * @param {string} data.name - Nome do usuário
 * @param {string} data.email - Email do usuário
 * @param {string} data.cpfCnpj - CPF/CNPJ do usuário
 * @param {string} data.phone - Telefone do usuário
 * @param {Object} data.plan - Dados do plano escolhido
 * @param {string} data.plan.name - Nome do plano
 * @param {number} data.plan.value - Valor do plano
 * @param {string} data.plan.cycle - Ciclo de cobrança (MONTHLY, YEARLY)
 * @param {string} data.billingType - Tipo de pagamento (CREDIT_CARD, PIX)
 * @returns {Promise<Object>} - Resposta contendo a URL de pagamento
 */
async function sendToN8nWebhook(data) {
  try {
    // URL do webhook do n8n (configure no arquivo .env)
    const n8nWebhookUrl = process.env.N8N_WEBHOOK_URL;
    
    if (!n8nWebhookUrl) {
      console.error('URL do webhook do n8n não configurada no .env');
      throw new Error('Configuração de webhook n8n ausente');
    }
    
    console.log(`Enviando dados para n8n: ${JSON.stringify(data)}`);
    
    // Enviar dados para o n8n via POST
    const response = await axios.post(n8nWebhookUrl, data);
    
    console.log(`Resposta do n8n: ${JSON.stringify(response.data)}`);
    
    // Verificar se a resposta contém a URL de pagamento
    if (!response.data || !response.data.paymentUrl) {
      console.warn('Resposta do n8n não contém URL de pagamento:', response.data);
      
      // Implementar fallback para casos onde o n8n não retorna a URL
      // Aqui você poderia implementar uma lógica para gerar URL de fallback
      
      return {
        success: false,
        message: 'URL de pagamento não encontrada na resposta do n8n',
        paymentUrl: null,
        data: response.data
      };
    }
    
    return {
      success: true,
      paymentUrl: response.data.paymentUrl,
      data: response.data
    };
  } catch (error) {
    console.error('Erro ao enviar dados para webhook do n8n:', error.message);
    
    return {
      success: false,
      message: `Erro ao processar pagamento: ${error.message}`,
      paymentUrl: null,
      error: error.message
    };
  }
}

/**
 * Adiciona rota para processar dados via n8n
 * @param {Express} app - Aplicação Express
 * @param {Object} options - Opções adicionais
 */
function addN8nRoutes(app, options = {}) {
  // Rota para processar pagamento via n8n
  app.post('/api/process-payment/n8n', async (req, res) => {
    try {
      const {
        name,
        email,
        cpfCnpj,
        phone,
        planId,
        userId,
        billingType
      } = req.body;
      
      // Validar campos obrigatórios
      if (!name || !email || !cpfCnpj || !planId || !userId || !billingType) {
        return res.status(400).json({
          success: false,
          message: 'Dados incompletos. Todos os campos são obrigatórios.'
        });
      }
      
      // Recuperar informações do plano do banco de dados
      const { supabase } = options;
      
      if (!supabase) {
        throw new Error('Cliente Supabase não fornecido');
      }
      
      const { data: planData, error: planError } = await supabase
        .from('plans')
        .select('*')
        .eq('id', planId)
        .single();
        
      if (planError || !planData) {
        console.error('Erro ao buscar dados do plano:', planError);
        return res.status(404).json({
          success: false,
          message: 'Plano não encontrado'
        });
      }
      
      // Preparar dados para enviar ao n8n
      const paymentData = {
        user: {
          name,
          email,
          cpfCnpj,
          phone,
          id: userId
        },
        plan: {
          id: planId,
          name: planData.name,
          value: planData.value,
          cycle: planData.cycle
        },
        billingType
      };
      
      // Enviar para o webhook do n8n
      const result = await sendToN8nWebhook(paymentData);
      
      // Registrar a tentativa no log do Supabase
      await supabase.from('n8n_logs').insert({
        user_id: userId,
        plan_id: planId,
        request_data: paymentData,
        response_data: result,
        success: result.success,
        created_at: new Date().toISOString()
      });
      
      if (!result.success) {
        return res.status(500).json({
          success: false,
          message: result.message || 'Erro ao processar pagamento',
          error: result.error
        });
      }
      
      return res.json({
        success: true,
        paymentUrl: result.paymentUrl,
        data: result.data
      });
    } catch (error) {
      console.error('Erro no processamento do pagamento via n8n:', error);
      return res.status(500).json({ 
        success: false, 
        message: 'Erro interno no servidor',
        error: error.message 
      });
    }
  });
  
  console.log('Rotas de integração com n8n configuradas com sucesso');
}

module.exports = {
  sendToN8nWebhook,
  addN8nRoutes
};
