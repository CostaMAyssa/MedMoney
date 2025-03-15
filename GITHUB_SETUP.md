# Conectando ao GitHub

Após criar o repositório no GitHub, execute os seguintes comandos no terminal:

```bash
# Repositório já configurado
git remote add origin https://github.com/CostaMAyssa/MedMoney.git
git branch -M main
git push -u origin main
```

Isso irá:
1. Adicionar o repositório remoto do GitHub como "origin"
2. Renomear a branch atual para "main" (caso ainda não seja esse o nome)
3. Enviar seu código para o GitHub e configurar a branch local para rastrear a branch remota

## Autenticação

Você pode ser solicitado a fornecer suas credenciais do GitHub. Recomendamos configurar a autenticação SSH para uma experiência mais segura e conveniente:
https://docs.github.com/pt/authentication/connecting-to-github-with-ssh 