class LoginResponseModel {
  final String accountId;
  final String email;
  final String jwtString;
  // Raw jwt.expiration config value in ms — not a countdown, not used for
  // expiry checks (the token's `exp` claim is).
  final int expiresIn;

  const LoginResponseModel({
    required this.accountId,
    required this.email,
    required this.jwtString,
    required this.expiresIn,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accountId: json['accountId'] as String,
      email: json['email'] as String,
      jwtString: json['jwtString'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }
}
