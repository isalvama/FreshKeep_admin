part of 'dashboard_bloc.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

/// The URL's range changed (or the page opened). Reloads the daily sections;
/// product types load on the first one only.
final class DashboardRangeChanged extends DashboardEvent {
  final DashboardRange range;

  const DashboardRangeChanged(this.range);
}

/// The Refresh button: reloads all four sections.
final class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

/// A card's Retry button: reloads that section only.
final class DashboardSectionRetried extends DashboardEvent {
  final DashboardSection section;

  const DashboardSectionRetried(this.section);
}
