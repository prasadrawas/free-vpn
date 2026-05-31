import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppTheme.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              titlePadding: EdgeInsets.only(left: 56, bottom: 16),
              centerTitle: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    onTap: () => _push(context, const _AboutPage()),
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _push(context, const _PolicyPage(
                      title: 'Privacy Policy',
                      content: _privacyPolicy,
                    )),
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => _push(context, const _PolicyPage(
                      title: 'Terms of Service',
                      content: _termsOfService,
                    )),
                  ),
                  _SettingsTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'VPN Disclaimer',
                    onTap: () => _push(context, const _PolicyPage(
                      title: 'VPN Disclaimer',
                      content: _vpnDisclaimer,
                    )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppTheme.accentCyan.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.accentCyan, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppTheme.primaryDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/app_icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Text(
                'FreeVPN',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const _InfoRow(label: 'Developer', value: 'Prasad Rawas'),
            const _InfoRow(label: 'VPN Service', value: 'VPN Gate (vpngate.net)'),
            const _InfoRow(label: 'Protocol', value: 'OpenVPN'),
            const Spacer(),
            Text(
              'This app connects to free, volunteer-run VPN Gate\nrelay servers. No account or subscription required.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyPage extends StatelessWidget {
  final String title;
  final String content;

  const _PolicyPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}

const _privacyPolicy = '''
Last updated: May 2026

FreeVPN ("the App") is developed by Prasad Rawas. This Privacy Policy explains how information is handled when you use the App.

1. Information We Collect

The App does not collect, store, or transmit any personal information. We do not require account registration, and no user data is sent to our servers.

2. VPN Gate Servers

The App connects to free VPN Gate relay servers operated by volunteers worldwide through the VPN Gate Academic Experiment Project (vpngate.net). When you connect to a VPN server:

- Your internet traffic is routed through the selected relay server
- The relay server operator may log connection timestamps and IP addresses as per VPN Gate's policy
- We have no control over data handling by individual relay server operators

3. Network Data

The App accesses the internet solely to:
- Fetch the list of available VPN servers from the VPN Gate public API
- Establish OpenVPN connections to selected servers

4. Local Storage

The App stores the following data locally on your device only:
- Selected and previously connected server information
- Favorite server list
- Connection timestamps for the session timer

This data never leaves your device and is not transmitted to any server.

5. Third-Party Services

The App uses VPN Gate (vpngate.net), a public VPN relay service operated by the University of Tsukuba, Japan. Please refer to VPN Gate's privacy policy for their data handling practices.

6. Children's Privacy

The App is not intended for use by children under 13. We do not knowingly collect information from children.

7. Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be reflected in the "Last updated" date above.

8. Contact

If you have questions about this Privacy Policy, please contact the developer, Prasad Rawas.
''';

const _termsOfService = '''
Last updated: May 2026

Please read these Terms of Service ("Terms") carefully before using FreeVPN ("the App") developed by Prasad Rawas.

1. Acceptance of Terms

By downloading, installing, or using the App, you agree to be bound by these Terms. If you do not agree, do not use the App.

2. Description of Service

The App provides a free VPN client that connects to VPN Gate public relay servers. The App does not operate any VPN servers itself.

3. No Warranty

The App is provided "as is" without warranties of any kind, either express or implied. We do not guarantee:
- Continuous, uninterrupted, or secure access to VPN servers
- The speed, reliability, or availability of any VPN server
- That the service will meet your specific requirements

4. Use at Your Own Risk

VPN Gate relay servers are operated by volunteers worldwide. We have no control over these servers and cannot guarantee their security, privacy practices, or reliability. You use the App and connect to VPN servers at your own risk.

5. Acceptable Use

You agree not to use the App to:
- Violate any applicable laws or regulations
- Engage in any illegal activities
- Infringe upon the rights of others
- Distribute malware or harmful content
- Attempt to compromise VPN server security

6. Limitation of Liability

To the maximum extent permitted by law, the developer shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App.

7. VPN Gate Terms

By using the App, you also agree to abide by VPN Gate's terms and conditions as published at vpngate.net.

8. Modifications

We reserve the right to modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the modified Terms.

9. Governing Law

These Terms shall be governed by and construed in accordance with applicable laws.

10. Contact

For questions about these Terms, please contact the developer, Prasad Rawas.
''';

const _vpnDisclaimer = '''
IMPORTANT: Please read this disclaimer carefully before using FreeVPN.

Volunteer-Run Servers

FreeVPN connects to VPN Gate relay servers, which are operated by volunteers around the world as part of an academic research project by the University of Tsukuba, Japan. These servers are NOT operated, maintained, or controlled by the developer of this App.

No Privacy Guarantee

While a VPN encrypts your connection between your device and the VPN server, the relay server operator can potentially see your internet traffic after it exits the VPN tunnel. Volunteer server operators may log connection data including:
- Your real IP address
- Connection timestamps
- Bandwidth usage

Do Not Use for Sensitive Activities

This App is intended for general privacy enhancement and accessing geo-restricted content. Do NOT rely on this App for:
- Protecting highly sensitive or confidential information
- Anonymity in situations where your safety depends on it
- Circumventing legal restrictions in your jurisdiction

Speed and Reliability

Free VPN servers may be:
- Slow or congested due to high usage
- Temporarily or permanently unavailable
- Subject to connection drops without warning

Server operators can shut down their servers at any time.

Legal Responsibility

You are solely responsible for ensuring that your use of VPN services complies with all applicable laws in your country and jurisdiction. Some countries restrict or prohibit the use of VPN services.

No Liability

The developer of this App assumes no liability for:
- Actions taken by VPN server operators
- Data breaches or privacy violations on relay servers
- Any damages arising from the use of this App
- Service interruptions or connection failures

By using this App, you acknowledge that you have read and understood this disclaimer and agree to use the service at your own risk.
''';
