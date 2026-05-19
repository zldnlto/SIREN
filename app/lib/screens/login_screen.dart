import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _employeeIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next is AsyncData && next.value == true) {
        context.go('/home');
      }
      if (next is AsyncError) {
        Toast.show(context, '로그인에 실패했습니다. 사원번호와 비밀번호를 확인해 주세요.',
            type: ToastType.error);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SIREN',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LNG 탱크 검사 시스템',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _employeeIdCtrl,
                    decoration: const InputDecoration(
                      labelText: '사원번호',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? '사원번호를 입력해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: authAsync is AsyncLoading ? null : _submit,
                    child: authAsync is AsyncLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('로그인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .login(_employeeIdCtrl.text, _passwordCtrl.text);
  }
}
