import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kloudshop/services/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) {
        // Pop the login page to reveal the AuthGate's dashboard underneath
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.03) 
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.shieldCheck,
                          size: 48,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to access your merchant dashboard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Google Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.logIn, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Staff Only',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white30 : Colors.black26,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
