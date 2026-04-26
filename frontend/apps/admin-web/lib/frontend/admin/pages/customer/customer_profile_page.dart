import 'package:flutter/material.dart';

import '../../../../domain/admin_models.dart';
import '../../widgets/admin_common_widgets.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({
    super.key,
    required this.callerNumber,
    required this.calls,
    required this.initialCallId,
    required this.onAddNote,
    required this.onDeleteNote,
    required this.onReloadCalls,
  });

  final String callerNumber;
  final List<CallSession> calls;
  final String? initialCallId;
  final Future<void> Function(String callId, String note) onAddNote;
  final Future<void> Function(String callId, String noteId) onDeleteNote;
  final Future<List<CallSession>> Function(String callerNumber) onReloadCalls;

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  late TextEditingController _searchController;
  late TextEditingController _newNoteController;
  String? _selectedCallId;
  String _sortBy = 'newest';
  bool _onlyFlagged = false;
  bool _showCallerOnly = false;
  late List<CallSession> _calls;

  List<CallSession> get _sortedCalls {
    final list = List<CallSession>.from(_calls);
    if (_searchController.text.trim().isNotEmpty) {
      final term = _searchController.text.trim().toLowerCase();
      list.retainWhere(
        (c) =>
            c.id.toLowerCase().contains(term) ||
            c.assistantId.toLowerCase().contains(term) ||
            c.status.toLowerCase().contains(term),
      );
    }
    if (_onlyFlagged) {
      list.retainWhere((c) => c.marked || c.important || c.warningActive);
    }
    list.sort((a, b) {
      switch (_sortBy) {
        case 'oldest':
          return a.startedAt.compareTo(b.startedAt);
        case 'duration':
          return b.durationSec.compareTo(a.durationSec);
        case 'latency':
          return b.metrics.avgLatencyMs.compareTo(a.metrics.avgLatencyMs);
        case 'tokens':
          return b.metrics.tokenTotal.compareTo(a.metrics.tokenTotal);
        case 'newest':
        default:
          return b.startedAt.compareTo(a.startedAt);
      }
    });
    return list;
  }

  CallSession? get _selectedCall {
    if (_selectedCallId != null) {
      for (final call in _sortedCalls) {
        if (call.id == _selectedCallId) return call;
      }
      for (final call in _calls) {
        if (call.id == _selectedCallId) return call;
      }
    }
    return _sortedCalls.isNotEmpty ? _sortedCalls.first : null;
  }

  int get _totalTokens =>
      _calls.fold<int>(0, (sum, call) => sum + call.metrics.tokenTotal);

  int get _avgDurationSec {
    if (_calls.isEmpty) return 0;
    final total = _calls.fold<int>(0, (sum, call) => sum + call.durationSec);
    return total ~/ _calls.length;
  }

  int get _avgLatencyMs {
    if (_calls.isEmpty) return 0;
    final total =
        _calls.fold<int>(0, (sum, call) => sum + call.metrics.avgLatencyMs);
    return total ~/ _calls.length;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _newNoteController = TextEditingController();
    _calls = List<CallSession>.from(widget.calls);
    _selectedCallId = widget.initialCallId;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $h:$min';
  }

  String _formatDuration(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _assistantDisplayName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Sprachassistent';
    final lowered = trimmed.toLowerCase();
    if (lowered.contains('twilio') || lowered.contains('llm')) {
      return 'Sprachassistent';
    }
    return trimmed;
  }

  Future<void> _reloadCalls() async {
    final updated = await widget.onReloadCalls(widget.callerNumber);
    if (!mounted) return;
    setState(() {
      _calls = updated;
      if (_selectedCallId == null ||
          _calls.every((c) => c.id != _selectedCallId)) {
        _selectedCallId = _calls.isNotEmpty ? _calls.first.id : null;
      }
    });
  }

  Future<void> _addNoteToSelectedCall() async {
    final selected = _selectedCall;
    final note = _newNoteController.text.trim();
    if (selected == null || note.isEmpty) return;
    await widget.onAddNote(selected.id, note);
    await _reloadCalls();
    _newNoteController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notiz hinzugefügt')),
    );
    setState(() {});
  }

  Future<void> _deleteNoteFromSelectedCall(String noteId) async {
    final selected = _selectedCall;
    if (selected == null) return;
    await widget.onDeleteNote(selected.id, noteId);
    await _reloadCalls();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notiz gelöscht')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedCall;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF020715) : const Color(0xFFF3F6FF),
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: AdminPageContainer(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: Icon(Icons.history),
                        label: Text('Telefonverlauf'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: selected == null
                        ? const Center(
                            child: Text(
                                'Keine Telefonate für diese Nummer vorhanden'),
                          )
                        : _buildCallsTab(selected, isDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kundenansicht ${widget.callerNumber}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF142246),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kompletter Telefonverlauf, Transkript und Notizen zur Nummer',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CB0E6)
                        : const Color(0xFF6073A8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildStats(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDark) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 6,
      children: [
        _statCard('Telefonate', '${_calls.length}', Icons.call, isDark),
        _statCard('Gesamt Tokens', '$_totalTokens', Icons.token, isDark),
        _statCard(
            'Ø Dauer', _formatDuration(_avgDurationSec), Icons.timer, isDark),
        _statCard('Ø Latenz', '$_avgLatencyMs ms', Icons.speed, isDark),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      width: 152,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1D45) : const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF29417A) : const Color(0xFFD8E2FB),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8D63FF)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF132449),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFF9CB0E6)
                        : const Color(0xFF6073A8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsTab(CallSession selected, bool isDark) {
    final notes = List<CallNote>.from(selected.notes)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final transcript = _showCallerOnly
        ? selected.transcript.where((t) => t.role == 'caller').toList()
        : selected.transcript;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1150;
        final listPanel = _buildCallListPanel(isDark, selected);
        final detailPanel =
            _buildCallDetailPanel(isDark, selected, transcript, notes);
        if (stacked) {
          return Column(
            children: [
              SizedBox(height: 260, child: listPanel),
              const Divider(height: 1),
              Expanded(child: detailPanel),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 360, child: listPanel),
            const VerticalDivider(width: 1),
            Expanded(child: detailPanel),
          ],
        );
      },
    );
  }

  Widget _buildCallListPanel(bool isDark, CallSession selected) {
    final calls = _sortedCalls;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Telefonate suchen (ID, Status, Assistant)',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_sortBy),
                  initialValue: _sortBy,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Sortierung',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'newest', child: Text('Neueste zuerst')),
                    DropdownMenuItem(
                        value: 'oldest', child: Text('Älteste zuerst')),
                    DropdownMenuItem(
                        value: 'duration',
                        child: Text('Dauer hoch -> niedrig')),
                    DropdownMenuItem(
                        value: 'latency',
                        child: Text('Latenz hoch -> niedrig')),
                    DropdownMenuItem(
                        value: 'tokens', child: Text('Tokens hoch -> niedrig')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sortBy = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _onlyFlagged,
                  onChanged: (value) => setState(() => _onlyFlagged = value),
                  title: const Text('Nur markierte',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              itemCount: calls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final call = calls[index];
                final selectedItem = call.id == selected.id;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedCallId = call.id);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selectedItem
                          ? (isDark
                              ? const Color(0xFF2E1B66)
                              : const Color(0xFFEAE2FF))
                          : (isDark
                              ? const Color(0xFF101E44)
                              : const Color(0xFFF7F9FF)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedItem
                            ? const Color(0xFF8D63FF)
                            : (isDark
                                ? const Color(0xFF29417A)
                                : const Color(0xFFD8E2FB)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatDate(call.startedAt),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF132449),
                                ),
                              ),
                            ),
                            StatusBadge(status: call.status, endedAt: call.endedAt),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _metaPill('ID ${call.id}', isDark),
                            _metaPill(
                                'Dauer ${_formatDuration(call.durationSec)}',
                                isDark),
                            _metaPill(
                                'Tokens ${call.metrics.tokenTotal}', isDark),
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
    );
  }

  Widget _buildCallDetailPanel(
    bool isDark,
    CallSession selected,
    List<TranscriptTurn> transcript,
    List<CallNote> notes,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Telefonat ${_formatDate(selected.startedAt)}',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF142246),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: _showCallerOnly,
                onChanged: (value) => setState(() => _showCallerOnly = value),
              ),
              const Text('Nur Anrufer'),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaPill(
                  'Assistent ${_assistantDisplayName(selected.assistantId)}',
                  isDark),
              _metaPill('Latenz ${selected.metrics.avgLatencyMs} ms', isDark),
              _metaPill('Notizen ${selected.notes.length}', isDark),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0B1A3D)
                          : const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1D3468)
                            : const Color(0xFFD8E2FB),
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: transcript.length,
                      itemBuilder: (context, index) {
                        final item = transcript[index];
                        final isCaller = item.role == 'caller';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCaller
                                ? (isDark
                                    ? const Color(0xFF131F42)
                                    : const Color(0xFFF3F6FF))
                                : (isDark
                                    ? const Color(0xFF0E2A4A)
                                    : const Color(0xFFEFF5FF)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF243B73)
                                  : const Color(0xFFD8E2FB),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCaller ? 'Anrufer' : 'Sprachassistent',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF9CB0E6)
                                      : const Color(0xFF6173A8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item.text),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0B1A3D)
                          : const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1D3468)
                            : const Color(0xFFD8E2FB),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              const Icon(Icons.notes),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Notizen zu diesem Telefonat',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF142246),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: notes.isEmpty
                              ? const Center(child: Text('Noch keine Notizen'))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  itemCount: notes.length,
                                  itemBuilder: (context, index) {
                                    final note = notes[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF101F45)
                                            : const Color(0xFFF4F7FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatDate(note.createdAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? const Color(0xFF8EA2DD)
                                                  : const Color(0xFF6A79A7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: Text(note.text)),
                                              IconButton(
                                                tooltip: 'Notiz löschen',
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: () =>
                                                    _deleteNoteFromSelectedCall(
                                                        note.id),
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: isDark
                                                      ? const Color(0xFFB9C9F5)
                                                      : const Color(0xFF5B72A6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newNoteController,
                                  minLines: 2,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Neue Notiz',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _addNoteToSelectedCall,
                                child: const Text('Speichern'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaPill(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12264F) : const Color(0xFFECF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFDBE6FF) : const Color(0xFF2D457A),
        ),
      ),
    );
  }
}
