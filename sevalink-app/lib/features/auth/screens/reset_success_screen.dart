import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/themes/app_theme.dart';
import '../widgets/auth_button.dart';

class ResetSuccessScreen extends StatelessWidget {
  const ResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), // Light green
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.checkCircle2,
                  color: Color(0xFF16A34A), // Green
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Password Reset\nSuccessful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your password has been successfully reset. You can now sign in with your new password.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.subtitleColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AuthButton(
                text: 'Go to Sign In',
                onPressed: () => context.go('/auth/login'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
