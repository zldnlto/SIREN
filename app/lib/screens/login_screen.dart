import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/tokens.dart';
import '../providers/auth_provider.dart';
import '../widgets/toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _employeeIdCtrl = TextEditingController(text: '84920'); // Pre-filled exactly like Stitch
  final _passwordCtrl = TextEditingController(text: '1234'); // Pre-filled pin placeholder
  final _formKey = GlobalKey<FormState>();
  
  TextEditingController? _activeController;

  @override
  void initState() {
    super.initState();
    _activeController = _employeeIdCtrl; // default active input field
  }

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onKeypadTap(String val) {
    if (_activeController == null) return;
    final text = _activeController!.text;

    if (val == 'clear') {
      setState(() => _activeController!.clear());
    } else if (val == 'backspace') {
      if (text.isNotEmpty) {
        setState(() => _activeController!.text = text.substring(0, text.length - 1));
      }
    } else {
      // Constraints matching actual field rules
      if (_activeController == _employeeIdCtrl && text.length >= 6) return;
      if (_activeController == _passwordCtrl && text.length >= 4) return;
      
      setState(() => _activeController!.text = text + val);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .login(_employeeIdCtrl.text, _passwordCtrl.text);
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

    final isTablet =
        MediaQuery.of(context).size.shortestSide >= AppBreakpoints.tablet;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Fluid responsive sizing clamps for the Tablet layout card (Slightly larger height scale to utilize vertical space)
    final tabletWidth = (screenWidth * 0.9).clamp(800.0, 1120.0);
    final tabletHeight = (screenHeight * 0.82).clamp(600.0, 780.0);

    // Left Branding Section (Clean layout without internal scrollbars + Compact design hierarchy)
    final brandingSection = Expanded(
      flex: isTablet ? 1 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // precision_manufacturing icon container (96x96 compact size, 8px rounded, lavender outline)
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant, // Surface 2
              borderRadius: AppRadius.borderMd, // 8px rounded
              border: Border.all(color: AppColors.primary, width: 1.5), // Elegant lavender accent outline
            ),
            child: const Center(
              child: Icon(
                Icons.precision_manufacturing_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md), // Compact spacing (16px)
          Text(
            'LNG TANK',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 30, // Compact typography scale for zero scrollbar
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -1.0,
              color: AppColors.onBackground,
            ),
          ),
          Text(
            'INSPECTOR',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -1.0,
              color: AppColors.primary, // signature lavender
            ),
          ),
          const SizedBox(height: AppSpacing.sm), // my-stack-sm (12px)
          Container(
            height: 3,
            width: 64,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(1.5)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '고위험 산업 환경용 검사 시스템. 허가된 작업자만 로그인할 수 있습니다.',
            style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 14, // Muted & compact description text
              height: 1.45,
            ),
          ),
          const Spacer(), // Safely pushes the device warning chip to bottom without IntrinsicHeight crash
          // Device Info Warning Chip (linear.app styled pill badge - compact height)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.borderSm, // 6px rounded
              border: Border.all(color: AppColors.border, width: 1), // 1px hairline border
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Text(
                  '기기 ID: TERM-X9-204',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Right Login Input & Keypad Section (Clean layout without internal scrollbars + Compact components)
    final loginInputSection = Expanded(
      flex: isTablet ? 1 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Operator ID Input Label
          Text(
            '작업자 ID',
            style: AppTextStyles.labelLg.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 60, // Refined height (60px instead of 72px) for elegant look & spacing savings
            child: TextFormField(
              controller: _employeeIdCtrl,
              readOnly: true,
              showCursor: true,
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
              onTap: () => setState(() => _activeController = _employeeIdCtrl),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceVariant, // Surface 2
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.onSurfaceMuted,
                  size: 20,
                ),
                hintText: '사원번호 6자리',
                hintStyle: AppTextStyles.headlineMd.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0x50D0D6E0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderMd, // 8px rounded
                  borderSide: BorderSide(
                    color: _activeController == _employeeIdCtrl ? AppColors.primary : AppColors.border,
                    width: _activeController == _employeeIdCtrl ? 1.5 : 1.0,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(color: AppColors.border, width: 1.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14), // space-y-stack-md (14px)

          // Password (PIN) Input Label
          Text(
            '비밀번호 (PIN)',
            style: AppTextStyles.labelLg.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 60, // Refined height (60px instead of 72px)
            child: TextFormField(
              controller: _passwordCtrl,
              readOnly: true,
              showCursor: true,
              obscureText: true,
              style: AppTextStyles.headlineMd.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 8.0, // balanced dots spacing
                color: AppColors.onBackground,
              ),
              onTap: () => setState(() => _activeController = _passwordCtrl),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceVariant,
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.onSurfaceMuted,
                  size: 20,
                ),
                hintText: 'PIN 입력',
                hintStyle: AppTextStyles.headlineMd.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0x50D0D6E0),
                  letterSpacing: 0,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(
                    color: _activeController == _passwordCtrl ? AppColors.primary : AppColors.border,
                    width: _activeController == _passwordCtrl ? 1.5 : 1.0,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(color: AppColors.border, width: 1.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Numeric Keypad Grid (compact ratio 2.4, clean 10px spacing)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4, // Compact key aspect ratio to save vertical space
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
              _buildKeypadButton('지우기', isSpecial: true, value: 'clear'),
              _buildKeypadButton('0'),
              _buildKeypadButton('backspace', isIcon: true, value: 'backspace'),
            ],
          ),
          const SizedBox(height: 16),

          // Action Login Button (60px height to align perfectly with form inputs)
          SizedBox(
            height: 60, // Slimmer elegant button
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, // Lavender brand color
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMd, // 8px rounded
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: authAsync is AsyncLoading ? null : _submit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (authAsync is AsyncLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.onPrimary,
                        strokeWidth: 2.0,
                      ),
                    )
                  else ...[
                    Text(
                      '로그인',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.login_rounded,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background, // Deepest near-black canvas (#010102)
      body: Stack(
        children: [
          // Layer 1: Ambient Auroral Glow (Signature linear.app aesthetic)
          Positioned(
            top: -250,
            left: -200,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08), // Elegant lavender bloom
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 150,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -200,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.04),
                    blurRadius: 180,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          // Layer 2: Main Login Card Frame and responsive content (Unified Single Scroll for entire screen under extreme viewport reduction)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // optimized screen margins
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? tabletWidth : 440,
                      maxHeight: isTablet ? tabletHeight : double.infinity,
                    ),
                    child: isTablet
                        ? Container(
                            width: tabletWidth,
                            height: tabletHeight, // Real-time fluid responsive height via MediaQuery clamp
                            padding: const EdgeInsets.all(32), // refined padding (32px instead of 48px) to optimize space
                            decoration: BoxDecoration(
                              color: AppColors.surface, // Surface 1 (#0F1011)
                              borderRadius: AppRadius.borderLg, // 12px rounded
                              border: Border.all(color: AppColors.border, width: 1.0), // 1px hairline border (#23252A)
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x60000000), // elegant soft shadow
                                  blurRadius: 30,
                                  offset: Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                brandingSection,
                                const SizedBox(width: 32),
                                const VerticalDivider(
                                  color: AppColors.border,
                                  width: 1,
                                  thickness: 1,
                                ),
                                const SizedBox(width: 32),
                                loginInputSection,
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.borderLg,
                              border: Border.all(color: AppColors.border, width: 1.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x50000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                brandingSection,
                                const SizedBox(height: 20),
                                const Divider(
                                  color: AppColors.border,
                                  height: 1,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 20),
                                loginInputSection,
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(
    String label, {
    bool isSpecial = false,
    bool isIcon = false,
    String? value,
  }) {
    final tapValue = value ?? label;
    final bgColor = isSpecial ? AppColors.surfaceTertiary : AppColors.surfaceVariant;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd, // 8px rounded corners
        ),
        side: const BorderSide(color: AppColors.border, width: 1.0), // 1px hairline border
      ),
      onPressed: () => _onKeypadTap(tapValue),
      child: isIcon
          ? const Icon(
              Icons.backspace_outlined,
              color: AppColors.onSurfaceVariant,
              size: 20,
            )
          : Text(
              label,
              style: isSpecial
                  ? AppTextStyles.labelLg.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceMuted,
                    )
                  : AppTextStyles.headlineMd.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
            ),
    );
  }
}
