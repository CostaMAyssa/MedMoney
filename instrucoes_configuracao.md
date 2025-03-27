# Instruções para Configurar o MedMoney.me

## 1. Configurar o Nginx

1. Remova configurações antigas:
```bash
sudo rm /etc/nginx/sites-available/medmoney
sudo rm /etc/nginx/sites-enabled/medmoney
```

2. Crie um novo arquivo de configuração:
```bash
sudo nano /etc/nginx/sites-available/medmoney
```

3. Cole o conteúdo do arquivo `medmoney.conf` que criamos:
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name medmoney.me www.medmoney.me;

    root /var/www/medmoney;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

4. Ative a configuração:
```bash
sudo ln -s /etc/nginx/sites-available/medmoney /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 2. Configurar o Arquivo .env

1. Atualize o arquivo .env com as configurações corretas:
```bash
nano .env
```

2. Cole o conteúdo do nosso arquivo .env:
```
# Supabase
SUPABASE_URL=https://rwotvxqknrjurqrhxhjv.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3R2eHFrbnJqdXJxcmh4aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4OTI0MzIsImV4cCI6MjA1NzQ2ODQzMn0.RgrvQZ2ltMtxVFWkcO2fRD2ySSeYdvaHVmM7MNGZt_M
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3R2eHFrbnJqdXJxcmh4aGp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MTg5MjQzMiwiZXhwIjoyMDU3NDY4NDMyfQ.EICNdxtrx0bY_ZvBE_oUp_uXjewpkxTfOvb-TH42IRk
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3R2eHFrbnJqdXJxcmh4aGp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MTg5MjQzMiwiZXhwIjoyMDU3NDY4NDMyfQ.EICNdxtrx0bY_ZvBE_oUp_uXjewpkxTfOvb-TH42IRk

# Configurações do Asaas
ASAAS_API_KEY=d0c01479-e8e9-4d34-867b-7c4babdeb5ec
ASAAS_API_URL=https://sandbox.asaas.com/api/v3
ASAAS_SANDBOX=true

# Configuração do Webhook
PORT=3000
HOSTNAME=0.0.0.0
NODE_ENV=production
SITE_URL=https://medmoney.me

# Configuração do n8n
N8N_WEBHOOK_URL=https://n8n-n8n.cnbu8g.easypanel.host/webhook/3111eb7b-0cd3-4001-bf5f-63187043c76d
```

## 3. Atualizar o Código do Webhook Handler

1. Edite o arquivo webhook_handler.js:
```bash
nano webhook_handler.js
```

2. Localize o bloco que verifica as variáveis do Supabase (aproximadamente linha 115) e substitua por:
```javascript
// Verificar variáveis de ambiente do Supabase
if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.warn('Aviso: Verificando variáveis alternativas...');
  
  // Tentar usar SUPABASE_SERVICE_ROLE_KEY se SUPABASE_SERVICE_KEY não estiver definido
  if (!SUPABASE_SERVICE_KEY && process.env.SUPABASE_SERVICE_ROLE_KEY) {
    console.warn('Usando SUPABASE_SERVICE_ROLE_KEY como alternativa');
    SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
  } else {
    console.error('Erro: Variáveis de ambiente do Supabase não configuradas!');
    process.exit(1);
  }
}
```

## 4. Reiniciar Serviços

1. Reinicie o webhook com PM2:
```bash
pm2 stop medmoney-webhook
pm2 start webhook_handler.js --name medmoney-webhook --update-env
```

2. Verifique os logs:
```bash
pm2 logs medmoney-webhook
```

## 5. Certificado SSL (depois que o site estiver funcionando)

1. Instale o Certbot:
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

2. Obtenha o certificado SSL:
```bash
sudo certbot --nginx -d medmoney.me -d www.medmoney.me
```

3. Siga as instruções na tela para concluir o processo.

## Verificação

1. Verifique se o Nginx está funcionando:
```bash
sudo systemctl status nginx
```

2. Verifique se o webhook está rodando:
```bash
pm2 list
```

3. Teste o site em um navegador:
   - http://medmoney.me
   - https://medmoney.me (depois de configurar o SSL)

4. Teste o webhook:
```bash
curl -X POST http://localhost:3000/api/process-payment/n8n -H "Content-Type: application/json" -d '{"test": true}'
``` 