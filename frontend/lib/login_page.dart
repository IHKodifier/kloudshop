import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/google_logo.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleEmailSignIn() {
    if (!_formKey.currentState!.validate()) return;

    // For demo purposes, allow any sign in but show dialog that Google Sign In is preferred
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Production accounts use Google AuthGate. Please continue with Google Login.',
            ),
            backgroundColor: AppTheme.brandTeal500,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        width: isDesktop ? 1100 : (size.width - 48),
        height: isDesktop ? 680 : (size.height - MediaQuery.of(context).viewInsets.bottom - 48),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Pane - The login form
                    Expanded(
                      flex: isDesktop ? 10 : 12,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 24,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // App Brand Logo
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandEmerald500.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Image.asset(
                                          'assets/logo3d.png',
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              LucideIcons.store,
                                              size: 28,
                                              color: AppTheme.brandEmerald500,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'KloudShop',
                                        style: GoogleFonts.outfit(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : AppTheme.brandTeal900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 48),

                                  Text(
                                    'Welcome Back',
                                    style: GoogleFonts.outfit(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Access your commerce operating system.',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 36),

                                  // Email Input
                                  Text(
                                    'Email Address',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    enabled: !_isLoading,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      hintText: 'name@company.com',
                                      prefixIcon: const Icon(LucideIcons.mail, size: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Password Input
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Password',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Password reset link sent to your registered email.',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: AppTheme.brandEmerald500,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    enabled: !_isLoading,
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      prefixIcon: const Icon(LucideIcons.lock, size: 16),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? LucideIcons.eyeOff
                                              : LucideIcons.eye,
                                          size: 16,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    validator: (value) => (value == null || value.isEmpty)
                                        ? 'Password is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 28),

                                  // Sign In Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: HoverScale(
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleEmailSignIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                          foregroundColor: isDark
                                              ? const Color(0xFF0F172A)
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                'Sign In',
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Divider
                                  Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'Or alternatively use',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white30
                                                : Colors.black26,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider()),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Google Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: OutlinedButton(
                                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(color: theme.dividerColor),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const GoogleLogo(size: 18),
                                          const SizedBox(width: 12),
                                          Text(
                                            ' Login with Google',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 48),

                                  // Footer links
                                  Center(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          "Don't have an account?",
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.hintColor,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Contacting sales...'),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            "Contact sales.",
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: AppTheme.brandEmerald500,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right Pane - Quote & Stats Panel (Desktop only)
                    if (isDesktop)
                      Expanded(
                        flex: 10,
                        child: Container(
                          padding: const EdgeInsets.all(60),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: const AssetImage('assets/login_datacenter.png'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                AppTheme.brandTeal900.withOpacity(0.32),
                                BlendMode.srcOver,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.quote,
                                size: 48,
                                color: AppTheme.brandEmerald500,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4.0,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 44),
                              TypewriterText(
                                text:
                                    '"KloudShop didn\'t just replace our tech stack—it unified our global growth strategy."',
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 2),
                                      blurRadius: 8.0,
                                      color: Colors.black,
                                    ),
                                    Shadow(
                                      offset: const Offset(0, 4),
                                      blurRadius: 16.0,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                                duration: const Duration(milliseconds: 3000),
                                startDelay: const Duration(milliseconds: 800),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Sarah Chen',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1.5),
                                      blurRadius: 4.0,
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'CTO at Aether Apparel',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1.5),
                                      blurRadius: 4.0,
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 64),

                              // Stats Badges
                              Row(
                                children: [
                                  _buildStatWidget('99.99%', 'Global Uptime'),
                                  const SizedBox(width: 48),
                                  _buildStatWidget('10X', 'Faster Deployment'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                // Dialog Close Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: HoverScale(
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: isDesktop
                              ? Colors.white.withOpacity(0.8)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatWidget(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                blurRadius: 4.0,
                color: Colors.black.withOpacity(0.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: const Offset(0, 1.5),
                blurRadius: 2.0,
                color: Colors.black.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final Duration startDelay;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 3000),
    this.startDelay = const Duration(milliseconds: 800),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _visibleText = "";
  int _currentIndex = 0;
  Timer? _typingTimer;
  Timer? _startTimer;
  bool _showCursor = true;
  Timer? _cursorTimer;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationStarted) {
      _animationStarted = true;
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        void listener(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            _startTyping();
            route.animation!.removeStatusListener(listener);
          }
        }
        if (route.animation!.isCompleted) {
          _startTyping();
        } else {
          route.animation!.addStatusListener(listener);
        }
      } else {
        _startTyping();
      }
    }
  }

  void _startTyping() {
    _startTimer = Timer(widget.startDelay, () {
      if (!mounted) return;
      final totalChars = widget.text.length;
      if (totalChars == 0) return;
      
      final charDelay = Duration(
        microseconds: (widget.duration.inMicroseconds / totalChars).round(),
      );

      _typingTimer = Timer.periodic(charDelay, (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_currentIndex < widget.text.length) {
          setState(() {
            _currentIndex++;
            _visibleText = widget.text.substring(0, _currentIndex);
          });
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showCursorSymbol = _showCursor && (_currentIndex <= widget.text.length);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: _visibleText),
          TextSpan(
            text: showCursorSymbol ? ' |' : '  ',
            style: widget.style.copyWith(
              color: AppTheme.brandEmerald500,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
      style: widget.style,
    );
  }
}
