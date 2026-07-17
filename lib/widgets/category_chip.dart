import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoryColor = AppColors.getCategoryColor(category.name, category.colorHex);

    // Selected styling: Category color at 12% opacity fill, 1.5px border in full color.
    // Unselected styling: White bg (or dark card bg), 1px border #E8E4DA.
    final boxDecoration = BoxDecoration(
      color: isSelected
          ? categoryColor.withOpacity(0.12)
          : (isDark ? AppColors.surfaceCardDark : Colors.white),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isSelected
            ? categoryColor
            : (isDark ? AppColors.borderDark : const Color(0xFFE8E4DA)),
        width: isSelected ? 1.5 : 1.0,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: boxDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                category.iconAsset.isNotEmpty ? category.iconAsset : 'assets/icons/tag.svg',
                colorFilter: ColorFilter.mode(categoryColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
