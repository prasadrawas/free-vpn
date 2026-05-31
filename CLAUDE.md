# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device (debug)
flutter run --release    # Release build
flutter build apk        # Build Android APK
flutter analyze          # Static analysis
flutter test             # Run tests
```

Android requires JVM 17. `jniLibs.useLegacyPackaging = true` is set in `build.gradle.kts` for OpenVPN native libraries.

## Architecture

Single-provider architecture using `ChangeNotifierProvider<VpnProvider>` at the root.

**VpnProvider** (`lib/providers/vpn_provider.dart`) is the central state manager. It owns:
- **VpnConnectionService** — wraps `openvpn_flutter`, handles config sanitization and cipher negotiation
- **VpnGateService** — fetches and parses the VPN Gate CSV API via `dio` with 3 retries

**Data flow:** VpnGateService fetches servers → VpnProvider holds server list + connection state → UI widgets consume via `Consumer<VpnProvider>`.

**Screens:** `HomeScreen` (connect button, timer, status) and `ServerListScreen` (search, favorites, server cards with online indicators).

**Widgets** (`ConnectButton`, `ConnectionTimer`, `StatusDisplay`, `ServerCard`) all use `Consumer<VpnProvider>` — no direct service access.

## Key Technical Details

### OpenVPN Config Sanitization
`VpnConnectionService._sanitizeConfig()` strips directives that break the `openvpn_flutter` plugin: `register-dns`, `block-outside-dns`, `setenv`, `up `, `down `, `script-security`, `dhcp-option`, `pull-filter`, `inactive`, `auth-user-pass`. It appends `data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC` and `data-ciphers-fallback AES-128-CBC` for cipher negotiation with the bundled 2020-era OpenVPN library.

### Connection Lifecycle
- **Auto-connect:** Iterates servers using a `Completer<bool>` per attempt, 15s timeout each
- **Server switch:** Disconnects first, stores `_pendingSwitchServer`, waits 2 seconds after disconnect for OpenVPN engine reset, then connects to new server
- **Reconnect detection:** 4 consecutive `reconnect` stage events = server offline. Auto-connect silently skips to next; manual mode shows offline warning via SnackBar

### State Persistence (SharedPreferences)
- `connected_server` + `connected_at` — restored on launch to resume connected state with accurate timer
- `favorite_ips` — persisted as `List<String>`
- Connection state is cleared on disconnect; only restored if both server and timestamp exist

### Server Filtering
Servers with ping <= 0, zero sessions, speed < 0.5 Mbps, or score <= 0 are removed. Sorted by score (reliability) → speed → ping.

### Background Refresh
Server list re-fetches every 5 minutes via `Timer.periodic`. Errors are suppressed during active VPN sessions.

## Dependencies

| Package | Purpose |
|---|---|
| `openvpn_flutter` | VPN tunnel (Android/iOS) |
| `dio` | HTTP client with retry for VPN Gate API |
| `csv` | Parse VPN Gate CSV response |
| `provider` | State management |
| `shared_preferences` | Persistence |
| `google_fonts` | Inter + JetBrains Mono fonts |
