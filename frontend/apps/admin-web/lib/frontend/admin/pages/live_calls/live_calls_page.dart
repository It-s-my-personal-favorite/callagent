import 'package:flutter/material.dart';

import '../../../../domain/admin_models.dart';
import '../../widgets/admin_common_widgets.dart';
import '../../widgets/call_detail_panel.dart';

class LiveCallsPage extends StatefulWidget {
  const LiveCallsPage({
    super.key,
    required this.calls,
    required this.selectedCallId,
    required this.onSelectCall,
    required this.selectedCall,
    required this.onToggleBlock,
    required this.onSaveReview,
    required this.onToggleArchived,
    required this.onToggleImportant,
    required this.onToggleWarning,
    required this.onToggleForward,
    required this.onAddCallNote,
    required this.onDeleteCallNote,
    required this.onOpenCustomerPage,
  });

  final List<CallSession> calls;
  final String? selectedCallId;
  final ValueChanged<String> onSelectCall;
  final CallSession? selectedCall;
  final ValueChanged<bool> onToggleBlock;
  final void Function(bool helpful, int score, String note) onSaveReview;
  final VoidCallback onToggleArchived;
  final VoidCallback onToggleImportant;
  final VoidCallback onToggleWarning;
  final VoidCallback onToggleForward;
  final ValueChanged<String> onAddCallNote;
  final ValueChanged<String> onDeleteCallNote;
  final ValueChanged<CallSession> onOpenCustomerPage;

  @override
  State<LiveCallsPage> createState() => _LiveCallsPageState();
}

class _LiveCallsPageState extends State<LiveCallsPage> {
  bool _showArchivedCalls = false;
  String _sortBy = 'newest';

  bool _isCurrentlyActiveCall(CallSession call) {
    final status = call.status.toLowerCase();
    final isLiveState = status == 'live' || status == 'in-progress';
    return isLiveState && call.endedAt == null;
  }

  bool _isEndedCall(CallSession call) {
    final status = call.status.toLowerCase();
    if (status == 'completed' || status == 'ended' || status == 'archived') {
      return true;
    }
    return call.endedAt != null && !_isCurrentlyActiveCall(call);
  }

  bool _isArchivedCall(CallSession call) =>
      call.status.toLowerCase() == 'archived';

