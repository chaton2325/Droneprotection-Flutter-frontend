import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Gros bouton d'urgence a "maintenir pour confirmer" : evite le
/// declenchement accidentel d'une alerte sur un simple appui.
class SosButton extends StatefulWidget {
  final Future<void> Function() onConfirmed;
  final bool busy;

  const SosButton({super.key, required this.onConfirmed, this.busy = false});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with TickerProviderStateMixin {
  late final AnimationController _controller;
  // Pulsation continue au repos pour attirer l'attention sur le bouton
  // d'urgence (glow qui "respire"), desactivee des que l'utilisateur
  // commence a maintenir le bouton ou qu'une action est en cours.
  late final AnimationController _pulseController;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _controller.addStatusListener(_handleStatus);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_triggered) {
      _triggered = true;
      widget.onConfirmed().whenComplete(() {
        if (!mounted) return;
        _controller.reset();
        setState(() => _triggered = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.busy || _triggered) return;
    _controller.forward(from: 0);
  }

  void _cancel() {
    if (_triggered) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _cancel(),
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _pulseController]),
        builder: (context, child) {
          final idle = _controller.value == 0 && !widget.busy;
          final pulse = idle ? _pulseController.value : 0.0;
          return SizedBox(
            width: 224,
            height: 224,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 224,
                  height: 224,
                  child: CircularProgressIndicator(
                    value: _controller.value == 0 ? null : _controller.value,
                    strokeWidth: 5,
                    backgroundColor: AppColors.surface2,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.brand400,
                    ),
                    semanticsLabel: 'Maintenez pour confirmer',
                  ),
                ),
                Transform.scale(
                  scale: 1 + pulse * 0.06,
                  child: Container(
                    width: 184,
                    height: 184,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.brand400, AppColors.brand700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand600.withValues(
                            alpha: 0.45 + pulse * 0.4,
                          ),
                          blurRadius: 44 + pulse * 30,
                          spreadRadius: 2 + pulse * 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.busy
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                    letterSpacing: 3,
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
        },
      ),
    );
  }
}
