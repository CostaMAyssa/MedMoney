import 'package:flutter/material.dart';

import '../screens/home_page.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/payment_page.dart';
import '../screens/payment_required_page.dart';
import '../screens/splash_screen.dart';
import '../screens/dashboard/dashboard_page.dart';
import '../middlewares/payment_check_middleware.dart';
import '../screens/subscription_status_page.dart';
import '../screens/terms_of_use_page.dart';

class AppRoutes {
  // Definição de rotas
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String splash = '/splash';
  static const String payment = '/payment';
  static const String paymentRequired = '/payment-required';
  static const String paymentSuccess = '/payment-success';
  static const String paymentFailure = '/payment-error';
  static const String subscriptionStatus = '/subscription_status';
  static const String profile = '/profile';
  static const String termsOfUse = '/terms-of-use';

  // Mapa de rotas
  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    login: (context) => const LoginPage(),
    register: (context) {
      final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return RegisterPage(initialData: args);
    },
    dashboard: (context) => const DashboardPage(),
    splash: (context) => const SplashScreen(),
    payment: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      
      // Obter valores diretamente dos argumentos, sem recalcular
      final planName = args['planName'] as String;
      final planType = args['planType'] as String;
      final planPrice = args['planPrice'] as double;
      final setupFee = args['setupFee'] as double;
      final totalPrice = args['totalPrice'] as double;
      
      return PaymentPage(
        planName: planName,
        planType: planType,
        planPrice: planPrice,
        setupFee: setupFee,
        totalPrice: totalPrice,
      );
    },
    paymentRequired: (context) => const PaymentRequiredPage(),
    subscriptionStatus: (context) => const SubscriptionStatusPage(),
    profile: (context) => Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: const Center(
        child: Text('Página de perfil em desenvolvimento', style: TextStyle(fontSize: 18)),
      ),
    ),
    termsOfUse: (context) => const TermsOfUsePage(),
  };
} 