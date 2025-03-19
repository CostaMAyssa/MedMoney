# Funções Edge do Supabase para MedMoney

Este diretório contém as funções Edge do Supabase usadas pelo aplicativo MedMoney.

## Função de Webhook do Asaas

A pasta `asaas-webhook` contém uma função Edge que processa notificações de webhook do Asaas para manter o banco de dados sincronizado com os eventos de pagamento.

### Implantação

Para implantar a função, siga estes passos:

1. Instale a CLI do Supabase:
   ```bash
   npm install -g supabase
   ```

2. Faça login na sua conta do Supabase:
   ```bash
   supabase login
   ```

3. Configure o projeto localmente:
   ```bash
   supabase init
   ```

4. Vincule ao seu projeto Supabase:
   ```bash
   supabase link --project-ref SEU_ID_DO_PROJETO
   ```

5. Implante a função:
   ```bash
   supabase functions deploy asaas-webhook --project-ref SEU_ID_DO_PROJETO
   ```

### Configuração no Painel do Supabase

1. No painel do Supabase, vá para "Functions" (Funções)
2. Selecione a função `asaas-webhook`
3. Vá para a guia "Settings" (Configurações)
4. Configure as seguintes variáveis de ambiente:
   - `SUPABASE_URL`: URL do seu projeto Supabase (ex: https://seuprojetoid.supabase.co)
   - `SUPABASE_SERVICE_ROLE_KEY`: Chave de serviço do seu projeto (encontrada em Project Settings > API)

### Configuração no Asaas

1. Faça login no painel do Asaas
2. Vá para Configurações > Integrações > Notificações
3. Adicione um novo webhook com a URL da sua função Edge:
   ```
   https://seuprojetoid.supabase.co/functions/v1/asaas-webhook
   ```
4. Selecione os eventos que deseja monitorar (recomendamos monitorar todos os eventos relacionados a pagamento)

### Tabelas Necessárias no Supabase

A função espera que existam as seguintes tabelas no seu banco de dados:

1. `payments` - Armazena informações sobre pagamentos
   - `id` (gerado pelo Supabase)
   - `external_id` (ID do pagamento no Asaas)
   - `customer_id` (ID do cliente no Asaas)
   - `value` (valor do pagamento)
   - `net_value` (valor líquido após taxas)
   - `billing_type` (tipo de cobrança)
   - `status` (status do pagamento)
   - `due_date` (data de vencimento)
   - `payment_date` (data de pagamento)
   - `client_payment_date` (data de pagamento pelo cliente)
   - `invoice_url` (URL da fatura)
   - `invoice_number` (número da fatura)
   - `external_reference` (referência externa)
   - `deleted` (status de exclusão)
   - `subscription_id` (ID da assinatura, se aplicável)
   - `event_type` (tipo de evento que gerou o registro)
   - `created_at` (data de criação)
   - `updated_at` (data de atualização)

2. `subscriptions` - Armazena informações sobre assinaturas
   - `id` (gerado pelo Supabase)
   - `external_id` (ID da assinatura no Asaas)
   - `user_id` (ID do usuário no Supabase)
   - `status` (status da assinatura)
   - `value` (valor da assinatura)
   - `next_due_date` (próxima data de vencimento)
   - `last_payment_date` (data do último pagamento)
   - `created_at` (data de criação)
   - `updated_at` (data de atualização)
   - Outros campos relevantes para sua aplicação

Você pode criar estas tabelas usando o Editor SQL no painel do Supabase. 