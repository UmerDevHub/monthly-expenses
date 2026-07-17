import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final VoidCallback onBackTap;
  final VoidCallback onAddExpenseTap;

  const HistoryScreen({
    super.key,
    required this.onBackTap,
    required this.onAddExpenseTap,
  });

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  
  // Set to track collapsed date headers
  final Set<String> _collapsedDates = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to change month using the arrows
  void _navigateMonth(int monthsDiff) {
    final currentMonthStr = ref.read(selectedMonthProvider);
    final parts = currentMonthStr.split('-');
    if (parts.length != 2) return;
    
    final year = int.tryParse(parts[0]) ?? 2026;
    final month = int.tryParse(parts[1]) ?? 7;
    
    final date = DateTime(year, month);
    final newDate = DateTime(date.year, date.month + monthsDiff);
    
    final newMonthStr = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}';
    ref.read(selectedMonthProvider.notifier).state = newMonthStr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedMonth = ref.watch(selectedMonthProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final categories = ref.watch(categoriesProvider);

    // Format Selected Month
    final monthDateTime = DateTime.parse('$selectedMonth-01');
    final monthName = DateFormat('MMMM yyyy').format(monthDateTime);

    // Filter expenses based on selected Category and Search Query
    final filteredExpenses = expenses.where((exp) {
      // 1. Category ID check
      if (_selectedCategoryId != null && exp.categoryId != _selectedCategoryId) {
        return false;
      }
      
      // 2. Search Query check
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        
        // Match note
        final noteMatch = exp.note?.toLowerCase().contains(query) ?? false;
        
        // Match category name
        final category = categories.firstWhere(
          (c) => c.id == exp.categoryId,
          orElse: () => Category(id: '', name: '', iconAsset: '', colorHex: ''),
        );
        final catMatch = category.name.toLowerCase().contains(query);
        
        // Match amount
        final amountMatch = exp.amount.toString().contains(query);

        return noteMatch || catMatch || amountMatch;
      }

      return true;
    }).toList();

    // Stats calculations for summary card
    final totalSpentFiltered = filteredExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final totalEntriesFiltered = filteredExpenses.length;

    // Group expenses by Date
    final Map<String, List<Expense>> groupedExpenses = {};
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    for (var exp in filteredExpenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(exp.date);
      if (!groupedExpenses.containsKey(dateKey)) {
        groupedExpenses[dateKey] = [];
      }
      groupedExpenses[dateKey]!.add(exp);
    }

    // Sort dates descending
    final sortedDateKeys = groupedExpenses.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Navigation Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Circular Back Button
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_outlined, size: 20),
                      onPressed: widget.onBackTap,
                    ),
                  ),
                  Text(
                    'History',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  // Search Button
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search_outlined, size: 20),
                      onPressed: () {
                        // Focus on search input
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 2. Month Selector Pagination Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 24),
                    onPressed: () => _navigateMonth(-1),
                  ),
                  GestureDetector(
                    onTap: () => _showMonthSelector(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          monthName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 24),
                    onPressed: () => _navigateMonth(1),
                  ),
                ],
              ),
            ),

            // 3. Search & Filter Inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Text Search Field
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceCardDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search expenses, notes, categories...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Button
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune_outlined, size: 20),
                      onPressed: () {
                        // Quick clear filters
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          _selectedCategoryId = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filters reset successfully'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 4. Category Filter Chips (Horizontal Row)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // "All" Chip
                    _buildFilterChip(
                      label: 'All',
                      isSelected: _selectedCategoryId == null,
                      icon: Icons.grid_view_outlined,
                      activeBgColor: AppColors.primary,
                      activeTextColor: Colors.white,
                      borderColor: isDark ? AppColors.borderDark : AppColors.border,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    // Default Categories Chips
                    ...categories.take(3).map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      final catColor = AppColors.getCategoryColor(cat.name, cat.colorHex);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildFilterChip(
                          label: cat.name,
                          isSelected: isSelected,
                          iconWidget: SvgPicture.asset(
                            cat.iconAsset,
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              isSelected ? Colors.white : catColor,
                              BlendMode.srcIn,
                            ),
                          ),
                          activeBgColor: catColor,
                          activeTextColor: Colors.white,
                          borderColor: catColor.withOpacity(0.4),
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = isSelected ? null : cat.id;
                            });
                          },
                        ),
                      );
                    }),
                    // "More" Dropdown Chip
                    _buildFilterChip(
                      label: 'More',
                      isSelected: _selectedCategoryId != null && 
                          !categories.take(3).any((c) => c.id == _selectedCategoryId),
                      icon: Icons.keyboard_arrow_down,
                      activeBgColor: AppColors.primary,
                      activeTextColor: Colors.white,
                      borderColor: isDark ? AppColors.borderDark : AppColors.border,
                      onTap: () => _showMoreCategoriesSheet(context, categories),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Monthly Stats Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    // Wallet Icon inside Circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Total Spent
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Spent',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rs. ${totalSpentFiltered.toStringAsFixed(0)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Vertical Separator
                    Container(
                      height: 36,
                      width: 1,
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    const SizedBox(width: 16),
                    // Total Entries
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Entries',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalEntriesFiltered',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
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

            // 6. Date Grouped Transaction List
            Expanded(
              child: filteredExpenses.isEmpty
                  ? _buildEmptyState(theme, isDark)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemCount: sortedDateKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedDateKeys[index];
                        final list = groupedExpenses[dateKey]!;
                        final isCollapsed = _collapsedDates.contains(dateKey);

                        // Date parser & formatter
                        final parsedDate = DateTime.parse(dateKey);
                        String dateHeader = '';
                        if (dateKey == todayStr) {
                          dateHeader = 'Today • ${DateFormat('d MMMM yyyy').format(parsedDate)}';
                        } else if (dateKey == yesterdayStr) {
                          dateHeader = 'Yesterday • ${DateFormat('d MMMM yyyy').format(parsedDate)}';
                        } else {
                          dateHeader = DateFormat('d MMMM yyyy').format(parsedDate);
                        }

                        final dayTotal = list.fold(0.0, (sum, exp) => sum + exp.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Accordion Header
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isCollapsed) {
                                    _collapsedDates.remove(dateKey);
                                  } else {
                                    _collapsedDates.add(dateKey);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateHeader,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Rs. ${dayTotal.toStringAsFixed(0)}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontFamily: 'Space Grotesk',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          isCollapsed 
                                              ? Icons.keyboard_arrow_down 
                                              : Icons.keyboard_arrow_up,
                                          size: 16,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Date Group Entries Card (only visible if expanded)
                            if (!isCollapsed)
                              Card(
                                margin: EdgeInsets.zero,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: list.length,
                                  separatorBuilder: (context, idx) => Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: isDark ? AppColors.borderDark : AppColors.border,
                                  ),
                                  itemBuilder: (context, itemIdx) {
                                    final exp = list[itemIdx];
                                    final category = categories.firstWhere(
                                      (c) => c.id == exp.categoryId,
                                      orElse: () => Category(
                                        id: exp.categoryId,
                                        name: exp.categoryId.replaceAll('_', ' '),
                                        iconAsset: 'assets/icons/tag.svg',
                                        colorHex: '#7A9E5A',
                                      ),
                                    );
                                    
                                    final catColor = AppColors.getCategoryColor(category.name, category.colorHex);
                                    final timeStr = DateFormat('hh:mm a').format(exp.date);

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: catColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: SvgPicture.asset(
                                          category.iconAsset,
                                          colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                                        ),
                                      ),
                                      title: Text(
                                        category.name,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        exp.note ?? 'No description',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Rs. ${exp.amount.toStringAsFixed(0)}',
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontFamily: 'Space Grotesk',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                timeStr,
                                                style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.more_vert, size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _showEntryMenu(context, exp),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddExpenseTap,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No matching expenses found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Try adjusting your search query or filters'),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    Widget? iconWidget,
    required Color activeBgColor,
    required Color activeTextColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeBgColor 
              : (isDark ? AppColors.surfaceCardDark : Colors.white),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? activeBgColor : borderColor,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null) ...[
              iconWidget,
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? activeTextColor 
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? activeTextColor 
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              ),
            ),
          ],
        ),
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

  void _showMoreCategoriesSheet(BuildContext context, List<Category> categories) {
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
                  'Select Category Filter',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategoryId == cat.id;
                    final catColor = AppColors.getCategoryColor(cat.name, cat.colorHex);
                    return ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SvgPicture.asset(
                          cat.iconAsset,
                          colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                        ),
                      ),
                      title: Text(cat.name),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = isSelected ? null : cat.id;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEntryMenu(BuildContext context, Expense expense) {
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
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text(
                  'Delete Entry',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, expense);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Expense expense) {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entry deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
