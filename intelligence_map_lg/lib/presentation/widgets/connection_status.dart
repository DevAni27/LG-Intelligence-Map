import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ssh_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the LG connection status as a colored dot with label.
/// Green = connected, Red = disconnected.
class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    // Access SSH service from the repository provider
    final sshService = context.read<SSHService>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: sshService.isConnected
                ? AppTheme.statusConnected
                : AppTheme.statusDisconnected,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (sshService.isConnected
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
          sshService.isConnected ? 'LG Connected' : 'LG Disconnected',
          style: TextStyle(
            color: sshService.isConnected
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
