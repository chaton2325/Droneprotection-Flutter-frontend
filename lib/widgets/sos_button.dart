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

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _controller.addStatusListener(_handleStatus);
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
        animation: _controller,
        builder: (context, child) {
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
                    valueColor: const AlwaysStoppedAnimation(AppColors.brand400),
                    semanticsLabel: 'Maintenez pour confirmer',
                  ),
                ),
                Container(
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
                        color: AppColors.brand600.withValues(alpha: 0.45),
                        blurRadius: 44,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.busy
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_rounded, color: Colors.white, size: 44),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
