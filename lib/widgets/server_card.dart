import 'package:flutter/material.dart';

import '../models/vpn_server.dart';
import '../theme/app_theme.dart';

class ServerCard extends StatelessWidget {
  final VpnServer server;
  final bool isSelected;
  final bool isFavorite;
  final bool isOnline;
  final double maxSpeed;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const ServerCard({
    super.key,
    required this.server,
    required this.isSelected,
    required this.isFavorite,
    this.isOnline = true,
    required this.maxSpeed,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.accentCyan.withValues(alpha: 0.08)
            : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppTheme.accentCyan.withValues(alpha: 0.4)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppTheme.accentCyan.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Flag with online indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      server.flagEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? AppTheme.accentGreen : AppTheme.textSecondary,
                          border: Border.all(color: AppTheme.cardDark, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Server info
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        server.hostName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Speed bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: maxSpeed > 0
                                    ? (server.speed / maxSpeed).clamp(0.0, 1.0)
                                    : 0,
                                minHeight: 4,
                                backgroundColor:
                                    AppTheme.primaryDark.withValues(alpha: 0.5),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _speedColor(server.speed / maxSpeed),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            server.speedMbps,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Ping + favorite
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Ping
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _pingColor(server.ping),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          server.pingDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      server.sessionsDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onFavoriteTap,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          key: ValueKey(isFavorite),
                          size: 22,
                          color: isFavorite
                              ? AppTheme.accentOrange
                              : AppTheme.textSecondary,
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

  Color _pingColor(int ping) {
    if (ping <= 0) return AppTheme.textSecondary;
    if (ping < 50) return AppTheme.accentGreen;
    if (ping < 100) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  Color _speedColor(double ratio) {
    if (ratio > 0.7) return AppTheme.accentGreen;
    if (ratio > 0.3) return AppTheme.accentCyan;
    return AppTheme.accentOrange;
  }
}
