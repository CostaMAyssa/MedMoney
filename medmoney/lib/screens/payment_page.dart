import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/responsive_container.dart';
import '../services/asaas_service.dart';

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

  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessing = false;
  String? _errorMessage;
  bool _paymentSuccess = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      try {
        // Processar pagamento através do AsaasService
        final description = 'Assinatura ${widget.planName} - ${widget.planType == 'annual' ? 'Anual' : 'Mensal'} + Setup Inicial';
        
        await AsaasService.processPayment(
          paymentMethod: _selectedPaymentMethod,
          amount: widget.totalPrice,
          description: description,
          cardNumber: _selectedPaymentMethod == 'credit_card' ? _cardNumberController.text : null,
          cardHolder: _selectedPaymentMethod == 'credit_card' ? _cardHolderController.text : null,
          expiryDate: _selectedPaymentMethod == 'credit_card' ? _expiryDateController.text : null,
          cvv: _selectedPaymentMethod == 'credit_card' ? _cvvController.text : null,
        );

        setState(() {
          _isProcessing = false;
          _paymentSuccess = true;
        });

        // Aguardar um momento antes de redirecionar
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Erro ao processar pagamento: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    'Finalizar Pagamento',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Complete o pagamento para ativar sua assinatura',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Card de pagamento
                  _buildPaymentCard(context),
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

  Widget _buildPaymentCard(BuildContext context) {
    return Card(
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
            // Resumo do plano
            _buildPlanSummary(),
            const SizedBox(height: 32),
            
            // Mensagem de erro (se houver)
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            
            // Mensagem de sucesso (se o pagamento for bem-sucedido)
            if (_paymentSuccess) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.successColor,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Pagamento processado com sucesso! Redirecionando para o dashboard...',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            
            // Métodos de pagamento
            Text(
              'Método de Pagamento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Opções de método de pagamento
            Row(
              children: [
                _buildPaymentMethodOption(
                  'credit_card',
                  'Cartão de Crédito',
                  Icons.credit_card,
                ),
                const SizedBox(width: 16),
                _buildPaymentMethodOption(
                  'pix',
                  'PIX',
                  Icons.qr_code,
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Formulário de pagamento
            if (_selectedPaymentMethod == 'credit_card')
              _buildCreditCardForm(),
            
            if (_selectedPaymentMethod == 'pix')
              _buildPixPayment(),
            
            const SizedBox(height: 32),
            
            // Botão de pagamento
            CustomButton(
              text: 'Finalizar Pagamento',
              onPressed: _processPayment,
              type: ButtonType.primary,
              size: ButtonSize.large,
              isLoading: _isProcessing,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do Plano',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            'Plano',
            'Plano ${widget.planName} (${widget.planType == 'annual' ? 'Anual' : 'Mensal'})',
          ),
          const SizedBox(height: 8),
          _buildSummaryItem(
            'Valor do Plano',
            'R\$ ${widget.planPrice.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildSummaryItem(
            'Taxa de Setup (única)',
            'R\$ ${widget.setupFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF2A2A5F)),
          const SizedBox(height: 8),
          _buildSummaryItem(
            'Total',
            'R\$ ${widget.totalPrice.toStringAsFixed(2)}',
            isHighlighted: true,
          ),
          const SizedBox(height: 8),
          _buildSummaryItem(
            'Próxima cobrança',
            widget.planType == 'annual'
                ? '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year + 1}'
                : '${DateTime.now().day}/${DateTime.now().month + 1}/${DateTime.now().year}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Color(0xFF2A2A5F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados do Cartão',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Número do Cartão',
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
            label: 'Nome no Cartão',
            hint: 'Nome como aparece no cartão',
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
                  label: 'Data de Validade',
                  hint: 'MM/AA',
                  controller: _expiryDateController,
                  keyboardType: TextInputType.datetime,
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
                  prefixIcon: Icons.security,
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
    );
  }

  Widget _buildPixPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
          'Escaneie o código QR com seu aplicativo bancário',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF2A2A5F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'pix@financasmedicas.com.br',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.copy,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  // Copiar chave PIX para a área de transferência
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chave PIX copiada para a área de transferência'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
} 