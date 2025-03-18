import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/home_page.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/dashboard/dashboard_page.dart';
import '../screens/payment_page.dart';
import '../screens/payment_required_page.dart';
import '../middlewares/payment_check_middleware.dart';
import '../screens/subscription_status_page.dart';

class AppRoutes {
  // Definição das rotas
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String splash = '/splash';
  static const String payment = '/payment';
  static const String paymentRequired = '/payment-required';
  static const String paymentSuccess = '/payment_success';
  static const String paymentFailure = '/payment_failure';
  static const String subscriptionStatus = '/subscription_status';
  static const String profile = '/profile';

  // Mapa de rotas
  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    dashboard: (context) => const PaymentCheckMiddleware(
      child: DashboardPage(),
    ),
    splash: (context) => const SplashScreen(),
    payment: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return PaymentPage(
        planName: args['planName'],
        planType: args['planType'],
        planPrice: args['planPrice'],
        setupFee: args['setupFee'],
        totalPrice: args['totalPrice'],
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
  };
} 