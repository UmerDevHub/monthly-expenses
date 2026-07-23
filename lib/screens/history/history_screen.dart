import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        if (_selectedFilter == 'Settings' && !type.contains('settings')) return false;
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
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    for (var log in filteredLogs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.timestamp);
      if (!groupedLogs.containsKey(dateKey)) {
        groupedLogs[dateKey] = [];
      }
      groupedLogs[dateKey]!.add(log);
    }

    final sortedDateKeys = groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF9F9F8),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE5E5E3),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
                      onPressed: widget.onBackTap,
                    ),
                  ),
                  Text(
                    'Activity History',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF073826),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE5E5E3),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                      onPressed: historyLogs.isEmpty ? null : () => _confirmClearHistory(context),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : const Color(0xFF222222)),
                  decoration: InputDecoration(
                    hintText: 'Search activity logs...',
                    hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : const Color(0xFF999999)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF073826)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Row(
                children: ['All', 'Expenses', 'Categories', 'Bills', 'Settings'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF073826)
                              : (isDark ? AppColors.surfaceCardDark : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF073826)
                                : (isDark ? AppColors.borderDark : const Color(0xFFE5E5E3)),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.textPrimaryDark : const Color(0xFF444444)),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // 4. Main History Timeline List or Empty State
            Expanded(
              child: historyLogs.isEmpty
                  ? _buildInitialEmptyState(theme, isDark)
                  : filteredLogs.isEmpty
                      ? _buildNoSearchResultState(theme, isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          physics: const BouncingScrollPhysics(),
                          itemCount: sortedDateKeys.length,
                          itemBuilder: (context, idx) {
                            final dateKey = sortedDateKeys[idx];
                            final list = groupedLogs[dateKey]!;
                            final parsedDate = DateTime.parse(dateKey);

                            String headerTitle = '';
                            if (dateKey == todayStr) {
                              headerTitle = 'Today • ${DateFormat('d MMMM').format(parsedDate)}';
                            } else if (dateKey == yesterdayStr) {
                              headerTitle = 'Yesterday • ${DateFormat('d MMMM').format(parsedDate)}';
                            } else {
                              headerTitle = DateFormat('d MMMM yyyy').format(parsedDate);
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0),
                                  child: Text(
                                    headerTitle,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF757575),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceCardDark : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : const Color(0xFFF0F0EE),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: list.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: isDark ? AppColors.borderDark : const Color(0xFFF2F2F0),
                                    ),
                                    itemBuilder: (context, subIdx) {
                                      final record = list[subIdx];
                                      return _buildHistoryRow(record, theme, isDark);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),
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

  Widget _buildHistoryRow(HistoryRecord record, ThemeData theme, bool isDark) {
    IconData icon = Icons.history_rounded;
    Color iconColor = const Color(0xFF073826);
    Color bgColor = const Color(0xFFE8F5E9);

    final type = record.actionType.toLowerCase();
    if (type == 'expense_added') {
      icon = Icons.add_circle_outline_rounded;
      iconColor = const Color(0xFF073826);
      bgColor = const Color(0xFFE8F5E9);
    } else if (type == 'expense_edited') {
      icon = Icons.edit_note_rounded;
      iconColor = const Color(0xFFE67E22);
      bgColor = const Color(0xFFFFF3E0);
    } else if (type == 'expense_deleted') {
      icon = Icons.delete_outline_rounded;
      iconColor = AppColors.danger;
      bgColor = const Color(0xFFFCE8E9);
    } else if (type.contains('category')) {
      icon = Icons.category_rounded;
      iconColor = const Color(0xFF6B4EFF);
      bgColor = const Color(0xFFF0EAFA);
    } else if (type.contains('recurring')) {
      icon = Icons.event_repeat_rounded;
      iconColor = const Color(0xFF00838F);
      bgColor = const Color(0xFFE0F7FA);
    } else if (type.contains('settings')) {
      icon = Icons.tune_rounded;
      iconColor = const Color(0xFF555555);
      bgColor = const Color(0xFFEEEEEE);
    }

    final timeStr = DateFormat('hh:mm a').format(record.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withOpacity(0.2) : bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E2522),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF073826).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 42,
                color: Color(0xFF073826),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Activity History Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF073826),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activity history is automatically recorded when you log expenses, update budgets, or adjust settings.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onAddExpenseTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Your First Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF073826),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 52, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No matching history records',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
          title: const Text('Clear Activity History?'),
          content: const Text('This will permanently clear all recorded activity logs. Your actual expenses and settings will remain intact.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(historyLogProvider.notifier).clearHistory();
                Navigator.pop(context);
              },
              child: const Text('Clear', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        );
      },
    );
  }
}
