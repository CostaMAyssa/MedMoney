# Configuração do Backend do MedMoney

Este documento contém instruções para configurar o backend do aplicativo MedMoney, que utiliza Supabase para banco de dados e autenticação, e Asaas para processamento de pagamentos.

## Pré-requisitos

- Conta no [Supabase](https://supabase.com)
- Conta no [Asaas](https://www.asaas.com)
- Node.js (versão 18 ou superior)

## Configuração do Supabase

### 1. Criar um projeto no Supabase

1. Acesse [supabase.com](https://supabase.com) e faça login
2. Clique em "New Project"
3. Preencha os detalhes do projeto:
   - Nome: MedMoney
   - Senha do banco de dados: crie uma senha forte
   - Região: escolha a mais próxima de você
4. Clique em "Create new project"

### 2. Obter as credenciais do projeto

1. No painel do Supabase, vá para Configurações > API
2. Copie a URL do projeto e a chave anônima
3. Copie também a chave de serviço (service_role key)

### 3. Atualizar as credenciais no projeto

1. Atualize o arquivo `lib/services/supabase_service.dart`:

```dart
static const String supabaseUrl = 'https://rwotvxqknrjurqrhxhjv.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3R2eHFrbnJqdXJxcmh4aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4OTI0MzIsImV4cCI6MjA1NzQ2ODQzMn0.RgrvQZ2ltMtxVFWkcO2fRD2ySSeYdvaHVmM7MNGZt_M';
```

2. Atualize o arquivo `.env` com suas credenciais:

```
SUPABASE_URL=https://rwotvxqknrjurqrhxhjv.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3R2eHFrbnJqdXJxcmh4aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4OTI0MzIsImV4cCI6MjA1NzQ2ODQzMn0.RgrvQZ2ltMtxVFWkcO2fRD2ySSeYdvaHVmM7MNGZt_M
SUPABASE_SERVICE_KEY=sua_chave_de_servico_do_supabase
```

### 4. Configurar as tabelas no Supabase

Você pode configurar as tabelas de duas maneiras:

#### Opção 1: Usando o script Node.js

1. Instale as dependências:

```bash
npm install
```

2. Execute o script de configuração:

```bash
npm run setup-supabase
```

#### Opção 2: Executando o SQL manualmente

1. No painel do Supabase, vá para SQL Editor
2. Clique em "New Query"
3. Cole o conteúdo do arquivo `supabase_setup.sql`
4. Clique em "Run"

### 5. Verificar a configuração

1. No painel do Supabase, vá para Table Editor
2. Verifique se todas as tabelas foram criadas:
   - profiles
   - plans
   - subscriptions
   - payments
   - transactions
   - categories
   - shifts
   - appointments
   - user_settings

## Configuração do Asaas

1. Crie uma conta no Asaas
2. Obtenha sua chave de API no ambiente Sandbox (para testes)
3. Atualize as credenciais no arquivo `lib/services/asaas_service.dart`:

```dart
static const String _apiKeySandbox = 'sua_chave_api_sandbox_asaas';
```

4. Quando estiver pronto para produção, obtenha a chave de API de produção e atualize:

```dart
static const String _apiKeyProduction = 'sua_chave_api_producao_asaas';
static const bool _isProduction = true; // Altere para true em produção
```

## Configuração do Webhook Handler

O webhook handler é um servidor Node.js que recebe notificações do Asaas e atualiza o banco de dados no Supabase.

### Instalação

1. Instale as dependências:

```bash
npm install
```

2. Atualize o arquivo `.env` com suas credenciais:

```
SUPABASE_URL=https://rwotvxqknrjurqrhxhjv.supabase.co
SUPABASE_SERVICE_KEY=sua_chave_de_servico_do_supabase
ASAAS_API_KEY=sua_chave_api_do_asaas
ASAAS_SANDBOX=true
PORT=3000
```

### Execução

Para iniciar o servidor webhook:

```bash
npm run start-webhook
```

### Implantação

Você pode implantar o webhook handler em serviços como:

- [Heroku](https://heroku.com)
- [Vercel](https://vercel.com)
- [Railway](https://railway.app)
- [Render](https://render.com)

Após a implantação, configure a URL do webhook no painel do Asaas.

## Estrutura do Banco de Dados

### Tabelas Principais

1. **profiles** - Informações do perfil do usuário
   - Estende a tabela auth.users do Supabase
   - Armazena informações como nome, telefone, cidade, estado, etc.

2. **plans** - Planos disponíveis
   - Armazena informações sobre os planos disponíveis (Básico, Premium)
   - Inclui preços mensais e anuais, descrição e recursos

3. **subscriptions** - Assinaturas dos usuários
   - Vincula um usuário a um plano
   - Armazena informações sobre o status da assinatura, data de início, próxima cobrança, etc.

4. **payments** - Pagamentos realizados
   - Registra todos os pagamentos feitos pelos usuários
   - Vincula-se a uma assinatura e a um usuário

5. **transactions** - Transações financeiras (entradas e saídas)
   - Registra todas as transações financeiras do usuário
   - Inclui tipo (entrada/saída), categoria, valor, data, etc.

6. **categories** - Categorias de transações
   - Define categorias para transações (ex: Plantão, Consulta, Alimentação, etc.)
   - Inclui categorias padrão e permite que o usuário crie suas próprias

7. **shifts** - Plantões médicos
   - Registra informações sobre plantões (local, horário, valor esperado, etc.)
   - Permite acompanhar o status do plantão (agendado, concluído, cancelado)

8. **appointments** - Consultas médicas
   - Registra informações sobre consultas (paciente, horário, valor esperado, etc.)
   - Permite acompanhar o status da consulta (agendada, concluída, cancelada)

9. **user_settings** - Configurações do usuário
   - Armazena preferências do usuário
   - Inclui configurações para integração com WhatsApp, Google Calendar, etc.

### Políticas de Segurança

O banco de dados utiliza Row Level Security (RLS) para garantir que os usuários só possam acessar seus próprios dados. As políticas de segurança já estão configuradas no script SQL.

## Webhooks

Para receber notificações de pagamentos do Asaas, você precisará configurar webhooks:

1. No painel do Asaas, acesse Configurações > Integrações > Notificações Webhook
2. Configure a URL do seu webhook (ex: https://seu-servidor.com/webhook/asaas)
3. Selecione os eventos que deseja receber:
   - Pagamento recebido
   - Pagamento confirmado
   - Pagamento atrasado
   - Pagamento cancelado/estornado
   - Assinatura criada
   - Assinatura renovada
   - Assinatura cancelada

## Fluxo de Pagamento

1. O usuário seleciona um plano no aplicativo
2. O aplicativo cria um cliente no Asaas (se ainda não existir)
3. O aplicativo cria uma assinatura ou cobrança no Asaas
4. O usuário é redirecionado para a página de pagamento
5. Após o pagamento, o Asaas notifica o servidor via webhook
6. O servidor atualiza o status da assinatura no Supabase

## Próximos Passos

1. Implemente a integração com o WhatsApp para registro de transações
2. Configure a integração com o Google Calendar para agendamento de plantões
3. Desenvolva o dashboard para visualização de relatórios financeiros

## Solução de Problemas

### Webhook não está recebendo eventos

- Verifique se a URL do webhook está correta no painel do Asaas
- Verifique se o servidor está online e acessível publicamente
- Verifique os logs do servidor para erros

### Pagamentos não estão sendo atualizados no Supabase

- Verifique se as credenciais do Supabase estão corretas no arquivo .env
- Verifique se o cliente do Asaas está corretamente associado ao usuário no Supabase
- Verifique os logs do servidor para erros nas consultas ao Supabase 