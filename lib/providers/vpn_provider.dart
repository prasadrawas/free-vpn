import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

import '../services/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vpn_server.dart';
import '../services/data_usage_service.dart';
import '../services/vpn_connection_service.dart';
import '../services/vpngate_service.dart';

enum ConnectionStatus { disconnected, connecting, connected, disconnecting, error }
enum ConnectionQuality { good, fair, poor, unknown }

class VpnProvider extends ChangeNotifier {
  final VpnGateService _vpnGateService = VpnGateService();
  VpnConnectionService? _vpnConnectionService;

  List<VpnServer> _servers = [];
  VpnServer? _selectedServer;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  VpnStatus? _vpnStatus;
  String? _stageName;
  String? _errorMessage;
  bool _isLoadingServers = false;
  Set<String> _favoriteIps = {};

  Timer? _connectionTimer;
  Timer? _refreshTimer;
  bool _disposed = false;
  final connectionDurationNotifier = ValueNotifier<Duration>(Duration.zero);
  DateTime? _connectedAt;
  int _reconnectCount = 0;
  bool _serverWentOffline = false;
  bool _isAutoConnecting = false;
  Set<String> _onlineServerIps = {};
  Completer<bool>? _connectionCompleter;
  VpnServer? _pendingSwitchServer;
  Timer? _switchDelayTimer;

  // Speed tracking
  int _sessionByteIn = 0;
  int _sessionByteOut = 0;
  int _prevByteIn = 0;
  int _prevByteOut = 0;
  DateTime? _prevSampleTime;
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;

  // Recent servers
  List<VpnServer> _recentServers = [];

  // Connection quality
  ConnectionQuality _connectionQuality = ConnectionQuality.unknown;

  // Getters
  List<VpnServer> get servers => _servers;
  VpnServer? get selectedServer => _selectedServer;
  ConnectionStatus get connectionStatus => _connectionStatus;
  VpnStatus? get vpnStatus => _vpnStatus;
  String? get stageName => _stageName;
  String? get errorMessage => _errorMessage;
  bool get isLoadingServers => _isLoadingServers;
  Duration get connectionDuration => connectionDurationNotifier.value;
  Set<String> get favoriteIps => _favoriteIps;
  double get downloadSpeed => _downloadSpeed;
  double get uploadSpeed => _uploadSpeed;
  List<VpnServer> get recentServers => _recentServers;
  ConnectionQuality get connectionQuality => _connectionQuality;

  bool get serverWentOffline => _serverWentOffline;
  bool get isAutoConnecting => _isAutoConnecting;
  bool isOnline(VpnServer server) => _onlineServerIps.contains(server.ip);

  void clearOfflineWarning() {
    _serverWentOffline = false;
    notifyListeners();
  }

  bool isFavorite(VpnServer server) => _favoriteIps.contains(server.ip);

  List<VpnServer> get favoriteServers =>
      _servers.where((s) => _favoriteIps.contains(s.ip)).toList();

  Future<void> initialize() async {
    Log.d('Provider: initializing');
    final service = VpnConnectionService(
      onStatusChanged: _onStatusChanged,
      onStageChanged: _onStageChanged,
    );
    service.initialize();
    _vpnConnectionService = service;

    await _loadFavorites();
    await _loadRecentServers();
    await _restoreConnectionState();
    _requestNotificationPermission();
    // Load servers in background — don't block init or show errors during active sessions
    loadServers();
    _startBackgroundRefresh();
    Log.d('Provider: initialized, status=$_connectionStatus, server=${_selectedServer?.hostName}');
  }

