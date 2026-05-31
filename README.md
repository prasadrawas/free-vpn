# FreeVPN

A free, open-source VPN client for Android and iOS built with Flutter. Connects to [VPN Gate](https://www.vpngate.net/) public relay servers using OpenVPN.

![FreeVPN Banner](assets/screenshots/freevpn-banner.webp)

## Features

- Auto-connect to the best available server
- Server list sorted by reliability score, speed, and ping
- Server switching without manual disconnect
- Favorite servers
- Connection timer with state persistence across app restarts
- Background server list refresh every 5 minutes
- Reconnect loop detection with automatic server failover
- Offline server warnings

## Screenshots

| Intro | Splash | Connecting | Connected | Server List |
|:---:|:---:|:---:|:---:|:---:|
| ![Intro](assets/screenshots/1_intro.png) | ![Splash](assets/screenshots/2_splash.png) | ![Connecting](assets/screenshots/3_connecting.png) | ![Connected](assets/screenshots/4_connected.png) | ![Servers](assets/screenshots/5_server_list.png) |

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
- **Firebase Crashlytics & Analytics** for crash reporting and usage insights
- **SharedPreferences** for connection state and favorites persistence

## Privacy & Legal

- [Privacy Policy](https://prasadrawas.github.io/free-vpn/privacy.html)
- [Terms of Service](https://prasadrawas.github.io/free-vpn/terms.html)
- [VPN Disclaimer](https://prasadrawas.github.io/free-vpn/disclaimer.html)

## License

This project is open source. Created by **Prasad Rawas**.
