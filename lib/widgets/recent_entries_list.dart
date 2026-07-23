import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'custom_card.dart';

class RecentEntriesList extends ConsumerWidget {
  final List<Expense> expenses;
  final List<Category> categories;
  final Function(Expense)? onExpenseTap;
  final String? currency;

  const RecentEntriesList({
    super.key,
    required this.expenses,
    required this.categories,
    this.onExpenseTap,
    this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider);
    final activeCurrency = currency ?? settings.currency;

    if (expenses.isEmpty) {
      return const CustomEmptyState(
        title: 'No Expenses Recorded',
        description: 'Your logged transactions for this period will appear here.',
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

    final sortedKeys = groupedExpenses.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final list = groupedExpenses[dateKey]!;

        String headerTitle;
        final parsedDate = DateTime.parse(dateKey);

        if (dateKey == todayStr) {
          headerTitle = 'Today';
        } else if (dateKey == yesterdayStr) {
          headerTitle = 'Yesterday';
        } else {
          headerTitle = DateFormat('EEEE, d MMMM').format(parsedDate);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 6.0, left: 4.0),
              child: Row(
                children: [
                  CustomPillBadge(
                    label: headerTitle,
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            PremiumCard(
              padding: EdgeInsets.zero,
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

                  final category = categories.firstWhere(
                    (cat) => cat.id == exp.categoryId,
                    orElse: () => Category(
                      id: exp.categoryId,
                      name: exp.categoryId.replaceAll('_', ' '),
                      iconAsset: 'receipt_long',
                      colorHex: '#10B981',
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
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconData(category.iconAsset),
                              size: 18,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (exp.note != null && exp.note!.isNotEmpty) ? exp.note! : 'No note added',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$activeCurrency ${exp.amount.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeText,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 10,
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

  IconData _getIconData(String iconAsset) {
    switch (iconAsset) {
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'restaurant':
        return Icons.restaurant;
      case 'home':
        return Icons.home;
      case 'phone_android':
        return Icons.phone_android;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'medical_services':
        return Icons.medical_services;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
