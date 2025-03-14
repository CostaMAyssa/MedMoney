# MedMoney

MedMoney é uma plataforma de gestão financeira para profissionais da saúde, que permite gerenciar plantões, consultas e finanças de forma simples e eficiente através do WhatsApp.

## Estrutura do Projeto

O projeto está organizado da seguinte forma:

```
MedMoney/
└── medmoney/           # Diretório principal do projeto
    ├── lib/            # Código fonte Flutter
    │   ├── assets/     # Assets internos
    │   ├── screens/    # Telas do aplicativo
    │   ├── services/   # Serviços (Supabase, Asaas)
    │   ├── utils/      # Utilitários
    │   ├── widgets/    # Widgets reutilizáveis
    │   └── main.dart   # Ponto de entrada do aplicativo
    ├── assets/         # Assets externos (imagens, ícones)
    ├── test/           # Testes automatizados
    └── ...             # Outros arquivos e diretórios
```

## Documentação

Para mais informações sobre o projeto, consulte os seguintes arquivos:

- [README do Projeto](medmoney/README.md) - Informações detalhadas sobre o projeto
- [Configuração do Backend](medmoney/BACKEND_SETUP.md) - Instruções para configurar o backend (Supabase e Asaas)

## Configuração do Supabase

Para configurar o banco de dados no Supabase, você pode:

1. Executar o script SQL diretamente no Editor SQL do Supabase:
   - Copie o conteúdo do arquivo [supabase_setup_manual.sql](medmoney/supabase_setup_manual.sql)
   - Cole no Editor SQL do Supabase e execute

2. Ou usar o script Node.js (requer a chave de serviço do Supabase):
   - Configure o arquivo `.env` com suas credenciais
   - Execute `npm run setup-supabase` dentro do diretório `medmoney`

## Executando o Projeto

Para executar o projeto:

1. Entre no diretório do projeto:
```bash
cd medmoney
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Execute o aplicativo:
```bash
flutter run
```

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests. 