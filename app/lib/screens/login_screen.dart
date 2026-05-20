import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../providers/auth_provider.dart';
import '../widgets/siren_button.dart';
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
        Toast.show(
          context,
          '로그인에 실패했습니다. 사원번호와 비밀번호를 확인해 주세요.',
          type: ToastType.error,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SIREN',
                    style: AppTextStyles.displaySm.copyWith(letterSpacing: 6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'LNG 탱크 검사 시스템',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.x2l),
                  _TokenInput(
                    controller: _employeeIdCtrl,
                    label: '사원번호',
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? '사원번호를 입력해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TokenInput(
                    controller: _passwordCtrl,
                    label: '비밀번호',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SirenButton(
                    label: '로그인',
                    onPressed: authAsync is AsyncLoading ? null : _submit,
                    isLoading: authAsync is AsyncLoading,
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

class _TokenInput extends StatelessWidget {
  const _TokenInput({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelLg.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        prefixIcon: Icon(prefixIcon, color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.destructive, width: 1.5),
        ),
        errorStyle: AppTextStyles.labelSm.copyWith(
          color: AppColors.destructive,
        ),
      ),
    );
  }
}
