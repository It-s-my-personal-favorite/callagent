import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../backend/admin_api/admin_api_contract.dart';
import '../../domain/admin_models.dart';
import '../../services/call_local_store.dart';
import 'pages/api_control/api_control_page.dart';
import 'pages/customer/customer_profile_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/live_calls/live_calls_page.dart';
import 'pages/moderation/moderation_page.dart';
import 'widgets/admin_common_widgets.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({
    super.key,
    required this.api,
    required this.themeMode,
    required this.onToggleThemeMode,
  });

  final AdminApiContract api;
  final ThemeMode themeMode;
  final VoidCallback onToggleThemeMode;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  static const _pageTitles = <String>[
    'Dashboard',
    'Anrufe',
    'Moderation',
    'API Status',
  ];

  int _selectedIndex = 0;
  List<CallSession> _calls = const [];
  String? _selectedCallId;
  bool _isLoading = true;
  Timer? _refreshTimer;
  final CallLocalStore _callLocalStore = CallLocalStore();

  bool _apiControlLoading = false;
  bool? _healthOk;
  Map<String, dynamic> _serverStatus = const {};
  Map<String, dynamic> _sourceStatus = const {};

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

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadCalls(),
    );
    _loadCalls();
    _refreshApiControl();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCalls() async {
    try {
      final raw = await widget.api.getCalls();
      final calls = await _callLocalStore.mergeCalls(raw);
      if (!mounted) return;
      setState(() {
        _calls = calls;
        if (_selectedCallId == null ||
            calls.every((c) => c.id != _selectedCallId)) {
          _selectedCallId = calls.isNotEmpty ? calls.first.id : null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Anrufe konnten nicht geladen werden: $e')));
    }
  }

  Future<void> _refreshApiControl() async {
    setState(() => _apiControlLoading = true);
    try {
      final server = await widget.api.getServerStatus();
      final source = await widget.api.getTwilioSourceStatus();
      final health = await widget.api.pingHealth();
      if (!mounted) return;
      setState(() {
        _serverStatus = server;
        _sourceStatus = source;
        _healthOk = health;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('API-Status konnte nicht geladen werden: $e')));
    } finally {
      if (mounted) {
        setState(() => _apiControlLoading = false);
      }
    }
  }

  CallSession? get _selectedCall {
    if (_selectedCallId == null) return null;
    for (final call in _calls) {
      if (call.id == _selectedCallId) return call;
    }
    return null;
  }

  Future<void> _toggleBlock(bool blocked) async {
    if (_selectedCall == null) return;
    final callsApi = widget.api;
    if (blocked) {
      await callsApi.blockNumber(_selectedCall!.id, 'Spam-Verdacht');
    } else {
      await callsApi.unblockNumber(_selectedCall!.id);
    }
    await _loadCalls();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text(blocked ? 'Nummer blockiert' : 'Nummer entsperrt')));
  }

  Future<void> _toggleArchivedForSelected() async {
    final c = _selectedCall;
    if (c == null) return;
    final isArchived = c.status.toLowerCase() == 'archived';
    await _callLocalStore.patchCall(
      c.id,
      {'status': isArchived ? 'completed' : 'archived'},
    );
    await _loadCalls();
  }

  Future<void> _toggleImportantForSelected() async {
    final c = _selectedCall;
    if (c == null) return;
    await _callLocalStore.patchCall(c.id, {'important': !c.important});
    await _loadCalls();
  }

  Future<void> _toggleWarningForSelected() async {
    final c = _selectedCall;
    if (c == null) return;
    await _callLocalStore.patchCall(c.id, {'warningActive': !c.warningActive});
    await _loadCalls();
  }

  Future<void> _toggleForwardForSelected() async {
    final c = _selectedCall;
    if (c == null) return;
    final next = c.isForwarded
        ? <String, dynamic>{'forwardedTo': null}
        : <String, dynamic>{'forwardedTo': 'Team Recht / Eskalation'};
    await _callLocalStore.patchCall(c.id, next);
    await _loadCalls();
  }

  Future<void> _addCallNoteForSelected(String text) async {
    final c = _selectedCall;
    if (c == null || text.trim().isEmpty) return;
    final note = CallNote(
      id: 'n-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      text: text.trim(),
    );
    final list = [...c.notes, note].map((e) => e.toJson()).toList();
    await _callLocalStore.patchCall(c.id, {'notes': list});
    await _loadCalls();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Notiz gespeichert')));
  }

  Future<void> _deleteCallNoteForSelected(String noteId) async {
    final c = _selectedCall;
    if (c == null) return;
    final updatedNotes =
        c.notes.where((note) => note.id != noteId).map((e) => e.toJson()).toList();
    await _callLocalStore.patchCall(c.id, {'notes': updatedNotes});
    await _loadCalls();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Notiz gelöscht')));
  }

  Future<void> _addCallNoteForCall(String callId, String text) async {
    if (text.trim().isEmpty) return;
    final target =
        _calls.where((c) => c.id == callId).cast<CallSession?>().firstWhere(
              (c) => c != null,
              orElse: () => null,
            );
    if (target == null) return;
    final note = CallNote(
      id: 'n-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      text: text.trim(),
    );
    final list = [...target.notes, note].map((e) => e.toJson()).toList();
    await _callLocalStore.patchCall(callId, {'notes': list});
    await _loadCalls();
  }

  Future<void> _deleteCallNoteForCall(String callId, String noteId) async {
    final target =
        _calls.where((c) => c.id == callId).cast<CallSession?>().firstWhere(
              (c) => c != null,
              orElse: () => null,
            );
    if (target == null) return;
    final updatedNotes = target.notes
        .where((note) => note.id != noteId)
        .map((e) => e.toJson())
        .toList();
    await _callLocalStore.patchCall(callId, {'notes': updatedNotes});
    await _loadCalls();
  }

  Future<void> _openCustomerPageForCall(CallSession call) async {
    final customerCalls =
        _calls.where((c) => c.callerNumber == call.callerNumber).toList();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerProfilePage(
          callerNumber: call.callerNumber,
          calls: customerCalls,
          initialCallId: call.id,
          onAddNote: _addCallNoteForCall,
          onDeleteNote: _deleteCallNoteForCall,
          onReloadCalls: _reloadCallsForCustomer,
        ),
      ),
    );
    await _loadCalls();
  }

  Future<List<CallSession>> _reloadCallsForCustomer(String callerNumber) async {
    await _loadCalls();
    return _calls.where((c) => c.callerNumber == callerNumber).toList();
  }

  Future<void> _saveReview(bool helpful, int score, String note) async {
    if (_selectedCall == null) return;
    await widget.api.submitInternalReview(
      callId: _selectedCall!.id,
      helpful: helpful,
      score: score,
      note: note,
    );
    await _loadCalls();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Interne Bewertung gespeichert')));
  }

  String _maskNumber(String value) {
    if (value.length <= 6) return value;
    return '${value.substring(0, 6)}***';
  }

  void _setPage(int index) {
    setState(() => _selectedIndex = index.clamp(0, _pageTitles.length - 1));
  }

  void _openLiveCallFromDashboard(String callId) {
    setState(() {
      _selectedCallId = callId;
      _selectedIndex = 1;
    });
  }

  void _openHistoryCallFromDashboard(String callId) {
    setState(() {
      _selectedCallId = callId;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liveCalls = _calls.where(_isCurrentlyActiveCall).length;
    final endedCalls = _calls.where(_isEndedCall).length;
    final blockedCalls = _calls.where((c) => c.blocked).length;
    final totalTokens =
        _calls.fold<int>(0, (sum, c) => sum + c.metrics.tokenTotal);
    final avgLatency = _calls.isEmpty
        ? 0
        : _calls.fold<int>(0, (sum, c) => sum + c.metrics.avgLatencyMs) ~/
            _calls.length;
    final avgFeedback = _calls.isEmpty
        ? 0.0
        : _calls.fold<int>(0, (sum, c) => sum + c.userFeedback.rating) /
            _calls.length;

    final pages = <Widget>[
      DashboardPage(
        liveCalls: liveCalls,
        endedCalls: endedCalls,
        blockedCalls: blockedCalls,
        totalTokens: totalTokens,
        avgLatency: avgLatency,
        avgFeedback: avgFeedback,
        calls: _calls,
        themeMode: widget.themeMode,
        onRefresh: _loadCalls,
        onToggleThemeMode: widget.onToggleThemeMode,
        onOpenLiveCalls: () => _setPage(1),
        onOpenHistory: () => _setPage(1),
        onOpenModeration: () => _setPage(2),
        onOpenVoiceApi: () => _setPage(3),
        onOpenApiControl: () => _setPage(3),
        onOpenLiveCallById: _openLiveCallFromDashboard,
        onOpenHistoryCallById: _openHistoryCallFromDashboard,
      ),
      LiveCallsPage(
        calls: _calls,
        selectedCallId: _selectedCallId,
        onSelectCall: (id) => setState(() => _selectedCallId = id),
        selectedCall: _selectedCall,
        onToggleBlock: (blocked) => _toggleBlock(blocked),
        onSaveReview: _saveReview,
        onToggleArchived: _toggleArchivedForSelected,
        onToggleImportant: _toggleImportantForSelected,
        onToggleWarning: _toggleWarningForSelected,
        onToggleForward: _toggleForwardForSelected,
        onAddCallNote: _addCallNoteForSelected,
        onDeleteCallNote: _deleteCallNoteForSelected,
        onOpenCustomerPage: _openCustomerPageForCall,
      ),
      ModerationPage(
        blockedCalls: _calls.where((c) => c.blocked).toList(),
        onUnblock: (callId) async {
          await widget.api.unblockNumber(callId);
          await _loadCalls();
        },
        maskNumber: _maskNumber,
      ),
      ApiControlPage(
        serverStatus: _serverStatus,
        sourceStatus: _sourceStatus,
        healthOk: _healthOk,
        loading: _apiControlLoading,
        onRefresh: _refreshApiControl,
      ),
    ];

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.digit1, control: true):
            _SwitchPageIntent(0),
        SingleActivator(LogicalKeyboardKey.digit2, control: true):
            _SwitchPageIntent(1),
        SingleActivator(LogicalKeyboardKey.digit3, control: true):
            _SwitchPageIntent(2),
        SingleActivator(LogicalKeyboardKey.digit4, control: true):
            _SwitchPageIntent(3),
        SingleActivator(LogicalKeyboardKey.keyR, control: true):
            _RefreshCallsIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SwitchPageIntent: CallbackAction<_SwitchPageIntent>(
            onInvoke: (intent) {
              setState(
                () => _selectedIndex =
                    intent.pageIndex.clamp(0, pages.length - 1),
              );
              return null;
            },
          ),
          _RefreshCallsIntent: CallbackAction<_RefreshCallsIntent>(
            onInvoke: (_) {
              _loadCalls();
              return null;
            },
          ),
        },
        child: Focus(
          child: Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF020715) : const Color(0xFFF3F6FF),
            body: _isLoading
                ? Semantics(
                    role: SemanticsRole.main,
                    child: const LoadingState(),
                  )
                : Column(
                    children: [
                      Semantics(
                        role: SemanticsRole.navigation,
                        label: 'Hauptnavigation',
                        child: _buildHeader(),
                      ),
                      Expanded(
                        child: Semantics(
                          role: SemanticsRole.main,
                          explicitChildNodes: true,
                          child: Semantics(
                            role: SemanticsRole.tabPanel,
                            label: _pageTitles[_selectedIndex],
                            explicitChildNodes: true,
                            child: pages[_selectedIndex],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A1636) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1D2E61) : const Color(0xFFDCE5FF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                role: SemanticsRole.tabBar,
                label: 'Bereiche',
                explicitChildNodes: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...List.generate(_pageTitles.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _buildPageTab(index, isDark),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _loadCalls,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Aktualisieren'),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: widget.themeMode == ThemeMode.dark
                      ? 'Hellmodus aktivieren'
                      : 'Dunkelmodus aktivieren',
                  onPressed: widget.onToggleThemeMode,
                  icon: Icon(
                    widget.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: isDark
                        ? const Color(0xFF1C2A4F)
                        : const Color(0xFFE5ECFF),
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: isDark
                          ? const Color(0xFFD2E0FF)
                          : const Color(0xFF334A80),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageTab(int index, bool isDark) {
    final selected = index == _selectedIndex;
    return Semantics(
      role: SemanticsRole.tab,
      selected: selected,
      label: _pageTitles[index],
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF5A38CC) : const Color(0xFFDCE5FF))
                : (isDark ? const Color(0xFF13234A) : const Color(0xFFF3F7FF)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? (isDark ? const Color(0xFF7C60DE) : const Color(0xFFB8CAFF))
                  : (isDark ? const Color(0xFF243A75) : const Color(0xFFD5E0FF)),
            ),
          ),
          child: Text(
            _pageTitles[index],
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected
                  ? (isDark ? Colors.white : const Color(0xFF203061))
                  : (isDark ? const Color(0xFFC5D5FF) : const Color(0xFF4E6293)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchPageIntent extends Intent {
  const _SwitchPageIntent(this.pageIndex);
  final int pageIndex;
}

class _RefreshCallsIntent extends Intent {
  const _RefreshCallsIntent();
}
