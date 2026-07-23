import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/recent_entries_list.dart';
import '../../widgets/spending_pie_chart.dart';
import '../category_detail/category_detail_screen.dart';
import '../reports/ai_insights_screen.dart';

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

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    if (hour < 21) return 'Good Evening 🌙';
    return 'Good Night ⭐️';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedMonth = ref.watch(selectedMonthProvider);
    final settings = ref.watch(appSettingsProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final totalSpent = ref.watch(totalSpentProvider);
    final categorySummaries = ref.watch(categorySummariesProvider);
    final recurringBills = ref.watch(recurringExpensesProvider);

    // Format selected month
    final monthDateTime = DateTime.parse('$selectedMonth-01');
    final monthName = DateFormat('MMMM yyyy').format(monthDateTime);

    // Budget Calculations
    final overallLimit = settings.overallMonthlyLimit ?? 0.0;
    final budgetUsagePercent = overallLimit > 0 ? (totalSpent / overallLimit) : 0.0;
    final daysInMonth = DateTime(monthDateTime.year, monthDateTime.month + 1, 0).day;
    final dailyBurnRate = totalSpent > 0 ? (totalSpent / daysInMonth) : 0.0;

    // Status styling
    Color budgetStatusColor = AppColors.primaryAccent;
    String budgetStatusText = "Optimal spending pace";
    if (totalSpent == 0) {
      budgetStatusText = "No expenses logged yet";
    } else if (budgetUsagePercent >= 1.0) {
      budgetStatusColor = AppColors.danger;
      budgetStatusText = "Over budget limit!";
    } else if (budgetUsagePercent >= 0.8) {
      budgetStatusColor = AppColors.accentWarning;
      budgetStatusText = "Approaching budget limit";
    }

    // Notifications check count
    int notificationCount = 0;
    if (overallLimit > 0 && totalSpent >= overallLimit) notificationCount++;
    for (var s in categorySummaries) {
      if ((s.category.monthlyLimit ?? 0) > 0 && s.spent >= s.category.monthlyLimit!) {
        notificationCount++;
      }
    }
    notificationCount += recurringBills.length;

    // Top spending category for Hero featured block
    final sortedSummaries = List<CategorySummary>.from(categorySummaries)
      ..sort((a, b) => b.spent.compareTo(a.spent));
    final CategorySummary? topCategory = sortedSummaries.isNotEmpty && sortedSummaries.first.spent > 0
        ? sortedSummaries.first
        : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Personalized Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // User Avatar with Status Indicator
                      Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.softLight,
                            ),
                            child: Center(
                              child: Text(
                                settings.userName.isNotEmpty ? settings.userName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.backgroundDark : AppColors.background,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTimeGreeting(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            settings.userName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Month Selector Chip & Notification Bell
                  Row(
                    children: [
                      BouncingButton(
                        onTap: () => _showMonthSelector(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceCardDark : Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.primaryAccent),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('MMM yyyy').format(monthDateTime),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Notification Bell Button
                      Stack(
                        children: [
                          BouncingButton(
                            onTap: () => _showNotificationsSheet(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceCardDark : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.borderDark : AppColors.border,
                                ),
                              ),
                              child: const Icon(Icons.notifications_none_rounded, size: 18),
                            ),
                          ),
                          if (notificationCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
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
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Hero SaaS Spending Card
              PremiumCard(
                padding: const EdgeInsets.all(22.0),
                gradient: isDark ? AppColors.heroGradientDark : AppColors.primaryGradient,
                boxShadow: AppShadows.heroGlow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Total Outflow',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _obscureAmount ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureAmount = !_obscureAmount;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _obscureAmount
                          ? '${settings.currency} ••••••'
                          : '${settings.currency} ${NumberFormat('#,##0').format(totalSpent)}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Burn rate tag & limit info
                    Row(
                      children: [
                        Text(
                          overallLimit > 0
                              ? 'of ${settings.currency} ${NumberFormat('#,##0').format(overallLimit)} limit'
                              : 'No overall budget set',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const Spacer(),
                        if (totalSpent > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '~ ${settings.currency} ${dailyBurnRate.toStringAsFixed(0)}/day',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Modern Progress Bar
                    if (overallLimit > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: budgetUsagePercent.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(budgetStatusColor),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: budgetStatusColor),
                          const SizedBox(width: 6),
                          Text(
                            budgetStatusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: budgetStatusColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(budgetUsagePercent * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),

                    // Quick Action Shortcuts inside Hero Card
                    Row(
                      children: [
                        Expanded(
                          child: BouncingButton(
                            onTap: widget.onAddExpenseTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Quick Add',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BouncingButton(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AiInsightsScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'AI Insights',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. Section: Category Spending (Asymmetrical Layout)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category Breakdown',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${categorySummaries.length} Categories',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (categorySummaries.isEmpty)
                const CustomEmptyState(
                  title: 'No Categories Configured',
                  description: 'Add your custom expense categories in Settings to get started.',
                )
              else ...[
                // Top Featured Category Banner (if spend > 0)
                if (topCategory != null) ...[
                  PremiumCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryDetailScreen(category: topCategory.category),
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CustomProgressRing(
                          progress: topCategory.usagePercent,
                          color: AppColors.getCategoryColor(topCategory.category.name, topCategory.category.colorHex),
                          trackColor: isDark ? AppColors.borderDark : AppColors.border,
                          strokeWidth: 4.5,
                          size: 48,
                          centerChild: Icon(
                            _getIconData(topCategory.category.iconAsset),
                            size: 20,
                            color: AppColors.getCategoryColor(topCategory.category.name, topCategory.category.colorHex),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    topCategory.category.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  CustomPillBadge(
                                    label: 'Highest Spend',
                                    color: AppColors.getCategoryColor(topCategory.category.name, topCategory.category.colorHex),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${topCategory.expenseCount} entries recorded',
                                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${settings.currency} ${topCategory.spent.toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (topCategory.category.monthlyLimit != null)
                              Text(
                                'Limit: ${topCategory.category.monthlyLimit!.toStringAsFixed(0)}',
                                style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Grid of Other Categories
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 110,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: categorySummaries.length,
                  itemBuilder: (context, index) {
                    final summary = categorySummaries[index];
                    final catColor = AppColors.getCategoryColor(summary.category.name, summary.category.colorHex);

                    return PremiumCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailScreen(category: summary.category),
                          ),
                        );
                      },
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconData(summary.category.iconAsset),
                                  size: 16,
                                  color: catColor,
                                ),
                              ),
                              Text(
                                '${summary.percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: summary.percentage >= 100 ? AppColors.danger : catColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${settings.currency} ${summary.spent.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 28),

              // 4. Spending Distribution Pie Chart
              if (expenses.isNotEmpty) ...[
                Text(
                  'Spending Distribution',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Column(
                  children: sortedSummaries.take(4).map((summary) {
                    final catColor = AppColors.getCategoryColor(summary.category.name, summary.category.colorHex);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                summary.category.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${settings.currency} ${summary.spent.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontFamily: 'Space Grotesk',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          CustomProgressBar(
                            progress: totalSpent > 0 ? (summary.spent / totalSpent) : 0.0,
                            color: catColor,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
              ],

              // 5. Recent Activity Timeline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (expenses.isNotEmpty)
                    Text(
                      '${expenses.length} Transactions',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              if (expenses.isEmpty)
                CustomEmptyState(
                  title: 'No Expenses Yet',
                  description: 'Start building your financial ledger by tapping the button below.',
                  buttonText: 'Add First Expense',
                  onButtonPressed: widget.onAddExpenseTap,
                )
              else
                RecentEntriesList(
                  expenses: expenses.take(6).toList(),
                  categories: ref.watch(categoriesProvider),
                  currency: settings.currency,
                ),
            ],
          ),
        ),
      ),
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
      case 'receipt_long':
        return Icons.receipt_long;
      default:
        return Icons.category_outlined;
    }
  }

  void _showMonthSelector(BuildContext context) {
    final selectedMonth = ref.read(selectedMonthProvider);
    final now = DateTime.now();

    final List<String> monthKeys = [];
    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      monthKeys.add(DateFormat('yyyy-MM').format(d));
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Calendar Period',
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
                      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryAccent) : null,
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

  void _showNotificationsSheet(BuildContext context) {
    final categorySummaries = ref.read(categorySummariesProvider);
    final recurringBills = ref.read(recurringExpensesProvider);
    final settings = ref.read(appSettingsProvider);
    final totalSpent = ref.read(totalSpentProvider);

    final List<Widget> alerts = [];

    // Overall budget check
    if ((settings.overallMonthlyLimit ?? 0) > 0 && totalSpent >= settings.overallMonthlyLimit!) {
      alerts.add(
        _buildNotificationTile(
          context,
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
          title: 'Overall Budget Exceeded',
          description: 'Total spend (${settings.currency} ${totalSpent.toStringAsFixed(0)}) exceeded set limit.',
        ),
      );
    }

    // Category limits check
    for (var s in categorySummaries) {
      if ((s.category.monthlyLimit ?? 0) > 0 && s.spent >= s.category.monthlyLimit!) {
        alerts.add(
          _buildNotificationTile(
            context,
            icon: Icons.pie_chart_outline,
            color: AppColors.accentWarning,
            title: '${s.category.name} Budget Reached',
            description: 'Spent ${settings.currency} ${s.spent.toStringAsFixed(0)} of limit ${s.category.monthlyLimit!.toStringAsFixed(0)}.',
          ),
        );
      }
    }

    // Recurring items check
    for (var r in recurringBills) {
      alerts.add(
        _buildNotificationTile(
          context,
          icon: Icons.access_time_rounded,
          color: AppColors.info,
          title: 'Upcoming Recurring Bill: ${r.label}',
          description: 'Amount: ${settings.currency} ${r.amount.toStringAsFixed(0)} due on Day ${r.dueDay} of month.',
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications & Budget Alerts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (alerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text('No active alerts. All spending is within budget limits!'),
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: alerts,
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
