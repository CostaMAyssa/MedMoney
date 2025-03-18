# Manual de Configuração do MedMoney

Este manual fornece instruções passo a passo para configurar corretamente o sistema MedMoney, incluindo a configuração do banco de dados Supabase e a integração com o Asaas para pagamentos.

## 1. Configuração do Banco de Dados Supabase

### 1.1 Executando os Scripts SQL

1. Acesse o painel do Supabase: https://app.supabase.io
2. Selecione seu projeto MedMoney
3. Vá para "SQL Editor" no menu lateral
4. Clique em "New Query"
5. Copie e cole o conteúdo do arquivo `supabase_setup.sql` fornecido
6. Clique em "Run" para executar o script
7. Verifique se não houve erros na execução

### 1.2 Verificar as Tabelas Criadas

Após executar o script, verifique se as seguintes tabelas foram criadas:

1. `profiles` - Perfis de usuários
2. `plans` - Planos disponíveis
3. `subscriptions` - Assinaturas dos usuários
4. `asaas_logs` - Logs de eventos do Asaas

## 2. Configuração da Integração com Asaas

### 2.1 Configuração do .env

Crie ou edite um arquivo `.env` na raiz do projeto com as seguintes informações:

```
SUPABASE_URL=sua_url_do_supabase
SUPABASE_KEY=sua_chave_anon_key_do_supabase
ASAAS_API_KEY=sua_chave_api_do_asaas
ASAAS_SANDBOX=true_ou_false
WEBHOOK_PORT=3000
```

Substitua os valores acima pelos dados corretos.

### 2.2 Configuração no Painel do Asaas

No painel do Asaas, você precisa configurar:

1. **Webhook:**
   - Acesse Configurações > Integrações > Webhook
   - Adicione um webhook com a URL: `https://seu-dominio.com/api/webhook/asaas`
   - Selecione os eventos: Pagamento confirmado, Pagamento recebido, Pagamento atrasado

2. **URL de Redirecionamento:**
   - Acesse Configurações > Preferências
   - Configure a URL de redirecionamento após pagamento: `https://seu-dominio.com/payment/success`

## 3. Execução da Aplicação

### 3.1 Instalação de Dependências

Execute os seguintes comandos para instalar as dependências:

```
flutter pub get
```

### 3.2 Inicialização da Aplicação

Execute a aplicação com:

```
flutter run
```

## 4. Verificação da Integração

Após concluir toda a configuração, faça um teste completo:

1. Registre um novo usuário
2. Selecione um plano para assinar
3. Complete o pagamento no checkout do Asaas
4. Verifique se o webhook está sendo recebido
5. Confirme se o status da assinatura é atualizado corretamente

## 5. Resolução de Problemas

### 5.1 Problemas com o Webhook

Se os webhooks não estiverem sendo recebidos:

- Verifique se a URL do webhook está correta
- Confirme se o servidor está acessível externamente
- Verifique os logs na tabela `asaas_logs`

### 5.2 Problemas com Pagamentos

Se houver problemas com pagamentos:

- Verifique a chave de API do Asaas no arquivo `.env`
- Confirme se está usando o ambiente correto (sandbox ou produção)
- Verifique os logs do aplicativo para mensagens de erro específicas

Para qualquer outro problema, entre em contato com o suporte técnico. 