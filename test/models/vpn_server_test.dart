import 'package:flutter_test/flutter_test.dart';
import 'package:free_vpns/models/vpn_server.dart';

VpnServer _makeServer({
  String hostName = 'test-vpn',
  String ip = '1.2.3.4',
  int score = 100,
  int ping = 10,
  int speed = 5000000,
  String countryLong = 'Japan',
  String countryShort = 'JP',
  int numVpnSessions = 5,
  int uptime = 1000,
  int totalUsers = 100,
  int totalTraffic = 999,
  String logType = '2weeks',
  String operator_ = 'test',
  String message = '',
  String openVpnConfigBase64 = 'dGVzdA==',
}) {
  return VpnServer(
    hostName: hostName,
    ip: ip,
    score: score,
    ping: ping,
    speed: speed,
    countryLong: countryLong,
    countryShort: countryShort,
    numVpnSessions: numVpnSessions,
    uptime: uptime,
    totalUsers: totalUsers,
    totalTraffic: totalTraffic,
    logType: logType,
    operator_: operator_,
    message: message,
    openVpnConfigBase64: openVpnConfigBase64,
  );
}

void main() {
  group('VpnServer', () {
    group('flagEmoji', () {
      test('returns correct flag for JP', () {
        final server = _makeServer(countryShort: 'JP');
        expect(server.flagEmoji, '\u{1F1EF}\u{1F1F5}');
      });

      test('returns correct flag for US', () {
        final server = _makeServer(countryShort: 'US');
        expect(server.flagEmoji, '\u{1F1FA}\u{1F1F8}');
      });

      test('returns empty string for invalid country code', () {
        final server = _makeServer(countryShort: 'J');
        expect(server.flagEmoji, '');
      });

      test('returns empty string for empty country code', () {
        final server = _makeServer(countryShort: '');
        expect(server.flagEmoji, '');
      });

      test('returns empty string for 3-letter code', () {
        final server = _makeServer(countryShort: 'JPN');
        expect(server.flagEmoji, '');
      });

      test('handles lowercase country code', () {
        final lower = _makeServer(countryShort: 'jp');
        final upper = _makeServer(countryShort: 'JP');
        expect(lower.flagEmoji, upper.flagEmoji);
      });

      test('handles mixed case country code', () {
        final mixed = _makeServer(countryShort: 'jP');
        final upper = _makeServer(countryShort: 'JP');
        expect(mixed.flagEmoji, upper.flagEmoji);
      });
    });

    group('speedMbps', () {
      test('formats speed >= 100 Mbps with no decimals', () {
        final server = _makeServer(speed: 150000000);
        expect(server.speedMbps, '150 Mbps');
      });

      test('formats speed >= 10 Mbps with 1 decimal', () {
        final server = _makeServer(speed: 25500000);
        expect(server.speedMbps, '25.5 Mbps');
      });

      test('formats speed < 10 Mbps with 2 decimals', () {
        final server = _makeServer(speed: 5250000);
        expect(server.speedMbps, '5.25 Mbps');
      });

      test('formats very low speed', () {
        final server = _makeServer(speed: 500000);
        expect(server.speedMbps, '0.50 Mbps');
      });

      test('formats zero speed', () {
        final server = _makeServer(speed: 0);
        expect(server.speedMbps, '0.00 Mbps');
      });
    });

    group('pingDisplay', () {
      test('shows ping value with ms suffix', () {
        final server = _makeServer(ping: 42);
        expect(server.pingDisplay, '42ms');
      });

      test('shows N/A for zero ping', () {
        final server = _makeServer(ping: 0);
        expect(server.pingDisplay, 'N/A');
      });

      test('shows N/A for negative ping', () {
        final server = _makeServer(ping: -1);
        expect(server.pingDisplay, 'N/A');
      });
    });

    group('sessionsDisplay', () {
      test('shows session count', () {
        final server = _makeServer(numVpnSessions: 42);
        expect(server.sessionsDisplay, '42 sessions');
      });

      test('shows zero sessions', () {
        final server = _makeServer(numVpnSessions: 0);
        expect(server.sessionsDisplay, '0 sessions');
      });
    });

    group('fromCsvRow', () {
      test('parses valid row', () {
        final row = [
          'host1', '1.2.3.4', '500', '10', '5000000',
          'Japan', 'JP', '5', '1000', '100',
          '999', '2weeks', 'operator', 'msg', 'dGVzdA==',
        ];
        final server = VpnServer.fromCsvRow(row);
        expect(server.hostName, 'host1');
        expect(server.ip, '1.2.3.4');
        expect(server.score, 500);
        expect(server.ping, 10);
        expect(server.speed, 5000000);
        expect(server.countryLong, 'Japan');
        expect(server.countryShort, 'JP');
        expect(server.numVpnSessions, 5);
        expect(server.uptime, 1000);
        expect(server.totalUsers, 100);
        expect(server.totalTraffic, 999);
        expect(server.logType, '2weeks');
        expect(server.operator_, 'operator');
        expect(server.message, 'msg');
        expect(server.openVpnConfigBase64, 'dGVzdA==');
      });

      test('handles short row with missing fields', () {
        final row = ['host1', '1.2.3.4', '500'];
        final server = VpnServer.fromCsvRow(row);
        expect(server.hostName, 'host1');
        expect(server.ip, '1.2.3.4');
        expect(server.score, 500);
        expect(server.ping, 0);
        expect(server.speed, 0);
        expect(server.countryLong, '');
        expect(server.openVpnConfigBase64, '');
      });

      test('handles non-numeric values gracefully', () {
        final row = [
          'host1', '1.2.3.4', 'abc', 'xyz', 'notanum',
          'Japan', 'JP', '5', '1000', '100',
          '999', '2weeks', 'operator', 'msg', 'dGVzdA==',
        ];
        final server = VpnServer.fromCsvRow(row);
        expect(server.score, 0);
        expect(server.ping, 0);
        expect(server.speed, 0);
      });

      test('trims whitespace from values', () {
        final row = [
          '  host1  ', ' 1.2.3.4 ', ' 500 ', ' 10 ', ' 5000000 ',
          ' Japan ', ' JP ', ' 5 ', ' 1000 ', ' 100 ',
          ' 999 ', ' 2weeks ', ' op ', ' msg ', ' dGVzdA== ',
        ];
        final server = VpnServer.fromCsvRow(row);
        expect(server.hostName, 'host1');
        expect(server.ip, '1.2.3.4');
        expect(server.score, 500);
        expect(server.openVpnConfigBase64, 'dGVzdA==');
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final server = _makeServer();
        final json = server.toJson();
        expect(json['hostName'], 'test-vpn');
        expect(json['ip'], '1.2.3.4');
        expect(json['score'], 100);
        expect(json['ping'], 10);
        expect(json['speed'], 5000000);
        expect(json['countryLong'], 'Japan');
        expect(json['countryShort'], 'JP');
        expect(json['numVpnSessions'], 5);
        expect(json['openVpnConfigBase64'], 'dGVzdA==');
      });

      test('fromJson restores server correctly', () {
        final original = _makeServer();
        final json = original.toJson();
        final restored = VpnServer.fromJson(json);
        expect(restored.hostName, original.hostName);
        expect(restored.ip, original.ip);
        expect(restored.score, original.score);
        expect(restored.ping, original.ping);
        expect(restored.speed, original.speed);
        expect(restored.countryLong, original.countryLong);
        expect(restored.countryShort, original.countryShort);
        expect(restored.numVpnSessions, original.numVpnSessions);
        expect(restored.uptime, original.uptime);
        expect(restored.totalUsers, original.totalUsers);
        expect(restored.totalTraffic, original.totalTraffic);
        expect(restored.logType, original.logType);
        expect(restored.operator_, original.operator_);
        expect(restored.message, original.message);
        expect(restored.openVpnConfigBase64, original.openVpnConfigBase64);
      });

      test('roundtrip toJson/fromJson preserves all fields', () {
        final server = _makeServer(
          hostName: 'vpn123',
          ip: '10.20.30.40',
          score: 999,
          ping: 5,
          speed: 100000000,
          countryLong: 'South Korea',
          countryShort: 'KR',
          numVpnSessions: 50,
          uptime: 86400,
          totalUsers: 1000,
          totalTraffic: 5000,
          logType: '2weeks',
          operator_: 'admin',
          message: 'hello',
          openVpnConfigBase64: 'Y29uZmln',
        );
        final restored = VpnServer.fromJson(server.toJson());
        expect(restored.hostName, server.hostName);
        expect(restored.ip, server.ip);
        expect(restored.score, server.score);
        expect(restored.countryShort, server.countryShort);
        expect(restored.openVpnConfigBase64, server.openVpnConfigBase64);
      });

      test('fromJson handles missing fields with defaults', () {
        final server = VpnServer.fromJson({});
        expect(server.hostName, '');
        expect(server.ip, '');
        expect(server.score, 0);
        expect(server.ping, 0);
        expect(server.speed, 0);
        expect(server.countryLong, '');
        expect(server.countryShort, '');
        expect(server.numVpnSessions, 0);
        expect(server.openVpnConfigBase64, '');
      });

      test('fromJson handles partial fields', () {
        final server = VpnServer.fromJson({
          'hostName': 'partial',
          'ip': '5.6.7.8',
        });
        expect(server.hostName, 'partial');
        expect(server.ip, '5.6.7.8');
        expect(server.score, 0);
        expect(server.countryLong, '');
      });
    });
  });
}
