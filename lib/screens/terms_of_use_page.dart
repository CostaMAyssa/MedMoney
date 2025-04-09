import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
        backgroundColor: const Color(0xFF1A1A4F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description,
              size: 80,
              color: Color(0xFF1A1A4F),
            ),
            const SizedBox(height: 24),
            const Text(
              'Termos de Uso da Plataforma',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ao utilizar a plataforma MedMoney, você concorda em cumprir e ficar vinculado aos nossos termos e condições.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Concordo com os Termos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _downloadTerms();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Baixar Termos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A4F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _downloadTerms() {
    // Obter a URL base do aplicativo
    final String baseUrl = html.window.location.origin;
    
    // Criar um elemento <a> para download
    final anchor = html.AnchorElement()
      ..href = '$baseUrl/assets/assets/pdf/termos_de_uso.pdf'
      ..target = '_blank'
      ..download = 'Termos_de_Uso_MedMoney.pdf';
    
    // Disparar o clique automaticamente
    anchor.click();
  }
} 