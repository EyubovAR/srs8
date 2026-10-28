class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Отсутствует интернет-соединение. Проверьте подключение.']);
}

class TimeoutException extends AppException {
  TimeoutException([super.message = 'Время ожидания ответа истекло. Повторите попытку позже.']);
}

class ServerException extends AppException {
  ServerException(super.message, [super.statusCode]);
}

class ParseException extends AppException {
  ParseException([super.message = 'Ошибка обработки данных с сервера.']);
}

class UnknownException extends AppException {
  UnknownException([super.message = 'Произошла непредвиденная ошибка.']);
}