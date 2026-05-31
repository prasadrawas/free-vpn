import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';

class ConnectButton extends StatefulWidget {
  const ConnectButton({super.key});

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _scaleController.view;
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _updateAnimations(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connecting:
        _rotationController.repeat();
        _pulseController.stop();
        _pulseController.reset();
        break;
      case ConnectionStatus.connected:
        _rotationController.stop();
        _rotationController.reset();
        _pulseController.repeat(reverse: true);
        break;
      default:
        _rotationController.stop();
        _rotationController.reset();
        _pulseController.stop();
        _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, provider, _) {
        _updateAnimations(provider.connectionStatus);

        final isConnected =
            provider.connectionStatus == ConnectionStatus.connected;
        final isConnecting =
            provider.connectionStatus == ConnectionStatus.connecting;
        final isDisconnecting =
            provider.connectionStatus == ConnectionStatus.disconnecting;

        final Color glowColor;
        final Color borderColor;
        final IconData icon;

        if (isConnected && _isPressed) {
          glowColor = AppTheme.accentRed.withValues(alpha: 0.3);
          borderColor = AppTheme.accentRed;
          icon = Icons.power_settings_new_rounded;
        } else if (isConnected) {
          glowColor = AppTheme.accentGreen.withValues(alpha: 0.3);
          borderColor = AppTheme.accentGreen;
          icon = Icons.shield_rounded;
        } else if (isConnecting || isDisconnecting) {
          glowColor = AppTheme.accentCyan.withValues(alpha: 0.2);
          borderColor = AppTheme.accentCyan;
          icon = Icons.sync_rounded;
        } else {
          glowColor = AppTheme.accentCyan.withValues(alpha: 0.15);
          borderColor = AppTheme.accentCyan;
          icon = Icons.power_settings_new_rounded;
        }

        return GestureDetector(
          onTapDown: (_) {
            _scaleController.reverse();
            if (mounted) setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            _scaleController.forward();
            if (mounted) setState(() => _isPressed = false);
            _onTap(provider);
          },
          onTapCancel: () {
            _scaleController.forward();
            if (mounted) setState(() => _isPressed = false);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [_rotationController, _pulseAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              Transform.scale(
                scale: _scaleAnimation.value,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow pulse
                      if (isConnected)
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor,
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Rotating gradient ring (connecting)
                      if (isConnecting || isDisconnecting)
                        Transform.rotate(
                          angle: _rotationController.value * 2 * pi,
                          child: CustomPaint(
                            size: const Size(200, 200),
                            painter: _GradientRingPainter(
                              colors: [AppTheme.accentCyan, AppTheme.accentPurple, AppTheme.accentCyan],
                              strokeWidth: 3,
                            ),
                          ),
                        ),

                      // Main circle
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceDark,
                          border: Border.all(
                            color: isConnecting || isDisconnecting
                                ? Colors.transparent
                                : borderColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor,
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                icon,
                                key: ValueKey(icon),
                                size: 48,
                                color: isConnected
                                    ? AppTheme.accentGreen
                                    : AppTheme.accentCyan,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                isConnected && _isPressed
                                    ? 'DISCONNECT'
                                    : isConnected
                                        ? 'CONNECTED'
                                        : isConnecting
                                            ? 'CONNECTING'
                                            : isDisconnecting
                                                ? 'STOPPING'
                                                : 'CONNECT',
                                key: ValueKey('${provider.connectionStatus}_$_isPressed'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: isConnected && _isPressed
                                      ? AppTheme.accentRed
                                      : isConnected
                                          ? AppTheme.accentGreen
                                          : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: isConnected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Text(
                  'Tap to disconnect',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _onTap(VpnProvider provider) {
    switch (provider.connectionStatus) {
      case ConnectionStatus.connected:
      case ConnectionStatus.connecting:
        provider.disconnect();
        break;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        if (provider.selectedServer != null) {
          provider.connectToServer();
        } else {
          provider.autoConnect();
        }
        break;
      default:
        break;
    }
  }
}

class _GradientRingPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;

  _GradientRingPainter({required this.colors, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = SweepGradient(colors: colors).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      0,
      2 * pi * 0.75,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth || oldDelegate.colors != colors;
}
