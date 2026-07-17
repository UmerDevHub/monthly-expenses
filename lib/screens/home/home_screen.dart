import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_progress_card.dart';
import '../../widgets/recent_entries_list.dart';
import '../../widgets/spending_pie_chart.dart';

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

    // Format selected month to human readable
    final monthDateTime = DateTime.parse('$selectedMonth-01');
    final monthName = DateFormat('MMMM yyyy').format(monthDateTime);

    // Budget Calculations
    final overallLimit = settings.overallMonthlyLimit ?? 0.0;
    final budgetUsagePercent = overallLimit > 0 ? (totalSpent / overallLimit) : 0.0;
    
    // Choose status color and text based on usage
    Color budgetStatusColor = AppColors.primary;
    String budgetStatusText = "You're doing good! 👍";
    if (budgetUsagePercent >= 1.0) {
      budgetStatusColor = AppColors.danger;
      budgetStatusText = "Budget exceed ho gaya hai! 🚨";
    } else if (budgetUsagePercent >= 0.8) {
      budgetStatusColor = AppColors.accentWarning;
      budgetStatusText = "Careful! Approaching limit ⚠️";
    }

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
                          'Salaam, Umer 👋',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Month Dropdown Trigger (simulated dropdown button)
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
                    // Custom Notification Bell
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_outlined, size: 22),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No new notifications'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
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
                            // Eye Toggle Icon Button
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
                        // Big Spent Amount
                        Text(
                          _obscureAmount 
                              ? 'Rs. ••••••' 
                              : 'Rs. ${totalSpent.toStringAsFixed(0)}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Budget context
                        if (overallLimit > 0) ...[
                          Text(
                            'of Rs. ${overallLimit.toStringAsFixed(0)} budget',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Progress Bar
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
                          // Warning message
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
                    TextButton(
                      onPressed: () {
                        // Simply toggle show all / clean selection
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
                ),
                const SizedBox(height: 12),

                // Category Carousel (Horizontal Scroll)
                SizedBox(
                  height: 115,
                  child: ListView.builder(
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
                            // Small filter label
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
                    Text(
                      'All entries',
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
                const SizedBox(height: 80), // bottom spacing for FAB
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

  void _showMonthSelector(BuildContext context) {
    final selectedMonth = ref.read(selectedMonthProvider);
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              // List of months to select (Simulate July 2026, June 2026, May 2026)
              ListTile(
                title: const Text('July 2026'),
                trailing: selectedMonth == '2026-07' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(selectedMonthProvider.notifier).state = '2026-07';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('June 2026'),
                trailing: selectedMonth == '2026-06' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(selectedMonthProvider.notifier).state = '2026-06';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('May 2026'),
                trailing: selectedMonth == '2026-05' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(selectedMonthProvider.notifier).state = '2026-05';
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Entry?'),
          content: Text('Are you sure you want to delete this expense of Rs. ${expense.amount.toStringAsFixed(0)}?'),
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
