import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../utils/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/responsive_container.dart';
import '../../services/supabase_service.dart';

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
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  String _selectedPlan = 'Básico'; // Plano padrão selecionado
  bool _isAnnualPlan = false; // Controla se o plano é anual ou mensal
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
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
        });
      }
      
      // Avançar para a etapa de informações pessoais
      _currentStep = 1;
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Registrar usuário no Supabase
        final supabaseService = SupabaseService();
        
        debugPrint('Iniciando registro com email: ${_emailController.text.trim()}');
        
        final response = await supabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        debugPrint('Resposta do registro: ${response.user != null ? 'Sucesso' : 'Falha'}');

        if (response.user != null) {
          // Registro bem-sucedido
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Conta criada com sucesso! Agora complete seu pagamento.'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            
            // Calcular preço com base no plano selecionado
            final double planPrice = _selectedPlan == 'Básico' 
                ? (_isAnnualPlan ? 199.00 : 19.90)
                : (_isAnnualPlan ? 299.00 : 29.90);
            
            // Taxa de setup fixa
            const double setupFee = 49.90;
            
            // Calcular preço total
            final double totalPrice = planPrice + setupFee;
            
            // Navegar para a tela de pagamento após o registro
            Navigator.pushReplacementNamed(
              context, 
              '/payment',
              arguments: {
                'planName': _selectedPlan,
                'planType': _isAnnualPlan ? 'annual' : 'monthly',
                'planPrice': planPrice,
                'setupFee': setupFee,
                'totalPrice': totalPrice,
              },
            );
          }
        } else {
          // Erro no registro
          setState(() {
            _errorMessage = 'Falha ao criar conta. Verifique se o email já está em uso.';
            _isLoading = false;
          });
        }
      } catch (e) {
        // Erro durante o registro
        debugPrint('Erro detalhado no registro: $e');
        
        String errorMsg = 'Erro ao criar conta';
        
        // Verificar tipos específicos de erro
        if (e.toString().contains('email')) {
          errorMsg = 'Email inválido ou já está em uso';
        } else if (e.toString().contains('password')) {
          errorMsg = 'Senha muito fraca. Use pelo menos 6 caracteres com letras e números';
        } else if (e.toString().contains('network')) {
          errorMsg = 'Erro de conexão. Verifique sua internet';
        } else if (e.toString().contains('profiles')) {
          errorMsg = 'Erro ao criar perfil. Verifique se o banco de dados está configurado corretamente.';
        }
        
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
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
            
            // Mensagem de erro (se houver)
            if (_errorMessage != null) ...[
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
        Text(
          'Escolha seu plano',
          style: TextStyle(
            fontSize: Responsive.isMobile(context) ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Selecione o plano que melhor atende às suas necessidades',
          style: TextStyle(
            fontSize: Responsive.isMobile(context) ? 14 : 16,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 32),
        
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
                      setState(() {
                        _isAnnualPlan = false;
                      });
                    }),
                    _buildPlanTypeOption('Anual', _isAnnualPlan, () {
                      setState(() {
                        _isAnnualPlan = true;
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Opções de plano
        _buildSimplePlanOption(
          'Plano Básico',
          'Bot no WhatsApp',
          _isAnnualPlan ? 'R\$ 199,00/ano' : 'R\$ 19,90/mês',
          _selectedPlan == 'Básico',
          () {
            setState(() {
              _selectedPlan = 'Básico';
            });
          },
        ),
        const SizedBox(height: 16),
        _buildSimplePlanOption(
          'Plano Premium',
          'Bot + Dashboard',
          _isAnnualPlan ? 'R\$ 299,00/ano' : 'R\$ 29,90/mês',
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
        Text(
          'Informações Pessoais',
          style: TextStyle(
            fontSize: Responsive.isMobile(context) ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Informe seus dados pessoais para criar sua conta',
          style: TextStyle(
            fontSize: Responsive.isMobile(context) ? 14 : 16,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          label: 'Nome completo',
          hint: 'Seu nome completo',
          controller: _nameController,
          prefixIcon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu nome';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Celular',
          hint: '(00) 00000-0000',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu celular';
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
                    label: 'Cidade',
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
                    label: 'Estado',
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
                      label: 'Cidade',
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
                      label: 'Estado',
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
        Text(
          'Credenciais de acesso',
          style: TextStyle(
            fontSize: Responsive.isMobile(context) ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
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
          label: 'Email',
          hint: 'Seu email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Por favor, informe um email válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Senha',
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
          label: 'Confirmar senha',
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
              return 'As senhas não coincidem';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: (value) {},
              activeColor: AppTheme.primaryColor,
            ),
            Expanded(
              child: Text(
                'Concordo com os Termos de Uso e Política de Privacidade',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 