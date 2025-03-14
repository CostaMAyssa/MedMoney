# Configuração do Backend

Este documento contém instruções detalhadas para configurar o backend do MedMoney, que utiliza Supabase para banco de dados e Asaas para processamento de pagamentos.

## Configuração do Supabase

### Passo 1: Criar uma conta no Supabase

1. Acesse [https://supabase.com](https://supabase.com) e crie uma conta ou faça login
2. Crie um novo projeto chamado "MedMoney"
3. Escolha uma senha forte para o banco de dados PostgreSQL
4. Selecione a região mais próxima de você
5. Aguarde a criação do projeto (pode levar alguns minutos)

### Passo 2: Configurar o banco de dados

Existem duas maneiras de configurar o banco de dados:

#### Opção 1: Executar o script SQL manualmente (Recomendado)

1. No painel do Supabase, clique em "SQL Editor" no menu lateral
2. Clique em "New Query" (Nova Consulta)
3. Copie todo o conteúdo do arquivo `supabase_setup_manual.sql` 
4. Cole no editor SQL e clique em "Run" (Executar)
5. Verifique se todas as tabelas foram criadas sem erros

#### Opção 2: Usar o script Node.js (Requer configuração adicional)

1. Certifique-se de que o Node.js está instalado em seu sistema
2. Atualize o arquivo `.env` com sua chave de serviço do Supabase:
   - Acesse o painel do Supabase
   - Vá para "Settings" > "API"
   - Copie a chave "service_role key" (NÃO a chave anon/public)
   - Cole no arquivo `.env` na variável `SUPABASE_SERVICE_KEY`
3. Execute o comando:
   ```bash
   npm run setup-supabase
   ```

### Passo 3: Verificar a configuração

1. No painel do Supabase, vá para "Table Editor"
2. Você deve ver as seguintes tabelas:
   - profiles
   - plans
   - subscriptions
   - payments
   - transactions
   - categories
   - shifts
   - appointments
   - user_settings
3. Verifique se os planos padrão foram inseridos na tabela "plans"
4. Verifique se as categorias padrão foram inseridas na tabela "categories"

## Configuração do Asaas

### Passo 1: Criar uma conta no Asaas

1. Acesse [https://www.asaas.com](https://www.asaas.com) e crie uma conta
2. Você pode começar com uma conta sandbox (ambiente de testes)

### Passo 2: Obter a chave de API

1. Após criar a conta, acesse o painel do Asaas
2. Vá para "Configurações" > "Integrações" > "API"
3. Gere uma nova chave de API
4. Copie a chave gerada

### Passo 3: Configurar no projeto

1. Abra o arquivo `.env` na raiz do projeto
2. Cole a chave de API na variável `ASAAS_API_KEY`
3. Defina `ASAAS_SANDBOX=true` para ambiente de testes ou `ASAAS_SANDBOX=false` para produção

## Testando a Configuração

Para verificar se tudo está funcionando corretamente:

1. Execute o aplicativo Flutter:
   ```bash
   flutter run
   ```
2. Tente criar uma conta de usuário
3. Verifique no painel do Supabase se o perfil do usuário foi criado na tabela "profiles"
4. Tente assinar um plano e verifique se a assinatura é criada no Asaas

## Solução de Problemas

### Problemas com o Supabase

- **Erro de conexão**: Verifique se as chaves do Supabase no arquivo `.env` estão corretas
- **Erro ao executar o script SQL**: Verifique se você tem permissões de administrador no projeto

### Problemas com o Asaas

- **Erro de pagamento**: Verifique se a chave API do Asaas está correta
- **Cartão recusado**: No ambiente sandbox, use os cartões de teste fornecidos pelo Asaas

## Próximos Passos

Após configurar o backend com sucesso:

1. Configure o frontend do aplicativo
2. Teste o fluxo completo de registro e assinatura
3. Configure as integrações com WhatsApp e Google Calendar 