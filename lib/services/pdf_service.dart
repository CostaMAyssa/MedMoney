import 'dart:io';
// Importação condicional para evitar erro em plataformas não-web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Importação condicional para dart:html
import 'web_helper.dart' if (dart.library.html) 'dart:html' as html;

class PdfService {
  /// Abre um arquivo PDF a partir dos assets
  /// 
  /// [assetPath] é o caminho do asset do PDF
  /// [fallbackUrl] é a URL de fallback caso o PDF não possa ser aberto
  static Future<bool> openPdfFromAsset({
    required String assetPath,
    required String fallbackUrl,
  }) async {
    try {
      if (kIsWeb) {
        try {
          // No Flutter Web, tentamos abrir usando a URL fornecida
          final Uri webUrl = Uri.parse(fallbackUrl);
          return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } catch (e) {
          // Se falhar, tentamos o método alternativo
          final Uri webUrl = Uri.parse(fallbackUrl);
          return await launchUrl(
            webUrl, 
            mode: LaunchMode.platformDefault,
            webOnlyWindowName: '_blank',
          );
        }
      } else {
        try {
          // Para dispositivos móveis, carregamos o arquivo e salvamos temporariamente
          final ByteData data = await rootBundle.load(assetPath);
          final Directory tempDir = await getTemporaryDirectory();
          final String tempPath = '${tempDir.path}/termos_de_uso.pdf';
          final File tempFile = File(tempPath);
          await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
          
          // Abre o arquivo temporário
          final Uri fileUri = Uri.file(tempPath);
          return await launchUrl(fileUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          // Se falhar, tentamos a URL de fallback
          final Uri webUrl = Uri.parse(fallbackUrl);
          return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      return false;
    }
  }
} 