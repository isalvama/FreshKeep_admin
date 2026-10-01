part of 'user_detail_bloc.dart';

/// The independently loaded parts of a user's page. [details] carries the
/// profile, spaces and receipts (one endpoint).
enum UserDetailSection { details, productsActivity, receiptsActivity }

class UserDetailState extends Equatable {
  final String userId;

  /// The last 30 days, resolved when the user was requested.
  final DateRange activityRange;
  final SectionState<UserDetails> details;

  /// The details request failed with a 400: unknown or malformed id.
  final bool userNotFound;
  final SectionState<List<DailyCount>> productsActivity;
  final SectionState<List<DailyCount>> receiptsActivity;

  const UserDetailState({
    required this.userId,
    required this.activityRange,
    this.details = const SectionState.loading(),
    this.userNotFound = false,
    this.productsActivity = const SectionState.loading(),
    this.receiptsActivity = const SectionState.loading(),
  });

  UserDetailState copyWith({
    SectionState<UserDetails>? details,
    bool? userNotFound,
    SectionState<List<DailyCount>>? productsActivity,
    SectionState<List<DailyCount>>? receiptsActivity,
  }) {
    return UserDetailState(
      userId: userId,
      activityRange: activityRange,
      details: details ?? this.details,
      userNotFound: userNotFound ?? this.userNotFound,
      productsActivity: productsActivity ?? this.productsActivity,
      receiptsActivity: receiptsActivity ?? this.receiptsActivity,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    activityRange,
    details,
    userNotFound,
    productsActivity,
    receiptsActivity,
  ];
}
