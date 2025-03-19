import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';

class AppHeader extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onRegisterPressed;
  final VoidCallback? onLogoutPressed;
  final VoidCallback? onDashboardPressed;
  final bool showLogo;
  final bool isTransparent;
  final bool showBackButton;
  final bool isHomePage;

  const AppHeader({
    Key? key,
    this.isLoggedIn = false,
    this.onLoginPressed,
    this.onRegisterPressed,
    this.onLogoutPressed,
    this.onDashboardPressed,
    this.showLogo = true,
    this.isTransparent = false,
    this.showBackButton = false,
    this.isHomePage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isTransparent ? Colors.transparent : AppTheme.backgroundColor,
        boxShadow: isTransparent
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppTheme.textPrimaryColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              if (showLogo)
                InkWell(
                  onTap: () => Navigator.pushReplacementNamed(context, '/'),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: Responsive.isMobile(context) ? 60 : 80,
                    fit: BoxFit.contain,
                  ),
                ),
              if (!Responsive.isMobile(context)) ...[
                const SizedBox(width: 48),
                _buildNavMenu(context),
              ],
            ],
          ),
          Row(
            children: [
              if (!Responsive.isMobile(context))
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Começar'),
              ),
              if (Responsive.isMobile(context))
                IconButton(
                  icon: const Icon(Icons.menu, size: 28),
                  onPressed: () {
                    _showMobileMenu(context);
                  },
                  color: AppTheme.textPrimaryColor,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavMenu(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNavItem(context, 'Como Funciona', '#como-funciona'),
        _buildNavItem(context, 'Benefícios', '#beneficios'),
        _buildNavItem(context, 'Planos', '#planos'),
        _buildNavItem(context, 'Contato', '#contato'),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () {
          if (route.startsWith('#')) {
            // Se é uma âncora, navegar para a home com a seção
            Navigator.of(context).pushReplacementNamed('/', arguments: {
              'section': route,
            });
          } else {
            // Navegar para uma rota normal
            Navigator.of(context).pushNamed(route);
          }
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMobileMenuItem(context, 'Início', Icons.home, () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              }),
              _buildMobileMenuItem(context, 'Como Funciona', Icons.help_outline, () {
                Navigator.pop(context);
                _navigateToSection(context, '#como-funciona');
              }),
              _buildMobileMenuItem(context, 'Benefícios', Icons.star_outline, () {
                Navigator.pop(context);
                _navigateToSection(context, '#beneficios');
              }),
              _buildMobileMenuItem(context, 'Planos', Icons.monetization_on_outlined, () {
                Navigator.pop(context);
                _navigateToSection(context, '#planos');
              }),
              _buildMobileMenuItem(context, 'Contato', Icons.contact_support_outlined, () {
                Navigator.pop(context);
                _navigateToSection(context, '#contato');
              }),
              const Divider(color: Color(0xFF2A2A5F)),
              if (isLoggedIn) ...[
                _buildMobileMenuItem(context, 'Dashboard', Icons.dashboard, () {
                  Navigator.pop(context);
                  if (onDashboardPressed != null) onDashboardPressed!();
                  else Navigator.pushReplacementNamed(context, '/dashboard');
                }),
                _buildMobileMenuItem(context, 'Sair', Icons.logout, () {
                  Navigator.pop(context);
                  if (onLogoutPressed != null) onLogoutPressed!();
                }),
              ] else ...[
                _buildMobileMenuItem(context, 'Entrar', Icons.login, () {
                  Navigator.pop(context);
                  if (onLoginPressed != null) onLoginPressed!();
                  else Navigator.pushNamed(context, '/login');
                }),
                _buildMobileMenuItem(context, 'Criar Conta', Icons.person_add, () {
                  Navigator.pop(context);
                  if (onRegisterPressed != null) onRegisterPressed!();
                  else Navigator.pushNamed(context, '/register');
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _navigateToSection(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed('/', arguments: {
      'section': route,
    });
  }
} 