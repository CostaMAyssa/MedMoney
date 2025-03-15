import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Importações condicionais para web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import '../../services/supabase_service.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCheckingSubscription = true;
  Map<String, dynamic>? _subscription;
  
  // URL do dashboard Lovable
  final String _dashboardUrl = 'https://medmoney-visuals.lovable.app';
  
  // ID único para o iframe
  final String _iframeElementId = 'dashboard-iframe';

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    
    if (kIsWeb) {
      // No Flutter Web, usamos um iframe
      setState(() {
        _isLoading = false;
      });
      
      // Registramos o iframe após a construção do widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerIframe();
      });
    } else {
      // Em dispositivos móveis, apenas definimos que não está carregando
      setState(() {
        _isLoading = false;
        _errorMessage = 'O dashboard está disponível apenas na versão web.';
      });
    }
  }
  
  // Registrar o iframe para uso no Flutter Web
  void _registerIframe() {
    // Registrar um elemento de visualização para o iframe
    ui_web.platformViewRegistry.registerViewFactory(
      _iframeElementId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = _dashboardUrl
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..allowFullscreen = true;
        
        return iframe;
      },
    );
  }

  // Verificar se o usuário tem uma assinatura ativa
  Future<void> _checkSubscription() async {
    try {
      setState(() {
        _isCheckingSubscription = true;
      });
      
      final supabaseService = SupabaseService();
      final subscription = await supabaseService.getUserSubscription();
      
      setState(() {
        _subscription = subscription;
        _isCheckingSubscription = false;
      });
      
      // Se não tiver assinatura ativa, redirecionar para a página de planos
      if (subscription == null || subscription['status'] != 'active') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você não possui uma assinatura ativa. Por favor, escolha um plano.'),
              backgroundColor: AppTheme.warningColor,
              duration: Duration(seconds: 5),
            ),
          );
          
          // Redirecionar para a página de planos após 2 segundos
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar assinatura: $e');
      setState(() {
        _isCheckingSubscription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Exibir status da assinatura
          if (_subscription != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                backgroundColor: _subscription!['status'] == 'active' 
                    ? AppTheme.successColor.withOpacity(0.2) 
                    : AppTheme.warningColor.withOpacity(0.2),
                label: Text(
                  _subscription!['status'] == 'active' 
                      ? 'Assinatura Ativa' 
                      : 'Assinatura ${_subscription!['status']}',
                  style: TextStyle(
                    color: _subscription!['status'] == 'active' 
                        ? AppTheme.successColor 
                        : AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                avatar: Icon(
                  _subscription!['status'] == 'active' 
                      ? Icons.check_circle 
                      : Icons.warning,
                  color: _subscription!['status'] == 'active' 
                      ? AppTheme.successColor 
                      : AppTheme.warningColor,
                  size: 16,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, size: 26),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isCheckingSubscription
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Verificando sua assinatura...',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _subscription == null || _subscription!['status'] != 'active'
              ? _buildNoSubscriptionView()
              : kIsWeb
                  ? _buildWebDashboard()
                  : _buildMobileMessage(),
    );
  }

  Widget _buildWebDashboard() {
    // Usar HtmlElementView para renderizar o iframe no Flutter Web
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: HtmlElementView(
        viewType: _iframeElementId,
      ),
    );
  }

  Widget _buildMobileMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.computer,
              color: AppTheme.warningColor,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Versão Web Recomendada',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Para uma melhor experiência com o dashboard, recomendamos acessar através de um navegador web em um computador.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              color: AppTheme.warningColor,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Assinatura Necessária',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Para acessar o dashboard completo, você precisa ter uma assinatura ativa.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Ver Planos Disponíveis',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final supabaseService = SupabaseService();
      await supabaseService.signOut();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 