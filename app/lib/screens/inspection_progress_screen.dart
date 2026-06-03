import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../providers/inspection_provider.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_card.dart';
import '../widgets/toast.dart';

class InspectionProgressScreen extends ConsumerStatefulWidget {
  const InspectionProgressScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  ConsumerState<InspectionProgressScreen> createState() =>
      _InspectionProgressScreenState();
}

class _InspectionProgressScreenState
    extends ConsumerState<InspectionProgressScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  Timer? _logTimer;
  Timer? _progressTimer;
  double _simulatedProgress = 0.0;
  int _logIndex = 0;

  // YOLO Real-time Simulator State
  final List<_SimulatedBBox> _activeBBoxes = [];
  final math.Random _random = math.Random();

  final List<String> _consoleLogsPool = [
    'SYSTEM: Initializing YOLOv8 inference pipeline...',
    'CUDA: Device [0] GeForce RTX 4090 detected and cached.',
    'YOLO: Loading weld seam weights [siren_yolov8_nano.pt]...',
    'YOLO: Anchor resolution set to 640x640, inference batch=1.',
    'RAG: Pre-loading LNG membrane structural specifications...',
    'SEAM: Scanning weld path alignment on Section B-3...',
    'DECT: Analyzing frame 12... [OK]',
    'DECT: Analyzing frame 45... [OK]',
    'DECT: Analyzing frame 78... [OK]',
    'WARNING: Porosity anomaly detected at seam point Y=142.4 (Conf: 94.2%)',
    'RAG: Vectorizing local geometry descriptor for RAG match...',
    'RAG: Retrieved 3 semantic matching records from DB.',
    'DECT: Analyzing frame 120... [OK]',
    'DECT: Analyzing frame 156... [OK]',
    'SEAM: Continuous weld bead inspected. Status: Tracking...',
    'WARNING: Micro-crack warning generated at edge vertex X=48.2 (Conf: 89.1%)',
    'DECT: Analyzing frame 198... [OK]',
    'DECT: Analyzing frame 220... [OK]',
    'SYSTEM: Compiling inspection timeline logs...',
    'RAG: Constructing onsite mitigation suggestions...',
    'YOLO: Finalizing bounding box annotations...',
    'CORE: Dispatching payload to FastAPI backend server...'
  ];

  @override
  void initState() {
    super.initState();
    
    // 1. Scan Line Animation Controller
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 2. Run Actual detection call
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDetection());

    // 3. Start Terminal Simulation
    _startTerminalSimulation();

    // 4. Start Progress Simulation (to smoothly glide from 0% to 99%)
    _startProgressSimulation();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _logTimer?.cancel();
    _progressTimer?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  void _runDetection() {
    ref.read(inspectionProvider.notifier).runDetection(widget.inspectionId);
  }

  void _startTerminalSimulation() {
    // Add initial log immediately
    _addLog('SYSTEM: Inspection process initiated.');
    
    _logTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) return;
      if (_logIndex < _consoleLogsPool.length) {
        _addLog(_consoleLogsPool[_logIndex]);
        _logIndex++;
        
        // Randomly generate bounding boxes on the scanner simulation
        if (_random.nextDouble() > 0.4) {
          _generateRandomBBox();
        }
      } else {
        // Loop simulation logs to keep it active
        _logIndex = 0;
      }
    });
  }

  void _startProgressSimulation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      
      final state = ref.read(inspectionProvider);
      
      setState(() {
        if (state.isDetecting) {
          // Smooth glide up to 99%
          if (_simulatedProgress < 98.0) {
            _simulatedProgress += _random.nextDouble() * 1.5;
          } else if (_simulatedProgress < 99.4) {
            _simulatedProgress += 0.05;
          }
        } else if (state.error != null) {
          _progressTimer?.cancel();
        } else {
          // Finished successfully, jump to 100%
          _simulatedProgress = 100.0;
          _progressTimer?.cancel();
        }
      });
    });
  }

  void _addLog(String text) {
    if (!mounted) return;
    final timeStr = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _logs.add('[$timeStr] $text');
    });

    // Auto-scroll to bottom with micro delay to allow layout build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: AppDurations.fast,
          curve: AppCurves.standard,
        );
      }
    });
  }

  void _generateRandomBBox() {
    final hasDefect = _random.nextDouble() > 0.6;
    final x = 40.0 + _random.nextDouble() * 200.0;
    final y = 40.0 + _random.nextDouble() * 140.0;
    final w = 50.0 + _random.nextDouble() * 70.0;
    final h = 30.0 + _random.nextDouble() * 50.0;
    
    final label = hasDefect 
        ? 'Weld Porosity ${(85 + _random.nextDouble() * 14).toStringAsFixed(1)}%' 
        : 'Seam Bead Approved';
        
    final newBox = _SimulatedBBox(
      rect: Rect.fromLTWH(x, y, w, h),
      label: label,
      isDefect: hasDefect,
      duration: const Duration(seconds: 2),
    );

    setState(() {
      _activeBBoxes.add(newBox);
    });

    // Automatically remove after its duration expires
    Timer(newBox.duration, () {
      if (mounted) {
        setState(() {
          _activeBBoxes.remove(newBox);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);

    ref.listen(inspectionProvider, (prev, next) {
      final route = next.nextRoute;
      if (route != null && prev?.nextRoute == null) {
        context.goNamed(route, extra: widget.inspectionId);
      }
      if (next.error != null && prev?.error == null) {
        Toast.show(
          context,
          '검사 중 오류가 발생했습니다.',
          type: ToastType.error,
          actionLabel: '재시도',
          onAction: _runDetection,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ─── Lavender Aura Glow Background ─────────────────────────────────
          Positioned(
            top: -200,
            right: -200,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ─── Main Scaffold Body ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  // 1. Sleek Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI REAL-TIME INSPECTION',
                            style: AppTextStyles.sectionHeader,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            children: [
                              Text(
                                '실시간 결함 검출 진단 중',
                                style: AppTextStyles.headlineMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _PulsingStatusLed(),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'ID: ${widget.inspectionId.substring(0, math.min(8, widget.inspectionId.length))}',
                          style: AppTextStyles.monoSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Main Simulator Grid (Expanded on tablet, stack on mobile)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet = constraints.maxWidth > AppBreakpoints.tablet;
                        
                        final simulatorWidget = _buildYoloSimulator();
                        final consoleWidget = _buildConsoleTerminal();

                        if (isTablet) {
                          // Horizontal split for tablet
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 3, child: simulatorWidget),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(flex: 2, child: consoleWidget),
                            ],
                          );
                        } else {
                          // Vertical layout for mobile
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: simulatorWidget),
                              const SizedBox(height: AppSpacing.md),
                              Expanded(flex: 3, child: consoleWidget),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Precise Progress Bar
                  _buildPrecisionProgress(state),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Control Buttons (50px Sporty Height with feedback)
                  _buildControlPanel(state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYoloSimulator() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderXl, // 16px rounded corners
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Custom Paint representing LNG cargo wall
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _YoloSimulatorPainter(
                    scanProgress: _scanController.value,
                    bboxes: _activeBBoxes,
                  ),
                );
              },
            ),
          ),
          
          // Simulation Header Overlay
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: AppRadius.borderXs,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.defect, // Red recording point
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE STREAM',
                    style: AppTextStyles.monoSm.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FPS & Diagnostics Overlay
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: AppRadius.borderXs,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'FPS: 29.8 | THR: 0.65',
                style: AppTextStyles.monoSm.copyWith(
                  fontSize: 10,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleTerminal() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIAGNOSTIC STATUS CONSOLE',
                style: AppTextStyles.sectionHeader.copyWith(
                  fontSize: 11,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const Icon(
                Icons.terminal,
                size: 14,
                color: AppColors.onSurfaceMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(color: AppColors.border, height: 1.0),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      'No logs active...',
                      style: AppTextStyles.monoSm.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _logScrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      // Highlight warning logs
                      final isWarning = log.contains('WARNING') || log.contains('defect');
                      final isSystem = log.contains('SYSTEM') || log.contains('INIT');
                      
                      Color logColor = AppColors.onSurfaceVariant;
                      if (isWarning) {
                        logColor = AppColors.defect;
                      } else if (isSystem) {
                        logColor = AppColors.primaryLight;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          log,
                          style: AppTextStyles.monoSm.copyWith(
                            color: logColor,
                            fontSize: 11.5,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecisionProgress(InspectionState state) {
    return SirenCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.isDetecting ? 'AI 결함 스캔 중...' : '스캔 분석 완료',
                style: AppTextStyles.bodyStrong.copyWith(
                  fontSize: 14,
                ),
              ),
              Text(
                '${_simulatedProgress.toStringAsFixed(1)}%',
                style: AppTextStyles.monoLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.borderFull,
            child: SizedBox(
              height: 2, // ultra precise thin progress line
              child: LinearProgressIndicator(
                value: _simulatedProgress / 100.0,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(InspectionState state) {
    if (state.error != null) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 64, // glove-friendly height
              child: SirenButton(
                label: '다시 시도',
                size: SirenButtonSize.xl,
                onPressed: _runDetection,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: 64, // glove-friendly height
              child: SirenButton(
                label: '홈으로',
                size: SirenButtonSize.xl,
                variant: SirenButtonVariant.secondary,
                onPressed: () => context.go('/home'),
              ),
            ),
          ),
        ],
      );
    }

    // 64px Height Glove-friendly Cancel/Stop button
    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.standard,
      width: double.infinity,
      height: 64, // glove-friendly height
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: AppColors.defect.withOpacity(0.4),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
          onTap: () {
            // Cancel process and return to home
            ref.read(inspectionProvider.notifier).reset();
            context.go('/home');
          },
          splashColor: AppColors.defect.withOpacity(0.15),
          highlightColor: AppColors.defect.withOpacity(0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.stop_circle_outlined,
                color: AppColors.defect,
                size: 24, // enlarged icon size
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'STOP INSPECTION (검사 비상 중단)',
                style: AppTextStyles.buttonLg.copyWith(
                  fontSize: 16.5, // matching SirenButtonSize.xl text size
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
}

// ─── Status Led Indicator Widget ─────────────────────────────────────────────
class _PulsingStatusLed extends StatefulWidget {
  @override
  State<_PulsingStatusLed> createState() => _PulsingStatusLedState();
}

class _PulsingStatusLedState extends State<_PulsingStatusLed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              AppColors.good.withOpacity(0.4),
              AppColors.good,
              _pulseController.value,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.good.withOpacity(0.6 * _pulseController.value),
                blurRadius: 6 * _pulseController.value,
                spreadRadius: 2 * _pulseController.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Simulated Bounding Box Entity ──────────────────────────────────────────
class _SimulatedBBox {
  const _SimulatedBBox({
    required this.rect,
    required this.label,
    required this.isDefect,
    required this.duration,
  });

  final Rect rect;
  final String label;
  final bool isDefect;
  final Duration duration;
}

// ─── Custom Painter for YOLO Simulator ───────────────────────────────────────
class _YoloSimulatorPainter extends CustomPainter {
  const _YoloSimulatorPainter({
    required this.scanProgress,
    required this.bboxes,
  });

  final double scanProgress;
  final List<_SimulatedBBox> bboxes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.surface;

    // Draw background base color (handled by container but paint just in case)
    canvas.drawRect(Offset.zero & size, paint);

    // 1. Draw grid pattern (Technical lines)
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.3)
      ..strokeWidth = 0.5;

    const gridSize = 30.0;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += gridSize) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    // 2. Draw mock LNG Cargo welded seam tracks (vertical pipelines)
    final seamPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 4.0;
    final seamDotPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double seam1X = size.width * 0.35;
    final double seam2X = size.width * 0.65;

    // Vertical solid backing rails
    canvas.drawLine(Offset(seam1X, 0), Offset(seam1X, size.height), seamPaint);
    canvas.drawLine(Offset(seam2X, 0), Offset(seam2X, size.height), seamPaint);

    // Simulated weld beads patterns (Dotted seam joints)
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawCircle(Offset(seam1X, y), 2.5, seamDotPaint);
      canvas.drawCircle(Offset(seam2X, y), 2.5, seamDotPaint);
    }

    // 3. Draw Active Bounding Boxes
    for (final bbox in bboxes) {
      // Scale coordinates matching simulator size dynamically
      final scaleX = size.width / 320.0;
      final scaleY = size.height / 240.0;

      final Rect scaledRect = Rect.fromLTRB(
        bbox.rect.left * scaleX,
        bbox.rect.top * scaleY,
        bbox.rect.right * scaleX,
        bbox.rect.bottom * scaleY,
      );

      final boxColor = bbox.isDefect ? AppColors.defect : AppColors.good;

      // Draw semi-transparent box fill
      final fillPaint = Paint()
        ..color = boxColor.withOpacity(0.06)
        ..style = PaintingStyle.fill;
      canvas.drawRect(scaledRect, fillPaint);

      // Draw bounding box borders
      final borderPaint = Paint()
        ..color = boxColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(scaledRect, borderPaint);

      // Draw high-tech corner brackets (8px L-shapes)
      final cornerPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      const double l = 8.0;
      // Top Left Corner
      canvas.drawLine(scaledRect.topLeft, scaledRect.topLeft.translate(l, 0), cornerPaint);
      canvas.drawLine(scaledRect.topLeft, scaledRect.topLeft.translate(0, l), cornerPaint);
      // Top Right Corner
      canvas.drawLine(scaledRect.topRight, scaledRect.topRight.translate(-l, 0), cornerPaint);
      canvas.drawLine(scaledRect.topRight, scaledRect.topRight.translate(0, l), cornerPaint);
      // Bottom Left Corner
      canvas.drawLine(scaledRect.bottomLeft, scaledRect.bottomLeft.translate(l, 0), cornerPaint);
      canvas.drawLine(scaledRect.bottomLeft, scaledRect.bottomLeft.translate(0, -l), cornerPaint);
      // Bottom Right Corner
      canvas.drawLine(scaledRect.bottomRight, scaledRect.bottomRight.translate(-l, 0), cornerPaint);
      canvas.drawLine(scaledRect.bottomRight, scaledRect.bottomRight.translate(0, -l), cornerPaint);

      // Draw text label on box top left
      final textSpan = TextSpan(
        text: bbox.label.toUpperCase(),
        style: TextStyle(
          color: boxColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrainsMono',
          backgroundColor: Colors.black.withOpacity(0.85),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, scaledRect.topLeft.translate(4, -12));
    }

    // 4. Draw Laser Scanline
    final double scanY = size.height * scanProgress;
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.0),
          AppColors.primary,
          AppColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 15, size.width, 30))
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanLinePaint);

    // Glowing aura effect around scanline
    final scanGlowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, scanY - 8, size.width, scanY + 8), scanGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _YoloSimulatorPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress || oldDelegate.bboxes != bboxes;
  }
}
