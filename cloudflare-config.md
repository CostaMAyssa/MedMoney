# Configuração do CloudFlare para resolver o problema de SSL

Para resolver o problema do site ser mostrado como inseguro, siga estas instruções para configurar o CloudFlare corretamente:

## 1. Acesse o Painel do CloudFlare

1. Faça login na sua conta do CloudFlare
2. Selecione o domínio "medmoney.me"

## 2. Configure o SSL/TLS

1. No menu lateral, clique em "SSL/TLS"
2. Na aba "Overview", selecione a opção "Flexible" para o modo de criptografia SSL/TLS
   - O modo "Flexible" permite uma conexão HTTPS entre os visitantes e o CloudFlare, mas uma conexão HTTP entre o CloudFlare e seu servidor
   - Isso é ideal para servidores que não têm certificados SSL próprios

## 3. Crie uma Page Rule para forçar HTTPS

1. No menu lateral, clique em "Rules" e depois em "Page Rules"
2. Clique em "Create Page Rule"
3. No campo URL, digite: `*medmoney.me/*`
4. Clique em "Add a Setting" e selecione "SSL"
5. Escolha a opção "Flexible"
6. Clique em "Save and Deploy"

## 4. Verifique os registros DNS

1. No menu lateral, clique em "DNS"
2. Certifique-se de que existe um registro A para "medmoney.me" que aponta para o IP do seu servidor
3. Confirme que o ícone de nuvem (proxy CloudFlare) está LARANJA/ATIVO
   - Se estiver cinza, clique nele para ativá-lo

## 5. Limpe o cache do CloudFlare

1. No menu lateral, clique em "Caching"
2. Vá para "Configuration"
3. Clique em "Purge Cache" e selecione "Purge Everything"
4. Confirme a limpeza do cache

## 6. Acesse seu site pela URL sem a porta

Após fazer essas configurações, **não acesse mais seu site usando a porta (medmoney.me:8080)**. Em vez disso, acesse simplesmente:

```
https://medmoney.me
```

O CloudFlare agora vai:
1. Fornecer um certificado SSL válido para seu domínio
2. Lidar com a conexão HTTPS entre os usuários e o CloudFlare
3. Encaminhar o tráfego para seu servidor na porta 8080 de forma segura

## Solução de problemas

- **Ainda aparece inseguro?** Limpe completamente o cache do seu navegador ou tente em uma janela anônima.
- **Erro ERR_TOO_MANY_REDIRECTS?** Pode ser um conflito entre redirecionamentos. Desative temporariamente a opção "Always Use HTTPS" em SSL/TLS > Edge Certificates no CloudFlare. 