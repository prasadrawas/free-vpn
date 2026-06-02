import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:free_vpns/models/vpn_server.dart';
import 'package:free_vpns/providers/vpn_provider.dart';

VpnServer _makeServer({
  String hostName = 'test-vpn',
  String ip = '1.2.3.4',
  int score = 100,
  int ping = 10,
  int speed = 5000000,
  String countryLong = 'Japan',
  String countryShort = 'JP',
  int numVpnSessions = 5,
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
    uptime: 1000,
    totalUsers: 100,
    totalTraffic: 999,
    logType: '2weeks',
    operator_: 'test',
    message: '',
    openVpnConfigBase64: openVpnConfigBase64,
  );
}

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('VpnProvider initial state', () {
    test('starts with disconnected status', () {
      final provider = VpnProvider();
      expect(provider.connectionStatus, ConnectionStatus.disconnected);
    });

    test('starts with no selected server', () {
      final provider = VpnProvider();
      expect(provider.selectedServer, isNull);
    });

    test('starts with empty server list', () {
      final provider = VpnProvider();
      expect(provider.servers, isEmpty);
    });

    test('starts with no error message', () {
      final provider = VpnProvider();
      expect(provider.errorMessage, isNull);
    });

    test('starts with no stage name', () {
      final provider = VpnProvider();
      expect(provider.stageName, isNull);
    });

    test('starts with zero connection duration', () {
      final provider = VpnProvider();
      expect(provider.connectionDuration, Duration.zero);
    });

    test('starts with zero connection duration notifier', () {
      final provider = VpnProvider();
      expect(provider.connectionDurationNotifier.value, Duration.zero);
    });

    test('starts with isLoadingServers false', () {
      final provider = VpnProvider();
      expect(provider.isLoadingServers, false);
    });

    test('starts with serverWentOffline false', () {
      final provider = VpnProvider();
      expect(provider.serverWentOffline, false);
    });

    test('starts with isAutoConnecting false', () {
      final provider = VpnProvider();
      expect(provider.isAutoConnecting, false);
    });

    test('starts with empty favorites', () {
      final provider = VpnProvider();
      expect(provider.favoriteIps, isEmpty);
      expect(provider.favoriteServers, isEmpty);
    });

    test('starts with null vpnStatus', () {
      final provider = VpnProvider();
      expect(provider.vpnStatus, isNull);
    });
  });

  group('VpnProvider.clearOfflineWarning', () {
    test('clears serverWentOffline flag', () {
      final provider = VpnProvider();
      provider.clearOfflineWarning();
      expect(provider.serverWentOffline, false);
    });

    test('notifies listeners', () {
      final provider = VpnProvider();
      int count = 0;
      provider.addListener(() => count++);
      provider.clearOfflineWarning();
      expect(count, 1);
    });
  });

  group('VpnProvider.isOnline', () {
    test('returns false for unknown server', () {
      final provider = VpnProvider();
      final server = _makeServer();
      expect(provider.isOnline(server), false);
    });
  });

  group('VpnProvider.isFavorite', () {
    test('returns false for non-favorite server', () {
      final provider = VpnProvider();
      final server = _makeServer();
      expect(provider.isFavorite(server), false);
    });
  });

  group('VpnProvider.toggleFavorite', () {
    test('adds server to favorites', () {
      final provider = VpnProvider();
      final server = _makeServer(ip: '10.0.0.1');
      provider.toggleFavorite(server);
      expect(provider.isFavorite(server), true);
      expect(provider.favoriteIps.contains('10.0.0.1'), true);
    });

    test('removes server from favorites on second toggle', () {
      final provider = VpnProvider();
      final server = _makeServer(ip: '10.0.0.1');
      provider.toggleFavorite(server);
      expect(provider.isFavorite(server), true);
      provider.toggleFavorite(server);
      expect(provider.isFavorite(server), false);
    });

    test('handles multiple favorites', () {
      final provider = VpnProvider();
      final s1 = _makeServer(ip: '1.1.1.1');
      final s2 = _makeServer(ip: '2.2.2.2');
      final s3 = _makeServer(ip: '3.3.3.3');
      provider.toggleFavorite(s1);
      provider.toggleFavorite(s2);
      provider.toggleFavorite(s3);
      expect(provider.isFavorite(s1), true);
      expect(provider.isFavorite(s2), true);
      expect(provider.isFavorite(s3), true);
    });

    test('removing one favorite does not affect others', () {
      final provider = VpnProvider();
      final s1 = _makeServer(ip: '1.1.1.1');
      final s2 = _makeServer(ip: '2.2.2.2');
      provider.toggleFavorite(s1);
      provider.toggleFavorite(s2);
      provider.toggleFavorite(s1);
      expect(provider.isFavorite(s1), false);
      expect(provider.isFavorite(s2), true);
    });

    test('notifies listeners on toggle', () {
      final provider = VpnProvider();
      final server = _makeServer();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.toggleFavorite(server);
      expect(notifyCount, 1);
      provider.toggleFavorite(server);
      expect(notifyCount, 2);
    });

    test('toggling same server twice leaves favorites empty', () {
      final provider = VpnProvider();
      final server = _makeServer(ip: '5.5.5.5');
      provider.toggleFavorite(server);
      provider.toggleFavorite(server);
      expect(provider.favoriteIps, isEmpty);
    });
  });

  group('VpnProvider.connectToServer', () {
    test('does nothing when target is null and no selected server', () async {
      final provider = VpnProvider();
      await provider.connectToServer(null);
      expect(provider.connectionStatus, ConnectionStatus.disconnected);
      expect(provider.stageName, isNull);
    });

    test('does nothing when service is not initialized', () async {
      final provider = VpnProvider();
      final server = _makeServer();
      // Service is null, should return early without crashing
      await provider.connectToServer(server);
      expect(provider.connectionStatus, ConnectionStatus.disconnected);
    });
  });

  group('VpnProvider.disconnect', () {
    test('sets status to disconnecting and clears error', () {
      final provider = VpnProvider();
      int notifyCount = 0;
      provider.addListener(() {
        if (notifyCount == 0) {
          expect(provider.connectionStatus, ConnectionStatus.disconnecting);
          expect(provider.stageName, 'Disconnecting...');
          expect(provider.errorMessage, isNull);
        }
        notifyCount++;
      });
      // disconnect with null service - sets state but disconnect call is safe (null-aware)
      provider.disconnect();
      expect(notifyCount, greaterThan(0));
    });

    test('clears isAutoConnecting', () {
      final provider = VpnProvider();
      provider.disconnect();
      expect(provider.isAutoConnecting, false);
    });
  });

  group('VpnProvider.switchServer', () {
    test('calls connectToServer when not connected', () async {
      final provider = VpnProvider();
      final server = _makeServer(hostName: 'new-server');
      // Service is null, so connectToServer returns early without setting server
      provider.switchServer(server);
      await Future.delayed(Duration.zero);
      // With null service, connectToServer bails early
      expect(provider.connectionStatus, ConnectionStatus.disconnected);
    });

    test('does not crash with null service', () {
      final provider = VpnProvider();
      final server = _makeServer(hostName: 'test');
      expect(() => provider.switchServer(server), returnsNormally);
    });
  });

  group('VpnProvider.connectionDurationNotifier', () {
    test('starts at zero', () {
      final provider = VpnProvider();
      expect(provider.connectionDurationNotifier.value, Duration.zero);
    });

    test('is a ValueNotifier', () {
      final provider = VpnProvider();
      expect(provider.connectionDurationNotifier, isA<ValueNotifier<Duration>>());
    });

    test('connectionDuration getter matches notifier value', () {
      final provider = VpnProvider();
      expect(provider.connectionDuration, provider.connectionDurationNotifier.value);
    });
  });

  group('VpnProvider.autoConnect', () {
    test('does nothing when service is not initialized', () async {
      final provider = VpnProvider();
      await provider.autoConnect();
      // Should return early, no crash
      expect(provider.connectionStatus, ConnectionStatus.disconnected);
    });
  });

  group('VpnProvider speed tracking', () {
    test('starts with zero download speed', () {
      final provider = VpnProvider();
      expect(provider.downloadSpeed, 0);
    });

    test('starts with zero upload speed', () {
      final provider = VpnProvider();
      expect(provider.uploadSpeed, 0);
    });
  });

  group('VpnProvider.connectionQuality', () {
    test('starts as unknown', () {
      final provider = VpnProvider();
      expect(provider.connectionQuality, ConnectionQuality.unknown);
    });
  });

  group('VpnProvider.recentServers', () {
    test('starts empty', () {
      final provider = VpnProvider();
      expect(provider.recentServers, isEmpty);
    });
  });

  group('ConnectionQuality enum', () {
    test('has all expected values', () {
      expect(ConnectionQuality.values, containsAll([
        ConnectionQuality.good,
        ConnectionQuality.fair,
        ConnectionQuality.poor,
        ConnectionQuality.unknown,
      ]));
    });

    test('has exactly 4 values', () {
      expect(ConnectionQuality.values.length, 4);
    });
  });

  group('ConnectionStatus enum', () {
    test('has all expected values', () {
      expect(ConnectionStatus.values, containsAll([
        ConnectionStatus.disconnected,
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
        ConnectionStatus.disconnecting,
        ConnectionStatus.error,
      ]));
    });

    test('has exactly 5 values', () {
      expect(ConnectionStatus.values.length, 5);
    });
  });

  group('VpnProvider.dispose', () {
    test('disposes without error', () {
      final provider = VpnProvider();
      expect(() => provider.dispose(), returnsNormally);
    });

    test('disposes connectionDurationNotifier', () {
      final provider = VpnProvider();
      provider.dispose();
      // Accessing disposed notifier should throw
      expect(() => provider.connectionDurationNotifier.addListener(() {}), throwsA(anything));
    });
  });
}
