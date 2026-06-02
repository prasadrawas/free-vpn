# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Platform

This project targets **Android only**. Do not configure, modify, or create files for iOS, web, Linux, macOS, or Windows. The `ios/` folder exists for legacy reasons but is not actively maintained.

## Build & Run

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected Android device (debug)
flutter build apk --release      # Release APK (for sharing)
flutter build appbundle --release # Release AAB (for Play Store)
flutter analyze          # Static analysis
flutter test             # Run tests
```

Android requires JVM 17. `jniLibs.useLegacyPackaging = true` is set in `build.gradle.kts` for OpenVPN native libraries. Release builds require `android/key.properties` with keystore credentials (not committed).

## Architecture

Single-provider architecture using `ChangeNotifierProvider<VpnProvider>` at the root.

**VpnProvider** (`lib/providers/vpn_provider.dart`) is the central state manager. It owns:
- **VpnConnectionService** — wraps `openvpn_flutter`, handles config sanitization and cipher negotiation
- **VpnGateService** — fetches and parses the VPN Gate CSV API via `dio` with ISP bypass fallback
- **DataUsageService** — tracks daily VPN data consumption in SharedPreferences

**Data flow:** VpnGateService fetches servers → VpnProvider holds server list + connection state → UI widgets consume via `Consumer<VpnProvider>`.

**Screens:**
- `SplashScreen` — 1.5s branded splash with creator credits
- `HomeScreen` — connect button, timer, speed display, quality indicator, server selector
- `ServerListScreen` — country filter chips, search, recently connected, favorites, all servers
- `SettingsScreen` — data usage, about, legal pages (WebView)
- `DataUsageScreen` — daily/weekly/monthly usage stats

**Widgets** (`ConnectButton`, `ConnectionTimer`, `StatusDisplay`, `ServerCard`) all use `Consumer<VpnProvider>` — no direct service access. `ConnectionTimer` uses a separate `ValueNotifier<Duration>` to avoid rebuilding the entire widget tree every second.

## Key Technical Details

### OpenVPN Config Sanitization
`VpnConnectionService._sanitizeConfig()` strips 21 dangerous/incompatible directives including `register-dns`, `block-outside-dns`, `auth-user-pass`, `log`, `plugin`, `tls-verify`, `route-up`, etc. Appends `data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC` and `data-ciphers-fallback AES-128-CBC` for cipher negotiation with the bundled 2020-era OpenVPN library.

### ISP DNS Bypass
`VpnGateService` tries the main VPN Gate URL first, then falls back to direct IP endpoints (`130.158.75.42`, `.40`, `.39`) with Host header and SSL certificate validation (checks cert subject contains `vpngate.net`). This bypasses DNS blocking by Indian ISPs (Jio, Vi, Airtel).

### Connection Lifecycle
- **Auto-connect:** Iterates servers using a `Completer<bool>` per attempt, 15s timeout each
- **Manual connect:** 30s timeout with 2 retries
- **Server switch:** Disconnects first, stores `_pendingSwitchServer`, waits 2 seconds (cancellable `Timer`) after disconnect for OpenVPN engine reset, then connects to new server
- **Reconnect detection:** 4 consecutive `reconnect` stage events = server offline. Auto-connect silently skips to next; manual mode shows offline warning via SnackBar

### Real-time Speed & Quality
Speed is calculated from `VpnStatus.byteIn/byteOut` deltas in `_onStatusChanged`. Connection quality (Good/Fair/Poor) is derived from ping (< 80ms) and download speed (> 500 KB/s). The `_disposed` flag prevents callbacks on disposed provider.

### State Persistence (SharedPreferences)
- `connected_server` + `connected_at` — restored on launch to resume connected state with accurate timer
- `favorite_ips` — persisted as `List<String>`
- `recent_servers` — last 5 connected servers as JSON list
- `data_usage` — daily download/upload bytes, last 30 days
- `battery_opt_dismissed` — battery optimization dialog state

### Server Filtering & Sorting
Servers with ping <= 0, zero sessions, speed < 0.5 Mbps, or score <= 0 are removed. Sorted by score (reliability) → speed → ping. Country filter and text search available on server list.

### Background Refresh
Server list re-fetches every 5 minutes via `Timer.periodic`. Skipped during auto-connect. Errors suppressed during active VPN sessions.

### Logging
`Log.d()` and `Log.error()` in `services/logger.dart`. Debug mode: `debugPrint`. Release mode: Firebase Crashlytics breadcrumbs (with Firebase availability check to prevent crashes if Firebase init fails).

### Native Platform Channel
`com.prasadrawas.freevpn/battery` channel in `MainActivity.kt` handles: battery optimization check/request, battery settings intent, and notification permission request (Android 13+).

## Dependencies

| Package | Purpose |
|---|---|
| `openvpn_flutter` | VPN tunnel (Android) |
| `dio` | HTTP client with retry and ISP bypass |
| `csv` | Parse VPN Gate CSV response |
| `provider` | State management |
| `shared_preferences` | Persistence (state, favorites, recent, usage) |
| `google_fonts` | Inter + JetBrains Mono fonts |
| `firebase_core` | Firebase initialization |
| `firebase_crashlytics` | Crash reporting with breadcrumb logs |
| `firebase_analytics` | Anonymous usage analytics |
| `webview_flutter` | Legal pages loaded from website |
| `package_info_plus` | Dynamic version display in About |
