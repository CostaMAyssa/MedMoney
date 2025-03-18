import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/routes.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SupabaseService supabaseService = SupabaseService();
    
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            color: Theme.of(context).primaryColor,
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    image: const DecorationImage(
                      image: AssetImage('assets/images/logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<String?>(
                  future: supabaseService.getUserDisplayName(),
                  builder: (context, snapshot) {
                    final displayName = snapshot.data ?? 'Usuário MedMoney';
                    return Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: 'Meu Perfil',
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.credit_card,
            title: 'Minha Assinatura',
            onTap: () {
              Navigator.pushNamed(context, '/subscription_status');
            },
          ),
          const Spacer(),
          Divider(height: 1, color: Colors.grey.shade300),
          _buildDrawerItem(
            context,
            icon: Icons.exit_to_app,
            title: 'Sair',
            onTap: () async {
              await supabaseService.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
} 