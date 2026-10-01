import 'package:equatable/equatable.dart';

import '../utils/calendar_day.dart';

/// The backend rejects metric ranges where `to − from` exceeds this.
const kMaxRangeLengthInDays = 100;

/// An inclusive range of calendar days (see [calendarDay]).
class DateRange extends Equatable {
  final DateTime from;
  final DateTime to;

  DateRange({required DateTime from, required DateTime to})
    : from = calendarDay(from),
      to = calendarDay(to),
      assert(!from.isAfter(to), 'from must not be after to');

  /// `to − from` in days, the measure the backend's 100-day limit uses.
  int get lengthInDays => to.difference(from).inDays;

  /// Every day from [from] to [to], inclusive.
  List<DateTime> get days => [
    for (var i = 0; i <= lengthInDays; i++)
      DateTime.utc(from.year, from.month, from.day + i),
  ];

  @override
  List<Object?> get props => [from, to];
}
