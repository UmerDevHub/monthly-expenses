// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      note: fields[4] as String?,
      isFromRecurring: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.isFromRecurring);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 1;

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      id: fields[0] as String,
      name: fields[1] as String,
      iconAsset: fields[2] as String,
      colorHex: fields[3] as String,
      monthlyLimit: fields[4] as double?,
      isDefault: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconAsset)
      ..writeByte(3)
      ..write(obj.colorHex)
      ..writeByte(4)
      ..write(obj.monthlyLimit)
      ..writeByte(5)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurringExpenseAdapter extends TypeAdapter<RecurringExpense> {
  @override
  final int typeId = 2;

  @override
  RecurringExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringExpense(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      amount: fields[2] as double,
      dueDay: fields[3] as int,
      label: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringExpense obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.dueDay)
      ..writeByte(4)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MonthlyInsightAdapter extends TypeAdapter<MonthlyInsight> {
  @override
  final int typeId = 3;

  @override
  MonthlyInsight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlyInsight(
      monthKey: fields[0] as String,
      insights: (fields[1] as List).cast<String>(),
      generatedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlyInsight obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.monthKey)
      ..writeByte(1)
      ..write(obj.insights)
      ..writeByte(2)
      ..write(obj.generatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyInsightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      currency: fields[0] as String,
      overallMonthlyLimit: fields[1] as double?,
      appLockEnabled: fields[2] as bool,
      darkMode: fields[3] as bool,
      geminiApiKey: fields[4] as String?,
      userName: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.currency)
      ..writeByte(1)
      ..write(obj.overallMonthlyLimit)
      ..writeByte(2)
      ..write(obj.appLockEnabled)
      ..writeByte(3)
      ..write(obj.darkMode)
      ..writeByte(4)
      ..write(obj.geminiApiKey)
      ..writeByte(5)
      ..write(obj.userName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
