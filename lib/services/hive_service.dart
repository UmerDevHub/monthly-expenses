import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class HiveService {
  static const String expensesBoxName = 'expenses';
  static const String categoriesBoxName = 'categories';
  static const String recurringBoxName = 'recurring_expenses';
  static const String insightsBoxName = 'monthly_insights';
  static const String settingsBoxName = 'app_settings';
  static const String historyBoxName = 'history_records';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Type Adapters
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(RecurringExpenseAdapter());
    Hive.registerAdapter(MonthlyInsightAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(HistoryRecordAdapter());

    // Open Boxes
    await Hive.openBox<Expense>(expensesBoxName);
    await Hive.openBox<Category>(categoriesBoxName);
    await Hive.openBox<RecurringExpense>(recurringBoxName);
    await Hive.openBox<MonthlyInsight>(insightsBoxName);
    await Hive.openBox<AppSettings>(settingsBoxName);
    await Hive.openBox<HistoryRecord>(historyBoxName);

    // Seed default database if empty
    await seedDefaultData();
  }

  static Future<void> seedDefaultData() async {
    final categoriesBox = Hive.box<Category>(categoriesBoxName);
    if (categoriesBox.isEmpty) {
      final defaultCategories = [
        Category(
          id: 'petrol',
          name: 'Petrol',
          iconAsset: 'assets/icons/petrol.svg',
          colorHex: '#C9822E',
          monthlyLimit: 500.0,
          isDefault: true,
        ),
        Category(
          id: 'khana',
          name: 'Khana',
          iconAsset: 'assets/icons/food.svg',
          colorHex: '#6B8E5A',
          monthlyLimit: 1000.0,
          isDefault: true,
        ),
        Category(
          id: 'room_rent',
          name: 'Room Rent',
          iconAsset: 'assets/icons/rent.svg',
          colorHex: '#5A7A9E',
          monthlyLimit: 1500.0,
          isDefault: true,
        ),
        Category(
          id: 'sim_bill',
          name: 'Sim Bill',
          iconAsset: 'assets/icons/sim.svg',
          colorHex: '#9E7A5A',
          monthlyLimit: 200.0,
          isDefault: true,
        ),
        Category(
          id: 'bike_maintenance',
          name: 'Bike Maintenance',
          iconAsset: 'assets/icons/bike.svg',
          colorHex: '#8E5A7A',
          monthlyLimit: 300.0,
          isDefault: true,
        ),
      ];

      for (var cat in defaultCategories) {
        await categoriesBox.put(cat.id, cat);
      }
    }

    final settingsBox = Hive.box<AppSettings>(settingsBoxName);
    if (settingsBox.isEmpty) {
      final defaultSettings = AppSettings(
        currency: 'QAR',
        overallMonthlyLimit: 5000.0,
        appLockEnabled: false,
        darkMode: false,
      );
      await settingsBox.put('app_settings', defaultSettings);
    }

  }

  static Box<Expense> get expensesBox => Hive.box<Expense>(expensesBoxName);
  static Box<Category> get categoriesBox => Hive.box<Category>(categoriesBoxName);
  static Box<RecurringExpense> get recurringBox => Hive.box<RecurringExpense>(recurringBoxName);
  static Box<MonthlyInsight> get insightsBox => Hive.box<MonthlyInsight>(insightsBoxName);
  static Box<AppSettings> get settingsBox => Hive.box<AppSettings>(settingsBoxName);
  static Box<HistoryRecord> get historyBox => Hive.box<HistoryRecord>(historyBoxName);
}

