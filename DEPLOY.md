# MedMoney Web App

Para implantar esta aplicação no servidor:

1. Faça o download do arquivo `medmoney_web.tar.gz`

2. No servidor, execute:

```bash
mkdir -p /var/www/medmoney
tar -xzvf medmoney_web.tar.gz -C /var/www/medmoney
```

3. Configure o Nginx conforme as instruções em WEBHOOK_SETUP.md

## Instruções para implantação na VPS

Para implantar esta aplicação na sua VPS, siga estes passos:

1. Faça login na sua VPS via SSH
2. Execute os seguintes comandos:

```bash
# Instalar dependências
sudo apt update
sudo apt install -y nginx
sudo apt install -y curl
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2

# Criar diretório para aplicação
sudo mkdir -p /var/www/medmoney
sudo mkdir -p /var/www/webhook

# Baixar e extrair aplicação web
cd /var/www/medmoney
sudo wget https://raw.githubusercontent.com/CostaMAyssa/MedMoney/gh-pages/medmoney_web.tar.gz
sudo tar -xzvf medmoney_web.tar.gz

# Baixar e configurar webhook
cd /var/www/webhook
sudo wget https://raw.githubusercontent.com/CostaMAyssa/MedMoney/gh-pages/webhook_handler.js
sudo wget https://raw.githubusercontent.com/CostaMAyssa/MedMoney/gh-pages/package.json

# Instalar dependências do webhook
sudo npm install

# Criar arquivo .env
sudo cat > /var/www/webhook/.env << EOL
PORT=82
HOSTNAME=0.0.0.0
NODE_ENV=production
SUPABASE_URL=https://rwotvxqknrjurqrhxhjv.supabase.co
SUPABASE_SERVICE_KEY=seu_service_key_aqui
ASAAS_API_KEY=sua_api_key_aqui
ASAAS_API_URL=https://www.asaas.com/api/v3
SITE_URL=https://medmoney.me
EOL

# Configurar Nginx
sudo cat > /etc/nginx/sites-available/medmoney << 'EOL'
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
EOL

# Ativar configuração e reiniciar Nginx
sudo ln -s /etc/nginx/sites-available/medmoney /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Iniciar webhook com PM2
cd /var/www/webhook
sudo pm2 start webhook_handler.js --name medmoney-webhook
sudo pm2 save
sudo pm2 startup

# Verificar se o webhook está funcionando
curl http://localhost:82/health
```

3. Configure seu DNS para apontar 'medmoney.me' para o IP da sua VPS

## Configuração HTTPS (opcional)

Para configurar HTTPS usando Let's Encrypt:

```bash
# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obter certificado SSL
sudo certbot --nginx -d medmoney.me

# Seguir instruções na tela
# Escolher redirecionamento automático de HTTP para HTTPS
```

O Certbot irá atualizar automaticamente a configuração do Nginx para usar HTTPS.

