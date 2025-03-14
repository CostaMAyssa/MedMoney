import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AsaasService {
  // Singleton pattern
  static final AsaasService _instance = AsaasService._internal();
  factory AsaasService() => _instance;
  AsaasService._internal();

  // URLs da API
  static const String _sandboxUrl = 'https://sandbox.asaas.com/api/v3';
  static const String _productionUrl = 'https://www.asaas.com/api/v3';
  
  // Chaves de API
  static String get _apiKey => dotenv.env['ASAAS_API_KEY'] ?? 'sua_chave_api_do_asaas';
  static bool get _isSandbox => dotenv.env['ASAAS_SANDBOX'] == 'true';
  
  // URL base da API
  String get _baseUrl => _isSandbox ? _sandboxUrl : _productionUrl;
  
  // Headers para as requisições
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'access_token': _apiKey,
  };
  
  // Clientes
  Future<Map<String, dynamic>> createCustomer({
    required String name,
    required String email,
    required String cpfCnpj,
    String? phone,
    String? mobilePhone,
    String? address,
    String? addressNumber,
    String? complement,
    String? province,
    String? postalCode,
  }) async {
    final url = Uri.parse('$_baseUrl/customers');
    
    final body = jsonEncode({
      'name': name,
      'email': email,
      'cpfCnpj': cpfCnpj,
      if (phone != null) 'phone': phone,
      if (mobilePhone != null) 'mobilePhone': mobilePhone,
      if (address != null) 'address': address,
      if (addressNumber != null) 'addressNumber': addressNumber,
      if (complement != null) 'complement': complement,
      if (province != null) 'province': province,
      if (postalCode != null) 'postalCode': postalCode,
    });
    
    final response = await http.post(url, headers: _headers, body: body);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao criar cliente: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> getCustomer(String customerId) async {
    final url = Uri.parse('$_baseUrl/customers/$customerId');
    
    final response = await http.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao obter cliente: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> updateCustomer({
    required String customerId,
    String? name,
    String? email,
    String? cpfCnpj,
    String? phone,
    String? mobilePhone,
    String? address,
    String? addressNumber,
    String? complement,
    String? province,
    String? postalCode,
  }) async {
    final url = Uri.parse('$_baseUrl/customers/$customerId');
    
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (cpfCnpj != null) data['cpfCnpj'] = cpfCnpj;
    if (phone != null) data['phone'] = phone;
    if (mobilePhone != null) data['mobilePhone'] = mobilePhone;
    if (address != null) data['address'] = address;
    if (addressNumber != null) data['addressNumber'] = addressNumber;
    if (complement != null) data['complement'] = complement;
    if (province != null) data['province'] = province;
    if (postalCode != null) data['postalCode'] = postalCode;
    
    final body = jsonEncode(data);
    
    final response = await http.post(url, headers: _headers, body: body);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao atualizar cliente: ${response.body}');
    }
  }
  
  // Assinaturas
  Future<Map<String, dynamic>> createSubscription({
    required String customerId,
    required double value,
    required String billingType,
    required String cycle,
    required String description,
    String? nextDueDate,
    int? dueDayMonth,
    int? discountValue,
    String? creditCardHolderName,
    String? creditCardNumber,
    String? creditCardExpiryMonth,
    String? creditCardExpiryYear,
    String? creditCardCcv,
  }) async {
    final url = Uri.parse('$_baseUrl/subscriptions');
    
    final Map<String, dynamic> data = {
      'customer': customerId,
      'value': value,
      'billingType': billingType,
      'cycle': cycle,
      'description': description,
    };
    
    if (nextDueDate != null) data['nextDueDate'] = nextDueDate;
    if (dueDayMonth != null) data['dueDayMonth'] = dueDayMonth;
    if (discountValue != null) data['discountValue'] = discountValue;
    
    // Dados do cartão de crédito (se aplicável)
    if (billingType == 'CREDIT_CARD') {
      if (creditCardHolderName == null || 
          creditCardNumber == null || 
          creditCardExpiryMonth == null || 
          creditCardExpiryYear == null || 
          creditCardCcv == null) {
        throw Exception('Dados do cartão de crédito incompletos');
      }
      
      data['creditCard'] = {
        'holderName': creditCardHolderName,
        'number': creditCardNumber,
        'expiryMonth': creditCardExpiryMonth,
        'expiryYear': creditCardExpiryYear,
        'ccv': creditCardCcv,
      };
      
      data['creditCardHolderInfo'] = {
        'name': creditCardHolderName,
        'email': 'email@cliente.com',
        'cpfCnpj': '00000000000',
        'postalCode': '00000000',
        'addressNumber': '000',
        'addressComplement': null,
        'phone': '0000000000',
        'mobilePhone': '0000000000',
      };
    }
    
    final body = jsonEncode(data);
    
    final response = await http.post(url, headers: _headers, body: body);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao criar assinatura: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> getSubscription(String subscriptionId) async {
    final url = Uri.parse('$_baseUrl/subscriptions/$subscriptionId');
    
    final response = await http.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao obter assinatura: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    final url = Uri.parse('$_baseUrl/subscriptions/$subscriptionId/cancel');
    
    final response = await http.post(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao cancelar assinatura: ${response.body}');
    }
  }
  
  // Pagamentos
  Future<Map<String, dynamic>> createPayment({
    required String customerId,
    required double value,
    required String description,
    required String dueDate,
    String? externalReference,
    String? billingType,
  }) async {
    final url = Uri.parse('$_baseUrl/payments');
    
    final body = jsonEncode({
      'customer': customerId,
      'value': value,
      'description': description,
      'dueDate': dueDate,
      if (externalReference != null) 'externalReference': externalReference,
      'billingType': billingType ?? 'BOLETO',
    });
    
    final response = await http.post(url, headers: _headers, body: body);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao criar pagamento: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final url = Uri.parse('$_baseUrl/payments/$paymentId');
    
    final response = await http.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao obter pagamento: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> cancelPayment(String paymentId) async {
    final url = Uri.parse('$_baseUrl/payments/$paymentId');
    
    final response = await http.delete(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao cancelar pagamento: ${response.body}');
    }
  }
  
  // Métodos auxiliares
  String getPaymentUrl(String paymentId) {
    return '$_baseUrl/payments/$paymentId/identificationField';
  }
  
  String getSubscriptionUrl(String subscriptionId) {
    return '$_baseUrl/subscriptions/$subscriptionId';
  }
} 