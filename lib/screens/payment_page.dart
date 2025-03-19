import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/custom_button.dart';
import '../widgets/responsive_container.dart';
import '../utils/routes.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../providers/payment_provider.dart';
import '../services/asaas_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentPage extends StatefulWidget {
  final String planName;
  final String planType;
  final double planPrice;
  final double setupFee;
  final double totalPrice;
  
  const PaymentPage({
    Key? key,
    required this.planName,
    required this.planType,
    required this.planPrice,
    required this.setupFee,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _initialized = false;
  String? _paymentUrl;
  final AsaasService _asaasService = AsaasService();
  late final SupabaseService _supabaseService;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() => _initializePayment());
    }
  }

  Future<void> _initializePayment() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Solução simplificada: gerar um link direto com parâmetros na URL
      // Isso evita os problemas de CORS ao fazer chamadas diretas à API
      final planType = widget.planType == 'annual' ? 'Anual' : 'Mensal';
      final description = 'Assinatura ${widget.planName} ($planType)';
      
      // Use a URL da sandbox para testes
      final baseUrl = 'https://sandbox.asaas.com/checkout';
      
      // Gerar um código único para referência externa
      final externalReference = 'medmoney_${DateTime.now().millisecondsSinceEpoch}';
      
      // Salvar o plano escolhido pelo usuário no Supabase
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _supabaseService.saveSelectedPlan(
          userId: userId,
          planType: widget.planName,
          billingFrequency: widget.planType,
          price: widget.totalPrice,
          externalReference: externalReference,
          paymentId: null, // Será atualizado quando recebermos o webhook
        );
      } else {
        throw Exception('Usuário não está autenticado');
      }
      
      // Gerar URL do checkout diretamente
      final checkoutUrl = Uri.parse(baseUrl).replace(queryParameters: {
        'externalReference': externalReference,
        'totalValue': widget.totalPrice.toString(),
        'billingType': 'UNDEFINED', // Permite que o cliente escolha
        'name': description,
        'description': 'Assinatura MedMoney - Plano ${widget.planName}',
        'installments': '1', // Parcela única
        'showDescription': 'true',
        'showNoteField': 'false',
        'dueDate': DateTime.now().add(Duration(days: 7)).toIso8601String().split('T')[0],
        'maxInstallmentCount': '1',
        'redirectUrl': 'https://medmoney.app/api/payment/success', // URL de redirecionamento após o pagamento
        'failureRedirectUrl': 'https://medmoney.app/api/payment/failure', // URL de redirecionamento em caso de falha
        'notificationEnabled': 'true',
      }).toString();
      
      if (!mounted) return;
      
      setState(() {
        _paymentUrl = checkoutUrl;
        _isLoading = false;
      });

      // Abrir o link de pagamento em uma nova aba
      html.window.open(_paymentUrl!, '_blank');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao gerar página de pagamento: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppHeader(),
            
            ResponsiveContainer(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 16 : 32,
                vertical: 64,
              ),
              child: Column(
                children: [
                  Text(
                    'Finalizar Assinatura',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Complete o pagamento para ativar sua assinatura',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppTheme.errorColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 48),
                  
                  // Card de pagamento
                  Card(
                    elevation: 4,
                    color: const Color(0xFF1A1A4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Resumo da compra
                          Text(
                            'Resumo da compra',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Detalhes do plano
                          _buildPlanDetails(),
                          const SizedBox(height: 32),
                          
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_paymentUrl != null)
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Uma nova aba foi aberta com a página de pagamento do Asaas.',
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Você pode escolher entre PIX, cartão de crédito ou boleto bancário.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            Center(
                              child: Text(
                                'Erro ao carregar o sistema de pagamento',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          
                          const SizedBox(height: 32),
                          
                          // Botões
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_paymentUrl != null) ...[
                                CustomButton(
                                  text: 'Reabrir página de pagamento',
                                  onPressed: () {
                                    if (_paymentUrl != null) {
                                      html.window.open(_paymentUrl!, '_blank');
                                    }
                                  },
                                  type: ButtonType.primary,
                                ),
                                const SizedBox(width: 16),
                              ],
                              CustomButton(
                                text: 'Voltar para o Dashboard',
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                                },
                                type: ButtonType.secondary,
                              ),
                            ],
                          ),

                          // Botão para abrir novamente a página de pagamento
                          ElevatedButton(
                            onPressed: () {
                              if (_paymentUrl != null) {
                                html.window.open(_paymentUrl!, '_blank');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text('Tentar Novamente'),
                          ),
                          const SizedBox(height: 16),
                          // Botão para verificar status da assinatura
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/subscription_status');
                            },
                            child: const Text('Verificar Status da Assinatura'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryItem(
          'Plano ${widget.planName} (${widget.planType == 'annual' ? 'Anual' : 'Mensal'})',
          'R\$ ${widget.planPrice.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 8),
        _buildSummaryItem(
          'Taxa de setup',
          'R\$ ${widget.setupFee.toStringAsFixed(2)}',
        ),
        const Divider(height: 32, color: Color(0xFF2A2A5F)),
        _buildSummaryItem(
          'Total',
          'R\$ ${widget.totalPrice.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
} 