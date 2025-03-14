import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../utils/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/responsive_container.dart';
import '../../services/supabase_service.dart';

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
        // Autenticação com Supabase
        final response = await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null) {
          // Login bem-sucedido
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          // Erro de autenticação
          setState(() {
            _errorMessage = 'Falha na autenticação. Verifique suas credenciais.';
            _isLoading = false;
          });
        }
      } catch (e) {
        // Erro durante a autenticação
        setState(() {
          _errorMessage = 'Erro ao fazer login: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, informe seu email para redefinir a senha.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await SupabaseService.resetPassword(email);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de redefinição de senha enviado. Verifique sua caixa de entrada.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao enviar email de redefinição: ${e.toString()}';
        _isLoading = false;
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
              onRegisterPressed: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
            
            // Conteúdo principal
            ResponsiveContainer(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 16 : 32,
                vertical: 64,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulário de login
                  Expanded(
                    flex: Responsive.isMobile(context) ? 1 : 1,
                    child: _buildLoginForm(context),
                  ),
                  
                  // Imagem lateral (apenas para desktop)
                  if (!Responsive.isMobile(context)) ...[
                    const SizedBox(width: 64),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bem-vindo de volta!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Acesse sua conta para continuar gerenciando suas finanças e plantões de forma eficiente.',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondaryColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Image.network(
                            'https://via.placeholder.com/600x400?text=Login+Illustration',
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                  ],
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

  Widget _buildLoginForm(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrar',
                style: TextStyle(
                  fontSize: 28,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
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
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    'Esqueceu sua senha?',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Entrar',
                onPressed: _login,
                type: ButtonType.primary,
                size: ButtonSize.large,
                isLoading: _isLoading,
                fullWidth: true,
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 32),
              Row(
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
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      'Criar conta',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}