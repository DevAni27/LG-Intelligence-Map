import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ssh_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the LG connection status.
/// Rebuilds every 2 seconds to reflect connection changes.
class ConnectionStatus extends StatefulWidget {
  final VoidCallback? onGoToSettings;
  const ConnectionStatus({super.key, this.onGoToSettings});

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus> {
  late bool _isConnected;

  @override
  void initState() {
    super.initState();
    _isConnected = false;
    _pollStatus();
  }

  void _pollStatus() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final ssh = context.read<SSHService>();
      if (ssh.isConnected != _isConnected) {
        setState(() => _isConnected = ssh.isConnected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ssh = context.watch<SSHService>();
    final isConnected = ssh.isConnected;

    return GestureDetector(
      onTap: isConnected ? null : widget.onGoToSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status dot + label row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF22C55E)
                      : AppTheme.severityCritical,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'LG Connected' : 'LG Disconnected',
                style: TextStyle(
                  color: isConnected
                      ? const Color(0xFF22C55E)
                      : AppTheme.severityCritical,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Subtitle — only show when disconnected
          if (!isConnected)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Tap to connect',
                style: TextStyle(
                  color: AppTheme.severityCritical.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
            ),
        ],
      ),
    );
  }
}
