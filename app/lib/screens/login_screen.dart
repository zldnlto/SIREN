import 'package:flutter/foundation.dart';
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
  static const _employeeIdMaxLen = 6;
  static const _pinMaxLen = 4;

  // 편의를 위해 개발용 프리필 탑재 (084920 / 1234)
  final _employeeIdCtrl = TextEditingController(
    text: '084920',
  );
  final _passwordCtrl = TextEditingController(
    text: '1234',
  );
  final _formKey = GlobalKey<FormState>();

  // Explicitly manage active input field via boolean state to prevent focus stealing bugs during virtual keypad taps
  bool _isIdActive = true; 

  final FocusNode _employeeIdFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    _employeeIdFocusNode.addListener(() {
      if (_employeeIdFocusNode.hasFocus) {
        setState(() => _isIdActive = true);
      }
    });
    
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() => _isIdActive = false);
      }
    });

    // Auto-focus ID field on page load/refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _employeeIdFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    _passwordCtrl.dispose();
    _employeeIdFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onKeypadTap(String val) {
    final controller = _isIdActive ? _employeeIdCtrl : _passwordCtrl;
    final maxLen = _isIdActive ? _employeeIdMaxLen : _pinMaxLen;
    final focusNode = _isIdActive ? _employeeIdFocusNode : _passwordFocusNode;
    final text = controller.text;

    if (val == 'clear') {
      setState(() => controller.clear());
      focusNode.requestFocus();
    } else if (val == 'backspace') {
      if (text.isNotEmpty) {
        setState(() => controller.text = text.substring(0, text.length - 1));
      }
      focusNode.requestFocus();
    } else {
      // Prevent further typing if limit reached
      if (text.length >= maxLen) {
        focusNode.requestFocus();
        return;
      }
      
      final nextText = text + val;
      setState(() => controller.text = nextText);

      // Smart UX Automation for gloved field inspectors (10-tap 프리패스)
      if (_isIdActive && nextText.length == _employeeIdMaxLen) {
        // Auto-advance to the password PIN input field
        _passwordFocusNode.requestFocus();
      } else if (!_isIdActive && nextText.length == _pinMaxLen) {
        // Auto-submit login immediately upon completing the 4-digit PIN
        _submit();
      } else {
        focusNode.requestFocus();
      }
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

    final shortestSide = MediaQuery.of(context).size.shortestSide;
    // Mobile Breakpoint spec: shortestSide < 600 dp (from supported_devices.md)
    final isTablet = shortestSide >= AppBreakpoints.tablet;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Fluid responsive sizing clamps for the Tablet layout card
    final tabletWidth = (screenWidth * 0.9).clamp(800.0, 1120.0);
    final tabletHeight = (screenHeight * 0.82).clamp(600.0, 780.0);

    // ─── Left Branding Component (Polymorphic Responsive Visuals) ───
    late Widget brandingWidget;

    if (isTablet) {
      // Full Tablet Landscape Branding (2-Pane column style)
      brandingWidget = Expanded(
        flex: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // precision_manufacturing icon container
            // Brand Logo with Ambient Radial Glow behind it
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft Lavender-Blue Ambient Aura behind the logo
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15), // soft lavender core
                        AppColors.primary.withValues(alpha: 0.05),
                        Colors.transparent, // smooth fade out
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // The boxless logo asset itself
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'LNG TANK',
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: 30,
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
            const SizedBox(height: AppSpacing.sm),
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
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const Spacer(),
            // Device Info Warning Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.borderSm, // 6px rounded
                border: Border.all(color: AppColors.border, width: 1),
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
    } else {
      // Compact Mobile Portrait Branding Header (Horizontal row style to save massive vertical space)
      brandingWidget = Container(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Micro Icon container (36x36)
            // Micro Logo with Soft Ambient Glow
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft Micro Glow for mobile
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Header Text & Device ID stacked (compact design)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LNG TANK ',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: AppColors.onBackground,
                      ),
                    ),
                    Text(
                      'INSPECTOR',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: AppColors.primary, // signature lavender
                      ),
                    ),
                  ],
                ),
                Text(
                  '기기 ID: TERM-X9-204 (모바일)',
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ─── Right Login Input & Keypad Section (Stitch skeleton + linear.app styles) ───
    final inputPaneContent = [
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
        height: 60, // Compact elegant form height
        child: TextFormField(
          controller: _employeeIdCtrl,
          focusNode: _employeeIdFocusNode,
          // Web/Desktop uses physical keyboard (+ keypad). Mobile uses keypad only.
          readOnly: !kIsWeb, 
          showCursor: true,
          style: AppTextStyles.headlineMd.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
          onTap: () => _employeeIdFocusNode.requestFocus(),
          onChanged: (val) {
            // Support physical keyboard auto-advance & length constraint
            if (val.length > _employeeIdMaxLen) {
              _employeeIdCtrl.text = val.substring(0, _employeeIdMaxLen);
              _employeeIdCtrl.selection = TextSelection.fromPosition(
                const TextPosition(offset: _employeeIdMaxLen),
              );
            }
            if (_employeeIdCtrl.text.length == _employeeIdMaxLen) {
              _passwordFocusNode.requestFocus();
            }
          },
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
            // Maintain dynamic border highlights based on the active boolean state
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMd, // 8px rounded
              borderSide: BorderSide(
                color: _isIdActive ? AppColors.primary : AppColors.border,
                width: _isIdActive ? 1.5 : 1.0,
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
      const SizedBox(height: 14),

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
        height: 60,
        child: TextFormField(
          controller: _passwordCtrl,
          focusNode: _passwordFocusNode,
          readOnly: !kIsWeb,
          showCursor: true,
          obscureText: true,
          style: AppTextStyles.headlineMd.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 8.0,
            color: AppColors.onBackground,
          ),
          onTap: () => _passwordFocusNode.requestFocus(),
          onChanged: (val) {
            // Support physical keyboard auto-submit & length constraint
            if (val.length > _pinMaxLen) {
              _passwordCtrl.text = val.substring(0, _pinMaxLen);
              _passwordCtrl.selection = TextSelection.fromPosition(
                const TextPosition(offset: _pinMaxLen),
              );
            }
            if (_passwordCtrl.text.length == _pinMaxLen) {
              _submit();
            }
          },
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
                color: !_isIdActive ? AppColors.primary : AppColors.border,
                width: !_isIdActive ? 1.5 : 1.0,
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
        childAspectRatio: 2.4,
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

      // Action Login Button
      SizedBox(
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
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
    ];

    final loginInputSection = isTablet
        ? Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: inputPaneContent,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: inputPaneContent,
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
          // Layer 2: Main Login Card Frame and responsive content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // optimized mobile screen margins
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
                                brandingWidget,
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
                            // Mobile view: Minimalistic one-screen card with elegant margins
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                brandingWidget, // Slim mobile header
                                const Divider(
                                  color: AppColors.border,
                                  height: 16,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 4),
                                loginInputSection, // Inputs + Keypad stacked
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
