import 'package:dio/dio.dart';

import '../errors/failures.dart';

const kValidationMessage = 'Please check the entered data.';
const kUnauthorizedMessage = 'Your session has expired. Please log in again.';
const kForbiddenMessage = "You don't have permission to do this.";
const kServerMessage = 'Something went wrong. Please try again.';
const kNetworkMessage = 'Could not reach the server. Please try again.';

/// Maps a failed request to an [AdminFailure].
///
/// 400/4xx messages use the `ProblemDetail.detail` from the backend when
/// present. 5xx always uses generic copy, since its detail is internal.
/// A request with no response (offline, timeout, or a CORS rejection, which
/// the browser reports the same way) is a [NetworkFailure].
AdminFailure mapDioException(DioException e) {
  final status = e.response?.statusCode;
  if (status == null) return const NetworkFailure(kNetworkMessage);

  final data = e.response?.data;
  final detail = data is Map ? data['detail'] as String? : null;

  if (status == 401) return UnauthorizedFailure(detail ?? kUnauthorizedMessage);
  if (status == 403) return ForbiddenFailure(detail ?? kForbiddenMessage);
  if (status >= 500) return const ServerFailure(kServerMessage);
  return ValidationFailure(detail ?? kValidationMessage);
}
