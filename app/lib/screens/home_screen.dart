import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Camera mock-state variables for premium UX and performance optimization
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;
  String _flashMode = 'off'; // 'off' | 'on' | 'auto'

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

    // Warm up camera interface
    _initializeCamera();
  }

  @override
  void dispose() {
    _focusCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isCameraInitialized = false;
        _hasCameraError = false;
      });
      
      // Simulate real physical hardware diagnostic warmup delay
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasCameraError = true;
      });
    }
  }

  void _toggleFlash() {
    // 0ms delay: Instant UI update with immediate visual sync
    HapticFeedback.lightImpact();
    setState(() {
      if (_flashMode == 'off') {
        _flashMode = 'on';
      } else if (_flashMode == 'on') {
        _flashMode = 'auto';
      } else {
        _flashMode = 'off';
      }
    });
  }

  Future<void> _captureAndPreview() async {
    // Prevent double triggers
    HapticFeedback.mediumImpact();
    
    try {
      // 1x1 Transparent PNG byte stream matching premium specifications
      final pngBytes = Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
        1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 108, 137, 0, 0, 0, 13, 73, 68,
        65, 84, 120, 156, 99, 96, 0, 0, 0, 2, 0, 1, 73, 175, 168, 14, 0, 0, 0,
        0, 73, 69, 78, 68, 174, 66, 96, 130
      ]);

      if (kIsWeb) {
        // Fallback for web sandbox environments
        if (!mounted) return;
        context.pushNamed('preview', extra: 'mock-temp-image.png');
        return;
      }

      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/siren_capture_${DateTime.now().millisecondsSinceEpoch}.png'
      );
      await tempFile.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;
      context.pushNamed('preview', extra: tempFile.path);
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, '사진 촬영에 실패했습니다.', type: ToastType.error);
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case 'on':
        return Icons.flash_on_rounded;
      case 'auto':
        return Icons.flash_auto_rounded;
      case 'off':
      default:
        return Icons.flash_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener is retained at top-level to orchestrate async routing/toasts without causing parent rebuilds
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
          // ─── 1. Live Viewfinder Background (Optimized & Non-rebuilding Base) ───
          Positioned.fill(
            child: _buildCameraViewport(),
          ),

          // ─── 2. Viewfinder HUD Top (CAM-01 / AI ACTIVE / FLASH CONTROL) ───
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
                  const SizedBox(width: 10),
                  
                  // Flash Controller with 0ms visual update latency
                  _buildFlashToggleChip(),
                ],
              ),
            ),
          ),

          // ─── 2-B. Viewfinder HUD Top Right (MOCK TEST PANEL WITH FAILURE TRIGGER) ───
          Positioned(
            top: 24,
            right: 24,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ' MOCK 툴: ',
                      style: AppTextStyles.monoSm.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildMockButton(
                      label: '결함 감지',
                      color: AppColors.defect,
                      onTap: () {
                        ref.read(inspectionProvider.notifier).injectMockResult(hasDefect: true);
                        context.pushNamed('result-defect', extra: 'mock-inspection-id-12345678');
                      },
                    ),
                    const SizedBox(width: 4),
                    _buildMockButton(
                      label: '정상 완료',
                      color: AppColors.good,
                      onTap: () {
                        ref.read(inspectionProvider.notifier).injectMockResult(hasDefect: false);
                        context.pushNamed('result-normal', extra: 'mock-inspection-id-12345678');
                      },
                    ),
                    const SizedBox(width: 4),
                    _buildMockButton(
                      label: _hasCameraError ? '카메라 정상화' : '에러 시뮬레이션',
                      color: _hasCameraError ? AppColors.primary : const Color(0xFFFF5E5E),
                      onTap: () {
                        setState(() {
                          _hasCameraError = !_hasCameraError;
                          if (!_hasCameraError) {
                            _isCameraInitialized = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── 3. Center Reticle / Crosshair / Pulsing Focus Box ───
          if (!_hasCameraError && _isCameraInitialized)
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
                                color: AppColors.defect,
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
          if (!_hasCameraError && _isCameraInitialized)
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
                      
                      // Tactile 120dp double circular shutter button
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isShutterPressed = true),
                        onTapUp: (_) {
                          setState(() => _isShutterPressed = false);
                          _captureAndPreview();
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
                            child: Consumer(
                              builder: (context, ref, _) {
                                // Optimized localised rebuild: Only this small inner dot listens to the inspection provider states
                                final isCreating = ref.watch(inspectionProvider.select((s) => s.isCreating));
                                return Container(
                                  width: 98,
                                  height: 98,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCreating ? AppColors.primary : Colors.white,
                                  ),
                                  child: isCreating
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
                                );
                              },
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

  Widget _buildCameraViewport() {
    if (_hasCameraError) {
      return const _DarkPlaceholder();
    }

    if (!_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

    // Camera viewport mock with static 3x3 grid line drawing
    return Container(
      color: AppColors.background,
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
          // Live Scanning guidelines grid pattern (3x3 grid)
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPatternPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashToggleChip() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleFlash,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
          splashColor: AppColors.primary.withValues(alpha: 0.2),
          highlightColor: AppColors.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFlashIcon(),
                  size: 13,
                  color: _flashMode == 'off' ? AppColors.onSurfaceMuted : AppColors.primaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'FLASH: ${_flashMode.toUpperCase()}',
                  style: AppTextStyles.monoSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _flashMode == 'off' ? AppColors.onSurfaceMuted : AppColors.primaryLight,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: AppRadius.borderSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: AppTextStyles.monoSm.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
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
}

// ─── Custom Painter for Viewfinder 3x3 Grid Pattern ───────────────────────────────
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines (3x3 grid)
    final double rowHeight = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, i * rowHeight),
        Offset(size.width, i * rowHeight),
        paint,
      );
    }

    // Draw vertical grid lines (3x3 grid)
    final double colWidth = size.width / 3;
    for (int i = 1; i < 3; i++) {
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

// ─── Dark Fallback Placeholder for Camera Failure ──────────────────────────────────
class _DarkPlaceholder extends StatelessWidget {
  const _DarkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.defect.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.defect.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: AppColors.defect,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'CAMERA HARDWARE ERROR',
              style: AppTextStyles.monoSm.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.defect,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '초기화 실패 또는 카메라 장치가 연결 해제되었습니다.\n케이블 접촉 부위를 점검하거나 시스템을 재시작하십시오.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'TERM-X9 ERROR CODE: 0xE0023B',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
