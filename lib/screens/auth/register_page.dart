import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../utils/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/responsive_container.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_service.dart';

// Definição da classe Plan no nível superior
class Plan {
  final String name;
  final String price;

  Plan({required this.name, required this.price});
}

class RegisterPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  
  const RegisterPage({Key? key, this.initialData}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  String _selectedPlan = 'Essencial'; // Plano padrão selecionado
  bool _isAnnualPlan = false; // Controla se o plano é anual ou mensal
  String? _errorMessage;
  bool plansLoaded = false;
  List<Plan> _plans = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Inicializar os planos
    _plans = [
      Plan(
        name: 'Essencial',
        price: _isAnnualPlan ? 'R\$ 163,00' : 'R\$ 15,90',
      ),
      Plan(
        name: 'Premium',
        price: _isAnnualPlan ? 'R\$ 254,00' : 'R\$ 24,90',
      ),
    ];
    plansLoaded = true;
    
    // Definir plano selecionado com base nos argumentos recebidos
    if (widget.initialData != null) {
      final selectedPlan = widget.initialData!['selectedPlan'];
      final isAnnual = widget.initialData!['isAnnual'];
      
      if (selectedPlan != null) {
        setState(() {
          _selectedPlan = selectedPlan;
        });
      }
      
      if (isAnnual != null) {
        setState(() {
          _isAnnualPlan = isAnnual;
          // Atualizar os preços de acordo com a periodicidade
          _updatePlanPrices();
        });
      }
      
      // Mantendo o usuário na etapa de escolha de plano (etapa 0)
      // para que ele possa confirmar ou modificar sua escolha
      _currentStep = 0;
    }
  }
  
  // Método para atualizar os preços conforme o tipo de plano selecionado
  void _updatePlanPrices() {
    _plans = [
      Plan(
        name: 'Essencial',
        price: _isAnnualPlan ? 'R\$ 163,00' : 'R\$ 15,90',
      ),
      Plan(
        name: 'Premium',
        price: _isAnnualPlan ? 'R\$ 254,00' : 'R\$ 24,90',
      ),
    ];
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final supabaseService = SupabaseService();
        
        debugPrint('Iniciando registro com email: ${_emailController.text.trim()}');
        // Garantir que o telefone é uma string
        final String phoneAsString = _phoneController.text.trim().toString();
        debugPrint('Telefone para registro (como string): $phoneAsString');
        debugPrint('Tipo do telefone: ${phoneAsString.runtimeType}');
        
        // Realizar cadastro do usuário
        final response = await supabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          phone: phoneAsString, // Explicitamente como string
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          cpf: _cpfController.text.trim(),
          selectedPlan: _selectedPlan,
          isAnnualPlan: _isAnnualPlan,
        );

        debugPrint('Resposta do registro: ${response.user != null ? 'Sucesso' : 'Falha'}');
        
        if (response.user != null) {
          // Registro realizado com sucesso
          setState(() {
            _isLoading = false;
          });
          
          // Mostrar mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conta criada com sucesso! Redirecionando...',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
          
          // Sempre redirecionar para a página de pagamento após o registro
          // independentemente do plano selecionado
          debugPrint('Redirecionando para a página de pagamento após registro');
          
          // Obter o plano selecionado do array de planos
          Plan selectedPlan = _plans.firstWhere(
            (plan) => plan.name == _selectedPlan,
            orElse: () => Plan(
              name: _selectedPlan,
              price: _isAnnualPlan ? 'R\$ 163,00' : 'R\$ 15,90',
            ),
          );
          
          // Remover símbolos e converter para double
          final String planPriceStr = selectedPlan.price;
          final double planPrice = double.tryParse(
              planPriceStr.replaceAll('R\$', '').replaceAll(',', '.').trim()) ?? 0.0;
          
          // Taxa de setup é zero
          final double setupFee = 0.0;
          
          // Log detalhado para debugging
          debugPrint('====== DETALHES DO PLANO SELECIONADO ======');
          debugPrint('Nome do plano: $_selectedPlan');
          debugPrint('Tipo: ${_isAnnualPlan ? "Anual" : "Mensal"}');
          debugPrint('Preço exibido: ${selectedPlan.price}');
          debugPrint('Preço convertido: $planPrice');
          debugPrint('Taxa de setup: $setupFee');
          debugPrint('==========================================');
          
          debugPrint('Plano: $_selectedPlan, Tipo: ${_isAnnualPlan ? 'Anual' : 'Mensal'}, Preço: $planPrice, Taxa: $setupFee');
          
          Navigator.pushReplacementNamed(
            context,
            '/payment',
            arguments: {
              'planName': _selectedPlan,
              'planType': _isAnnualPlan ? 'annual' : 'monthly',
              'planPrice': planPrice,
              'setupFee': setupFee,
              'totalPrice': planPrice,
            },
          );
        } else {
          // Falha no registro
          setState(() {
            _isLoading = false;
            _errorMessage = 'Falha ao criar conta. Verifique os dados e tente novamente.';
          });
        }
      } catch (e) {
        debugPrint('Erro no registro: $e');
        
        // Tratar erros específicos
        String errorMsg = 'Erro ao criar conta';
        String errorText = e.toString().toLowerCase();
        
        if (errorText.contains('user_already_exists') || 
            errorText.contains('already registered') || 
            errorText.contains('already registered') || 
            errorText.contains('statuscode: 422') ||
            errorText.contains('user_already_exists') ||
            (errorText.contains('authexception') && errorText.contains('registered')) ||
            errorText.contains('email já está cadastrado')) {
          errorMsg = 'Este email já está cadastrado. Por favor, utilize outro email ou faça login.';
        } else if (errorText.contains('invalid email')) {
          errorMsg = 'Email inválido. Por favor, verifique o formato do email informado.';
        } else if (errorText.contains('network')) {
          errorMsg = 'Erro de conexão. Verifique sua internet e tente novamente.';
        } else if (errorText.contains('password')) {
          errorMsg = 'Senha inválida. A senha deve ter pelo menos 6 caracteres.';
        } else if (errorText.contains('statuscode: 422')) {
          errorMsg = 'Usuário já registrado. Por favor, faça login com sua conta existente.';
        } else if (errorText.contains('supabase')) {
          // Erro específico do Supabase
          if (errorText.contains('auth')) {
            errorMsg = 'Erro de autenticação. Por favor, verifique suas credenciais.';
          } else {
            errorMsg = 'Erro no serviço. Por favor, tente novamente mais tarde.';
          }
        }
        
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
    } else {
      _register();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Future<void> _openTermsOfUse() async {
    // Navegar para a página de termos de uso
    Navigator.pushNamed(context, '/terms-of-use');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho
            AppHeader(
              onLoginPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            
            // Conteúdo principal
            ResponsiveContainer(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 16 : 32,
                vertical: 64,
              ),
              child: Column(
                children: [
                  Text(
                    'Crie sua conta',
                    style: TextStyle(
                      fontSize: Responsive.isMobile(context) ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comece a organizar suas finanças em poucos passos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.isMobile(context) ? 14 : 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Stepper de registro
                  _buildRegisterStepper(context),
                ],
              ),
            ),
            
            // Rodapé
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterStepper(BuildContext context) {
    return Card(
      elevation: 4,
      color: Color(0xFF1A1A4F), // Cor escura para o fundo do card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
        child: Column(
          children: [
            // Mensagem de erro para usuário já registrado (se houver)
            if (_errorMessage != null && _errorMessage!.contains('email já está cadastrado')) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usuário já registrado',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: Text(
                              'Clique aqui para fazer login',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Indicador de progresso
            Responsive.isMobile(context)
              ? Column(
                  children: [
                    Row(
                      children: [
                        _buildStepIndicator(0, 'Plano'),
                        _buildStepConnector(_currentStep >= 1),
                        _buildStepIndicator(1, 'Informações'),
                        _buildStepConnector(_currentStep >= 2),
                        _buildStepIndicator(2, 'Credenciais'),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Text(
                      _currentStep == 0 
                        ? 'Escolha seu plano' 
                        : _currentStep == 1 
                          ? 'Informações Pessoais' 
                          : 'Credenciais de acesso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildStepIndicator(0, 'Escolha seu plano'),
                    _buildStepConnector(_currentStep >= 1),
                    _buildStepIndicator(1, 'Informações Pessoais'),
                    _buildStepConnector(_currentStep >= 2),
                    _buildStepIndicator(2, 'Credenciais de acesso'),
                  ],
                ),
            
            // Mensagem de erro (para outros erros)
            if (_errorMessage != null && !_errorMessage!.contains('email já está cadastrado')) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Conteúdo do passo atual
            Form(
              key: _formKey,
              child: _buildStepContent(),
            ),
            
            // Botões de navegação
            const SizedBox(height: 32),
            Responsive.isMobile(context)
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: _currentStep < 2 ? 'Continuar' : 'Criar Conta',
                          onPressed: _nextStep,
                          type: ButtonType.primary,
                          size: ButtonSize.medium,
                          isLoading: _isLoading,
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Voltar',
                            onPressed: _previousStep,
                            type: ButtonType.outline,
                            size: ButtonSize.medium,
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        CustomButton(
                          text: 'Voltar',
                          onPressed: _previousStep,
                          type: ButtonType.outline,
                          size: ButtonSize.medium,
                        )
                      else
                        const SizedBox(),
                      CustomButton(
                        text: _currentStep < 2 ? 'Continuar' : 'Criar Conta',
                        onPressed: _nextStep,
                        type: ButtonType.primary,
                        size: ButtonSize.medium,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : Color(0xFF2A2A5F),
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : null,
            ),
            child: Center(
              child: isActive
                  ? const Icon(Icons.check, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? AppTheme.primaryColor : Color(0xFF2A2A5F),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPlanSelection();
      case 1:
        return _buildPersonalInfo();
      case 2:
        return _buildCredentials();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlanSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildPlanOptions(),
      ],
    );
  }

  Widget _buildPlanOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seletor de plano anual ou mensal
        Container(
          margin: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              Text(
                'Periodicidade:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
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
                    _buildPlanTypeOption('Mensal', !_isAnnualPlan, () {
                      if (_isAnnualPlan) {
                        setState(() {
                          _isAnnualPlan = false;
                          // Atualizar os preços diretamente
                          _updatePlanPrices();
                        });
                      }
                    }),
                    _buildPlanTypeOption('Anual', _isAnnualPlan, () {
                      if (!_isAnnualPlan) {
                        setState(() {
                          _isAnnualPlan = true;
                          // Atualizar os preços diretamente
                          _updatePlanPrices();
                        });
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Opções de plano
        _buildSimplePlanOption(
          'Plano Essencial',
          'Bot no WhatsApp',
          _plans.isNotEmpty ? (_plans[0].price) : (_isAnnualPlan ? 'R\$ 163,00' : 'R\$ 15,90'),
          _selectedPlan == 'Essencial',
          () {
            setState(() {
              _selectedPlan = 'Essencial';
            });
          },
        ),
        const SizedBox(height: 16),
        _buildSimplePlanOption(
          'Plano Premium',
          'Bot + Dashboard completo',
          _plans.isNotEmpty && _plans.length > 1 ? (_plans[1].price) : (_isAnnualPlan ? 'R\$ 254,00' : 'R\$ 24,90'),
          _selectedPlan == 'Premium',
          () {
            setState(() {
              _selectedPlan = 'Premium';
            });
          },
        ),
      ],
    );
  }

  Widget _buildPlanTypeOption(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.isMobile(context) ? 16 : 32,
          vertical: 16
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: Responsive.isMobile(context) ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSimplePlanOption(
    String title,
    String subtitle,
    String price,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Color(0xFF2A2A5F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Radio(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.isMobile(context) ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Responsive.isMobile(context) ? 12 : 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: Responsive.isMobile(context) ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        CustomTextField(
          label: 'Nome completo *',
          hint: 'Seu nome completo',
          controller: _nameController,
          prefixIcon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu nome completo';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'CPF *',
          hint: '000.000.000-00',
          controller: _cpfController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.assignment_ind,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu CPF';
            }
            // Validação básica de CPF (formato)
            if (!RegExp(r'^\d{3}\.\d{3}\.\d{3}\-\d{2}$').hasMatch(value) && 
                !RegExp(r'^\d{11}$').hasMatch(value)) {
              return 'Formato de CPF inválido. Use 000.000.000-00';
            }
            
            // Formatar o CPF automaticamente
            if (RegExp(r'^\d{11}$').hasMatch(value)) {
              // Se for digitado sem pontuação, formatar automaticamente
              Future.microtask(() {
                final formattedCpf = '${value.substring(0, 3)}.${value.substring(3, 6)}.${value.substring(6, 9)}-${value.substring(9, 11)}';
                _cpfController.text = formattedCpf;
              });
            }
            
            return null;
          },
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Celular *',
          hint: '(00) 00000-0000',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu celular';
            }
            
            // Validação básica de celular (formato)
            // Aceita formatos como (XX) XXXXX-XXXX ou XX XXXXX-XXXX ou XXXXXXXXXXX
            if (!RegExp(r'^\(\d{2}\) \d{5}\-\d{4}$').hasMatch(value) &&
                !RegExp(r'^\d{2} \d{5}\-\d{4}$').hasMatch(value) &&
                !RegExp(r'^\d{11}$').hasMatch(value)) {
              return 'Formato de celular inválido. Use (00) 00000-0000';
            }
            
            // Formatar o telefone automaticamente se for digitado sem pontuação
            if (RegExp(r'^\d{11}$').hasMatch(value)) {
              Future.microtask(() {
                final formattedPhone = '(${value.substring(0, 2)}) ${value.substring(2, 7)}-${value.substring(7, 11)}';
                _phoneController.text = formattedPhone;
                // Garantindo que é uma string
                debugPrint('Telefone formatado (String): ${_phoneController.text}');
                debugPrint('Tipo do telefone: ${_phoneController.text.runtimeType}');
              });
            }
            
            return null;
          },
        ),
        const SizedBox(height: 24),
        Responsive.isMobile(context)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'Cidade *',
                    hint: 'Sua cidade',
                    controller: _cityController,
                    prefixIcon: Icons.location_city,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe sua cidade';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Estado *',
                    hint: 'UF',
                    controller: _stateController,
                    prefixIcon: Icons.map,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe seu estado';
                      }
                      return null;
                    },
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Cidade *',
                      hint: 'Sua cidade',
                      controller: _cityController,
                      prefixIcon: Icons.location_city,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe sua cidade';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      label: 'Estado *',
                      hint: 'UF',
                      controller: _stateController,
                      prefixIcon: Icons.map,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe seu estado';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildCredentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Crie suas credenciais para acessar a plataforma',
          style: TextStyle(
            fontSize: Responsive.isMobile(context) ? 14 : 16,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          label: 'Email *',
          hint: 'Seu email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu email';
            }
            
            // Regex mais completa para validação de email
            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
              return 'Por favor, informe um email válido (exemplo@dominio.com)';
            }
            
            // Verificações adicionais
            if (value.contains('..') || value.startsWith('.') || value.endsWith('.')) {
              return 'Email inválido: não pode conter pontos consecutivos ou começar/terminar com ponto';
            }
            
            if (!value.contains('@') || value.indexOf('@') != value.lastIndexOf('@')) {
              return 'Email inválido: deve conter exatamente um caractere @';
            }
            
            return null;
          },
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Senha *',
          hint: 'Sua senha',
          controller: _passwordController,
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock,
          suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
          onSuffixIconPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe sua senha';
            }
            if (value.length < 6) {
              return 'A senha deve ter pelo menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Confirmar senha *',
          hint: 'Confirme sua senha',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
          onSuffixIconPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, confirme sua senha';
            }
            if (value != _passwordController.text) {
              return 'As senhas não conferem';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: true,
              onChanged: (value) {},
              activeColor: AppTheme.primaryColor,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Concordo com os Termos de Uso e Política de Privacidade',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: _openTermsOfUse,
                    child: Text(
                      'Ler termos de uso',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
} 