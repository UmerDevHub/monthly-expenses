import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'amount_input.dart';
import 'category_chip.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final double? initialAmount;
  final bool isFromRecurring;

  const QuickAddSheet({
    super.key,
    this.initialCategoryId,
    this.initialAmount,
    this.isFromRecurring = false,
  });

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  
  bool _isNoteExpanded = false;
  bool _isSaving = false;
  bool _showCategoryWarning = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0.0;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) return 'Today';
    if (compareDate == yesterday) return 'Yesterday';
    return DateFormat('d MMMM yyyy').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.surfaceCardDark,
                    onSurface: AppColors.textPrimaryDark,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    surface: Colors.white,
                    onSurface: AppColors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddCategoryDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nameController = TextEditingController();
    
    String selectedIcon = 'assets/icons/tag.svg';
    String selectedColorHex = '#7A9E5A';

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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceCardDark : Colors.white,
              title: Text(
                'Create Category',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
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
                    Text(
                      'Choose Icon',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                     const SizedBox(height: 8),
                     Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: presetIcons.map((icon) {
                         final isSelected = selectedIcon == icon;
                         return GestureDetector(
                           onTap: () {
                             setDialogState(() {
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
                         );
                       }).toList(),
                     ),
                     const SizedBox(height: 20),
                     Text(
                       'Choose Color',
                       style: theme.textTheme.labelMedium?.copyWith(
                         color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                       ),
                     ),
                     const SizedBox(height: 8),
                     Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: presetColors.map((hex) {
                         final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                         final isSelected = selectedColorHex == hex;
                         return GestureDetector(
                           onTap: () {
                             setDialogState(() {
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
                         );
                       }).toList(),
                     ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    
                    final newCategory = Category(
                      id: name.toLowerCase().replaceAll(' ', '_') + DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      iconAsset: selectedIcon,
                      colorHex: selectedColorHex,
                      isDefault: false,
                    );
                    
                    ref.read(categoriesProvider.notifier).addCategory(newCategory);
                    setState(() {
                      _selectedCategoryId = newCategory.id;
                      _showCategoryWarning = false;
                    });
                    
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Create',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveExpense() async {
    if (_amount <= 0.0) return;
    
    if (_selectedCategoryId == null) {
      setState(() {
        _showCategoryWarning = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Simulate 200ms delay for visual feedback/acknowledgement
    await Future.delayed(const Duration(milliseconds: 200));

    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: _selectedCategoryId!,
      amount: _amount,
      date: _selectedDate,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      isFromRecurring: widget.isFromRecurring,
    );

    await ref.read(expensesProvider.notifier).addExpense(newExpense);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final settings = ref.watch(appSettingsProvider);
    final categories = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 1. Drag Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE8E4DA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Amount Input Hero
                    AmountInput(
                      controller: _amountController,
                      currency: settings.currency,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    
                    // Category Header & Row
                    Text(
                      'Category',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Horizontal scroll of category chips
                    SizedBox(
                      height: 84,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length + 1,
                        itemBuilder: (context, idx) {
                          if (idx == categories.length) {
                            // Last chip: Add category "+"
                            return Padding(
                              key: const ValueKey('add_new_category_chip'),
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: _showAddCategoryDialog,
                                child: Container(
                                  width: 72,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceCardDark : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : const Color(0xFFE8E4DA),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'New',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          final cat = categories[idx];
                          final isSelected = _selectedCategoryId == cat.id;
                          return Padding(
                            key: ValueKey(cat.id),
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CategoryChip(
                              category: cat,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = cat.id;
                                  _showCategoryWarning = false;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Subtle category validation warning
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: _showCategoryWarning
                          ? const Padding(
                              padding: EdgeInsets.only(top: 8.0, left: 4.0),
                              child: Text(
                                'Select a category first to save',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Collapsible note section
                    AnimatedCrossFade(
                      firstChild: GestureDetector(
                        onTap: () => setState(() => _isNoteExpanded = true),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: isDark ? AppColors.primaryDark : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add a note',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              hintText: 'What was this expense for?',
                              hintStyle: TextStyle(
                                color: isDark ? AppColors.textSecondaryDark.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: isDark ? AppColors.surfaceCardDark : const Color(0xFFF7F5F0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: TextStyle(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      crossFadeState: _isNoteExpanded 
                          ? CrossFadeState.showSecond 
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                    const SizedBox(height: 24),
                    
                    // Date picker row
                    Text(
                      'Date',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceCardDark : const Color(0xFFF7F5F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(_selectedDate),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_amount <= 0.0 || _isSaving) ? null : _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.40),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Expense',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
