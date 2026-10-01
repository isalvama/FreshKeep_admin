import 'package:equatable/equatable.dart';

class Admin extends Equatable {
  final String accountId; // `accountId` claim
  final String adminId; // `adminId` claim
  final String email; // `sub` claim

  const Admin({
    required this.accountId,
    required this.adminId,
    required this.email,
  });

  @override
  List<Object?> get props => [accountId, adminId, email];
}
