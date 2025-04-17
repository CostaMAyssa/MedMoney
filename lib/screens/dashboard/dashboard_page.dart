import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
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
import 'dart:convert';

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
  
  // URL do dashboard React
  String _dashboardUrl = 'http://medmoney.me:8081'; // Apontando diretamente para o VPS para testes
  
  // ID único para o iframe
  final String _iframeElementId = 'dashboard-iframe';
  
  // Controle do erro de carregamento do iframe
  bool _iframeError = false;

  @override
  void initState() {
    super.initState();
    debugPrint('===== INICIANDO DASHBOARD =====');
    debugPrint('Modo: ${kIsWeb ? "Web/Iframe" : "Mobile/WebView"}');
    
    _checkSubscription();
    
    if (kIsWeb) {
      // No Flutter Web, usamos um iframe
      setState(() {
        _isLoading = false;
      });
      
      // Registramos o iframe após a construção do widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('Registrando iframe para o dashboard...');
        _registerIframe();
      });
    } else {
      // Em dispositivos móveis, configuramos o WebView
      debugPrint('Inicializando WebView para o dashboard...');
      _initWebView();
    }
  }
  
  // Registrar o iframe para uso no Flutter Web
  void _registerIframe() {
    // Obter token para autenticação
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    
    debugPrint('Token obtido: ${token != null ? "Sim (${token.substring(0, 10)}...)" : "Não"}');
    
    // URL simplificada com apenas o token, como o dashboard espera
    final dashboardUrlWithAuth = Uri.parse(_dashboardUrl).replace(
      queryParameters: {
        'token': token,
        // Removido userId e refreshToken pois o dashboard não os processa
      },
    ).toString();
    
    debugPrint('Carregando dashboard React de: $dashboardUrlWithAuth');
    
    // Registrar um elemento de visualização para o iframe
    ui_web.platformViewRegistry.registerViewFactory(
      _iframeElementId,
      (int viewId) {
        debugPrint('Criando elemento iframe (viewId: $viewId)');
        final iframe = html.IFrameElement()
          ..src = dashboardUrlWithAuth
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..style.backgroundColor = '#0A0A3E'
          ..allowFullscreen = true;
        
        // Permitir comunicação e recursos
        iframe.setAttribute('allow', 'autoplay; camera; microphone; fullscreen');
        
        // Monitorar carregamento e erros
        iframe.onLoad.listen((_) {
          debugPrint('Dashboard carregado com sucesso no iframe');
          setState(() {
            _isLoading = false;
          });
        });
        
        iframe.onError.listen((event) {
          debugPrint('ERRO ao carregar o dashboard React: $event');
          setState(() {
            _iframeError = true;
          });
        });
        
        // Adicionar listener para mensagens do console do iframe (para debug)
        html.window.addEventListener('message', (event) {
          if (event is html.MessageEvent) {
            debugPrint('Mensagem recebida do iframe: ${event.data}');
          }
        });
        
        return iframe;
      },
    );
  }
  
  // Inicializar WebView para dispositivos móveis
  void _initWebView() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    
    // URL simplificada apenas com o token
    final dashboardUrl = Uri.parse(_dashboardUrl).replace(
      queryParameters: {
        'token': token,
        // Removido userId e refreshToken
      },
    ).toString();
    
    debugPrint('Inicializando WebView para dashboard: $dashboardUrl');
    
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
            
            // Removido código que tentava injetar tokens no localStorage
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Erro ao carregar dashboard: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(dashboardUrl));
  }
  
  // Processar mensagens recebidas do dashboard
  void _handleDashboardMessage(String message) {
    debugPrint('Mensagem recebida do dashboard React: $message');
    
    try {
      // Processar diferentes tipos de mensagens do dashboard React
      if (message.contains('DATA_UPDATED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados no dashboard'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (message.contains('AUTH_ERROR')) {
        _logout();
      } else if (message.contains('TOKEN_REFRESH_NEEDED')) {
        // Atualizar token e enviar de volta
        _refreshToken();
      }
    } catch (e) {
      debugPrint('Erro ao processar mensagem do dashboard: $e');
    }
  }
  
  // Método para atualizar token
  Future<void> _refreshToken() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      if (session != null) {
        // Atualizar sessão
        final newToken = session.accessToken;
        
        // Enviar novo token para o iframe/webview
        if (kIsWeb) {
          final message = {
            'type': 'TOKEN_REFRESHED',
            'data': {
              'token': newToken,
            }
          };
          final jsonMessage = json.encode(message);
          
          // Enviar através do postMessage
          html.window.postMessage(jsonMessage, '*');
        } else if (_webViewController != null) {
          // Atualizar token no localStorage do WebView
          _webViewController!.runJavaScript('''
            localStorage.setItem('supabaseToken', '$newToken');
            window.dispatchEvent(new CustomEvent('tokenRefreshed', {
              detail: { token: '$newToken' }
            }));
          ''');
        }
      }
    } catch (e) {
      debugPrint('Erro ao atualizar token: $e');
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
      
      // TEMPORÁRIO: Forçar acesso ao dashboard para testes
      // Comentado verificação de assinatura para isolar o problema
      /*
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
      */
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
    // TEMPORÁRIO: Forçar acesso ao dashboard para teste
    bool hasValidSubscription = true; // Forçando acesso
    
    /*
    if (_subscription != null) {
      bool isActive = _subscription!['status'] == 'active';
      bool isPaid = _subscription!['payment_status'] == 'confirmed' || 
                    _subscription!['payment_status'] == 'paid';
      bool isPremium = _subscription!['plan_name']?.toLowerCase().contains('premium') ?? false;
      
      hasValidSubscription = isActive && isPaid && isPremium;
    }
    */
    
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
    // Fallback em caso de erro no carregamento do iframe
    if (_iframeError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'Não foi possível carregar o dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tentando carregar o dashboard de: $_dashboardUrl',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _iframeError = false;
                });
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    
    // Usar HtmlElementView para renderizar o iframe no Flutter Web
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: HtmlElementView(
            viewType: _iframeElementId,
          ),
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
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