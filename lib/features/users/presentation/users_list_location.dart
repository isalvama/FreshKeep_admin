import 'users_list_query.dart';

/// The last users list URL visited this session, so "← Back to users" on a
/// user's page returns to the same range and page. In memory only (a get_it
/// singleton): a reload starts from the default again.
class UsersListLocation {
  String _value = usersListLocation(kDefaultUsersListQuery);

  String get value => _value;

  /// Records a list URL. Anything that isn't the users list is ignored.
  void remember(String location) {
    if (Uri.parse(location).path == kUsersPath) _value = location;
  }
}
