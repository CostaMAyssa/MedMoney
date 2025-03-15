import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' show min;
import '../utils/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/custom_button.dart';
import '../widgets/responsive_container.dart';
import '../utils/routes.dart';

class PixPaymentPage extends StatelessWidget {
  final Map<String, dynamic> pixInfo;
  final String planName;
  final String planType;
  
  const PixPaymentPage({
    Key? key,
    required this.pixInfo,
    required this.planName,
    required this.planType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho
            AppHeader(),
            
            // Conteúdo principal
            ResponsiveContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 64,
              ),
              child: Column(
                children: [
                  Text(
                    'Pagamento via PIX',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Escaneie o QR code ou copie o código PIX para realizar o pagamento',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Card do PIX
                  Card(
                    elevation: 4,
                    color: Color(0xFF1A1A4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Resumo da compra
                          Text(
                            'Plano ${planName} (${planType == 'annual' ? 'Anual' : 'Mensal'})',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // QR Code
                          _buildQrCode(context),
                          const SizedBox(height: 32),
                          
                          // Código PIX
                          Text(
                            'Código PIX Copia e Cola',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A5F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    pixInfo['copyPaste'] ?? 'Código não disponível',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimaryColor,
                                      fontFamily: 'Monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.copy,
                                    color: AppTheme.primaryColor,
                                  ),
                                  onPressed: () {
                                    _copyPixCode(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Instruções
                          Text(
                            'Instruções',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInstructionItem(
                            '1',
                            'Abra o aplicativo do seu banco',
                          ),
                          const SizedBox(height: 8),
                          _buildInstructionItem(
                            '2',
                            'Escolha a opção de pagamento via PIX',
                          ),
                          const SizedBox(height: 8),
                          _buildInstructionItem(
                            '3',
                            'Escaneie o QR code ou cole o código',
                          ),
                          const SizedBox(height: 8),
                          _buildInstructionItem(
                            '4',
                            'Confirme o pagamento',
                          ),
                          const SizedBox(height: 32),
                          
                          // Data de expiração
                          if (pixInfo['expirationDate'] != null)
                            Text(
                              'Este PIX expira em: ${pixInfo['expirationDate']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          const SizedBox(height: 32),
                          
                          // Botão para voltar ao dashboard
                          CustomButton(
                            text: 'Voltar para o Dashboard',
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Rodapé
            AppFooter(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQrCode(BuildContext context) {
    try {
      if (pixInfo['qrCode'] != null || pixInfo['encodedImage'] != null) {
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
          child: Image.memory(
            base64Decode(qrCodeBase64),
            width: 218,
            height: 218,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Erro ao carregar QR code: $error');
              return _buildQrCodePlaceholder('Não foi possível carregar o QR code');
            },
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
  
  void _copyPixCode(BuildContext context) {
    try {
      if (pixInfo['copyPaste'] != null) {
        Clipboard.setData(ClipboardData(text: pixInfo['copyPaste']));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código PIX copiado para a área de transferência'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código PIX não disponível'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao copiar código PIX: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao copiar código PIX: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  Widget _buildInstructionItem(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

// Função para decodificar base64
Uint8List base64Decode(String source) {
  try {
    return Uint8List.fromList(
      const Base64Decoder().convert(source.replaceAll('\n', '')),
    );
  } catch (e) {
    debugPrint('Erro ao decodificar base64: $e');
    throw Exception('Erro ao decodificar QR code: $e');
  }
} 