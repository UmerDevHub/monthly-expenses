import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/hive_service.dart';
import '../utils/currency_formatter.dart';

// Selected Month Provider (Format: "yyyy-MM")
final selectedMonthProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

// App Settings Provider
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;
  AppSettingsNotifier(this._ref) : super(HiveService.settingsBox.get('app_settings') ?? AppSettings());

  Future<void> updateSettings(AppSettings newSettings) async {
    final oldSettings = state;
    state = newSettings;
    await HiveService.settingsBox.put('app_settings', newSettings);

    // Log to History
    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Settings Updated',
      description: 'Updated currency to ${newSettings.currency}, monthly limit to ${newSettings.overallMonthlyLimit ?? "Unlimited"}',
      actionType: 'settings_updated',
    );
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref);
});

// History Log Provider
class HistoryLogNotifier extends StateNotifier<List<HistoryRecord>> {
  HistoryLogNotifier() : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    final list = HiveService.historyBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = list;
  }

  Future<void> addLog({
    required String title,
    required String description,
    required String actionType,
    String? colorHex,
  }) async {
    final record = HistoryRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      actionType: actionType,
      timestamp: DateTime.now(),
      colorHex: colorHex,
    );
    await HiveService.historyBox.put(record.id, record);
    _loadHistory();
  }

  Future<void> clearHistory() async {
    await HiveService.historyBox.clear();
    state = [];
  }
}

final historyLogProvider = StateNotifierProvider<HistoryLogNotifier, List<HistoryRecord>>((ref) {
  return HistoryLogNotifier();
});

// Categories Provider
class CategoriesNotifier extends StateNotifier<List<Category>> {
  final Ref _ref;
  CategoriesNotifier(this._ref) : super(HiveService.categoriesBox.values.toList());

  Future<void> addCategory(Category category) async {
    await HiveService.categoriesBox.put(category.id, category);
    state = HiveService.categoriesBox.values.toList();
    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Category Created',
      description: 'Added category "${category.name}"',
      actionType: 'category_added',
      colorHex: category.colorHex,
    );
  }

  Future<void> updateCategory(Category category) async {
    await HiveService.categoriesBox.put(category.id, category);
    state = HiveService.categoriesBox.values.toList();
    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Category Updated',
      description: 'Updated "${category.name}" details/limit',
      actionType: 'category_edited',
      colorHex: category.colorHex,
    );
  }

  Future<void> deleteCategory(String id) async {
    final cat = HiveService.categoriesBox.get(id);
    final catName = cat?.name ?? 'Category';
    await HiveService.categoriesBox.delete(id);
    state = HiveService.categoriesBox.values.toList();
    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Category Deleted',
      description: 'Removed category "$catName"',
      actionType: 'category_deleted',
    );
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  return CategoriesNotifier(ref);
});

// Expenses Provider
class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final Ref _ref;
  ExpensesNotifier(this._ref) : super([]) {
    _loadExpenses();
  }

  void _loadExpenses() {
    final box = HiveService.expensesBox;
    state = box.values.toList();
  }

  Future<void> addExpense(Expense expense) async {
    await HiveService.expensesBox.put(expense.id, expense);
    state = HiveService.expensesBox.values.toList();

    // Lookup Category Name
    final categories = _ref.read(categoriesProvider);
    final cat = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => Category(id: '', name: 'Expense', iconAsset: '', colorHex: ''),
    );
    final currency = _ref.read(appSettingsProvider).currency;
    final formattedAmt = CurrencyFormatter.format(expense.amount, currency, decimalDigits: 0);

    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Expense Added',
      description: '$formattedAmt in ${cat.name}${expense.note != null && expense.note!.isNotEmpty ? " (${expense.note})" : ""}',
      actionType: 'expense_added',
      colorHex: cat.colorHex,
    );
  }

  Future<void> updateExpense(Expense expense) async {
    await HiveService.expensesBox.put(expense.id, expense);
    state = HiveService.expensesBox.values.toList();

    final categories = _ref.read(categoriesProvider);
    final cat = categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => Category(id: '', name: 'Expense', iconAsset: '', colorHex: ''),
    );
    final currency = _ref.read(appSettingsProvider).currency;
    final formattedAmt = CurrencyFormatter.format(expense.amount, currency, decimalDigits: 0);

    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Expense Updated',
      description: '$formattedAmt in ${cat.name}',
      actionType: 'expense_edited',
      colorHex: cat.colorHex,
    );
  }

  Future<void> deleteExpense(String id) async {
    final exp = HiveService.expensesBox.get(id);
    double amount = exp?.amount ?? 0.0;
    await HiveService.expensesBox.delete(id);
    state = HiveService.expensesBox.values.toList();

    final currency = _ref.read(appSettingsProvider).currency;
    final formattedAmt = CurrencyFormatter.format(amount, currency, decimalDigits: 0);
    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Expense Deleted',
      description: 'Removed expense of $formattedAmt',
      actionType: 'expense_deleted',
    );
  }

}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  return ExpensesNotifier(ref);
});

