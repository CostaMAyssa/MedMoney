# MedMoney

Sistema de gestão financeira para profissionais de saúde com integração de pagamentos Asaas e PIX.

## Sobre o Projeto

MedMoney é uma aplicação Flutter desenvolvida para auxiliar profissionais de saúde na gestão financeira de seus consultórios e clínicas. O sistema permite o agendamento de consultas, controle de pagamentos e integração com a plataforma Asaas para processamento de pagamentos via PIX.

## Funcionalidades

- Autenticação de usuários com Supabase
- Dashboard com visão geral financeira
- Agendamento de consultas
- Gestão de horários disponíveis
- Processamento de pagamentos via PIX (integração Asaas)
- Geração de QR Code para pagamentos
- Histórico de transações

## Tecnologias Utilizadas

- Flutter
- Dart
- Supabase (Autenticação e Banco de Dados)
- Asaas API (Processamento de Pagamentos)
- Provider (Gerenciamento de Estado)

## Configuração do Ambiente

### Pré-requisitos

- Flutter SDK
- Dart SDK
- Conta no Supabase
- Conta no Asaas

### Instalação

1. Clone o repositório
```bash
git clone https://github.com/SEU_USUARIO/MedMoney.git
cd MedMoney/medmoney
```

2. Instale as dependências
```bash
flutter pub get
```

3. Configure as variáveis de ambiente
   - Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:
   ```
   SUPABASE_URL=sua_url_do_supabase
   SUPABASE_ANON_KEY=sua_chave_anonima_do_supabase
   ASAAS_API_KEY=sua_chave_api_do_asaas
   ASAAS_API_URL=url_da_api_do_asaas
   ```

4. Execute o aplicativo
```bash
flutter run
```

## Configuração do Supabase

Consulte o arquivo [SUPABASE_SETUP.md](medmoney/SUPABASE_SETUP.md) para instruções detalhadas sobre como configurar o banco de dados no Supabase.

## Integração com Asaas

O sistema utiliza a API do Asaas para processamento de pagamentos via PIX. A integração permite:

- Criação de clientes
- Geração de cobranças
- Geração de QR Code PIX
- Consulta de status de pagamentos

## Contribuição

Contribuições são bem-vindas! Para contribuir:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para detalhes.

## Contato

Mayssa Ferreira - mayssaprog16@outlook.com

Link do projeto: [https://github.com/SEU_USUARIO/MedMoney](https://github.com/SEU_USUARIO/MedMoney) 