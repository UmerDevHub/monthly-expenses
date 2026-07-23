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
      // 1. Filter Chip check
      if (_selectedFilter != 'All') {
        final type = log.actionType.toLowerCase();
        if (_selectedFilter == 'Expenses' && !type.contains('expense')) return false;
        if (_selectedFilter == 'Categories' && !type.contains('category')) return false;
        if (_selectedFilter == 'Bills' && !type.contains('recurring')) return false;
        if (_selectedFilter == 'Settings' && !type.contains('settings')) return false;
      }

      // 2. Search check
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
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                    'Activity History',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                      onPressed: historyLogs.isEmpty ? null : () => _confirmClearHistory(context),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search history...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: ['All', 'Expenses', 'Categories', 'Bills', 'Settings'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard,
                      onSelected: (val) => setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Main History List or Empty State
            Expanded(
              child: historyLogs.isEmpty
                  ? _buildInitialEmptyState(theme, isDark)
                  : filteredLogs.isEmpty
                      ? _buildNoSearchResultState(theme, isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                  child: Text(
                                    headerTitle,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Card(
                                  margin: EdgeInsets.zero,
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: list.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: isDark ? AppColors.borderDark : AppColors.border,
                                    ),
                                    itemBuilder: (context, subIdx) {
                                      final record = list[subIdx];
                                      return _buildHistoryRow(record, theme, isDark);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
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
    IconData icon = Icons.history;
    Color iconColor = AppColors.primary;

    final type = record.actionType.toLowerCase();
    if (type == 'expense_added') {
      icon = Icons.add_circle_outline;
      iconColor = AppColors.primary;
    } else if (type == 'expense_edited') {
      icon = Icons.edit_outlined;
      iconColor = AppColors.accentWarning;
    } else if (type == 'expense_deleted') {
      icon = Icons.delete_outline;
      iconColor = AppColors.danger;
    } else if (type.contains('category')) {
      icon = Icons.category_outlined;
      iconColor = const Color(0xFF5A7A9E);
    } else if (type.contains('recurring')) {
      icon = Icons.event_repeat;
      iconColor = const Color(0xFF8E5A7A);
    } else if (type.contains('settings')) {
      icon = Icons.settings_outlined;
      iconColor = Colors.grey;
    }

    final timeStr = DateFormat('hh:mm a').format(record.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
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
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Activity History Yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'History logs are created automatically when you add, edit, or delete expenses, categories, and settings.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onAddExpenseTap,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Your First Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
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
