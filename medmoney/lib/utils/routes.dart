import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_page.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/transaction_form_screen.dart';
import '../screens/transaction_list_screen.dart';
import '../screens/shift_form_screen.dart';
import '../screens/shift_list_screen.dart';
import '../screens/appointment_form_screen.dart';
import '../screens/appointment_list_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/payment_success_screen.dart';
import '../screens/payment_failure_screen.dart';
import '../screens/category_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/notification_screen.dart';

class AppRoutes {
  // Nomes das rotas
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String transactionForm = '/transaction-form';
  static const String transactionList = '/transaction-list';
  static const String shiftForm = '/shift-form';
  static const String shiftList = '/shift-list';
  static const String appointmentForm = '/appointment-form';
  static const String appointmentList = '/appointment-list';
  static const String subscription = '/subscription';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment-success';
  static const String paymentFailure = '/payment-failure';
  static const String category = '/category';
  static const String reports = '/reports';
  static const String notification = '/notification';
  
  // Mapa de rotas
  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomePage(),
    dashboard: (context) => const DashboardScreen(),
    profile: (context) => const ProfileScreen(),
    settings: (context) => const SettingsScreen(),
    transactionForm: (context) => const TransactionFormScreen(),
    transactionList: (context) => const TransactionListScreen(),
    shiftForm: (context) => const ShiftFormScreen(),
    shiftList: (context) => const ShiftListScreen(),
    appointmentForm: (context) => const AppointmentFormScreen(),
    appointmentList: (context) => const AppointmentListScreen(),
    subscription: (context) => const SubscriptionScreen(),
    payment: (context) => const PaymentScreen(),
    paymentSuccess: (context) => const PaymentSuccessScreen(),
    paymentFailure: (context) => const PaymentFailureScreen(),
    category: (context) => const CategoryScreen(),
    reports: (context) => const ReportsScreen(),
    notification: (context) => const NotificationScreen(),
  };
} 