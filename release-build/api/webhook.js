// Webhook handler para notificações do Asaas
// Este arquivo é um placeholder - na produção, use a função Edge do Supabase

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

    // NOTA: Este webhook é apenas um placeholder.
    // Na produção, use a função Edge do Supabase implementada em:
    // supabase/functions/asaas-webhook/index.ts
    
    // Por enquanto, apenas reconheceremos o recebimento
    return res.status(200).json({ 
      success: true, 
      message: 'Webhook processado com sucesso (placeholder)',
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