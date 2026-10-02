import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/result.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final ApiService _apiService;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    final isLoggedIn = await _apiService.initAuth();
    if (isLoggedIn) {
      if (!mounted) return;
      context.go('/');
    }
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiService.loginWithOidc();
    
    if (mounted) {
      switch (result) {
        case Success():
          context.go('/');
        case Failure(exception: final e):
          setState(() {
            _isLoading = false;
            _errorMessage = 'Login failed: $e';
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white, // surface-container-lowest
      body: SelectionArea(
        child: Center(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEEEE), // surface-container
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_boat,
                      size: 32,
                      color: Color(0xFF1D3261), // oxford-blue
                    ),
                  ),
                ),
                Text(
                  'BRUG TOT BRUG',
                  style: textTheme.headlineLarge?.copyWith(
                    color: const Color(0xFF1D3261),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in om je prestaties te bekijken',
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF717C96), // cadet-grey
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (_errorMessage != null) ...[
                  Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _login,
                    icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const SizedBox.shrink(),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Inloggen', style: textTheme.labelMedium?.copyWith(color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.login, size: 20, color: Colors.white),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D3261), // oxford-blue
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.play_circle_outline, size: 18, color: Color(0xFF27AE60)),
                    label: const Text('Direct doorgaan (Demo / Simulatie)', style: TextStyle(color: Color(0xFF27AE60), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF27AE60)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
       ),
      ),
    );
  }
}
