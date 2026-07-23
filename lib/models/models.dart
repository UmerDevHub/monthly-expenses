import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final bool isFromRecurring;

  Expense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note,
    this.isFromRecurring = false,
  });

  Expense copyWith({
    String? id,
    String? categoryId,
    double? amount,
    DateTime? date,
    String? note,
    bool? isFromRecurring,
  }) {
    return Expense(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      isFromRecurring: isFromRecurring ?? this.isFromRecurring,
    );
  }
}

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String iconAsset; // path to custom svg

  @HiveField(3)
  final String colorHex;

  @HiveField(4)
  final double? monthlyLimit;

  @HiveField(5)
  final bool isDefault; // true for the 5 fixed ones

  Category({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.colorHex,
    this.monthlyLimit,
    this.isDefault = false,
  });

  Category copyWith({
    String? id,
    String? name,
    String? iconAsset,
    String? colorHex,
    double? monthlyLimit,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      colorHex: colorHex ?? this.colorHex,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

@HiveType(typeId: 2)
class RecurringExpense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final int dueDay; // day of month

  @HiveField(4)
  final String label;

  RecurringExpense({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.dueDay,
    required this.label,
  });

  RecurringExpense copyWith({
    String? id,
    String? categoryId,
    double? amount,
    int? dueDay,
    String? label,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      dueDay: dueDay ?? this.dueDay,
      label: label ?? this.label,
    );
  }
}

@HiveType(typeId: 3)
class MonthlyInsight extends HiveObject {
  @HiveField(0)
  final String monthKey; // "2026-07"

  @HiveField(1)
  final List<String> insights;

  @HiveField(2)
  final DateTime generatedAt;

  MonthlyInsight({
    required this.monthKey,
    required this.insights,
    required this.generatedAt,
  });
}

@HiveType(typeId: 4)
class AppSettings extends HiveObject {
  @HiveField(0)
  final String currency; // "PKR"

  @HiveField(1)
  final double? overallMonthlyLimit;

  @HiveField(2)
  final bool appLockEnabled;

  @HiveField(3)
  final bool darkMode;

  @HiveField(4)
  final String? geminiApiKey;

  @HiveField(5)
  final String userName;

  AppSettings({
    this.currency = 'QAR',
    this.overallMonthlyLimit,
    this.appLockEnabled = false,
    this.darkMode = false,
    this.geminiApiKey,
    this.userName = 'Umer Nisar',
  });

  AppSettings copyWith({
    String? currency,
    double? overallMonthlyLimit,
    bool? appLockEnabled,
    bool? darkMode,
    String? geminiApiKey,
    String? userName,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      overallMonthlyLimit: overallMonthlyLimit ?? this.overallMonthlyLimit,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      darkMode: darkMode ?? this.darkMode,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      userName: userName ?? this.userName,
    );
  }
}

@HiveType(typeId: 5)
class HistoryRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String actionType; // 'expense_added', 'expense_edited', 'expense_deleted', 'category_added', 'category_edited', 'category_deleted', 'recurring_added', 'recurring_deleted', 'recurring_paid', 'settings_updated'

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? colorHex;

  HistoryRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
    required this.timestamp,
    this.colorHex,
  });
}

