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
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!_hasActiveSubscription) {
      return PaymentRequiredPage();
    }
    
    return widget.child;
  }
} 