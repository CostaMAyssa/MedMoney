# Checklist de Instalação e Configuração - MedMoney

Use este checklist para garantir que todos os componentes necessários para o funcionamento do MedMoney estejam corretamente configurados.

## Configuração do Banco de Dados

- [ ] Conta no Supabase criada
- [ ] Projeto MedMoney criado no Supabase
- [ ] Script SQL executado com sucesso
- [ ] Tabela `profiles` criada e verificada
- [ ] Tabela `plans` criada e verificada
- [ ] Tabela `subscriptions` criada e verificada
- [ ] Tabela `asaas_logs` criada e verificada
- [ ] Planos padrão inseridos corretamente
- [ ] Funções e triggers para atualização de timestamps criados

## Configuração do Asaas

- [ ] Conta no Asaas criada
- [ ] API Key gerada com as permissões necessárias
- [ ] URL de redirecionamento após pagamento configurada
- [ ] Ambiente correto selecionado (sandbox para testes ou produção)
- [ ] Teste de pagamento realizado com sucesso

## Configuração do Webhook (APÓS PUBLICAÇÃO)

Esta etapa deverá ser realizada somente após a publicação do aplicativo:

- [ ] Servidor Node.js configurado para receber webhooks
- [ ] Dependências do webhook instaladas com `npm install`
- [ ] Webhook configurado no painel do Asaas apontando para a URL correta
- [ ] Eventos do webhook selecionados (Pagamento confirmado, recebido, etc.)
- [ ] Teste de webhook realizado com sucesso

Para instruções detalhadas sobre esta etapa, consulte o arquivo **WEBHOOK_SETUP.md**.

## Configuração do Aplicativo

- [ ] Arquivo `.env` criado com as variáveis necessárias:
  - [ ] SUPABASE_URL
  - [ ] SUPABASE_KEY
  - [ ] ASAAS_API_KEY
  - [ ] ASAAS_SANDBOX
  - [ ] WEBHOOK_PORT (será utilizado após a publicação)
- [ ] Dependências instaladas com `flutter pub get`
- [ ] Aplicativo compilado sem erros

## Testes de Integração

- [ ] Teste de registro de usuário realizado com sucesso
- [ ] Teste de login realizado com sucesso
- [ ] Teste de seleção de plano realizado com sucesso
- [ ] Teste de checkout no Asaas realizado com sucesso
- [ ] Status da assinatura atualizado para "active" manualmente (webhook será configurado após publicação)
- [ ] Usuário consegue visualizar seu plano contratado

## Verificações Finais

- [ ] Aplicativo acessível via web na URL configurada
- [ ] Todas as funcionalidades testadas em diferentes dispositivos
- [ ] Backup da configuração inicial realizado
- [ ] Documento de entrega para o cliente preparado

## Observações Importantes

1. Para ambiente de produção, garanta que:
   - [ ] HTTPS está configurado para todas as URLs
   - [ ] Variável ASAAS_SANDBOX está definida como `false`
   - [ ] Backup automático do banco de dados está configurado

2. Para ambiente de desenvolvimento/testes:
   - [ ] ASAAS_SANDBOX deve estar definido como `true`
   - [ ] Use URLs de teste para webhooks (ex: ngrok para testes locais)

## Próximos Passos Após Instalação

- [ ] Treinar os administradores do sistema
- [ ] Configurar políticas de backup regulares
- [ ] Estabelecer procedimento de monitoramento contínuo
- [ ] Documentar processo de atualização do sistema
- [ ] Configurar servidor de webhook conforme instruções no arquivo WEBHOOK_SETUP.md

## Guia passo a passo para você subir a build para o GitHub

Vou te fornecer os comandos exatos que você precisa executar no seu terminal:

### 1. Gere a build do aplicativo (se ainda não gerou):

```bash
cd /Users/mayssaferreira/Desktop/MedMoney/medmoney
flutter build web --release --base-href=/medmoney/
```

### 2. Inicialize o Git e adicione os arquivos:

```bash
# Inicializar Git (se ainda não inicializado)
git init

# Adicionar todos os arquivos
git add .

# Fazer o commit inicial
git commit -m "Versão inicial do MedMoney"
```

### 3. Crie um repositório no GitHub:
- Acesse [github.com/new](https://github.com/new)
- Nomeie o repositório como "medmoney"
- Deixe-o público
- Clique em "Create repository"

### 4. Conecte seu repositório local ao GitHub:

```bash
# Substitua 'seu-usuario' pelo seu nome de usuário GitHub
git remote add origin https://github.com/seu-usuario/medmoney.git

# Envie o código para o GitHub
git push -u origin main
```

### 5. Configure o GitHub Pages:

```bash
# Crie uma branch específica para o GitHub Pages
git checkout -b gh-pages

# Limpe tudo exceto a pasta build/web
git rm -rf --cached .

# Configure o arquivo .gitignore para o GitHub Pages
echo "*
!build/
build/*
!build/web/
!.gitignore" > .gitignore

# Adicione os arquivos da pasta build/web
git add .

# Faça o commit
git commit -m "Configuração do GitHub Pages"

# Envie para o GitHub
git push -u origin gh-pages
```

### 6. Ative o GitHub Pages:
- Acesse seu repositório no GitHub
- Vá para Settings > Pages
- Em "Source", selecione a branch "gh-pages"
- Clique em "Save"

Depois de alguns minutos, seu site estará disponível em:
```
https://seu-usuario.github.io/medmoney/
```

Você gostaria que eu detalhe algum desses passos mais especificamente?