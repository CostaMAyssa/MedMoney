import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AcessoDashboardPage extends StatelessWidget {
  const AcessoDashboardPage({super.key});

  final String dashboardUrl = 'http://medmoney.me:8081';

  Future<void> _abrirDashboard() async {
    final Uri url = Uri.parse(dashboardUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Não foi possível abrir: $dashboardUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _abrirDashboard,
          child: const Text('Acessar MedMoney Dashboard'),
        ),
      ),
    );
  }
}
