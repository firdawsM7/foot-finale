import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/api_error_utils.dart';
import '../../widgets/theme_mode_toggle.dart';

class ActivateAccountScreen extends StatefulWidget {
  const ActivateAccountScreen({super.key});

  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _activateAccount() async {
    if (_formKey.currentState!.validate()) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (arguments == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Données d\'activation manquantes'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final email = arguments['email'] as String;
      final activationToken = arguments['activationToken'] as String;

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.activateAccount(
        email: email,
        password: _passwordController.text,
        activationToken: activationToken,
      );

      if (success && mounted) {
        // Show success message
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Compte activé!'),
              ],
            ),
            content: const Text(
              'Votre compte a été activé avec succès. Vous pouvez maintenant vous connecter.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pushReplacementNamed('/home'); // Go to home
                },
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                    color: AppTheme.masYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiErrorUtils.sanitizeForDisplay(
                authProvider.error,
                fallback: ApiErrorUtils.generic,
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
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = arguments?['email'] as String? ?? 'utilisateur';
    
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
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Activation Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.masYellow.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.how_to_reg,
                      size: 64,
                      color: AppTheme.masYellow,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'ACTIVER VOTRE COMPTE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.masYellow,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Subtitle with email
                  Text(
                    'Bienvenue! Veuillez créer votre mot de passe pour activer votre compte.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.masYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.masYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Activation Form
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: AppTheme.containerDecoration(
                      context,
                      borderRadius: 20,
                    ),
                    child: Column(
                      children: [
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
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
                              return 'Veuillez entrer un mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.masYellow),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: textColor.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez confirmer votre mot de passe';
                            }
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Activate Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _activateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.masYellow,
                              foregroundColor: AppTheme.masBlack,
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(
                                    color: AppTheme.masBlack,
                                    strokeWidth: 3,
                                  )
                                : const Text(
                                    'ACTIVER MON COMPTE',
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

                  // Back to Login Link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      '← Retour à la connexion',
                      style: TextStyle(
                        color: AppTheme.masYellow,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
