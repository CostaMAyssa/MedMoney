import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

class PixCopyPaste extends StatelessWidget {
  final Map<String, dynamic> pixInfo;

  const PixCopyPaste({
    Key? key,
    required this.pixInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pixInfo['copyPaste'] != null && pixInfo['copyPaste'].length > 30
                          ? '${pixInfo['copyPaste'].substring(0, 30)}...'
                          : pixInfo['copyPaste'] ?? 'Código não disponível',
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
              const SizedBox(height: 8),
              Text(
                'Este código pode ser usado em qualquer banco que aceite PIX',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
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
} 