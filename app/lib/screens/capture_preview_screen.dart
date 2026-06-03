import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../providers/inspection_provider.dart';
import '../widgets/siren_button.dart';

class CapturePreviewScreen extends ConsumerStatefulWidget {
  const CapturePreviewScreen({super.key, required this.imagePath});
  final String imagePath;

  @override
  ConsumerState<CapturePreviewScreen> createState() => _CapturePreviewScreenState();
}

class _CapturePreviewScreenState extends ConsumerState<CapturePreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Emil Kowalski Principle: 200ms ease-out transitions from bottom to center
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Start offset is (0, 0.04) as requested by motion specifications, avoiding scale(0)
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    // Run entry transition
    if (!kIsWeb && MediaQuery.of(context).disableAnimations) {
      _animCtrl.value = 1.0;
    } else {
      _animCtrl.forward();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _cleanupTempFile(); // Cleanup memory leaks/storage on exit
    super.dispose();
  }

  void _cleanupTempFile() {
    if (kIsWeb) return;
    try {
      final file = File(widget.imagePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {
      // Gracefully capture exception if file is locked or already deleted
    }
  }

  void _handleRetake() {
    // Asymmetric timing: Retake should pop quickly (150ms) as a fast system response
    _cleanupTempFile();
    Navigator.of(context).pop();
  }

  Future<void> _handleStartInspection() async {
    // Asymmetric timing: Intentional transition with 220ms delay before entering progress screen
    HapticFeedback.mediumImpact();
    
    // Smooth exit animations transition out
    await _animCtrl.reverse();
    
    if (!mounted) return;
    
    // Launch the backend inspection creation call
    ref.read(inspectionProvider.notifier).start('surface_treatment');
    
    // Route to the real-time AI progress analysis screen
    // We already listening to inspectionProvider in HomeScreen, but pushing progress ensures routing
    final state = ref.read(inspectionProvider);
    if (state.inspection != null) {
      context.goNamed('progress', extra: state.inspection!.id);
    } else {
      // If not created yet (starts async loading), progress screen will be handled by Riverpod listener
      // but we force transition to home to let HomeRiverpod listener catch state.
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMock = widget.imagePath == 'mock-temp-image.png';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Sleek Top Bar HUD
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PREVIEW FRAME',
                      style: AppTextStyles.monoSm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.8),
                        borderRadius: AppRadius.borderXs,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'UNRESOLVED',
                        style: AppTextStyles.monoSm.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Main Image Workspace (16px rounded + 1px hairline border)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppRadius.borderXl,
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: isMock
                              ? Opacity(
                                  opacity: 0.15,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.defect,
                                      size: 48,
                                    ),
                                  ),
                                ),
                        ),
                        // Soft inner diagnostic corners
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PreviewCornerPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. Tactile 72dp Asymmetric Buttons (flex: 2 vs 3, height: 72)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 72, // 72dp tactile touch target for gloves
                        child: SirenButton(
                          label: '다시 찍기',
                          variant: SirenButtonVariant.secondary,
                          icon: const Icon(Icons.replay_rounded, size: 22),
                          onPressed: _handleRetake,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 72, // 72dp tactile touch target for gloves
                        child: SirenButton(
                          label: '검사 시작',
                          size: SirenButtonSize.xl,
                          icon: const Icon(Icons.rocket_launch_rounded, size: 22),
                          onPressed: _handleStartInspection,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Painter for diagnostic crosshair frame corners ───────────────────────────
class _PreviewCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double len = 20.0;

    // Top-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(len, 0)
        ..lineTo(0, 0)
        ..lineTo(0, len),
      paint,
    );

    // Top-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      paint,
    );

    // Bottom-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(len, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - len),
      paint,
    );

    // Bottom-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
