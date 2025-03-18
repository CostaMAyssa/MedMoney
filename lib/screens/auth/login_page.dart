import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../utils/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/responsive_container.dart';
import '../../services/supabase_service.dart';
import '../../utils/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        debugPrint('Iniciando login com email: ${_emailController.text.trim()}');
        
        final supabaseService = SupabaseService();
        final response = await supabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        debugPrint('Resposta do login: ${response.user != null ? 'Sucesso' : 'Falha'}');

        if (response.user != null) {
          // Login bem-sucedido
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login realizado com sucesso!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            
            // Verificar se o usuário tem uma assinatura ativa
            try {
              final userId = supabaseService.getCurrentUserId();
              final subscription = userId != null 
                  ? await supabaseService.getUserSubscription(userId) 
                  : null;
              
              if (subscription != null && subscription.status == 'active') {
                // Usuário tem assinatura ativa, navegar para o dashboard
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              } else {
                // Usuário não tem assinatura ativa, navegar para a tela de pagamento
                Navigator.pushReplacementNamed(
                  context, 
                  AppRoutes.payment,
                  arguments: {
                    'planName': 'Básico',
                    'planType': 'monthly',
                    'planPrice': 19.90,
                    'setupFee': 49.90,
                    'totalPrice': 69.80,
                  },
                );
              }
            } catch (e) {
              debugPrint('Erro ao verificar assinatura: $e');
              
              // Verificar se o erro é devido à tabela inexistente
              if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('É necessário configurar o banco de dados. Verifique o arquivo SUPABASE_SETUP.md para instruções.'),
                    backgroundColor: AppTheme.warningColor,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              
              // Em caso de erro, direcionar para a tela de pagamento por segurança
              Navigator.pushReplacementNamed(
                context, 
                AppRoutes.payment,
                arguments: {
                  'planName': 'Básico',
                  'planType': 'monthly',
                  'planPrice': 19.90,
                  'setupFee': 49.90,
                  'totalPrice': 69.80,
                },
              );
            }
          }
        } else {
          // Erro no login
          setState(() {
            _errorMessage = 'Credenciais inválidas. Verifique seu email e senha.';
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Erro detalhado no login: $e');
        
        String errorMsg = 'Erro ao fazer login';
        
        // Verificar tipos específicos de erro
        if (e.toString().contains('Email not confirmed')) {
          errorMsg = 'Email não confirmado. Verifique sua caixa de entrada para confirmar seu email.';
        } else if (e.toString().contains('Invalid login credentials')) {
          errorMsg = 'Credenciais inválidas. Verifique seu email e senha.';
        } else if (e.toString().contains('network')) {
          errorMsg = 'Erro de conexão. Verifique sua internet.';
        }
        
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho
            AppHeader(
              onRegisterPressed: () {
                Navigator.pushNamed(context, AppRoutes.register);
              },
            ),
            
            // Conteúdo principal
            ResponsiveContainer(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 16 : 32,
                vertical: 64,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Seção de boas-vindas (visível apenas em desktop)
                  if (!Responsive.isMobile(context))
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bem-vindo de volta!',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Acesse sua conta para continuar gerenciando suas finanças e plantões de forma eficiente.',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Ícone médico em vez da imagem
                          Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.medical_services_outlined,
                                size: 150,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (!Responsive.isMobile(context))
                    const SizedBox(width: 64),
                  
                  // Formulário de login
                  Expanded(
                    child: Card(
                      elevation: 4,
                      color: Color(0xFF1A1A4F), // Cor escura para o fundo do card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Informe seus dados para acessar sua conta',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
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
                            
                            // Formulário de login
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    hint: 'Seu email',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, informe seu email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Senha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
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
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        // Implementar recuperação de senha
                                      },
                                      child: Text(
                                        'Esqueceu sua senha?',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    child: CustomButton(
                                      text: 'Entrar',
                                      onPressed: _login,
                                      type: ButtonType.primary,
                                      size: ButtonSize.large,
                                      isLoading: _isLoading,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Divisor
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: AppTheme.textSecondaryColor.withOpacity(0.3),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'ou',
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: AppTheme.textSecondaryColor.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Link para criar conta
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Não tem uma conta?',
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushNamed(context, AppRoutes.register);
                                          },
                                          child: Text(
                                            'Criar conta',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w600,
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
                        ),
                      ),
                    ),
                  ),
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
}