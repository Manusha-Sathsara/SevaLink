import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/themes/app_theme.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../../../providers/auth_provider.dart';
import 'dart:async';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isPinVerified = false;
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }
  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  Future<void> _handleResend() async {
    if (!_canResend) return;
    try {
      await ref.read(authRepositoryProvider).forgotPassword(widget.email);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN resent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isPinVerified) {
      // Local validation of PIN length before revealing password fields
      if (_pinController.text.trim().length == 6) {
        setState(() => _isPinVerified = true);
      }
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
        _pinController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        context.go('/auth/reset-success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter the 6-digit PIN sent to\n${widget.email}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.subtitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                AuthTextField(
                  label: '6-Digit PIN',
                  hint: 'Enter PIN',
                  prefixIcon: LucideIcons.key,
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.length != 6 ? 'Must be 6 digits' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _canResend ? _handleResend : null,
                    child: Text(
                      _canResend ? 'Resend PIN' : 'Resend in $_secondsRemaining s',
                      style: TextStyle(
                        color: _canResend ? AppTheme.primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isPinVerified) ...[
                  AuthTextField(
                    label: 'New Password',
                    hint: 'Enter new password',
                    prefixIcon: LucideIcons.lock,
                    controller: _passwordController,
                    isPassword: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: AppTheme.subtitleColor,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) => value!.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 20),
                  AuthTextField(
                    label: 'Confirm New Password',
                    hint: 'Re-enter new password',
                    prefixIcon: LucideIcons.lock,
                    controller: _confirmPasswordController,
                    isPassword: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: AppTheme.subtitleColor,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),
                ],
                AuthButton(
                  text: _isPinVerified ? 'Update Password' : 'Verify PIN',
                  isLoading: _isLoading,
                  onPressed: _handleReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
