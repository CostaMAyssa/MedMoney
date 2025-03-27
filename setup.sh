#!/bin/bash
# Script de instalação MedMoney

echo "Iniciando instalação do MedMoney..."

# Atualizar repositórios
echo "Atualizando repositórios..."
sudo apt update
sudo apt upgrade -y

# Instalar dependências
echo "Instalando dependências..."
sudo apt install -y nginx
sudo apt install -y curl
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2

# Criar diretórios
echo "Criando diretórios..."
sudo mkdir -p /var/www/medmoney
sudo mkdir -p /var/www/webhook

# Extrair arquivos da aplicação web
echo "Extraindo arquivos da aplicação web..."
sudo tar -xzvf medmoney_web.tar.gz -C /var/www/medmoney

# Copiar arquivos do webhook
echo "Configurando webhook..."
sudo cp webhook_handler.js /var/www/webhook/
sudo cp package.json /var/www/webhook/

# Criar arquivo .env a partir do exemplo
echo "Criando arquivo .env..."
sudo cp .env.example /var/www/webhook/.env
echo "IMPORTANTE: Edite o arquivo /var/www/webhook/.env com suas credenciais!"

# Instalar dependências do webhook
echo "Instalando dependências do webhook..."
cd /var/www/webhook
sudo npm install

# Configurar Nginx
echo "Configurando Nginx..."
sudo bash -c 'cat > /etc/nginx/sites-available/medmoney << EOL
server {
    listen 80;
    server_name medmoney.me;

    location / {
        root /var/www/medmoney;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:82;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL'

# Ativar configuração Nginx
sudo ln -s /etc/nginx/sites-available/medmoney /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Iniciar webhook com PM2
echo "Iniciando webhook com PM2..."
cd /var/www/webhook
sudo pm2 start webhook_handler.js --name medmoney-webhook
sudo pm2 save
sudo pm2 startup

# Verificar se o webhook está funcionando
echo "Verificando webhook..."
curl http://localhost:82/health

echo "Instalação concluída!"
echo "Agora você pode acessar o MedMoney em http://medmoney.me"
echo "LEMBRE-SE de configurar seu DNS para apontar medmoney.me para o IP desta máquina"
