import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/custom_button.dart';
import '../widgets/responsive_container.dart';

class HomePage extends StatefulWidget {
  final String? initialSection;
  
  const HomePage({super.key, this.initialSection});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Chaves para cada seção
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _benefitsKey = GlobalKey();
  final GlobalKey _workflowKey = GlobalKey();
  final GlobalKey _plansKey = GlobalKey();
  final GlobalKey _demoKey = GlobalKey();
  final GlobalKey _securityKey = GlobalKey();
  
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Agendar a navegação para depois que o widget for construído
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToSection(widget.initialSection);
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _navigateToSection(String? section) {
    if (section == null) return;
    
    GlobalKey? targetKey;
    
    switch (section) {
      case '#como-funciona':
        targetKey = _workflowKey;
        break;
      case '#beneficios':
        targetKey = _benefitsKey;
        break;
      case '#planos':
        targetKey = _plansKey;
        break;
      case '#contato':
        targetKey = _securityKey; // Usando a seção de segurança como contato por enquanto
        break;
      default:
        return;
    }
    
    if (targetKey.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            const AppHeader(),
            _buildHeroSection(context, _heroKey),
            _buildBenefitsSection(_benefitsKey),
            _buildWorkflowSection(_workflowKey),
            _buildPlansSection(context, _plansKey),
            _buildDemoSection(_demoKey),
            _buildSecuritySection(_securityKey),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, GlobalKey key) {
    return ResponsiveContainer(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: MediaQuery.of(context).size.width > 800
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildHeroContent(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 300,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildHeroContent(context),
                  const SizedBox(height: 32),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 300,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simplifique suas Finanças\ncom Automação Inteligente',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Gerencie seus plantões, consultas e finanças de forma simples e eficiente através do WhatsApp.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/register'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Text('Começar Agora'),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(GlobalKey key) {
    return ResponsiveContainer(
      key: key,
      backgroundColor: AppTheme.backgroundColor, // Cor escura para o fundo da seção
      padding: const EdgeInsets.symmetric(vertical: 64.0),
      child: Column(
        children: [
          Text(
            'Benefícios Principais',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 48),
          
          // Versão responsiva dos cards de benefícios
          LayoutBuilder(
            builder: (context, constraints) {
              // Verificar se é versão web (largura maior que 1100px)
              final isWeb = constraints.maxWidth > 1100;
              
              if (isWeb) {
                // Versão web: cards em linha
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBenefitCard(
                      icon: Icons.whatshot,
                      title: 'Integração com WhatsApp',
                      description: 'Registre entradas e saídas financeiras diretamente pelo WhatsApp',
                    ),
                    const SizedBox(width: 24),
                    _buildBenefitCard(
                      icon: Icons.calendar_today,
                      title: 'Agenda Automática',
                      description: 'Seus plantões são automaticamente adicionados ao Google Calendar',
                    ),
                    const SizedBox(width: 24),
                    _buildBenefitCard(
                      icon: Icons.notifications_active,
                      title: 'Notificações Inteligentes',
                      description: 'Receba alertas de pagamentos e compromissos importantes',
                    ),
                    const SizedBox(width: 24),
                    _buildBenefitCard(
                      icon: Icons.analytics,
                      title: 'Relatórios Detalhados',
                      description: 'Visualize sua performance financeira com gráficos e análises',
                    ),
                  ],
                );
              } else {
                // Versão mobile: cards em wrap (comportamento atual)
                return Wrap(
                  spacing: 32,
                  runSpacing: 32,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildBenefitCard(
                      icon: Icons.whatshot,
                      title: 'Integração com WhatsApp',
                      description: 'Registre entradas e saídas financeiras diretamente pelo WhatsApp',
                    ),
                    _buildBenefitCard(
                      icon: Icons.calendar_today,
                      title: 'Agenda Automática',
                      description: 'Seus plantões são automaticamente adicionados ao Google Calendar',
                    ),
                    _buildBenefitCard(
                      icon: Icons.notifications_active,
                      title: 'Notificações Inteligentes',
                      description: 'Receba alertas de pagamentos e compromissos importantes',
                    ),
                    _buildBenefitCard(
                      icon: Icons.analytics,
                      title: 'Relatórios Detalhados',
                      description: 'Visualize sua performance financeira com gráficos e análises',
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A4F), // Cor escura para o fundo dos cards
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF2A2A5F),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowSection(GlobalKey key) {
    return ResponsiveContainer(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 64.0),
      child: Column(
        children: [
          const Text(
            'Como Funciona',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            children: [
              _buildWorkflowStep(
                number: '1',
                title: 'Cadastre-se',
                description: 'Crie sua conta gratuitamente e escolha seu plano',
              ),
              _buildWorkflowStep(
                number: '2',
                title: 'Configure',
                description: 'Conecte seu WhatsApp e personalize suas preferências',
              ),
              _buildWorkflowStep(
                number: '3',
                title: 'Comece a Usar',
                description: 'Registre suas finanças e gerencie seus plantões',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A4F), // Cor escura para o fundo dos cards
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF2A2A5F),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection(BuildContext context, GlobalKey key) {
    // Valores padrão para os planos
    final ValueNotifier<bool> isAnnualNotifier = ValueNotifier<bool>(false);
    final ValueNotifier<String> selectedPlanNotifier = ValueNotifier<String>('Básico');
    
    return ResponsiveContainer(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isMobile(context) ? 16 : 32,
        vertical: 64,
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          // Função para escolher um plano (apenas seleciona, não navega)
          void selectPlan(String plan) {
            setState(() {
              selectedPlanNotifier.value = plan;
            });
          }
          
          // Função para alternar entre plano anual e mensal
          void togglePlanType(bool annual) {
            setState(() {
              isAnnualNotifier.value = annual;
            });
          }
          
          // Função para navegar para a página de registro com o plano selecionado
          void navigateToRegister() {
            Navigator.pushNamed(
              context, 
              '/register',
              arguments: {
                'selectedPlan': selectedPlanNotifier.value,
                'isAnnual': isAnnualNotifier.value,
              },
            );
          }
          
          return Column(
            children: [
              Text(
                'Planos e Preços',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.isMobile(context) ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Escolha o plano ideal para suas necessidades',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.isMobile(context) ? 16 : 18,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              
              // Informação sobre o setup inicial
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Setup Inicial: R\$ 49,90',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pago uma única vez para personalização individual da plataforma',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Seletor de plano anual ou mensal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A5F),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlanTypeButton(
                      context, 
                      'Mensal', 
                      !isAnnualNotifier.value, 
                      () => togglePlanType(false)
                    ),
                    _buildPlanTypeButton(
                      context, 
                      'Anual', 
                      isAnnualNotifier.value, 
                      () => togglePlanType(true)
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              Responsive.isMobile(context)
                  ? Column(
                      children: [
                        _buildSimplePlanCard(
                          context,
                          'Plano Básico',
                          'Bot no WhatsApp',
                          isAnnualNotifier.value ? 'R\$ 142,00/ano' : 'R\$ 13,90/mês',
                          selectedPlanNotifier.value == 'Básico',
                          () => selectPlan('Básico'),
                          () => navigateToRegister(),
                          isAnnualNotifier.value ? 'Economia de 15% em relação ao pagamento mensal' : 'R\$ 167,00/ano se pago mensalmente',
                        ),
                        const SizedBox(height: 24),
                        _buildSimplePlanCard(
                          context,
                          'Plano Premium',
                          'Bot no WhatsApp + Dashboard',
                          isAnnualNotifier.value ? 'R\$ 228,00/ano' : 'R\$ 22,90/mês',
                          selectedPlanNotifier.value == 'Premium',
                          () => selectPlan('Premium'),
                          () => navigateToRegister(),
                          isAnnualNotifier.value ? 'Economia de 17% em relação ao pagamento mensal' : 'R\$ 275,00/ano se pago mensalmente',
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildSimplePlanCard(
                            context,
                            'Plano Básico',
                            'Bot no WhatsApp',
                            isAnnualNotifier.value ? 'R\$ 142,00/ano' : 'R\$ 13,90/mês',
                            selectedPlanNotifier.value == 'Básico',
                            () => selectPlan('Básico'),
                            () => navigateToRegister(),
                            isAnnualNotifier.value ? 'Economia de 15% em relação ao pagamento mensal' : 'R\$ 167,00/ano se pago mensalmente',
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildSimplePlanCard(
                            context,
                            'Plano Premium',
                            'Bot no WhatsApp + Dashboard',
                            isAnnualNotifier.value ? 'R\$ 228,00/ano' : 'R\$ 22,90/mês',
                            selectedPlanNotifier.value == 'Premium',
                            () => selectPlan('Premium'),
                            () => navigateToRegister(),
                            isAnnualNotifier.value ? 'Economia de 17% em relação ao pagamento mensal' : 'R\$ 275,00/ano se pago mensalmente',
                          ),
                        ),
                      ],
                    ),
            ],
          );
        }
      ),
    );
  }
  
  Widget _buildPlanTypeButton(BuildContext context, String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSimplePlanCard(
    BuildContext context,
    String title,
    String subtitle,
    String price,
    bool isSelected,
    VoidCallback onCardTap,
    VoidCallback onButtonTap,
    String additionalInfo,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A1A4F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Color(0xFF2A2A5F),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCardTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isSelected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Recomendado',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      additionalInfo,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Escolher Plano',
                      onPressed: onButtonTap,
                      type: ButtonType.primary,
                      size: ButtonSize.large,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoSection(GlobalKey key) {
    return ResponsiveContainer(
      key: key,
      backgroundColor: AppTheme.backgroundColor, // Cor escura para o fundo da seção
      padding: const EdgeInsets.symmetric(vertical: 64.0),
      child: Column(
        children: [
          Text(
            'Veja como é fácil usar',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: Color(0xFF1A1A4F), // Cor escura para o fundo do container
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF2A2A5F),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Demonstração Interativa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(GlobalKey key) {
    return ResponsiveContainer(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 64.0),
      child: Column(
        children: [
          const Text(
            'Segurança',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Segurança é nossa prioridade. Confie em nós para proteger suas informações financeiras.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 