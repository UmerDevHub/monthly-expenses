import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final ValueChanged<String> onChanged;

  const AmountInput({
    super.key,
    required this.controller,
    required this.currency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textLength = controller.text.isEmpty ? 1 : controller.text.length;
    final double inputWidth = (textLength * 28.0) + 16.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Currency Symbol Hero
        Text(
          currency,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        // Amount input field
        SizedBox(
          width: inputWidth,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: theme.textTheme.displayLarge?.copyWith(
              fontFamily: 'Space Grotesk',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: theme.textTheme.displayLarge?.copyWith(
                fontFamily: 'Space Grotesk',
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary).withOpacity(0.3),
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
