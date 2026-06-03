import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vpn_provider.dart';
import '../services/battery_optimization_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connect_button.dart';
import '../widgets/connection_timer.dart';
import '../widgets/status_display.dart';
import 'server_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _offlineShown = false;
  bool _batteryCheckDone = false;
  bool _notificationCheckDone = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<VpnProvider>(
        builder: (context, provider, _) {
          final isConnected =
              provider.connectionStatus == ConnectionStatus.connected;

          // Show offline warning
          if (provider.serverWentOffline && !_offlineShown) {
            _offlineShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showOfflineWarning(context, provider);
            });
          }
          if (!provider.serverWentOffline) {
            _offlineShown = false;
          }

          // Check battery optimization on first connection
          if (isConnected && !_batteryCheckDone) {
            _batteryCheckDone = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkBatteryOptimization();
            });
          }

          // Check notification permission on first connection
          if (isConnected && !_notificationCheckDone) {
            _notificationCheckDone = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkNotificationPermission(provider);
            });
          }

          return Stack(
            children: [
              // Animated background glow
              AnimatedPositioned(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                top: MediaQuery.of(context).size.height * 0.15,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    width: isConnected ? 300 : 200,
                    height: isConnected ? 300 : 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isConnected
                                  ? AppTheme.accentGreen
                                  : AppTheme.accentCyan)
                              .withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // App title + settings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 40),
                          Expanded(
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: const Text(
                                'FreeVPN',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              icon: const Icon(
                                Icons.settings_rounded,
                                color: AppTheme.textSecondary,
                                size: 22,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Connect button
                      const ConnectButton(),

                      const SizedBox(height: 16),

                      // Timer
                      const ConnectionTimer(),

                      const SizedBox(height: 8),

                      // Status
                      const Flexible(flex: 3, child: StatusDisplay()),

                      const Spacer(),

                      // Server selector
                      _ServerSelector(provider: provider),

                      const SizedBox(height: 16),

                      // Creator
                      Text(
                        'Created by Prasad Rawas',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _checkBatteryOptimization() async {
    final dismissed = await BatteryOptimizationService.wasDismissed();
    if (dismissed) return;

    final isIgnoring = await BatteryOptimizationService.isIgnoringBatteryOptimizations();
    if (isIgnoring) return;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.battery_alert_rounded, color: AppTheme.accentOrange, size: 24),
            SizedBox(width: 10),
            Text(
              'Battery Optimization',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'To keep the VPN connected in the background, please disable battery optimization for FreeVPN.\n\n'
          'Without this, your device may kill the VPN when the screen is off or you switch apps.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              BatteryOptimizationService.setDismissed();
              Navigator.of(ctx).pop();
            },
            child: const Text('Later', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              BatteryOptimizationService.requestIgnoreBatteryOptimizations();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentCyan),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkNotificationPermission(VpnProvider provider) async {
    final granted = await provider.isNotificationPermissionGranted();
    if (granted) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_off_rounded, color: AppTheme.accentOrange, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Notifications are off. Enable them to see VPN connection status.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'ENABLE',
          textColor: AppTheme.accentCyan,
          onPressed: () {
            provider.openNotificationSettings();
          },
        ),
      ),
    );
  }

  void _showOfflineWarning(BuildContext context, VpnProvider provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.accentOrange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Server appears offline. Try a different server.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'SWITCH',
          textColor: AppTheme.accentCyan,
          onPressed: () {
            provider.clearOfflineWarning();
            provider.disconnect();
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ServerListScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ServerSelector extends StatefulWidget {
  final VpnProvider provider;

  const _ServerSelector({required this.provider});

  @override
  State<_ServerSelector> createState() => _ServerSelectorState();
}

class _ServerSelectorState extends State<_ServerSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;
  bool _hasInteracted = false;
  Timer? _startTimer;
  Timer? _stopTimer;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    // Start shimmer after a short delay, repeat a few times
    _startTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_hasInteracted) {
        _shimmerController.repeat();
        _stopTimer = Timer(const Duration(seconds: 6), () {
          if (mounted) _shimmerController.stop();
        });
      }
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _stopTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  void _openServerList() {
    setState(() => _hasInteracted = true);
    _shimmerController.stop();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ServerListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final server = widget.provider.selectedServer;

    return GestureDetector(
      onTap: _openServerList,
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !_hasInteracted && _shimmerController.isAnimating
                    ? AppTheme.accentCyan.withValues(alpha: 0.4)
                    : AppTheme.dividerColor,
              ),
              gradient: !_hasInteracted && _shimmerController.isAnimating
                  ? LinearGradient(
                      begin: Alignment(_shimmerAnimation.value - 1, 0),
                      end: Alignment(_shimmerAnimation.value, 0),
                      colors: [
                        AppTheme.cardDark,
                        AppTheme.accentCyan.withValues(alpha: 0.06),
                        AppTheme.cardDark,
                      ],
                    )
                  : null,
            ),
            child: child,
          );
        },
        child: Row(
          children: [
            if (server != null) ...[
              Text(
                server.flagEmoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.countryLong,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${server.hostName} • ${server.speedMbps}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentCyan.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: AppTheme.accentCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.provider.isLoadingServers
                      ? 'Loading servers...'
                      : 'Select a server',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentCyan.withValues(alpha: 0.4),
                ),
                color: AppTheme.accentCyan.withValues(alpha: 0.08),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.accentCyan,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
