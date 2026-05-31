# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# OpenVPN
-keep class de.blinkt.openvpn.** { *; }
-keep class id.laskarmedia.openvpn_flutter.** { *; }

# Google Play Core (referenced by Flutter deferred components)
-dontwarn com.google.android.play.core.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
