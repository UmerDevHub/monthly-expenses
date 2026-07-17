import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class RecentEntriesList extends ConsumerWidget {
  final List<Expense> expenses;
  final List<Category> categories;
  final Function(Expense)? onExpenseTap;

  const RecentEntriesList({
    super.key,
    required this.expenses,
    required this.categories,
    this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider);

    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'No entries found',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Group expenses by date string
    final Map<String, List<Expense>> groupedExpenses = {};
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    for (var exp in expenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(exp.date);
      if (!groupedExpenses.containsKey(dateKey)) {
        groupedExpenses[dateKey] = [];
      }
      groupedExpenses[dateKey]!.add(exp);
    }

    // Sort date keys descending
    final sortedKeys = groupedExpenses.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final list = groupedExpenses[dateKey]!;
        
        // Format Header title
        String headerTitle = '';
        final parsedDate = DateTime.parse(dateKey);
        
        if (dateKey == todayStr) {
          headerTitle = 'Today • ${DateFormat('d MMMM').format(parsedDate)}';
        } else if (dateKey == yesterdayStr) {
          headerTitle = 'Yesterday • ${DateFormat('d MMMM').format(parsedDate)}';
        } else {
          headerTitle = DateFormat('d MMMM yyyy').format(parsedDate);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Group Header
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
              child: Text(
                headerTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ),
            // Group List
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 1.0,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                itemBuilder: (context, subIndex) {
                  final exp = list[subIndex];
                  
                  // Find category matching categoryId
                  final category = categories.firstWhere(
                    (cat) => cat.id == exp.categoryId,
                    orElse: () => Category(
                      id: exp.categoryId,
                      name: exp.categoryId.replaceAll('_', ' '),
                      iconAsset: 'assets/icons/tag.svg',
                      colorHex: '#7A9E5A',
                    ),
                  );

                  final catColor = AppColors.getCategoryColor(category.name, category.colorHex);
                  final timeText = DateFormat('hh:mm a').format(exp.date);

                  return InkWell(
                    onTap: () {
                      if (onExpenseTap != null) {
                        onExpenseTap!(exp);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          // Custom Category Icon
                          Container(
                            width: 42,
                            height: 42,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SvgPicture.asset(
                              category.iconAsset,
                              colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Category & Notes Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  exp.note ?? 'No description',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Amount & Time Column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${settings.currency} ${exp.amount.toStringAsFixed(0)}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeText,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
