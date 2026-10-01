import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_keep_admin/core/errors/failures.dart';
import 'package:fresh_keep_admin/shared/creators/data/creator_label_remote_datasource.dart';
import 'package:fresh_keep_admin/shared/creators/data/creator_label_repository_impl.dart';
import 'package:fresh_keep_admin/shared/creators/domain/get_creator_label_usecase.dart';

import '../../fakes/fake_http_adapter.dart';

CreatorLabelRepositoryImpl _repository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8082'))
    ..httpClientAdapter = adapter;
  return CreatorLabelRepositoryImpl(
    remoteDataSource: CreatorLabelRemoteDataSource(dio),
  );
}

void main() {
  test('reads the email from the user details', () async {
    final adapter = JsonResponseAdapter(
      statusCode: 200,
      body: {'id': 'u-1', 'email': 'alice@example.com', 'roles': []},
    );

    final result = await GetCreatorLabelUseCase(_repository(adapter))('u-1');

    expect(adapter.requests.single.path, '/api/v1/admin/users/u-1');
    expect(result.getRight().toNullable(), 'alice@example.com');
  });

  test('encodes the id so it stays one path segment', () async {
    final adapter = JsonResponseAdapter(
      statusCode: 200,
      body: {'email': 'alice@example.com'},
    );

    await _repository(adapter).getCreatorEmail('../products');

    expect(adapter.requests.single.path, '/api/v1/admin/users/..%2Fproducts');
  });

  test('a user without an email is a ServerFailure', () async {
    final result = await _repository(
      JsonResponseAdapter(statusCode: 200, body: {'id': 'u-1'}),
    ).getCreatorEmail('u-1');

    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });

  test('a missing user (400) is a ValidationFailure', () async {
    final result = await _repository(
      JsonResponseAdapter(statusCode: 400, body: {'detail': 'No such user.'}),
    ).getCreatorEmail('u-9');

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });
}
