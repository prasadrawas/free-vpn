# Changelog

## 1.0.6+7 (2026-06-03)

### UX Improvements
- Added notification permission check on first VPN connection — shows a SnackBar with "ENABLE" shortcut to system notification settings when permission is denied

## 1.0.5+6 (2026-06-02)

### Bug Fixes
- Fixed home screen layout overflow on smaller screens by rebalancing flex distribution
- Added null safety guard for VPN connection service in auto-connect

### UX Improvements
- Server selector now shows a styled "Change" button instead of a plain chevron icon
- Added shimmer animation on server selector to draw attention on first launch

### Chore
- Removed integration tests and package
- Added Play Store feature graphic (1024x500)

## 1.0.4+5 (2026-06-02)

### Bug Fixes
- Fixed status display overflow on smaller screens
- Version bump for Play Store release

## 1.0.3+5 (2026-06-02)

### New Features
- Real-time download/upload speed display on home screen (KB/s, MB/s)
- Connection quality indicator badge (Good/Fair/Poor) based on ping and speed
- Country filter chips on server list for quick filtering
- Recently connected servers section (last 5) on server list
- Signal strength bars replacing linear speed indicator on server cards
- Data usage tracking with daily/weekly/monthly breakdown in Settings
- VPN notification shows server country name ("FreeVPN - Japan")
- Notification permission request for Android 13+

### Improvements
- Speed displayed in Mbps next to signal bars with color coding
- Legal pages (Privacy, Terms, Disclaimer) loaded via WebView from website
- Dynamic version display in About screen using package_info_plus

## 1.0.2+3 (2026-06-01)

### Bug Fixes
- Fixed logger crash when Firebase not initialized in release builds
- Fixed release signing — key.properties path corrected in build.gradle.kts

## 1.0.1+2 (2026-06-01)

### Bug Fixes
- Fixed Firebase Crashlytics crash on app launch in release mode
- Logger now checks Firebase availability before accessing Crashlytics

## 1.0.0+1 (2026-05-31)

### Build & Configuration
- Removed `android:extractNativeLibs="true"` and used `jniLibs.useLegacyPackaging` instead
- Added `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_SPECIAL_USE` permissions
- Changed application ID from `com.example.free_vpns` to `com.prasadrawas.freevpn`
- Configured release signing with keystore, ProGuard rules, R8 minification
- Adaptive launcher icons with dark navy background
- Native Android launch screen matching app theme
- Integrated Firebase Crashlytics and Analytics

### VPN Connection
- OpenVPN config sanitization — strips 21 dangerous/incompatible directives
- Cipher negotiation via `data-ciphers` and `data-ciphers-fallback` directives
- ISP DNS bypass using direct IP fallback with SSL certificate validation
- Reconnect loop detection (4 retries = server offline)
- 30s connection timeout with 2 automatic retries
- Cancellable 2s server switch delay

### Auto-Connect
- One-tap auto-connect tries servers one by one (15s timeout each)
- Fetches servers if list empty, retries on failure
- Shows progress: "Trying Japan (1/50)..."

### Server List
- Filtered by ping, sessions, speed, and score thresholds
- Sorted by VPN Gate reliability score, then speed, then ping
- Online indicator (green/grey dot) on server cards
- Search by country, hostname
- Favorite servers with persistence

### Server Switching
- Auto-connect on server tap from list
- Proper disconnect → 2s delay → connect sequence
- "Switching server..." status during transition

### State Persistence
- Connection state (server + timestamp) survives app kills
- Timer resumes from actual elapsed time on relaunch
- Favorites persisted across sessions

### UX
- Animated connect button with rotating ring (connecting), pulse glow (connected), red disconnect on press
- "Tap to disconnect" hint when connected
- Splash screen with creator credits (1.5s)
- Settings with About, Privacy Policy, Terms, Disclaimer
- Battery optimization prompt for aggressive OEM ROMs
- Offline server snackbar with quick switch action
- Error messages suppressed during active sessions
- Server fetch errors only shown when disconnected and no cached servers

### Infrastructure
- Unified logger: debugPrint in debug, Crashlytics breadcrumbs in release
- Background server refresh every 5 minutes (skipped during auto-connect)
- Callbacks guarded against disposed provider
- 115+ unit tests covering models, services, provider, and widgets
- Landing page website on GitHub Pages with SEO
- Custom domain: freevpn.prasadrawas.online
