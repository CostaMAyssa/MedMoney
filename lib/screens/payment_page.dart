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
    _processPayment();
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

      // Obter dados do usuário atual
      final user = Supabase.instance.client.auth.currentUser;
      Map<String, dynamic>? userProfile;
      
      try {
        userProfile = await _supabaseService.getUserProfile();
        debugPrint('Perfil do usuário obtido com sucesso: ${userProfile?.keys.join(', ')}');
      } catch (e) {
        debugPrint('Erro ao obter perfil do usuário: $e');
      }

      if (user == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      if (userProfile == null || userProfile['name'] == null || userProfile['name'].toString().isEmpty) {
        throw Exception('Perfil incompleto. Por favor, complete seu cadastro.');
      }

      // Obter CPF do perfil ou informar que é obrigatório
      String cpf = '';
      if (userProfile['cpf'] == null || userProfile['cpf'].toString().isEmpty) {
        debugPrint('CPF não encontrado no perfil.');
        throw Exception('CPF é obrigatório para realizar o pagamento. Por favor, complete seu cadastro.');
      } else {
        cpf = userProfile['cpf'].toString();
      }

      // Obter telefone do perfil ou usar valor vazio (não usar valores de teste)
      String phone = '';
      if (userProfile['phone'] == null || userProfile['phone'].toString().isEmpty) {
        debugPrint('Telefone não encontrado no perfil. Usando valor vazio.');
        // Não usar telefone de teste, usar string vazia
        phone = '';
      } else {
        phone = userProfile['phone'].toString();
      }

      // Usar o PaymentProvider para processar o pagamento via n8n
      final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context, listen: false);
      
      debugPrint('Iniciando processamento de pagamento para o plano ${widget.planName}');
      final success = await paymentProvider.processPaymentViaN8n(
        planName: widget.planName,
        isAnnual: widget.planType == 'annual',
        email: user.email ?? '',
        userId: user.id,
        name: userProfile['name'],
        cpf: cpf,
        phone: phone,
      );
      
      if (!mounted) return;
      
      if (success) {
        // Dados do pagamento foram processados
        final paymentData = paymentProvider.paymentData;
        
        debugPrint('Pagamento processado com sucesso. Dados: $paymentData');
        
        // Verificar se temos a URL de pagamento (pode estar em diferentes campos)
        String? paymentUrl;
        
        if (paymentData != null) {
          // Verificar os possíveis campos que podem conter a URL
          if (paymentData['url'] != null) {
            paymentUrl = paymentData['url'].toString();
          } else if (paymentData['paymentUrl'] != null) {
            paymentUrl = paymentData['paymentUrl'].toString();
          } else if (paymentData.containsKey('payment_url')) {
            paymentUrl = paymentData['payment_url'].toString();
          }
        }
        
        _paymentUrl = paymentUrl;
        
        if (_paymentUrl != null && _paymentUrl!.isNotEmpty) {
          debugPrint('URL de pagamento encontrada: $_paymentUrl');
          
          // Se estamos em ambiente web, abrir o link em nova aba imediatamente
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              // Abrir o link em uma nova aba
              html.window.open(_paymentUrl!, '_blank');
              
              // Exibir mensagem de sucesso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link de pagamento aberto em uma nova aba'),
                  duration: Duration(seconds: 5),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        } else {
          debugPrint('Pagamento processado, mas sem URL de pagamento: ${paymentData?.toString()}');
          
          // Mostrar erro se não encontrarmos uma URL de pagamento
          setState(() {
            _errorMessage = 'Não foi possível gerar o link de pagamento. Entre em contato com o suporte.';
          });
        }
        
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception(paymentProvider.errorMessage ?? 'Não foi possível gerar o pagamento');
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Erro ao gerar página de pagamento: $e');
        setState(() {
          _errorMessage = 'Erro ao gerar página de pagamento: ${e.toString()}';
          _isLoading = false;
        });
        
        // Adicionar botão para completar o cadastro se o erro for sobre CPF ausente
        if (e.toString().contains('CPF é obrigatório')) {
          Future.delayed(Duration.zero, () {
            // Mostrar um diálogo com um campo para adicionar o CPF
            final cpfController = TextEditingController();
            bool isLoading = false;
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  title: const Text('Adicionar CPF'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Você precisa adicionar seu CPF para continuar com o pagamento.'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: cpfController,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          hintText: '000.000.000-00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading ? null : () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        // Validar CPF
                        final cpf = cpfController.text.trim();
                        if (cpf.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, informe seu CPF')),
                          );
                          return;
                        }
                        
                        setState(() {
                          isLoading = true;
                        });
                        
                        try {
                          // Atualizar o perfil com o CPF
                          await _supabaseService.updateUserProfile({'cpf': cpf});
                          
                          // Fechar o diálogo
                          Navigator.pop(context);
                          
                          // Recarregar a página
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('CPF adicionado com sucesso'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            // Tentar processar o pagamento novamente
                            _processPayment();
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao atualizar perfil: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            );
          });
        }
      }
    }
  }

  // Método para processar o pagamento
  void _processPayment() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final _supabaseService = SupabaseService();
      final user = Supabase.instance.client.auth.currentUser;
      
      // Obter perfil do usuário
      Map<String, dynamic>? userProfile;
      try {
        userProfile = await _supabaseService.getUserProfile();
        debugPrint('Perfil do usuário obtido com sucesso: ${userProfile?.keys.join(', ')}');
      } catch (e) {
        debugPrint('Erro ao obter perfil do usuário: $e');
      }

      if (user == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      if (userProfile == null || userProfile['name'] == null || userProfile['name'].toString().isEmpty) {
        throw Exception('Perfil incompleto. Por favor, complete seu cadastro.');
      }

      // Obter CPF do perfil ou informar que é obrigatório
      String cpf = '';
      if (userProfile['cpf'] == null || userProfile['cpf'].toString().isEmpty) {
        debugPrint('CPF não encontrado no perfil.');
        throw Exception('CPF é obrigatório para realizar o pagamento. Por favor, complete seu cadastro.');
      } else {
        cpf = userProfile['cpf'].toString();
      }

      // Obter telefone do perfil ou usar valor vazio (não usar valores de teste)
      String phone = '';
      if (userProfile['phone'] == null || userProfile['phone'].toString().isEmpty) {
        debugPrint('Telefone não encontrado no perfil. Usando valor vazio.');
        // Não usar telefone de teste, usar string vazia
        phone = '';
      } else {
        phone = userProfile['phone'].toString();
      }

      // Usar o PaymentProvider para processar o pagamento via n8n
      final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context, listen: false);
      
      debugPrint('Iniciando processamento de pagamento para o plano ${widget.planName}');
      final success = await paymentProvider.processPaymentViaN8n(
        planName: widget.planName,
        isAnnual: widget.planType == 'annual',
        email: user.email ?? '',
        userId: user.id,
        name: userProfile['name'],
        cpf: cpf,
        phone: phone,
      );
      
      if (!mounted) return;
      
      if (success) {
        // Dados do pagamento foram processados
        final paymentData = paymentProvider.paymentData;
        
        debugPrint('Pagamento processado com sucesso. Dados: $paymentData');
        
        // Verificar se temos a URL de pagamento (pode estar em diferentes campos)
        String? paymentUrl;
        
        if (paymentData != null) {
          // Verificar os possíveis campos que podem conter a URL
          if (paymentData['url'] != null) {
            paymentUrl = paymentData['url'].toString();
          } else if (paymentData['paymentUrl'] != null) {
            paymentUrl = paymentData['paymentUrl'].toString();
          } else if (paymentData.containsKey('payment_url')) {
            paymentUrl = paymentData['payment_url'].toString();
          }
        }
        
        _paymentUrl = paymentUrl;
        
        if (_paymentUrl != null && _paymentUrl!.isNotEmpty) {
          debugPrint('URL de pagamento encontrada: $_paymentUrl');
          
          // Se estamos em ambiente web, abrir o link em nova aba imediatamente
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              // Abrir o link em uma nova aba
              html.window.open(_paymentUrl!, '_blank');
              
              // Exibir mensagem de sucesso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link de pagamento aberto em uma nova aba'),
                  duration: Duration(seconds: 5),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        } else {
          debugPrint('Pagamento processado, mas sem URL de pagamento: ${paymentData?.toString()}');
          
          // Mostrar erro se não encontrarmos uma URL de pagamento
          setState(() {
            _errorMessage = 'Não foi possível gerar o link de pagamento. Entre em contato com o suporte.';
          });
        }
        
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception(paymentProvider.errorMessage ?? 'Não foi possível gerar o pagamento');
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Erro ao gerar página de pagamento: $e');
        setState(() {
          _errorMessage = 'Erro ao gerar página de pagamento: ${e.toString()}';
          _isLoading = false;
        });
        
        // Adicionar botão para completar o cadastro se o erro for sobre CPF ausente
        if (e.toString().contains('CPF é obrigatório')) {
          Future.delayed(Duration.zero, () {
            // Mostrar um diálogo com um campo para adicionar o CPF
            final cpfController = TextEditingController();
            bool isLoading = false;
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  title: const Text('Adicionar CPF'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Você precisa adicionar seu CPF para continuar com o pagamento.'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: cpfController,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          hintText: '000.000.000-00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading ? null : () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        // Validar CPF
                        final cpf = cpfController.text.trim();
                        if (cpf.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, informe seu CPF')),
                          );
                          return;
                        }
                        
                        setState(() {
                          isLoading = true;
                        });
                        
                        try {
                          // Atualizar o perfil com o CPF
                          await _supabaseService.updateUserProfile({'cpf': cpf});
                          
                          // Fechar o diálogo
                          Navigator.pop(context);
                          
                          // Recarregar a página
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('CPF adicionado com sucesso'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            // Tentar processar o pagamento novamente
                            _processPayment();
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao atualizar perfil: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            );
          });
        }
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
      bottomNavigationBar: null,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ResponsiveContainer(
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
                        
                        // Link de pagamento (se disponível)
                        if (_paymentUrl != null) ...[
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text(
                                    'Link de Pagamento',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Utilize o link abaixo para acessar sua página de pagamento:',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Abrir Página de Pagamento'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    onPressed: () {
                                      if (_paymentUrl != null) {
                                        html.window.open(_paymentUrl!, '_blank');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Após finalizar seu pagamento, você receberá a confirmação por email.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Mensagem do n8n se disponível
                        if (paymentData != null && paymentData['message'] != null && _paymentUrl == null) ...[
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text(
                                    'Status do Pagamento',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Icon(
                                    Icons.info_outline,
                                    size: 48,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    paymentData['message'] as String? ?? 'Processando seu pagamento...',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Em instantes você receberá um email com instruções para completar seu pagamento.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // QR Code PIX (se disponível)
                        _buildPixQrCode(context, paymentData),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  AppFooter(),
                ],
              ),
            ),
    );
  }
} 