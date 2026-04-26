import 'package:flutter/material.dart';

import '../../widgets/admin_common_widgets.dart';

class ApiControlPage extends StatefulWidget {
  const ApiControlPage({
    super.key,
    required this.serverStatus,
    required this.sourceStatus,
    required this.healthOk,
    required this.loading,
    required this.onRefresh,
  });

  final Map<String, dynamic> serverStatus;
  final Map<String, dynamic> sourceStatus;
  final bool? healthOk;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  State<ApiControlPage> createState() => _ApiControlPageState();
}

class _ApiControlPageState extends State<ApiControlPage> {
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _startAutoRefreshLoop();
  }

  void _startAutoRefreshLoop() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 5));
      if (!mounted || !_autoRefresh || widget.loading) continue;
      await widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final callagentStatus =
        (widget.serverStatus['callagentPython'] as Map<String, dynamic>?) ??
            const {};
    final snapshot =
        (widget.serverStatus['snapshot'] as Map<String, dynamic>?) ?? const {};
    final db = (snapshot['db'] as Map<String, dynamic>?) ?? const {};
    final calls = (snapshot['calls'] as Map<String, dynamic>?) ?? const {};
    final voiceCfg =
        (snapshot['voiceConfig'] as Map<String, dynamic>?) ?? const {};
    final callagentRunning = callagentStatus['running'] == true;
    final callagentConfigured = callagentStatus['configured'] == true;
    final dbConnected = db['connected'] == true;
    final telephonyCfgOk = voiceCfg['twilioSidSet'] == true &&
        voiceCfg['twilioAuthTokenSet'] == true &&
        voiceCfg['twilioPhoneSet'] == true;

    return AdminPageContainer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Spacer(),
              Switch(
                value: _autoRefresh,
                onChanged: (v) => setState(() => _autoRefresh = v),
              ),
              const SizedBox(width: 4),
              const Text('Auto-Refresh (5s)'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Live-Monitoring für Root-Backend, callagent_python, Datenbank und Voice-Konfiguration.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          _kv('Snapshot', '${snapshot['updatedAt'] ?? '-'}'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _chip(
                label: 'Server',
                value: (widget.serverStatus['running'] == true)
                    ? 'Live'
                    : 'Offline',
                color: (widget.serverStatus['running'] == true)
                    ? Colors.green
                    : Colors.red,
              ),
              _chip(
                label: 'Datenbank',
                value: dbConnected ? 'Verbunden' : 'Fehler',
                color: dbConnected ? Colors.green : Colors.red,
              ),
              _chip(
                label: 'Callagent Python',
                value: !callagentConfigured
                    ? 'Nicht konfiguriert'
                    : (callagentRunning ? 'Live' : 'Offline'),
                color: !callagentConfigured
                    ? Colors.grey
                    : (callagentRunning ? Colors.green : Colors.red),
              ),
              _chip(
                label: 'Health',
                value: widget.healthOk == null
                    ? 'Unbekannt'
                    : (widget.healthOk! ? 'Healthy' : 'Fehler'),
                color: widget.healthOk == true ? Colors.green : Colors.orange,
              ),
              _chip(
                label: 'Telefonie Source',
                value: (widget.sourceStatus['enabled'] == true)
                    ? 'Aktiv'
                    : 'Inaktiv',
                color: (widget.sourceStatus['enabled'] == true)
                    ? Colors.green
                    : Colors.orange,
              ),
              _chip(
                label: 'Telefonie Konfig',
                value: telephonyCfgOk ? 'Vollständig' : 'Unvollständig',
                color: telephonyCfgOk ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _kv('Server PID', '${widget.serverStatus['pid'] ?? '-'}'),
          _kv('Uptime (s)', '${widget.serverStatus['uptimeSec'] ?? '-'}'),
          _kv('CallRecords gesamt', '${calls['totalFromCallRecords'] ?? '-'}'),
          _kv('Live Calls', '${calls['liveCount'] ?? '-'}'),
          _kv('History Calls', '${calls['historyCount'] ?? '-'}'),
          _kv('Letzter Call Start', '${calls['latestStartedAt'] ?? '-'}'),
          _kv('Callagent URL', '${callagentStatus['url'] ?? '-'}'),
          _kv('Callagent Health',
              '${callagentStatus['healthEndpoint'] ?? '-'}'),
          _kv('Callagent Detail', '${callagentStatus['detail'] ?? '-'}'),
          _kv('Voice localServerUrl', '${voiceCfg['localServerUrl'] ?? '-'}'),
          _kv('Telefonie SID gesetzt', '${voiceCfg['twilioSidSet'] ?? false}'),
          _kv('Telefonie Token gesetzt',
              '${voiceCfg['twilioAuthTokenSet'] ?? false}'),
          _kv('Telefonie Nummer gesetzt',
              '${voiceCfg['twilioPhoneSet'] ?? false}'),
          _kv('Deepgram Key gesetzt', '${voiceCfg['deepgramKeySet'] ?? false}'),
          _kv('Telefonie SID Hinweis', '${voiceCfg['twilioSidHint'] ?? '-'}'),
          _kv('Letzter Sync', '${widget.sourceStatus['lastSyncAt'] ?? '-'}'),
          _kv('Letzter Fehler', '${widget.sourceStatus['lastError'] ?? '-'}'),
          _kv('Gefetchte Calls',
              '${widget.sourceStatus['lastFetchedCount'] ?? '-'}'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.loading ? null : widget.onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Status aktualisieren'),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),
          Text('Hinweis', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            'Keine Eingabe von API-Keys und keine Start/Stop-Aktionen mehr auf dieser Seite.\n'
            'Diese Seite ist rein für Live-Status und Read-Only-Monitoring.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(key,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _chip(
      {required String label, required String value, required Color color}) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }
}
