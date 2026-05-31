# FreeVPN

A free, open-source VPN client for Android and iOS built with Flutter. Connects to [VPN Gate](https://www.vpngate.net/) public relay servers using OpenVPN.

## Features

- Auto-connect to the best available server
- Server list sorted by reliability score, speed, and ping
- Server switching without manual disconnect
- Favorite servers
- Connection timer with state persistence across app restarts
- Background server list refresh every 5 minutes
- Reconnect loop detection with automatic server failover
- Offline server warnings

## Requirements

- Flutter 3.12+
- Android SDK with CMake 3.22.1
- JDK 17

## Setup

```bash
flutter pub get
flutter run
```

## How It Works

The app fetches free VPN servers from the [VPN Gate API](https://www.vpngate.net/api/iphone/), filters out unreliable ones (low speed, no sessions, no ping), and connects using the `openvpn_flutter` plugin.

OpenVPN configs from VPN Gate are sanitized at connect time to strip directives incompatible with the mobile OpenVPN library, and cipher negotiation directives are injected for compatibility.

## Tech Stack

- **Flutter** with Provider for state management
- **openvpn_flutter** for VPN tunnel
- **Dio** for API requests with retry logic
- **SharedPreferences** for connection state and favorites persistence
