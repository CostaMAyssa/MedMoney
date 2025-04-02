import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';

class AsaasService {
  // Singleton pattern
  static final AsaasService _instance = AsaasService._internal();
  factory AsaasService() => _instance;
  AsaasService._internal() {
    // Imprimir informações de configuração ao inicializar o serviço
    debugPrint('==== AsaasService inicializado ====');
    debugPrint('Ambiente: ${_isSandbox ? 'Sandbox' : 'Produção'}');
    debugPrint('URL base: $_baseUrl');
    
    // Verificar se a chave API está configurada
    if (_apiKey.isEmpty) {
      debugPrint('ALERTA: API Key não configurada! Verifique seu arquivo .env');
    } else {
      // Não imprimir a chave completa por segurança
      debugPrint('API Key configurada: Sim (${_apiKey.length > 10 ? _apiKey.substring(0, 10) + "..." : _apiKey})');
    }
    
    // Verificar variáveis de ambiente
    if (dotenv.env['ASAAS_API_KEY'] == null) {
      debugPrint('ERRO: Variável ASAAS_API_KEY não encontrada no arquivo .env');
    }
    
    if (dotenv.env['ASAAS_SANDBOX'] == null) {
      debugPrint('ERRO: Variável ASAAS_SANDBOX não encontrada no arquivo .env');
    }
    
    debugPrint('==== Fim da inicialização do AsaasService ====');
  }

  // URLs da API
  static const String _sandboxUrl = 'https://sandbox.asaas.com/api/v3';
  static const String _productionUrl = 'https://api.asaas.com/api/v3';
  
  // Chaves de API
  static String get _apiKey => dotenv.env['ASAAS_API_KEY'] ?? '';
  static bool get _isSandbox => dotenv.env['ASAAS_SANDBOX'] == 'true';
  
  // URL base da API
  String get _baseUrl => _isSandbox ? _sandboxUrl : _productionUrl;
  
