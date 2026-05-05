import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/models/enums.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final isError = status == ConnectionStatus.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isError
          ? Colors.red.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.wifi_off,
            size: 16,
            color: isError ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isError
                  ? 'Connection error. Check your server.'
                  : 'Disconnected from server.',
              style: TextStyle(
                fontSize: 13,
                color: isError ? Colors.red : Colors.orange[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.push(AppRoutes.servers);
            },
            child: Text(
              'Configure',
              style: TextStyle(
                fontSize: 13,
                color: isError ? Colors.red : Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
