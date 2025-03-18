# MedMoney

MedMoney é um aplicativo de gestão financeira desenvolvido especificamente para profissionais da área da saúde. Ele permite o controle de plantões, consultas, despesas e receitas, oferecendo uma visão clara das finanças pessoais e profissionais.

## Funcionalidades

- **Controle de Plantões**: Registre seus plantões, locais, horários e valores.
- **Gestão de Consultas**: Acompanhe suas consultas médicas e os pagamentos recebidos.
- **Controle Financeiro**: Registre receitas e despesas com categorização.
- **Dashboard**: Visualize gráficos e relatórios sobre sua situação financeira.
- **Planos de Assinatura**: Escolha entre planos Básico e Premium com diferentes funcionalidades.

## Configuração do Projeto

### Pré-requisitos

- Flutter SDK (versão 3.0.0 ou superior)
- Dart SDK (versão 2.17.0 ou superior)
- Conta no Supabase para o backend

### Instalação

1. Clone o repositório:
   ```
   git clone https://github.com/seu-usuario/medmoney.git
   cd medmoney
   ```

2. Instale as dependências:
   ```
   flutter pub get
   ```

3. Configure o arquivo `.env` na raiz do projeto:
   ```
   SUPABASE_URL=sua_url_do_supabase
   SUPABASE_ANON_KEY=sua_chave_anon_do_supabase
   ```

4. Configure o Supabase seguindo as instruções no arquivo `SUPABASE_SETUP.md`.

5. Execute o aplicativo:
   ```
   flutter run
   ```

## Configuração do Supabase

O MedMoney utiliza o Supabase como backend. Para configurar corretamente o banco de dados e a autenticação, siga as instruções detalhadas no arquivo `SUPABASE_SETUP.md`.

O script SQL para criar todas as tabelas necessárias está disponível no arquivo `supabase_setup.sql`. Execute este script no SQL Editor do Supabase para configurar o banco de dados.

## Estrutura do Projeto

```
lib/
├── main.dart                  # Ponto de entrada do aplicativo
├── screens/                   # Telas do aplicativo
│   ├── auth/                  # Telas de autenticação
│   ├── dashboard/             # Telas do dashboard
│   └── ...
├── widgets/                   # Widgets reutilizáveis
├── services/                  # Serviços (Supabase, etc.)
├── providers/                 # Provedores de estado
├── models/                    # Modelos de dados
└── utils/                     # Utilitários e constantes
```

## Planos de Assinatura

O MedMoney oferece dois planos de assinatura:

1. **Plano Básico**:
   - Bot no WhatsApp para controle financeiro
   - Preço: R$ 19,90/mês ou R$ 199,00/ano

2. **Plano Premium**:
   - Bot no WhatsApp
   - Dashboard completo
   - Preço: R$ 29,90/mês ou R$ 299,00/ano

## Contribuição

Contribuições são bem-vindas! Para contribuir:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Faça commit das suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Faça push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para mais detalhes.
