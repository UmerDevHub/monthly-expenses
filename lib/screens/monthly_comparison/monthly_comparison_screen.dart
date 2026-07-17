import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

class MonthlyComparisonScreen extends ConsumerStatefulWidget {
  const MonthlyComparisonScreen({super.key});

  @override
  ConsumerState<MonthlyComparisonScreen> createState() => _MonthlyComparisonScreenState();
}

class _MonthlyComparisonScreenState extends ConsumerState<MonthlyComparisonScreen> {
  String _baseMonth = '2026-07';
  String _targetMonth = '2026-06';

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
    monthSet.addAll(['2026-07', '2026-06', '2026-05', '2026-04']);
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
              ...availableMonths.map((m) {
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
              }),
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
              // 1. Month Picker Row
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
                                Text(
                                  _formatMonthLabel(_baseMonth),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
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
                                Text(
                                  _formatMonthLabel(_targetMonth),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
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

              // 2. Spent Summary Hero Card
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
                      Text(
                        'Total Comparison',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${settings.currency} ${baseTotal.toStringAsFixed(0)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _formatMonthLabel(_baseMonth),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${settings.currency} ${targetTotal.toStringAsFixed(0)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontFamily: 'Space Grotesk',
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _formatMonthLabel(_targetMonth),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // Delta status row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: deltaAmount > 0
                                  ? AppColors.danger.withOpacity(0.12)
                                  : (deltaAmount < 0 
                                      ? AppColors.primary.withOpacity(0.12)
                                      : Colors.grey.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  deltaAmount > 0 
                                      ? Icons.trending_up 
                                      : (deltaAmount < 0 ? Icons.trending_down : Icons.trending_flat),
                                  color: deltaAmount > 0 
                                      ? AppColors.danger 
                                      : (deltaAmount < 0 ? AppColors.primary : Colors.grey),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  deltaAmount > 0 
                                      ? '+${deltaPercent.toStringAsFixed(1)}%' 
                                      : '${deltaPercent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: deltaAmount > 0 
                                        ? AppColors.danger 
                                        : (deltaAmount < 0 ? AppColors.primary : Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              deltaAmount > 0
                                  ? 'Spent ${settings.currency} ${deltaAmount.abs().toStringAsFixed(0)} more than comparison month.'
                                  : (deltaAmount < 0
                                      ? 'Saved ${settings.currency} ${deltaAmount.abs().toStringAsFixed(0)} compared to comparison month!'
                                      : 'Spending was identical!'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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

              // 3. FL Double Bar Chart Component
              if (activeCategories.isNotEmpty) ...[
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Spends Chart',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(width: 12, height: 12, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              _formatMonthLabel(_baseMonth),
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(width: 16),
                            Container(width: 12, height: 12, color: AppColors.accentWarning),
                            const SizedBox(width: 6),
                            Text(
                              _formatMonthLabel(_targetMonth),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // FL double bar chart container
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: activeCategories.take(4).map((c) {
                                final base = baseCatSpent[c.id] ?? 0.0;
                                final target = targetCatSpent[c.id] ?? 0.0;
                                return base > target ? base : target;
                              }).fold<double>(1000.0, (prev, val) => val > prev ? val : prev) * 1.15,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < activeCategories.take(4).length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6.0),
                                          child: Text(
                                            activeCategories[index].name,
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(activeCategories.take(4).length, (i) {
                                final cat = activeCategories[i];
                                final baseVal = baseCatSpent[cat.id] ?? 0.0;
                                final targetVal = targetCatSpent[cat.id] ?? 0.0;
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: baseVal,
                                      color: AppColors.primary,
                                      width: 12,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                    BarChartRodData(
                                      toY: targetVal,
                                      color: AppColors.accentWarning,
                                      width: 12,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 4. Category-wise Breakdown Ledger
              Text(
                'Category Spends Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (activeCategories.isEmpty) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No spending records found in either month.'),
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeCategories.length,
                    separatorBuilder: (context, idx) => Divider(
                      height: 1,
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final cat = activeCategories[index];
                      final baseVal = baseCatSpent[cat.id] ?? 0.0;
                      final targetVal = targetCatSpent[cat.id] ?? 0.0;
                      final diff = baseVal - targetVal;
                      final double percentDiff = targetVal > 0 ? (diff / targetVal) * 100 : 0.0;

                      final catColor = AppColors.getCategoryColor(cat.name, cat.colorHex);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        child: Row(
                          children: [
                            // Category Icon Container
                            Container(
                              width: 32,
                              height: 32,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset(
                                cat.iconAsset.isNotEmpty ? cat.iconAsset : 'assets/icons/tag.svg',
                                colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Category Name and comparison details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${settings.currency} ${baseVal.toStringAsFixed(0)} vs ${settings.currency} ${targetVal.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Delta Badge Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: diff > 0
                                    ? AppColors.danger.withOpacity(0.12)
                                    : (diff < 0 
                                        ? AppColors.primary.withOpacity(0.12)
                                        : Colors.grey.withOpacity(0.12)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                diff > 0 
                                    ? '+${percentDiff.toStringAsFixed(0)}%' 
                                    : (diff < 0 ? '${percentDiff.toStringAsFixed(0)}%' : '0%'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: diff > 0 
                                      ? AppColors.danger 
                                      : (diff < 0 ? AppColors.primary : Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
