import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../utils/routes.dart';
import '../widgets/custom_button.dart';

class PaymentRequiredPage extends StatelessWidget {
  const PaymentRequiredPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho
            const AppHeader(),
            
            // Conteúdo principal
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 64,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      // Ícone de aviso
                      Icon(
                        Icons.security,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 32),
                      
                      // Título
                      Text(
                        'Assinatura Necessária',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Mensagem
                      Text(
                        'Para acessar o dashboard e todas as funcionalidades do MedMoney, é necessário ter uma assinatura ativa.',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Detalhes
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Status de Assinatura: Inativo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Seu pagamento não foi confirmado ou sua assinatura expirou. Para continuar usando o MedMoney, por favor, escolha um plano e efetue o pagamento.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            
                            // Opções de assinatura
                            Text(
                              'Escolha um Plano',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPlanOption(
                              context,
                              title: 'Plano Essencial',
                              price: 'R\$ 15,90/mês',
                              features: [
                                'Bot no WhatsApp',
                                'Suporte 24/7',
                                'Até 50 lançamentos mensais',
                              ],
                              planName: 'Essencial',
                              planType: 'monthly',
                              planPrice: 15.90,
                              setupFee: 0.0,
                            ),
                            const SizedBox(height: 16),
                            _buildPlanOption(
                              context,
                              title: 'Plano Premium',
                              price: 'R\$ 24,90/mês',
                              features: [
                                'Bot no WhatsApp + Dashboard',
                                'Suporte 24/7',
                                'Lançamentos ilimitados',
                                'Relatórios avançados',
                              ],
                              planName: 'Premium',
                              planType: 'monthly',
                              planPrice: 24.90,
                              setupFee: 0.0,
                              isRecommended: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Voltar para a home
                      CustomButton(
                        text: 'Voltar para a Home',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.home);
                        },
                        type: ButtonType.secondary,
                        size: ButtonSize.medium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Rodapé
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOption(
    BuildContext context, {
    required String title,
    required String price,
    required List<String> features,
    required String planName,
    required String planType,
    required double planPrice,
    required double setupFee,
    bool isRecommended = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isRecommended ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Recomendado',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isRecommended ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 8),
                Text(
                  feature,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Assinar Agora',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.payment,
                  arguments: {
                    'planName': planName,
                    'planType': planType,
                    'planPrice': planPrice,
                    'setupFee': setupFee,
                    'totalPrice': planPrice + setupFee,
                  },
                );
              },
              type: isRecommended ? ButtonType.primary : ButtonType.secondary,
              size: ButtonSize.medium,
            ),
          ),
        ],
      ),
    );
  }
} 