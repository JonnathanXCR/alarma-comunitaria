class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => 'UnauthorizedException: sesión expirada o no válida';
}

class WebSocketException implements Exception {
  final String message;
  const WebSocketException(this.message);

  @override
  String toString() => 'WebSocketException: $message';
}

class ServerException implements Exception {
  final int statusCode;
  final String message;
  const ServerException({required this.statusCode, required this.message});

  @override
  String toString() => 'ServerException [$statusCode]: $message';
}
