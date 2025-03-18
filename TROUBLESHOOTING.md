# Guia de Solução de Problemas - MedMoney

Este guia apresenta as soluções para os problemas mais comuns que você pode encontrar ao configurar e usar o sistema MedMoney.

## 1. Usuário faz login mas não vê seu pacote contratado

### Sintoma:
O usuário consegue entrar no sistema (fazer login), mas não visualiza o pacote/plano que contratou.

### Possíveis causas e soluções:

#### 1.1 Tabelas não criadas corretamente no Supabase
**Verificação:** Acesse o painel do Supabase e verifique se as tabelas `profiles`, `plans`, `subscriptions` e `asaas_logs` foram criadas.

**Solução:** Execute o script SQL de configuração conforme indicado no manual de configuração.

#### 1.2 Assinatura não registrada para o usuário
**Verificação:** No painel do Supabase, verifique a tabela `subscriptions` e confirme se existe um registro para o usuário em questão.

**Solução:** Se não existir, você pode:
- Verificar se o pagamento foi realizado no Asaas
- Adicionar manualmente uma assinatura no banco de dados
- Solicitar que o usuário refaça o processo de assinatura

#### 1.3 Status da assinatura não está "active"
**Verificação:** Verifique se o campo `status` na tabela `subscriptions` está definido como "active" para o usuário.

**Solução:** Atualize o status da assinatura:
```sql
UPDATE subscriptions 
SET status = 'active' 
WHERE user_id = 'id_do_usuario';
```

#### 1.4 Webhook não está funcionando
**Verificação:** 
- Verifique a tabela `asaas_logs` para ver se os webhooks estão sendo recebidos
- Confirme se o URL do webhook está configurado corretamente no painel do Asaas

**Solução:**
- Configure corretamente o URL do webhook conforme manual
- Verifique se o servidor está online e acessível
- Teste o webhook enviando um evento de teste do Asaas

## 2. Problemas com Pagamentos

### 2.1 Pagamento não é registrado no sistema

**Verificação:** Verifique se o pagamento aparece como realizado no painel do Asaas.

**Solução:**
- Confirme se o webhook está configurado para receber notificações de pagamento
- Verifique se o `externalReference` usado no pagamento está correto
- Confirme se a API key do Asaas está correta

### 2.2 Erro ao tentar realizar pagamento

**Verificação:** Verifique os logs do aplicativo para mensagens de erro específicas.

**Solução:**
- Confirme se a chave API do Asaas está correta
- Verifique se está usando o ambiente correto (sandbox vs produção)
- Confirme se a integração com Asaas está devidamente configurada

## 3. Problemas de Login e Autenticação

### 3.1 Usuário não consegue fazer login

**Verificação:** Verifique os logs de autenticação do Supabase.

**Solução:**
- Confirme se as credenciais do Supabase estão corretas no arquivo `.env`
- Verifique se a conta do usuário existe na tabela `auth.users` do Supabase
- Confirme se não há bloqueios de segurança no Supabase

### 3.2 Token de autenticação expira rapidamente

**Verificação:** Observe quanto tempo o usuário permanece logado antes de ser deslogado.

**Solução:**
- Ajuste a configuração de expiração do token no Supabase
- Implemente uma lógica de renovação de token no aplicativo

## 4. Verificação e Diagnóstico do Sistema

Para verificar se o sistema está funcionando corretamente, execute os seguintes testes:

### 4.1 Teste do Webhook
1. Acesse a tabela `asaas_logs` no Supabase
2. Envie um evento de teste do painel do Asaas
3. Verifique se o evento foi registrado na tabela de logs

### 4.2 Teste de Integração Completa
1. Crie um novo usuário no sistema
2. Realize o processo de assinatura
3. Complete o pagamento no Asaas
4. Verifique se a assinatura é atualizada para status "active"
5. Verifique se o usuário consegue acessar o conteúdo do plano

## 5. Contato para Suporte

Se você tentou todas as soluções acima e ainda está enfrentando problemas, entre em contato com nossa equipe de suporte para assistência adicional: 