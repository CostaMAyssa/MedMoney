# Configuração do Webhook MedMoney

Este documento detalha o processo de configuração do webhook para o MedMoney. O webhook é responsável por processar notificações de pagamento do Asaas e atualizar o banco de dados Supabase.

## Requisitos

- Node.js 16 ou superior
- npm 
- Um servidor ou VPS com acesso à internet
- Nginx (para configuração de proxy reverso)
- PM2 (para gerenciamento de processos)

## Instalação na VPS

Siga os passos abaixo para configurar o webhook em seu servidor:

### 1. Instalar dependências necessárias

```bash
# Atualizar repositórios
sudo apt update
sudo apt upgrade -y

# Instalar Node.js e npm (se ainda não estiverem instalados)
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar PM2 para gerenciar o processo
sudo npm install -g pm2

# Instalar Nginx
sudo apt install -y nginx
```

### 2. Configurar o Nginx

Crie um arquivo de configuração para o site:

```bash
sudo nano /etc/nginx/sites-available/medmoney
```

Adicione o seguinte conteúdo (substitua medmoney.me pelo seu domínio):

```nginx
server {
    listen 80;
    server_name medmoney.me;

    location / {
        root /var/www/medmoney;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:82;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Ative a configuração e reinicie o Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/medmoney /etc/nginx/sites-enabled/
sudo nginx -t  # Verificar se a configuração está correta
sudo systemctl restart nginx
```

### 3. Configurar o webhook

Crie um diretório para o webhook:

```bash
mkdir -p /var/www/webhook
cd /var/www/webhook
```

Copie os arquivos `webhook_handler.js`, `package.json` e `.env` para este diretório.

Instale as dependências:

```bash
npm install
```

### 4. Configurar variáveis de ambiente

Crie um arquivo `.env` com as seguintes variáveis:

```bash
nano .env
```

Adicione este conteúdo (substitua os valores com suas credenciais):

```
PORT=82
HOSTNAME=0.0.0.0
NODE_ENV=production
SUPABASE_URL=https://rwotvxqknrjurqrhxhjv.supabase.co
SUPABASE_SERVICE_KEY=sua_chave_de_servico_do_supabase
ASAAS_API_KEY=sua_chave_de_api_do_asaas
ASAAS_API_URL=https://www.asaas.com/api/v3
SITE_URL=https://medmoney.me
```

### 5. Iniciar o webhook com PM2

```bash
pm2 start webhook_handler.js --name medmoney-webhook
pm2 save
pm2 startup  # Siga as instruções para configurar o PM2 para iniciar com o sistema
```

### 6. Verificar se está funcionando

```bash
curl http://localhost:82/health
```

Você deve receber uma resposta indicando que o webhook está funcionando e conectado ao Supabase.

## Configuração da aplicação Flutter

Na aplicação Flutter, certifique-se de que as seguintes variáveis estão configuradas para usar a URL correta:

- Em `lib/services/asaas_service.dart`: Todas as referências a webhookBaseUrl devem apontar para `https://medmoney.me` (sem a porta)
- Em `lib/providers/payment_provider.dart`: Todas as referências a webhookBaseUrl devem apontar para `https://medmoney.me` (sem a porta)

## Atualização de webhooks no Asaas

Caso esteja utilizando webhooks do Asaas, atualize o URL no painel administrativo do Asaas para usar `https://medmoney.me/api/webhook/asaas` (sem a porta).

## Resolução de problemas

Se o webhook não estiver funcionando corretamente, verifique:

1. Os logs do PM2:
   ```bash
   pm2 logs medmoney-webhook
   ```

2. Se o Nginx está redirecionando corretamente:
   ```bash
   sudo nginx -t
   sudo tail -f /var/log/nginx/error.log
   ```

3. Se as variáveis de ambiente estão configuradas corretamente:
   ```bash
   cat .env
   ```

4. Se a porta 82 está sendo usada por algum outro serviço:
   ```bash
   sudo lsof -i :82
   ```

5. Se o firewall está permitindo o tráfego:
   ```bash
   sudo ufw status
   sudo ufw allow 80/tcp
   ``` 