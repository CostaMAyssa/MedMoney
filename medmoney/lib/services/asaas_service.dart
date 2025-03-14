import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class AsaasService {
  // Configurações do Asaas
  static const String _apiKeySandbox = 'aact_YTU5YTE0M2M2N2I4MTliNzk0YTI5N2U5MzdjNWZmNDQ6OjAwMDAwMDAwMDAwMDAwNDM2MDg6OiRhYWNoXzgwZWVjMGVlLTk2ZjMtNDFmMy1hZjJiLTU5ZWRkYzA3NDRkMw==';
  static const String _apiKeyProduction = 'SUA_API_KEY_PRODUCAO_ASAAS'; // Será configurada quando for para produção
  
  // URLs base
  static const String _baseUrlSandbox = 'https://sandbox.asaas.com/api/v3';
  static const String _baseUrlProduction = 'https://www.asaas.com/api/v3';
  
  // Determina se está em modo de produção ou sandbox
  static const bool _isProduction = false; // Altere para true em produção
  
  // Getters para as configurações atuais
  static String get _apiKey => _isProduction ? _apiKeyProduction : _apiKeySandbox;
  static String get _baseUrl => _isProduction ? _baseUrlProduction : _baseUrlSandbox;
  
  // Headers padrão para as requisições
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'access_token': _apiKey,
  };
  
  // Criar um cliente (customer) no Asaas
  static Future<Map<String, dynamic>> createCustomer({
    required String name,
    required String email,
    required String cpfCnpj,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'cpfCnpj': cpfCnpj,
          'phone': phone,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('Cliente criado com sucesso no Asaas: ${data['id']}');
        }
        return data;
      } else {
        throw Exception('Erro ao criar cliente no Asaas: ${data['errors'][0]['description']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao criar cliente no Asaas: $e');
      }
      rethrow;
    }
  }
  
  // Criar uma cobrança (payment) no Asaas
  static Future<Map<String, dynamic>> createPayment({
    required String customerId,
    required double value,
    required String description,
    required String dueDate,
    String? externalReference,
    bool? installment = false,
    int? installmentCount,
    String billingType = 'CREDIT_CARD', // BOLETO, CREDIT_CARD, PIX
  }) async {
    try {
      final Map<String, dynamic> paymentData = {
        'customer': customerId,
        'billingType': billingType,
        'value': value,
        'description': description,
        'dueDate': dueDate,
      };
      
      if (externalReference != null) {
        paymentData['externalReference'] = externalReference;
      }
      
      if (installment == true && installmentCount != null) {
        paymentData['installmentCount'] = installmentCount;
        paymentData['installmentValue'] = value / installmentCount;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/payments'),
        headers: _headers,
        body: jsonEncode(paymentData),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('Cobrança criada com sucesso no Asaas: ${data['id']}');
        }
        
        // Salvar a cobrança no Supabase
        await _savePaymentToSupabase(data);
        
        return data;
      } else {
        throw Exception('Erro ao criar cobrança no Asaas: ${data['errors'][0]['description']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao criar cobrança no Asaas: $e');
      }
      rethrow;
    }
  }
  
  // Processar pagamento com cartão de crédito
  static Future<Map<String, dynamic>> processCreditCardPayment({
    required String paymentId,
    required String holderName,
    required String number,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/$paymentId/payWithCreditCard'),
        headers: _headers,
        body: jsonEncode({
          'creditCard': {
            'holderName': holderName,
            'number': number,
            'expiryMonth': expiryMonth,
            'expiryYear': expiryYear,
            'cvv': cvv,
          },
          'creditCardHolderInfo': {
            'name': holderName,
            'email': await _getCurrentUserEmail(),
            'cpfCnpj': '00000000000', // Deve ser substituído pelo CPF real
            'postalCode': '00000000', // Deve ser substituído pelo CEP real
            'addressNumber': '0', // Deve ser substituído pelo número real
            'phone': '00000000000', // Deve ser substituído pelo telefone real
          },
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('Pagamento com cartão processado com sucesso: ${data['id']}');
        }
        
        // Atualizar o status do pagamento no Supabase
        await _updatePaymentStatusInSupabase(paymentId, data['status']);
        
        return data;
      } else {
        throw Exception('Erro ao processar pagamento com cartão: ${data['errors'][0]['description']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao processar pagamento com cartão: $e');
      }
      rethrow;
    }
  }
  
  // Gerar QR Code PIX
  static Future<Map<String, dynamic>> generatePixQrCode(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$paymentId/pixQrCode'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('QR Code PIX gerado com sucesso');
        }
        return data;
      } else {
        throw Exception('Erro ao gerar QR Code PIX: ${data['errors'][0]['description']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao gerar QR Code PIX: $e');
      }
      rethrow;
    }
  }
  
  // Consultar status de um pagamento
  static Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$paymentId'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('Status do pagamento consultado com sucesso: ${data['status']}');
        }
        return data;
      } else {
        throw Exception('Erro ao consultar status do pagamento: ${data['errors'][0]['description']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao consultar status do pagamento: $e');
      }
      rethrow;
    }
  }
  
  // Salvar pagamento no Supabase
  static Future<void> _savePaymentToSupabase(Map<String, dynamic> paymentData) async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user == null) throw Exception('Usuário não autenticado');
      
      await SupabaseService.client.from('payments').insert({
        'user_id': user.id,
        'payment_method': paymentData['billingType'],
        'amount': paymentData['value'],
        'description': paymentData['description'],
        'status': paymentData['status'],
        'asaas_id': paymentData['id'],
      });
      
      if (kDebugMode) {
        print('Pagamento salvo no Supabase com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar pagamento no Supabase: $e');
      }
      rethrow;
    }
  }
  
  // Atualizar status do pagamento no Supabase
  static Future<void> _updatePaymentStatusInSupabase(String asaasId, String status) async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user == null) throw Exception('Usuário não autenticado');
      
      await SupabaseService.client
          .from('payments')
          .update({'status': status})
          .eq('asaas_id', asaasId)
          .eq('user_id', user.id);
      
      if (kDebugMode) {
        print('Status do pagamento atualizado no Supabase com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao atualizar status do pagamento no Supabase: $e');
      }
      rethrow;
    }
  }
  
  // Obter email do usuário atual
  static Future<String> _getCurrentUserEmail() async {
    final user = SupabaseService.getCurrentUser();
    if (user == null) throw Exception('Usuário não autenticado');
    return user.email ?? '';
  }
  
  // Processar pagamento (método principal a ser chamado pela aplicação)
  static Future<Map<String, dynamic>> processPayment({
    required String paymentMethod,
    required double amount,
    required String description,
    String? cardNumber,
    String? cardHolder,
    String? expiryDate,
    String? cvv,
  }) async {
    try {
      // Obter o usuário atual
      final user = SupabaseService.getCurrentUser();
      if (user == null) throw Exception('Usuário não autenticado');
      
      // Obter ou criar o cliente no Asaas
      final customerData = await _getOrCreateCustomer(user.email ?? '');
      
      // Criar a cobrança
      final dueDate = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
      final billingType = _getBillingTypeFromPaymentMethod(paymentMethod);
      
      final paymentData = await createPayment(
        customerId: customerData['id'],
        value: amount,
        description: description,
        dueDate: dueDate,
        externalReference: user.id,
        billingType: billingType,
      );
      
      // Processar o pagamento de acordo com o método
      if (paymentMethod == 'credit_card' && 
          cardNumber != null && 
          cardHolder != null && 
          expiryDate != null && 
          cvv != null) {
        
        final expiryParts = expiryDate.split('/');
        if (expiryParts.length != 2) throw Exception('Data de validade inválida');
        
        return await processCreditCardPayment(
          paymentId: paymentData['id'],
          holderName: cardHolder,
          number: cardNumber.replaceAll(' ', ''),
          expiryMonth: expiryParts[0],
          expiryYear: expiryParts[1],
          cvv: cvv,
        );
      } else if (paymentMethod == 'pix') {
        return await generatePixQrCode(paymentData['id']);
      } else {
        return paymentData;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao processar pagamento: $e');
      }
      rethrow;
    }
  }
  
  // Obter ou criar cliente no Asaas
  static Future<Map<String, dynamic>> _getOrCreateCustomer(String email) async {
    try {
      // Tentar encontrar o cliente pelo email
      final response = await http.get(
        Uri.parse('$_baseUrl/customers?email=$email'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300 && data['data'].isNotEmpty) {
        return data['data'][0];
      } else {
        // Cliente não encontrado, criar um novo
        final user = SupabaseService.getCurrentUser();
        if (user == null) throw Exception('Usuário não autenticado');
        
        // Obter dados do perfil do usuário
        final profileData = await SupabaseService.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        
        return await createCustomer(
          name: profileData['name'] ?? 'Cliente',
          email: email,
          cpfCnpj: '00000000000', // Deve ser substituído pelo CPF real
          phone: profileData['phone'],
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter ou criar cliente no Asaas: $e');
      }
      rethrow;
    }
  }
  
  // Converter método de pagamento para o formato do Asaas
  static String _getBillingTypeFromPaymentMethod(String paymentMethod) {
    switch (paymentMethod) {
      case 'credit_card':
        return 'CREDIT_CARD';
      case 'pix':
        return 'PIX';
      case 'boleto':
        return 'BOLETO';
      default:
        return 'UNDEFINED';
    }
  }
} 