# Guia Completo de Deploy do MedMoney na VPS

Este guia fornece instruções detalhadas para configurar o MedMoney em sua VPS.

## Pré-requisitos

- VPS com Ubuntu 20.04 ou superior
- Acesso SSH à VPS
- Domínio configurado para apontar para o IP da VPS
- Nginx instalado
- Node.js v16 ou superior instalado
- PM2 instalado globalmente

## Passos para Configuração

### 1. Preparar o Ambiente

```bash
# Atualizar o sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install -y nginx git curl

# Instalar Node.js 16
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar PM2 globalmente
sudo npm install -g pm2
```

### 2. Configurar o Diretório Web

```bash
# Criar diretório para o site
sudo mkdir -p /var/www/medmoney
sudo chown -R $USER:$USER /var/www/medmoney

# Clonar a branch gh-pages
git clone -b gh-pages https://github.com/CostaMayssa/MedMoney.git /tmp/medmoney
cp -r /tmp/medmoney/* /var/www/medmoney/
```

### 3. Configurar o Webhook

```bash
# Criar diretório para o webhook
mkdir -p ~/medmoney-webhook
cp /var/www/medmoney/webhook_handler.js ~/medmoney-webhook/
cp /var/www/medmoney/package.json ~/medmoney-webhook/
cp /var/www/medmoney/.env.example ~/medmoney-webhook/.env

# Instalar dependências
cd ~/medmoney-webhook
npm install

# Editar o arquivo .env com as configurações corretas
nano .env

# Iniciar o webhook com PM2
pm2 start webhook_handler.js
pm2 save
pm2 startup
```

### 4. Configurar o Nginx

```bash
# Copiar o arquivo de configuração
sudo cp /var/www/medmoney/medmoney.conf /etc/nginx/conf.d/

# Verificar a configuração do Nginx
sudo nginx -t

# Reiniciar o Nginx
sudo systemctl restart nginx
```

### 5. Configurar o Firewall

```bash
# Configurar o firewall para permitir HTTP e HTTPS
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 22
sudo ufw enable
```

### 6. Verificar a Configuração

```bash
# Verificar se o webhook está funcionando
curl http://localhost:3000/health

# Verificar se o Nginx está redirecionando corretamente
curl -I http://localhost/api/health
```

## Solução de Problemas

### Problemas com Nginx

```bash
# Verificar logs do Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Reiniciar o Nginx
sudo systemctl restart nginx
```

### Problemas com o Webhook

```bash
# Verificar logs do PM2
pm2 logs webhook_handler

# Reiniciar o webhook
pm2 restart webhook_handler
```

### Problemas de Permissão

```bash
# Verificar permissões do diretório web
sudo chown -R $USER:$USER /var/www/medmoney
sudo chmod -R 755 /var/www/medmoney
```

## Atualizações

Para atualizar o sistema após alterações no repositório:

```bash
# Atualizar o site
cd /var/www/medmoney
git pull

# Atualizar o webhook
cd ~/medmoney-webhook
git pull
npm install
pm2 restart webhook_handler
``` 