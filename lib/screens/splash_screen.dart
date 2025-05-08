import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Aguardar um tempo mínimo para mostrar a animação
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Verificar se o usuário está autenticado
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      debugPrint('Verificando autenticação: ${currentUser != null ? 'Usuário autenticado' : 'Usuário não autenticado'}');
      
      if (currentUser != null) {
        // Usuário autenticado, verificar tipo de acesso
        try {
          final supabaseService = SupabaseService();
          final accessType = await supabaseService.checkUserAccessType();
          
          debugPrint('Tipo de acesso do usuário: $accessType');
          
          // Redirecionar para a tela de login em vez do dashboard
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        } catch (e) {
          debugPrint('Erro ao verificar assinatura: $e');
          
          // Verificar se o erro é devido à tabela inexistente
          if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('É necessário configurar o banco de dados. Verifique o arquivo SUPABASE_SETUP.md para instruções.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
          
          // Em caso de erro, direcionar para a tela de pagamento por segurança
          Navigator.pushReplacementNamed(
            context, 
            AppRoutes.payment,
            arguments: {
              'planName': 'Essencial',
              'planType': 'monthly',
              'planPrice': 15.90,
              'setupFee': 0.0,
              'totalPrice': 15.90,
            },
          );
        }
      } else {
        // Usuário não autenticado, navegar para a tela de login
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Erro ao verificar autenticação: $e');
      // Em caso de erro, navegar para a tela de login
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou animação
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Erro ao carregar logo: $error');
                    // Fallback para um ícone quando a imagem falha
                    return Icon(
                      Icons.medical_services,
                      size: 80,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Nome do app
            Text(
              'MedMoney',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            // Subtítulo
            Text(
              'Finanças para profissionais de saúde',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 64),
            // Indicador de carregamento
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
} 