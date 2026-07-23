import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/category_progress_card.dart';
import '../../widgets/recent_entries_list.dart';
import '../category_detail/category_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onAddExpenseTap;
  final Function(int)? onNavigateTab;

  const HomeScreen({
    super.key,
    required this.onAddExpenseTap,
    this.onNavigateTab,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _obscureAmount = false;
  String? _selectedCategoryHighlight;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning ☀️';
    if (hour >= 12 && hour < 17) return 'Good Afternoon 🌤️';
    if (hour >= 17 && hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  void _showCurrencySelector(BuildContext context) {
    final settings = ref.read(appSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceCardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Currency',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fixed exchange rate: 1 QAR = 74.03 PKR',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: settings.currency == 'QAR'
                    ? (isDark ? const Color(0xFF1E2822) : const Color(0xFFE8F3EE))
                    : null,
                leading: const Text('🇶🇦', style: TextStyle(fontSize: 28)),
                title: const Text('Qatari Riyal (QAR)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Default Currency'),
                trailing: settings.currency == 'QAR' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).updateSettings(
                    settings.copyWith(currency: 'QAR'),
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: settings.currency == 'PKR'
                    ? (isDark ? const Color(0xFF1E2822) : const Color(0xFFE8F3EE))
                    : null,
                leading: const Text('🇵🇰', style: TextStyle(fontSize: 28)),
                title: const Text('Pakistani Rupee (PKR)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('1 QAR = 74.03 PKR'),
                trailing: settings.currency == 'PKR' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(appSettingsProvider.notifier).updateSettings(
                    settings.copyWith(currency: 'PKR'),
                  );
                  Navigator.pop(context);
                },
              ),
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

    final selectedMonth = ref.watch(selectedMonthProvider);
    final settings = ref.watch(appSettingsProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final categories = ref.watch(categoriesProvider);
    final totalSpent = ref.watch(totalSpentProvider);
    final categorySummaries = ref.watch(categorySummariesProvider);
    final recurringBills = ref.watch(recurringExpensesProvider);

    // Format selected month
    final monthDateTime = DateTime.parse('$selectedMonth-01');
    final monthName = DateFormat('MMM yyyy').format(monthDateTime);

    // Budget Calculations
    final overallLimit = settings.overallMonthlyLimit ?? 5000.0;
    final budgetUsagePercent = overallLimit > 0 ? (totalSpent / overallLimit) : 0.0;

    Color budgetStatusColor = const Color(0xFF2EA072);
    String budgetStatusText = "No expenses logged yet";
    if (totalSpent > 0) {
      if (budgetUsagePercent >= 1.0) {
        budgetStatusColor = AppColors.danger;
        budgetStatusText = "Budget exceeded! 🚨";
      } else if (budgetUsagePercent >= 0.8) {
        budgetStatusColor = AppColors.accentWarning;
        budgetStatusText = "Careful! Approaching limit ⚠️";
      } else {
        budgetStatusColor = const Color(0xFF2EA072);
        budgetStatusText = "You're staying on track! 👍";
      }
    }

    // Notification count check
    int notificationCount = 0;
    if (overallLimit > 0 && totalSpent >= overallLimit) notificationCount++;
    for (var s in categorySummaries) {
      if ((s.category.monthlyLimit ?? 0) > 0 && s.spent >= s.category.monthlyLimit!) {
        notificationCount++;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF9F9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP HEADER BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatar & User Info
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: Color(0xFF073826),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (settings.userName.isNotEmpty ? settings.userName[0] : 'U').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2EA072),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? AppColors.backgroundDark : const Color(0xFFF9F9F8),
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
                              _getGreeting(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF757575),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              settings.userName.isNotEmpty ? settings.userName : 'Abdul Jabbar',

                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E2522),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Stay on track! 💪',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF8C8C8C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Currency & Month Selectors
                    Row(
                      children: [
                        // Currency Selector Pill Button
                        GestureDetector(
                          onTap: () => _showCurrencySelector(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceCardDark : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : const Color(0xFFE5E5E3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  CurrencyFormatter.getCurrencyFlag(settings.currency),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  settings.currency,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 14,
                                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF555555),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Month Pill Button
                        GestureDetector(
                          onTap: () => _showMonthSelector(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceCardDark : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : const Color(0xFFE5E5E3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF555555)),
                                const SizedBox(width: 4),
                                Text(
                                  monthName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF555555)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 2. HERO TOTAL OUTFLOW CARD (Matching exact screenshot design)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF073826),
                        Color(0xFF0C4D35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF073826).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative background circular swoosh
                      Positioned(
                        right: -30,
                        bottom: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: -60,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.03),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Outflow tag & Eye button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.output_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Total Outflow',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _obscureAmount ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.white70,
                                  size: 20,
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

                          // Main Amount Text
                          Text(
                            _obscureAmount
                                ? '${settings.currency} ••••••'
                                : CurrencyFormatter.format(totalSpent, settings.currency, decimalDigits: 0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Space Grotesk',
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Budget Limit text
                          Text(
                            'of ${CurrencyFormatter.format(overallLimit, settings.currency, decimalDigits: 0)} limit',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Progress Bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: budgetUsagePercent.clamp(0.0, 1.0),
                                    backgroundColor: Colors.white.withOpacity(0.18),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      budgetUsagePercent > 1.0 ? const Color(0xFFFF5252) : const Color(0xFF2EA072),
                                    ),
                                    minHeight: 5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${(budgetUsagePercent * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Status indicator line
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: budgetStatusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                budgetStatusText,
                                style: TextStyle(
                                  color: budgetStatusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Action Buttons Row inside Hero Card
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: widget.onAddExpenseTap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF073826),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF073826)),
                                  label: const Text(
                                    'Quick Add',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showBudgetGoalsSheet(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.12),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  icon: const Icon(Icons.track_changes_rounded, size: 18, color: Colors.white),
                                  label: const Text(
                                    'Goals & Budget',
                                    style: TextStyle(
                                      fontSize: 14,
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
                ),
                const SizedBox(height: 16),

                // 3. QUICK ACTIONS ROW (4 Cards matching exact screenshot layout)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceCardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionItem(
                        icon: Icons.add_rounded,
                        bgColor: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF073826),
                        label: 'Add Expense',
                        onTap: widget.onAddExpenseTap,
                        isDark: isDark,
                      ),
                      _buildQuickActionItem(
                        icon: Icons.description_outlined,
                        bgColor: const Color(0xFFF0EAFA),
                        iconColor: const Color(0xFF6B4EFF),
                        label: 'Reports',
                        onTap: () {
                          if (widget.onNavigateTab != null) widget.onNavigateTab!(2);
                        },
                        isDark: isDark,
                      ),
                      _buildQuickActionItem(
                        icon: Icons.history_rounded,
                        bgColor: const Color(0xFFFDF0E6),
                        iconColor: const Color(0xFFE67E22),
                        label: 'History',
                        onTap: () {
                          if (widget.onNavigateTab != null) widget.onNavigateTab!(1);
                        },
                        isDark: isDark,
                      ),
                      _buildQuickActionItem(
                        icon: Icons.track_changes_outlined,
                        bgColor: const Color(0xFFE6F5F3),
                        iconColor: const Color(0xFF00897B),
                        label: 'Goals',
                        onTap: () => _showBudgetGoalsSheet(context),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 4. CATEGORY BREAKDOWN SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category Breakdown',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E2522),
                      ),
                    ),
                    Text(
                      '${categorySummaries.length} Categories',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 164,
                  child: categorySummaries.isEmpty
                      ? Center(
                          child: Text(
                            'No categories created yet',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF888888),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryDetailScreen(
                                      category: summary.category,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),

                // 5. RECENT ACTIVITY SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E2522),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.onNavigateTab != null) widget.onNavigateTab!(1);
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF073826),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Recent entries list or Custom Empty State Illustration
                if (expenses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const ClipboardEmptyIllustration(),
                        const SizedBox(height: 16),
                        Text(
                          'No Expenses Yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E2522),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start building your financial ledger by\ntapping the button below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF757575),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: widget.onAddExpenseTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF073826),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'Add First Expense',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  RecentEntriesList(
                    expenses: _selectedCategoryHighlight == null
                        ? expenses
                        : expenses.where((e) => e.categoryId == _selectedCategoryHighlight).toList(),
                    categories: categories,
                    onExpenseTap: (exp) => _showDeleteConfirmation(context, exp),
                  ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withOpacity(0.2) : bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthSelector(BuildContext context) {
    final allExpenses = ref.read(expensesProvider);
    final Set<String> monthsSet = {
      DateFormat('yyyy-MM').format(DateTime.now()),
    };
    for (var exp in allExpenses) {
      monthsSet.add(DateFormat('yyyy-MM').format(exp.date));
    }
    final months = monthsSet.toList()..sort((a, b) => b.compareTo(a));


    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              final date = DateTime.parse('$month-01');
              final formattedStr = DateFormat('MMMM yyyy').format(date);
              final isSelected = ref.watch(selectedMonthProvider) == month;

              return ListTile(
                title: Text(
                  formattedStr,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF073826) : null,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF073826)) : null,
                onTap: () {
                  ref.read(selectedMonthProvider.notifier).state = month;
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showBudgetGoalsSheet(BuildContext context) {
    final settings = ref.read(appSettingsProvider);
    final controller = TextEditingController(
      text: settings.overallMonthlyLimit?.toStringAsFixed(0) ?? '55000',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Monthly Spending Goal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Set your target monthly limit to track budget health.'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monthly Limit (${settings.currency})',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(controller.text) ?? 55000.0;
                    ref.read(appSettingsProvider.notifier).updateSettings(
                      settings.copyWith(overallMonthlyLimit: val),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Budget limit updated successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF073826),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Target'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF2EA072)),
              SizedBox(height: 12),
              Text(
                'All Clear!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'No pending budget alerts or bill reminders.',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16),
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
          title: const Text('Delete Expense'),
          content: Text('Are you sure you want to remove "${expense.note}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              onPressed: () {
                ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

// CUSTOM ILLUSTRATION WIDGET (Matching exact Clipboard + Plant + Sparkles illustration in screenshot)
class ClipboardEmptyIllustration extends StatelessWidget {
  const ClipboardEmptyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft circle
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFD3EBE1),
              shape: BoxShape.circle,
            ),
          ),
          // Clipboard shape
          Container(
            width: 48,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF073826), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF073826).withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top clip bar
                Container(
                  width: 22,
                  height: 6,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF073826),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 8),
                // Lines inside clipboard
                _buildLine(30),
                const SizedBox(height: 4),
                _buildLine(24),
                const SizedBox(height: 4),
                _buildLine(28),
                const SizedBox(height: 4),
                _buildLine(18),
              ],
            ),
          ),
          // Potted plant on bottom left of clipboard
          Positioned(
            left: 18,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFF073826),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sparkle 1 (Top right)
          const Positioned(
            right: 18,
            top: 14,
            child: Text(
              '✦',
              style: TextStyle(
                color: Color(0xFF073826),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Sparkle 2 (Top left)
          const Positioned(
            left: 20,
            top: 22,
            child: Text(
              '✦',
              style: TextStyle(
                color: Color(0xFF073826),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(double width) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0xFF2EA072),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
