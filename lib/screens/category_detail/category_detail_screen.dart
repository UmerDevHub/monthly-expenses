import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {

  final Category category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  late Category _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
  }

  void _showEditCategorySheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.read(appSettingsProvider);

    final double displayLimit = (_currentCategory.monthlyLimit != null && _currentCategory.monthlyLimit! > 0)
        ? CurrencyFormatter.convert(_currentCategory.monthlyLimit!, settings.currency)
        : 0.0;
    
    final nameController = TextEditingController(text: _currentCategory.name);
    final limitController = TextEditingController(
      text: displayLimit > 0 ? displayLimit.toStringAsFixed(0) : '',
    );
    
    String selectedIcon = _currentCategory.iconAsset;
    String selectedColorHex = _currentCategory.colorHex;

    final presetIcons = [
      'assets/icons/food.svg',
      'assets/icons/petrol.svg',
      'assets/icons/rent.svg',
      'assets/icons/sim.svg',
      'assets/icons/bike.svg',
      'assets/icons/tag.svg',
    ];

    final presetColors = [
      '#2D5F4C', // Deep forest green
      '#C9822E', // Warm amber
      '#B33A3A', // Muted red
      '#6B8E5A', // Sage green
      '#5A7A9E', // Slate blue
      '#9E7A5A', // Clay brown
      '#8E5A7A', // Plum purple
      '#7A9E5A', // Olive green
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Category Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name field
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Category Name',
                          labelStyle: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Limit field
                      TextField(
                        controller: limitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monthly Limit (${settings.currency})',
                          prefixText: '${settings.currency} ',
                          labelStyle: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Icon picker
                      Text(
                        'Choose Icon',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: presetIcons.length,
                          itemBuilder: (context, idx) {
                            final icon = presetIcons[idx];
                            final isSelected = selectedIcon == icon;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedIcon = icon;
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.12)
                                        : (isDark ? AppColors.borderDark : AppColors.background),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: SvgPicture.asset(
                                    icon,
                                    colorFilter: ColorFilter.mode(
                                      isSelected 
                                          ? AppColors.primary 
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Color picker
                      Text(
                        'Choose Color',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: presetColors.length,
                          itemBuilder: (context, idx) {
                            final hex = presetColors[idx];
                            final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                            final isSelected = selectedColorHex == hex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    selectedColorHex = hex;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected 
                                      ? Icon(Icons.check, size: 16, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;
                            
                            final double? enteredVal = double.tryParse(limitController.text.trim());
                            final double? limitInQAR = (enteredVal != null && enteredVal > 0)
                                ? (settings.currency == 'PKR' ? (enteredVal / 74.03) : enteredVal)
                                : null;
                            
                            final updated = _currentCategory.copyWith(
                              name: name,
                              iconAsset: selectedIcon,
                              colorHex: selectedColorHex,
                              monthlyLimit: limitInQAR,
                            );

                            ref.read(categoriesProvider.notifier).updateCategory(updated);
                            setState(() {
                              _currentCategory = updated;
                            });

                            Navigator.pop(context);
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Expense expense, String currency) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Entry?'),
          content: Text('Are you sure you want to delete this expense of $currency ${expense.amount.toStringAsFixed(0)}?'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedMonth = ref.watch(selectedMonthProvider);
    final settings = ref.watch(appSettingsProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final totalSpentOverall = ref.watch(totalSpentProvider);

    // Refresh current category details from categoriesProvider if updated elsewhere
    final currentList = ref.watch(categoriesProvider);
    final freshCat = currentList.firstWhere(
      (c) => c.id == _currentCategory.id,
      orElse: () => _currentCategory,
    );
    _currentCategory = freshCat;

    final categoryColor = AppColors.getCategoryColor(_currentCategory.name, _currentCategory.colorHex);

    // Filter expenses matching this category
    final categoryExpenses = expenses
        .where((e) => e.categoryId == _currentCategory.id)
        .toList();

    final categorySpent = categoryExpenses.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final monthlyLimit = _currentCategory.monthlyLimit ?? 0.0;
    final usagePercent = monthlyLimit > 0 ? (categorySpent / monthlyLimit) : 0.0;

    // Daily Average Calculation
    final monthDateTime = DateTime.parse('$selectedMonth-01');
    final year = monthDateTime.year;
    final month = monthDateTime.month;
    final totalDaysInMonth = DateUtils.getDaysInMonth(year, month);
    final dailyAverage = categorySpent / totalDaysInMonth;

    // Share of overall spend calculation
    final shareOfWallet = totalSpentOverall > 0 
        ? (categorySpent / totalSpentOverall) * 100 
        : 0.0;

    // Select color matching progress
    Color progressBarColor = categoryColor;
    if (usagePercent >= 1.0) {
      progressBarColor = AppColors.danger;
    } else if (usagePercent >= 0.8) {
      progressBarColor = AppColors.accentWarning;
    }

    // Group expenses by date
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var exp in categoryExpenses) {
      final formattedDay = DateFormat('d MMMM').format(exp.date);
      final yearStr = DateFormat('yyyy').format(exp.date);
      
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      String displayGroupKey = '$formattedDay, $yearStr';
      if (exp.date.year == today.year && exp.date.month == today.month && exp.date.day == today.day) {
        displayGroupKey = 'Today - $formattedDay';
      } else if (exp.date.year == yesterday.year && exp.date.month == yesterday.month && exp.date.day == yesterday.day) {
        displayGroupKey = 'Yesterday - $formattedDay';
      }
      
      if (groupedExpenses[displayGroupKey] == null) {
        groupedExpenses[displayGroupKey] = [];
      }
      groupedExpenses[displayGroupKey]!.add(exp);
    }

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
          _currentCategory.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_note_outlined,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              size: 26,
            ),
            onPressed: () => _showEditCategorySheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Summary Card
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              _currentCategory.iconAsset.isNotEmpty 
                                  ? _currentCategory.iconAsset 
                                  : 'assets/icons/tag.svg',
                              colorFilter: ColorFilter.mode(categoryColor, BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Month Spend Total',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Big Spent Text
                      Text(
                        CurrencyFormatter.format(categorySpent, settings.currency, decimalDigits: 0),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontFamily: 'Space Grotesk',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Progress and limit description
                      if (monthlyLimit > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Limit: ${CurrencyFormatter.format(monthlyLimit, settings.currency, decimalDigits: 0)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),

                            Text(
                              '${(usagePercent * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: progressBarColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: usagePercent.clamp(0.0, 1.0),
                            backgroundColor: isDark 
                                ? AppColors.borderDark 
                                : AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
                            minHeight: 6,
                          ),
                        ),
                        if (usagePercent >= 1.0) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'Exceeded this month budget! 🚨',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'No budget limit set.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showEditCategorySheet(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Set Limit',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Metrics Rows (Daily Average & Share of Wallet)
              Row(
                children: [
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Average',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(dailyAverage, settings.currency, decimalDigits: 0),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share of Wallet',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${shareOfWallet.toStringAsFixed(1)}%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Transactions Log Header
              Text(
                'Transaction Log',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Grouped Expenses List
              if (categoryExpenses.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: isDark ? AppColors.borderDark : Colors.grey[350],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No entries for this category',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groupedExpenses.keys.length,
                  itemBuilder: (context, groupIndex) {
                    final dateKey = groupedExpenses.keys.elementAt(groupIndex);
                    final groupList = groupedExpenses[dateKey]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
                          child: Text(
                            dateKey,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupList.length,
                            separatorBuilder: (context, idx) => Divider(
                              height: 1,
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                            itemBuilder: (context, itemIdx) {
                              final exp = groupList[itemIdx];
                              return ListTile(
                                title: Text(
                                  exp.note ?? 'Expense',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('jm').format(exp.date),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(exp.amount, settings.currency, decimalDigits: 0),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontFamily: 'Space Grotesk',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                      onPressed: () => _showDeleteConfirmation(context, exp, settings.currency),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
