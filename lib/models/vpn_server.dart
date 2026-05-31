class VpnServer {
  final String hostName;
  final String ip;
  final int score;
  final int ping;
  final int speed;
  final String countryLong;
  final String countryShort;
  final int numVpnSessions;
  final int uptime;
  final int totalUsers;
  final int totalTraffic;
  final String logType;
  final String operator_;
  final String message;
  final String openVpnConfigBase64;

  VpnServer({
    required this.hostName,
    required this.ip,
    required this.score,
    required this.ping,
    required this.speed,
    required this.countryLong,
    required this.countryShort,
    required this.numVpnSessions,
    required this.uptime,
    required this.totalUsers,
    required this.totalTraffic,
    required this.logType,
    required this.operator_,
    required this.message,
    required this.openVpnConfigBase64,
  });

  String get flagEmoji {
    if (countryShort.length != 2) return '';
    final first = 0x1F1E6 + countryShort.codeUnitAt(0) - 0x41;
    final second = 0x1F1E6 + countryShort.codeUnitAt(1) - 0x41;
    return String.fromCharCodes([first, second]);
  }

  String get speedMbps {
    final mbps = speed / 1000000;
    if (mbps >= 100) return '${mbps.toStringAsFixed(0)} Mbps';
    if (mbps >= 10) return '${mbps.toStringAsFixed(1)} Mbps';
    return '${mbps.toStringAsFixed(2)} Mbps';
  }

  String get pingDisplay => ping > 0 ? '${ping}ms' : 'N/A';

  String get sessionsDisplay => '$numVpnSessions sessions';

  factory VpnServer.fromCsvRow(List<dynamic> row) {
    return VpnServer(
      hostName: _str(row, 0),
      ip: _str(row, 1),
      score: _int(row, 2),
      ping: _int(row, 3),
      speed: _int(row, 4),
      countryLong: _str(row, 5),
      countryShort: _str(row, 6),
      numVpnSessions: _int(row, 7),
      uptime: _int(row, 8),
      totalUsers: _int(row, 9),
      totalTraffic: _int(row, 10),
      logType: _str(row, 11),
      operator_: _str(row, 12),
      message: _str(row, 13),
      openVpnConfigBase64: _str(row, 14),
    );
  }

  Map<String, dynamic> toJson() => {
    'hostName': hostName,
    'ip': ip,
    'score': score,
    'ping': ping,
    'speed': speed,
    'countryLong': countryLong,
    'countryShort': countryShort,
    'numVpnSessions': numVpnSessions,
    'uptime': uptime,
    'totalUsers': totalUsers,
    'totalTraffic': totalTraffic,
    'logType': logType,
    'operator_': operator_,
    'message': message,
    'openVpnConfigBase64': openVpnConfigBase64,
  };

  factory VpnServer.fromJson(Map<String, dynamic> json) => VpnServer(
    hostName: json['hostName'] ?? '',
    ip: json['ip'] ?? '',
    score: json['score'] ?? 0,
    ping: json['ping'] ?? 0,
    speed: json['speed'] ?? 0,
    countryLong: json['countryLong'] ?? '',
    countryShort: json['countryShort'] ?? '',
    numVpnSessions: json['numVpnSessions'] ?? 0,
    uptime: json['uptime'] ?? 0,
    totalUsers: json['totalUsers'] ?? 0,
    totalTraffic: json['totalTraffic'] ?? 0,
    logType: json['logType'] ?? '',
    operator_: json['operator_'] ?? '',
    message: json['message'] ?? '',
    openVpnConfigBase64: json['openVpnConfigBase64'] ?? '',
  );

  static String _str(List<dynamic> row, int i) =>
      i < row.length ? row[i].toString().trim() : '';

  static int _int(List<dynamic> row, int i) =>
      i < row.length ? int.tryParse(row[i].toString().trim()) ?? 0 : 0;
}
