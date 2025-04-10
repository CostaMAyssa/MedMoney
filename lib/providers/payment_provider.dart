import 'package:flutter/material.dart';
import '../services/asaas_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  Uint8List? _pixImage;
  bool _isLoading = false;
  
  // Getters
  PaymentStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get paymentData => _paymentData;
  Map<String, dynamic>? get pixData => _pixData;
  Uint8List? get pixImage => _pixImage;
  bool get isProcessing => _status == PaymentStatus.processing;
  bool get isLoading => _isLoading;
  
  // Resetar estado
  void reset() {
    _status = PaymentStatus.initial;
    _errorMessage = null;
    _paymentData = null;
    _pixData = null;
    _pixImage = null;
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
    required String planName,
    required bool isAnnual,
    required String email,
    required String userId,
    required String name,
    required String cpf,
    required String phone,
  }) async {
    try {
      // Log detalhado de todos os parâmetros recebidos
      debugPrint('==== INICIANDO PROCESSAMENTO DE PAGAMENTO VIA N8N ====');
      debugPrint('Plano: $planName');
      debugPrint('Tipo: ${isAnnual ? "Anual" : "Mensal"}');
      debugPrint('Email: $email');
      debugPrint('UserId: $userId');
      debugPrint('Nome: $name');
      debugPrint('CPF: $cpf');
      debugPrint('Telefone: $phone');
      
      _isLoading = true;
      _errorMessage = null;
      _paymentData = null;
      notifyListeners();
      
      // Limpar e validar o CPF (remover formatação)
      final cleanCpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
      
      // Garantir que o telefone é uma string válida
      final String phoneStr = phone.toString().trim();
      debugPrint('Telefone na processPaymentViaN8n (string): $phoneStr');
      
      // Construir URL do webhook do N8N
      final String n8nWebhookUrl = dotenv.env['N8N_WEBHOOK_URL'] ?? 'https://n8n-n8n.cnbu8g.easypanel.host/webhook/3111eb7b-0cd3-4001-bf5f-63187043c76d';
      debugPrint('Webhook URL: $n8nWebhookUrl');
      
      // Preparar payload
      final planType = isAnnual ? 'annual' : 'monthly';
      
      // Definir valores precisos para o plano
      double planPrice;
      if (planName == 'Essencial') {
        planPrice = isAnnual ? 163.00 : 15.90;
      } else if (planName == 'Premium') {
        planPrice = isAnnual ? 254.00 : 24.90;
      } else {
        // Valor padrão se algum outro nome de plano for passado
        planPrice = isAnnual ? 163.00 : 15.90;
      }
          
      // Taxa de setup (agora é zero)
      final double setupFee = 0.0;
      
      // Cálculo total (sem taxa de setup)
      final double totalPrice = planPrice;
      
      // Mostrar log detalhado para debugging
      debugPrint('Processando pagamento para plano: $planName, tipo: ${isAnnual ? "Anual" : "Mensal"}, preço: $planPrice');
      
      final Map<String, dynamic> data = {
        'userId': userId,
        'email': email,
        'planName': planName,
        'isAnnual': isAnnual,
        'planType': planType,
        'planPrice': planPrice,
        'setupFee': setupFee,
        'totalPrice': totalPrice,
        'name': name,
        'cpf': cleanCpf,
      };
      
      // Adicionar telefone apenas se não for vazio
      if (phoneStr.isNotEmpty) {
        data['phone'] = phoneStr;
      } else {
        // Adicionar telefone vazio para o log
        data['phone'] = '';
      }
      
      debugPrint('Enviando dados para n8n: $data');
      
      // Fazer a requisição para o N8N
      final response = await http.post(
        Uri.parse(n8nWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      debugPrint('Resposta do n8n: ${response.statusCode}');
      debugPrint('Headers da resposta: ${response.headers}');
      debugPrint('Corpo da resposta: ${response.body}');
      
      // Verificar se a resposta foi bem-sucedida
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Tentar decodificar a resposta
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('==== RESPOSTA DO N8N DECODIFICADA ====');
          debugPrint('Dados da resposta do n8n: $responseData');
          
          // Salvar os dados de pagamento
          _paymentData = responseData;
          
          // Verificar se temos uma URL de pagamento
          String? paymentUrl;
          if (_paymentData!.containsKey('paymentUrl')) {
            paymentUrl = _paymentData!['paymentUrl'];
            debugPrint('URL de pagamento encontrada: $paymentUrl');
          } else if (_paymentData!.containsKey('url')) {
            paymentUrl = _paymentData!['url'];
            debugPrint('URL de pagamento encontrada (campo url): $paymentUrl');
          } else if (_paymentData!.containsKey('payment_url')) {
            paymentUrl = _paymentData!['payment_url'];
            debugPrint('URL de pagamento encontrada (campo payment_url): $paymentUrl');
          }
          
          // Log final
          debugPrint('==== FIM DO PROCESSAMENTO DE PAGAMENTO ====');
          debugPrint('Sucesso: ${paymentUrl != null ? "Sim" : "Não"}');
          
          // Verificar se temos uma URL de pagamento ou outra resposta válida
          if (_paymentData!.containsKey('paymentUrl') || 
              _paymentData!.containsKey('url') || 
              _paymentData!.containsKey('payment_url') ||
              _paymentData!.containsKey('message')) {
            
            return true;
          } else {
            _errorMessage = 'Resposta inválida do servidor de processamento de pagamento';
            return false;
          }
        } catch (e) {
          _errorMessage = 'Erro ao processar resposta do pagamento: $e';
          return false;
        }
      } else {
        _errorMessage = 'Erro ao processar pagamento: ${response.statusCode} - ${response.body}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erro ao processar pagamento: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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