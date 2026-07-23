import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';

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
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final historyLogs = ref.watch(historyLogProvider);

    // Filter logs
    final filteredLogs = historyLogs.where((log) {
      if (_selectedFilter != 'All') {
        final type = log.actionType.toLowerCase();
        if (_selectedFilter == 'Expenses' && !type.contains('expense')) return false;
        if (_selectedFilter == 'Categories' && !type.contains('category')) return false;
        if (_selectedFilter == 'Bills' && !type.contains('recurring')) return false;
        if (_selectedFilter == 'Settings' && !type.contains('settings') && !type.contains('backup')) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = log.title.toLowerCase().contains(q);
        final matchDesc = log.description.toLowerCase().contains(q);
        return matchTitle || matchDesc;
      }

      return true;
    }).toList();

    // Group logs by date
    final Map<String, List<HistoryRecord>> groupedLogs = {};
    for (var log in filteredLogs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.timestamp);
      if (!groupedLogs.containsKey(dateKey)) {
        groupedLogs[dateKey] = [];
      }
      groupedLogs[dateKey]!.add(log);
    }

    final sortedDateKeys = groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BouncingButton(
                    onTap: widget.onBackTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceCardDark : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  Text(
                    'Activity History',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (historyLogs.isNotEmpty)
                    BouncingButton(
                      onTap: () => _confirmClearHistory(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.danger),
                            SizedBox(width: 4),
                            Text(
                              'Clear',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // 2. Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                  boxShadow: AppShadows.softLight,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search actions, notes, amounts...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primaryAccent),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // 3. Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: ['All', 'Expenses', 'Categories', 'Bills', 'Settings'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: BouncingButton(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.surfaceCardDark : Colors.white),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.borderDark : AppColors.border),
                          ),
                          boxShadow: isSelected ? AppShadows.heroGlow : null,
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // 4. Timeline List / Empty State
            Expanded(
              child: filteredLogs.isEmpty
                  ? CustomEmptyState(
                      title: 'No Activity History',
                      description: historyLogs.isEmpty
                          ? 'Your actions (adding expenses, editing budgets) will automatically build an audit timeline here.'
                          : 'No history logs found matching "$_searchQuery".',
                      icon: Icons.history_rounded,
                      buttonText: historyLogs.isEmpty ? 'Log First Expense' : null,
                      onButtonPressed: historyLogs.isEmpty ? widget.onAddExpenseTap : null,
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: sortedDateKeys.length,
                      itemBuilder: (context, dateIdx) {
                        final dateKey = sortedDateKeys[dateIdx];
                        final dayLogs = groupedLogs[dateKey]!;
                        final parsedDate = DateTime.parse(dateKey);

                        final now = DateTime.now();
                        String dateHeader;
                        if (DateFormat('yyyy-MM-dd').format(now) == dateKey) {
                          dateHeader = 'Today';
                        } else if (DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1))) == dateKey) {
                          dateHeader = 'Yesterday';
                        } else {
                          dateHeader = DateFormat('EEEE, dd MMMM yyyy').format(parsedDate);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Section Header
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                              child: Row(
                                children: [
                                  CustomPillBadge(
                                    label: dateHeader,
                                    color: AppColors.primaryAccent,
                                    icon: Icons.calendar_month_outlined,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? AppColors.borderDark : AppColors.border,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Day's Log Cards
                            ...dayLogs.map((log) => _buildHistoryCard(context, log, isDark, theme)),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryRecord log, bool isDark, ThemeData theme) {
    IconData icon;
    Color iconColor;

    final actionLower = log.actionType.toLowerCase();
    if (actionLower.contains('add')) {
      icon = Icons.add_circle_outline_rounded;
      iconColor = AppColors.primaryAccent;
    } else if (actionLower.contains('delete') || actionLower.contains('clear')) {
      icon = Icons.delete_outline_rounded;
      iconColor = AppColors.danger;
    } else if (actionLower.contains('edit') || actionLower.contains('update')) {
      icon = Icons.edit_note_rounded;
      iconColor = AppColors.accentWarning;
    } else if (actionLower.contains('backup') || actionLower.contains('restore')) {
      icon = Icons.cloud_sync_rounded;
      iconColor = AppColors.info;
    } else {
      icon = Icons.receipt_long_rounded;
      iconColor = AppColors.primary;
    }

    final timeStr = DateFormat('hh:mm a').format(log.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          log.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Clear Activity Logs?'),
          content: const Text('This action will erase all activity history entries. Your expense records will remain untouched.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Clear All Logs'),
              onPressed: () {
                ref.read(historyLogProvider.notifier).clearAllLogs();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity history cleared successfully.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
