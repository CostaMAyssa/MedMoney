import 'package:flutter/material.dart';
import '../services/asaas_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

enum PaymentStatus {
  initial,
  processing,
  success,
  failed,
  pixGenerated
}

class PaymentProvider with ChangeNotifier {
  final AsaasService _asaasService = AsaasService();
  final SupabaseService _supabaseService = SupabaseService();
  
  PaymentStatus _status = PaymentStatus.initial;
  String? _errorMessage;
  Map<String, dynamic>? _paymentData;
  Map<String, dynamic>? _pixData;
  
  // Getters
  PaymentStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get paymentData => _paymentData;
  Map<String, dynamic>? get pixData => _pixData;
  bool get isProcessing => _status == PaymentStatus.processing;
  
  // Resetar estado
  void reset() {
    _status = PaymentStatus.initial;
    _errorMessage = null;
    _paymentData = null;
    _pixData = null;
    notifyListeners();
  }
  
  // Processar pagamento com cartão de crédito
  Future<bool> processCreditCardPayment({
    required String planName,
    required String planType,
    required double totalPrice,
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    _status = PaymentStatus.processing;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Obter perfil do usuário
      Map<String, dynamic> userProfile;
      try {
        userProfile = await _supabaseService.getUserProfile();
      } catch (e) {
        debugPrint('Erro ao obter perfil do usuário: $e');
        // Usar dados básicos se não conseguir obter o perfil
        userProfile = {
          'name': 'Usuário',
          'email': user.email ?? 'email@exemplo.com',
          'phone': '',
        };
      }
      
      // Criar ou obter cliente no Asaas
      Map<String, dynamic> customer;
      try {
        // Verificar se temos um CPF válido
        if (userProfile['cpf_cnpj'] == null || userProfile['cpf_cnpj'].toString().isEmpty) {
          throw Exception('CPF/CNPJ é obrigatório para criar cliente no Asaas');
        }
        
        customer = await _asaasService.createCustomer(
          name: userProfile['name'] ?? 'Usuário',
          email: userProfile['email'] ?? user.email ?? 'email@exemplo.com',
          cpfCnpj: userProfile['cpf_cnpj'],
          phone: userProfile['phone'] ?? '',
        );
        debugPrint('Cliente criado no Asaas: ${customer['id']}');
      } catch (e) {
        debugPrint('Erro ao criar cliente no Asaas: $e');
        _status = PaymentStatus.failed;
        _errorMessage = 'Não foi possível criar o cliente no Asaas: ${e.toString()}';
        notifyListeners();
        return false;
      }
      
      // Descrição do pagamento
      final description = 'Assinatura $planName (${planType == 'annual' ? 'Anual' : 'Mensal'})';
      
      // Calcular próxima data de cobrança
      final now = DateTime.now();
      final nextBillingDate = planType == 'annual'
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime(now.year, now.month + 1, now.day);
      
      // Extrair mês e ano de expiração
      final expiryParts = expiryDate.split('/');
      final expiryMonth = expiryParts[0].padLeft(2, '0');
      final expiryYear = '20${expiryParts[1]}';
      
      try {
        // Criar assinatura com cartão de crédito
        final paymentResponse = await _asaasService.createSubscription(
          customerId: customer['id'],
          value: totalPrice,
          billingType: 'CREDIT_CARD',
          cycle: planType == 'annual' ? 'YEARLY' : 'MONTHLY',
          description: description,
          nextDueDate: now.toIso8601String().split('T')[0],
          creditCardHolderName: cardHolderName,
          creditCardNumber: cardNumber.replaceAll(' ', ''),
          creditCardExpiryMonth: expiryMonth,
          creditCardExpiryYear: expiryYear,
          creditCardCcv: cvv,
        );
        
        _paymentData = paymentResponse;
        debugPrint('Assinatura criada no Asaas: ${paymentResponse['id']}');
        
        // Salvar informações da assinatura no Supabase
        try {
          // Criar assinatura
          await _supabaseService.createSubscription({
            'plan_name': planName,
            'plan_type': planType,
            'price': totalPrice,
            'status': 'active',
            'payment_method': 'credit_card',
            'start_date': now.toIso8601String(),
            'next_billing_date': nextBillingDate.toIso8601String(),
            'external_id': paymentResponse['id'], // ID da assinatura no Asaas
          });
          
          // Criar registro de transação
          await _supabaseService.createTransaction({
            'description': description,
            'amount': totalPrice,
            'type': 'expense',
            'date': now.toIso8601String().split('T')[0],
          });
        } catch (e) {
          debugPrint('Erro ao salvar dados no Supabase: $e');
          // Continuar mesmo com erro no Supabase
        }
        
        _status = PaymentStatus.success;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Erro ao criar assinatura com cartão: $e');
        
        // Extrair mensagem de erro mais amigável
        String errorMsg = 'Falha ao processar pagamento com cartão';
        
        if (e.toString().contains('cartão')) {
          errorMsg = 'Dados do cartão inválidos. Verifique as informações e tente novamente.';
        } else if (e.toString().contains('recusado')) {
          errorMsg = 'Pagamento recusado pela operadora do cartão. Tente outro cartão ou forma de pagamento.';
        } else if (e.toString().contains('saldo')) {
          errorMsg = 'Cartão sem saldo suficiente. Tente outro cartão ou forma de pagamento.';
        }
        
        _status = PaymentStatus.failed;
        _errorMessage = errorMsg;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Erro geral ao processar pagamento: $e');
      _status = PaymentStatus.failed;
      _errorMessage = 'Erro ao processar pagamento: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Processar pagamento com PIX
  Future<bool> processPixPayment({
    required String planName,
    required String planType,
    required double totalPrice,
  }) async {
    _status = PaymentStatus.processing;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Verificar se o usuário está autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }
      
      // Obter perfil do usuário
      Map<String, dynamic> userProfile;
      try {
        userProfile = await _supabaseService.getUserProfile();
      } catch (e) {
        debugPrint('Erro ao obter perfil do usuário: $e');
        // Usar dados básicos se não conseguir obter o perfil
        userProfile = {
          'name': 'Usuário',
          'email': user.email ?? 'email@exemplo.com',
          'phone': '',
        };
      }
      
      // Criar ou obter cliente no Asaas
      Map<String, dynamic> customer;
      try {
        // Verificar se temos um CPF válido
        if (userProfile['cpf_cnpj'] == null || userProfile['cpf_cnpj'].toString().isEmpty) {
          throw Exception('CPF/CNPJ é obrigatório para criar cliente no Asaas');
        }
        
        customer = await _asaasService.createCustomer(
          name: userProfile['name'] ?? 'Usuário',
          email: userProfile['email'] ?? user.email ?? 'email@exemplo.com',
          cpfCnpj: userProfile['cpf_cnpj'],
          phone: userProfile['phone'] ?? '',
        );
        
        if (customer == null || customer['id'] == null) {
          throw Exception('Resposta inválida ao criar cliente no Asaas');
        }
        
        debugPrint('Cliente criado no Asaas com ID: ${customer['id']}');
      } catch (e) {
        debugPrint('Erro ao criar cliente no Asaas: $e');
        _status = PaymentStatus.failed;
        _errorMessage = 'Não foi possível criar o cliente no Asaas: ${e.toString()}';
        notifyListeners();
        return false;
      }
      
      // Descrição do pagamento
      final description = 'Assinatura $planName (${planType == 'annual' ? 'Anual' : 'Mensal'})';
      
      // Calcular próxima data de cobrança
      final now = DateTime.now();
      final nextBillingDate = planType == 'annual'
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime(now.year, now.month + 1, now.day);
      
      try {
        // Criar pagamento único via PIX
        final dueDate = now.toIso8601String().split('T')[0];
        
        // Verificar se o ID do cliente é válido
        if (customer['id'] == null || customer['id'].toString().isEmpty) {
          throw Exception('ID do cliente inválido');
        }
        
        final paymentResponse = await _asaasService.createPayment(
          customerId: customer['id'],
          value: totalPrice,
          description: description,
          dueDate: dueDate,
          billingType: 'PIX',
        );
        
        if (paymentResponse == null) {
          throw Exception('Resposta nula ao criar pagamento PIX');
        }
        
        _paymentData = paymentResponse;
        
        // Criar dados do PIX mesmo se não tivermos o QR code
        _pixData = {
          'copyPaste': 'Código PIX indisponível',
          'expirationDate': dueDate,
        };
        
        // Verificar se o QR code foi gerado corretamente
        if (paymentResponse['pix'] != null) {
          final pixData = paymentResponse['pix'];
          if (pixData['encodedImage'] != null && pixData['payload'] != null) {
            _pixData = {
              'qrCode': pixData['encodedImage'],
              'copyPaste': pixData['payload'],
              'expirationDate': paymentResponse['dueDate'] ?? dueDate,
            };
            
            debugPrint('QR Code PIX gerado com sucesso');
          } else {
            debugPrint('Dados do PIX incompletos na resposta');
          }
        } else {
          // Tentar obter o QR code manualmente
          try {
            if (paymentResponse['id'] != null) {
              final pixData = await _asaasService.getPixQrCode(paymentResponse['id']);
              if (pixData != null && pixData['encodedImage'] != null && pixData['payload'] != null) {
                _pixData = {
                  'qrCode': pixData['encodedImage'],
                  'copyPaste': pixData['payload'],
                  'expirationDate': paymentResponse['dueDate'] ?? dueDate,
                };
                debugPrint('QR Code PIX obtido manualmente com sucesso');
              }
            }
          } catch (e) {
            debugPrint('Erro ao obter QR Code PIX manualmente: $e');
            // Manter os dados básicos do PIX que já definimos
          }
        }
        
        debugPrint('Pagamento PIX criado no Asaas: ${paymentResponse['id'] ?? "ID não disponível"}');
        
        // Salvar informações da assinatura no Supabase
        try {
          // Criar assinatura
          await _supabaseService.createSubscription({
            'plan_name': planName,
            'plan_type': planType,
            'price': totalPrice,
            'status': 'pending',
            'payment_method': 'pix',
            'start_date': now.toIso8601String(),
            'next_billing_date': nextBillingDate.toIso8601String(),
            'external_id': paymentResponse['id'] ?? 'unknown', // ID do pagamento no Asaas
          });
          
          // Criar registro de transação
          await _supabaseService.createTransaction({
            'description': description,
            'amount': totalPrice,
            'type': 'expense',
            'date': now.toIso8601String().split('T')[0],
          });
        } catch (e) {
          debugPrint('Erro ao salvar dados no Supabase: $e');
          // Continuar mesmo com erro no Supabase
        }
        
        _status = PaymentStatus.pixGenerated;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Erro ao criar pagamento PIX: $e');
        _status = PaymentStatus.failed;
        _errorMessage = 'Falha ao gerar PIX: ${e.toString()}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Erro geral ao processar pagamento: $e');
      _status = PaymentStatus.failed;
      _errorMessage = 'Erro ao processar pagamento: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Processar pagamento usando nossa nova API de webhook
  Future<bool> processPaymentViaWebhook({
    required String planName,
    required String planType,
    required double totalPrice,
    required String billingType, // 'PIX', 'CREDIT_CARD', 'BOLETO'
  }) async {
    _status = PaymentStatus.processing;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Obter perfil do usuário
      Map<String, dynamic> userProfile;
      try {
        userProfile = await _supabaseService.getUserProfile();
      } catch (e) {
        debugPrint('Erro ao obter perfil do usuário: $e');
        // Usar dados básicos se não conseguir obter o perfil
        userProfile = {
          'name': 'Usuário',
          'email': user.email ?? 'email@exemplo.com',
          'phone': '',
        };
      }
      
      // Criar ou obter cliente no Asaas via nossa API
      Map<String, dynamic> customer;
      try {
        // Verificar se temos CPF/CNPJ no perfil
        if (userProfile['cpf_cnpj'] == null || userProfile['cpf_cnpj'].toString().isEmpty) {
          throw Exception('CPF/CNPJ é obrigatório para criar cliente');
        }
        
        customer = await _asaasService.createCustomerViaWebhook(
          name: userProfile['name'] ?? 'Usuário',
          email: userProfile['email'] ?? user.email ?? 'email@exemplo.com',
          cpfCnpj: userProfile['cpf_cnpj'],
          phone: userProfile['phone'],
          userId: user.id,
        );
      } catch (e) {
        debugPrint('Erro ao criar cliente no Asaas via webhook: $e');
        _status = PaymentStatus.failed;
        _errorMessage = 'Não foi possível criar o cliente: ${e.toString()}';
        notifyListeners();
        return false;
      }
      
      // Descrição do pagamento
      final description = 'Assinatura $planName (${planType == 'annual' ? 'Anual' : 'Mensal'})';
      
      // Data de vencimento (hoje + 1 dia)
      final dueDate = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
      
      // Criar pagamento ou assinatura
      try {
        if (planType == 'single') {
          // Criar pagamento único
          final paymentResponse = await _asaasService.createPaymentViaWebhook(
            customerId: customer['id'],
            value: totalPrice,
            billingType: billingType,
            description: description,
            dueDate: dueDate,
            userId: user.id,
          );
          
          _paymentData = paymentResponse;
          _status = PaymentStatus.success;
          notifyListeners();
          return true;
        } else {
          // Criar assinatura (mensal ou anual)
          final cycle = planType == 'annual' ? 'YEARLY' : 'MONTHLY';
          
          final subscriptionResponse = await _asaasService.createSubscriptionViaWebhook(
            customerId: customer['id'],
            value: totalPrice,
            billingType: billingType,
            cycle: cycle,
            description: description,
            nextDueDate: dueDate,
            userId: user.id,
          );
          
          _paymentData = subscriptionResponse;
          _status = PaymentStatus.success;
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint('Erro ao criar pagamento/assinatura: $e');
        _status = PaymentStatus.failed;
        _errorMessage = 'Falha ao processar pagamento: ${e.toString()}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Erro geral ao processar pagamento via webhook: $e');
      _status = PaymentStatus.failed;
      _errorMessage = 'Erro ao processar pagamento: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Processar pagamento usando n8n
  Future<bool> processPaymentViaN8n({
    required String userId,
    required String email,
    required String planName,
    required bool isAnnual,
    String? name,
    String? cpf,
    String? phone,
  }) async {
    _status = PaymentStatus.processing;
    _errorMessage = null;
    notifyListeners();
    
    try {
      debugPrint('Iniciando processamento de pagamento via n8n');
      
      // Definir URL do webhook n8n correta
      String webhookUrl = 'https://n8n-n8n.cnbu8g.easypanel.host/webhook/3111eb7b-0cd3-4001-bf5f-63187043c76d';
      
      debugPrint('Webhook URL: $webhookUrl');
      
      // Calcular preços com base no plano selecionado
      final double planPrice = planName == 'Básico' 
          ? (isAnnual ? 199.00 : 19.90)
          : (isAnnual ? 299.00 : 29.90);
      
      // Taxa de setup fixa
      const double setupFee = 49.90;
      
      // Calcular preço total
      final double totalPrice = planPrice + setupFee;
      
      // Validar campos obrigatórios
      if (name == null || name.isEmpty || name == 'Nome não informado') {
        throw Exception('Nome é obrigatório para criar pagamento');
      }
      
      if (cpf == null || cpf.isEmpty || cpf == 'CPF não informado') {
        throw Exception('CPF é obrigatório para criar pagamento');
      }
      
      // Telefone não é mais obrigatório, usar valor vazio se não fornecido
      final String phoneValue = (phone == null || phone.isEmpty || phone == 'Telefone não informado')
          ? '' // Valor vazio para telefone, não usar valor padrão
          : phone;
      
      // Preparar dados para enviar ao n8n
      final Map<String, dynamic> paymentData = {
        'userId': userId,
        'email': email,
        'planName': planName,
        'isAnnual': isAnnual,
        'planType': isAnnual ? 'annual' : 'monthly',
        'planPrice': planPrice,
        'setupFee': setupFee,
        'totalPrice': totalPrice,
        'name': name,
        'cpf': cpf,
        'phone': phoneValue,
      };
      
      // Log detalhado para depuração
      debugPrint('-------- DETALHES DOS DADOS ENVIADOS PARA N8N --------');
      debugPrint('userId: $userId');
      debugPrint('email: $email');
      debugPrint('name: $name');
      debugPrint('cpf: $cpf (deve ser o valor real)');
      debugPrint('phone: $phoneValue (vazio se não informado)');
      debugPrint('planName: $planName');
      debugPrint('planType: ${isAnnual ? 'annual' : 'monthly'}');
      debugPrint('-----------------------------------------------------');
      
      debugPrint('Enviando dados para n8n: $paymentData');
      
      // Enviar dados para o webhook n8n
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(paymentData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao processar pagamento via n8n');
        },
      );
      
      debugPrint('Resposta do n8n: ${response.statusCode}');
      debugPrint('Headers da resposta: ${response.headers}');
      
      if (response.body.isNotEmpty) {
        if (response.body.length > 100) {
          debugPrint('Corpo da resposta: ${response.body.substring(0, 100)}...');
        } else {
          debugPrint('Corpo da resposta: ${response.body}');
        }
      } else {
        debugPrint('Corpo da resposta está vazio');
      }
      
      // Verificar se é um redirecionamento
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          debugPrint('URL de redirecionamento encontrada: $redirectUrl');
          _paymentData = {'url': redirectUrl};
          _status = PaymentStatus.success;
          notifyListeners();
          return true;
        }
      }
      
      // Se a resposta for bem-sucedida (código 200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Mesmo que o corpo esteja vazio, vamos tentar processar a resposta
        try {
          Map<String, dynamic> responseData;
          
          // Se a resposta for vazia, exibir erro claro
          if (response.body.trim().isEmpty) {
            debugPrint('Resposta vazia do n8n, não é possível extrair URL de pagamento');
            throw Exception(
              'O servidor n8n retornou uma resposta vazia.\n\n'
              'O n8n deve retornar um JSON com a URL de pagamento no formato:\n'
              '{"paymentUrl": "https://url-do-pagamento"}'
            );
          }
          
          // Tentar fazer o parsing do JSON
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
          
          debugPrint('Dados da resposta do n8n: $responseData');
          
          // Verificar se temos o campo de URL de pagamento
          if (responseData.containsKey('paymentUrl')) {
            final paymentUrl = responseData['paymentUrl'];
            
            if (paymentUrl != null && paymentUrl.toString().isNotEmpty) {
              // Salvar os dados da resposta com a URL
              _paymentData = {'url': paymentUrl, ...responseData};
              _status = PaymentStatus.success;
              notifyListeners();
              return true;
            }
          }
          
          // Se não encontramos a URL mas temos uma mensagem, ainda é um sucesso
          if (responseData.containsKey('message')) {
            debugPrint('Resposta recebida sem paymentUrl: ${responseData['message']}');
            _paymentData = responseData;
            _status = PaymentStatus.success;
            notifyListeners();
            return true;
          }
          
          // Se chegamos aqui, a resposta foi "bem-sucedida" mas não temos dados úteis
          throw Exception('Resposta do n8n não contém URL de pagamento ou mensagem');
          
        } catch (jsonError) {
          debugPrint('Erro ao processar JSON da resposta: $jsonError');
          throw Exception('Erro ao processar resposta do n8n: $jsonError');
        }
      }
      
      // Se chegamos aqui, houve um erro na resposta
      throw Exception('Falha ao processar pagamento via n8n: [${response.statusCode}] ${response.body}');
    } catch (e) {
      debugPrint('Erro ao processar pagamento via n8n: $e');
      _status = PaymentStatus.failed;
      _errorMessage = 'Erro ao processar pagamento: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Limpar erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Salvar dados do pagamento (para link de pagamento)
  Future<bool> savePaymentData(Map<String, dynamic> paymentLinkData) async {
    try {
      _paymentData = paymentLinkData;
      
      // Salvar link de pagamento no Supabase (opcional)
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Dados atuais
          final now = DateTime.now();
          
          // Criar registro de transação pendente
          await _supabaseService.createTransaction({
            'description': paymentLinkData['name'] ?? 'Assinatura via link de pagamento',
            'amount': paymentLinkData['value'] ?? 0.0,
            'type': 'expense',
            'date': now.toIso8601String().split('T')[0],
            'status': 'pending',
            'payment_link_id': paymentLinkData['id'],
          });
          
          debugPrint('Dados do link de pagamento salvos no Supabase');
        }
      } catch (e) {
        debugPrint('Erro ao salvar dados no Supabase: $e');
        // Continuar mesmo com erro no Supabase
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar dados do pagamento: $e');
      _errorMessage = 'Erro ao salvar dados do pagamento: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Método para verificar o status do pagamento
  Future<Map<String, dynamic>?> checkPaymentStatus(String paymentId) async {
    try {
      debugPrint('Verificando status do pagamento: $paymentId');
      
      // Verificar o status do pagamento no Asaas
      final paymentStatus = await _asaasService.getPayment(paymentId);
      
      if (paymentStatus != null) {
        debugPrint('Status do pagamento: ${paymentStatus['status']}');
        
        // Se o pagamento foi confirmado, atualizar a assinatura no Supabase
        if (paymentStatus['status'] == 'CONFIRMED' || 
            paymentStatus['status'] == 'RECEIVED' ||
            paymentStatus['status'] == 'RECEIVED_IN_CASH') {
          
          try {
            // Buscar a assinatura pelo ID externo
            final subscription = await _supabaseService.getSubscriptionByExternalId(paymentId);
            
            if (subscription != null) {
              // Atualizar o status da assinatura para ativo
              await _supabaseService.updateSubscription(
                subscription['id'],
                {
                  'status': 'active',
                  'payment_status': 'confirmed',
                  'updated_at': DateTime.now().toIso8601String(),
                },
              );
              
              debugPrint('Assinatura atualizada para ativa');
            }
          } catch (e) {
            debugPrint('Erro ao atualizar assinatura: $e');
          }
        }
        
        return paymentStatus;
      }
      
      return null;
    } catch (e) {
      debugPrint('Erro ao verificar status do pagamento: $e');
      return null;
    }
  }
  
  // Método para verificar periodicamente o status do pagamento PIX
  Future<bool> startPaymentStatusCheck(String paymentId, {int maxAttempts = 10}) async {
    int attempts = 0;
    bool isConfirmed = false;
    
    debugPrint('Iniciando verificação periódica do pagamento: $paymentId');
    
    while (attempts < maxAttempts && !isConfirmed) {
      try {
        final paymentStatus = await checkPaymentStatus(paymentId);
        
        if (paymentStatus != null && 
            (paymentStatus['status'] == 'CONFIRMED' || 
             paymentStatus['status'] == 'RECEIVED' ||
             paymentStatus['status'] == 'RECEIVED_IN_CASH')) {
          debugPrint('Pagamento confirmado após ${attempts + 1} tentativas');
        isConfirmed = true;
          break;
        }
        
        attempts++;
        await Future.delayed(Duration(seconds: 3 + attempts));
      } catch (e) {
        debugPrint('Erro na verificação #$attempts: $e');
        attempts++;
        await Future.delayed(Duration(seconds: 3));
      }
    }
    
    return isConfirmed;
  }
  
  // Método para obter o QR code PIX de uma assinatura
  Future<Map<String, dynamic>> getSubscriptionPixQrCode(String subscriptionId) async {
    try {
      _errorMessage = null;
      notifyListeners();
      
      debugPrint('Obtendo QR code PIX para assinatura: $subscriptionId');
      
      // Definir URL da API do webhook (local ou produção)
      String webhookBaseUrl;
      
      if (kIsWeb) {
        // Em produção ou desenvolvimento web, usar a URL de API correspondente
        if (kReleaseMode) {
          // URL de produção
          webhookBaseUrl = 'https://medmoney.me';
        } else {
          // URL de desenvolvimento
          webhookBaseUrl = 'http://localhost:3000';
        }
      } else {
        // Em dispositivos móveis, usar a URL de API de produção
        webhookBaseUrl = 'https://medmoney.me';
      }
      
      // Utilizamos nossa API de webhook para obter o QR code PIX
      final url = Uri.parse('$webhookBaseUrl/api/subscription/$subscriptionId/pix');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao obter QR code PIX');
        },
      );
      
      debugPrint('Resposta: ${response.statusCode}');
      if (response.body.length > 100) {
        debugPrint('Corpo da resposta: ${response.body.substring(0, 100)}...');
      } else {
        debugPrint('Corpo da resposta: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Verifica se o QR code PIX está na resposta direta
        if (responseData['pixQrCode'] != null) {
          return responseData;
        }
        
        // Verifica se a resposta inclui uma assinatura com primeiro pagamento contendo PIX
        final subscription = responseData['subscription'] as Map<String, dynamic>?;
        if (subscription != null) {
          final firstPayment = subscription['firstPayment'] as Map<String, dynamic>?;
          if (firstPayment != null && firstPayment['pix'] != null) {
            return {
              'subscription': subscription,
              'pixQrCode': firstPayment['pix']
            };
          }
        }
        
        // Caso não tenha encontrado QR code PIX, verificar se temos o paymentData
        final paymentData = _paymentData;
        if (paymentData != null) {
          // Verifica se temos um first payment com pix
          final firstPayment = paymentData['firstPayment'] as Map<String, dynamic>?;
          if (firstPayment != null && firstPayment['pix'] != null) {
            return {
              'subscription': paymentData,
              'pixQrCode': firstPayment['pix']
            };
          }
          
          // Verifica se temos um campo pix direto
          final pix = paymentData['pix'];
          if (pix != null) {
            return {
              'subscription': paymentData,
              'pixQrCode': pix
            };
          }
        }
        
        // Retornar os dados da resposta de qualquer forma
        return responseData;
      } else {
        throw Exception('Falha ao obter QR code PIX: [${response.statusCode}] ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao obter QR code PIX: $e');
      _errorMessage = 'Erro ao obter QR code PIX: $e';
      notifyListeners();
      
      // Mesmo com erro, se tivermos _paymentData com pix, retornar
      final paymentData = _paymentData;
      if (paymentData != null) {
        final pix = paymentData['pix'];
        if (pix != null) {
          return {
            'subscription': paymentData,
            'pixQrCode': pix
          };
        }
        
        final firstPayment = paymentData['firstPayment'] as Map<String, dynamic>?;
        if (firstPayment != null && firstPayment['pix'] != null) {
          return {
            'subscription': paymentData,
            'pixQrCode': firstPayment['pix']
          };
        }
      }
      
      throw Exception('Não foi possível obter o QR code PIX: $e');
    }
  }
  
  // Método para criar um link de pagamento do Asaas
  Future<String?> createAsaasCheckout({
    required String planName,
    required String planType,
    required double totalPrice,
  }) async {
    _status = PaymentStatus.processing;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Verificar se o usuário está autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }
      
      // Obter perfil do usuário
      Map<String, dynamic> userProfile;
      try {
        userProfile = await _supabaseService.getUserProfile();
      } catch (e) {
        debugPrint('Erro ao obter perfil do usuário: $e');
        // Usar dados básicos se não conseguir obter o perfil
        userProfile = {
          'name': 'Usuário',
          'email': user.email ?? 'email@exemplo.com',
          'phone': '',
        };
      }
      
      // Gerar referência externa única
      final externalReference = 'medmoney_${DateTime.now().millisecondsSinceEpoch}';
      
      // Descrição do pagamento
      final description = 'Assinatura $planName (${planType == 'annual' ? 'Anual' : 'Mensal'})';
      
      // Calcular próxima data de cobrança
      final now = DateTime.now();
      
      // Salvar o plano escolhido no Supabase primeiro
      try {
        await _supabaseService.saveSelectedPlan(
          userId: user.id,
          planType: planName,
          billingFrequency: planType,
          price: totalPrice,
          externalReference: externalReference,
          paymentId: null, // Será atualizado quando recebermos o webhook
        );
        debugPrint('Plano escolhido salvo com sucesso no Supabase');
      } catch (e) {
        debugPrint('Erro ao salvar plano escolhido: $e');
        // Continuar mesmo com erro, pois podemos tentar novamente mais tarde
      }
      
      // Criar link de pagamento
      final paymentLinkData = await _asaasService.createPaymentLink(
        name: 'Assinatura MedMoney - $planName',
        value: totalPrice,
        description: description,
        dueDateLimitDays: '7', // 7 dias para efetuar o pagamento
        allowedPaymentTypes: ['CREDIT_CARD', 'PIX', 'BOLETO'],
      );
      
      // Salvar dados do pagamento
      _paymentData = paymentLinkData;
      
      // Atualizar status
      _status = PaymentStatus.pixGenerated;
      notifyListeners();
      
      // Se tudo ocorreu bem, retornar a URL do link de pagamento
      if (paymentLinkData.containsKey('url')) {
        debugPrint('Link de pagamento gerado com sucesso: ${paymentLinkData['url']}');
        return paymentLinkData['url'];
      } else {
        throw Exception('URL do link de pagamento não encontrada na resposta');
      }
    } catch (e) {
      debugPrint('Erro ao criar link de pagamento: $e');
      _status = PaymentStatus.failed;
      _errorMessage = 'Falha ao gerar o checkout: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  // Método para verificar se o usuário tem assinatura ativa
  Future<bool> checkActiveSubscription() async {
    try {
      // Verificar se o usuário está autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return false;
      }
      
      // Buscar assinaturas ativas do usuário
      final subscriptions = await _supabaseService.getActiveSubscriptions();
      
      // Se encontrou pelo menos uma assinatura ativa, o usuário tem acesso
      return subscriptions.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao verificar assinatura ativa: $e');
      return false;
    }
  }
} 