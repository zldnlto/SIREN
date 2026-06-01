import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/tokens.dart';
import '../providers/auth_provider.dart';
import '../widgets/toast.dart';

// Stitch industrial theme colors specifically defined for the login screen
abstract final class _StitchColors {
  static const primary = Color(0xFF92CCFF); // Light blue brand color
  static const primaryContainer = Color(0xFF3498DB); // Blue action color
  static const onPrimary = Color(0xFF003351); // Dark blue text on action buttons
  static const background = Color(0xFF131313); // Deep industrial grey
  static const surfaceContainerLowest = Color(0xFF0E0E0E); // Deepest background gradient target
  static const surfaceContainerLow = Color(0xFF1C1B1B); // Card container background
  static const surfaceContainerHigh = Color(0xFF2A2A2A); // Active card element or key buttons
  static const surfaceContainerHighest = Color(0xFF353534); // Special keypad keys (Clear / Backspace)
  static const surfaceContainer = Color(0xFF201F1F); // Form input backgrounds
  static const outlineVariant = Color(0xFF3F4850); // Industrial borders
  static const onBackground = Color(0xFFE5E2E1); // High contrast text
  static const onSurface = Color(0xFFE5E2E1); // Card text
  static const onSurfaceVariant = Color(0xFFBFC7D2); // Secondary text
  static const tertiary = Color(0xFFE9C400); // Yellow warnings
}

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

    // Left Branding Section (Perfect sync with Stitch branding column)
    final brandingSection = Expanded(
      flex: isTablet ? 1 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // precision_manufacturing icon container
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: _StitchColors.primaryContainer,
              border: Border.all(color: _StitchColors.onBackground, width: 4),
            ),
            child: const Center(
              child: Icon(
                Icons.precision_manufacturing,
                color: _StitchColors.onPrimary,
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 24), // space-y-stack-lg (24px)
          Text(
            'LNG TANK',
            style: GoogleFonts.workSans(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 40 / 34,
              letterSpacing: -0.02 * 34,
              color: _StitchColors.onBackground,
            ),
          ),
          Text(
            'INSPECTOR',
            style: GoogleFonts.workSans(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 40 / 34,
              letterSpacing: -0.02 * 34,
              color: _StitchColors.primary,
            ),
          ),
          const SizedBox(height: 16), // my-stack-md (16px)
          Container(
            height: 4,
            width: 96,
            color: _StitchColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '고위험 산업 환경용 검사 시스템. 허가된 작업자만 로그인할 수 있습니다.',
            style: GoogleFonts.workSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 26 / 18,
              color: _StitchColors.onSurfaceVariant,
            ),
          ),
          if (isTablet) const Spacer(),
          if (!isTablet) const SizedBox(height: 24),
          // Device Info Warning Chip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _StitchColors.surfaceContainerHigh,
              border: Border.all(color: _StitchColors.outlineVariant, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning,
                  color: _StitchColors.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  '기기 ID: TERM-X9-204',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 16 / 12,
                    color: _StitchColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Right Login Input & Keypad Section (Perfect sync with Stitch fields and numeric pad)
    final loginInputSection = Expanded(
      flex: isTablet ? 1 : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Operator ID Input Label
          Text(
            '작업자 ID',
            style: GoogleFonts.workSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
              letterSpacing: 0.1 * 14,
              color: _StitchColors.onSurface,
            ),
          ),
          const SizedBox(height: 8), // space-y-stack-sm (8px)
          SizedBox(
            height: 72, // h-[72px]
            child: TextFormField(
              controller: _employeeIdCtrl,
              readOnly: true,
              showCursor: true,
              style: GoogleFonts.workSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 34 / 28,
                letterSpacing: -0.01 * 28,
                color: _StitchColors.onBackground,
              ),
              onTap: () => setState(() => _activeController = _employeeIdCtrl),
              decoration: InputDecoration(
                filled: true,
                fillColor: _StitchColors.surfaceContainer,
                prefixIcon: const Icon(
                  Icons.badge,
                  color: _StitchColors.onSurfaceVariant,
                  size: 24,
                ),
                hintText: '사원번호 6자리',
                hintStyle: GoogleFonts.workSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0x80BFC7D2), // exact 50% opacity representation
                  letterSpacing: 0,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _StitchColors.outlineVariant, width: 2.0),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _StitchColors.primary, width: 2.0),
                ),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _StitchColors.outlineVariant, width: 2.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24), // space-y-stack-lg (24px)

          // Password (PIN) Input Label
          Text(
            '비밀번호 (PIN)',
            style: GoogleFonts.workSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
              letterSpacing: 0.1 * 14,
              color: _StitchColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72, // h-[72px]
            child: TextFormField(
              controller: _passwordCtrl,
              readOnly: true,
              showCursor: true,
              obscureText: true,
              style: GoogleFonts.workSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 34 / 28,
                letterSpacing: 14.0, // tracking-[0.5em] for passwords
                color: _StitchColors.onBackground,
              ),
              onTap: () => setState(() => _activeController = _passwordCtrl),
              decoration: InputDecoration(
                filled: true,
                fillColor: _StitchColors.surfaceContainer,
                prefixIcon: const Icon(
                  Icons.lock,
                  color: _StitchColors.onSurfaceVariant,
                  size: 24,
                ),
                hintText: 'PIN 입력',
                hintStyle: GoogleFonts.workSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0x80BFC7D2), // exact 50% opacity representation
                  letterSpacing: 0,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _StitchColors.outlineVariant, width: 2.0),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _StitchColors.primary, width: 2.0),
                ),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _StitchColors.outlineVariant, width: 2.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16), // pt-stack-md (16px)

          // Numeric Keypad Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2, // balanced compact landscape touch ratio
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
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
          const SizedBox(height: 24), // mt-stack-lg (24px)

          // Action Login Button
          SizedBox(
            height: 72, // h-[72px]
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _StitchColors.primaryContainer,
                foregroundColor: _StitchColors.onPrimary,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                side: const BorderSide(color: _StitchColors.primaryContainer, width: 2.0),
                padding: EdgeInsets.zero,
              ),
              onPressed: authAsync is AsyncLoading ? null : _submit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (authAsync is AsyncLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: _StitchColors.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  else ...[
                    Text(
                      '로그인',
                      style: GoogleFonts.workSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 28 / 22,
                        letterSpacing: 4.0, // tracking-widest
                        color: _StitchColors.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.login,
                      color: _StitchColors.onPrimary,
                      size: 24,
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
      backgroundColor: _StitchColors.background,
      body: Stack(
        children: [
          // Layer 1: Background Texture (Unsplash)
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.network(
                'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?q=80&w=2070&auto=format&fit=crop',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.transparent); // Fallback color
                },
              ),
            ),
          ),
          // Layer 2: Black Gradient overlay from lowest boundary
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _StitchColors.surfaceContainerLowest,
                  ],
                ),
              ),
            ),
          ),
          // Layer 3: Main Login Card Frame and responsive content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32), // p-8 in HTML (32px)
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 1280 : 440, // max-w-7xl (1280px)
                      maxHeight: isTablet ? 900 : double.infinity, // max-h-[900px]
                    ),
                    child: isTablet
                        ? Container(
                            padding: const EdgeInsets.all(48), // p-12 in HTML (48px)
                            decoration: BoxDecoration(
                              color: _StitchColors.surfaceContainerLow,
                              borderRadius: const BorderRadius.all(Radius.circular(4)), // DEFAULT (0.25rem = 4px)
                              border: Border.all(color: _StitchColors.outlineVariant, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x80000000), // exact 50% opacity black
                                  blurRadius: 25,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  brandingSection,
                                  const SizedBox(width: 48),
                                  const VerticalDivider(
                                    color: _StitchColors.outlineVariant,
                                    width: 2,
                                    thickness: 2,
                                  ),
                                  const SizedBox(width: 48),
                                  loginInputSection,
                                ],
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _StitchColors.surfaceContainerLow,
                              borderRadius: const BorderRadius.all(Radius.circular(4)),
                              border: Border.all(color: _StitchColors.outlineVariant, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x80000000),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                brandingSection,
                                const SizedBox(height: 24),
                                const Divider(
                                  color: _StitchColors.outlineVariant,
                                  height: 2,
                                  thickness: 2,
                                ),
                                const SizedBox(height: 24),
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
    final bgColor = isSpecial ? _StitchColors.surfaceContainerHighest : _StitchColors.surfaceContainerHigh;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: _StitchColors.onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        side: const BorderSide(color: _StitchColors.outlineVariant, width: 2.0),
      ),
      onPressed: () => _onKeypadTap(tapValue),
      child: isIcon
          ? const Icon(
              Icons.backspace,
              color: _StitchColors.onSurfaceVariant,
              size: 24,
            )
          : Text(
              label,
              style: isSpecial
                  ? GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _StitchColors.onSurfaceVariant,
                    )
                  : GoogleFonts.workSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _StitchColors.onBackground,
                    ),
            ),
    );
  }
}
