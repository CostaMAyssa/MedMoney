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
    
    // Não processamos mais o pagamento automaticamente
    // Em vez disso, aguardamos a confirmação do usuário
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Apenas inicializamos a página, sem processar o pagamento
      Future.microtask(() => setState(() {
        _isLoading = false; 
        _initialized = true;
      }));
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
        // Garantir que o CPF tenha apenas dígitos, removendo qualquer formatação
        cpf = userProfile['cpf'].toString().replaceAll(RegExp(r'[^\d]'), '');
        debugPrint('CPF obtido do perfil (apenas dígitos): $cpf');
      }

      // Obter telefone do perfil ou usar valor vazio (não usar valores de teste)
      String phone = '';
      if (userProfile['phone'] == null || userProfile['phone'].toString().trim().isEmpty) {
        debugPrint('Telefone não encontrado no perfil. Usando valor vazio.');
        phone = '';
      } else {
        // Garantir que o telefone seja uma string trimada
        phone = userProfile['phone'].toString().trim();
        debugPrint('Telefone encontrado no perfil (como string): $phone');
        debugPrint('Tipo do telefone: ${phone.runtimeType}');
        debugPrint('Valor original do telefone: ${userProfile['phone']}');
        debugPrint('Tipo original do telefone: ${userProfile['phone'].runtimeType}');
      }

      // Garantir que o telefone é uma string, mesmo que vazia
      final String phoneStr = phone.toString().trim();
      debugPrint('Telefone (como string explícita): $phoneStr');
      debugPrint('Tipo do telefone após conversão: ${phoneStr.runtimeType}');
      
      // Usar o PaymentProvider para processar o pagamento via n8n
      final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context, listen: false);
      
      debugPrint('Iniciando processamento de pagamento para o plano ${widget.planName}');
      debugPrint('-------- DETALHES DOS DADOS ENVIADOS PARA N8N --------');
      debugPrint('userId: ${user.id}');
      debugPrint('email: ${user.email ?? ''}');
      debugPrint('name: ${userProfile['name']}');
      debugPrint('cpf original: $cpf');
      debugPrint('cpf limpo (enviado): $cpf');
      debugPrint('phone: $phoneStr');
      debugPrint('planName: ${widget.planName}');
      debugPrint('planType: ${widget.planType}');
      debugPrint('-----------------------------------------------------');
      
      final success = await paymentProvider.processPaymentViaN8n(
        planName: widget.planName,
        isAnnual: widget.planType == 'annual',
        email: user.email ?? '',
        userId: user.id,
        name: userProfile['name'],
        cpf: cpf,
        phone: phoneStr,  // Usar a versão explicitamente convertida para string
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
                          // Atualizar o perfil com o CPF - Garantir que apenas números sejam salvos
                          final cpfOnlyDigits = cpf.replaceAll(RegExp(r'[^\d]'), '');
                          await _supabaseService.updateUserProfile({'cpf': cpfOnlyDigits});
                          
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
        // Garantir que o CPF tenha apenas dígitos, removendo qualquer formatação
        cpf = userProfile['cpf'].toString().replaceAll(RegExp(r'[^\d]'), '');
        debugPrint('CPF obtido do perfil (apenas dígitos): $cpf');
      }

      // Obter telefone do perfil ou usar valor vazio (não usar valores de teste)
      String phone = '';
      if (userProfile['phone'] == null || userProfile['phone'].toString().trim().isEmpty) {
        debugPrint('Telefone não encontrado no perfil. Usando valor vazio.');
        phone = '';
      } else {
        // Garantir que o telefone seja uma string trimada
        phone = userProfile['phone'].toString().trim();
        debugPrint('Telefone encontrado no perfil (como string): $phone');
        debugPrint('Tipo do telefone: ${phone.runtimeType}');
        debugPrint('Valor original do telefone: ${userProfile['phone']}');
        debugPrint('Tipo original do telefone: ${userProfile['phone'].runtimeType}');
      }

      // Garantir que o telefone é uma string, mesmo que vazia
      final String phoneStr = phone.toString().trim();
      debugPrint('Telefone (como string explícita): $phoneStr');
      debugPrint('Tipo do telefone após conversão: ${phoneStr.runtimeType}');

      // Usar o PaymentProvider para processar o pagamento via n8n
      final paymentProvider = provider_pkg.Provider.of<PaymentProvider>(context, listen: false);
      
      debugPrint('Iniciando processamento de pagamento para o plano ${widget.planName}');
      debugPrint('-------- DETALHES DOS DADOS ENVIADOS PARA N8N --------');
      debugPrint('userId: ${user.id}');
      debugPrint('email: ${user.email ?? ''}');
      debugPrint('name: ${userProfile['name']}');
      debugPrint('cpf original: $cpf');
      debugPrint('cpf limpo (enviado): $cpf');
      debugPrint('phone: $phoneStr');
      debugPrint('planName: ${widget.planName}');
      debugPrint('planType: ${widget.planType}');
      debugPrint('-----------------------------------------------------');
      
      final success = await paymentProvider.processPaymentViaN8n(
        planName: widget.planName,
        isAnnual: widget.planType == 'annual',
        email: user.email ?? '',
        userId: user.id,
        name: userProfile['name'],
        cpf: cpf,
        phone: phoneStr,  // Usar a versão explicitamente convertida para string
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
                          // Atualizar o perfil com o CPF - Garantir que apenas números sejam salvos
                          final cpfOnlyDigits = cpf.replaceAll(RegExp(r'[^\d]'), '');
                          await _supabaseService.updateUserProfile({'cpf': cpfOnlyDigits});
                          
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho
            AppHeader(
              onLoginPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            
            // Conteúdo principal
            ResponsiveContainer(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 16 : 32,
                vertical: 64,
              ),
              child: Column(
                children: [
                  Text(
                    'Resumo da Assinatura',
                    style: TextStyle(
                      fontSize: Responsive.isMobile(context) ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Confirme os detalhes da sua assinatura antes de prosseguir para o pagamento',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.isMobile(context) ? 14 : 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Detalhes da assinatura
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalhes do Plano',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Plano selecionado
                        _buildInfoRow(
                          'Plano selecionado:',
                          'Plano ${widget.planName}',
                        ),
                        const SizedBox(height: 12),
                        
                        // Periodicidade
                        _buildInfoRow(
                          'Periodicidade:',
                          widget.planType == 'annual' ? 'Anual' : 'Mensal',
                        ),
                        const SizedBox(height: 12),
                        
                        // Valor da mensalidade
                        _buildInfoRow(
                          'Valor da mensalidade:',
                          'R\$ ${widget.planPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                        ),
                        
                        // Taxa de ativação (se aplicável)
                        if (widget.setupFee > 0) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Taxa de ativação:',
                            'R\$ ${widget.setupFee.toStringAsFixed(2).replaceAll('.', ',')}',
                          ),
                        ],
                        
                        const Divider(height: 32),
                        
                        // Valor total
                        _buildInfoRow(
                          'Valor total:',
                          'R\$ ${widget.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  
                  // Mensagem de erro (se houver)
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 12),
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
                  ],
                  
                  // Botão de ação
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: _isLoading ? 'Processando...' : 'Prosseguir para Pagamento',
                      onPressed: processarPagamento,
                      type: ButtonType.primary,
                      size: ButtonSize.large,
                      isLoading: _isLoading,
                    ),
                  ),
                  
                  // Botão para voltar
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Cancelar',
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/payment-required');
                      },
                      type: ButtonType.outline,
                      size: ButtonSize.medium,
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
  
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  // Método para processar o pagamento com VoidCallback definida
  void processarPagamento() {
    if (!_isLoading) {
      _processPayment();
    }
  }
} 