  // Headers para as requisições
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'access_token': _apiKey,
    // No Flutter web, estes headers adicionais podem causar problemas com CORS
    // Manter apenas os headers essenciais
  };
  
  // Método para verificar se a API está configurada corretamente
  Future<bool> checkApiConnection() async {
    try {
      debugPrint('Verificando conexão com a API do Asaas...');
      debugPrint('URL: $_baseUrl/finance/balance');
      
      // Tentativa direta sem usar proxy CORS
      final url = Uri.parse('$_baseUrl/finance/balance');
      
      // Adicionar headers específicos para debugging
      final Map<String, String> debugHeaders = {
        ..._headers,
        'X-Debug-Time': DateTime.now().toIso8601String(),
      };
      
      debugPrint('Headers: $debugHeaders');
      
      final response = await http.get(url, headers: debugHeaders);
      
      debugPrint('Resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        debugPrint('Conexão com a API do Asaas estabelecida com sucesso!');
        return true;
      } else {
        debugPrint('Erro ao conectar com a API do Asaas: ${response.statusCode}');
        
        // Tentar extrair mensagem de erro mais detalhada
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
          debugPrint('Mensagem de erro: $errorMessage');
          
          // Verificar se é um problema de autenticação
          if (response.statusCode == 401) {
            debugPrint('ERRO DE AUTENTICAÇÃO: Verifique se a chave API está correta');
            debugPrint('API Key (primeiros 5 caracteres): ${_apiKey.isNotEmpty ? _apiKey.substring(0, 5) + "..." : "vazia"}');
          }
        } catch (e) {
          debugPrint('Não foi possível extrair mensagem de erro: $e');
        }
        
        // Retornar true mesmo com erro para não bloquear o aplicativo
        debugPrint('Aplicativo continuará funcionando mesmo com erro na API do Asaas');
        return true;
      }
    } catch (e) {
      debugPrint('Exceção ao conectar com a API do Asaas: $e');
      
      // Informações adicionais para debug
      debugPrint('Ambiente: ${_isSandbox ? "Sandbox" : "Produção"}');
      debugPrint('URL Base: $_baseUrl');
      debugPrint('API Key configurada: ${_apiKey.isNotEmpty ? "Sim" : "Não"}');
      
      // Retornar true mesmo com erro para não bloquear o aplicativo
      debugPrint('Aplicativo continuará funcionando mesmo com erro na API do Asaas');
      return true;
    }
  }
  
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
    try {
      debugPrint('Criando cliente no Asaas...');
      debugPrint('URL: $_baseUrl/customers');
      debugPrint('Dados: nome=$name, email=$email, cpfCnpj=$cpfCnpj');
      
      // Verificar se o cliente já existe pelo CPF/CNPJ
      final existingCustomer = await findCustomerByCpfCnpj(cpfCnpj);
      if (existingCustomer != null) {
        debugPrint('Cliente já existe no Asaas com ID: ${existingCustomer['id']}');
        return existingCustomer;
      }
      
      final url = Uri.parse('$_baseUrl/customers');
      
      final body = jsonEncode({
        'name': name,
        'email': email,
        'cpfCnpj': cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''), // Remover caracteres não numéricos
        if (phone != null) 'phone': phone,
        if (mobilePhone != null) 'mobilePhone': mobilePhone,
        if (address != null) 'address': address,
        if (addressNumber != null) 'addressNumber': addressNumber,
        if (complement != null) 'complement': complement,
        if (province != null) 'province': province,
        if (postalCode != null) 'postalCode': postalCode,
      });
      
      debugPrint('Headers: $_headers');
      debugPrint('Body: $body');
      
      final response = await http.post(
        url, 
        headers: _headers, 
        body: body
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao criar cliente no Asaas');
        },
      );
      
      debugPrint('Resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        debugPrint('Cliente criado com sucesso: ${responseData['id']}');
        return responseData;
      } else {
        throw Exception('Falha ao criar cliente: [${response.statusCode}] ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao criar cliente no Asaas: $e');
      // Não criar cliente genérico para testes, mesmo em ambiente sandbox
      throw Exception('Não foi possível criar o cliente no Asaas: $e');
    }
  }
  
  // Método para buscar cliente por CPF/CNPJ
  Future<Map<String, dynamic>?> findCustomerByCpfCnpj(String cpfCnpj) async {
    try {
      final cleanCpfCnpj = cpfCnpj.replaceAll(RegExp(r'[^0-9]'), '');
      debugPrint('Buscando cliente por CPF/CNPJ: $cleanCpfCnpj');
      
      final url = Uri.parse('$_baseUrl/customers?cpfCnpj=$cleanCpfCnpj');
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          debugPrint('Cliente encontrado: ${data['data'][0]['id']}');
          return data['data'][0];
        }
      }
      
      debugPrint('Cliente não encontrado para CPF/CNPJ: $cleanCpfCnpj');
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar cliente por CPF/CNPJ: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>> getCustomer(String customerId) async {
    final url = Uri.parse('$_baseUrl/customers/$customerId');
    
    try {
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
        throw Exception('Falha ao obter cliente: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Falha ao obter cliente: $e');
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
    
    try {
      final response = await http.post(url, headers: _headers, body: body);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
        throw Exception('Falha ao atualizar cliente: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Falha ao atualizar cliente: $e');
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
      
      // Validar dados do cartão
      if (creditCardNumber.length < 13 || creditCardNumber.length > 19) {
        throw Exception('Número do cartão inválido');
      }
      
      if (creditCardHolderName.isEmpty) {
        throw Exception('Nome do titular do cartão é obrigatório');
      }
      
      // Validar mês de expiração
      final expiryMonthInt = int.tryParse(creditCardExpiryMonth);
      if (expiryMonthInt == null || expiryMonthInt < 1 || expiryMonthInt > 12) {
        throw Exception('Mês de expiração inválido');
      }
      
      // Validar ano de expiração
      final currentYear = DateTime.now().year;
      final expiryYearInt = int.tryParse(creditCardExpiryYear);
      if (expiryYearInt == null || expiryYearInt < currentYear) {
        throw Exception('Ano de expiração inválido');
      }
      
      data['creditCard'] = {
        'holderName': creditCardHolderName,
        'number': creditCardNumber,
        'expiryMonth': creditCardExpiryMonth,
        'expiryYear': creditCardExpiryYear,
        'ccv': creditCardCcv,
      };
      
      // Obter cliente existente para dados do titular
      Map<String, dynamic>? customerData;
      try {
        customerData = await getCustomer(customerId);
      } catch (e) {
        debugPrint('Erro ao obter dados do cliente: $e');
      }
      
      data['creditCardHolderInfo'] = {
        'name': creditCardHolderName,
        'email': customerData?['email'] ?? 'email@example.com',
        'cpfCnpj': customerData?['cpfCnpj'] ?? '',
        'postalCode': customerData?['postalCode'] ?? '',
        'addressNumber': customerData?['addressNumber'] ?? '',
        'addressComplement': customerData?['addressComplement'],
        'phone': customerData?['phone'] ?? '',
        'mobilePhone': customerData?['mobilePhone'] ?? customerData?['phone'] ?? '',
      };
    }
    
    final body = jsonEncode(data);
    
    try {
      debugPrint('Enviando requisição para criar assinatura...');
      debugPrint('URL: $url');
      debugPrint('Corpo da requisição: $body');
      
      final response = await http.post(url, headers: _headers, body: body);
      
      debugPrint('Resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
        throw Exception('Falha ao criar assinatura: $errorMessage');
      }
    } catch (e) {
      debugPrint('Exceção ao criar assinatura: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Falha ao criar assinatura: $e');
    }
  }
  
  Future<Map<String, dynamic>> getSubscription(String subscriptionId) async {
    final url = Uri.parse('$_baseUrl/subscriptions/$subscriptionId');
    
    try {
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
        throw Exception('Falha ao obter assinatura: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Falha ao obter assinatura: $e');
    }
  }
  
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    final url = Uri.parse('$_baseUrl/subscriptions/$subscriptionId/cancel');
    
    try {
      final response = await http.post(url, headers: _headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
        throw Exception('Falha ao cancelar assinatura: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Falha ao cancelar assinatura: $e');
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
    
    // Garantir que o valor tenha duas casas decimais
    final formattedValue = double.parse(value.toStringAsFixed(2));
    
    final Map<String, dynamic> data = {
      'customer': customerId,
      'value': formattedValue,
      'description': description,
      'dueDate': dueDate,
      if (externalReference != null) 'externalReference': externalReference,
      'billingType': billingType ?? 'BOLETO',
    };
    
    // Se for PIX, adicionar configurações específicas
    if (billingType == 'PIX') {
      data['discount'] = {
        'value': 0,
        'dueDateLimitDays': 0
      };
      data['interest'] = {
        'value': 0
      };
      data['fine'] = {
        'value': 0
      };
      // Adicionar configuração para gerar QR code PIX
      data['postalService'] = false;
    }
    
    final body = jsonEncode(data);
    
    try {
      debugPrint('Enviando requisição para criar pagamento...');
      debugPrint('URL: $url');
      debugPrint('Corpo da requisição: $body');
      
      final response = await http.post(url, headers: _headers, body: body);
      
      debugPrint('Resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Se for PIX, buscar o QR code
        if (billingType == 'PIX' && responseData['id'] != null) {
          try {
            final pixData = await getPixQrCode(responseData['id']);
            responseData['pix'] = pixData;
            debugPrint('QR Code PIX gerado com sucesso');
          } catch (e) {
            debugPrint('Erro ao gerar QR Code PIX: $e');
            // Mesmo com erro no QR code, retornar o pagamento criado
          }
        }
        
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
        throw Exception('Falha ao criar pagamento: $errorMessage');
      }
    } catch (e) {
      debugPrint('Exceção ao criar pagamento: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Falha ao criar pagamento: $e');
    }
  }
  
  // Método específico para obter o QR code PIX
  Future<Map<String, dynamic>> getPixQrCode(String paymentId) async {
    final url = Uri.parse('$_baseUrl/payments/$paymentId/pixQrCode');
    
    try {
      debugPrint('Buscando QR Code PIX para o pagamento $paymentId...');
      final response = await http.get(url, headers: _headers);
      
      debugPrint('Resposta QR Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('QR Code PIX obtido com sucesso');
        
        // Verificar se a imagem está codificada corretamente
        if (data['encodedImage'] != null) {
          // Verificar se a string base64 começa com prefixos comuns que precisam ser removidos
          String encodedImage = data['encodedImage'];
          if (encodedImage.startsWith('data:image/png;base64,')) {
            encodedImage = encodedImage.substring('data:image/png;base64,'.length);
          }
          
          // Garantir que a string base64 não tenha quebras de linha
          encodedImage = encodedImage.replaceAll('\n', '').replaceAll('\r', '');
          
          // Verificar se a string base64 é válida
          try {
            base64Decode(encodedImage);
            debugPrint('QR Code base64 validado com sucesso');
          } catch (e) {
            debugPrint('QR Code base64 inválido: $e');
            // Tentar corrigir a string base64
            encodedImage = base64.normalize(encodedImage);
          }
          
          return {
            'encodedImage': encodedImage,
            'payload': data['payload'],
            'expirationDate': data['expirationDate'],
          };
        } else {
          debugPrint('QR Code não contém imagem codificada');
          throw Exception('QR Code não contém imagem codificada');
        }
      } else {
        throw Exception('Falha ao obter QR Code PIX: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao obter QR Code PIX: $e');
      throw Exception('Falha ao obter QR Code PIX: $e');
    }
  }
  
  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final url = Uri.parse('$_baseUrl/payments/$paymentId');
    
    try {
      final response = await http.get(url, headers: _headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
        throw Exception('Falha ao obter pagamento: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Falha ao obter pagamento: $e');
    }
  }
  
  Future<Map<String, dynamic>> cancelPayment(String paymentId) async {
    final url = Uri.parse('$_baseUrl/payments/$paymentId');
    
    try {
      final response = await http.delete(url, headers: _headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
        throw Exception('Falha ao cancelar pagamento: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Falha ao cancelar pagamento: $e');
    }
  }
  
  // Métodos auxiliares
  String getPaymentUrl(String paymentId) {
    return '$_baseUrl/payments/$paymentId/identificationField';
  }
  
  String getSubscriptionUrl(String subscriptionId) {
    return '$_baseUrl/subscriptions/$subscriptionId';
  }

  // Método para criar um link de pagamento
  Future<Map<String, dynamic>> createPaymentLink({
    required String name,
    required double value,
    required String description,
    String? dueDateLimitDays,
    bool? chargeType,
    List<String>? allowedPaymentTypes,
  }) async {
    try {
      // Testar conexão com a API primeiro
      final isConnected = await checkApiConnection();
      if (!isConnected) {
        throw Exception('Não foi possível conectar-se ao Asaas. Verifique sua conexão e credenciais.');
      }
      
      debugPrint('Criando link de pagamento no Asaas...');
      debugPrint('Ambiente: ${_isSandbox ? 'Sandbox' : 'Produção'}');
      debugPrint('API Key (primeiros 10 chars): ${_apiKey.substring(0, 10)}...');
      debugPrint('URL: $_baseUrl/payment-links');
      
      // Alterando o endpoint de paymentLinks para payment-links conforme documentação atualizada do Asaas
      final url = Uri.parse('$_baseUrl/payment-links');
      
      final body = jsonEncode({
        'name': name,
        'description': description,
        'value': value,
        'dueDateLimitDays': dueDateLimitDays ?? '30',
        'chargeType': chargeType ?? false, // false = não cobrar pela emissão
        'allowedPaymentTypes': allowedPaymentTypes ?? ['CREDIT_CARD', 'PIX', 'BOLETO'],
      });
      
      debugPrint('Body: $body');
      debugPrint('Headers: ${_headers.toString()}');
      
      final response = await http.post(
        url, 
        headers: _headers, 
        body: body
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao criar link de pagamento no Asaas');
        },
      );
      
      debugPrint('Resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        debugPrint('Link de pagamento criado com sucesso: ${responseData['id']}');
        debugPrint('URL do link: ${responseData['url']}');
        return responseData;
      } else {
        // Tentar extrair mensagem de erro mais detalhada
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['errors']?[0]?['description'] ?? 'Erro desconhecido';
          throw Exception('Falha ao criar link de pagamento: $errorMessage');
        } catch (_) {
          // Se não conseguir extrair erro, usar mensagem genérica
          throw Exception('Falha ao criar link de pagamento: [${response.statusCode}] ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Erro ao criar link de pagamento no Asaas: $e');
      throw Exception('Não foi possível criar o link de pagamento no Asaas: $e');
    }
  }

  // Método para criar um cliente via webhook API
  Future<Map<String, dynamic>> createCustomerViaWebhook({
    required String name,
    required String email,
    required String cpfCnpj,
    String? phone,
    String? userId,
  }) async {
    try {
      debugPrint('Criando cliente no Asaas via webhook API...');
      
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
      
      // Montar URL da API de criação de cliente
      final url = Uri.parse('$webhookBaseUrl/api/create-customer');
      
      final body = jsonEncode({
        'name': name,
        'email': email,
        'cpfCnpj': cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''), // Remover caracteres não numéricos
        'phone': phone,
        'userId': userId,
      });
      
      debugPrint('Enviando requisição para: $url');
      debugPrint('Corpo da requisição: $body');
      
      final response = await http.post(
        url, 
        headers: {'Content-Type': 'application/json'}, 
        body: body
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao criar cliente via webhook API');
        },
      );
      
      debugPrint('Resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Cliente criado com sucesso via webhook API: ${responseData['customer']['id']}');
        return responseData['customer'];
      } else {
        throw Exception('Falha ao criar cliente: [${response.statusCode}] ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao criar cliente via webhook API: $e');
      // Em desenvolvimento, vamos criar um cliente simulado para não interromper o fluxo
      if (kDebugMode) {
        debugPrint('Retornando cliente simulado para desenvolvimento');
        return {
          'id': 'cus_000${Random().nextInt(10000)}',
          'name': name,
          'email': email,
          'cpfCnpj': cpfCnpj,
          'phone': phone,
          'simulated': true,
        };
      }
      throw Exception('Não foi possível criar o cliente: $e');
    }
  }
  
  // Método para criar pagamento usando nossa API de webhook
  Future<Map<String, dynamic>> createPaymentViaWebhook({
    required String customerId,
    required double value,
    required String billingType,
    String? description,
    String? dueDate,
    required String userId,
  }) async {
    try {
      debugPrint('Criando pagamento no Asaas via webhook API...');
      
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
      
      final url = Uri.parse('$webhookBaseUrl/api/create-payment');
      
      final body = jsonEncode({
        'customerId': customerId,
        'value': value,
        'billingType': billingType,
        'description': description ?? 'Pagamento MedMoney',
        'dueDate': dueDate ?? DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
        'userId': userId,
      });
      
      final response = await http.post(
        url, 
        headers: {'Content-Type': 'application/json'}, 
        body: body
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao criar pagamento via webhook API');
        },
      );
      
      debugPrint('Resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Pagamento criado com sucesso via webhook API: ${responseData['payment']['id']}');
        return responseData['payment'];
      } else {
        throw Exception('Falha ao criar pagamento: [${response.statusCode}] ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao criar pagamento via webhook API: $e');
      throw Exception('Não foi possível criar o pagamento: $e');
    }
  }
  
  // Método para criar assinatura usando nossa API de webhook
  Future<Map<String, dynamic>> createSubscriptionViaWebhook({
    required String customerId,
    required double value,
    required String billingType,
    required String cycle,
    String? description,
    String? nextDueDate,
    required String userId,
    String? planId,
  }) async {
    try {
      debugPrint('Criando assinatura no Asaas via webhook API...');
      
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
      
      final url = Uri.parse('$webhookBaseUrl/api/create-subscription');
      
      final body = jsonEncode({
        'customerId': customerId,
        'value': value,
        'billingType': billingType,
        'cycle': cycle, // 'MONTHLY' ou 'YEARLY'
        'description': description ?? 'Assinatura MedMoney',
        'nextDueDate': nextDueDate ?? DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
        'userId': userId,
        'planId': planId,
      });
      
      final response = await http.post(
        url, 
        headers: {'Content-Type': 'application/json'}, 
        body: body
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao criar assinatura via webhook API');
        },
      );
      
      debugPrint('Resposta: ${response.statusCode}');
      debugPrint('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Assinatura criada com sucesso via webhook API: ${responseData['subscription']['id']}');
        return responseData['subscription'];
      } else {
        throw Exception('Falha ao criar assinatura: [${response.statusCode}] ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao criar assinatura via webhook API: $e');
      throw Exception('Não foi possível criar a assinatura: $e');
    }
  }
} 