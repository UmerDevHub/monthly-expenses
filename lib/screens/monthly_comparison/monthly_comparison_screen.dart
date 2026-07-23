import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';


class MonthlyComparisonScreen extends ConsumerStatefulWidget {
  const MonthlyComparisonScreen({super.key});

  @override
  ConsumerState<MonthlyComparisonScreen> createState() => _MonthlyComparisonScreenState();
}

class _MonthlyComparisonScreenState extends ConsumerState<MonthlyComparisonScreen> {
  late String _baseMonth;
  late String _targetMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateFormat('yyyy-MM').format(now);
    _targetMonth = DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1, 1));
  }

  String _formatMonthLabel(String yearMonth) {
    try {
      final date = DateTime.parse('$yearMonth-01');
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return yearMonth;
    }
  }

  void _showMonthPicker(BuildContext context, bool isBase) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allExpenses = ref.read(expensesProvider);
    final monthSet = allExpenses.map((e) => DateFormat('yyyy-MM').format(e.date)).toSet();
    monthSet.add(DateFormat('yyyy-MM').format(DateTime.now()));

    final availableMonths = monthSet.toList()..sort((a, b) => b.compareTo(a));


    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? AppColors.surfaceCardDark : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  isBase ? 'Select Base Month' : 'Select Comparison Month',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: availableMonths.map((m) {
                    final isSelected = isBase ? (_baseMonth == m) : (_targetMonth == m);
                    return ListTile(
                      title: Text(_formatMonthLabel(m)),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          if (isBase) {
                            _baseMonth = m;
                          } else {
                            _targetMonth = m;
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settings = ref.watch(appSettingsProvider);
    final allExpenses = ref.watch(expensesProvider);
    final categories = ref.watch(categoriesProvider);

    // Compute Base Month data
    final baseExpenses = allExpenses
        .where((e) => DateFormat('yyyy-MM').format(e.date) == _baseMonth)
        .toList();
    final baseTotal = baseExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    
    final Map<String, double> baseCatSpent = {};
    for (var e in baseExpenses) {
      baseCatSpent[e.categoryId] = (baseCatSpent[e.categoryId] ?? 0.0) + e.amount;
    }

    // Compute Target Month data
    final targetExpenses = allExpenses
        .where((e) => DateFormat('yyyy-MM').format(e.date) == _targetMonth)
        .toList();
    final targetTotal = targetExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    final Map<String, double> targetCatSpent = {};
    for (var e in targetExpenses) {
      targetCatSpent[e.categoryId] = (targetCatSpent[e.categoryId] ?? 0.0) + e.amount;
    }

    // Total Overall Delta
    final deltaAmount = baseTotal - targetTotal;
    final double deltaPercent = targetTotal > 0 ? (deltaAmount / targetTotal) * 100 : 0.0;

    // Collect all categories that have spending in either month
    final activeCategoryIds = <String>{...baseCatSpent.keys, ...targetCatSpent.keys};
    final activeCategories = categories.where((c) => activeCategoryIds.contains(c.id)).toList();

    // Sort by largest spending in the base month
    activeCategories.sort((a, b) {
      final aSpent = baseCatSpent[a.id] ?? 0.0;
      final bSpent = baseCatSpent[b.id] ?? 0.0;
      return bSpent.compareTo(aSpent);
    });

    final bool isEmptyBoth = baseTotal == 0 && targetTotal == 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Monthly Comparison',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Picker Row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showMonthPicker(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceCardDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Base Month',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatMonthLabel(_baseMonth),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showMonthPicker(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceCardDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compare With',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatMonthLabel(_targetMonth),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (isEmptyBoth) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.compare_arrows, size: 48, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No Expenses to Compare',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add expenses in either ${_formatMonthLabel(_baseMonth)} or ${_formatMonthLabel(_targetMonth)} to view side-by-side analytics.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Spent Summary Hero Card
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Spent Comparison',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (deltaAmount > 0 ? AppColors.danger : AppColors.primary).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${deltaAmount >= 0 ? "+" : ""}${deltaPercent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: deltaAmount > 0 ? AppColors.danger : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatMonthLabel(_baseMonth),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(baseTotal, settings.currency, decimalDigits: 0),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 40, color: isDark ? AppColors.borderDark : AppColors.border),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatMonthLabel(_targetMonth),
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(targetTotal, settings.currency, decimalDigits: 0),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Breakdown Comparison List
                Text(
                  'Category Differences',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final cat = activeCategories[idx];
                    final bSpent = baseCatSpent[cat.id] ?? 0.0;
                    final tSpent = targetCatSpent[cat.id] ?? 0.0;
                    final diff = bSpent - tSpent;
                    final color = AppColors.getCategoryColor(cat.name, cat.colorHex);

                    return Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SvgPicture.asset(
                                cat.iconAsset,
                                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${CurrencyFormatter.format(bSpent, settings.currency, decimalDigits: 0)} vs ${CurrencyFormatter.format(tSpent, settings.currency, decimalDigits: 0)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${diff >= 0 ? "+" : "-"}${CurrencyFormatter.format(diff.abs(), settings.currency, decimalDigits: 0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: diff > 0 ? AppColors.danger : (diff < 0 ? AppColors.primary : Colors.grey),
                              ),
                            ),

                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