  Future<void> loadServers() async {
    Log.d('Servers: fetching');
    _isLoadingServers = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _servers = await _vpnGateService.fetchServers();
      _onlineServerIps = _servers.map((s) => s.ip).toSet();
      Log.d('Servers: loaded ${_servers.length} servers');
    } catch (e) {
      Log.error('Servers: fetch failed', e);
      // Only show error if fully disconnected and idle
      if (_connectionStatus == ConnectionStatus.disconnected &&
          _servers.isEmpty) {
        _errorMessage = 'Failed to load servers. Tap to retry.';
      }
    } finally {
      _isLoadingServers = false;
      notifyListeners();
    }
  }

  void selectServer(VpnServer server) {
    Log.d('Server selected: ${server.hostName} (${server.ip}), ${server.countryLong}');
    _selectedServer = server;
    _saveSelectedServer();
    notifyListeners();
  }

  Future<void> _saveSelectedServer() async {
    if (_selectedServer == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_server', jsonEncode(_selectedServer!.toJson()));
  }

  static const _connectTimeout = Duration(seconds: 30);
  static const _maxConnectRetries = 2;

  static const _channel = MethodChannel('com.prasadrawas.freevpn/battery');

  Future<void> _requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } on PlatformException {
      // Ignore — pre-Android 13 doesn't need this
    }
  }

  Future<void> connectToServer([VpnServer? server]) async {
    final target = server ?? _selectedServer;
    if (target == null) {
      Log.d('Connect: no target server, aborting');
      return;
    }

    if (_vpnConnectionService == null) {
      Log.d('Connect: service not initialized yet');
      return;
    }

    await _requestNotificationPermission();
    _selectedServer = target;
    _errorMessage = null;
    _serverWentOffline = false;

    for (var attempt = 1; attempt <= _maxConnectRetries; attempt++) {
      Log.d('Connect: attempt $attempt/$_maxConnectRetries to ${target.hostName} (${target.ip}), ${target.countryLong}');
      _connectionStatus = ConnectionStatus.connecting;
      _stageName = attempt > 1
          ? 'Retrying (${attempt}/$_maxConnectRetries)...'
          : 'Preparing...';
      _reconnectCount = 0;
      notifyListeners();

      _connectionCompleter = Completer<bool>();

      try {
        await _vpnConnectionService!.connect(target);
      } catch (e) {
        Log.error('Connect: failed to ${target.hostName}', e);
        _connectionCompleter = null;
        if (attempt == _maxConnectRetries) {
          _connectionStatus = ConnectionStatus.error;
          _errorMessage = 'Connection failed: $e';
          notifyListeners();
          return;
        }
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      final connected = await _connectionCompleter!.future
          .timeout(_connectTimeout, onTimeout: () => false);
      _connectionCompleter = null;

      if (connected) {
        Log.d('Connect: SUCCESS on attempt $attempt');
        return;
      }

      Log.d('Connect: attempt $attempt timed out');
      _vpnConnectionService?.disconnect();

      if (attempt < _maxConnectRetries) {
        _stageName = 'Retrying...';
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // All retries failed
    Log.d('Connect: all $_maxConnectRetries attempts failed for ${target.hostName}');
    _connectionStatus = ConnectionStatus.error;
    _errorMessage = 'Connection timed out. Try a different server.';
    notifyListeners();
  }

  /// Try servers one by one until one connects successfully.
  Future<void> autoConnect() async {
    Log.d('AutoConnect: started, servers=${_servers.length}, loading=$_isLoadingServers');

    // If no servers, fetch them first
    if (_servers.isEmpty) {
      _connectionStatus = ConnectionStatus.connecting;
      _stageName = 'Fetching servers...';
      _errorMessage = null;
      notifyListeners();

      if (!_isLoadingServers) {
        await loadServers();
      } else {
        while (_isLoadingServers) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }

    if (_servers.isEmpty) {
      Log.d('AutoConnect: no servers available after fetch');
      _connectionStatus = ConnectionStatus.error;
      _errorMessage = 'Failed to load servers. Tap to retry.';
      notifyListeners();
      return;
    }

    _isAutoConnecting = true;
    _errorMessage = null;
    _serverWentOffline = false;

    for (var i = 0; i < _servers.length; i++) {
      final server = _servers[i];

      // Stop if user disconnected manually during auto-connect
      if (!_isAutoConnecting) {
        Log.d('AutoConnect: cancelled by user at server ${i + 1}');
        return;
      }

      _selectedServer = server;
      _connectionStatus = ConnectionStatus.connecting;
      _stageName = 'Trying ${server.countryLong} (${i + 1}/${_servers.length})...';
      _reconnectCount = 0;
      notifyListeners();

      Log.d('AutoConnect: trying ${server.hostName} (${server.ip}), ${server.countryLong}, attempt ${i + 1}/${_servers.length}');

      // Create a completer that the stage callback will resolve
      _connectionCompleter = Completer<bool>();

      try {
        await _vpnConnectionService!.connect(server);
      } catch (e) {
        Log.error('AutoConnect: ${server.hostName} threw error', e);
        continue;
      }

      // Wait for the connection result (max 15 seconds per server)
      final connected = await _connectionCompleter!.future
          .timeout(const Duration(seconds: 15), onTimeout: () => false);

      if (connected) {
        Log.d('AutoConnect: SUCCESS with ${server.hostName} (${server.ip}) on attempt ${i + 1}');
        _isAutoConnecting = false;
        _connectionCompleter = null;
        return;
      }

      // Failed — disconnect before trying next
      Log.d('AutoConnect: FAILED ${server.hostName}, moving to next');
      _vpnConnectionService?.disconnect();
      // Brief pause between attempts
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // All servers failed
    Log.d('AutoConnect: ALL ${_servers.length} servers failed');
    _isAutoConnecting = false;
    _connectionCompleter = null;
    _connectionStatus = ConnectionStatus.error;
    _stageName = null;
    _errorMessage = 'Could not connect to any server. Try again later.';
    notifyListeners();
  }

  void switchServer(VpnServer server) {
    Log.d('Switch: from ${_selectedServer?.hostName} to ${server.hostName} (${server.ip}), status=$_connectionStatus');
    _switchDelayTimer?.cancel();
    _pendingSwitchServer = server;
    if (_connectionStatus == ConnectionStatus.connected ||
        _connectionStatus == ConnectionStatus.connecting) {
      // Disconnect first — the disconnect callback will trigger the new connection
      _isAutoConnecting = false;
      _connectionCompleter?.complete(false);
      _connectionCompleter = null;
      _connectionStatus = ConnectionStatus.disconnecting;
      _stageName = 'Switching server...';
      _stopTimer();
      notifyListeners();
      _vpnConnectionService?.disconnect();
    } else {
      // Not connected, connect directly
      _pendingSwitchServer = null;
      connectToServer(server);
    }
  }

  void disconnect() {
    Log.d('Disconnect: requested, status=$_connectionStatus, server=${_selectedServer?.hostName}');
    _switchDelayTimer?.cancel();
    _pendingSwitchServer = null;
    _isAutoConnecting = false;
    _connectionCompleter?.complete(false);
    _connectionCompleter = null;
    _connectionStatus = ConnectionStatus.disconnecting;
    _stageName = 'Disconnecting...';
    _errorMessage = null;
    notifyListeners();
    _vpnConnectionService?.disconnect();
  }

  void toggleFavorite(VpnServer server) {
    if (_favoriteIps.contains(server.ip)) {
      _favoriteIps.remove(server.ip);
      Log.d('Favorite removed: ${server.hostName} (${server.ip})');
    } else {
      _favoriteIps.add(server.ip);
      Log.d('Favorite added: ${server.hostName} (${server.ip})');
    }
    _saveFavorites();
    notifyListeners();
  }

  void _onStatusChanged(VpnStatus? status) {
    if (_disposed) return;
    _vpnStatus = status;

    // Calculate real-time speed
    if (status != null && _connectionStatus == ConnectionStatus.connected) {
      final now = DateTime.now();
      final byteIn = int.tryParse(status.byteIn ?? '0') ?? 0;
      final byteOut = int.tryParse(status.byteOut ?? '0') ?? 0;

      if (_prevSampleTime != null) {
        final elapsed = now.difference(_prevSampleTime!).inMilliseconds;
        if (elapsed > 0) {
          _downloadSpeed = (byteIn - _prevByteIn) / elapsed * 1000;
          _uploadSpeed = (byteOut - _prevByteOut) / elapsed * 1000;
          if (_downloadSpeed < 0) _downloadSpeed = 0;
          if (_uploadSpeed < 0) _uploadSpeed = 0;
          _updateConnectionQuality();
        }
      }
      _prevByteIn = byteIn;
      _prevByteOut = byteOut;
      _sessionByteIn = byteIn;
      _sessionByteOut = byteOut;
      _prevSampleTime = now;
    }

    notifyListeners();
  }

  void _resetSpeedTracking() {
    // Save session usage before resetting
    if (_sessionByteIn > 0 || _sessionByteOut > 0) {
      DataUsageService.addUsage(_sessionByteIn, _sessionByteOut);
    }
    _sessionByteIn = 0;
    _sessionByteOut = 0;
    _prevByteIn = 0;
    _prevByteOut = 0;
    _prevSampleTime = null;
    _downloadSpeed = 0;
    _uploadSpeed = 0;
    _connectionQuality = ConnectionQuality.unknown;
  }

  void _updateConnectionQuality() {
    final ping = _selectedServer?.ping ?? 999;
    final speedKBs = _downloadSpeed / 1024;

    if (ping < 80 && speedKBs > 500) {
      _connectionQuality = ConnectionQuality.good;
    } else if (ping < 150 || speedKBs > 100) {
      _connectionQuality = ConnectionQuality.fair;
    } else {
      _connectionQuality = ConnectionQuality.poor;
    }
  }

  void _onStageChanged(VPNStage? stage) {
    if (_disposed || stage == null) return;
    Log.d('VPN Stage: $stage, server=${_selectedServer?.hostName}');

    switch (stage) {
      case VPNStage.connected:
        _connectionStatus = ConnectionStatus.connected;
        _stageName = 'Connected';
        _connectedAt ??= DateTime.now();
        _reconnectCount = 0;
        _resetSpeedTracking();
        _saveConnectionState();
        _startTimer();
        if (_selectedServer != null) _addRecentServer(_selectedServer!);
        Log.d('VPN CONNECTED to ${_selectedServer?.hostName} (${_selectedServer?.ip}), ${_selectedServer?.countryLong}');
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(true);
        }
        break;
      case VPNStage.disconnected:
        _resetSpeedTracking();
        Log.d('VPN DISCONNECTED, pendingSwitch=${_pendingSwitchServer?.hostName}');
        _connectedAt = null;
        _clearConnectionState();
        _stopTimer();
        // Signal auto-connect that this server failed
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(false);
        }
        // If switching to a new server, wait for OpenVPN engine to reset
        if (_pendingSwitchServer != null) {
          final server = _pendingSwitchServer!;
          _pendingSwitchServer = null;
          _connectionStatus = ConnectionStatus.connecting;
          _stageName = 'Switching server...';
          Log.d('VPN: switching to ${server.hostName} after 2s delay');
          notifyListeners();
          _switchDelayTimer?.cancel();
          _switchDelayTimer = Timer(const Duration(seconds: 2), () {
            connectToServer(server);
          });
          return;
        }
        _connectionStatus = ConnectionStatus.disconnected;
        _stageName = null;
        _errorMessage = null;
        break;
      case VPNStage.wait_connection:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Waiting for connection...';
        break;
      case VPNStage.authenticating:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Authenticating...';
        break;
      case VPNStage.tcp_connect:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Connecting (TCP)...';
        break;
      case VPNStage.udp_connect:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Connecting (UDP)...';
        break;
      case VPNStage.assign_ip:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Assigning IP...';
        break;
      case VPNStage.resolve:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Resolving host...';
        break;
      case VPNStage.vpn_generate_config:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Generating config...';
        break;
      case VPNStage.get_config:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Loading config...';
        break;
      case VPNStage.prepare:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Preparing...';
        break;
      case VPNStage.connecting:
        _connectionStatus = ConnectionStatus.connecting;
        _stageName = 'Connecting...';
        break;
      case VPNStage.exiting:
        _connectionStatus = ConnectionStatus.disconnecting;
        _stageName = 'Disconnecting...';
        break;
      case VPNStage.denied:
        Log.d('VPN DENIED: permission denied by user');
        _connectionStatus = ConnectionStatus.error;
        _stageName = null;
        _errorMessage = 'VPN permission denied';
        _stopTimer();
        break;
      case VPNStage.error:
        Log.error('VPN ERROR: connection error on ${_selectedServer?.hostName}');
        _connectionStatus = ConnectionStatus.error;
        _stageName = null;
        _errorMessage = 'Connection error occurred';
        _stopTimer();
        break;
      default:
        // The 'reconnect' raw stage maps here
        _reconnectCount++;
        Log.d('VPN RECONNECT #$_reconnectCount on ${_selectedServer?.hostName}, autoConnect=$_isAutoConnecting');
        if (_reconnectCount >= 4) {
          Log.d('VPN OFFLINE: ${_selectedServer?.hostName} failed after $_reconnectCount reconnects');
          _reconnectCount = 0;
          _connectedAt = null;
          _clearConnectionState();
          _stopTimer();
          _vpnConnectionService?.disconnect();
          if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
            // Auto-connect mode: signal failure, let it try next server
            _connectionCompleter!.complete(false);
          } else {
            // Manual connect: show error to user
            _connectionStatus = ConnectionStatus.error;
            _stageName = null;
            _errorMessage = 'Server appears to be offline. Try a different server.';
            _serverWentOffline = true;
          }
        } else {
          _connectionStatus = ConnectionStatus.connecting;
          _stageName = 'Reconnecting (${_reconnectCount}/3)...';
        }
    }
    notifyListeners();
  }

  void _startTimer() {
    _connectionTimer?.cancel();
    if (_connectedAt != null) {
      connectionDurationNotifier.value = DateTime.now().difference(_connectedAt!);
    } else {
      connectionDurationNotifier.value = Duration.zero;
    }
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt != null) {
        connectionDurationNotifier.value = DateTime.now().difference(_connectedAt!);
      } else {
        connectionDurationNotifier.value += const Duration(seconds: 1);
      }
    });
  }

  void _stopTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
    connectionDurationNotifier.value = Duration.zero;
  }

  Future<void> _saveConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedServer != null) {
      await prefs.setString('connected_server', jsonEncode(_selectedServer!.toJson()));
    }
    if (_connectedAt != null) {
      await prefs.setString('connected_at', _connectedAt!.toIso8601String());
    }
    Log.d('State: saved connection, server=${_selectedServer?.hostName}, connectedAt=$_connectedAt');
  }

  Future<void> _clearConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connected_server');
    await prefs.remove('connected_at');
    Log.d('State: cleared connection');
  }

  Future<void> _restoreConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    final serverJson = prefs.getString('connected_server');
    final connectedAtStr = prefs.getString('connected_at');

    if (serverJson != null) {
      try {
        _selectedServer = VpnServer.fromJson(jsonDecode(serverJson));
        if (connectedAtStr != null) {
          _connectedAt = DateTime.parse(connectedAtStr);
          _connectionStatus = ConnectionStatus.connected;
          _stageName = 'Connected';
          _startTimer();
        }
        Log.d('State: restored server=${_selectedServer!.hostName} (${_selectedServer!.ip}), connectedAt=$_connectedAt');
      } catch (e) {
        Log.error('State: restore failed', e);
        await _clearConnectionState();
      }
    } else {
      Log.d('State: no saved connection found');
    }
  }

  void _startBackgroundRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_isAutoConnecting) {
        Log.d('Refresh: skipped, auto-connect in progress');
        return;
      }
      Log.d('Refresh: background server list refresh starting');
      try {
        final freshServers = await _vpnGateService.fetchServers();
        _servers = freshServers;
        _onlineServerIps = _servers.map((s) => s.ip).toSet();
        Log.d('Refresh: loaded ${_servers.length} servers');
        notifyListeners();
      } catch (e) {
        Log.error('Refresh: background refresh failed', e);
      }
    });
  }

  void _addRecentServer(VpnServer server) {
    _recentServers.removeWhere((s) => s.ip == server.ip);
    _recentServers.insert(0, server);
    if (_recentServers.length > 5) {
      _recentServers = _recentServers.sublist(0, 5);
    }
    _saveRecentServers();
  }

  Future<void> _saveRecentServers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _recentServers.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('recent_servers', jsonList);
  }

  Future<void> _loadRecentServers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('recent_servers');
    if (jsonList != null) {
      _recentServers = jsonList
          .map((s) => VpnServer.fromJson(jsonDecode(s)))
          .toList();
    }
    Log.d('Recent: loaded ${_recentServers.length} recent servers');
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorite_ips');
    if (favs != null) {
      _favoriteIps = favs.toSet();
    }
    Log.d('Favorites: loaded ${_favoriteIps.length} favorites');
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_ips', _favoriteIps.toList());
  }

  @override
  void dispose() {
    Log.d('Provider: disposing');
    _disposed = true;
    _connectionTimer?.cancel();
    _refreshTimer?.cancel();
    _switchDelayTimer?.cancel();
    connectionDurationNotifier.dispose();
    super.dispose();
  }
}
