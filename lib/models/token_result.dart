class TokenResult {
  final bool isValid;
  final String message;
  final String? tokenStatus; // 'trial' or 'permanent'
  final String? expiresAt; // ISO 8601 date string or empty

  TokenResult({
    required this.isValid,
    required this.message,
    this.tokenStatus,
    this.expiresAt,
  });
}
