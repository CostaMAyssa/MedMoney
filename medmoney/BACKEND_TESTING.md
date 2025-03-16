# Guia de Testes do Backend do MedMoney

Este documento fornece instruções detalhadas para testar todas as funcionalidades do backend do MedMoney.

## Pré-requisitos

Antes de iniciar os testes, certifique-se de que:

1. O Supabase está configurado corretamente (ver `SUPABASE_SETUP.md`)
2. O arquivo `.env` contém as credenciais corretas:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_KEY`
   - `ASAAS_API_KEY`
   - `ASAAS_SANDBOX=true`
   - `PORT=3000`
3. Todas as dependências estão instaladas:
   ```
   npm install
   ```

## 1. Teste Automatizado do Backend

O MedMoney inclui um script de teste automatizado que verifica todas as funcionalidades principais do backend:

1. Autenticação e acesso ao dashboard
2. Gestão de planos e assinaturas
3. Processamento de pagamentos
4. Controle financeiro
5. Segurança e performance

Para executar o teste automatizado:

```bash
npm run test-backend
```

O script criará usuários de teste, assinaturas, pagamentos e transações, e verificará se tudo está funcionando corretamente. Ao final, ele limpará os dados de teste.

## 2. Teste do Webhook

O webhook é responsável por receber notificações do Asaas e atualizar o banco de dados do Supabase. Para testá-lo:

### 2.1. Iniciar o Webhook

Primeiro, inicie o servidor webhook:

```bash
npm run start-webhook
```

### 2.2. Executar o Teste do Webhook

Em outro terminal, execute o script de teste do webhook:

```bash
npm run test-webhook
```

Este script enviará eventos simulados para o webhook e verificará se eles são processados corretamente.

### 2.3. Configurar o Webhook no Asaas

Para tornar o webhook acessível pela internet e configurá-lo no Asaas:

```bash
npm run webhook
```

Este comando iniciará o webhook e criará um túnel usando o localtunnel, fornecendo uma URL pública que pode ser configurada no Asaas.

## 3. Testes Manuais

Além dos testes automatizados, é recomendável realizar testes manuais para verificar a experiência do usuário.

### 3.1. Autenticação e Acesso ao Dashboard

1. Crie um novo usuário através da tela de registro
2. Faça login com o usuário criado
3. Tente acessar o dashboard sem uma assinatura ativa (deve ser redirecionado)
4. Assine um plano Premium e verifique se consegue acessar o dashboard

### 3.2. Gestão de Planos e Assinaturas

1. Visualize os planos disponíveis
2. Assine um plano mensal
3. Verifique se a assinatura foi criada corretamente
4. Cancele a assinatura e verifique se o status foi atualizado

### 3.3. Processamento de Pagamentos

1. Realize um pagamento via PIX
2. Verifique se o QR code é gerado corretamente
3. Simule a confirmação do pagamento (usando o webhook)
4. Verifique se o status da assinatura é atualizado

### 3.4. Controle Financeiro

1. Crie uma transação de receita
2. Crie uma transação de despesa
3. Verifique se as transações aparecem no histórico
4. Crie uma categoria personalizada
5. Crie uma transação com a categoria personalizada

### 3.5. Segurança e Performance

1. Tente acessar dados de outro usuário (deve ser bloqueado)
2. Verifique o tempo de resposta das requisições
3. Teste o acesso ao dashboard com diferentes status de assinatura

## 4. Solução de Problemas

### 4.1. Erro no Teste do Backend

Se o teste do backend falhar, verifique:

- As credenciais do Supabase no arquivo `.env`
- Se as tabelas foram criadas corretamente no Supabase
- Os logs de erro no console

### 4.2. Erro no Teste do Webhook

Se o teste do webhook falhar, verifique:

- Se o servidor webhook está rodando
- Se a porta 3000 está disponível
- Se o localtunnel está funcionando corretamente

### 4.3. Erro no Acesso ao Dashboard

Se o acesso ao dashboard falhar, verifique:

- Se o usuário tem uma assinatura ativa
- Se o pagamento foi confirmado
- Se o plano é do tipo Premium

## 5. Logs e Monitoramento

Para monitorar o funcionamento do backend:

1. Verifique os logs do console durante a execução dos testes
2. Acesse o painel do Supabase para verificar os dados no banco
3. Acesse o painel do Asaas para verificar os pagamentos e assinaturas

## 6. Conclusão

Após executar todos os testes, você deve ter uma visão clara do funcionamento do backend do MedMoney. Se encontrar algum problema, consulte a documentação ou entre em contato com a equipe de desenvolvimento. 