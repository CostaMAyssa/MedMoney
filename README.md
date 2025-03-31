# MedMoney - Configuração para VPS

Este repositório contém os arquivos necessários para configurar o MedMoney em sua VPS.

## Arquivos Importantes

- `webhook_handler.js` - Manipulador de webhook para processar pagamentos
- `medmoney.conf` - Arquivo de configuração do Nginx
- `.env.example` - Exemplo de variáveis de ambiente
- `.env` - Variáveis de ambiente configuradas
- `CNAME` - Configuração de domínio para GitHub Pages

## Passos para Configuração na VPS

1. **Configurar o Nginx**:
   ```
   sudo cp medmoney.conf /etc/nginx/conf.d/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

2. **Configurar o Webhook Handler**:
   ```
   # Instalar dependências
   npm install

   # Configurar variáveis de ambiente
   cp .env.example .env
   nano .env  # Editar com suas credenciais

   # Iniciar o webhook com PM2
   pm2 start webhook_handler.js
   pm2 save
   ```

3. **Verificar o funcionamento**:
   ```
   curl http://localhost:82/health
   ```

## Solução de Problemas

- Se encontrar problemas com o Nginx, verifique os logs: `sudo tail -f /var/log/nginx/error.log`
- Para problemas com o webhook: `pm2 logs webhook_handler` 