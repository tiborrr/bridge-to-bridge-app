import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Icon(Icons.directions_boat, color: Color(0xFF1D3261), size: 32),
                  const SizedBox(width: 16),
                  Text(
                    'MENU',
                    style: textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF1D3261),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFD9DADB)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.map_outlined,
                    title: 'Trajecten Beheren',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/trajectories');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: 'Mijn Profiel',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.group,
                    title: 'Mijn Team',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/team');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.history,
                    title: 'Historie',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/history');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.leaderboard_outlined,
                    title: 'Ranglijst',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/leaderboard');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFD9DADB)),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Uitloggen',
              onTap: () async {
                final apiService = context.read<ApiService>();
                await apiService.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      leading: Icon(icon, color: const Color(0xFF1D3261)),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: const Color(0xFF1D3261),
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
