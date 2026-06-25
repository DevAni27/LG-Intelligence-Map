import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ssh_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the LG connection status.
/// Rebuilds every 2 seconds to reflect connection changes.
class ConnectionStatus extends StatefulWidget {
  const ConnectionStatus({super.key});

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isConnected
                ? AppTheme.statusConnected
                : AppTheme.statusDisconnected,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isConnected
                        ? AppTheme.statusConnected
                        : AppTheme.statusDisconnected)
                    .withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _isConnected ? 'LG Connected' : 'LG Disconnected',
          style: TextStyle(
            color: _isConnected
                ? AppTheme.statusConnected
                : AppTheme.statusDisconnected,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}