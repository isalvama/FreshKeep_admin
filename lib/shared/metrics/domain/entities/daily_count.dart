import 'package:equatable/equatable.dart';

import '../utils/calendar_day.dart';

class DailyCount extends Equatable {
  final DateTime date; // a calendar day (see calendarDay)
  final int count;

  DailyCount({required DateTime date, required this.count})
    : date = calendarDay(date);

  @override
  List<Object?> get props => [date, count];
}
