# Configuração do Webhook do Asaas - MedMoney

Este documento contém instruções detalhadas para configurar o webhook do Asaas após a publicação do projeto MedMoney. Esta etapa é essencial para que os pagamentos sejam processados corretamente e as assinaturas sejam ativadas automaticamente.

## Pré-requisitos

- Conta no Asaas (Sandbox para testes ou Produção)
- Aplicativo MedMoney publicado em um servidor com URL acessível externamente
- Acesso ao painel administrativo do Asaas

## Passos para Configuração

### 1. Preparar o Servidor para Receber Webhooks

O MedMoney já vem com um servidor de webhook embutido, que precisa ser iniciado quando o aplicativo estiver em execução. Para garantir que ele esteja funcionando:

```bash
# Verificar se as dependências estão instaladas
cd /caminho/para/medmoney
npm install

# Iniciar o servidor de webhook (em produção, você deve usar um process manager como o PM2)
node start_webhook.js
```

### 2. Configurar o Webhook no Painel do Asaas

1. Acesse o painel do Asaas: [https://www.asaas.com/login](https://www.asaas.com/login)
2. Após o login, vá para **Configurações > API > Webhooks**
3. Clique em **Adicionar Webhook**
4. Preencha os seguintes campos:
   - **URL**: `https://seu-dominio.com/api/webhook/asaas` (substitua pelo seu domínio real)
   - **Descrição**: "Webhook do MedMoney"
   - **Eventos**: Selecione os seguintes eventos:
     - PAYMENT_RECEIVED (Pagamento recebido)
     - PAYMENT_CONFIRMED (Pagamento confirmado)
     - PAYMENT_OVERDUE (Pagamento atrasado)
     - PAYMENT_DELETED (Pagamento removido)
     - PAYMENT_REFUNDED (Pagamento estornado)
     - PAYMENT_CANCELED (Pagamento cancelado)
     - SUBSCRIPTION_CREATED (Assinatura criada)
     - SUBSCRIPTION_RENEWED (Assinatura renovada)
     - SUBSCRIPTION_CANCELED (Assinatura cancelada)
5. Clique em **Salvar**

### 3. Testar o Webhook

Para garantir que o webhook está funcionando corretamente:

1. Use o script de teste fornecido no projeto:

```bash
# Definir a URL do seu webhook
export WEBHOOK_URL=https://seu-dominio.com/api/webhook/asaas

# Executar o teste
node test_webhook.js
```

2. Verifique se o evento de teste foi registrado na tabela `asaas_logs` no Supabase:

```sql
SELECT * FROM asaas_logs ORDER BY created_at DESC LIMIT 1;
```

3. Também é possível enviar um evento de teste diretamente do painel do Asaas:
   - Acesse **Configurações > API > Webhooks**
   - Encontre o webhook configurado
   - Clique no botão "..." e selecione "Testar"
   - Selecione o tipo de evento (exemplo: PAYMENT_RECEIVED)
   - Clique em "Enviar"

### 4. Configuração no Ambiente de Produção

Para o ambiente de produção, é importante garantir:

1. **HTTPS**: A URL do webhook DEVE utilizar HTTPS para segurança.
2. **Disponibilidade**: O servidor deve estar sempre disponível para receber eventos do Asaas.
3. **Monitoramento**: Configure alertas para ser notificado se o servidor de webhook ficar indisponível.

### 5. Solução de Problemas

Se estiver enfrentando problemas com o webhook:

1. **Verifique os logs**: Execute `node webhook_handler.js` e observe os logs quando um evento é enviado.
2. **Verifique a conectividade**: Confirme se a URL do webhook é acessível externamente.
3. **Verifique o firewall**: Certifique-se de que a porta do webhook está aberta (padrão: 3000).
4. **Verifique o banco de dados**: Confirme se as credenciais do Supabase estão corretas no arquivo `.env`.

### 6. Considerações de Segurança

Para aumentar a segurança do seu webhook:

1. **Token de Autenticação**: Implemente um token de autenticação para validar se a requisição vem realmente do Asaas.
2. **Rate Limiting**: Implemente um limite de requisições para prevenir ataques de DoS.
3. **Validação de Payload**: Sempre valide o payload recebido antes de processá-lo.

## Recursos Adicionais

- [Documentação de Webhooks do Asaas](https://asaasdev.atlassian.net/wiki/spaces/API/pages/592510977/Webhooks)
- [Guia de Solução de Problemas MedMoney](./TROUBLESHOOTING.md) 