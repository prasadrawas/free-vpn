import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';

class StatusDisplay extends StatelessWidget {
  const StatusDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, provider, _) {
        final server = provider.selectedServer;
        final isConnected =
            provider.connectionStatus == ConnectionStatus.connected;
        final isConnecting =
            provider.connectionStatus == ConnectionStatus.connecting;

        return Column(
          children: [
            // Stage text
            if (provider.stageName != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  provider.stageName!,
                  key: ValueKey(provider.stageName),
                  style: TextStyle(
                    fontSize: 14,
                    color: isConnected
                        ? AppTheme.accentGreen
                        : isConnecting
                            ? AppTheme.accentCyan
                            : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Error message (hide when connected)
            if (provider.errorMessage != null && !isConnected) ...[
              const SizedBox(height: 4),
              Text(
                provider.errorMessage!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.accentRed,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Server info with quality indicator
            if (server != null && isConnected) ...[
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: isConnected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        server.flagEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            server.countryLong,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            server.ip,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Connection quality indicator
                      _QualityBadge(quality: provider.connectionQuality),
                    ],
                  ),
                ),
              ),
            ],

            // Speed + total stats
            if (isConnected && provider.vpnStatus != null) ...[
              const SizedBox(height: 12),
              // Real-time speed
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(
                    icon: Icons.arrow_downward_rounded,
                    label: _formatSpeed(provider.downloadSpeed),
                    color: AppTheme.accentGreen,
                  ),
                  const SizedBox(width: 16),
                  _StatChip(
                    icon: Icons.arrow_upward_rounded,
                    label: _formatSpeed(provider.uploadSpeed),
                    color: AppTheme.accentCyan,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Total transferred
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_formatBytes(provider.vpnStatus!.byteIn ?? '0')} / ${_formatBytes(provider.vpnStatus!.byteOut ?? '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatBytes(String bytesStr) {
    final bytes = int.tryParse(bytesStr) ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _QualityBadge extends StatelessWidget {
  final ConnectionQuality quality;

  const _QualityBadge({required this.quality});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (quality) {
      ConnectionQuality.good => (AppTheme.accentGreen, 'Good'),
      ConnectionQuality.fair => (AppTheme.accentOrange, 'Fair'),
      ConnectionQuality.poor => (AppTheme.accentRed, 'Poor'),
      ConnectionQuality.unknown => (AppTheme.textSecondary, '...'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
