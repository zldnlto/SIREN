import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../core/tokens.dart';
import '../models/annotation_domain.dart';
import '../providers/inspection_provider.dart';
import '../widgets/toast.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _focusCtrl;
  late final Animation<double> _focusScale;
  bool _isShutterPressed = false;
  
  // Camera mock-state variables for premium UX and performance optimization
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;
  String _flashMode = 'off'; // 'off' | 'on' | 'auto'
  String _deviceModel = 'CAM-01';
  AnnotationDomain _selectedDomain = AnnotationDomain.auto;

  // Inline progress overlay animations
  late final AnimationController _overlayCtrl;
  late final Animation<double> _overlayScale;
  late final Animation<double> _overlayFade;

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

    // Overlay transition configuration (springy entry + smooth fade)
    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _overlayScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeOutCubic),
    );
    _overlayFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _overlayCtrl, curve: Curves.easeIn),
    );

    // Warm up camera interface
    _initializeCamera();
    _loadDeviceModel();
  }

  Future<void> _loadDeviceModel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String model = 'CAM-01';
      if (kIsWeb) {
        model = 'Web Simulator';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        model = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.utsname.machine;
      }
      if (!mounted) return;
      setState(() {
        _deviceModel = model;
      });
    } catch (_) {
      // Fallback stays as CAM-01
    }
  }

  @override
  void dispose() {
    _focusCtrl.dispose();
    _overlayCtrl.dispose();
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

      final extraData = {
        'imagePath': 'mock-temp-image.png',
        'domain': _selectedDomain.apiValue,
      };

      if (kIsWeb) {
        // Fallback for web sandbox environments
        if (!mounted) return;
        context.pushNamed('preview', extra: extraData);
        return;
      }

      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/siren_capture_${DateTime.now().millisecondsSinceEpoch}.png'
      );
      await tempFile.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;
      context.pushNamed(
        'preview',
        extra: {
          'imagePath': tempFile.path,
          'domain': _selectedDomain.apiValue,
        },
      );
    } catch (e) {
      if (!mounted) return;
      Toast.show(
        context,
        '사진 촬영에 실패했습니다.',
        type: ToastType.error,
        actionLabel: '재시도',
        onAction: _captureAndPreview,
      );
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
    final inspectionState = ref.watch(inspectionProvider);
    final showOverlay = inspectionState.isCreating ||
        inspectionState.isDetecting ||
        inspectionState.isRagConnecting ||
        inspectionState.isReady;

    // Listener is retained at top-level to orchestrate async routing/toasts without causing parent rebuilds
    ref.listen<InspectionState>(inspectionProvider, (prev, next) {
      final showPrev = prev != null && (prev.isCreating || prev.isDetecting || prev.isRagConnecting || prev.isReady);
      final showNext = next.isCreating || next.isDetecting || next.isRagConnecting || next.isReady;
      
      if (showPrev != showNext) {
        if (showNext) {
          _overlayCtrl.forward();
        } else {
          _overlayCtrl.reverse();
        }
      }

      if (next.isReady && !(prev?.isReady ?? false)) {
        final route = next.nextRoute;
        if (route != null && next.inspection != null) {
          // Grant brief period for the user to see the 100% finished state
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.goNamed(route, extra: next.inspection!.id);
            }
          });
        }
      }

      if (next.error != null && prev?.error == null) {
        Toast.show(
          context,
          '검사 중 오류가 발생했습니다.',
          type: ToastType.error,
          actionLabel: '재시도',
          onAction: () => ref.read(inspectionProvider.notifier).start(_selectedDomain.apiValue),
        );
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
                          _deviceModel,
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
                  const SizedBox(width: 10),
                  _buildDomainSelectorChip(),
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
          
          // ─── 5. Inline Progress Overlay (Stack Top) ───
          if (showOverlay || _overlayCtrl.isAnimating)
            Positioned.fill(
              child: _buildProgressOverlay(inspectionState),
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

  Color _getFlashColor() {
    switch (_flashMode) {
      case 'on':
        return AppColors.warning;
      case 'auto':
        return AppColors.primaryLight;
      case 'off':
      default:
        return AppColors.onSurfaceMuted;
    }
  }

  Widget _buildFlashToggleChip() {
    return Container(
      width: 44,
      height: 44, // 44dp Touch target ensured
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
          child: Center(
            child: Icon(
              _getFlashIcon(),
              size: 20, // optimized icon size for tactile touch
              color: _getFlashColor(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDomainSelectorChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 44, // 44dp Touch target height matched
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AnnotationDomain>(
          value: _selectedDomain,
          dropdownColor: AppColors.surface,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.onSurfaceMuted,
          ),
          onChanged: (AnnotationDomain? newVal) {
            if (newVal != null) {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedDomain = newVal;
              });
            }
          },
          items: AnnotationDomain.values.map((domain) {
            return DropdownMenuItem<AnnotationDomain>(
              value: domain,
              child: Text(
                domain.label,
                style: AppTextStyles.monoSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: domain == AnnotationDomain.auto ? AppColors.primaryLight : AppColors.onSurface,
                ),
              ),
            );
          }).toList(),
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

  // ─── Progress Overlay Render Helpers ────────────────────────────────────────────────
  Widget _buildProgressOverlay(InspectionState state) {
    final steps = _calculateSteps(state, _selectedDomain);

    return AnimatedBuilder(
      animation: _overlayCtrl,
      builder: (context, child) {
        return FadeTransition(
          opacity: _overlayFade,
          child: ScaleTransition(
            scale: _overlayScale,
            alignment: const Alignment(0.0, 0.75), // Aligned with physical shutter button
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          // 1. Refractive blurring overlay backplate
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                color: AppColors.background.withValues(alpha: 0.85),
              ),
            ),
          ),
          
          // 2. Control overlay content container
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Top Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI REAL-TIME INSPECTION',
                            style: AppTextStyles.sectionHeader.copyWith(
                              color: AppColors.primaryLight,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '실시간 검사 및 AI 분석 진행 중',
                            style: AppTextStyles.headlineMd.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (state.inspection != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.borderSm,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'ID: ${state.inspection!.id.substring(0, math.min(8, state.inspection!.id.length))}',
                            style: AppTextStyles.monoSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // 6-step checklist card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.5),
                        borderRadius: AppRadius.borderXl,
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: steps.map((step) => _buildStepRow(step)).toList(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Emergency Cancel Button
                  _buildOverlayControlPanel(state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(ProgressStep step) {
    Color iconColor;
    Widget leadingWidget;
    TextStyle textStyle;

    switch (step.status) {
      case StepStatus.done:
        iconColor = AppColors.good;
        leadingWidget = Icon(Icons.check_circle_rounded, color: iconColor, size: 22);
        textStyle = AppTextStyles.bodyStrong.copyWith(
          color: AppColors.onSurface,
          fontSize: 16,
        );
        break;
      case StepStatus.running:
        iconColor = AppColors.primary;
        leadingWidget = const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
        textStyle = AppTextStyles.bodyStrong.copyWith(
          color: AppColors.primaryLight,
          fontSize: 16,
        );
        break;
      case StepStatus.pending:
      default:
        iconColor = AppColors.onSurfaceMuted;
        leadingWidget = Icon(Icons.radio_button_unchecked_rounded, color: iconColor, size: 22);
        textStyle = AppTextStyles.bodySm.copyWith(
          color: AppColors.onSurfaceMuted,
          fontSize: 16,
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          leadingWidget,
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              step.label,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayControlPanel(InspectionState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: AppColors.defect.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
          onTap: () {
            HapticFeedback.mediumImpact();
            ref.read(inspectionProvider.notifier).reset();
          },
          splashColor: AppColors.defect.withValues(alpha: 0.15),
          highlightColor: AppColors.defect.withValues(alpha: 0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.stop_circle_outlined,
                color: AppColors.defect,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'STOP INSPECTION (검사 비상 중단)',
                style: AppTextStyles.buttonLg.copyWith(
                  fontSize: 16.5,
                  color: AppColors.defect,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ProgressStep> _calculateSteps(InspectionState state, AnnotationDomain selectedDomain) {
    final domainLabel = state.inspection != null
        ? (AnnotationDomain.values.firstWhere(
            (d) => d.apiValue == state.inspection!.annotationDomain,
            orElse: () => selectedDomain,
          ).label)
        : selectedDomain.label;

    // Step 1: 이미지 전송
    final step1Status = state.inspection != null
        ? StepStatus.done
        : (state.isCreating ? StepStatus.running : StepStatus.pending);
    final step1Label = step1Status == StepStatus.running
        ? '이미지 전송 중...'
        : '이미지 전송 완료';

    // Step 2: 공정 검사 시작
    final step2Status = state.inspection != null ? StepStatus.done : StepStatus.pending;
    final step2Label = '[$domainLabel] 도메인으로 검사 시작';

    // Step 3: AI 결함 탐지
    StepStatus step3Status;
    if (state.result != null) {
      step3Status = StepStatus.done;
    } else if (state.inspection != null && state.isDetecting) {
      step3Status = StepStatus.running;
    } else {
      step3Status = StepStatus.pending;
    }
    final step3Label = step3Status == StepStatus.running
        ? 'AI 결함 탐지 중...'
        : 'AI 결함 탐지 완료';

    // Step 4: 결함 건수
    final step4Status = state.result != null ? StepStatus.done : StepStatus.pending;
    String step4Label = '결함 분석 대기';
    if (state.result != null) {
      final defectCount = state.result!.defects.length;
      step4Label = defectCount > 0 ? '결함 $defectCount건 검출' : '결함 없음';
    }

    // Step 5: RAG 연결
    StepStatus step5Status;
    if (state.isReady) {
      step5Status = StepStatus.done;
    } else if (state.result != null && state.isRagConnecting) {
      step5Status = StepStatus.running;
    } else {
      step5Status = StepStatus.pending;
    }
    final step5Label = step5Status == StepStatus.running
        ? 'RAG 조치 안내 연결 중...'
        : 'RAG 조치 안내 연결 완료';

    // Step 6: 조치 가이드 준비 완료
    final step6Status = state.isReady ? StepStatus.done : StepStatus.pending;
    final step6Label = '조치 가이드 준비 완료';

    return [
      ProgressStep(label: step1Label, status: step1Status),
      ProgressStep(label: step2Label, status: step2Status),
      ProgressStep(label: step3Label, status: step3Status),
      ProgressStep(label: step4Label, status: step4Status),
      ProgressStep(label: step5Label, status: step5Status),
      ProgressStep(label: step6Label, status: step6Status),
    ];
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

enum StepStatus { pending, running, done }

class ProgressStep {
  final String label;
  final StepStatus status;

  const ProgressStep({required this.label, required this.status});
}
