import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';
import 'package:my_sweet_home/features/tasks/presentation/calendar_page.dart';

class MonthView extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime today;
  final List<Task> tasks;
  final List<CalendarBill> bills;
  final ValueChanged<DateTime>? onDaySelected;

  const MonthView({
    super.key,
    required this.focusedMonth,
    required this.today,
    this.tasks = const [],
    this.bills = const [],
    this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );
    final firstDayOfMonth = DateTime.utc(focusedMonth.year, focusedMonth.month);

    // Weekday 1 is Monday, 7 is Sunday.
    final firstWeekday = firstDayOfMonth.weekday;
    final leadingEmptyDays = firstWeekday - 1;

    final totalDaysToShow = leadingEmptyDays + daysInMonth;
    final rows = (totalDaysToShow / 7).ceil();
    final totalCells = rows * 7;

    return Column(
      children: [
        _buildDaysOfWeek(context),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays ||
                  index >= leadingEmptyDays + daysInMonth) {
                return const SizedBox.shrink();
              }

              final day = index - leadingEmptyDays + 1;
              final date = DateTime.utc(
                focusedMonth.year,
                focusedMonth.month,
                day,
              );

              final tasksForDay = tasks.where((t) {
                if (t.dueAt == null) return false;
                final dateDue = t.allDay ? t.dueAt! : t.dueAt!.toLocal();
                return dateDue.year == date.year &&
                    dateDue.month == date.month &&
                    dateDue.day == date.day;
              }).toList();

              final billsForDay = bills.where((b) {
                final due = b.dueOn;
                return due.year == date.year &&
                    due.month == date.month &&
                    due.day == date.day;
              }).toList();

              return _MonthDayCell(
                date: date,
                today: today,
                tasksCount: tasksForDay.length,
                billsCount: billsForDay.length,
                onTap: () => onDaySelected?.call(date),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDaysOfWeek(BuildContext context) {
    // We can use an arbitrary Monday to get Monday-Sunday names
    final monday = DateTime.utc(2023, 10, 2); // 2023-10-02 is a Monday

    return Row(
      children: List.generate(7, (index) {
        final day = monday.add(Duration(days: index));
        final format = DateFormat.E(
          Localizations.localeOf(context).languageCode,
        );
        return Expanded(
          child: Center(
            child: Text(
              format.format(day),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        );
      }),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final int tasksCount;
  final int billsCount;
  final VoidCallback onTap;

  const _MonthDayCell({
    required this.date,
    required this.today,
    required this.tasksCount,
    this.billsCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, today);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tasksCount > 0)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$tasksCount',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (tasksCount > 0 && billsCount > 0)
                      const SizedBox(width: 2),
                    if (billsCount > 0)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$billsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
