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

                      const Spacer(flex: 2),

                      // Connect button
                      const ConnectButton(),

                      const SizedBox(height: 16),

                      // Timer
                      const ConnectionTimer(),

                      const SizedBox(height: 8),

                      // Status
                      const Flexible(child: StatusDisplay()),

                      const Spacer(flex: 3),

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

class _ServerSelector extends StatelessWidget {
  final VpnProvider provider;

  const _ServerSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    final server = provider.selectedServer;

    return GestureDetector(
      onTap: () {
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.dividerColor,
          ),
        ),
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
                  provider.isLoadingServers
                      ? 'Loading servers...'
                      : 'Select a server',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
