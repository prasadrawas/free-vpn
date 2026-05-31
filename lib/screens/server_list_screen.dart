import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vpn_server.dart';
import '../providers/vpn_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/server_card.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<VpnProvider>(
        builder: (context, provider, _) {
          final servers = _filteredServers(provider.servers);
          final favorites = _filteredServers(provider.favoriteServers);
          final rawMaxSpeed = provider.servers.isEmpty
              ? 1.0
              : provider.servers.first.speed.toDouble();
          final maxSpeed = rawMaxSpeed > 0 ? rawMaxSpeed : 1.0;

          return CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                backgroundColor: AppTheme.primaryDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Select Server',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  titlePadding:
                      const EdgeInsets.only(left: 56, bottom: 16),
                  centerTitle: false,
                ),
                actions: [
                  if (provider.isLoadingServers)
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ),
                ],
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search by country...',
                      hintStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Quick connect (fastest server)
              if (_searchQuery.isEmpty && servers.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: _QuickConnectCard(
                      server: servers.first,
                      onTap: () => _selectAndConnect(provider, servers.first),
                    ),
                  ),
                ),

              // Favorites section
              if (favorites.isNotEmpty && _searchQuery.isEmpty) ...[
                const SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Favorites'),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final server = favorites[index];
                      return ServerCard(
                        server: server,
                        isSelected:
                            provider.selectedServer?.ip == server.ip,
                        isFavorite: true,
                        isOnline: provider.isOnline(server),
                        maxSpeed: maxSpeed,
                        onTap: () => _selectAndConnect(provider, server),
                        onFavoriteTap: () =>
                            provider.toggleFavorite(server),
                      );
                    },
                    childCount: favorites.length,
                  ),
                ),
              ],

              // All servers
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: _searchQuery.isEmpty
                      ? 'All Servers (${servers.length})'
                      : 'Results (${servers.length})',
                ),
              ),

              // Error state
              if (provider.errorMessage != null && servers.isEmpty)
                SliverFillRemaining(
                  child: _ErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadServers(),
                  ),
                ),

              // Loading state
              if (provider.isLoadingServers && servers.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ),

              // Server list
              if (servers.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final server = servers[index];
                      return ServerCard(
                        server: server,
                        isSelected:
                            provider.selectedServer?.ip == server.ip,
                        isFavorite: provider.isFavorite(server),
                        isOnline: provider.isOnline(server),
                        maxSpeed: maxSpeed,
                        onTap: () => _selectAndConnect(provider, server),
                        onFavoriteTap: () =>
                            provider.toggleFavorite(server),
                      );
                    },
                    childCount: servers.length,
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          );
        },
      ),
    );
  }

  void _selectAndConnect(VpnProvider provider, VpnServer server) {
    provider.switchServer(server);
    Navigator.of(context).pop();
  }

  List<VpnServer> _filteredServers(List<VpnServer> servers) {
    if (_searchQuery.isEmpty) return servers;
    final query = _searchQuery.toLowerCase();
    return servers
        .where((s) =>
            s.countryLong.toLowerCase().contains(query) ||
            s.countryShort.toLowerCase().contains(query) ||
            s.hostName.toLowerCase().contains(query))
        .toList();
  }
}

class _QuickConnectCard extends StatelessWidget {
  final VpnServer server;
  final VoidCallback onTap;

  const _QuickConnectCard({required this.server, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Connect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Fastest server • ${server.flagEmoji} ${server.countryLong} • ${server.speedMbps}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
