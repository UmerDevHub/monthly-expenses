import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/hive_service.dart';

// Selected Month Provider (Format: "yyyy-MM")
final selectedMonthProvider = StateProvider<String>((ref) {
  // Let's lock it to 2026-07 initially to match the screenshot, or use the current real month.
  // The current date in metadata is July 2026, so 2026-07 is perfect.
  return '2026-07';
});

// App Settings Provider
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(HiveService.settingsBox.get('app_settings') ?? AppSettings());

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    await HiveService.settingsBox.put('app_settings', newSettings);
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

// Categories Provider
class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier() : super(HiveService.categoriesBox.values.toList());

  Future<void> addCategory(Category category) async {
    await HiveService.categoriesBox.put(category.id, category);
    state = HiveService.categoriesBox.values.toList();
  }

  Future<void> updateCategory(Category category) async {
    await HiveService.categoriesBox.put(category.id, category);
    state = HiveService.categoriesBox.values.toList();
  }

  Future<void> deleteCategory(String id) async {
    await HiveService.categoriesBox.delete(id);
    state = HiveService.categoriesBox.values.toList();
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  return CategoriesNotifier();
});

// Expenses Provider
class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier() : super([]) {
    _loadExpenses();
  }

  void _loadExpenses() {
    final box = HiveService.expensesBox;
    if (box.isEmpty) {
      // Seed the mock expenses matching the screenshot so the dashboard looks beautiful instantly
      final seedExpenses = [
        // Today - 16 Jul
        Expense(
          id: 'exp1',
          categoryId: 'khana',
          amount: 320,
          date: DateTime(2026, 7, 16, 12, 45),
          note: 'Dopahar ka khana',
        ),
        Expense(
          id: 'exp2',
          categoryId: 'petrol',
          amount: 500,
          date: DateTime(2026, 7, 16, 9, 15),
          note: 'Bike fuel',
        ),
        // Yesterday - 15 Jul
        Expense(
          id: 'exp3',
          categoryId: 'sim_bill',
          amount: 350,
          date: DateTime(2026, 7, 15, 20, 30),
          note: 'Jazz Monthly Package',
        ),
        // 14 Jul
        Expense(
          id: 'exp4',
          categoryId: 'room_rent',
          amount: 15000,
          date: DateTime(2026, 7, 14, 11, 20),
          note: 'July room rent',
        ),
        // Additional items to reach the screenshot numbers:
        // Petrol target: 8,450. (Current: 500). Needs 7,950
        Expense(
          id: 'exp_petrol_bulk',
          categoryId: 'petrol',
          amount: 7950,
          date: DateTime(2026, 7, 10, 18, 00),
          note: 'Car fuel refill',
        ),
        // Khana target: 6,320. (Current: 320). Needs 6,000
        Expense(
          id: 'exp_khana_bulk',
          categoryId: 'khana',
          amount: 6000,
          date: DateTime(2026, 7, 8, 21, 30),
          note: 'Grocery & weekly dinner',
        ),
        // Sim Bill target: 1,050. (Current: 350). Needs 700
        Expense(
          id: 'exp_sim_bulk',
          categoryId: 'sim_bill',
          amount: 700,
          date: DateTime(2026, 7, 1, 10, 00),
          note: 'Office Sim Card DSL',
        ),
        // Bike Maintenance target: 2,800. Needs 2,800
        Expense(
          id: 'exp_bike_bulk',
          categoryId: 'bike_maintenance',
          amount: 2800,
          date: DateTime(2026, 7, 12, 14, 00),
          note: 'Tuning & Engine Oil',
        ),
        // Custom Category / Other target to hit Rs. 42,350 total.
        // Current sum: 8450 (Petrol) + 6320 (Khana) + 15000 (Rent) + 1050 (Sim) + 2800 (Bike) = 33,620.
        // We need 8,730 more. Let's place it in a custom category "Shopping" (id: custom_shopping)
        Expense(
          id: 'exp_shopping_bulk',
          categoryId: 'custom_shopping',
          amount: 8730,
          date: DateTime(2026, 7, 5, 16, 45),
          note: 'New clothes & shoes',
        ),
      ];

      // Also need to create the custom category "Shopping" so it renders correctly
      final categoriesBox = HiveService.categoriesBox;
      if (!categoriesBox.containsKey('custom_shopping')) {
        final shoppingCat = Category(
          id: 'custom_shopping',
          name: 'Shopping',
          iconAsset: 'assets/icons/tag.svg',
          colorHex: '#7A9E5A',
          monthlyLimit: 12000.0,
          isDefault: false,
        );
        categoriesBox.put(shoppingCat.id, shoppingCat);
      }

      for (var exp in seedExpenses) {
        box.put(exp.id, exp);
      }
    }
    state = box.values.toList();
  }

  Future<void> addExpense(Expense expense) async {
    await HiveService.expensesBox.put(expense.id, expense);
    state = HiveService.expensesBox.values.toList();
  }

  Future<void> updateExpense(Expense expense) async {
    await HiveService.expensesBox.put(expense.id, expense);
    state = HiveService.expensesBox.values.toList();
  }

  Future<void> deleteExpense(String id) async {
    await HiveService.expensesBox.delete(id);
    state = HiveService.expensesBox.values.toList();
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  return ExpensesNotifier();
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
      // Find category in hive or create a fallback
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

  // Filter out categories with 0 spent unless they are default categories (keep defaults visible)
  return summaries.where((s) => s.category.isDefault || s.spent > 0).toList();
});
