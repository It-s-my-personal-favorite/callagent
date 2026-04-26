import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101E42) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isDark ? const Color(0xFFA5B9EA) : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isLive = status == 'live' ||
        status == 'queued' ||
        status == 'ringing' ||
        status == 'in-progress';
    return Chip(
      label: Text(isLive ? 'Live' : 'Beendet'),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      backgroundColor: isLive ? const Color(0xFF8D2C6B) : const Color(0xFF2C6E52),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class LatencyBadge extends StatelessWidget {
  const LatencyBadge({super.key, required this.ms});

  final int ms;

  @override
  Widget build(BuildContext context) {
    final color = ms < 1000
        ? const Color(0xFF2C6E52)
        : ms < 2000
            ? const Color(0xFF846322)
            : const Color(0xFF8F3A3A);
    return Chip(
      label: Text('$ms ms'),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      backgroundColor: color,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({
    super.key,
    required this.connected,
    required this.checking,
  });

  final bool connected;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Chip(
        avatar: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text('Verbindung wird geprüft...'),
      );
    }
    return Chip(
      avatar: Icon(
        connected ? Icons.check_circle : Icons.error_outline,
        color: connected ? Colors.green.shade700 : Colors.red.shade700,
      ),
      backgroundColor: connected ? Colors.green.shade100 : Colors.red.shade100,
      label: Text(connected ? 'Verbunden' : 'Nicht verbunden'),
    );
  }
}

class EnvField extends StatelessWidget {
  const EnvField({
    super.key,
    required this.envName,
    this.label,
    required this.controller,
    required this.validator,
    this.obscureText = false,
  });

  final String envName;
  final String? label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label ?? envName,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
