import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../widgets/quick_add_sheet.dart';
import '../category_detail/category_detail_screen.dart';

class RecurringExpensesScreen extends ConsumerStatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  ConsumerState<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends ConsumerState<RecurringExpensesScreen> {

  void _openQuickAddSheet(BuildContext context, RecurringExpense item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return QuickAddSheet(
          initialCategoryId: item.categoryId,
          initialAmount: item.amount,
          isFromRecurring: true,
        );
      },
    );
  }

  void _showAddEditRecurringSheet(BuildContext context, {RecurringExpense? editItem}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final labelController = TextEditingController(text: editItem?.label ?? '');
    final amountController = TextEditingController(
      text: editItem != null ? editItem.amount.toStringAsFixed(0) : '',
    );
    
    int selectedDay = editItem?.dueDay ?? 1;
    final categories = ref.read(categoriesProvider);
    String selectedCatId = editItem?.categoryId ?? (categories.isNotEmpty ? categories.first.id : 'other');

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
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE8E4DA),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                            editItem == null ? 'Add Recurring Expense' : 'Edit Recurring Expense',
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
                      
                      // Label Field
                      TextField(
                        controller: labelController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Label (e.g. WiFi Bill, Room Rent)',
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

                      // Amount Field
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
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

                      // Category Selector Label
                      Text(
                        'Category',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedCatId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceCardDark : const Color(0xFFF7F5F0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        dropdownColor: isDark ? AppColors.surfaceCardDark : Colors.white,
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              selectedCatId = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Due Day Selector Grid
                      Text(
                        'Due Day of Month: $selectedDay',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Grid of 31 days
                      Container(
                        height: 190,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceCardDark : const Color(0xFFF7F5F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1,
                          ),
                          itemCount: 31,
                          itemBuilder: (context, index) {
                            final dayNum = index + 1;
                            final isSelected = selectedDay == dayNum;
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  selectedDay = dayNum;
                                });
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppColors.primary 
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected 
                                        ? Colors.transparent 
                                        : (isDark ? AppColors.borderDark : const Color(0xFFE8E4DA)),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                                  ),
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
                          onPressed: () async {
                            final label = labelController.text.trim();
                            final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                            
                            if (label.isEmpty || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid label and amount.'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                              return;
                            }

                            final id = editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                            final newItem = RecurringExpense(
                              id: id,
                              categoryId: selectedCatId,
                              amount: amount,
                              dueDay: selectedDay,
                              label: label,
                            );

                            // Save in Hive
                            await ref.read(recurringExpensesProvider.notifier).addRecurringExpense(newItem);

                            // Schedule local notification
                            await NotificationService.scheduleMonthlyNotification(
                              id: id,
                              title: 'Bill Due: $label',
                              body: 'Your monthly payment of Rs. ${amount.toStringAsFixed(0)} is due today.',
                              dueDay: selectedDay,
                              categoryId: selectedCatId,
                              amount: amount,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            editItem == null ? 'Save Fixed Expense' : 'Save Changes',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

  Widget _statusPill({required String label, required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusPill(RecurringExpense item, List<Expense> allExpenses) {
    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);
    
    final isPaid = allExpenses.any((e) =>
      e.isFromRecurring &&
      e.categoryId == item.categoryId &&
      DateFormat('yyyy-MM').format(e.date) == currentMonthKey
    );

    if (isPaid) {
      return _statusPill(
        label: 'Paid this month',
        bgColor: const Color(0xFF6B8E5A).withOpacity(0.15),
        textColor: const Color(0xFF6B8E5A),
      );
    }

    final int dueDay = item.dueDay;
    final int daysInCurrentMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final int targetDay = dueDay > daysInCurrentMonth ? daysInCurrentMonth : dueDay;
    
    final dueDate = DateTime(now.year, now.month, targetDay);
    final today = DateTime(now.year, now.month, now.day);
    
    if (dueDate.isBefore(today)) {
      return _statusPill(
        label: 'Overdue',
        bgColor: const Color(0xFFB33A3A).withOpacity(0.15),
        textColor: const Color(0xFFB33A3A),
      );
    } else {
      final diffDays = dueDate.difference(today).inDays;
      final label = diffDays == 0 ? 'Due today' : 'Due in $diffDays days';
      return _statusPill(
        label: label,
        bgColor: const Color(0xFFC9822E).withOpacity(0.15),
        textColor: const Color(0xFFC9822E),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final recurringList = ref.watch(recurringExpensesProvider);
    final categories = ref.watch(categoriesProvider);
    final allExpenses = ref.watch(expensesProvider);
    final settings = ref.watch(appSettingsProvider);

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
          'Fixed Expenses',
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showAddEditRecurringSheet(context),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: recurringList.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Line-art tag icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceCardDark : const Color(0xFFF7F5F0),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE8E4DA),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No fixed expenses yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Room Rent, Sim Bill, etc. to get automated reminders.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => _showAddEditRecurringSheet(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? AppColors.primaryDark : AppColors.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          'Add Room Rent, Sim Bill, etc.',
                          style: TextStyle(
                            color: isDark ? AppColors.primaryDark : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: recurringList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = recurringList[index];
                  final cat = categories.firstWhere(
                    (c) => c.id == item.categoryId,
                    orElse: () => Category(
                      id: 'other',
                      name: 'Other',
                      iconAsset: 'assets/icons/tag.svg',
                      colorHex: '#7A9E5A',
                    ),
                  );
                  final catColor = AppColors.getCategoryColor(cat.name, cat.colorHex);

                  final now = DateTime.now();
                  final currentMonthKey = DateFormat('yyyy-MM').format(now);
                  final isPaid = allExpenses.any((e) =>
                    e.isFromRecurring &&
                    e.categoryId == item.categoryId &&
                    DateFormat('yyyy-MM').format(e.date) == currentMonthKey
                  );

                  return SwipeableRecurringCard(
                    onEdit: () => _showAddEditRecurringSheet(context, editItem: item),
                    onDelete: () async {
                      await ref.read(recurringExpensesProvider.notifier).deleteRecurringExpense(item.id);
                      await NotificationService.cancelNotification(item.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.label} deleted'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: GestureDetector(
                      onTap: () {
                        if (isPaid) {
                          // Tap Paid: open CategoryDetailScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryDetailScreen(category: cat),
                            ),
                          );
                        } else {
                          // Tap Due/Overdue: open Quick Add pre-filled
                          _openQuickAddSheet(context, item);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceCardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE8E4DA),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(
                                        cat.iconAsset.isNotEmpty ? cat.iconAsset : 'assets/icons/tag.svg',
                                        colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      item.label,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${settings.currency} ${NumberFormat('#,##0').format(item.amount)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontFamily: 'Space Grotesk',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Due on ${_getOrdinalDay(item.dueDay)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                                _buildStatusPill(item, allExpenses),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _getOrdinalDay(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}

class SwipeableRecurringCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SwipeableRecurringCard({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<SwipeableRecurringCard> createState() => _SwipeableRecurringCardState();
}

class _SwipeableRecurringCardState extends State<SwipeableRecurringCard> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  final double _maxDragWidth = 110.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(-_maxDragWidth, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset < -_maxDragWidth / 2) {
      setState(() {
        _dragOffset = -_maxDragWidth;
      });
    } else {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  void _reset() {
    setState(() {
      _dragOffset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: isDark ? AppColors.primaryDark : AppColors.primary),
                  onPressed: () {
                    _reset();
                    widget.onEdit();
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: () {
                    _reset();
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
