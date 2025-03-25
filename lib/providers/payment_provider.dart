import 'package:flutter/material.dart';
import '../services/asaas_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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
        // Limpar o número do cartão (remover espaços)
        final cleanCardNumber = cardNumber.replaceAll(' ', '');
        
        // Validar dados do cartão
        if (cleanCardNumber.length < 13 || cleanCardNumber.length > 19) {
          throw Exception('Número do cartão inválido');
        }
        
        if (cardHolderName.isEmpty) {
          throw Exception('Nome do titular do cartão é obrigatório');
        }
        
        // Validar data de expiração
        final expiryParts = expiryDate.split('/');
        if (expiryParts.length != 2) {
          throw Exception('Data de expiração inválida. Use o formato MM/AA');
        }
        
        // Validar CVV
        if (cvv.length < 3 || cvv.length > 4) {
          throw Exception('CVV inválido');
        }
        
        // Obter ou criar cliente no Asaas
        customer = await _asaasService.createCustomer(
          name: userProfile['name'] ?? 'Usuário',
          email: userProfile['email'] ?? user.email ?? 'email@exemplo.com',
          cpfCnpj: userProfile['cpf_cnpj'] ?? '12345678909', // Usar CPF do perfil ou um valor padrão
          phone: userProfile['phone'],
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
        // Garantir que temos um CPF válido (mesmo que seja fictício para teste)
        final cpfCnpj = '12345678909'; // CPF fictício para teste
        
        customer = await _asaasService.createCustomer(
          name: userProfile['name'] ?? 'Usuário',
          email: userProfile['email'] ?? user.email ?? 'email@exemplo.com',
          cpfCnpj: cpfCnpj,
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
    
    // Verificar o status a cada 30 segundos
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      attempts++;
      debugPrint('Verificação $attempts de $maxAttempts');
      
      // Verificar o status do pagamento
      final status = await checkPaymentStatus(paymentId);
      
      // Se o pagamento foi confirmado ou o número máximo de tentativas foi atingido
      if (status != null && 
          (status['status'] == 'CONFIRMED' || 
           status['status'] == 'RECEIVED' || 
           status['status'] == 'RECEIVED_IN_CASH')) {
        
        isConfirmed = true;
        timer.cancel();
        
        // Notificar os ouvintes
        _status = PaymentStatus.success;
        notifyListeners();
        
        debugPrint('Pagamento confirmado!');
      } else if (attempts >= maxAttempts) {
        timer.cancel();
        debugPrint('Número máximo de tentativas atingido');
      }
    });
    
    return isConfirmed;
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