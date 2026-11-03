// lib/core/network/api_exception.dart

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  @override
  String toString() => 'ApiException: [$statusCode] $message (code: $code)';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'အကောင့်ဝင်ရန် လိုအပ်ပါသည် သို့မဟုတ် Session သက်တမ်းကုန်ဆုံးသွားပါပြီ (Unauthorized)',
    super.code = 'UNAUTHORIZED',
    super.details,
  }) : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'လုပ်ဆောင်ခွင့် မရှိပါ (Forbidden)',
    super.code = 'FORBIDDEN',
    super.details,
  }) : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'ရှာမတွေ့ပါ (Not Found)',
    super.code = 'NOT_FOUND',
    super.details,
  }) : super(statusCode: 404);
}

class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.details,
  }) : super(statusCode: 400);
}

class ConflictException extends ApiException {
  const ConflictException({
    required super.message,
    super.code = 'CONFLICT',
    super.details,
  }) : super(statusCode: 409);
}

class ServerException extends ApiException {
  const ServerException({
    super.message = 'ဆာဗာချို့ယွင်းချက် ဖြစ်ပွားနေပါသည် (Internal Server Error)',
    super.code = 'SERVER_ERROR',
    super.details,
  }) : super(statusCode: 500);
}

class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'အင်တာနက် သို့မဟုတ် ဆာဗာချိတ်ဆက်၍ မရပါ (Network / Connection Error)',
    super.code = 'NETWORK_ERROR',
    super.details,
  }) : super(statusCode: 0);
}

class RequestTimeoutException extends ApiException {
  const RequestTimeoutException({
    super.message = 'ချိတ်ဆက်မှု အချိန်ပြည့်သွားပါသည် (Request Timeout)',
    super.code = 'TIMEOUT',
  }) : super(statusCode: 408);
}

