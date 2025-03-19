# Instruções de Deploy - MedMoney

Este documento contém instruções para publicar o MedMoney em um servidor VPN ou ambiente de produção.

## Pré-requisitos

- Acesso ao servidor ou ambiente de produção
- Git instalado no servidor
- Acesso ao repositório MedMoney no GitHub

## Opção 1: Deploy direto da branch (Recomendado)

1. Clone o repositório na VPN ou servidor:
   ```bash
   git clone https://github.com/CostaMAyssa/MedMoney.git
   cd MedMoney
   ```

2. Mude para a branch `amigo-vpn`:
   ```bash
   git checkout amigo-vpn
   ```

3. A pasta `release-build` contém todos os arquivos de build prontos para publicação. Copie estes arquivos para o diretório raiz do seu servidor web:
   ```bash
   cp -r release-build/* /caminho/para/diretorio/web/
   ```

4. Configure o servidor web (Apache, Nginx, etc.) para servir estes arquivos estáticos.

## Opção 2: Build local e deploy

Se preferir fazer uma build nova:

1. Clone o repositório:
   ```bash
   git clone https://github.com/CostaMAyssa/MedMoney.git
   cd MedMoney
   ```

2. Mude para a branch `amigo-vpn`:
   ```bash
   git checkout amigo-vpn
   ```

3. Instale as dependências:
   ```bash
   flutter pub get
   ```

4. Crie o arquivo `.env` com base no `.env.example`:
   ```bash
   cp .env.example .env
   # Edite o arquivo .env com os valores corretos
   ```

5. Construa a aplicação web:
   ```bash
   flutter build web --release
   ```

6. Copie os arquivos da build para o diretório web:
   ```bash
   cp -r build/web/* /caminho/para/diretorio/web/
   ```

## Configuração do Webhook

Para o processamento de pagamentos, configure o webhook no Asaas:

1. Acesse o painel do Asaas: https://www.asaas.com/
2. Vá para Configurações > Integrações > Notificações
3. Adicione um novo webhook com a URL do seu servidor:
   ```
   https://seu-dominio-vpn.com/api/webhook
   ```
   Ou, se estiver usando a função Edge do Supabase:
   ```
   https://seuprojetoid.supabase.co/functions/v1/asaas-webhook
   ```

## Teste de Funcionamento

Após a publicação:

1. Acesse o site pelo navegador para verificar se carrega corretamente
2. Faça login com uma conta de teste
3. Crie um pagamento de teste no Asaas
4. Verifique se o webhook está recebendo e processando as notificações corretamente

## Solução de Problemas

Se encontrar problemas:

1. Verifique os logs do servidor web
2. Verifique se o arquivo `.env` está configurado corretamente
3. Certifique-se de que o servidor tem permissões para acessar os arquivos
4. Verifique se o webhook está configurado com a URL correta 