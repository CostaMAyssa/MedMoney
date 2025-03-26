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
import '../widgets/pix_qr_code.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

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

      // Usar o PaymentProvider para processar o pagamento via nossa API de webhook
      final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context, listen: false);
      
      // Por padrão, vamos iniciar com PIX que é mais fácil e não requer dados adicionais
      final success = await paymentProvider.processPaymentViaWebhook(
        planName: widget.planName,
        planType: widget.planType,
        totalPrice: widget.totalPrice,
        billingType: 'PIX',
      );
      
      if (!mounted) return;
      
      if (success) {
        // Dados do pagamento ou assinatura criado
        final paymentData = paymentProvider.paymentData;
        
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception(paymentProvider.errorMessage ?? 'Não foi possível gerar o pagamento');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao gerar página de pagamento: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Método para processar o QRCode PIX
  Widget _buildPixQrCode(BuildContext context, Map<String, dynamic>? paymentData) {
    if (paymentData == null || paymentData['billingType'] != 'PIX') {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: provider_pkg.Provider.of<PaymentProvider>(context, listen: false)
          .getSubscriptionPixQrCode(paymentData['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando QR code PIX...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Erro ao carregar QR code PIX: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Erro ao carregar QR code PIX: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Força reconstrução para tentar novamente
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || 
            (snapshot.data?['pixQrCode'] == null && 
             snapshot.data?['subscription']?['firstPayment']?['pix'] == null)) {
          return const Center(
            child: Text('QR code PIX não disponível. Tente novamente mais tarde.'),
          );
        }

        // Extrair o QR code PIX da resposta
        final pixData = snapshot.data!['pixQrCode'] ?? 
                        snapshot.data!['subscription']?['firstPayment']?['pix'];
        
        if (pixData == null) {
          return const Center(
            child: Text('QR code PIX não disponível. Tente novamente mais tarde.'),
          );
        }

        final String? qrCode = pixData['encodedImage'] ?? pixData['qrCode'];
        final String? pixKey = pixData['payload'] ?? pixData['copy'];

        if (qrCode == null) {
          return const Center(
            child: Text('QR code PIX não disponível. Tente novamente mais tarde.'),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Escaneie o QR code PIX',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Exibir o QR code como imagem
              Image.memory(
                base64Decode(qrCode.replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')),
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 16),
              if (pixKey != null) ...[
                const Text(
                  'Ou copie o código PIX:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pixKey,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: pixKey));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código PIX copiado!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Importante: Após realizar o pagamento, aguarde a confirmação que será enviada automaticamente.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context);
    final paymentData = paymentProvider.paymentData;

    return Scaffold(
      appBar: const AppHeader(
        showBackButton: true,
      ),
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Gerando pagamento...'),
              ],
            ),
          )
        : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _initializePayment();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    const Text(
                      'Pagamento',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plano: ${widget.planName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tipo: ${widget.planType}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Valor: R\$ ${widget.planPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (widget.setupFee > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Taxa de setup: R\$ ${widget.setupFee.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Total: R\$ ${widget.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // QR Code PIX (se disponível)
                    _buildPixQrCode(context, paymentData),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: AppFooter(),
    );
  }
} 