# Configuração do Supabase para o MedMoney

Este guia fornece instruções detalhadas para configurar o Supabase para o projeto MedMoney.

## Pré-requisitos

- Conta no Supabase (https://supabase.com)
- Projeto criado no Supabase

## Passo 1: Obter credenciais do Supabase

1. Acesse o dashboard do Supabase e selecione seu projeto
2. No menu lateral, clique em "Configurações do Projeto" (ícone de engrenagem)
3. Selecione "API" no submenu
4. Copie a "URL do projeto" e a "chave anon pública"
5. Crie um arquivo `.env` na raiz do projeto MedMoney com o seguinte conteúdo:

```
SUPABASE_URL=sua-url-do-projeto
SUPABASE_ANON_KEY=sua-chave-anon-publica
```

## Passo 2: Executar o script SQL para criar as tabelas

1. No dashboard do Supabase, clique em "SQL Editor" no menu lateral
2. Clique em "Novo Query" para criar uma nova consulta
3. Copie e cole o conteúdo do arquivo `lib/sql/database_setup.sql` no editor
4. Clique em "Executar" para criar as funções necessárias

## Passo 3: Executar as funções para criar as tabelas

Após criar as funções, execute cada uma delas para criar as tabelas:

1. No SQL Editor, crie uma nova consulta com o seguinte conteúdo:

```sql
-- Criar tabelas
SELECT create_profiles_table();
SELECT create_plans_table();
SELECT create_subscriptions_table();
SELECT create_transactions_table();
```

2. Clique em "Executar" para criar todas as tabelas

## Passo 4: Verificar a criação das tabelas

1. No menu lateral, clique em "Tabela" para ver as tabelas criadas
2. Você deve ver as seguintes tabelas:
   - profiles
   - plans
   - subscriptions
   - transactions

## Passo 5: Configurar autenticação

1. No menu lateral, clique em "Autenticação"
2. Em "Configurações", certifique-se de que:
   - "Email Auth" está habilitado
   - "Confirmar email" está desabilitado (para facilitar o teste)
   - "Secure email change" está habilitado

## Passo 6: Verificar políticas de segurança (RLS)

1. No menu lateral, clique em "Tabela"
2. Selecione cada tabela e clique na aba "Políticas"
3. Verifique se as políticas de segurança foram criadas corretamente

## Alternativa: Configuração automática pelo aplicativo

O aplicativo MedMoney agora inclui uma funcionalidade para criar automaticamente as tabelas necessárias quando é iniciado pela primeira vez. Para usar essa funcionalidade:

1. Configure corretamente o arquivo `.env` com as credenciais do Supabase
2. Execute o aplicativo
3. O aplicativo tentará criar as tabelas automaticamente se elas não existirem

## Solução de problemas

### Erro ao criar perfil durante o registro

Se você encontrar erros relacionados à tabela "profiles" não existir durante o registro, isso indica que a tabela não foi criada corretamente. Siga os passos acima para criar manualmente a tabela.

### Erro ao verificar assinatura

Se você encontrar erros relacionados à tabela "subscriptions" não existir, isso indica que a tabela não foi criada corretamente. Siga os passos acima para criar manualmente a tabela.

## Referências

- [Documentação do Supabase](https://supabase.com/docs)
- [Guia de Row Level Security (RLS)](https://supabase.com/docs/guides/auth/row-level-security)
- [Guia de SQL no Supabase](https://supabase.com/docs/guides/database) 