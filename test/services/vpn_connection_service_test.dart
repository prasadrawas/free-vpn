import 'package:flutter_test/flutter_test.dart';

// Test the config sanitization logic from VpnConnectionService.
// We replicate _sanitizeConfig here since it's private, to test the logic.

String sanitizeConfig(String config) {
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
    // Security: prevent file writes and code execution
    'log ',
    'log-append',
    'plugin',
    'iproute',
    'route-up',
    'route-pre-down',
    'ipchange',
    'client-connect',
    'client-disconnect',
    'learn-address',
    'tls-verify',
  ];

  final lines = config.split('\n');
  final sanitized = <String>[];

  for (final line in lines) {
    final trimmed = line.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith(';')) {
      sanitized.add(line);
      continue;
    }

    bool skip = false;
    for (final directive in problematicDirectives) {
      if (trimmed.startsWith(directive)) {
        skip = true;
        break;
      }
    }
    if (!skip) sanitized.add(line);
  }

  sanitized.add('data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC');
  sanitized.add('data-ciphers-fallback AES-128-CBC');

  return sanitized.join('\n');
}

void main() {
  group('Config sanitization - basic directives', () {
    test('preserves basic directives', () {
      const config = 'dev tun\nproto tcp\nremote 1.2.3.4 443\ncipher AES-128-CBC';
      final result = sanitizeConfig(config);
      expect(result, contains('dev tun'));
      expect(result, contains('proto tcp'));
      expect(result, contains('remote 1.2.3.4 443'));
      expect(result, contains('cipher AES-128-CBC'));
    });

    test('preserves comments', () {
      const config = '# This is a comment\n; Another comment\ndev tun';
      final result = sanitizeConfig(config);
      expect(result, contains('# This is a comment'));
      expect(result, contains('; Another comment'));
    });

    test('preserves empty lines', () {
      const config = 'dev tun\n\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, contains('\n\n'));
    });

    test('is case insensitive for directive matching', () {
      const config = 'REGISTER-DNS\nBlock-Outside-DNS\nSETENV foo bar';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('REGISTER-DNS')));
      expect(result, isNot(contains('Block-Outside-DNS')));
      expect(result, isNot(contains('SETENV')));
    });

    test('handles empty config', () {
      final result = sanitizeConfig('');
      expect(result, contains('data-ciphers'));
    });

    test('handles config with only comments', () {
      const config = '# comment1\n# comment2\n; comment3';
      final result = sanitizeConfig(config);
      expect(result, contains('# comment1'));
      expect(result, contains('data-ciphers'));
    });
  });

  group('Config sanitization - original denylist', () {
    test('removes register-dns', () {
      final result = sanitizeConfig('dev tun\nregister-dns\nproto tcp');
      expect(result, isNot(contains('register-dns')));
      expect(result, contains('dev tun'));
    });

    test('removes block-outside-dns', () {
      final result = sanitizeConfig('dev tun\nblock-outside-dns');
      expect(result, isNot(contains('block-outside-dns')));
    });

    test('removes setenv', () {
      final result = sanitizeConfig('setenv UV_SOMETHING 1');
      expect(result, isNot(contains('setenv')));
    });

    test('removes up directive', () {
      final result = sanitizeConfig('up /etc/openvpn/update.sh');
      expect(result, isNot(contains('up /etc/openvpn')));
    });

    test('removes down directive', () {
      final result = sanitizeConfig('down /etc/openvpn/down.sh');
      expect(result, isNot(contains('down /etc/openvpn')));
    });

    test('removes script-security', () {
      final result = sanitizeConfig('script-security 2');
      expect(result, isNot(contains('script-security')));
    });

    test('removes dhcp-option', () {
      final result = sanitizeConfig('dhcp-option DNS 8.8.8.8');
      expect(result, isNot(contains('dhcp-option')));
    });

    test('removes pull-filter', () {
      final result = sanitizeConfig('pull-filter ignore "route"');
      expect(result, isNot(contains('pull-filter')));
    });

    test('removes inactive', () {
      final result = sanitizeConfig('inactive 3600');
      expect(result, isNot(contains('inactive')));
    });

    test('removes auth-user-pass', () {
      final result = sanitizeConfig('auth-user-pass');
      expect(result, isNot(contains('auth-user-pass')));
    });

    test('does not remove "update" (partial match for "up ")', () {
      final result = sanitizeConfig('update-resolv-conf');
      expect(result, contains('update-resolv-conf'));
    });

    test('does not remove "download" (partial match for "down ")', () {
      final result = sanitizeConfig('download-speed 100');
      expect(result, contains('download-speed'));
    });
  });

  group('Config sanitization - security denylist', () {
    test('removes log directive', () {
      final result = sanitizeConfig('dev tun\nlog /sdcard/vpn.log');
      expect(result, isNot(contains('log /sdcard')));
      expect(result, contains('dev tun'));
    });

    test('removes log-append', () {
      final result = sanitizeConfig('log-append /sdcard/vpn.log');
      expect(result, isNot(contains('log-append')));
    });

    test('removes plugin', () {
      final result = sanitizeConfig('plugin /usr/lib/openvpn/auth.so');
      expect(result, isNot(contains('plugin')));
    });

    test('removes iproute', () {
      final result = sanitizeConfig('iproute /sbin/ip');
      expect(result, isNot(contains('iproute')));
    });

    test('removes route-up', () {
      final result = sanitizeConfig('route-up /etc/openvpn/route.sh');
      expect(result, isNot(contains('route-up')));
    });

    test('removes route-pre-down', () {
      final result = sanitizeConfig('route-pre-down /etc/openvpn/predown.sh');
      expect(result, isNot(contains('route-pre-down')));
    });

    test('removes ipchange', () {
      final result = sanitizeConfig('ipchange /etc/openvpn/ipchange.sh');
      expect(result, isNot(contains('ipchange')));
    });

    test('removes client-connect', () {
      final result = sanitizeConfig('client-connect /etc/openvpn/connect.sh');
      expect(result, isNot(contains('client-connect')));
    });

    test('removes client-disconnect', () {
      final result = sanitizeConfig('client-disconnect /etc/openvpn/disconnect.sh');
      expect(result, isNot(contains('client-disconnect')));
    });

    test('removes learn-address', () {
      final result = sanitizeConfig('learn-address /etc/openvpn/learn.sh');
      expect(result, isNot(contains('learn-address')));
    });

    test('removes tls-verify', () {
      final result = sanitizeConfig('tls-verify /etc/openvpn/verify.sh');
      expect(result, isNot(contains('tls-verify')));
    });

    test('does not remove "logging" (partial match for "log ")', () {
      final result = sanitizeConfig('logging-enabled true');
      expect(result, contains('logging-enabled'));
    });

    test('removes all security directives at once', () {
      const config = 'dev tun\n'
          'log /tmp/a.log\n'
          'log-append /tmp/b.log\n'
          'plugin /lib/auth.so\n'
          'iproute /sbin/ip\n'
          'route-up /test.sh\n'
          'route-pre-down /test.sh\n'
          'ipchange /test.sh\n'
          'client-connect /test.sh\n'
          'client-disconnect /test.sh\n'
          'learn-address /test.sh\n'
          'tls-verify /test.sh\n'
          'proto tcp';
      final result = sanitizeConfig(config);
      expect(result, contains('dev tun'));
      expect(result, contains('proto tcp'));
      expect(result, isNot(contains('log /tmp')));
      expect(result, isNot(contains('log-append')));
      expect(result, isNot(contains('plugin')));
      expect(result, isNot(contains('iproute')));
      expect(result, isNot(contains('route-up')));
      expect(result, isNot(contains('route-pre-down')));
      expect(result, isNot(contains('ipchange')));
      expect(result, isNot(contains('client-connect')));
      expect(result, isNot(contains('client-disconnect')));
      expect(result, isNot(contains('learn-address')));
      expect(result, isNot(contains('tls-verify')));
    });
  });

  group('Config sanitization - cipher directives', () {
    test('appends data-ciphers directives', () {
      final result = sanitizeConfig('dev tun');
      expect(result, contains('data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC'));
      expect(result, contains('data-ciphers-fallback AES-128-CBC'));
    });

    test('data-ciphers are always at the end', () {
      final result = sanitizeConfig('dev tun\nproto tcp\ncipher AES-128-CBC');
      final lines = result.split('\n');
      expect(lines[lines.length - 1], 'data-ciphers-fallback AES-128-CBC');
      expect(lines[lines.length - 2], 'data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC');
    });
  });

  group('Config sanitization - VPN Gate config', () {
    test('handles full VPN Gate config with inline certs', () {
      const config = 'dev tun\n'
          'proto tcp\n'
          'remote 1.2.3.4 443\n'
          'cipher AES-128-CBC\n'
          'auth SHA1\n'
          'resolv-retry infinite\n'
          'nobind\n'
          'persist-key\n'
          'persist-tun\n'
          'client\n'
          'verb 3\n'
          '<ca>\n'
          '-----BEGIN CERTIFICATE-----\n'
          'MIID...\n'
          '-----END CERTIFICATE-----\n'
          '</ca>';
      final result = sanitizeConfig(config);
      expect(result, contains('remote 1.2.3.4 443'));
      expect(result, contains('cipher AES-128-CBC'));
      expect(result, contains('<ca>'));
      expect(result, contains('-----BEGIN CERTIFICATE-----'));
      expect(result, contains('</ca>'));
      expect(result, contains('resolv-retry infinite'));
      expect(result, contains('nobind'));
      expect(result, contains('persist-key'));
      expect(result, contains('client'));
    });

    test('removes all problematic directives from combined config', () {
      const config = 'dev tun\n'
          'register-dns\n'
          'block-outside-dns\n'
          'setenv UV_TEST 1\n'
          'script-security 2\n'
          'up /test.sh\n'
          'down /test.sh\n'
          'dhcp-option DNS 8.8.8.8\n'
          'pull-filter ignore "route"\n'
          'inactive 3600\n'
          'auth-user-pass\n'
          'log /tmp/vpn.log\n'
          'plugin /lib/auth.so\n'
          'tls-verify /test.sh\n'
          'proto tcp';
      final result = sanitizeConfig(config);
      expect(result, contains('dev tun'));
      expect(result, contains('proto tcp'));
      // Count remaining non-empty, non-comment lines (excluding data-ciphers)
      final remaining = result.split('\n').where((l) {
        final t = l.trim();
        return t.isNotEmpty && !t.startsWith('#') && !t.startsWith(';') && !t.startsWith('data-ciphers');
      }).toList();
      expect(remaining, ['dev tun', 'proto tcp']);
    });
  });
}
