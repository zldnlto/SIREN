import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'constants.dart';

const _storage = FlutterSecureStorage();

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: kTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});
