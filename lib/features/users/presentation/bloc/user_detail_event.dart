part of 'user_detail_bloc.dart';

sealed class UserDetailEvent {
  const UserDetailEvent();
}

/// The page opened for [userId] (from the URL).
final class UserDetailRequested extends UserDetailEvent {
  final String userId;

  const UserDetailRequested(this.userId);
}

/// A section's Retry button: reloads that section only.
final class UserDetailSectionRetried extends UserDetailEvent {
  final UserDetailSection section;

  const UserDetailSectionRetried(this.section);
}
