import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/responsive.dart';
import '../../utils/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/responsive_container.dart';
import '../../utils/routes.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  // Função para abrir o link do dashboard React
  Future<void> _launchDashboard() async {
    final Uri url = Uri.parse('http://medmoney.me:8081');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Erro ao abrir URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho (mantido igual)
            AppHeader(
              onRegisterPressed: () {
                Navigator.pushNamed(context, AppRoutes.register);
              },
            ),
            
            // Conteúdo principal em estilo Hero, similar à home
            ResponsiveContainer(
              padding: const EdgeInsets.symmetric(vertical: 60.0),
              child: MediaQuery.of(context).size.width > 800
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildLeftContent(context),
                    ),
                    const SizedBox(width: 80),
                    Expanded(
                      flex: 5,
                      child: _buildRightContent(context),
                    ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildRightContent(context),
                    const SizedBox(height: 40),
                    _buildLeftContent(context),
                  ],
                ),
            ),
            
            // Rodapé
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftContent(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isMobile = MediaQuery.of(context).size.width <= 600;
    
    return Container(
      width: isDesktop ? double.infinity : MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 20),
      child: Column(
        crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          isMobile 
          ? Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 10),
                Text(
                  'Dashboard MedMoney',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: isDesktop ? 40 : 32,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 20),
                Text(
                  'Dashboard MedMoney',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: isDesktop ? 40 : 32,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          Text(
            'Seu aliado no controle financeiro',
            style: TextStyle(
              fontSize: isDesktop ? 28 : 24,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: 30),
          Container(
            width: isDesktop ? null : MediaQuery.of(context).size.width - 40,
            constraints: BoxConstraints(
              maxWidth: 600,
            ),
            child: Text(
              'Fui criado especialmente para profissionais da saúde como você, que buscam praticidade e clareza na hora de gerenciar suas finanças.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
                height: 1.5,
                fontSize: isDesktop ? 18 : 16,
              ),
              textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: isDesktop ? 550 : MediaQuery.of(context).size.width - 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureItem(
                  Icons.lightbulb_outline,
                  'Visualize receitas, despesas, saldo mensal e até gastos previstos com facilidade.',
                  isDesktop,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.bar_chart,
                  'Organize seus plantões, acompanhe metas e tome decisões com base em dados reais, não achismos.',
                  isDesktop,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.medical_services_outlined,
                  'Pode confiar: eu cuido dos números pra você cuidar dos seus pacientes. ',
                  isDesktop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightContent(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Container(
      width: isDesktop ? double.infinity : MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: isDesktop ? 40 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waving_hand,
                size: isDesktop ? 36 : 30,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Olá! Eu sou o Dashboard MedMoney',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Text(
            ' Pronto para começar?\n\nO acesso ao seu painel agora é feito dentro do novo sistema MedMoney. Clique no botão abaixo para fazer login com segurança e aproveitar todos os recursos do seu plano.',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _launchDashboard,
              icon: Icon(Icons.lock_open, size: 24),
              label: Text(
                'Acessar Painel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 36),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 22,
                color: Colors.orange[300],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'O login e a recuperação de senha agora são feitos diretamente no painel.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Não tem uma conta?',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  child: Text(
                    'Criar conta',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text, bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isDesktop ? 36 : 30,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}