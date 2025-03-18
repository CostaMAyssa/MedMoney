import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/routes.dart';
import '../providers/payment_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/custom_button.dart';
import '../widgets/pix_qr_code.dart';
import '../widgets/pix_copy_paste.dart';

class PixPaymentPage extends StatefulWidget {
  final Map<String, dynamic> pixInfo;
  final Map<String, dynamic>? paymentData;

  const PixPaymentPage({
    Key? key,
    required this.pixInfo,
    this.paymentData,
  }) : super(key: key);

  @override
  State<PixPaymentPage> createState() => _PixPaymentPageState();
}

class _PixPaymentPageState extends State<PixPaymentPage> {
  bool _isCheckingPayment = false;
  String? _paymentStatus;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho
            AppHeader(showBackButton: true),
            
            // Conteúdo principal
            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título
                            Text(
                              'Pagamento via PIX',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Subtítulo
                            Text(
                              'Escaneie o QR code ou copie o código PIX para realizar o pagamento',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Card do PIX
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // QR Code
                                  Center(
                                    child: PixQrCode(pixInfo: widget.pixInfo),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // Código PIX
                                  PixCopyPaste(pixInfo: widget.pixInfo),
                                  const SizedBox(height: 32),
                                  
                                  // Status do pagamento
                                  if (_paymentStatus != null)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _paymentStatus == 'CONFIRMED' || 
                                              _paymentStatus == 'RECEIVED' || 
                                              _paymentStatus == 'RECEIVED_IN_CASH'
                                            ? AppTheme.successColor.withOpacity(0.2)
                                            : AppTheme.warningColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _paymentStatus == 'CONFIRMED' || 
                                            _paymentStatus == 'RECEIVED' || 
                                            _paymentStatus == 'RECEIVED_IN_CASH'
                                                ? Icons.check_circle
                                                : Icons.info,
                                            color: _paymentStatus == 'CONFIRMED' || 
                                                  _paymentStatus == 'RECEIVED' || 
                                                  _paymentStatus == 'RECEIVED_IN_CASH'
                                                ? AppTheme.successColor
                                                : AppTheme.warningColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _getStatusMessage(_paymentStatus!),
                                              style: TextStyle(
                                                color: _paymentStatus == 'CONFIRMED' || 
                                                      _paymentStatus == 'RECEIVED' || 
                                                      _paymentStatus == 'RECEIVED_IN_CASH'
                                                    ? AppTheme.successColor
                                                    : AppTheme.warningColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 32),
                                  
                                  // Botão para verificar status
                                  ElevatedButton.icon(
                                    onPressed: _isCheckingPayment
                                        ? null
                                        : () => _checkPaymentStatus(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    icon: _isCheckingPayment
                                        ? Container(
                                            width: 24,
                                            height: 24,
                                            padding: const EdgeInsets.all(2.0),
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Icon(Icons.refresh),
                                    label: Text(
                                      _isCheckingPayment
                                          ? 'Verificando...'
                                          : 'Verificar Status do Pagamento',
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // Instruções
                                  Text(
                                    'Instruções',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInstructionItem(
                                    '1',
                                    'Abra o aplicativo do seu banco',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInstructionItem(
                                    '2',
                                    'Escolha a opção de pagamento via PIX',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInstructionItem(
                                    '3',
                                    'Escaneie o QR code ou cole o código',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInstructionItem(
                                    '4',
                                    'Confirme o pagamento',
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // Data de expiração
                                  if (widget.pixInfo['expirationDate'] != null)
                                    Text(
                                      'Este PIX expira em: ${widget.pixInfo['expirationDate']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.warningColor,
                                      ),
                                    ),
                                  const SizedBox(height: 32),
                                  
                                  // Botão para voltar ao dashboard
                                  CustomButton(
                                    text: 'Voltar para o Dashboard',
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
  
  // Verificar o status do pagamento
  Future<void> _checkPaymentStatus(BuildContext context) async {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final paymentId = paymentProvider.paymentData?['id'];
    
    if (paymentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID do pagamento não disponível'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isCheckingPayment = true;
    });
    
    try {
      final paymentStatus = await paymentProvider.checkPaymentStatus(paymentId);
      
      setState(() {
        _isCheckingPayment = false;
        _paymentStatus = paymentStatus?['status'];
      });
      
      // Se o pagamento foi confirmado, redirecionar para o dashboard após 3 segundos
      if (paymentStatus != null && 
          (paymentStatus['status'] == 'CONFIRMED' || 
           paymentStatus['status'] == 'RECEIVED' || 
           paymentStatus['status'] == 'RECEIVED_IN_CASH')) {
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao verificar status do pagamento: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  String _getStatusMessage(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'RECEIVED':
      case 'RECEIVED_IN_CASH':
        return 'Pagamento confirmado! Redirecionando para o dashboard...';
      case 'PENDING':
        return 'Pagamento pendente. Aguardando confirmação do banco.';
      case 'OVERDUE':
        return 'Pagamento vencido. Por favor, gere um novo PIX.';
      case 'REFUNDED':
        return 'Pagamento estornado.';
      case 'CANCELED':
        return 'Pagamento cancelado.';
      default:
        return 'Status do pagamento: $status';
    }
  }
  
  Widget _buildInstructionItem(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }
} 