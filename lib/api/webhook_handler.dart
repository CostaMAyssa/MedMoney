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
      ..get('/api/health', _handleHealthCheck);
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
}

// Função auxiliar para limitar tamanho
int min(int a, int b) => a < b ? a : b; 