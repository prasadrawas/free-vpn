# Changelog

## 2026-05-31

### Build & Configuration Fixes
- Removed `android:extractNativeLibs="true"` from AndroidManifest.xml and moved to `jniLibs.useLegacyPackaging = true` in build.gradle.kts to fix Gradle `packageDebug` build failure
- Renamed Android SDK `cmdline-tools/latest-3` to `latest` to fix inconsistent location warning
- Cleaned up stale `cmdline-tools/latest-2` and `latest-backup` directories
- Added `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_SPECIAL_USE` permissions to AndroidManifest.xml

### VPN Connection Fixes
- Added OpenVPN config sanitization — strips problematic directives (`register-dns`, `block-outside-dns`, `auth-user-pass`, etc.) that caused connection failures with the `openvpn_flutter` plugin
- Added `data-ciphers` and `data-ciphers-fallback` directives to enable cipher negotiation between the 2020-era OpenVPN library and modern VPN Gate servers
- Fixed reconnect loop (`wait_connection → authenticating → get_config → reconnect`) by enabling proper cipher fallback to AES-128-CBC

### Server List Improvements
- Filtered out unusable servers: no ping response, zero sessions, speed < 0.5 Mbps, zero score
- Sorted servers by VPN Gate score (reliability) first, then speed, then ping
- Added background server list auto-refresh every 5 minutes
- Added online indicator (green/grey dot) on server cards
- Switched from `http` to `dio` package for network requests
- Added 3 retries with increasing delay (2s, 4s, 6s) for server list fetching
- Set 10s connect timeout and 30s receive timeout for API calls
- Removed `http` package dependency

### Auto-Connect
- Added auto-connect feature: tapping Connect with no server selected tries servers one by one until one works (15s timeout per server)
- Connect button retries server fetch if list is empty — shows "Fetching servers..." instead of immediate error
- Tapping Connect after a failed fetch retries the fetch and auto-connects

### Server Switching
- Tapping any server in the list auto-connects (disconnects current if needed)
- Added `switchServer` method with `_pendingSwitchServer` to properly sequence disconnect → 2s delay → connect, avoiding race conditions where the OpenVPN engine wasn't ready
- UI shows "Switching server..." during the transition

### Reconnect Loop Detection
- Detects reconnect loops (4 consecutive reconnect attempts) and stops the connection
- In manual mode: shows "Server appears to be offline. Try a different server." error
- In auto-connect mode: silently skips to the next server
- Removed false-positive offline detection based on API list (server can be working but not in current API response)

### State Persistence
- Added JSON serialization (`toJson`/`fromJson`) to `VpnServer` model
- Saved connected server and connection start time to SharedPreferences
- On relaunch: restores connection status, selected server, and timer (continues from actual elapsed time)
- Cleared saved state on disconnect
- Only restores selected server if there was an active connection (no stale server on fresh launch)

### Disconnect UX
- Connect button toggles to disconnect when connected
- On press-down while connected: button turns red with "DISCONNECT" label and power icon
- On release: returns to green "CONNECTED" state (or disconnects if tap completes)
- Added "Tap to disconnect" hint text below button when connected
- Disconnect clears all error messages

### Error Handling
- Server fetch errors suppressed while VPN is connected (don't disrupt active sessions)
- Server fetch errors only shown when fully disconnected and no cached servers
- Disconnect clears any stale error messages
- Error message updated to "Tap to retry" instead of "Pull to refresh"

### Logging
- Removed file-based `LogService` and `path_provider` dependency
- Replaced all logging with `debugPrint` (console only in debug mode)

### Offline Server Warning
- Added floating snackbar with "SWITCH" button when server goes offline
- Offline warning only triggers from actual VPN reconnect failures, not API list changes
