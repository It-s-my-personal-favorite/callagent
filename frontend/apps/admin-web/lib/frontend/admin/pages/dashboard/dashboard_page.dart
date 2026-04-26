import 'package:flutter/material.dart';

import '../../../../domain/admin_models.dart';
import '../../widgets/admin_common_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.liveCalls,
    required this.endedCalls,
    required this.blockedCalls,
    required this.totalTokens,
    required this.avgLatency,
    required this.avgFeedback,
    required this.calls,
    required this.themeMode,
    required this.onRefresh,
    required this.onToggleThemeMode,
    required this.onOpenLiveCalls,
    required this.onOpenHistory,
    required this.onOpenModeration,
    required this.onOpenVoiceApi,
    required this.onOpenApiControl,
    required this.onOpenLiveCallById,
    required this.onOpenHistoryCallById,
  });

  final int liveCalls;
  final int endedCalls;
  final int blockedCalls;
  final int totalTokens;
  final int avgLatency;
  final double avgFeedback;
  final List<CallSession> calls;
  final ThemeMode themeMode;
  final VoidCallback onRefresh;
  final VoidCallback onToggleThemeMode;
  final VoidCallback onOpenLiveCalls;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenModeration;
  final VoidCallback onOpenVoiceApi;
  final VoidCallback onOpenApiControl;
  final ValueChanged<String> onOpenLiveCallById;
  final ValueChanged<String> onOpenHistoryCallById;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showOnlyImportant = false;

  bool _isCurrentlyActiveCall(CallSession call) {
    final status = call.status.toLowerCase();
    final isLiveState = status == 'live' || status == 'in-progress';
    return isLiveState && call.endedAt == null;
  }

  bool _isEndedCall(CallSession call) {
    final status = call.status.toLowerCase();
    if (status == 'completed' || status == 'ended') return true;
    return call.endedAt != null && !_isCurrentlyActiveCall(call);
  }

  List<CallSession> get _liveItems =>
      widget.calls.where(_isCurrentlyActiveCall).toList();

  List<CallSession> get _historyItems =>
      widget.calls.where(_isEndedCall).toList();

  String _formatDuration(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _automationScore {
    if (widget.calls.isEmpty) return 0;
    final ratio = widget.endedCalls / widget.calls.length;
    final latencyScore = (3000 - widget.avgLatency).clamp(500, 3000) / 3000;
    return ((ratio * 0.6) + (latencyScore * 0.4)) * 100;
  }

  int get _escalations => widget.calls
      .where((c) => c.warningActive || c.blocked || c.isForwarded)
      .length;

  int get _highValueCalls =>
      widget.calls.where((c) => c.important || c.marked).length;

  int get _averageTokensPerCall =>
      widget.calls.isEmpty ? 0 : widget.totalTokens ~/ widget.calls.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF13213F);
    final subtitleColor =
        isDark ? const Color(0xFFAEC0F7) : const Color(0xFF4E628F);
    final topHistory = _historyItems.take(5).toList();
    final topLive = _liveItems.take(5).toList();

    return AdminPageContainer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                MetricCard(title: 'Anrufe', value: '${widget.calls.length}'),
                MetricCard(
                    title: 'Beendete Anrufe', value: '${widget.endedCalls}'),
                MetricCard(
                    title: 'Blockierte Nummern',
                    value: '${widget.blockedCalls}'),
                MetricCard(
                    title: 'Gesamte Tokens', value: '${widget.totalTokens}'),
                MetricCard(title: 'Ø Latenz', value: '${widget.avgLatency} ms'),
                MetricCard(
                  title: 'Ø Nutzer-Feedback',
                  value: widget.avgFeedback.toStringAsFixed(1),
                ),
                MetricCard(
                    title: 'Ø Tokens / Call', value: '$_averageTokensPerCall'),
                MetricCard(title: 'Eskalationen', value: '$_escalations'),
              ],
            ),
            const SizedBox(height: 14),
            _EnterpriseOverviewPanel(
              isDark: isDark,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              automationScore: _automationScore,
              escalations: _escalations,
              highValueCalls: _highValueCalls,
              liveCalls: widget.liveCalls,
              endedCalls: widget.endedCalls,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 1260;
                final livePane = _LiveCallsPreview(
                  isDark: isDark,
                  calls: topLive,
                  onlyImportant: _showOnlyImportant,
                  onToggleImportantFilter: () =>
                      setState(() => _showOnlyImportant = !_showOnlyImportant),
                  onOpenCall: widget.onOpenLiveCallById,
                  onOpenAll: widget.onOpenLiveCalls,
                  formatDuration: _formatDuration,
                );
                final historyPane = _HistoryPreview(
                  isDark: isDark,
                  calls: topHistory,
                  onOpenCall: widget.onOpenHistoryCallById,
                  onOpenAll: widget.onOpenHistory,
                  formatDuration: _formatDuration,
                );
                if (stacked) {
                  return Column(
                    children: [
                      livePane,
                      const SizedBox(height: 10),
                      historyPane,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: livePane),
                    const SizedBox(width: 10),
                    Expanded(child: historyPane),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            _InfoBanner(
              isDark: isDark,
              text:
                  'Live-Ansicht aktiv: Es werden ausschließlich echte Backend-Daten verwendet.',
            ),
          ],
        ),
      ),
    );
  }
}

class _EnterpriseOverviewPanel extends StatelessWidget {
  const _EnterpriseOverviewPanel({
    required this.isDark,
    required this.titleColor,
    required this.subtitleColor,
    required this.automationScore,
    required this.escalations,
    required this.highValueCalls,
    required this.liveCalls,
    required this.endedCalls,
  });

