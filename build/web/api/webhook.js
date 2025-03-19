// Webhook handler para notificações do Asaas
// Este arquivo foi projetado para ser implantado em um ambiente serverless como Vercel ou Netlify

export default async function handler(req, res) {
  // Permitir apenas método POST
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método não permitido' });
  }

  try {
    // Obter os dados do webhook do Asaas
    const webhookData = req.body;
    
    // Registrar os dados do webhook para depuração
    console.log('Webhook do Asaas recebido:', JSON.stringify(webhookData, null, 2));

    // Você pode adicionar lógica de processamento adicional aqui
    // Por exemplo, atualizar um banco de dados, enviar notificações, etc.
    
    // Normalmente você faria:
    // 1. Verificar a assinatura do webhook (se o Asaas fornecer uma)
    // 2. Processar confirmações de pagamento
    // 3. Lidar com falhas de pagamento
    // 4. Processar eventos de assinatura
    // 5. Atualizar seu banco de dados de acordo

    // Por enquanto, apenas reconheceremos o recebimento
    return res.status(200).json({ 
      success: true, 
      message: 'Webhook processado com sucesso',
      received: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erro ao processar webhook:', error);
    return res.status(500).json({ 
      error: 'Erro Interno do Servidor',
      message: error.message 
    });
  }
} 