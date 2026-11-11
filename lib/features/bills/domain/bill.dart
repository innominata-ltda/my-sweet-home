import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

typedef BillId = String;

/// Conta fixa (RN-130).
class Bill {
  final BillId id;
  final String title;
  final CategoryId categoryId;
  final int dueDay;
  final RecurrenceRule recurrence;
  final Money? amount;
  final bool isEstimated;
  final int noticeDays;
  final bool isPaused;

  const Bill({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.dueDay,
    required this.recurrence,
    this.amount,
    required this.isEstimated,
    this.noticeDays = 3,
    this.isPaused = false,
  });

  Bill copyWith({bool? isPaused}) {
    return Bill(
      id: id,
      title: title,
      categoryId: categoryId,
      dueDay: dueDay,
      recurrence: recurrence,
      amount: amount,
      isEstimated: isEstimated,
      noticeDays: noticeDays,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bill &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          categoryId == other.categoryId &&
          dueDay == other.dueDay &&
          recurrence == other.recurrence &&
          amount == other.amount &&
          isEstimated == other.isEstimated &&
          noticeDays == other.noticeDays &&
          isPaused == other.isPaused;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      categoryId.hashCode ^
      dueDay.hashCode ^
      recurrence.hashCode ^
      amount.hashCode ^
      isEstimated.hashCode ^
      noticeDays.hashCode ^
      isPaused.hashCode;
}

class NewBill {
  final BillId? id;
  final String title;
  final CategoryId categoryId;
  final int dueDay;
  final RecurrenceRule recurrence;
  final Money? amount;
  final bool isEstimated;
  final int noticeDays;

  const NewBill({
    this.id,
    required this.title,
    required this.categoryId,
    required this.dueDay,
    required this.recurrence,
    this.amount,
    required this.isEstimated,
    this.noticeDays = 3,
  });
}
