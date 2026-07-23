import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_progress_card.dart';
import '../../widgets/recent_entries_list.dart';
import '../../widgets/spending_pie_chart.dart';
import '../category_detail/category_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onAddExpenseTap;

  const HomeScreen({
    super.key,
    required this.onAddExpenseTap,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _obscureAmount = false;
  String? _selectedCategoryHighlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedMonth = ref.watch(selectedMonthProvider);
    final settings = ref.watch(appSettingsProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final categories = ref.watch(categoriesProvider);
    final totalSpent = ref.watch(totalSpentProvider);
    final categorySummaries = ref.watch(categorySummariesProvider);
    final recurringBills = ref.watch(recurringExpensesProvider);

    // Format selected month to human readable
    final monthDateTime = DateTime.parse('$selectedMonth-01');
    final monthName = DateFormat('MMMM yyyy').format(monthDateTime);

    // Budget Calculations
    final overallLimit = settings.overallMonthlyLimit ?? 0.0;
    final budgetUsagePercent = overallLimit > 0 ? (totalSpent / overallLimit) : 0.0;
    
    // Choose status color and text based on usage
    Color budgetStatusColor = AppColors.primary;
    String budgetStatusText = "You're doing good! 👍";
    if (totalSpent == 0) {
      budgetStatusText = "No expenses logged yet";
    } else if (budgetUsagePercent >= 1.0) {
      budgetStatusColor = AppColors.danger;
      budgetStatusText = "Budget exceeded! 🚨";
    } else if (budgetUsagePercent >= 0.8) {
      budgetStatusColor = AppColors.accentWarning;
      budgetStatusText = "Careful! Approaching limit ⚠️";
    }

    // Notifications check
    int notificationCount = 0;
    if (overallLimit > 0 && totalSpent >= overallLimit) notificationCount++;
    for (var s in categorySummaries) {
      if ((s.category.monthlyLimit ?? 0) > 0 && s.spent >= s.category.monthlyLimit!) {
        notificationCount++;
      }
    }
    notificationCount += recurringBills.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting and Bell Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salaam, ${settings.userName} 👋',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _showMonthSelector(context),
                          child: Row(
                            children: [
                              Text(
                                monthName,
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Functional Notification Bell
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_outlined, size: 22),
                            onPressed: () => _showNotificationsSheet(context),
                          ),
                        ),
                        if (notificationCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total Spent Card
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
                              'Total Spent',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? AppColors.borderDark 
                                    : AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _obscureAmount 
                                      ? Icons.visibility_outlined 
                                      : Icons.visibility_off_outlined,
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureAmount = !_obscureAmount;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _obscureAmount 
                              ? '${settings.currency} ••••••' 
                              : '${settings.currency} ${totalSpent.toStringAsFixed(0)}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (overallLimit > 0) ...[
                          Text(
                            'of ${settings.currency} ${overallLimit.toStringAsFixed(0)} budget',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: budgetUsagePercent.clamp(0.0, 1.0),
                              backgroundColor: isDark 
                                  ? AppColors.borderDark 
                                  : AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(budgetStatusColor),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            budgetStatusText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: budgetStatusColor,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'No overall budget set',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Spending by Category Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spending by Category',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedCategoryHighlight != null) ...[
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategoryHighlight = null;
                          });
                        },
                        child: Text(
                          'Clear filter',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Category Carousel (Horizontal Scroll)
                SizedBox(
                  height: 138,
                  child: categorySummaries.isEmpty
                      ? Center(
                          child: Text(
                            'No categories set up',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: categorySummaries.length,
                          itemBuilder: (context, index) {
                            final summary = categorySummaries[index];
                            final isSelected = _selectedCategoryHighlight == summary.category.id;
                            return CategoryProgressCard(
                              category: summary.category,
                              spent: summary.spent,
                              limit: summary.category.monthlyLimit ?? 0.0,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCategoryHighlight = null;
                                  } else {
                                    _selectedCategoryHighlight = summary.category.id;
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),

                // Donut Chart Card (This Month Breakdown)
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
                              'This Month Breakdown',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'By Amount',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SpendingPieChart(
                          summaries: categorySummaries,
                          totalSpent: totalSpent,
                          selectedCategoryId: _selectedCategoryHighlight,
                          onCategorySelected: (catId) {
                            setState(() {
                              _selectedCategoryHighlight = catId;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Entries Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Entries',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (expenses.isNotEmpty)
                      Text(
                        '${expenses.length} entries',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),

                // Filtered recent entries list
                RecentEntriesList(
                  expenses: _selectedCategoryHighlight == null
                      ? expenses
                      : expenses.where((e) => e.categoryId == _selectedCategoryHighlight).toList(),
                  categories: categories,
                  onExpenseTap: (exp) {
                    _showDeleteConfirmation(context, exp);
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddExpenseTap,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.read(appSettingsProvider);
    final categorySummaries = ref.read(categorySummariesProvider);
    final totalSpent = ref.read(totalSpentProvider);
    final recurringBills = ref.read(recurringExpensesProvider);
    final overallLimit = settings.overallMonthlyLimit ?? 0.0;

    final List<Map<String, dynamic>> alerts = [];

    // Check overall budget limit
    if (overallLimit > 0 && totalSpent >= overallLimit) {
      alerts.add({
        'title': 'Overall Monthly Budget Exceeded',
        'desc': 'Total spent is ${settings.currency} ${totalSpent.toStringAsFixed(0)} (Budget: ${settings.currency} ${overallLimit.toStringAsFixed(0)})',
        'icon': Icons.warning_amber_rounded,
        'color': AppColors.danger,
      });
    }

    // Check individual category limits
    for (var s in categorySummaries) {
      final limit = s.category.monthlyLimit ?? 0.0;
      if (limit > 0 && s.spent >= limit) {
        alerts.add({
          'title': '${s.category.name} Budget Exceeded',
          'desc': 'Spent ${settings.currency} ${s.spent.toStringAsFixed(0)} out of ${settings.currency} ${limit.toStringAsFixed(0)} limit',
          'icon': Icons.report_problem_outlined,
          'color': AppColors.accentWarning,
        });
      }
    }

    // Add recurring bill reminders
    for (var r in recurringBills) {
      alerts.add({
        'title': 'Recurring Bill Due: ${r.label}',
        'desc': 'Amount: ${settings.currency} ${r.amount.toStringAsFixed(0)} (Due day ${r.dueDay} of month)',
        'icon': Icons.calendar_today_outlined,
        'color': AppColors.primary,
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceCardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Budget Alerts & Reminders',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (alerts.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.primary, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'All Clear!',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No budget overflow alerts or pending bill reminders.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final alert = alerts[idx];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (alert['color'] as Color).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (alert['color'] as Color).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(alert['icon'] as IconData, color: alert['color'] as Color, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert['title'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: alert['color'] as Color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      alert['desc'] as String,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthSelector(BuildContext context) {
    final selectedMonth = ref.read(selectedMonthProvider);
    final now = DateTime.now();
    
    // Generate last 12 months dynamically
    final List<String> monthKeys = [];
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      monthKeys.add(DateFormat('yyyy-MM').format(date));
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Month',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: monthKeys.length,
                  itemBuilder: (context, idx) {
                    final key = monthKeys[idx];
                    final date = DateTime.parse('$key-01');
                    final label = DateFormat('MMMM yyyy').format(date);
                    final isSelected = selectedMonth == key;

                    return ListTile(
                      title: Text(label),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        ref.read(selectedMonthProvider.notifier).state = key;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Expense expense) {
    final settings = ref.read(appSettingsProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Entry?'),
          content: Text('Are you sure you want to delete this expense of ${settings.currency} ${expense.amount.toStringAsFixed(0)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                Navigator.pop(context);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );
  }
}
