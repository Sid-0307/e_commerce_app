import 'dart:math' as math;
import 'package:e_commerce_app/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:simple_animations/animation_builder/custom_animation_builder.dart';
import 'package:simple_animations/movie_tween/movie_tween.dart';

// Singleton to manage persistent animation controllers
class BackgroundDecorations {
  static final BackgroundDecorations _instance = BackgroundDecorations._internal();
  factory BackgroundDecorations() => _instance;
  BackgroundDecorations._internal();

  AnimationController? _blob1Controller;
  AnimationController? _particlesController;
  List<ParticleModel>? _particles;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  AnimationController? get blob1Controller => _blob1Controller;
  AnimationController? get particlesController => _particlesController;
  List<ParticleModel>? get particles => _particles;

  void initialize(TickerProvider vsync) {
    if (!_isInitialized) {
      _blob1Controller = AnimationController(
        vsync: vsync,
        duration: const Duration(seconds: 12),
      )..repeat();

      _particlesController = AnimationController(
        vsync: vsync,
        duration: const Duration(seconds: 30),
      )..repeat();

      _particles = List.generate(100, (index) => ParticleModel());
      _isInitialized = true;
    }
  }

  void dispose() {
    _blob1Controller?.dispose();
    _particlesController?.dispose();
    _blob1Controller = null;
    _particlesController = null;
    _particles = null;
    _isInitialized = false;
  }
}

// Updated BackgroundDecorations using the singleton
class BackgroundDecorationsState extends StatefulWidget {
  const BackgroundDecorationsState({super.key});

  @override
  State<BackgroundDecorationsState> createState() => _BackgroundDecorationsState();
}

class _BackgroundDecorationsState extends State<BackgroundDecorationsState>
    with TickerProviderStateMixin {
  late BackgroundDecorations _manager;

  @override
  void initState() {
    super.initState();
    _manager = BackgroundDecorations();
    _manager.initialize(this);
  }

  @override
  Widget build(BuildContext context) {
    if (!_manager.isInitialized) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Floating particles
        ...(_manager.particles?.map((particle) => _buildParticle(particle, context)) ?? []),

        // Top blob
        Positioned(
          left: -100,
          top: -50,
          right: -100,
          child: _buildBlob1(),
        ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withOpacity(0.1),
                AppColors.background.withOpacity(0.3),
                AppColors.background.withOpacity(0.5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlob1() {
    return AnimatedBuilder(
      animation: _manager.blob1Controller!,
      builder: (context, child) {
        final value = _manager.blob1Controller!.value;
        final scale = 1.0 + 0.1 * math.sin(value * math.pi * 2);

        return Transform.translate(
          offset: const Offset(0, 0),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: 1,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(200),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticle(ParticleModel particle, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _manager.particlesController!,
      builder: (context, child) {
        final progress = ((_manager.particlesController!.value + particle.initialProgress) % 1.0);

        return Positioned(
          left: screenWidth * (particle.x + 0.1 * math.sin(progress * math.pi * 2)),
          top: screenHeight * progress,
          child: Transform.rotate(
            angle: progress * math.pi * 2,
            child: Opacity(
              opacity: particle.opacity * math.sin(progress * math.pi),
              child: Container(
                width: particle.size,
                height: particle.size,
                decoration: BoxDecoration(
                  color: particle.color,
                  borderRadius: BorderRadius.circular(particle.size / 2),
                  boxShadow: [
                    BoxShadow(
                      color: particle.color.withOpacity(0.3),
                      blurRadius: 2,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Don't dispose the singleton controllers in individual widgets
  @override
  void dispose() {
    // The singleton will manage its own lifecycle
    super.dispose();
  }
}

// Your ParticleModel class (keep as is)
class ParticleModel {
  final double x;
  final double size;
  final Color color;
  final double opacity;
  final double initialProgress;

  ParticleModel()
      : x = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 4 + 2,
        color = _getRandomColor(),
        opacity = 0.8,
        initialProgress = math.Random().nextDouble();

  static Color _getRandomColor() {
    final colors = [
      AppColors.primary.withOpacity(0.3),
      AppColors.secondary.withOpacity(0.3),
      Colors.white.withOpacity(0.2),
      const Color(0xFF1E3B70).withOpacity(0.25),
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
}

// Alternative implementation with simple_animations package
class AnimatedBackgroundDecorations extends StatelessWidget {
  final Widget child;

  const AnimatedBackgroundDecorations({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Create the movie tween
    final MovieTween movieTween = MovieTween()
    // Blob 1 animations
      ..scene(
          begin: const Duration(seconds: 0),
          end: const Duration(seconds: 10))
          .tween('blob1X', Tween<double>(begin: -120.0, end: -80.0), curve: Curves.easeInOut)
          .tween('blob1Y', Tween<double>(begin: -70.0, end: -30.0), curve: Curves.easeInOut)
          .tween('blob1Scale', Tween<double>(begin: 1.0, end: 1.1), curve: Curves.easeInOut)
          .tween('blob1Opacity', Tween<double>(begin:1, end: 1), curve: Curves.easeInOut)

      ..scene(
          begin: const Duration(seconds: 10),
          end: const Duration(seconds: 20))
          .tween('blob1X', Tween<double>(begin: -80.0, end: -120.0), curve: Curves.easeInOut)
          .tween('blob1Y', Tween<double>(begin: -30.0, end: -70.0), curve: Curves.easeInOut)
          .tween('blob1Scale', Tween<double>(begin: 1.1, end: 1.0), curve: Curves.easeInOut)
          .tween('blob1Opacity', Tween<double>(begin: 1, end: 1), curve: Curves.easeInOut);

    return CustomAnimationBuilder(
      duration: const Duration(seconds: 20),
      tween: movieTween,
      control: Control.loop, // Makes the animation loop continuously
      builder: (context, value, child) {
        return Stack(
          children: [
            // Top blob
            Positioned(
              left: value.get('blob1X'),
              top: value.get('blob1Y'),
              right: -100,
              child: Transform.scale(
                scale: value.get('blob1Scale'),
                child: Opacity(
                  opacity: value.get('blob1Opacity'),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(200),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            child!,
          ],
        );
      },
      // child:child,
    );
  }}