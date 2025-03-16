import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/theme.dart';

class PixQrCode extends StatelessWidget {
  final Map<String, dynamic> pixInfo;

  const PixQrCode({
    Key? key,
    required this.pixInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      // Verificar se temos o código PIX copia e cola
      if (pixInfo['copyPaste'] != null && 
          pixInfo['copyPaste'].isNotEmpty && 
          pixInfo['copyPaste'] != 'Código PIX indisponível') {
        
        // Usar o código PIX copia e cola para gerar um QR code real
        final String pixCode = pixInfo['copyPaste'];
        
        return Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR Code gerado a partir do código PIX
              Expanded(
                child: QrImageView(
                  data: pixCode,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  errorStateBuilder: (context, error) {
                    debugPrint('Erro ao gerar QR code: $error');
                    return _buildQrCodePlaceholder('Não foi possível gerar o QR code');
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'QR Code PIX',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        );
      } 
      // Tentar usar o QR code fornecido pelo Asaas como fallback
      else if (pixInfo['qrCode'] != null || pixInfo['encodedImage'] != null) {
        // Usar a chave correta para o QR code
        final qrCodeBase64 = pixInfo['encodedImage'] ?? pixInfo['qrCode'];
        
        if (qrCodeBase64 == null || qrCodeBase64.isEmpty) {
          return _buildQrCodePlaceholder('QR Code temporariamente indisponível');
        }
        
        debugPrint('Renderizando QR code com base64 (primeiros 50 caracteres): ${qrCodeBase64.substring(0, qrCodeBase64.length > 50 ? 50 : qrCodeBase64.length)}...');
        
        return Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.memory(
                  base64Decode(qrCodeBase64),
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Erro ao carregar QR code: $error');
                    return _buildQrCodePlaceholder('Não foi possível carregar o QR code');
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'QR Code PIX (Asaas)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        );
      } else {
        return _buildQrCodePlaceholder('QR Code não disponível');
      }
    } catch (e) {
      debugPrint('Exceção ao renderizar QR code: $e');
      return _buildQrCodePlaceholder('Erro ao processar QR code');
    }
  }

  Widget _buildQrCodePlaceholder(String message) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone de PIX
          Icon(
            Icons.qr_code_2,
            color: AppTheme.primaryColor,
            size: 80,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              message,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use o código PIX abaixo',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Função para decodificar base64
Uint8List base64Decode(String source) {
  try {
    // Remover prefixos comuns de base64 de imagens
    String cleanSource = source;
    if (cleanSource.startsWith('data:image/png;base64,')) {
      cleanSource = cleanSource.substring('data:image/png;base64,'.length);
    } else if (cleanSource.startsWith('data:image/jpeg;base64,')) {
      cleanSource = cleanSource.substring('data:image/jpeg;base64,'.length);
    }
    
    // Remover quebras de linha e espaços
    cleanSource = cleanSource.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
    
    // Normalizar a string base64 se necessário
    if (cleanSource.length % 4 != 0) {
      debugPrint('Normalizando string base64 (comprimento original: ${cleanSource.length})');
      cleanSource = base64.normalize(cleanSource);
    }
    
    debugPrint('Decodificando base64 (comprimento: ${cleanSource.length})');
    return Uint8List.fromList(
      const Base64Decoder().convert(cleanSource),
    );
  } catch (e) {
    debugPrint('Erro ao decodificar base64: $e');
    throw Exception('Erro ao decodificar QR code: $e');
  }
} 