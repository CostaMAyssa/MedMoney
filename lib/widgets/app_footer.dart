import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF050530), // Um pouco mais escuro que o fundo principal
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 64,
              runSpacing: 32,
              children: [
                _buildFooterSection(
                  context,
                  title: 'MedMoney',
                  children: [
                    _buildFooterText(
                      'Simplifique a gestão financeira dos seus plantões e consultas.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSocialIcon(Icons.public, () {}),
                        _buildSocialIcon(Icons.photo_camera, () {}),
                        _buildSocialIcon(Icons.business_center, () {}),
                      ],
                    ),
                  ],
                ),
                _buildFooterSection(
                  context,
                  title: 'Links Úteis',
                  children: [
                    _buildFooterLink('Como Funciona', () {
                      Navigator.pushReplacementNamed(context, '/', arguments: '#como-funciona');
                    }),
                    _buildFooterLink('Planos', () {
                      Navigator.pushReplacementNamed(context, '/', arguments: '#planos');
                    }),
                    _buildFooterLink('Benefícios', () {
                      Navigator.pushReplacementNamed(context, '/', arguments: '#beneficios');
                    }),
                    _buildFooterLink('Blog', () {}),
                  ],
                ),
                _buildFooterSection(
                  context,
                  title: 'Suporte',
                  children: [
                    _buildFooterLink('Central de Ajuda', () {}),
                    _buildFooterLink('Contato', () {
                      Navigator.pushReplacementNamed(context, '/', arguments: '#contato');
                    }),
                    _buildFooterLink('Política de Privacidade', () {}),
                    _buildFooterLink('Termos de Uso', () {}),
                  ],
                ),
                _buildFooterSection(
                  context,
                  title: 'Contato',
                  children: [
                    _buildFooterText('contato@medmoney.com.br'),
                    _buildFooterText('(11) 99999-9999'),
                    _buildFooterText('São Paulo, SP'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFF2A2A5F),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              '© ${DateTime.now().year} MedMoney. Todos os direitos reservados.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return SizedBox(
      width: Responsive.isMobile(context) ? double.infinity : 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textSecondaryColor,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
} 