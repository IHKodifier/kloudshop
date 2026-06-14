import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/semantic_text_form_field.dart';

class UnblockVerificationPage extends ConsumerStatefulWidget {
  const UnblockVerificationPage({super.key});

  @override
  ConsumerState<UnblockVerificationPage> createState() => _UnblockVerificationPageState();
}

class _UnblockVerificationPageState extends ConsumerState<UnblockVerificationPage> {
  bool _isVerifying = true;
  bool _success = false;
  String _errorMessage = '';
  String? _token;
  bool _isRequestingNewLink = false;
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Retrieve token from Uri base on startup (Web-friendly)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Uri.base.queryParameters['token'];
      if (token == null || token.isEmpty) {
        setState(() {
          _isVerifying = false;
          _success = false;
          _errorMessage = 'No unblock token was found in the link.';
        });
      } else {
        _token = token;
        _verifyToken(token);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken(String token) async {
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.verifyUnblock(token);
      
      setState(() {
        _isVerifying = false;
        _success = true;
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _success = false;
        _errorMessage = e.toString().contains('400') || e.toString().contains('expired')
            ? 'The unblock token is invalid or has expired (180s TTL limit).'
            : 'An unexpected error occurred during verification: $e';
      });
    }
  }

  Future<void> _requestNewUnblockLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRequestingNewLink = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final email = _emailController.text.trim();
      await apiService.requestUnblock(email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Link is valid for 180s.'),
            backgroundColor: AppTheme.brandEmerald500,
          ),
        );
        setState(() {
          _isRequestingNewLink = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('429')) {
          errorMsg = 'Maximum unblock requests exceeded for today. Try again in 24 hours.';
        } else if (errorMsg.contains('400')) {
          errorMsg = 'This account is not currently blocked.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request link: $errorMsg'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isRequestingNewLink = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildGlassCard(
              isDark: isDark,
              theme: theme,
              children: [
                if (_isVerifying)
                  _buildVerifyingState(theme)
                else if (_success)
                  _buildSuccessState(theme)
                else
                  _buildFailureState(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required bool isDark,
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.7)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.brandEmerald500.withOpacity(0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyingState(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppTheme.brandEmerald500,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Verifying Security Token',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please wait while we authorize your unblock request...',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.hintColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.brandEmerald500.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.shieldCheck,
            size: 48,
            color: AppTheme.brandEmerald500,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Account Unlocked!',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.brandEmerald500,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your merchant credentials have been successfully unlocked and verified. You may now return to your login screen and sign in.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: HoverScale(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Return to Login',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailureState(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.shieldAlert,
            size: 48,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Unblock Failed',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: theme.hintColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 20),
        Text(
          'Request a new unblock link',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              SemanticTextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                labelText: 'Email Address',
                hintText: 'name@company.com',
                prefixIcon: LucideIcons.mail,
                validator: (v) => v == null || !v.contains('@')
                    ? 'Enter a valid email address'
                    : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: HoverScale(
                  child: ElevatedButton(
                    onPressed: _isRequestingNewLink ? null : _requestNewUnblockLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandEmerald500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isRequestingNewLink
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Send Unlock Link',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/');
          },
          child: Text(
            'Back to Login',
            style: TextStyle(
              color: theme.hintColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
