import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final _employeeIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Explicitly manage active input field via boolean state to prevent focus stealing bugs during virtual keypad taps
  bool _isIdActive = true; 
  Offset _targetGlowPos = const Offset(200, 300);

  final FocusNode _employeeIdFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    _employeeIdFocusNode.addListener(() {
      if (_employeeIdFocusNode.hasFocus) {
        setState(() {
          _isIdActive = true;
          _updateGlowForFocus();
        });
      }
    });
    
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() {
          _isIdActive = false;
          _updateGlowForFocus();
        });
      }
    });

    // Auto-focus ID field on page load/refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _employeeIdFocusNode.requestFocus();
      _updateGlowForFocus();
    });
  }

  void _updateGlowForFocus() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final isTablet = size.shortestSide >= AppBreakpoints.tablet;
      
      setState(() {
        if (_isIdActive) {
          _targetGlowPos = isTablet
              ? Offset(size.width * 0.75, size.height * 0.25)
              : Offset(size.width * 0.5, size.height * 0.32);
        } else {
          _targetGlowPos = isTablet
              ? Offset(size.width * 0.75, size.height * 0.58)
              : Offset(size.width * 0.5, size.height * 0.68);
        }
      });
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
        // Auto-submit login removed for QA specs. User must tap login button.
        focusNode.requestFocus();
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

  void _resetLoginForm() {
    setState(() {
      _passwordCtrl.clear();
      _isIdActive = true;
    });
    _employeeIdFocusNode.requestFocus();
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
          actionLabel: '재시도',
          onAction: _resetLoginForm,
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
              clipBehavior: Clip.none,
              children: [
                // [기법 2] 로고 하단 타원형 radial-gradient glow (바닥 네온 빛 번짐)
                Positioned(
                  bottom: -15, // 로고 하단 가장자리에 배치
                  child: Container(
                    width: 180,
                    height: 24, // 가로로 찌그러진 타원형 발광체
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.35), // 네온 빛무리 코어
                          AppColors.primary.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // 원래의 220dp 거대 오라 글로우 (배후 조명)
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.20),
                        AppColors.primary.withValues(alpha: 0.08),
                        AppColors.primary.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),

                // [기법 1] 로고 실루엣 drop-shadow 레이어 (사각 박스그림자가 아닌 픽셀 경계선 기준)
                Positioned(
                  top: 4, // 아래로 미세 오프셋
                  left: 2,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: Image.asset(
                        'assets/images/logo@2x.png',
                        fit: BoxFit.contain,
                        // 실루엣을 딥 블랙 섀도우 톤으로 변환
                        color: AppColors.background.withValues(alpha: 0.75),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                // 원래의 고화질 logo@2x.png 에셋 본체
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Image.asset(
                    'assets/images/logo@2x.png',
                    fit: BoxFit.contain,
                    // 네온 흰 잔상을 어두운 배경에 블렌딩
                    color: Colors.white.withValues(alpha: 0.95),
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'SIREN',
              style: GoogleFonts.unbounded(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -1.5,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ship Inspection with RAG Engine + Neural network',
              style: AppTextStyles.monoSm.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryLight,
                letterSpacing: -0.2,
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
              'LNG 탱크 육안 검사를 AI 비전으로 대체하는 현장 보조 시스템.\n허가된 작업자만 접근 가능합니다.',
              style: AppTextStyles.bodyLg.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 13.5,
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
              clipBehavior: Clip.none,
              children: [
                // [기법 2] 모바일 로고 하단 타원형 radial-gradient glow (바닥 네온 빛 번짐)
                Positioned(
                  bottom: -6,
                  child: Container(
                    width: 70,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.35),
                          AppColors.primary.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // 원래의 모바일 glow 컨테이너
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.20),
                        AppColors.primary.withValues(alpha: 0.08),
                        AppColors.primary.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),

                // [기법 1] 모바일 로고 실루엣 drop-shadow 레이어 (blur 4.0)
                Positioned(
                  top: 2,
                  left: 1,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Image.asset(
                        'assets/images/logo@2x.png',
                        fit: BoxFit.contain,
                        color: AppColors.background.withValues(alpha: 0.75),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                // 원래의 모바일 로고 이미지에 BlendMode 필터 튜닝 적용
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Image.asset(
                    'assets/images/logo@2x.png',
                    fit: BoxFit.contain,
                    color: Colors.white.withValues(alpha: 0.95),
                    colorBlendMode: BlendMode.modulate,
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
                Text(
                  'SIREN',
                  style: GoogleFonts.unbounded(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: AppColors.onBackground,
                  ),
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
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.31),
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
            // Support physical keyboard length constraint
            if (val.length > _pinMaxLen) {
              _passwordCtrl.text = val.substring(0, _pinMaxLen);
              _passwordCtrl.selection = TextSelection.fromPosition(
                const TextPosition(offset: _pinMaxLen),
              );
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
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.31),
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
          // Layer 1: Interactive Grid & Glow Background (A + C + Alpha)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                setState(() {
                  _targetGlowPos = details.localPosition;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _targetGlowPos = details.localPosition;
                });
              },
              child: TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(end: _targetGlowPos),
                duration: AppDurations.slow,
                curve: Curves.easeOutQuart,
                builder: (context, animOffset, child) {
                  final activeColor = _isIdActive
                      ? AppColors.primary
                      : const Color(0xFF5E6DF8); // Indigo color for PIN focus to show a dynamic change
                  return TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: activeColor),
                    duration: AppDurations.slow,
                    curve: Curves.easeOutQuart,
                    builder: (context, animColor, child) {
                      return CustomPaint(
                        painter: _LoginBackgroundPainter(
                          glowPosition: animOffset,
                          themeColor: animColor ?? AppColors.primary,
                        ),
                      );
                    },
                  );
                },
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
                        ? ClipRRect(
                            borderRadius: AppRadius.borderLg,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                              child: Container(
                                width: tabletWidth,
                                height: tabletHeight, // Real-time fluid responsive height via MediaQuery clamp
                                padding: const EdgeInsets.all(32), // refined padding (32px instead of 48px) to optimize space
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withValues(alpha: 0.85), // 미세 투명화하여 뒷배경 굴절 투과
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
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: AppRadius.borderLg,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                              child: Container(
                                // Mobile view: Minimalistic one-screen card with elegant margins
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withValues(alpha: 0.85), // 동일하게 미세 투명화
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
            ),
          ),
          // ─── Floating Demo Account Login Toolbar (Clipped & blurred backdrop) ───
          Positioned(
            left: 24,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _employeeIdCtrl.text = '000001';
                      _passwordCtrl.text = '1234';
                      _submit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x30000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '데모 로그인',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 1,
                            height: 12,
                            color: AppColors.border,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '사원: 000001 | PIN: 1234',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
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

// ─── Custom Painter for Interactive Login Backdrop ──────────────────────────
class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter({
    required this.glowPosition,
    required this.themeColor,
  });

  final Offset glowPosition;
  final Color themeColor;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 닷 그리드 배경 (C) 그리기
    final dotPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const double spacing = 32.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }

    // 2. 터치 및 포커스 반응형 대형 Radial Glow (A + Alpha)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          themeColor.withValues(alpha: 0.28), // 0.12 -> 0.28로 선명도 상향
          themeColor.withValues(alpha: 0.10), // 0.04 -> 0.10으로 그라데이션 강도 보완
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: glowPosition, radius: 400)); // 크기 360 -> 400

    canvas.drawCircle(glowPosition, 400, glowPaint);
    
    // 3. 좌상단 및 우하단 보조 Ambient Glow (은은한 깊이감 유지)
    final ambientTopPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          themeColor.withValues(alpha: 0.12), // 0.06 -> 0.12
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: const Offset(0, 0), radius: 450));
    canvas.drawCircle(const Offset(0, 0), 450, ambientTopPaint);

    final ambientBottomPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.08), // 0.03 -> 0.08
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: 450));
    canvas.drawCircle(Offset(size.width, size.height), 450, ambientBottomPaint);
  }

  @override
  bool shouldRepaint(covariant _LoginBackgroundPainter oldDelegate) {
    return oldDelegate.glowPosition != glowPosition || oldDelegate.themeColor != themeColor;
  }
}
