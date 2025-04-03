# Configuração do CloudFlare para ocultar a porta 8080 do domínio medmoney.me

Siga estes passos para configurar o CloudFlare corretamente e ocultar a porta 8080 do seu domínio:

## 1. Verifique os registros DNS no CloudFlare

1. Faça login na sua conta do CloudFlare
2. Selecione o domínio `medmoney.me`
3. Vá para a seção "DNS"
4. Verifique se existe um registro A para `medmoney.me` que aponta para o IP do seu servidor
5. Certifique-se de que o ícone da nuvem (proxy) esteja **laranja/ativo** para esse registro, indicando que o tráfego está passando pelo proxy do CloudFlare

## 2. Configure o modo SSL/TLS no CloudFlare

1. Vá para a seção "SSL/TLS"
2. Em "Overview", selecione "Full" ou "Full (Strict)" para o modo SSL/TLS
   - "Full": O CloudFlare estabelece uma conexão HTTPS com seu servidor, mas não verifica o certificado
   - "Full (Strict)": O CloudFlare verifica se o certificado do seu servidor é válido

## 3. Configure uma Page Rule para ocultar a porta

1. Vá para a seção "Rules" > "Page Rules"
2. Clique em "Create Page Rule"
3. Em "URL", digite: `medmoney.me/*`
4. Adicione as seguintes configurações:
   - "SSL": Full ou Full (Strict)
   - "Cache Level": Standard (se não quiser cache) ou Cache Everything (para maior performance)
5. Clique em "Save and Deploy"

## 4. Verifique a configuração de Origin Rules (opcional)

1. Vá para a seção "Rules" > "Origin Rules"
2. Crie uma regra que aplique a todas as solicitações para medmoney.me
3. Defina a ação para modificar o cabeçalho do host para `medmoney.me` sem a porta

## 5. Teste a configuração

1. Limpe o cache do seu navegador
2. Acesse `http://medmoney.me` (sem especificar a porta)
3. Você deve ser redirecionado para `https://medmoney.me` e ver seu site sem precisar especificar a porta 8080

## Solução de problemas

- **Problema**: O site não carrega ou mostra erro de conexão
  **Solução**: Verifique se o proxy do CloudFlare está ativo (ícone laranja) para seu registro DNS

- **Problema**: O site redireciona para a porta 8080
  **Solução**: Verifique se o Traefik está configurado corretamente para encaminhar o tráfego para a porta 8080 internamente

- **Problema**: O site mostra erro de SSL
  **Solução**: Ajuste o modo SSL/TLS no CloudFlare para "Flexible" temporariamente e depois volte para "Full" quando o problema for resolvido

## Observações importantes

- O CloudFlare oculta a porta do usuário final, mas internamente o tráfego ainda é encaminhado para a porta 8080 no seu servidor
- As alterações no CloudFlare podem levar alguns minutos para se propagar
- Se você usar HTTPS, certifique-se de que seu servidor tenha um certificado SSL válido ou use o modo "Flexible" no CloudFlare 