import 'dart:convert';

import 'package:openvpn_flutter/openvpn_flutter.dart';

import '../models/vpn_server.dart';
import 'logger.dart';

class VpnConnectionService {
  late OpenVPN _openVPN;

  final void Function(VpnStatus? status) onStatusChanged;
  final void Function(VPNStage? stage) onStageChanged;

  VpnConnectionService({
    required this.onStatusChanged,
    required this.onStageChanged,
  });

  void initialize() {
    Log.d('OpenVPN: initializing plugin');
    _openVPN = OpenVPN(
      onVpnStatusChanged: (data) {
        Log.d('OpenVPN Status: duration=${data?.duration}, byteIn=${data?.byteIn}, byteOut=${data?.byteOut}, packetsIn=${data?.packetsIn}, packetsOut=${data?.packetsOut}');
        onStatusChanged(data);
      },
      onVpnStageChanged: (data, raw) {
        Log.d('OpenVPN Stage: raw=$raw, parsed=$data');
        onStageChanged(data);
      },
    );
    _openVPN.initialize(
      groupIdentifier: 'group.com.prasadrawas.freevpn',
      providerBundleIdentifier: 'com.prasadrawas.freevpn.VPNExtension',
      localizedDescription: 'FreeVPN',
    );
    Log.d('OpenVPN: plugin initialized');
  }

  String _sanitizeConfig(String config) {
    final problematicDirectives = [
      'register-dns',
      'block-outside-dns',
      'setenv',
      'up ',
      'down ',
      'script-security',
      'dhcp-option',
      'pull-filter',
      'inactive',
      'auth-user-pass',
    ];

    final lines = config.split('\n');
    final sanitized = <String>[];

    for (final line in lines) {
      final trimmed = line.trim().toLowerCase();
      if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith(';')) {
        sanitized.add(line);
        continue;
      }

      // Remove problematic directives
      bool skip = false;
      for (final directive in problematicDirectives) {
        if (trimmed.startsWith(directive)) {
          skip = true;
          break;
        }
      }
      if (!skip) sanitized.add(line);
    }

    // Add cipher negotiation directives that enable the connection
    sanitized.add('data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC');
    sanitized.add('data-ciphers-fallback AES-128-CBC');

    return sanitized.join('\n');
  }

  Future<void> connect(VpnServer server) async {
    Log.d('OpenVPN Connect: ${server.hostName} (${server.ip}), ${server.countryLong}, configSize=${server.openVpnConfigBase64.length}');
    final configBytes = base64.decode(server.openVpnConfigBase64);
    final rawConfig = utf8.decode(configBytes);
    final config = _sanitizeConfig(rawConfig);
    Log.d('OpenVPN Config: sanitized, ${config.split('\n').length} lines');
    _openVPN.connect(
      config,
      server.hostName,
      certIsRequired: true,
    );
  }

  void disconnect() {
    Log.d('OpenVPN Disconnect: requested');
    _openVPN.disconnect();
  }
}
