import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class CategoryProgressCard extends ConsumerWidget {
  final Category category;
  final double spent;
  final double limit;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryProgressCard({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider);

    final categoryColor = AppColors.getCategoryColor(category.name, category.colorHex);
    final usagePercent = limit > 0 ? (spent / limit) : 0.0;
    final percentText = '${(usagePercent * 100).toInt()}%';

    Color bgSoftColor = categoryColor.withOpacity(0.12);
    if (category.name.toLowerCase().contains('bike') || category.name.toLowerCase().contains('maintenance')) {
      bgSoftColor = const Color(0xFFFCE8E9);
    } else if (category.name.toLowerCase().contains('khana') || category.name.toLowerCase().contains('food')) {
      bgSoftColor = const Color(0xFFE8F5E9);
    } else if (category.name.toLowerCase().contains('petrol') || category.name.toLowerCase().contains('fuel')) {
      bgSoftColor = const Color(0xFFFFF3E0);
    } else if (category.name.toLowerCase().contains('rent') || category.name.toLowerCase().contains('home')) {
      bgSoftColor = const Color(0xFFE3F2FD);
    } else if (category.name.toLowerCase().contains('sim') || category.name.toLowerCase().contains('bill')) {
      bgSoftColor = const Color(0xFFF5F0EB);
    }

    final progressBarColor = usagePercent > 1.0 ? AppColors.danger : categoryColor;
    final formattedAmount = CurrencyFormatter.format(spent, settings.currency, decimalDigits: 0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 145,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? const Color(0xFF1E2822) : AppColors.surfaceCardDark)
              : (isSelected ? const Color(0xFFE8F3EE) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark || isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : const Color(0xFFF0F0EE)),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon Container Badge
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isDark ? categoryColor.withOpacity(0.2) : bgSoftColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                category.iconAsset,
                colorFilter: ColorFilter.mode(categoryColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2C3E35),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formattedAmount,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'Space Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF073826),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      percentText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: usagePercent > 1.0 ? AppColors.danger : (usagePercent > 0 ? progressBarColor : const Color(0xFFE65100)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: usagePercent.clamp(0.0, 1.0),
                          backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFEEEEEC),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usagePercent > 1.0 ? AppColors.danger : progressBarColor,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
