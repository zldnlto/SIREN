import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../providers/inspection_provider.dart';
import '../widgets/toast.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _focusCtrl;
  late final Animation<double> _focusScale;
  bool _isShutterPressed = false;

  @override
  void initState() {
    super.initState();
    _focusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _focusScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _focusCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _focusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspectionState = ref.watch(inspectionProvider);

    ref.listen(inspectionProvider, (prev, next) {
      if (next.inspection != null &&
          prev?.inspection == null &&
          !next.isCreating) {
        context.pushNamed('progress', extra: next.inspection!.id);
      }
      if (next.error != null && prev?.error == null) {
        Toast.show(context, '검사 생성에 실패했습니다.', type: ToastType.error);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // ─── 1. Live Viewfinder Background Mockup (Dark Grayscale Industrial Feed) ───
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0A0A0B),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient neon glow backplate reflecting scanner state
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Blurred brand watermarked viewfinder placeholder
                  Opacity(
                    opacity: 0.04,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Live Scanning guidelines grid pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridPatternPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── 2. Viewfinder HUD Top (CAM-01 / AI ACTIVE) ───
          Positioned(
            top: 24,
            left: 24,
            child: SafeArea(
              child: Row(
                children: [
                  _buildHudChip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _PulsingStatusLed(),
                        const SizedBox(width: 8),
                        Text(
                          'CAM-01',
                          style: AppTextStyles.monoSm.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildHudChip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          size: 13,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI ACTIVE',
                          style: AppTextStyles.monoSm.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── 3. Center Reticle / Crosshair / Pulsing Focus Box ───
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // External framing guide (4 brackets)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                      ),
                      // Crosshair horizontal lines
                      Positioned(
                        left: -20,
                        child: Container(width: 40, height: 1, color: AppColors.primary),
                      ),
                      Positioned(
                        right: -20,
                        child: Container(width: 40, height: 1, color: AppColors.primary),
                      ),
                      // Crosshair vertical lines
                      Positioned(
                        top: -20,
                        child: Container(width: 1, height: 40, color: AppColors.primary),
                      ),
                      Positioned(
                        bottom: -20,
                        child: Container(width: 1, height: 40, color: AppColors.primary),
                      ),
                      // Center Red Focus Box with soft breathing pulse animation
                      AnimatedBuilder(
                        animation: _focusScale,
                        builder: (context, child) => Transform.scale(
                          scale: _focusScale.value,
                          child: child,
                        ),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFFF3B30),
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── 4. Viewfinder HUD Bottom / Large Shutter Button ───
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '초점 자동 동기화 완료 (TERM-X9)',
                      style: AppTextStyles.monoSm.copyWith(
                        fontSize: 10,
                        color: AppColors.onSurfaceMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Double White Circular Shutter Button
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isShutterPressed = true),
                      onTapUp: (_) {
                        setState(() => _isShutterPressed = false);
                        if (!inspectionState.isLoading) {
                          _startInspection();
                        }
                      },
                      onTapCancel: () => setState(() => _isShutterPressed = false),
                      child: AnimatedScale(
                        scale: _isShutterPressed ? 0.90 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 98,
                            height: 98,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: inspectionState.isCreating
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                            child: inspectionState.isCreating
                                ? const Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudChip({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: child,
    );
  }

  void _startInspection() {
    // Sub-issue #206: 'surface_treatment'로 디폴트 생성하여, 백엔드가 검출 결과 기반 역매핑하도록 바인딩
    ref.read(inspectionProvider.notifier).start('surface_treatment');
  }
}

// ─── Custom Painter for Viewfinder Grid Pattern ─────────────────────────────────
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    const int gridRows = 8;
    final double rowHeight = size.height / gridRows;
    for (int i = 1; i < gridRows; i++) {
      canvas.drawLine(
        Offset(0, i * rowHeight),
        Offset(size.width, i * rowHeight),
        paint,
      );
    }

    // Draw vertical grid lines
    const int gridCols = 8;
    final double colWidth = size.width / gridCols;
    for (int i = 1; i < gridCols; i++) {
      canvas.drawLine(
        Offset(i * colWidth, 0),
        Offset(i * colWidth, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Pulsing status LED ────────────────────────────────────────────────────────
class _PulsingStatusLed extends StatefulWidget {
  const _PulsingStatusLed();

  @override
  State<_PulsingStatusLed> createState() => _PulsingStatusLedState();
}

class _PulsingStatusLedState extends State<_PulsingStatusLed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryLight.withValues(alpha: 0.5 * _animation.value),
              blurRadius: 6 * _animation.value,
              spreadRadius: 2 * _animation.value,
            ),
          ],
        ),
      ),
    );
  }
}
