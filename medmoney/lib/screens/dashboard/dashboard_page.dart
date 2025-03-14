import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  // URL do dashboard Lovable
  final String _dashboardUrl = 'https://dashboard.medmoney.app';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            // Injetar token de autenticação se necessário
            _injectAuthToken();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Erro ao carregar o dashboard: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_dashboardUrl));
  }

  // Injetar token de autenticação no WebView para manter a sessão
  Future<void> _injectAuthToken() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      final token = await SupabaseService.client.auth.refreshSession();
      final script = '''
        localStorage.setItem('authToken', '${token.session?.accessToken}');
        console.log('Token de autenticação injetado');
      ''';
      _webViewController.runJavaScript(script);
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
          IconButton(
            icon: const Icon(Icons.refresh, size: 26),
            onPressed: () {
              _webViewController.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 26),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // WebView do dashboard
          WebViewWidget(controller: _webViewController),
          
          // Indicador de carregamento
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
            
          // Mensagem de erro
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _webViewController.reload();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
} 