import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repo);
  final AuthRepository _repo;

  Future<void> call(String employeeId, String password) async {
    if (employeeId.trim().isEmpty || password.isEmpty) {
      throw ArgumentError('사원번호와 비밀번호를 입력해 주세요.');
    }
    final token = await _repo.login(employeeId.trim(), password);
    await _repo.saveToken(token);
  }
}

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.read(authRepositoryProvider)),
);
