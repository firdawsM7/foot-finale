import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/api_error_utils.dart';
import '../../widgets/theme_mode_toggle.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Check if login was successful
      if (result is Map && result['success'] == true) {
        Navigator.pushReplacementNamed(context, '/home');
      } 
      // Check if account needs activation
      else if (result is Map && result['needsActivation'] == true) {
        Navigator.pushNamed(
          context,
          '/activate-account',
          arguments: {
            'email': result['email'],
            'activationToken': result['activationToken'],
          },
        );
      } 
      // Login failed
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorUtils.sanitizeForDisplay(
                authProvider.error,
                fallback: ApiErrorUtils.authFailed,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getGradient(context),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // MAS Logo
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white, // Keep logo background white for contrast
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.masYellow.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/mas_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
  
                        // Title
                        Text(
                          'MAS DE FÈS',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.masYellow,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: AppTheme.masYellow.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        Text(
                          'Depuis 1946',
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withOpacity(0.7),
                            letterSpacing: 2,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 48),
  
                        // Login Form
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: AppTheme.containerDecoration(context, borderRadius: 20),
                          child: Column(
                            children: [
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: textColor),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email, color: AppTheme.masYellow),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
  
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  prefixIcon: const Icon(Icons.lock, color: AppTheme.masYellow),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre mot de passe';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
  
                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Implement forgot password
                                  },
                                  child: const Text(
                                    'Mot de passe oublié ?',
                                    style: TextStyle(
                                      color: AppTheme.masYellow,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
  
                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _login,
                                  child: authProvider.isLoading
                                      ? const CircularProgressIndicator(
                                          color: AppTheme.masBlack,
                                          strokeWidth: 3,
                                        )
                                      : const Text(
                                          'SE CONNECTER',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
  
                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pas encore de compte ? ',
                              style: TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                'S\'inscrire',
                                style: TextStyle(
                                  color: AppTheme.masYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
  
                        // Footer
                        Text(
                          '© 2026 MAS de Fès - Tous droits réservés',
                          style: TextStyle(
                            color: textColor.withOpacity(0.4),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Theme Toggle Button (Moved to end ensuring it is on top)
              const Positioned(
                top: 8,
                right: 8,
                child: ThemeModeToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
