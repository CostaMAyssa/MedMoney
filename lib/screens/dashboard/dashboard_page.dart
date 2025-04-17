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
import 'dart:async';

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
  
  // URL de fallback caso a primeira falhe (para testes)
  String _fallbackDashboardUrl = 'https://medmoney-dashboard.vercel.app'; // URL alternativa
  
  // Controle se estamos usando a URL principal ou fallback
  bool _usingFallbackUrl = false;
  
  // ID único para o iframe
  final String _iframeElementId = 'dashboard-iframe';
  
  // Controle do erro de carregamento do iframe
  bool _iframeError = false;

  @override
  void initState() {
    super.initState();
    debugPrint('===== INICIANDO DASHBOARD =====');
    debugPrint('Modo: ${kIsWeb ? "Web/Iframe" : "Mobile/WebView"}');
    debugPrint('URL inicial: $_dashboardUrl');
    
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
  
  // Alternar entre a URL principal e fallback
  void _toggleDashboardUrl() {
    setState(() {
      _usingFallbackUrl = !_usingFallbackUrl;
      _isLoading = true;
      _iframeError = false;
    });
    
    final newUrl = _usingFallbackUrl ? _fallbackDashboardUrl : _dashboardUrl;
    debugPrint('Alternando para ${_usingFallbackUrl ? "URL FALLBACK" : "URL PRINCIPAL"}: $newUrl');
    
    if (kIsWeb) {
      _registerIframe();
    } else if (_webViewController != null) {
      _initWebView();
    }
  }
  
  // Registrar o iframe para uso no Flutter Web
  void _registerIframe() {
    debugPrint('[Dashboard] Registrando iframe com ID: $_iframeElementId');
    
    // Obtendo tokens e ID do usuário
    final session = Supabase.instance.client.auth.currentSession;
    final String? token = session?.accessToken;
    final String? refreshToken = session?.refreshToken;
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    
    debugPrint('[Dashboard] Token disponível: ${token != null}');
    debugPrint('[Dashboard] User ID disponível: ${userId != null}');
    
    if (token == null || userId == null) {
      debugPrint('[Dashboard] ERRO: Token ou User ID não disponíveis');
      setState(() {
        _iframeError = true;
        _errorMessage = 'Erro de autenticação. Por favor, faça login novamente.';
        _isLoading = false;
      });
      return;
    }

    // Construir URL com parâmetros de autenticação
    final baseUrl = _usingFallbackUrl ? _fallbackDashboardUrl : _dashboardUrl;
    final url = Uri.parse(baseUrl).replace(
      queryParameters: {
        'token': token,
        'userId': userId,
        'refreshToken': refreshToken,
        't': DateTime.now().millisecondsSinceEpoch.toString(), // Evita cache
      },
    ).toString();
    
    debugPrint('[Dashboard] Carregando URL: $url');

    // Criar e configurar elemento iframe
    ui_web.platformViewRegistry.registerViewFactory(_iframeElementId, (int viewId) {
      final iframe = html.IFrameElement()
        ..id = 'dashboard-iframe'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..src = url
        ..allow = 'camera; microphone; fullscreen; display-capture'
        ..allowFullscreen = true;
      
      // Monitorar erros de carregamento
      iframe.onError.listen((event) {
        debugPrint('[Dashboard] ERRO ao carregar iframe: ${event.toString()}');
        _setIframeError(true);
      });

      // Monitorar carregamento do iframe
      iframe.onLoad.listen((event) {
        debugPrint('[Dashboard] Iframe carregado com sucesso');
        _setIframeError(false);
        
        // Enviar mensagem com os dados de autenticação para o dashboard
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            // Atenção: formato adaptado para o que o React espera
            final authMessage = {
              'type': 'AUTH_DATA',
              'token': token,
              'userId': userId,
              'refreshToken': refreshToken,
            };
            
            debugPrint('[Dashboard] Enviando dados de autenticação via postMessage');
            iframe.contentWindow?.postMessage(jsonEncode(authMessage), '*');
          } catch (e) {
            debugPrint('[Dashboard] ERRO ao enviar mensagem para iframe: $e');
          }
        });
      });

      return iframe;
    });

    // Configurar listener para mensagens do iframe
    html.window.onMessage.listen((html.MessageEvent event) {
      try {
        debugPrint('[Dashboard] Mensagem recebida do iframe: ${event.data}');
        
        // Tentar decodificar a mensagem
        // Mas primeiro verificar se é uma string de JSON válida
        if (event.data is String && event.data.toString().trim().startsWith('{')) {
          final data = jsonDecode(event.data);
          _processMessageFromDashboard(data);
        } else {
          debugPrint('[Dashboard] Formato de mensagem não reconhecido, ignorando');
        }
      } catch (e) {
        debugPrint('[Dashboard] ERRO ao processar mensagem do iframe: $e');
      }
    });

    Future.delayed(Duration(seconds: 5), () {
      if (_isLoading && mounted) {
        debugPrint('[Dashboard] Timeout de carregamento, verificando estado do iframe');
        final iframe = html.document.getElementById('dashboard-iframe') as html.IFrameElement?;
        
        if (iframe == null) {
          debugPrint('[Dashboard] Iframe não encontrado no DOM');
          _setIframeError(true);
        } else {
          debugPrint('[Dashboard] Iframe está presente no DOM');
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  // Inicializar WebView para dispositivos móveis
  void _initWebView() {
    debugPrint('[Dashboard] Inicializando WebView para dispositivos móveis');
    
    final session = Supabase.instance.client.auth.currentSession;
    final String? token = session?.accessToken;
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    
    if (token == null || userId == null) {
      setState(() {
        _errorMessage = 'Erro de autenticação. Por favor, faça login novamente.';
        _isLoading = false;
      });
      return;
    }
    
    // Escolher URL base (principal ou fallback)
    final baseUrl = _usingFallbackUrl ? _fallbackDashboardUrl : _dashboardUrl;
    
    // URL com os tokens necessários
    final url = Uri.parse(baseUrl).replace(
      queryParameters: {
        'token': token,
        'userId': userId,
        'refreshToken': session?.refreshToken,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    ).toString();
    
    debugPrint('[Dashboard] Carregando URL no WebView: $url');
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              
              // Injetar script para adicionar listener de mensagem
              _webViewController?.runJavaScript('''
                window.addEventListener('message', function(event) {
                  console.log('Mensagem recebida no WebView:', event.data);
                  window.flutter_inappwebview.callHandler('messageHandler', event.data);
                });
                
                // Notificar que o WebView está pronto
                window.parent.postMessage(JSON.stringify({
                  type: 'WEBVIEW_READY'
                }), '*');
              ''');
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[Dashboard] ERRO WebView: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Erro ao carregar dashboard: ${error.description}';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _setIframeError(bool hasError) {
    if (mounted) {
      setState(() {
        _iframeError = hasError;
        _isLoading = false;
        if (hasError) {
          _errorMessage = 'Não foi possível carregar o dashboard. Verifique sua conexão.';
        } else {
          _errorMessage = null;
        }
      });
    }
  }

  void _processMessageFromDashboard(Map<String, dynamic> data) {
    if (!mounted) return;
    
    debugPrint('[Dashboard] Processando mensagem: ${data['type']}');
    
    switch (data['type']) {
      case 'DASHBOARD_READY':
        debugPrint('[Dashboard] Dashboard pronto para receber dados');
        setState(() {
          _isLoading = false;
        });
        
        // Reenvia os dados de autenticação para garantir
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null && kIsWeb) {
          final authData = {
            'type': 'AUTH_DATA',
            'token': session.accessToken,
            'userId': Supabase.instance.client.auth.currentUser?.id,
            'refreshToken': session.refreshToken,
          };
          
          debugPrint('[Dashboard] Reenviando dados de autenticação após DASHBOARD_READY');
          final iframe = html.document.getElementById('dashboard-iframe') as html.IFrameElement?;
          iframe?.contentWindow?.postMessage(jsonEncode(authData), '*');
        }
        break;
      case 'TOKEN_EXPIRED':
        debugPrint('[Dashboard] Token expirado, tentando renovar');
        _refreshToken();
        break;
      case 'UPDATE_SUBSCRIPTION':
        debugPrint('[Dashboard] Atualizando informações de assinatura');
        _checkSubscription();
        break;
      case 'ERROR':
        debugPrint('[Dashboard] Erro reportado pelo dashboard: ${data['message']}');
        setState(() {
          _errorMessage = data['message'] ?? 'Erro no dashboard';
        });
        break;
      case 'LOGOUT':
        debugPrint('[Dashboard] Solicitação de logout recebida');
        _logout();
        break;
      default:
        debugPrint('[Dashboard] Tipo de mensagem não reconhecido: ${data['type']}');
    }
  }

  Future<void> _refreshToken() async {
    debugPrint('[Dashboard] Iniciando renovação de token');
    try {
      // Obter nova sessão
      final response = await Supabase.instance.client.auth.refreshSession();
      final session = response.session;
      
      if (session != null) {
        debugPrint('[Dashboard] Token renovado com sucesso');
        // Enviar novo token para o iframe
        if (kIsWeb) {
          final authData = {
            'type': 'AUTH_DATA',
            'token': session.accessToken,
            'userId': session.user.id,
            'refreshToken': session.refreshToken,
          };
          
          final iframe = html.document.getElementById('dashboard-iframe') as html.IFrameElement?;
          iframe?.contentWindow?.postMessage(jsonEncode(authData), '*');
          debugPrint('[Dashboard] Novo token enviado para o dashboard');
        } else if (_webViewController != null) {
          // Para WebView mobile
          final authData = jsonEncode({
            'type': 'AUTH_DATA',
            'token': session.accessToken,
            'userId': session.user.id,
            'refreshToken': session.refreshToken,
          });
          
          await _webViewController?.runJavaScript(
            "window.postMessage($authData, '*');"
          );
          debugPrint('[Dashboard] Novo token enviado para WebView');
        }
      } else {
        debugPrint('[Dashboard] Falha ao renovar token: sessão nula');
        // Token não pode ser renovado, redirecionar para login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sua sessão expirou. Por favor, faça login novamente.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    } catch (e) {
      debugPrint('[Dashboard] Erro ao renovar token: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao renovar sessão: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Em caso de erro grave, redirecionar para login
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
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
      if (mounted) {
        setState(() {
          _isCheckingSubscription = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Limpar controlador do WebView
    _webViewController = null;
    super.dispose();
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  _usingFallbackUrl ? 'URL alternativa' : 'URL principal',
                  style: TextStyle(
                    fontSize: 12,
                    color: _usingFallbackUrl ? Colors.amber : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Botão para abrir no navegador (apenas Web)
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 26),
              onPressed: () {
                // Obter URL com token
                final token = Supabase.instance.client.auth.currentSession?.accessToken;
                final baseUrl = _usingFallbackUrl ? _fallbackDashboardUrl : _dashboardUrl;
                final urlWithToken = Uri.parse(baseUrl).replace(
                  queryParameters: {
                    'token': token,
                  },
                ).toString();
                
                // Abrir em nova janela
                html.window.open(urlWithToken, '_blank');
              },
              tooltip: 'Abrir em nova janela',
            ),
          // Botão para recarregar o dashboard
          IconButton(
            icon: const Icon(Icons.refresh, size: 26),
            onPressed: () {
              debugPrint('Recarregando dashboard...');
              setState(() {
                _isLoading = true;
                _iframeError = false;
                _errorMessage = null;
              });
              if (kIsWeb) {
                _registerIframe();
              } else if (_webViewController != null) {
                _initWebView();
              }
            },
          ),
          // Botão para alternar URL
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 26),
            onPressed: () {
              _toggleDashboardUrl();
            },
            tooltip: _usingFallbackUrl ? 'Usar URL principal' : 'Usar URL alternativa',
          ),
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
          // Botão para visualizar logs (Apenas em modo debug)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.info_outline, size: 26),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Informações de Depuração'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('URL: ${_usingFallbackUrl ? _fallbackDashboardUrl : _dashboardUrl}'),
                          const SizedBox(height: 8),
                          Text('Token disponível: ${Supabase.instance.client.auth.currentSession?.accessToken != null}'),
                          Text('User ID: ${Supabase.instance.client.auth.currentUser?.id ?? "Não disponível"}'),
                          const SizedBox(height: 8),
                          Text('Status: ${_isLoading ? "Carregando" : _iframeError ? "Erro" : "Carregado"}'),
                          if (_errorMessage != null)
                            Text('Erro: $_errorMessage', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Fechar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _isLoading = true;
                            _iframeError = false;
                          });
                          if (kIsWeb) {
                            _registerIframe();
                          } else if (_webViewController != null) {
                            _initWebView();
                          }
                        },
                        child: const Text('Recarregar'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Informações de Depuração',
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
              'Tentando carregar o dashboard de: ${_usingFallbackUrl ? _fallbackDashboardUrl : _dashboardUrl}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _iframeError = false;
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _registerIframe();
                  },
                  child: const Text('Tentar novamente'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _toggleDashboardUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  child: Text(_usingFallbackUrl ? 'Usar URL principal' : 'Usar URL alternativa'),
                ),
              ],
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 