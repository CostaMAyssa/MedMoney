# MedMoney

MedMoney é uma plataforma de gestão financeira para profissionais da saúde, que permite gerenciar plantões, consultas e finanças de forma simples e eficiente através do WhatsApp.

## Funcionalidades

- **Integração com WhatsApp**: Registre entradas e saídas financeiras diretamente pelo WhatsApp
- **Agenda Automática**: Seus plantões são automaticamente adicionados ao Google Calendar
- **Notificações Inteligentes**: Receba alertas de pagamentos e compromissos importantes
- **Relatórios Detalhados**: Visualize sua performance financeira com gráficos e análises
- **Planos Flexíveis**: Escolha entre planos mensais ou anuais de acordo com suas necessidades

## Tecnologias Utilizadas

- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **Pagamentos**: Asaas
- **Webhook Handler**: Node.js, Express

## Estrutura do Projeto

```
medmoney/
├── lib/                  # Código fonte Flutter
│   ├── assets/           # Assets internos
│   ├── screens/          # Telas do aplicativo
│   ├── services/         # Serviços (Supabase, Asaas)
│   ├── utils/            # Utilitários
│   ├── widgets/          # Widgets reutilizáveis
│   └── main.dart         # Ponto de entrada do aplicativo
├── assets/               # Assets externos (imagens, ícones)
├── webhook_handler.js    # Servidor para processar webhooks do Asaas
├── setup_supabase.js     # Script para configurar o Supabase
├── supabase_setup.sql    # Script SQL para configurar o Supabase
├── BACKEND_SETUP.md      # Instruções para configurar o backend
└── README.md             # Este arquivo
```

## Instalação e Configuração

### Pré-requisitos

- Flutter SDK (versão 3.0.0 ou superior)
- Dart SDK (versão 3.0.0 ou superior)
- Node.js (versão 18 ou superior) para o webhook handler
- Conta no Supabase
- Conta no Asaas

### Configuração do Flutter

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/medmoney.git
cd medmoney
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure as credenciais do Supabase e Asaas (veja BACKEND_SETUP.md)

4. Execute o aplicativo:
```bash
flutter run
```

### Configuração do Supabase

1. Crie uma conta no [Supabase](https://supabase.com) e crie um novo projeto

2. Obtenha as credenciais do projeto (URL e chaves) em Configurações > API

3. Atualize o arquivo `.env` com suas credenciais:
```
SUPABASE_URL=sua_url_do_supabase
SUPABASE_ANON_KEY=sua_chave_anonima
SUPABASE_SERVICE_KEY=sua_chave_de_servico
```

4. Instale as dependências do Node.js:
```bash
npm install
```

5. Execute o script de configuração do Supabase:
```bash
npm run setup-supabase
```

Este script criará todas as tabelas necessárias no Supabase:
- Perfis de usuários
- Planos
- Assinaturas
- Pagamentos
- Transações
- Categorias
- Plantões
- Consultas
- Configurações do usuário

### Configuração do Webhook Handler

1. Configure o webhook no Asaas (veja BACKEND_SETUP.md)

2. Execute o servidor webhook:
```bash
npm run start-webhook
```

## Planos e Preços

- **Plano Básico**: Bot no WhatsApp
  - Mensal: R$ 13,90/mês
  - Anual: R$ 142,00/ano (economia de 15%)

- **Plano Premium**: Bot no WhatsApp + Dashboard
  - Mensal: R$ 22,90/mês
  - Anual: R$ 228,00/ano (economia de 17%)

- **Setup Inicial**: R$ 49,90 (pago uma única vez)

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para detalhes.
