import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../usecases/login_usecase.dart';

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.read(authRepositoryProvider).readToken();
    return token != null;
  }

  Future<void> login(String employeeId, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        await ref.read(loginUseCaseProvider).call(employeeId, password);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).clearToken();
    state = const AsyncData(false);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);
