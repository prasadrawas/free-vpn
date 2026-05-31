import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/vpn_server.dart';
import 'logger.dart';

class VpnGateService {
  // Fallback endpoints to bypass ISP DNS blocking
  static const _endpoints = [
    'https://www.vpngate.net/api/iphone/',
    'https://130.158.75.42/api/iphone/',
    'https://130.158.75.40/api/iphone/',
    'https://130.158.75.39/api/iphone/',
  ];

  Dio _createDio({bool trustAllCerts = false}) {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Host': 'www.vpngate.net',
      },
    ));

    // When connecting via IP, we need to skip certificate hostname verification
    if (trustAllCerts) {
      (dio.httpClientAdapter as dynamic);
      dio.httpClientAdapter = _createVpnGateCertAdapter();
    }

    return dio;
  }

  HttpClientAdapter _createVpnGateCertAdapter() {
    return IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // When connecting via IP, the hostname won't match the cert.
        // Verify the cert is actually issued for vpngate.net.
        client.badCertificateCallback = (cert, host, port) {
          final subject = cert.subject.toLowerCase();
          return subject.contains('vpngate.net');
        };
        return client;
      },
    );
  }

  Future<String> _fetchFromEndpoints() async {
    final errors = <String>[];

    for (final endpoint in _endpoints) {
      final isIpEndpoint = !endpoint.contains('www.vpngate.net');
      final dio = _createDio(trustAllCerts: isIpEndpoint);

      // 2 retries per endpoint
      for (var attempt = 1; attempt <= 2; attempt++) {
        try {
          Log.d('VpnGate: trying $endpoint (attempt $attempt)');
          final response = await dio.get<String>(endpoint);
          final body = response.data;
          if (body != null && body.contains('*vpn_servers')) {
            Log.d('VpnGate: success from $endpoint');
            return body;
          }
        } on DioException catch (e) {
          errors.add('$endpoint attempt $attempt: ${e.message}');
          if (attempt < 2) {
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
      }
    }

    throw Exception('All VPN Gate endpoints failed: ${errors.join(', ')}');
  }

  Future<List<VpnServer>> fetchServers() async {
    final body = await _fetchFromEndpoints();

    final lines = body.split('\n');
    if (lines.length < 3) {
      throw Exception('Invalid API response');
    }

    // Remove first line (*vpn_servers) and last lines (* and empty)
    final csvLines = <String>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line == '*' || line.isEmpty) continue;
      csvLines.add(lines[i]);
    }

    final csvString = csvLines.join('\n');
    final converter = const CsvToListConverter(eol: '\n', shouldParseNumbers: false);
    final rows = converter.convert(csvString);

    if (rows.isEmpty) return [];

    // First row is the header, skip it
    final servers = <VpnServer>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 15) continue;

      final configBase64 = row[14].toString().trim();
      if (configBase64.isEmpty) continue;

      try {
        servers.add(VpnServer.fromCsvRow(row));
      } catch (_) {
        // Skip malformed rows
      }
    }

    // Filter out servers that are likely offline or unusable
    servers.removeWhere((s) {
      if (s.ping <= 0) return true;
      if (s.numVpnSessions <= 0) return true;
      if (s.speed < 500000) return true;
      if (s.score <= 0) return true;
      return false;
    });

    // Sort by score (reliability) descending, then speed, then ping
    servers.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      final speedCmp = b.speed.compareTo(a.speed);
      if (speedCmp != 0) return speedCmp;
      return a.ping.compareTo(b.ping);
    });

    return servers;
  }
}
