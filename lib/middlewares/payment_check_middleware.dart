import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/payment_required_page.dart';

class PaymentCheckMiddleware extends StatefulWidget {
  final Widget child;

  const PaymentCheckMiddleware({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<PaymentCheckMiddleware> createState() => _PaymentCheckMiddlewareState();
}

class _PaymentCheckMiddlewareState extends State<PaymentCheckMiddleware> {
  bool _isLoading = true;
  bool _hasActiveSubscription = false;
  
  // Lista de rotas públicas que não precisam de verificação
  final List<String> _publicRoutes = [
    '/',
    '/login',
    '/register',
    '/payment-required',
    '/forgot-password',
    '/reset-password',
    '/dashboard', // Permitir acesso ao dashboard sem verificação
  ];

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      // Verificar se o usuário está autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _hasActiveSubscription = false;
        });
        return;
      }
      
      // Buscar assinaturas ativas do usuário
      final response = await Supabase.instance.client
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1);
      
      // Se encontrou pelo menos uma assinatura ativa, o usuário tem acesso
      setState(() {
        _isLoading = false;
        _hasActiveSubscription = response.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Erro ao verificar assinatura ativa: $e');
      setState(() {
        _isLoading = false;
        _hasActiveSubscription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar a rota atual
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    
    // Se estivermos na página de pagamento, não verificamos assinatura
    if (currentRoute.startsWith('/payment')) {
      return widget.child;
    }
    
    // Permitir acesso às rotas públicas sem verificação
    if (_publicRoutes.contains(currentRoute)) {
      return widget.child;
    }
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!_hasActiveSubscription) {
      // Não redirecionar se já estamos no dashboard ou em uma página pública
      if (!currentRoute.contains('/payment') && 
          !currentRoute.contains('/dashboard') && 
          !_publicRoutes.contains(currentRoute)) {
        Future.microtask(() {
          Navigator.pushReplacementNamed(context, '/dashboard'); // Ir para o dashboard em vez da página de pagamento
        });
      }
      
      // Retornar o widget filho para permitir o acesso
      return widget.child;
    }
    
    return widget.child;
  }
} 