import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/hive_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../monthly_comparison/monthly_comparison_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedMonthRange = 'Last 6 Months';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedMonth = ref.watch(selectedMonthProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final categories = ref.watch(categoriesProvider);
    final categorySummaries = ref.watch(categorySummariesProvider);
    final totalSpent = ref.watch(totalSpentProvider);
    final settings = ref.watch(appSettingsProvider);

    // Date formatting for the subtitle
    final monthDateTime = DateTime.parse('$selectedMonth-01');
    final monthName = DateFormat('MMMM yyyy').format(monthDateTime);

    // Calculate core statistics
    final totalEntries = expenses.length;
    final daysInMonth = DateTime(monthDateTime.year, monthDateTime.month + 1, 0).day;
    final dailyAverage = totalSpent > 0 ? (totalSpent / daysInMonth) : 0.0;

    // Previous month baseline calculation from Hive
    final prevMonthDate = DateTime(monthDateTime.year, monthDateTime.month - 1, 1);
    final prevMonthKey = DateFormat('yyyy-MM').format(prevMonthDate);
    final allExpensesList = HiveService.expensesBox.values.toList();
    final prevMonthExpenses = allExpensesList.where((e) {
      final y = e.date.year;
      final m = e.date.month.toString().padLeft(2, '0');
      return '$y-$m' == prevMonthKey;
    }).toList();

    final double prevMonthSpent = prevMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final double prevDailyAvg = prevMonthSpent > 0 ? (prevMonthSpent / DateTime(prevMonthDate.year, prevMonthDate.month + 1, 0).day) : 0.0;
    final int prevEntries = prevMonthExpenses.length;

    // Trend calculations vs previous month
    final spentTrendPercent = prevMonthSpent > 0 ? ((totalSpent - prevMonthSpent) / prevMonthSpent * 100) : 0.0;
    final dailyAvgTrendPercent = prevDailyAvg > 0 ? ((dailyAverage - prevDailyAvg) / prevDailyAvg * 100) : 0.0;
    final entriesTrendDiff = totalEntries - prevEntries;
    final prevMonthName = DateFormat('MMM').format(prevMonthDate);

    // Sort category summaries by spent amount descending
    final sortedSummaries = List<CategorySummary>.from(categorySummaries)
      ..sort((a, b) => b.spent.compareTo(a.spent));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Analyze your spending and trends',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.calendar_today_outlined, size: 20),
                            onPressed: () => _showMonthSelector(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Month and Filter Selector Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceCardDark : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _navigateMonth(-1),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showMonthSelector(context),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  monthName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 14),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _navigateMonth(1),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filters reset'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.surfaceCardDark : Colors.white,
                        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.filter_list_outlined, size: 16),
                      label: const Text('Filters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Spent',
                        value: CurrencyFormatter.format(totalSpent, settings.currency, decimalDigits: 0),
                        trend: prevMonthSpent == 0 ? 'First period' : '${spentTrendPercent >= 0 ? "+" : ""}${spentTrendPercent.toStringAsFixed(0)}% vs $prevMonthName',
                        icon: Icons.account_balance_wallet_outlined,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Daily Average',
                        value: CurrencyFormatter.format(dailyAverage, settings.currency, decimalDigits: 0),
                        trend: prevMonthSpent == 0 ? 'First period' : '${dailyAvgTrendPercent >= 0 ? "+" : ""}${dailyAvgTrendPercent.toStringAsFixed(0)}% vs $prevMonthName',
                        icon: Icons.bar_chart_outlined,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Entries',
                        value: '$totalEntries',
                        trend: prevEntries == 0 ? 'First period' : '${entriesTrendDiff >= 0 ? "+" : ""}$entriesTrendDiff vs $prevMonthName',
                        icon: Icons.receipt_long_outlined,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),


                const SizedBox(height: 24),

                // 4. Spending by Category Donut Chart
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spending by Category',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Scroll down to category details
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'View Details',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDonutChartSection(sortedSummaries, totalSpent, theme, isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Month-to-Month Comparison Bar Chart
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Month-to-Month Comparison',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const MonthlyComparisonScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Compare',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildRangeSelector(context),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildBarChartSection(theme, isDark, settings),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Category Details List with Custom Progress Bars
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Category Details',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Sorting label
                            Row(
                              children: [
                                Text(
                                  'By Amount',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 14,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedSummaries.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final summary = sortedSummaries[index];
                            final percentage = totalSpent > 0 ? (summary.spent / totalSpent) : 0.0;
                            final color = AppColors.getCategoryColor(summary.category.name, summary.category.colorHex);

                            return Row(
                              children: [
                                // Category Icon
                                Container(
                                  width: 36,
                                  height: 36,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SvgPicture.asset(
                                    summary.category.iconAsset,
                                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Category Name and Progress Bar
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        summary.category.name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Progress Indicator Line
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage,
                                          backgroundColor: isDark 
                                              ? AppColors.borderDark 
                                              : AppColors.border,
                                          valueColor: AlwaysStoppedAnimation<Color>(color),
                                          minHeight: 5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Amount & Percent
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(summary.spent, settings.currency, decimalDigits: 0),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontFamily: 'Space Grotesk',
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(percentage * 100).toStringAsFixed(0)}%',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Export PDF Document Card
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.article_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Monthly Report',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Download PDF report for this month',
                                style: theme.textTheme.labelLarge?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _exportReportAsPdf(context, expenses, categories, monthName, totalSpent),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          icon: const Icon(Icons.download_outlined, size: 16),
                          label: const Text('Export PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60), // Space at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Space Grotesk',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: trend.contains('-') ? AppColors.danger : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChartSection(
    List<CategorySummary> summaries,
    double totalSpent,
    ThemeData theme,
    bool isDark,
  ) {
    final settings = ref.read(appSettingsProvider);
    if (summaries.isEmpty || totalSpent == 0) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text('No entries this month', style: theme.textTheme.bodyMedium),
      );
    }

    const double pieSize = 180.0;

    final pieSections = List.generate(summaries.length, (i) {
      final summary = summaries[i];
      final color = AppColors.getCategoryColor(summary.category.name, summary.category.colorHex);

      return PieChartSectionData(
        color: color,
        value: summary.spent,
        radius: 20,
        showTitle: false,
      );
    });

    return Row(
      children: [
        // Pie/Donut Visualizer
        Expanded(
          flex: 5,
          child: SizedBox(
            height: pieSize,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 52,
                    sections: pieSections,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(totalSpent, settings.currency, decimalDigits: 0),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Space Grotesk',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Simplified Legend
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(summaries.take(5).length, (i) {
              final summary = summaries[i];
              final percentage = totalSpent > 0 ? (summary.spent / totalSpent) * 100 : 0.0;
              final color = AppColors.getCategoryColor(summary.category.name, summary.category.colorHex);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        summary.category.iconAsset,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        summary.category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Space Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartSection(ThemeData theme, bool isDark, AppSettings settings) {
    int monthCount = 6;
    if (_selectedMonthRange == 'Last 3 Months') monthCount = 3;
    if (_selectedMonthRange == 'Last 12 Months') monthCount = 12;

    final selectedMonthStr = ref.watch(selectedMonthProvider);
    final selectedDate = DateTime.parse('$selectedMonthStr-01');

    final List<double> historicalSpents = [];
    final List<String> historicalMonths = [];

    final allExpenses = HiveService.expensesBox.values.toList();

    for (int i = monthCount - 1; i >= 0; i--) {
      final d = DateTime(selectedDate.year, selectedDate.month - i, 1);
      final mKey = DateFormat('yyyy-MM').format(d);
      final mLabel = DateFormat('MMM').format(d);

      final totalForMonth = allExpenses.where((e) {
        final y = e.date.year;
        final m = e.date.month.toString().padLeft(2, '0');
        return '$y-$m' == mKey;
      }).fold(0.0, (sum, e) => sum + e.amount);

      historicalSpents.add(totalForMonth);
      historicalMonths.add(mLabel);
    }

    final maxSpent = historicalSpents.reduce((a, b) => a > b ? a : b);
    if (maxSpent == 0) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: Text(
          'No monthly spending data logged for this range.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      );
    }

    final double calculatedMaxY = (maxSpent * 1.2).clamp(1000.0, 1000000.0);

    final barGroups = List.generate(historicalSpents.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: historicalSpents[i],
            color: AppColors.primary,
            width: monthCount > 6 ? 14 : 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
        showingTooltipIndicators: historicalSpents[i] > 0 ? [0] : [],
      );
    });

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: calculatedMaxY,
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 6,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (rod.toY == 0) return null;
                return BarTooltipItem(
                  CurrencyFormatter.formatCompact(rod.toY, settings.currency),
                  theme.textTheme.labelLarge!.copyWith(
                    fontFamily: 'Space Grotesk',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < historicalMonths.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        historicalMonths[index],
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value == 0 || value == calculatedMaxY) return const SizedBox();
                  return Text(
                    NumberFormat.compact().format(value),
                    style: theme.textTheme.labelLarge?.copyWith(fontSize: 8.5),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: calculatedMaxY / 3,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark ? AppColors.borderDark : AppColors.border,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Last 3 Months'),
                    onTap: () {
                      setState(() => _selectedMonthRange = 'Last 3 Months');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Last 6 Months'),
                    onTap: () {
                      setState(() => _selectedMonthRange = 'Last 6 Months');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Last 12 Months'),
                    onTap: () {
                      setState(() => _selectedMonthRange = 'Last 12 Months');
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceCardDark : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedMonthRange,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 14),
          ],
        ),
      ),
    );
  }

  void _navigateMonth(int diff) {
    final currentMonthStr = ref.read(selectedMonthProvider);
    final parts = currentMonthStr.split('-');
    if (parts.length != 2) return;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final date = DateTime(year, month);
    final newDate = DateTime(date.year, date.month + diff);
    ref.read(selectedMonthProvider.notifier).state =
        '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}';
  }

  void _showMonthSelector(BuildContext context) {
    final selectedMonth = ref.read(selectedMonthProvider);
    final allExpenses = ref.read(expensesProvider);

    final Set<String> monthSet = {
      DateFormat('yyyy-MM').format(DateTime.now()),
    };
    for (var exp in allExpenses) {
      monthSet.add(DateFormat('yyyy-MM').format(exp.date));
    }
    final List<String> monthKeys = monthSet.toList()..sort((a, b) => b.compareTo(a));


    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Month',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: monthKeys.map((mk) {
                    final d = DateTime.parse('$mk-01');
                    final label = DateFormat('MMMM yyyy').format(d);
                    final isSelected = selectedMonth == mk;
                    return ListTile(
                      title: Text(label),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        ref.read(selectedMonthProvider.notifier).state = mk;
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


  Future<void> _exportReportAsPdf(
    BuildContext context,
    List<Expense> expenses,
    List<Category> categories,
    String monthName,
    double totalSpent,
  ) async {
    final settings = ref.read(appSettingsProvider);
    // Show a loading banner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF Report...'),
        duration: Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final pdf = pw.Document();

    // Group expenses by category
    final Map<String, double> categorySpent = {};
    for (var exp in expenses) {
      categorySpent[exp.categoryId] = (categorySpent[exp.categoryId] ?? 0.0) + exp.amount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Letterhead / Invoice Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('KHARCHA APP REPORT',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text('Local Personal Expense Statements', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Statement Period', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(monthName),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey),
            pw.SizedBox(height: 16),

            // Summary Info Blocks
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Spent', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(CurrencyFormatter.format(totalSpent, settings.currency), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),

                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Transactions', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text('${expenses.length} Entries', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Category Table
            pw.Text('CATEGORY WISE BREAKDOWN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Category Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Amount Spent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Share %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...categorySpent.entries.map((entry) {
                  final cat = categories.firstWhere(
                    (c) => c.id == entry.key,
                    orElse: () => Category(id: entry.key, name: entry.key, iconAsset: '', colorHex: ''),
                  );
                  final double percent = totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0.0;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(cat.name.isEmpty ? entry.key : cat.name),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(CurrencyFormatter.format(entry.value, settings.currency)),
                      ),

                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${percent.toStringAsFixed(1)}%'),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 24),

            // Transaction Ledger Table
            pw.Text('TRANSACTION LOG LEDGER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Date & Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Description Note', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Amount (${settings.currency})', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                  ],
                ),
                ...expenses.map((exp) {
                  final cat = categories.firstWhere(
                    (c) => c.id == exp.categoryId,
                    orElse: () => Category(id: exp.categoryId, name: exp.categoryId, iconAsset: '', colorHex: ''),
                  );
                  final formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(exp.date);
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(cat.name, style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(exp.note ?? '', style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(CurrencyFormatter.convert(exp.amount, settings.currency).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
                      ),

                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    // Save and print/preview using printing library
    final monthStr = ref.read(selectedMonthProvider);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'KharchaApp_Report_${monthStr.replaceAll('-', '_')}.pdf',
    );
  }
}
