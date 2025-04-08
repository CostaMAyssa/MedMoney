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
      final userId = supabaseService.getCurrentUserId();
      final subscription = userId != null 
          ? await supabaseService.getUserSubscription(userId) 
          : null;
      
      // Usar o método que retorna Map<String, dynamic> para manter compatibilidade
      final subscriptionMap = await supabaseService.getUserSubscriptionMap();
      
      setState(() {
        _subscription = subscriptionMap;
        _isCheckingSubscription = false;
      });
      
      // Verificar se o usuário tem uma assinatura ativa e paga
      bool hasValidSubscription = false;
      
      if (subscriptionMap != null) {
        // Verificar se a assinatura está ativa
        bool isActive = subscriptionMap['status'] == 'active';
        
        // Verificar se o pagamento foi confirmado
        bool isPaid = subscriptionMap['payment_status'] == 'confirmed' || 
                      subscriptionMap['payment_status'] == 'paid';
        
        // Verificar se é um plano premium (que dá acesso ao dashboard)
        bool isPremium = subscriptionMap['plan_name']?.toLowerCase() == 'premium';
        
        // Acesso permitido apenas se todas as condições forem atendidas
        hasValidSubscription = isActive && isPaid && isPremium;
        
        debugPrint('Status da assinatura: ${subscriptionMap['status']}');
        debugPrint('Status do pagamento: ${subscriptionMap['payment_status']}');
        debugPrint('Plano: ${subscriptionMap['plan_name']}');
        debugPrint('Acesso ao dashboard: ${hasValidSubscription ? 'Permitido' : 'Negado'}');
      }
      
      // Se não tiver assinatura válida, redirecionar para a página de planos
      if (!hasValidSubscription) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você precisa de uma assinatura Premium ativa para acessar o dashboard.'),
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
    // Verificar se o usuário tem uma assinatura premium ativa
    bool hasValidSubscription = false;
    
    if (_subscription != null) {
      bool isActive = _subscription!['status'] == 'active';
      bool isPaid = _subscription!['payment_status'] == 'confirmed' || 
                    _subscription!['payment_status'] == 'paid';
      bool isPremium = _subscription!['plan_name']?.toLowerCase() == 'premium';
      
      hasValidSubscription = isActive && isPaid && isPremium;
    }
    
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
                backgroundColor: hasValidSubscription
                    ? AppTheme.successColor.withOpacity(0.2) 
                    : AppTheme.warningColor.withOpacity(0.2),
                label: Text(
                  hasValidSubscription
                      ? 'Premium Ativo' 
                      : _subscription!['plan_name'] == 'Premium' 
                          ? 'Premium Pendente'
                          : 'Básico',
                  style: TextStyle(
                    color: hasValidSubscription
                        ? AppTheme.successColor 
                        : AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                avatar: Icon(
                  hasValidSubscription
                      ? Icons.check_circle 
                      : Icons.warning,
                  color: hasValidSubscription
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
          : !hasValidSubscription
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.desktop_windows, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Dashboard disponível apenas na versão web',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Por favor, acesse o MedMoney em um navegador para visualizar o dashboard completo.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionView() {
    // Verificar se o usuário tem alguma assinatura
    bool hasPendingPremium = _subscription != null && 
                           _subscription!['plan_name']?.toLowerCase() == 'premium' &&
                           _subscription!['status'] != 'cancelled';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasPendingPremium ? Icons.pending_actions : Icons.subscriptions_outlined,
              color: AppTheme.warningColor,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              hasPendingPremium ? 'Pagamento Pendente' : 'Assinatura Premium Necessária',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              hasPendingPremium 
                ? 'Seu pagamento do plano Premium está pendente. Após a confirmação, você terá acesso ao dashboard completo.'
                : 'Para acessar o dashboard completo, você precisa ter uma assinatura Premium ativa.',
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
              child: Text(
                hasPendingPremium ? 'Verificar Status do Pagamento' : 'Ver Planos Disponíveis',
                style: const TextStyle(fontSize: 16),
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