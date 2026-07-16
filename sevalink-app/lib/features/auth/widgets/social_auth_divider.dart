import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';
class SocialAuthDivider extends StatelessWidget {
  const SocialAuthDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppTheme.borderColor)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Or continue with",
            style: TextStyle(color: AppTheme.subtitleColor, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.borderColor)),
      ],
    );
  }
}
