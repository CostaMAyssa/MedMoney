import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/custom_button.dart';
import '../widgets/responsive_container.dart';
import '../utils/routes.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../providers/payment_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js if (dart.library.js) 'dart:js';

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
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPaymentUrlGenerated = false;
  String? _paymentUrl;
  bool _paymentSuccess = false;

  // Processar pagamento com o checkout do Asaas
  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context, listen: false);
      
      // Gerar um link de pagamento do Asaas
      final paymentUrl = await paymentProvider.createAsaasCheckout(
        planName: widget.planName,
        planType: widget.planType,
        totalPrice: widget.totalPrice,
      );
      
      setState(() {
        _isLoading = false;
        if (paymentUrl != null) {
          _isPaymentUrlGenerated = true;
          _paymentUrl = paymentUrl;
          
          // Tentar abrir o link automaticamente
          _openPaymentUrl(paymentUrl);
        } else {
          _errorMessage = paymentProvider.errorMessage ?? 'Erro ao gerar link de pagamento';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro inesperado: ${e.toString()}';
      });
      
      // Mostrar snackbar com erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Abrir o link de pagamento em uma nova aba
  void _openPaymentUrl(String url) async {
    try {
      // Verificar se estamos no ambiente web
      if (kIsWeb) {
        // Usar JS para abrir URL em nova aba (apenas em web)
        js.context.callMethod('open', [url, '_blank']);
      } else {
        // Usar url_launcher em plataformas não web
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Não foi possível abrir a URL: $url');
        }
      }
      
      // Exibir mensagem de confirmação
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link de pagamento gerado. Abrindo página do Asaas...'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao abrir link: $e');
      
      // Se não conseguir abrir automaticamente, mostrar instrução para o usuário
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, clique no botão "Acessar Pagamento" para continuar.'),
          backgroundColor: AppTheme.warningColor,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context);
    final isLoading = paymentProvider.isProcessing || _isLoading;
    final errorMessage = paymentProvider.errorMessage ?? _errorMessage;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho
            const AppHeader(),
            
            // Conteúdo principal
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
                  
                  // Exibir mensagem de erro se houver
                  if (errorMessage != null)
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
                              errorMessage,
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: AppTheme.errorColor),
                            onPressed: () => paymentProvider.clearError(),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
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
                          const SizedBox(height: 32),
                          
                          // Se o link de pagamento foi gerado, mostrar botões para abrir o link
                          if (_isPaymentUrlGenerated && _paymentUrl != null) ...[
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppTheme.successColor,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Link de pagamento gerado com sucesso!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Clique no botão abaixo para abrir a página de pagamento do Asaas e concluir sua assinatura. Você poderá escolher entre cartão de crédito, PIX ou boleto.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openPaymentUrl(_paymentUrl!),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Acessar Pagamento'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Após finalizar o pagamento, você será redirecionado para o dashboard automaticamente.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                                    },
                                    child: const Text('Voltar para o Dashboard'),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Botão para gerar o link de pagamento do Asaas
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                text: 'Pagar com Asaas',
                                onPressed: _processPayment,
                                type: ButtonType.primary,
                                size: ButtonSize.large,
                                isLoading: isLoading,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Ao clicar, você será redirecionado para a página de pagamento segura do Asaas, onde poderá escolher entre cartão de crédito, PIX ou boleto.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Rodapé
            const AppFooter(),
          ],
        ),
      ),
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