// Computed provider: Expenses filtered by selected month
final monthlyExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider); // "yyyy-MM"
  
  return expenses.where((exp) {
    final year = exp.date.year;
    final month = exp.date.month.toString().padLeft(2, '0');
    return '$year-$month' == selectedMonth;
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date)); // Sort newest first
});

// Computed provider: Total spent in selected month
final totalSpentProvider = Provider<double>((ref) {
  final monthlyExpenses = ref.watch(monthlyExpensesProvider);
  return monthlyExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
});

// Category summary class
class CategorySummary {
  final Category category;
  final double spent;
  final double percentage;

  CategorySummary({
    required this.category,
    required this.spent,
    required this.percentage,
  });
}

// Computed provider: Category-wise breakdown of expenses for selected month
final categorySummariesProvider = Provider<List<CategorySummary>>((ref) {
  final monthlyExpenses = ref.watch(monthlyExpensesProvider);
  final categories = ref.watch(categoriesProvider);

  // Calculate spent per category
  final Map<String, double> categorySpent = {};
  for (var exp in monthlyExpenses) {
    categorySpent[exp.categoryId] = (categorySpent[exp.categoryId] ?? 0.0) + exp.amount;
  }

  final List<CategorySummary> summaries = [];
  for (var cat in categories) {
    final spent = categorySpent[cat.id] ?? 0.0;
    final limit = cat.monthlyLimit ?? 0.0;
    final percentage = limit > 0 ? (spent / limit) * 100 : 0.0;
    summaries.add(CategorySummary(
      category: cat,
      spent: spent,
      percentage: percentage,
    ));
  }

  // Include custom categories that are not default but have expenses
  for (var catId in categorySpent.keys) {
    if (!summaries.any((s) => s.category.id == catId)) {
      final cat = HiveService.categoriesBox.get(catId) ?? Category(
        id: catId,
        name: catId.replaceAll('_', ' '),
        iconAsset: 'assets/icons/tag.svg',
        colorHex: '#7A9E5A',
        isDefault: false,
      );
      final spent = categorySpent[catId] ?? 0.0;
      final limit = cat.monthlyLimit ?? 0.0;
      final percentage = limit > 0 ? (spent / limit) * 100 : 0.0;
      summaries.add(CategorySummary(
        category: cat,
        spent: spent,
        percentage: percentage,
      ));
    }
  }

  return summaries.where((s) => s.category.isDefault || s.spent > 0).toList();
});

// Recurring Expenses Provider
class RecurringExpensesNotifier extends StateNotifier<List<RecurringExpense>> {
  final Ref _ref;
  RecurringExpensesNotifier(this._ref) : super(HiveService.recurringBox.values.toList());

  Future<void> addRecurringExpense(RecurringExpense recurring) async {
    await HiveService.recurringBox.put(recurring.id, recurring);
    state = HiveService.recurringBox.values.toList();

    final currency = _ref.read(appSettingsProvider).currency;
    final formattedAmt = CurrencyFormatter.format(recurring.amount, currency, decimalDigits: 0);
    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Recurring Bill Added',
      description: 'Added "${recurring.label}" for $formattedAmt (Due day ${recurring.dueDay})',
      actionType: 'recurring_added',
    );
  }

  Future<void> deleteRecurringExpense(String id) async {
    final item = HiveService.recurringBox.get(id);
    final label = item?.label ?? 'Recurring Item';
    await HiveService.recurringBox.delete(id);
    state = HiveService.recurringBox.values.toList();

    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Recurring Bill Removed',
      description: 'Removed bill "$label"',
      actionType: 'recurring_deleted',
    );
  }

  Future<void> markPaid(RecurringExpense item) async {
    final currency = _ref.read(appSettingsProvider).currency;
    final formattedAmt = CurrencyFormatter.format(item.amount, currency, decimalDigits: 0);
    _ref.read(historyLogProvider.notifier).addLog(
      title: 'Bill Paid',
      description: 'Paid recurring bill "${item.label}" of $formattedAmt',
      actionType: 'recurring_paid',
    );
  }

}

final recurringExpensesProvider = StateNotifierProvider<RecurringExpensesNotifier, List<RecurringExpense>>((ref) {
  return RecurringExpensesNotifier(ref);
});
