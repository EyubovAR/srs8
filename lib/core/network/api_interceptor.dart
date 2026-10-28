import 'package:dio/dio.dart';
import '../error/app_exception.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json; charset=UTF-8';
    options.headers['X-Client-Platform'] = 'Flutter-SRS8';
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException appException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        appException = TimeoutException();
        break;
      case DioExceptionType.connectionError:
        appException = NetworkException();
        break;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        if (status != null && status >= 400 && status < 500) {
          appException = ServerException('Ошибка клиента: $status', status);
        } else if (status != null && status >= 500) {
          appException = ServerException('Ошибка сервера ($status). Повторите позже.', status);
        } else {
          appException = ServerException('Некорректный ответ сервера', status);
        }
        break;
      default:
        appException = UnknownException(err.message ?? 'Неизвестная ошибка');
    }

    final customError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: appException,
    );

    super.onError(customError, handler);
  }
}