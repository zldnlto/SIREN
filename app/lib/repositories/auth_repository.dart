import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_client.dart';
import '../core/constants.dart';

class AuthRepository {
  const AuthRepository(this._dio);
  final Dio _dio;

  Future<String> login(String employeeId, String password) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'employee_id': employeeId, 'password': password},
    );
    return resp.data!['access_token'] as String;
  }

  Future<void> saveToken(String token) async {
    const FlutterSecureStorage().write(key: kTokenKey, value: token);
  }

  Future<void> clearToken() async {
    await const FlutterSecureStorage().delete(key: kTokenKey);
  }

  Future<String?> readToken() async {
    return const FlutterSecureStorage().read(key: kTokenKey);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(dioProvider)),
);
