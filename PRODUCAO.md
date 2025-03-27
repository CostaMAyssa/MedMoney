# Configuração para Produção do MedMoney

Este documento descreve os passos necessários para colocar o MedMoney em produção.

## 1. Configurar o Backend (Webhook Asaas)

### Opção 1: Deploy no Vercel

1. Instale o Vercel CLI:
   ```bash
   npm install -g vercel
   ```

2. Faça login no Vercel:
   ```bash
   vercel login
   ```

3. Configure os segredos no Vercel:
   ```bash
   vercel secrets add supabase_url "sua_url_supabase"
   vercel secrets add supabase_service_role_key "sua_chave_supabase"
   vercel secrets add asaas_api_key "sua_chave_asaas"
   vercel secrets add asaas_api_url "https://api.asaas.com/v3"
   ```

4. Faça o deploy:
   ```bash
   vercel
   ```

5. Quando perguntado, confirme as configurações. O Vercel identificará automaticamente o arquivo `vercel.json`.

6. Após o deploy, anote a URL gerada pelo Vercel (por exemplo: `https://medmoney-webhook.vercel.app`).

### Opção 2: Deploy no Heroku

1. Instale o Heroku CLI e faça login:
   ```bash
   npm install -g heroku
   heroku login
   ```

2. Crie um app no Heroku:
   ```bash
   heroku create medmoney-webhook
   ```

3. Configure as variáveis de ambiente:
   ```bash
   heroku config:set SUPABASE_URL="sua_url_supabase"
   heroku config:set SUPABASE_SERVICE_ROLE_KEY="sua_chave_supabase"
   heroku config:set ASAAS_API_KEY="sua_chave_asaas"
   heroku config:set ASAAS_API_URL="https://api.asaas.com/v3"
   heroku config:set NODE_ENV="production"
   ```

4. Crie um arquivo `Procfile` na raiz do projeto:
   ```
   web: node webhook_handler.js
   ```

5. Faça o deploy:
   ```bash
   git add .
   git commit -m "Preparando para produção"
   git push heroku main
   ```

6. Anote a URL gerada pelo Heroku (por exemplo: `https://medmoney-webhook.herokuapp.com`).

## 2. Configurar o Asaas

1. Acesse sua conta Asaas em https://www.asaas.com/
2. Vá para "Configurações" > "Integrações" > "Notificações Webhook"
3. Adicione um novo webhook com a URL do seu servidor:
   ```
   https://sua-url-do-servidor/api/webhook/asaas
   ```
4. Selecione todos os eventos que deseja receber (pagamentos, assinaturas, etc.)
5. Salve as configurações

## 3. Atualizar o App Flutter

1. Edite o arquivo `lib/services/asaas_service.dart` e atualize a URL do servidor:
   ```dart
   String webhookBaseUrl = 'https://sua-url-do-servidor';
   ```

2. Substitua em todos os lugares:
   ```dart
   webhookBaseUrl = 'https://sua-api-producao.herokuapp.com';
   ```
   
   por:
   ```dart
   webhookBaseUrl = 'https://sua-url-do-servidor'; // URL do Vercel ou Heroku
   ```

3. Gere uma versão de produção do app Flutter:
   ```bash
   flutter build web --release
   ```

4. Faça o deploy da versão web em um serviço como Firebase Hosting, Netlify, ou Vercel.

## 4. Testar a Integração

1. Acesse a aplicação web
2. Faça login e tente realizar uma assinatura
3. Verifique nos logs do servidor se a requisição está chegando corretamente
4. Verifique no Asaas se os registros estão sendo criados

## 5. Solução de Problemas

Se encontrar problemas durante o deploy ou a execução:

1. Verifique os logs do servidor:
   - No Vercel: `vercel logs`
   - No Heroku: `heroku logs --tail`

2. Certifique-se de que as variáveis de ambiente estão configuradas corretamente

3. Teste as rotas do webhook com ferramentas como Postman ou Insomnia

4. Verifique a conectividade entre o Asaas, seu webhook e o Supabase

## 6. Outras Considerações

- **Segurança**: Considere adicionar autenticação às rotas do webhook para maior segurança
- **Monitoramento**: Configure alertas para monitorar o servidor
- **Backup**: Implemente uma rotina de backup para os dados do Supabase 