import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_endpoints.dart';
class TokenInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  TokenInterceptor(this.dio, this.secureStorage);
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await secureStorage.read(key: 'access_token');
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final response = await Dio().post(
            ApiEndpoints.refreshToken,
            options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
          );
          if (response.statusCode == 200) {
            final newAccessToken = response.data['data']['accessToken'];
            final newRefreshToken = response.data['data']['refreshToken'];
            await secureStorage.write(key: 'access_token', value: newAccessToken);
            await secureStorage.write(key: 'refresh_token', value: newRefreshToken);
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await Dio().fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          await secureStorage.deleteAll();
          // Broadcast session expired logic here or redirect via router provider
        }
      } else {
        await secureStorage.deleteAll();
      }
    }
    return handler.next(err);
  }
}
