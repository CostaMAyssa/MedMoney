import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/responsive_container.dart';
import '../services/supabase_service.dart';
import '../utils/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/asaas_service.dart';
import 'pix_payment_page.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../providers/payment_provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String _paymentMethod = 'credit_card'; // 'credit_card' ou 'pix'

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_paymentMethod == 'credit_card' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context, listen: false);
      
      if (_paymentMethod == 'credit_card') {
        final success = await paymentProvider.processCreditCardPayment(
          planName: widget.planName,
          planType: widget.planType,
          totalPrice: widget.totalPrice,
          cardHolderName: _cardHolderController.text,
          cardNumber: _cardNumberController.text,
          expiryDate: _expiryDateController.text,
          cvv: _cvvController.text,
        );
        
        if (success && mounted) {
          // Mostrar mensagem de sucesso para cartão
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pagamento processado com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          // Navegar para o dashboard após o pagamento bem-sucedido
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        } else if (mounted) {
          // Mostrar mensagem de erro
          setState(() {
            _errorMessage = paymentProvider.errorMessage ?? 'Erro ao processar pagamento';
            _isLoading = false;
          });
          
          // Mostrar snackbar com erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'Erro ao processar pagamento'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } else if (_paymentMethod == 'pix') {
        final success = await paymentProvider.processPixPayment(
          planName: widget.planName,
          planType: widget.planType,
          totalPrice: widget.totalPrice,
        );
        
        if (success && mounted && paymentProvider.pixData != null) {
          // Navegar para a tela de QR code do PIX
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PixPaymentPage(
                pixInfo: paymentProvider.pixData!,
              ),
            ),
          );
        } else if (mounted) {
          // Mostrar mensagem de erro
          setState(() {
            _errorMessage = paymentProvider.errorMessage ?? 'Erro ao gerar PIX';
            _isLoading = false;
          });
          
          // Mostrar snackbar com erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'Erro ao gerar PIX'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro inesperado: ${e.toString()}';
          _isLoading = false;
        });
        
        // Mostrar snackbar com erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
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

  @override
  Widget build(BuildContext context) {
    final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context);
    final isLoading = paymentProvider.isProcessing;
    final errorMessage = paymentProvider.errorMessage;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho
            AppHeader(),
            
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
                    color: Color(0xFF1A1A4F),
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
                          
                          // Métodos de pagamento
                          Text(
                            'Método de pagamento',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPaymentMethodOption(
                                  'Cartão de Crédito',
                                  Icons.credit_card,
                                  'credit_card',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildPaymentMethodOption(
                                  'PIX',
                                  Icons.qr_code,
                                  'pix',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Formulário de cartão de crédito
                          if (_paymentMethod == 'credit_card') ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dados do cartão',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Número do cartão',
                                    hint: '0000 0000 0000 0000',
                                    controller: _cardNumberController,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.credit_card,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, informe o número do cartão';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Nome no cartão',
                                    hint: 'NOME COMO ESTÁ NO CARTÃO',
                                    controller: _cardHolderController,
                                    prefixIcon: Icons.person,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, informe o nome no cartão';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          label: 'Data de validade',
                                          hint: 'MM/AA',
                                          controller: _expiryDateController,
                                          keyboardType: TextInputType.number,
                                          prefixIcon: Icons.calendar_today,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Informe a validade';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: CustomTextField(
                                          label: 'CVV',
                                          hint: '123',
                                          controller: _cvvController,
                                          keyboardType: TextInputType.number,
                                          prefixIcon: Icons.lock,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Informe o CVV';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // QR Code PIX
                          if (_paymentMethod == 'pix') ...[
                            Column(
                              children: [
                                Text(
                                  'Escaneie o QR Code abaixo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.qr_code,
                                      size: 150,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ou copie o código PIX',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2A2A5F),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '00020126580014br.gov.bcb.pix0136a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0',
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy,
                                          color: AppTheme.primaryColor,
                                        ),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Código PIX copiado!'),
                                              backgroundColor: AppTheme.successColor,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          // Botão de finalizar pagamento
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Finalizar Pagamento',
                              onPressed: _processPayment,
                              type: ButtonType.primary,
                              size: ButtonSize.large,
                              isLoading: isLoading,
                            ),
                          ),
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

  Widget _buildPaymentMethodOption(String title, IconData icon, String method) {
    final isSelected = _paymentMethod == method;
    
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Color(0xFF2A2A5F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
} 