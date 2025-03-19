import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../models/subscription.dart';
import '../screens/payment_page.dart';

class SubscriptionStatusPage extends StatefulWidget {
  const SubscriptionStatusPage({Key? key}) : super(key: key);

  @override
  _SubscriptionStatusPageState createState() => _SubscriptionStatusPageState();
}

class _SubscriptionStatusPageState extends State<SubscriptionStatusPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  Subscription? _subscription;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Verificar se há parâmetros na URL (vindo do redirecionamento de pagamento)
    final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
    if (uri.queryParameters.isNotEmpty) {
      final paymentId = uri.queryParameters['payment_id'];
      final externalReference = uri.queryParameters['external_reference'];
      
      if (paymentId != null || externalReference != null) {
        // Se temos parâmetros de pagamento, atualizar a assinatura
        debugPrint('Recebido redirecionamento com paymentId=$paymentId, externalReference=$externalReference');
        _refreshSubscriptionStatus(paymentId, externalReference);
      }
    }
  }
  
  Future<void> _refreshSubscriptionStatus(String? paymentId, String? externalReference) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Aguardar um pouco para dar tempo do webhook ser processado
      await Future.delayed(Duration(seconds: 2));
      
      // Recarregar a assinatura
      await _loadSubscription();
      
      // Mostrar mensagem de sucesso (opcional)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pagamento processado! Sua assinatura foi atualizada.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao atualizar status da assinatura: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _supabaseService.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Usuário não está autenticado';
        });
        return;
      }

      final subscription = await _supabaseService.getUserSubscription(userId);
      setState(() {
        _subscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar assinatura: ${e.toString()}';
      });
    }
  }

  Future<void> _renewSubscription() async {
    if (_subscription == null) return;

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'planName': _subscription!.planName,
        'planType': _subscription!.planType,
        'planPrice': _subscription!.price,
        'setupFee': 0.0,
        'totalPrice': _subscription!.price,
      },
    );
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'green';
      case 'pending':
        return 'orange';
      case 'overdue':
        return 'red';
      case 'cancelled':
        return 'grey';
      default:
        return 'blue';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Ativa';
      case 'pending':
        return 'Pendente';
      case 'overdue':
        return 'Vencida';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  Widget _buildSubscriptionCard() {
    if (_subscription == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Nenhuma assinatura encontrada',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(_subscription!.status);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plano ${_subscription!.planName.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${statusColor.substring(0, 6)}')),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(_subscription!.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Periodicidade', _subscription!.planType == 'monthly' ? 'Mensal' : 'Anual'),
            _buildInfoRow('Valor', _formatCurrency(_subscription!.price)),
            _buildInfoRow('Data de início', _formatDate(_subscription!.startDate)),
            _buildInfoRow('Próxima cobrança', _formatDate(_subscription!.nextBillingDate)),
            _buildInfoRow('Data de expiração', _formatDate(_subscription!.expirationDate)),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _subscription!.status.toLowerCase() == 'active' 
                    ? null 
                    : _renewSubscription,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  _subscription!.status.toLowerCase() == 'active' 
                      ? 'Assinatura Ativa' 
                      : 'Renovar Assinatura',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Status da Assinatura'),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadSubscription,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSubscription,
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSubscriptionCard(),
                        const SizedBox(height: 24),
                        const Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Histórico de Pagamentos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'O histórico de pagamentos estará disponível em breve.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
} 