import 'package:flutter_test/flutter_test.dart';
import 'package:free_vpns/models/vpn_server.dart';

// Test the CSV parsing and filtering logic without hitting the network.
// We replicate the parsing/filtering from VpnGateService.fetchServers().

List<VpnServer> _parseAndFilter(String body) {
  final lines = body.split('\n');
  if (lines.length < 3) throw Exception('Invalid API response');

  final csvLines = <String>[];
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line == '*' || line.isEmpty) continue;
    csvLines.add(lines[i]);
  }

  // Simple CSV split (no quoting needed for test data)
  final rows = csvLines.map((l) => l.split(',')).toList();

  if (rows.isEmpty) return [];

  final servers = <VpnServer>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 15) continue;
    final configBase64 = row[14].trim();
    if (configBase64.isEmpty) continue;
    try {
      servers.add(VpnServer.fromCsvRow(row));
    } catch (_) {}
  }

  servers.removeWhere((s) {
    if (s.ping <= 0) return true;
    if (s.numVpnSessions <= 0) return true;
    if (s.speed < 500000) return true;
    if (s.score <= 0) return true;
    return false;
  });

  servers.sort((a, b) {
    final scoreCmp = b.score.compareTo(a.score);
    if (scoreCmp != 0) return scoreCmp;
    final speedCmp = b.speed.compareTo(a.speed);
    if (speedCmp != 0) return speedCmp;
    return a.ping.compareTo(b.ping);
  });

  return servers;
}

const _header = 'HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,Uptime,TotalUsers,TotalTraffic,LogType,Operator,Message,OpenVPN_ConfigData_Base64';

String _row({
  String host = 'vpn1',
  String ip = '1.2.3.4',
  int score = 500,
  int ping = 10,
  int speed = 5000000,
  String country = 'Japan',
  String cc = 'JP',
  int sessions = 5,
  int uptime = 1000,
  int users = 100,
  int traffic = 999,
  String logType = '2weeks',
  String op = 'test',
  String msg = '',
  String config = 'dGVzdA==',
}) {
  return '$host,$ip,$score,$ping,$speed,$country,$cc,$sessions,$uptime,$users,$traffic,$logType,$op,$msg,$config';
}

void main() {
  group('VpnGateService parsing logic', () {
    test('parses valid API response', () {
      final body = '*vpn_servers\n$_header\n${_row()}\n*\n';
      final servers = _parseAndFilter(body);
      expect(servers.length, 1);
      expect(servers[0].hostName, 'vpn1');
      expect(servers[0].ip, '1.2.3.4');
    });

    test('parses multiple servers', () {
      final body = '*vpn_servers\n$_header\n'
          '${_row(host: 'vpn1', ip: '1.1.1.1', score: 100)}\n'
          '${_row(host: 'vpn2', ip: '2.2.2.2', score: 200)}\n'
          '${_row(host: 'vpn3', ip: '3.3.3.3', score: 300)}\n'
          '*\n';
      final servers = _parseAndFilter(body);
      expect(servers.length, 3);
    });

    test('returns empty list for empty CSV', () {
      final body = '*vpn_servers\n$_header\n*\n';
      final servers = _parseAndFilter(body);
      expect(servers, isEmpty);
    });

    test('throws on too-short response', () {
      expect(() => _parseAndFilter('*vpn_servers\n'), throwsException);
      expect(() => _parseAndFilter(''), throwsException);
    });

    test('skips rows with fewer than 15 columns', () {
      final body = '*vpn_servers\n$_header\nvpn1,1.2.3.4,500\n${_row(host: 'vpn2')}\n*\n';
      final servers = _parseAndFilter(body);
      expect(servers.length, 1);
      expect(servers[0].hostName, 'vpn2');
    });

    test('skips rows with empty config', () {
      final body = '*vpn_servers\n$_header\n${_row(config: '')}\n${_row(host: 'good')}\n*\n';
      final servers = _parseAndFilter(body);
      expect(servers.length, 1);
      expect(servers[0].hostName, 'good');
    });
  });

  group('Server filtering', () {
    test('filters out servers with ping <= 0', () {
      final body = '*vpn_servers\n$_header\n'
          '${_row(host: 'noping', ping: 0)}\n'
          '${_row(host: 'negping', ping: -1)}\n'
          '${_row(host: 'good', ping: 10)}\n'
          '*\n';
      final servers = _parseAndFilter(body);
      expect(servers.length, 1);
      expect(servers[0].hostName, 'good');
    });

    test('filters out servers with zero sessions', () {
      final body = '*vpn_servers\n$_header\n'
          '${_row(host: 'nosess', sessions: 0)}\n'
          '${_row(host: 'good', sessions: 1)}\n'
          '*\n';
      final servers = _parseAndFilter(body);
      expect(servers.length, 1);
      expect(servers[0].hostName, 'good');
    });

    test('filters out servers with speed < 500000', () {
      final body = '*vpn_servers\n$_header\n'
          '${_row(host: 'slow', speed: 499999)}\n'
          '${_row(host: 'borderline', speed: 500000)}\n'
          '${_row(host: 'fast', speed: 500001)}\n'
          '*\n';
      final servers = _parseAndFilter(body);
      expect(servers.length, 2);
      expect(servers.any((s) => s.hostName == 'slow'), false);
    });

    test('filters out servers with score <= 0', () {
      final body = '*vpn_servers\n$_header\n'
          '${_row(host: 'noscore', score: 0)}\n'
          '${_row(host: 'negscore', score: -5)}\n'
          '${_row(host: 'good', score: 1)}\n'
          '*\n';
      final servers = _parseAndFilter(body);
      expect(servers.length, 1);
      expect(servers[0].hostName, 'good');
    });

    test('filters out servers failing multiple criteria', () {
      final body = '*vpn_servers\n$_header\n'
          '${_row(host: 'bad', ping: 0, sessions: 0, speed: 100, score: 0)}\n'
          '${_row(host: 'good')}\n'
          '*\n';
      final servers = _parseAndFilter(body);
      expect(servers.length, 1);
      expect(servers[0].hostName, 'good');
    });
  });

  group('Server sorting', () {
    test('sorts by score descending', () {
      final body = '*vpn_servers\n$_header\n'
          '${_row(host: 'low', score: 100)}\n'
          '${_row(host: 'high', score: 500)}\n'
          '${_row(host: 'mid', score: 300)}\n'
          '*\n';
      final servers = _parseAndFilter(body);
      expect(servers[0].hostName, 'high');
      expect(servers[1].hostName, 'mid');
      expect(servers[2].hostName, 'low');
    });

    test('sorts by speed when scores are equal', () {
      final body = '*vpn_servers\n$_header\n'
          '${_row(host: 'slow', score: 100, speed: 1000000)}\n'
          '${_row(host: 'fast', score: 100, speed: 9000000)}\n'
          '*\n';
      final servers = _parseAndFilter(body);
      expect(servers[0].hostName, 'fast');
      expect(servers[1].hostName, 'slow');
    });

    test('sorts by ping when score and speed are equal', () {
      final body = '*vpn_servers\n$_header\n'
          '${_row(host: 'highping', score: 100, speed: 5000000, ping: 100)}\n'
          '${_row(host: 'lowping', score: 100, speed: 5000000, ping: 5)}\n'
          '*\n';
      final servers = _parseAndFilter(body);
      expect(servers[0].hostName, 'lowping');
      expect(servers[1].hostName, 'highping');
    });
  });
}
