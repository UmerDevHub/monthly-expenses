import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

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
    
    // Progress bar color matches category color, turns red if over 100%
    final progressBarColor = usagePercent > 1.0 
        ? AppColors.danger 
        : categoryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.borderDark : const Color(0xFFF0ECE3))
              : (isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                category.iconAsset,
                colorFilter: ColorFilter.mode(categoryColor, BlendMode.srcIn),
              ),
            ),
            const Spacer(),
            // Category Name
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            // Spent Amount
            Text(
              '${settings.currency} ${spent.toStringAsFixed(0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontFamily: 'Space Grotesk',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Progress percentage and bar
            if (limit > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    percentText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: progressBarColor,
                    ),
                  ),
                  if (usagePercent > 1.0)
                    Text(
                      'Over',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 9,
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: usagePercent.clamp(0.0, 1.0),
                  backgroundColor: isDark 
                      ? AppColors.borderDark 
                      : AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
                  minHeight: 4,
                ),
              ),
            ] else ...[
              Text(
                'No Limit',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 10,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
