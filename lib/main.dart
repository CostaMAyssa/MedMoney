import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Importações para as páginas que serão criadas
import 'screens/home_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'services/supabase_service.dart';
import 'services/asaas_service.dart';
import 'utils/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/shift_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/terms_of_use_page.dart';
// import 'api/webhook_handler.dart'; // Webhook será configurado posteriormente

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Carregar variáveis de ambiente
    await dotenv.load(fileName: '.env');
    
    // Obter credenciais do Supabase
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://rwotvxqknrjurqrhxhjv.supabase.co';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3R2eHFrbnJqdXJxcmh4aGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4OTI0MzIsImV4cCI6MjA1NzQ2ODQzMn0.RgrvQZ2ltMtxVFWkcO2fRD2ySSeYdvaHVmM7MNGZt_M';
    
    debugPrint('Inicializando Supabase com URL: $supabaseUrl');
    
    // Inicializar Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
    
    // Webhook será configurado posteriormente após a publicação do projeto
    // Consulte o arquivo WEBHOOK_SETUP.md para instruções detalhadas
    debugPrint('NOTA: O servidor de webhook precisará ser configurado após a publicação');
    debugPrint('Consulte o arquivo WEBHOOK_SETUP.md para instruções detalhadas');
    
    debugPrint('Supabase inicializado com sucesso!');
    
    // Verificar usuário atual
    final currentUser = Supabase.instance.client.auth.currentUser;
    debugPrint('Usuário atual: ${currentUser?.email ?? 'Nenhum usuário autenticado'}');
    
    // Inicializar banco de dados
    final supabaseService = SupabaseService();
    await supabaseService.initializeDatabase();
    
    // Verificar conexão com a API do Asaas
    final asaasService = AsaasService();
    final asaasConnected = await asaasService.checkApiConnection();
    debugPrint('Conexão com a API do Asaas: ${asaasConnected ? 'OK' : 'FALHA'}');
    
    if (!asaasConnected) {
      debugPrint('AVISO: Não foi possível conectar à API do Asaas. Verifique a chave da API e a conexão com a internet.');
    }
    
  } catch (e) {
    debugPrint('Erro ao inicializar serviços: $e');
  }
  
  // Configurar orientação do app
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
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ShiftProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
      initialRoute: AppRoutes.splash, // Iniciar com a tela de splash para verificar autenticação
      routes: {
        ...AppRoutes.routes,
        '/terms-of-use': (context) => const TermsOfUsePage(),
      },
    );
  }
}
