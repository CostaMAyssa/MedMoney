import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Importações condicionais para web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  WebViewController? _webViewController;
  
  // URL do dashboard
  // final String _dashboardUrl = 'https://medmoney-visuals.lovable.app';
  final String _dashboardUrl = 'http://medmoney.me:8081';
  
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
      // Em dispositivos móveis, configuramos o WebView
      _initWebView();
    }
  }
  
  // Inicializar WebView para dispositivos móveis
  void _initWebView() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    // URL do dashboard com parâmetros de autenticação
    final dashboardUrl = '$_dashboardUrl?token=$token&userId=$userId';
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Erro ao carregar dashboard: ${error.description}';
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'MedMoneyApp',
        onMessageReceived: (JavaScriptMessage message) {
          _handleDashboardMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(dashboardUrl));
  }
  
  // Registrar o iframe para uso no Flutter Web
  void _registerIframe() {
    // Obter token e ID do usuário para autenticação
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    // URL completa com parâmetros de autenticação
    final dashboardUrlWithAuth = '$_dashboardUrl?token=$token&userId=$userId';
    
    // Registrar um elemento de visualização para o iframe
    ui_web.platformViewRegistry.registerViewFactory(
      _iframeElementId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = dashboardUrlWithAuth
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..allowFullscreen = true;
        
        // Configurar comunicação entre iframe e Flutter
        html.window.addEventListener('message', (event) {
          if (event is html.MessageEvent) {
            _handleDashboardMessage(event.data.toString());
          }
        });
        
        return iframe;
      },
    );
  }
  
  // Processar mensagens recebidas do dashboard
  void _handleDashboardMessage(String message) {
    debugPrint('Mensagem recebida do dashboard: $message');
    
    try {
      // Processar diferentes tipos de mensagens
      if (message.contains('DATA_UPDATED')) {
        // Atualizar dados do app conforme necessário
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados no dashboard'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (message.contains('AUTH_ERROR')) {
        // Tratar erros de autenticação
        _logout();
      }
    } catch (e) {
      debugPrint('Erro ao processar mensagem do dashboard: $e');
    }
  }
  
  // Enviar mensagem para o dashboard (para dispositivos móveis)
  void _sendMessageToDashboard(String message) {
    if (!kIsWeb && _webViewController != null) {
      _webViewController!.runJavaScript(
        '''
        window.postMessage(
          JSON.stringify($message),
          '*'
        );
        '''
      );
    }
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
        bool isPremium = subscriptionMap['plan_name']?.toLowerCase().contains('premium') ?? false;
        
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
      bool isPremium = _subscription!['plan_name']?.toLowerCase().contains('premium') ?? false;
      
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
                  : _buildMobileDashboard(),
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

  Widget _buildMobileDashboard() {
    if (_webViewController == null) {
      return const Center(
        child: Text('Erro ao inicializar o dashboard'),
      );
    }
    
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController!),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
        if (_errorMessage != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isLoading = true;
                      });
                      _initWebView();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoSubscriptionView() {
    // Verificar se o usuário tem alguma assinatura
    bool hasPendingPremium = _subscription != null && 
                           _subscription!['plan_name']?.toLowerCase().contains('premium') == true &&
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