  final bool isDark;
  final Color titleColor;
  final Color subtitleColor;
  final double automationScore;
  final int escalations;
  final int highValueCalls;
  final int liveCalls;
  final int endedCalls;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Cockpit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Automatisierung, Qualitätslage und operative Last in einem Blick.',
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ScoreTile(
                  isDark: isDark,
                  title: 'Automation Score',
                  value: '${automationScore.toStringAsFixed(1)}%',
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScoreTile(
                  isDark: isDark,
                  title: 'Eskalationen',
                  value: '$escalations',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScoreTile(
                  isDark: isDark,
                  title: 'High-Value Calls',
                  value: '$highValueCalls',
                  icon: Icons.stars_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LoadBar(
            isDark: isDark,
            title: 'Auslastung Live-Team',
            value: (liveCalls / (liveCalls + endedCalls + 1)).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 10),
          _LoadBar(
            isDark: isDark,
            title: 'Abschlussquote',
            value: endedCalls == 0
                ? 0
                : (endedCalls / (liveCalls + endedCalls)).clamp(0.0, 1.0),
          ),
        ],
      ),
    );
  }
}

class _LiveCallsPreview extends StatelessWidget {
  const _LiveCallsPreview({
    required this.isDark,
    required this.calls,
    required this.onlyImportant,
    required this.onToggleImportantFilter,
    required this.onOpenCall,
    required this.onOpenAll,
    required this.formatDuration,
  });

  final bool isDark;
  final List<CallSession> calls;
  final bool onlyImportant;
  final VoidCallback onToggleImportantFilter;
  final ValueChanged<String> onOpenCall;
  final VoidCallback onOpenAll;
  final String Function(int) formatDuration;

  @override
  Widget build(BuildContext context) {
    final filtered = onlyImportant
        ? calls.where((c) => c.important || c.marked).toList()
        : calls;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Live Feed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF1A2A4D),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onToggleImportantFilter,
                icon: Icon(
                    onlyImportant ? Icons.filter_alt_off : Icons.filter_alt),
                label: Text(onlyImportant ? 'Alle' : 'Wichtige'),
              ),
              const SizedBox(width: 6),
              FilledButton.tonal(
                  onPressed: onOpenAll, child: const Text('Alle öffnen')),
            ],
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const ListTile(
              dense: true,
              leading: Icon(Icons.info_outline),
              title: Text('Keine passenden Anrufe'),
            )
          else
            ...filtered.map(
              (call) => _CallListItem(
                isDark: isDark,
                title: call.callerNumber,
                subtitle:
                    '${call.assistantId} • Dauer ${formatDuration(call.durationSec)}',
                highlighted: call.important || call.marked,
                latency: call.metrics.avgLatencyMs,
                onTap: () => onOpenCall(call.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryPreview extends StatelessWidget {
  const _HistoryPreview({
    required this.isDark,
    required this.calls,
    required this.onOpenCall,
    required this.onOpenAll,
    required this.formatDuration,
  });

  final bool isDark;
  final List<CallSession> calls;
  final ValueChanged<String> onOpenCall;
  final VoidCallback onOpenAll;
  final String Function(int) formatDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF1A2A4D),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              FilledButton.tonal(
                  onPressed: onOpenAll, child: const Text('Zur Historie')),
            ],
          ),
          const SizedBox(height: 10),
          if (calls.isEmpty)
            const ListTile(
              dense: true,
              leading: Icon(Icons.info_outline),
              title: Text('Noch keine beendeten Calls vorhanden'),
            )
          else
            ...calls.map(
              (call) => _CallListItem(
                isDark: isDark,
                title: call.callerNumber,
                subtitle:
                    'Feedback ${call.userFeedback.rating}/5 • ${formatDuration(call.durationSec)}',
                highlighted: call.blocked || call.warningActive,
                latency: call.metrics.avgLatencyMs,
                onTap: () => onOpenCall(call.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CallListItem extends StatelessWidget {
  const _CallListItem({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.highlighted,
    required this.latency,
    required this.onTap,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final bool highlighted;
  final int latency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1A3B) : const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted
                ? const Color(0xFF8D63FF)
                : (isDark ? const Color(0xFF2A3F74) : const Color(0xFFD8E2FB)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              highlighted ? Icons.priority_high_rounded : Icons.call,
              color: highlighted
                  ? const Color(0xFFFFA726)
                  : const Color(0xFF7D94CA),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1B2D53),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFA3B7EC)
                          : const Color(0xFF5870A5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            LatencyBadge(ms: latency),
          ],
        ),
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.isDark,
    required this.title,
    required this.value,
    required this.icon,
  });

  final bool isDark;
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1A3B) : const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F74) : const Color(0xFFD8E2FB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7E9CFF), size: 16),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A2A4D),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFA3B7EC) : const Color(0xFF5870A5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadBar extends StatelessWidget {
  const _LoadBar({
    required this.isDark,
    required this.title,
    required this.value,
  });

  final bool isDark;
  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFD2E0FF)
                      : const Color(0xFF2B426F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFB7CCFF) : const Color(0xFF4F6699),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 9,
            backgroundColor:
                isDark ? const Color(0xFF122650) : const Color(0xFFE4ECFF),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.isDark,
    required this.text,
  });

  final bool isDark;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1A3C) : const Color(0xFFF2F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF28447C) : const Color(0xFFD6E5FF),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? const Color(0xFF0D1C43) : const Color(0xFFF8FAFF),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: isDark ? const Color(0xFF1D3370) : const Color(0xFFD8E2FB),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
        blurRadius: 14,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
