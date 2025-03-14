import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Importações para as páginas que serão criadas
import 'screens/home_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'screens/payment_page.dart';
import 'utils/theme.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientação para retrato apenas
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Definir o nome do aplicativo para a tela de splash
  SystemChrome.setApplicationSwitcherDescription(
    ApplicationSwitcherDescription(
      label: 'MedMoney',
      primaryColor: AppTheme.backgroundColor.value,
    ),
  );
  
  // Inicializar o Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedMoney',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Usar o tema escuro por padrão
      initialRoute: SupabaseService.isAuthenticated() ? '/dashboard' : '/',
      onGenerateRoute: (settings) {
        // Capturar argumentos para navegação entre seções
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => HomePage(initialSection: settings.arguments as String?),
          );
        }
        
        // Rota para o dashboard (WebView para o Lovable)
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(
            builder: (context) => const DashboardPage(),
          );
        }
        
        // Rota para a página de pagamento
        if (settings.name == '/payment') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PaymentPage(
              planName: args['planName'],
              planType: args['planType'],
              planPrice: args['planPrice'],
              setupFee: args['setupFee'],
              totalPrice: args['totalPrice'],
            ),
          );
        }
        
        // Outras rotas
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginPage());
          case '/register':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => RegisterPage(initialData: args),
            );
          default:
            return MaterialPageRoute(builder: (context) => const HomePage());
        }
      },
    );
  }
}
