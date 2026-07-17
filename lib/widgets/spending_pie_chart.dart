import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class SpendingPieChart extends StatefulWidget {
  final List<CategorySummary> summaries;
  final double totalSpent;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const SpendingPieChart({
    super.key,
    required this.summaries,
    required this.totalSpent,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Sort summaries so that the rendering is deterministic
    final list = List<CategorySummary>.from(widget.summaries)
      ..sort((a, b) => b.spent.compareTo(a.spent));

    if (list.isEmpty || widget.totalSpent == 0) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          'No data for this month',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    // Handle mapping selectedCategory to touchedIndex
    if (widget.selectedCategoryId != null) {
      touchedIndex = list.indexWhere((s) => s.category.id == widget.selectedCategoryId);
    } else {
      touchedIndex = -1;
    }

    final pieSections = List.generate(list.length, (i) {
      final summary = list[i];
      final isTouched = i == touchedIndex;
      final color = AppColors.getCategoryColor(summary.category.name, summary.category.colorHex);
      final double percentageValue = (summary.spent / widget.totalSpent) * 100;
      final double radius = isTouched ? 30.0 : 25.0;

      return PieChartSectionData(
        color: color,
        value: summary.spent,
        title: '${percentageValue.toInt()}%',
        radius: radius,
        titleStyle: theme.textTheme.labelLarge?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: percentageValue > 8, // Hide title if too small
      );
    });

    return Row(
      children: [
        // Donut Chart
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 180,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            // Don't deselect automatically to keep focus crisp unless user clicks outside
                            return;
                          }
                          final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          if (index >= 0 && index < list.length) {
                            touchedIndex = index;
                            widget.onCategorySelected(list[index].category.id);
                          } else {
                            touchedIndex = -1;
                            widget.onCategorySelected(null);
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    sections: pieSections,
                  ),
                ),
                // Center Hole Label
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs.',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        widget.totalSpent.toStringAsFixed(0),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
        // Legend List
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(list.length, (i) {
              final summary = list[i];
              final isSelected = widget.selectedCategoryId == summary.category.id;
              final color = AppColors.getCategoryColor(summary.category.name, summary.category.colorHex);
              final double percentageValue = (summary.spent / widget.totalSpent) * 100;

              return InkWell(
                onTap: () {
                  if (isSelected) {
                    widget.onCategorySelected(null);
                  } else {
                    widget.onCategorySelected(summary.category.id);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Color indicator dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category Name
                      Expanded(
                        child: Text(
                          summary.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      // Amount
                      Text(
                        'Rs. ${summary.spent.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Space Grotesk',
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Percentage
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${percentageValue.toInt()}%',
                          textAlign: Alignment.centerRight.x > 0 ? TextAlign.right : TextAlign.left,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
