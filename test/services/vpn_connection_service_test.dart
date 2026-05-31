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
  group('Config sanitization', () {
    test('preserves basic directives', () {
      const config = 'dev tun\nproto tcp\nremote 1.2.3.4 443\ncipher AES-128-CBC';
      final result = sanitizeConfig(config);
      expect(result, contains('dev tun'));
      expect(result, contains('proto tcp'));
      expect(result, contains('remote 1.2.3.4 443'));
      expect(result, contains('cipher AES-128-CBC'));
    });

    test('removes register-dns', () {
      const config = 'dev tun\nregister-dns\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('register-dns')));
      expect(result, contains('dev tun'));
      expect(result, contains('proto tcp'));
    });

    test('removes block-outside-dns', () {
      const config = 'dev tun\nblock-outside-dns\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('block-outside-dns')));
    });

    test('removes setenv', () {
      const config = 'dev tun\nsetenv UV_SOMETHING 1\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('setenv')));
    });

    test('removes up directive', () {
      const config = 'dev tun\nup /etc/openvpn/update.sh\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('up /etc/openvpn')));
    });

    test('removes down directive', () {
      const config = 'dev tun\ndown /etc/openvpn/down.sh\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('down /etc/openvpn')));
    });

    test('removes script-security', () {
      const config = 'dev tun\nscript-security 2\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('script-security')));
    });

    test('removes dhcp-option', () {
      const config = 'dev tun\ndhcp-option DNS 8.8.8.8\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('dhcp-option')));
    });

    test('removes pull-filter', () {
      const config = 'dev tun\npull-filter ignore "route"\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('pull-filter')));
    });

    test('removes inactive', () {
      const config = 'dev tun\ninactive 3600\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('inactive')));
    });

    test('removes auth-user-pass', () {
      const config = 'dev tun\nauth-user-pass\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, isNot(contains('auth-user-pass')));
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

    test('appends data-ciphers directives', () {
      const config = 'dev tun\nproto tcp';
      final result = sanitizeConfig(config);
      expect(result, contains('data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC'));
      expect(result, contains('data-ciphers-fallback AES-128-CBC'));
    });

    test('data-ciphers are always at the end', () {
      const config = 'dev tun\nproto tcp\ncipher AES-128-CBC';
      final result = sanitizeConfig(config);
      final lines = result.split('\n');
      expect(lines[lines.length - 1], 'data-ciphers-fallback AES-128-CBC');
      expect(lines[lines.length - 2], 'data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC');
    });

    test('removes multiple problematic directives at once', () {
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
          'proto tcp';
      final result = sanitizeConfig(config);
      expect(result, contains('dev tun'));
      expect(result, contains('proto tcp'));
      expect(result, isNot(contains('register-dns')));
      expect(result, isNot(contains('block-outside-dns')));
      expect(result, isNot(contains('setenv')));
      expect(result, isNot(contains('script-security')));
      expect(result, isNot(contains('up /test')));
      expect(result, isNot(contains('down /test')));
      expect(result, isNot(contains('dhcp-option')));
      expect(result, isNot(contains('pull-filter')));
      expect(result, isNot(contains('inactive')));
      expect(result, isNot(contains('auth-user-pass')));
    });

    test('does not remove "update" or "download" (partial match for up/down)', () {
      const config = 'dev tun\nupdate-resolv-conf\ndownload-speed 100';
      final result = sanitizeConfig(config);
      // "up " has a trailing space, so "update" should NOT be removed
      expect(result, contains('update-resolv-conf'));
      // "down " has a trailing space, so "download" should NOT be removed
      expect(result, contains('download-speed'));
    });

    test('handles VPN Gate style config with inline certs', () {
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
    });

    test('handles empty config', () {
      final result = sanitizeConfig('');
      expect(result, contains('data-ciphers'));
    });

    test('handles config with only comments', () {
      const config = '# comment1\n# comment2\n; comment3';
      final result = sanitizeConfig(config);
      expect(result, contains('# comment1'));
      expect(result, contains('# comment2'));
      expect(result, contains('; comment3'));
      expect(result, contains('data-ciphers'));
    });
  });
}