  List<CallSession> get _displayCalls {
    final list = widget.calls.where(_isEndedCall).where((call) {
      if (_showArchivedCalls) return _isArchivedCall(call);
      return !_isArchivedCall(call);
    }).toList();
    list.sort((a, b) {
      switch (_sortBy) {
        case 'oldest':
          return a.startedAt.compareTo(b.startedAt);
        case 'longest':
          return b.durationSec.compareTo(a.durationSec);
        case 'newest':
        default:
          return b.startedAt.compareTo(a.startedAt);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return _CallOverviewLayout(
      calls: _displayCalls,
      selectedCallId: widget.selectedCallId,
      onSelectCall: widget.onSelectCall,
      selectedCall: widget.selectedCall,
      onToggleBlock: widget.onToggleBlock,
      onSaveReview: widget.onSaveReview,
      onToggleArchived: widget.onToggleArchived,
      onToggleImportant: widget.onToggleImportant,
      onToggleWarning: widget.onToggleWarning,
      onToggleForward: widget.onToggleForward,
      onAddCallNote: widget.onAddCallNote,
      onDeleteCallNote: widget.onDeleteCallNote,
      onOpenCustomerPage: widget.onOpenCustomerPage,
      topToolbar: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _toolbarActionButton(
            context: context,
            label: _showArchivedCalls
                ? 'Archivierte Anrufe ausgeblendet'
                : 'Archivierte Anrufe anzeigen',
            icon: _showArchivedCalls ? Icons.archive : Icons.archive_outlined,
            isActive: _showArchivedCalls,
            onTap: () =>
                setState(() => _showArchivedCalls = !_showArchivedCalls),
          ),
          _sortDropdown(context),
        ],
      ),
    );
  }

  Widget _toolbarActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(
          color: isActive
              ? const Color(0xFF8D63FF)
              : (isDark ? const Color(0xFF29417A) : const Color(0xFF4A5F95)),
        ),
        backgroundColor: isActive
            ? (isDark ? const Color(0xFF2E1B66) : const Color(0xFFEAE2FF))
            : (isDark ? const Color(0xFF0E1E47) : Colors.white),
        foregroundColor:
            isDark ? const Color(0xFFD8E4FF) : const Color(0xFF142246),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _sortDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFD8E4FF) : const Color(0xFF142246);
    return Container(
      width: 220,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1E47) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF29417A) : const Color(0xFF4A5F95),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Sortierung',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              dropdownColor: isDark ? const Color(0xFF102247) : Colors.white,
              style: TextStyle(color: textColor, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Neueste')),
                DropdownMenuItem(value: 'oldest', child: Text('Älteste')),
                DropdownMenuItem(value: 'longest', child: Text('Längste')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sortBy = value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CallOverviewLayout extends StatelessWidget {
  const _CallOverviewLayout({
    super.key,
    required this.calls,
    required this.selectedCallId,
    required this.onSelectCall,
    required this.selectedCall,
    required this.onToggleBlock,
    required this.onSaveReview,
    required this.onToggleArchived,
    required this.onToggleImportant,
    required this.onToggleWarning,
    required this.onToggleForward,
    required this.onAddCallNote,
    required this.onDeleteCallNote,
    required this.onOpenCustomerPage,
    this.topToolbar,
    this.emptySelectionText = 'Kein Anruf ausgewählt',
  });

  final List<CallSession> calls;
  final String? selectedCallId;
  final ValueChanged<String> onSelectCall;
  final CallSession? selectedCall;
  final ValueChanged<bool> onToggleBlock;
  final void Function(bool helpful, int score, String note) onSaveReview;
  final VoidCallback onToggleArchived;
  final VoidCallback onToggleImportant;
  final VoidCallback onToggleWarning;
  final VoidCallback onToggleForward;
  final ValueChanged<String> onAddCallNote;
  final ValueChanged<String> onDeleteCallNote;
  final ValueChanged<CallSession> onOpenCustomerPage;
  final Widget? topToolbar;
  final String emptySelectionText;

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateTime(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    final time = _formatTime(value);
    return '$d.$m.$y $time';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyCalls = List<CallSession>.from(calls);
    return AdminPageContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 1180;
          final leftMinWidth = stacked ? constraints.maxWidth : 320.0;
          final rightMinWidth = stacked ? constraints.maxWidth : 620.0;
          final leftPanel = ConstrainedBox(
            constraints: BoxConstraints(minWidth: leftMinWidth, minHeight: 240),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0D1C43) : const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1B2E5D)
                      : const Color(0xFFD8E2FB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (topToolbar != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: topToolbar!,
                    ),
                  Text(
                    'Anrufshistorie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color:
                              isDark ? Colors.white : const Color(0xFF142246),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: historyCalls.isEmpty
                        ? Center(
                            child: Text(
                              'Noch keine beendeten Anrufe vorhanden',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF9AB0E8)
                                    : const Color(0xFF6A79A7),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: historyCalls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final call = historyCalls[index];
                              final isSelected = call.id == selectedCallId;
                              return InkWell(
                                onTap: () => onSelectCall(call.id),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark
                                            ? const Color(0xFF311A67)
                                            : const Color(0xFFEAE2FF))
                                        : (isDark
                                            ? const Color(0xFF101E44)
                                            : const Color(0xFFF7F9FF)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF8D63FF)
                                          : (isDark
                                              ? const Color(0xFF29417A)
                                              : const Color(0xFFD8E2FB)),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (call.marked)
                                            Container(
                                              width: 4,
                                              margin: const EdgeInsets.only(
                                                  right: 8, top: 2, bottom: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF9800),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              call.callerNumber,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF142246),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (call.important)
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(right: 6),
                                              child: Icon(Icons.star,
                                                  color: Color(0xFFFFC107),
                                                  size: 18),
                                            ),
                                          Text(
                                            _formatTime(call.startedAt),
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFF9AB0E8)
                                                  : const Color(0xFF6A79A7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          StatusBadge(status: call.status, endedAt: call.endedAt),
                                          const SizedBox(width: 6),
                                          LatencyBadge(
                                              ms: call.metrics.avgLatencyMs),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _MetaPill(
                                            icon: Icons.schedule,
                                            label:
                                                'Am ${_formatDateTime(call.startedAt)}',
                                            isDark: isDark,
                                          ),
                                          _MetaPill(
                                            icon: Icons.support_agent,
                                            label: call.assistantId,
                                            isDark: isDark,
                                          ),
                                          _MetaPill(
                                            icon: Icons.token,
                                            label:
                                                '${call.metrics.tokenTotal} Tokens',
                                            isDark: isDark,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
          final rightPanel = ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: rightMinWidth, minHeight: 300),
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0D1C43) : const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: selectedCall == null
                  ? Center(child: Text(emptySelectionText))
                  : CallDetailPanel(
                      call: selectedCall!,
                      onToggleBlock: onToggleBlock,
                      onSaveReview: onSaveReview,
                      onToggleArchived: onToggleArchived,
                      onToggleImportant: onToggleImportant,
                      onToggleWarning: onToggleWarning,
                      onToggleForward: onToggleForward,
                      onAddCallNote: onAddCallNote,
                      onDeleteCallNote: onDeleteCallNote,
                      onOpenCustomerPage: () =>
                          onOpenCustomerPage(selectedCall!),
                    ),
            ),
          );
          if (stacked) {
            return Column(
              children: [
                Expanded(flex: 3, child: leftPanel),
                Expanded(flex: 5, child: rightPanel),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 2, child: leftPanel),
              Expanded(flex: 5, child: rightPanel),
            ],
          );
        },
      ),
    );
  }
}

class CallOverviewLayout extends _CallOverviewLayout {
  const CallOverviewLayout({
    super.key,
    required super.calls,
    required super.selectedCallId,
    required super.onSelectCall,
    required super.selectedCall,
    required super.onToggleBlock,
    required super.onSaveReview,
    required super.onToggleArchived,
    required super.onToggleImportant,
    required super.onToggleWarning,
    required super.onToggleForward,
    required super.onAddCallNote,
    required super.onDeleteCallNote,
    required super.onOpenCustomerPage,
    super.topToolbar,
    super.emptySelectionText,
  });
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12264F) : const Color(0xFFECF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? const Color(0xFFB5C8FF) : const Color(0xFF3B5DA1),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFFDBE6FF) : const Color(0xFF2D457A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
