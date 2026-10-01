/// Shared by every feature: all admin endpoints fail the same ways.
sealed class AdminFailure {
  final String message;

  const AdminFailure(this.message);
}

// 400 and other 4xx — incl. "not found", which the backend maps to 400.
class ValidationFailure extends AdminFailure {
  const ValidationFailure(super.message);
}

class UnauthorizedFailure extends AdminFailure {
  const UnauthorizedFailure(super.message); // 401
}

class ForbiddenFailure extends AdminFailure {
  const ForbiddenFailure(super.message); // 403
}

class ServerFailure extends AdminFailure {
  const ServerFailure(super.message); // 5xx
}

class NetworkFailure extends AdminFailure {
  const NetworkFailure(super.message); // no response / timeout / CORS block
}

class NotAdminFailure extends AdminFailure {
  const NotAdminFailure(super.message); // login only — token lacks ROLE_ADMIN
}
