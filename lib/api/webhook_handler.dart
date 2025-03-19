import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../services/supabase_service.dart';

class WebhookHandler {
  final SupabaseService _supabaseService = SupabaseService();
  late final Router _router;

  WebhookHandler() {
    _router = Router()
      // Endpoint para receber webhooks do Asaas
      ..post('/api/webhook/asaas', _handleAsaasWebhook)
      // Endpoint de health check
      ..get('/api/health', _handleHealthCheck)
      // Endpoint para redirecionamento após pagamento
      ..get('/api/payment/success', _handlePaymentSuccess)
      ..get('/api/payment/failure', _handlePaymentFailure);
  }

  /// Inicia o servidor para receber webhooks
  Future<HttpServer> startServer(int port) async {
    // Criar uma pipeline com middlewares
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addHandler(_router);

    // Iniciar o servidor
    debugPrint('Iniciando servidor webhook na porta $port...');
    final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    
    debugPrint('Servidor webhook iniciado: ${server.address.address}:${server.port}');
    return server;
  }

  /// Middleware para permitir CORS
  Middleware _corsMiddleware() {
    return createMiddleware(
      responseHandler: (response) {
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Request-With',
          'Access-Control-Allow-Credentials': 'true',
        });
      },
      requestHandler: (request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Request-With',
            'Access-Control-Allow-Credentials': 'true',
          });
        }
        return null;
      },
    );
  }

  /// Handler para processar webhooks do Asaas
  Future<Response> _handleAsaasWebhook(Request request) async {
    try {
      // Verificar o content-type
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('Content-Type inválido: $contentType');
        return Response(400, body: 'Content-Type deve ser application/json');
      }

      // Ler o corpo da requisição
      final body = await request.readAsString();
      if (body.isEmpty) {
        debugPrint('Corpo da requisição vazio');
        return Response(400, body: 'Corpo da requisição não pode ser vazio');
      }

      // Decodificar o JSON
      Map<String, dynamic> webhookData;
      try {
        webhookData = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Erro ao decodificar JSON: $e');
        return Response(400, body: 'JSON inválido');
      }

      // Processar o webhook
      debugPrint('Recebido webhook do Asaas: ${webhookData.toString().substring(0, min(200, webhookData.toString().length))}...');
      
      // Processar o webhook de forma assíncrona para não bloquear a resposta
      _processWebhookAsync(webhookData);
      
      // Retornar resposta de sucesso imediatamente
      return Response.ok(jsonEncode({'status': 'received', 'message': 'Webhook recebido com sucesso'}),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      debugPrint('Erro ao processar webhook: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': 'Erro interno ao processar webhook: ${e.toString()}'}),
          headers: {'content-type': 'application/json'});
    }
  }

  /// Processa o webhook de forma assíncrona
  Future<void> _processWebhookAsync(Map<String, dynamic> webhookData) async {
    try {
      // Processar o webhook no SupabaseService
      final success = await _supabaseService.processAsaasWebhook(webhookData);
      debugPrint('Webhook processado ${success ? 'com sucesso' : 'com falha'}');
    } catch (e) {
      debugPrint('Erro ao processar webhook de forma assíncrona: $e');
    }
  }

  /// Handler para health check
  Response _handleHealthCheck(Request request) {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Handler para processar sucesso no pagamento
  Response _handlePaymentSuccess(Request request) {
    try {
      // Extrair parâmetros da query
      final params = request.url.queryParameters;
      final paymentId = params['payment_id'] ?? '';
      final externalReference = params['external_reference'] ?? '';
      
      debugPrint('Recebido retorno de pagamento com sucesso: paymentId=$paymentId, externalReference=$externalReference');
      
      // Criar uma página HTML com redirecionamento para a página de status
      final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pagamento Processado - MedMoney</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #0A0A3E;
      color: white;
      text-align: center;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      padding: 20px;
    }
    .success-container {
      background-color: #1A1A4F;
      border-radius: 16px;
      padding: 40px;
      box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
      max-width: 500px;
      width: 100%;
    }
    h1 {
      color: #48B7A2;
      margin-bottom: 20px;
    }
    p {
      font-size: 18px;
      line-height: 1.6;
      margin-bottom: 30px;
    }
    .loader {
      border: 4px solid #f3f3f3;
      border-top: 4px solid #48B7A2;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      animation: spin 2s linear infinite;
      margin: 20px auto;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    .redirect-text {
      color: #B9A6F5;
      font-size: 14px;
      margin-top: 20px;
    }
  </style>
  <script>
    // Redirecionar para a página de status após 3 segundos
    setTimeout(function() {
      window.location.href = "/subscription_status?payment_id=${paymentId}&external_reference=${externalReference}";
    }, 3000);
  </script>
</head>
<body>
  <div class="success-container">
    <h1>Pagamento Recebido!</h1>
    <p>Obrigado! Seu pagamento foi processado com sucesso.</p>
    <div class="loader"></div>
    <p class="redirect-text">Você será redirecionado para a página de status da sua assinatura em instantes...</p>
  </div>
</body>
</html>
      ''';
      
      return Response.ok(html, headers: {'content-type': 'text/html'});
    } catch (e) {
      debugPrint('Erro ao processar retorno de pagamento: $e');
      return Response.internalServerError(
          body: 'Erro ao processar retorno de pagamento',
          headers: {'content-type': 'text/plain'});
    }
  }
  
  /// Handler para processar falha no pagamento
  Response _handlePaymentFailure(Request request) {
    try {
      // Extrair parâmetros da query
      final params = request.url.queryParameters;
      final errorCode = params['error_code'] ?? '';
      final errorMessage = params['error_message'] ?? 'Erro desconhecido';
      
      debugPrint('Recebido retorno de falha no pagamento: code=$errorCode, message=$errorMessage');
      
      // Criar uma página HTML com redirecionamento para a página de pagamento
      final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pagamento Não Concluído - MedMoney</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #0A0A3E;
      color: white;
      text-align: center;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      padding: 20px;
    }
    .error-container {
      background-color: #1A1A4F;
      border-radius: 16px;
      padding: 40px;
      box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
      max-width: 500px;
      width: 100%;
    }
    h1 {
      color: #FF6B6B;
      margin-bottom: 20px;
    }
    p {
      font-size: 18px;
      line-height: 1.6;
      margin-bottom: 30px;
    }
    .error-message {
      background-color: rgba(255, 107, 107, 0.1);
      padding: 15px;
      border-radius: 8px;
      margin-bottom: 30px;
      font-size: 16px;
    }
    .redirect-text {
      color: #B9A6F5;
      font-size: 14px;
      margin-top: 20px;
    }
    .loader {
      border: 4px solid #f3f3f3;
      border-top: 4px solid #FF6B6B;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      animation: spin 2s linear infinite;
      margin: 20px auto;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
  <script>
    // Redirecionar para a página de pagamento após 5 segundos
    setTimeout(function() {
      window.location.href = "/payment_required";
    }, 5000);
  </script>
</head>
<body>
  <div class="error-container">
    <h1>Pagamento Não Concluído</h1>
    <p>Houve um problema ao processar seu pagamento:</p>
    <div class="error-message">${errorMessage}</div>
    <p>Você pode tentar novamente em alguns instantes.</p>
    <div class="loader"></div>
    <p class="redirect-text">Você será redirecionado automaticamente em instantes...</p>
  </div>
</body>
</html>
      ''';
      
      return Response.ok(html, headers: {'content-type': 'text/html'});
    } catch (e) {
      debugPrint('Erro ao processar retorno de falha no pagamento: $e');
      return Response.internalServerError(
          body: 'Erro ao processar retorno de falha no pagamento',
          headers: {'content-type': 'text/plain'});
    }
  }
}

// Função auxiliar para limitar tamanho
int min(int a, int b) => a < b ? a : b; 