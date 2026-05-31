import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';

class ConnectionTimer extends StatelessWidget {
  const ConnectionTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnProvider>(
      builder: (context, provider, _) {
        final isConnected =
            provider.connectionStatus == ConnectionStatus.connected;
        final duration = provider.connectionDuration;

        final hours = duration.inHours.toString().padLeft(2, '0');
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return AnimatedOpacity(
          opacity: isConnected ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: AnimatedSlide(
            offset: isConnected ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: Text(
              '$hours:$minutes:$seconds',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: AppTheme.accentGreen,
                letterSpacing: 4,
              ),
            ),
          ),
        );
      },
    );
  }
}
