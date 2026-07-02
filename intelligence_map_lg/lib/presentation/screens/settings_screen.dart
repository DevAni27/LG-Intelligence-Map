import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/global_event.dart';
import '../../data/repositories/event_repository.dart';
import '../../logic/blocs/events/events_bloc.dart';
import '../../logic/blocs/events/events_event.dart';
import '../../logic/blocs/events/events_state.dart';
import '../../services/ssh_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController(text: 'lg');
  final _passwordController = TextEditingController(text: 'lg');
  int _numberOfRigs = 3;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final box = Hive.box(AppConstants.settingsBox);
    _ipController.text = box.get(AppConstants.keySSHHost, defaultValue: '');
    _portController.text =
        box.get(AppConstants.keySSHPort, defaultValue: '22');
    _usernameController.text =
        box.get(AppConstants.keySSHUser, defaultValue: 'lg');
    _passwordController.text =
        box.get(AppConstants.keySSHPassword, defaultValue: 'lg');
    _numberOfRigs =
        box.get(AppConstants.keyNumberOfRigs, defaultValue: 3);
  }

  Future<void> _saveSettings() async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(AppConstants.keySSHHost, _ipController.text);
    await box.put(AppConstants.keySSHPort, _portController.text);
    await box.put(AppConstants.keySSHUser, _usernameController.text);
    await box.put(AppConstants.keySSHPassword, _passwordController.text);
    await box.put(AppConstants.keyNumberOfRigs, _numberOfRigs);
  }

  Future<void> _connect() async {
    if (_ipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an IP address.')),
      );
      return;
    }

    setState(() => _isConnecting = true);
    await _saveSettings();

    final ssh = context.read<SSHService>();
    final success = await ssh.connect(
      host: _ipController.text,
      port: int.tryParse(_portController.text) ?? 22,
      username: _usernameController.text,
      password: _passwordController.text,
      numberOfRigs: _numberOfRigs,
    );

    setState(() => _isConnecting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connected to LG rig!'
                : 'Failed to connect. Check credentials.',
          ),
          backgroundColor:
              success ? AppTheme.statusConnected : AppTheme.severityCritical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ssh = context.read<SSHService>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Configure Liquid Galaxy & AI',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // ── LG Connection ─────────────────────────────
          _buildSectionHeader(
            context,
            icon: Icons.wifi_tethering,
            title: 'Liquid Galaxy Connection',
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status'),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: ssh.isConnected
                                ? AppTheme.statusConnected
                                : AppTheme.statusDisconnected,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ssh.isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: ssh.isConnected
                                ? AppTheme.statusConnected
                                : AppTheme.statusDisconnected,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    hintText: 'IP Address',
                    prefixIcon: Icon(Icons.computer, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _portController,
                        decoration: const InputDecoration(hintText: 'Port'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(hintText: 'Username'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(hintText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Number of Rigs'),
                    DropdownButton<int>(
                      value: _numberOfRigs,
                      dropdownColor: AppTheme.surfaceLight,
                      items: List.generate(
                        5,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _numberOfRigs = value ?? 3);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : _connect,
                    child: _isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Connect'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Data Sources ──────────────────────────────
          _buildSectionHeader(
            context,
            icon: Icons.storage_outlined,
            title: 'Data Sources',
          ),
          const SizedBox(height: 12),
          BlocBuilder<EventsBloc, EventsState>(
            builder: (context, state) {
              return _buildCard(
                child: Column(
                  children: [
                    _buildSourceToggle(context, state, EventSource.usgs, 'USGS'),
                    _buildSourceToggle(
                        context, state, EventSource.nasaEonet, 'NASA EONET'),
                    _buildSourceToggle(context, state, EventSource.who, 'WHO'),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── API Status ────────────────────────────────
          _buildSectionHeader(
            context,
            icon: Icons.monitor_heart_outlined,
            title: 'API Status',
          ),
          const SizedBox(height: 12),
          BlocBuilder<EventsBloc, EventsState>(
            builder: (context, state) {
              return _buildCard(
                child: Column(
                  children: state.sourceResults.entries.map((entry) {
                    return _buildApiStatusRow(entry.key, entry.value);
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── LG Quick Commands ─────────────────────────
          _buildSectionHeader(
            context,
            icon: Icons.power_settings_new,
            title: 'LG Quick Commands',
          ),
          const SizedBox(height: 12),
          _buildCard(
            child: Column(
              children: [
                _buildCommandRow(
                  context,
                  'Clear KML',
                  Icons.layers_clear,
                  () => _confirmAction(
                    context,
                    'Clear all KML overlays from the LG rig?',
                    () => ssh.clearKML(),
                  ),
                ),
                const Divider(height: 1),
                _buildCommandRow(
                  context,
                  'Clear Logo',
                  Icons.image_not_supported_outlined,
                  () => ssh.clearLogo(),
                ),
                const Divider(height: 1),
                _buildCommandRow(
                  context,
                  'Refresh',
                  Icons.refresh,
                  () => ssh.refresh(),
                ),
                const Divider(height: 1),
                _buildCommandRow(
                  context,
                  'Reboot',
                  Icons.restart_alt,
                  () => _confirmAction(
                    context,
                    'Reboot all LG rigs? This will take a few minutes.',
                    () => ssh.reboot(),
                  ),
                ),
                const Divider(height: 1),
                _buildCommandRow(
                  context,
                  'Shutdown',
                  Icons.power_settings_new,
                  () => _confirmAction(
                    context,
                    'Shutdown all LG rigs? This cannot be undone remotely.',
                    () => ssh.shutdown(),
                  ),
                  isDestructive: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _buildSourceToggle(
    BuildContext context,
    EventsState state,
    EventSource source,
    String label,
  ) {
    final enabled = state.enabledSources.contains(source);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Switch(
            value: enabled,
            onChanged: (value) {
              context.read<EventsBloc>().add(
                    ToggleSource(source: source, enabled: value),
                  );
            },
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildApiStatusRow(EventSource source, SourceResult result) {
    final statusColor = switch (result.status) {
      SourceStatus.loaded => AppTheme.statusConnected,
      SourceStatus.loading => AppTheme.statusLoading,
      SourceStatus.error => AppTheme.statusDisconnected,
      SourceStatus.idle => AppTheme.textTertiary,
    };

    final statusText = switch (result.status) {
      SourceStatus.loaded =>
        '${result.events.length} events · ${_formatTime(result.lastUpdated)}',
      SourceStatus.loading => 'Loading...',
      SourceStatus.error => result.errorMessage ?? 'Error',
      SourceStatus.idle => 'Idle',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(source.label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandRow(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.severityCritical : AppTheme.textSecondary,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? AppTheme.severityCritical : AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
      onTap: onTap,
    );
  }

  void _confirmAction(
    BuildContext context,
    String message,
    Future<bool> Function() action,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              action();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.severityCritical,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
