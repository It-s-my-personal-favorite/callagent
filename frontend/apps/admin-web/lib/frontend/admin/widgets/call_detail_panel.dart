import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;

import '../../../domain/admin_models.dart';
import '../../../services/pdf/pdf_export_service.dart';
import 'admin_common_widgets.dart';

class CallDetailPanel extends StatefulWidget {
  const CallDetailPanel({
    super.key,
    required this.call,
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

  final CallSession call;
  final ValueChanged<bool> onToggleBlock;
  final void Function(bool helpful, int score, String note) onSaveReview;
  final VoidCallback onToggleArchived;
  final VoidCallback onToggleImportant;
  final VoidCallback onToggleWarning;
  final VoidCallback onToggleForward;
  final ValueChanged<String> onAddCallNote;
  final ValueChanged<String> onDeleteCallNote;
  final VoidCallback onOpenCustomerPage;

  @override
  State<CallDetailPanel> createState() => _CallDetailPanelState();
}

class _CallDetailPanelState extends State<CallDetailPanel> {
  late bool _helpful;
  late double _score;
  late TextEditingController _noteController;
  late TextEditingController _newNoteController;
  final PdfExportService _pdfExport = PdfExportService();

  /// Web: [html.AudioElement]. Als [dynamic] typisiert, damit VM-Tests (ohne vollständige DOM-Stubs) bauen.
  dynamic _audioElement;
  Timer? _playbackTicker;
  double _currentPositionSec = 0;
  bool _isPlaying = false;
  int _activeTurnIndex = 0;
  int _activeTab = 0;
  String? _localRecordingObjectUrl;

  List<TranscriptTurn> get _displayTranscript {
    final transcript = widget.call.transcript;
    if (transcript.length >= 8) return transcript;
    if (transcript.isEmpty) {
      return [
        TranscriptTurn(
          role: 'system',
          text: 'Kein Original-Transkript vorhanden (Demo-Kontext aktiv).',
          timestamp: widget.call.startedAt,
        ),
      ];
    }

    final generated = <TranscriptTurn>[];
    for (var i = 0; i < transcript.length; i++) {
      final base = transcript[i];
      final start = widget.call.startedAt.add(Duration(seconds: i * 45));
      generated.add(
        TranscriptTurn(role: base.role, text: base.text, timestamp: start),
      );
      generated.addAll([
        TranscriptTurn(
          role: base.role == 'caller' ? 'assistant' : 'caller',
          text:
              'Verstanden. Ich gehe mit dir Schritt für Schritt durch, was wir schon wissen.',
          timestamp: start.add(const Duration(seconds: 16)),
        ),
        TranscriptTurn(
          role: base.role,
          text:
              'Okay, ich gebe dir dazu noch den fehlenden Kontext aus meinem Fall.',
          timestamp: start.add(const Duration(seconds: 31)),
        ),
      ]);
    }
    return generated.take(16).toList();
  }

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _newNoteController = TextEditingController();
    _hydrateReviewValues();
    _initAudio();
  }

  @override
  void didUpdateWidget(covariant CallDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call.id != widget.call.id) {
      _disposeAudio();
      _hydrateReviewValues();
      _newNoteController.clear();
      _initAudio();
    }
  }

  @override
  void dispose() {
    _disposeAudio();
    _noteController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }

  Future<void> _exportCallPdf() async {
    await _pdfExport.exportCallBriefing(widget.call);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF-Export wurde heruntergeladen')),
    );
  }

  void _hydrateReviewValues() {
    _helpful = widget.call.internalReview.helpful;
    _score = widget.call.internalReview.score.toDouble();
    _noteController.text = widget.call.internalReview.note;
    _currentPositionSec = 0;
    _activeTurnIndex = 0;
    _isPlaying = false;
  }

  void _initAudio() {
    final recordingUrl = widget.call.recordingUrl;
    if (recordingUrl == null || recordingUrl.isEmpty) return;
    final el = html.AudioElement()
      ..src = recordingUrl
      ..preload = 'metadata';
    try {
      el.loop = false;
    } catch (_) {}
    el.onPlay.listen((_) {
      if (!mounted) return;
      setState(() => _isPlaying = true);
    });
    el.onPause.listen((_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
    });
    el.onEnded.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _currentPositionSec = _timelineDurationSec.toDouble();
        _activeTurnIndex = _findActiveTurnIndex(_currentPositionSec);
      });
    });
    el.onError.listen((_) {
      _audioElement = null;
    });
    _audioElement = el;
  }

  void _disposeAudio() {
    _playbackTicker?.cancel();
    _playbackTicker = null;
    _audioElement?.pause();
    _audioElement?.src = '';
    _audioElement = null;
    if (_localRecordingObjectUrl != null) {
      html.Url.revokeObjectUrl(_localRecordingObjectUrl!);
      _localRecordingObjectUrl = null;
    }
  }

  int get _timelineDurationSec {
    final maxDuration =
        widget.call.durationSec <= 0 ? 1 : widget.call.durationSec;
    final transcript = _displayTranscript;
    if (transcript.isEmpty) return maxDuration;
    final first = transcript.first.timestamp;
    final last = transcript.last.timestamp;
    final transcriptDuration = last.difference(first).inSeconds + 12;
    return transcriptDuration > maxDuration ? transcriptDuration : maxDuration;
  }

  int _turnStartSec(int index) {
    final first = widget.call.startedAt;
    final sec = _displayTranscript[index].timestamp.difference(first).inSeconds;
    if (sec < 0) return 0;
    final max = _timelineDurationSec;
    if (sec > max) return max;
    return sec;
  }

  int _turnEndSec(int index) {
    if (index + 1 < _displayTranscript.length) {
      final nextStart = _turnStartSec(index + 1);
      return nextStart <= _turnStartSec(index)
          ? _turnStartSec(index) + 6
          : nextStart;
    }
    final tail = _turnStartSec(index) + 8;
    return tail > _timelineDurationSec ? _timelineDurationSec : tail;
  }

  int _findActiveTurnIndex(double positionSec) {
    for (var i = 0; i < _displayTranscript.length; i++) {
      final start = _turnStartSec(i).toDouble();
      final end = _turnEndSec(i).toDouble();
      if (positionSec >= start && positionSec <= end) return i;
    }
    return 0;
  }

  void _startTicker() {
    _playbackTicker?.cancel();
    _playbackTicker = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted || !_isPlaying) return;
      if (_audioElement != null) {
        final ct = (_audioElement as dynamic).currentTime;
        final ctSec = ct is num ? ct.toDouble() : 0.0;
        final current = _audioPositionToTimelineSec(ctSec);
        setState(() {
          _currentPositionSec = current > _timelineDurationSec
              ? _timelineDurationSec.toDouble()
              : current;
          _activeTurnIndex = _findActiveTurnIndex(_currentPositionSec);
        });
        return;
      }
      setState(() {
        _currentPositionSec = (_currentPositionSec + 0.12)
            .clamp(0, _timelineDurationSec.toDouble());
        _activeTurnIndex = _findActiveTurnIndex(_currentPositionSec);
        if (_currentPositionSec >= _timelineDurationSec) {
          _isPlaying = false;
        }
      });
    });
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      _audioElement?.pause();
      setState(() => _isPlaying = false);
      return;
    }
    if (_audioElement != null) {
      final a = _audioElement as dynamic;
      a.currentTime = _timelineToAudioSec(_currentPositionSec);
      await a.play() as dynamic;
    }
    setState(() => _isPlaying = true);
    _startTicker();
  }

  void _seekTo(double seconds) {
    final nextPos =
        seconds.clamp(0, _timelineDurationSec.toDouble()).toDouble();
    if (_audioElement != null) {
      (_audioElement as dynamic).currentTime = _timelineToAudioSec(nextPos);
    }
    setState(() {
      _currentPositionSec = nextPos;
      _activeTurnIndex = _findActiveTurnIndex(nextPos);
    });
  }

  double _timelineToAudioSec(double timelineSec) {
    final audio = _audioElement;
    if (audio == null) return timelineSec;
    final dur = (audio as dynamic).duration;
    final audioDuration = dur is num ? dur.toDouble() : double.nan;
    if (!audioDuration.isFinite || audioDuration <= 0) {
      return timelineSec;
    }
    final timelineDuration = _timelineDurationSec.toDouble();
    if (timelineDuration <= 0) return 0;
    final ratio = (timelineSec / timelineDuration).clamp(0, 1).toDouble();
    return audioDuration * ratio;
  }

  double _audioPositionToTimelineSec(double audioSec) {
    final audio = _audioElement;
    if (audio == null) return audioSec;
    final dur = (audio as dynamic).duration;
    final audioDuration = dur is num ? dur.toDouble() : double.nan;
    if (!audioDuration.isFinite || audioDuration <= 0) {
      return audioSec;
    }
    final ratio = (audioSec / audioDuration).clamp(0, 1).toDouble();
    return _timelineDurationSec * ratio;
  }

  String _formatClock(double totalSec) {
    final sec = totalSec.round();
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $h:$min';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final call = widget.call;
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): _TogglePlaybackIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _SeekBackwardIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _SeekForwardIntent(),
        SingleActivator(LogicalKeyboardKey.digit1, control: true):
            _SelectTabIntent(0),
        SingleActivator(LogicalKeyboardKey.digit2, control: true):
            _SelectTabIntent(1),
        SingleActivator(LogicalKeyboardKey.digit3, control: true):
            _SelectTabIntent(2),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _TogglePlaybackIntent: CallbackAction<_TogglePlaybackIntent>(
            onInvoke: (_) {
              _togglePlayback();
              return null;
            },
          ),
          _SeekBackwardIntent: CallbackAction<_SeekBackwardIntent>(
            onInvoke: (_) {
              _seekTo((_currentPositionSec - 10)
                  .clamp(0, _timelineDurationSec.toDouble()));
              return null;
            },
          ),
          _SeekForwardIntent: CallbackAction<_SeekForwardIntent>(
            onInvoke: (_) {
              _seekTo((_currentPositionSec + 10)
                  .clamp(0, _timelineDurationSec.toDouble()));
              return null;
            },
          ),
          _SelectTabIntent: CallbackAction<_SelectTabIntent>(
            onInvoke: (intent) {
              setState(() => _activeTab = intent.tabIndex);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF050A1F), Color(0xFF0A1435)]
                    : const [Color(0xFFF8FAFF), Color(0xFFEDF2FF)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useStackedLayout = constraints.maxWidth < 1120;
                  final sidePanelWidth =
                      constraints.maxWidth < 1360 ? 280.0 : 310.0;
                  if (useStackedLayout) {
                    return Column(
                      children: [
                        Expanded(
                            child: _buildTranscriptAndAudio(
                                context, call, isDark)),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: _buildSidePanel(context, call, isDark),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildTranscriptAndAudio(context, call, isDark),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: sidePanelWidth,
                        child: _buildSidePanel(context, call, isDark),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptAndAudio(
      BuildContext context, CallSession call, bool isDark) {
    final transcript = _displayTranscript;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071129) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF1A2952) : const Color(0xFFD8E2FB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call, color: Color(0xFF8EA2FF), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  call.callerNumber,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color:
                            isDark ? Colors.white : const Color(0xFF142246),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildTabStrip(isDark, compact: true),
              ),
              const SizedBox(width: 10),
              StatusBadge(status: call.status, endedAt: call.endedAt),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Gespräch gestartet: ${_formatDateTime(call.startedAt)}   '
                'dauer: ${_formatDuration(call.durationSec)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? const Color(0xFF9CB0E6)
                          : const Color(0xFF6A79A7),
                    ),
              ),
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF081632) : const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF1B2E5E)
                        : const Color(0xFFD8E2FB)),
              ),
              child: _buildMainTabBody(context, call, isDark, transcript),
            ),
          ),
          const SizedBox(height: 12),
          _buildAudioTrack(call, isDark, transcript),
        ],
      ),
    );
  }

  Widget _buildMainTabBody(
    BuildContext context,
    CallSession call,
    bool isDark,
    List<TranscriptTurn> transcript,
  ) {
    switch (_activeTab) {
      case 1:
        return _buildLiveInfo(isDark);
      case 2:
        return _buildNotesTab(context, call, isDark);
      case 0:
      default:
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: transcript.length,
          itemBuilder: (context, index) {
            final item = transcript[index];
            final isCaller = item.role == 'caller';
            final isActive = _activeTurnIndex == index;
            return GestureDetector(
              onTap: () => _seekTo(_turnStartSec(index).toDouble()),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                          ? const Color(0xFF2E1B66)
                          : const Color(0xFFEAE2FF))
                      : isCaller
                          ? (isDark
                              ? const Color(0xFF131F42)
                              : const Color(0xFFF3F6FF))
                          : (isDark
                              ? const Color(0xFF0E2A4A)
                              : const Color(0xFFEFF5FF)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF8A63FF)
                        : const Color(0xFF243B73),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCaller
                          ? Icons.record_voice_over
                          : Icons.smart_toy_outlined,
                      color: isCaller
                          ? const Color(0xFFAAB8FF)
                          : const Color(0xFF78E2FF),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCaller ? 'Anrufer' : 'Sprachassistent',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF9CB0E6)
                                      : const Color(0xFF6173A8),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF132449),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatClock(_turnStartSec(index).toDouble()),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF8EA2DD),
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }

  Widget _buildNotesTab(BuildContext context, CallSession call, bool isDark) {
    final sorted = List<CallNote>.from(call.notes)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Text(
            'Notizen zu diesem Anruf (lokal gespeichert)',
            style: TextStyle(
              color: isDark ? const Color(0xFF9CB0E6) : const Color(0xFF5E74A8),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: sorted.isEmpty
              ? Center(
                  child: Text(
                    'Noch keine Notizen.',
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFF8EA2DD)
                            : const Color(0xFF6A79A7)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final n = sorted[index];
                    final ts =
                        '${n.createdAt.day.toString().padLeft(2, '0')}.${n.createdAt.month.toString().padLeft(2, '0')}.${n.createdAt.year} '
                        '${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')} Uhr';
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF101F45)
                            : const Color(0xFFF4F7FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark
                                ? const Color(0xFF29417A)
                                : const Color(0xFFD8E2FB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ts,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF8EA2DD)
                                  : const Color(0xFF6A79A7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  n.text,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF142246),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: 'Notiz löschen',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => widget.onDeleteCallNote(n.id),
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
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _newNoteController,
                  minLines: 2,
                  maxLines: 4,
                  style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF142246),
                      fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Neue Notiz',
                    isDense: true,
                    labelStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFFA5BAEE)
                          : const Color(0xFF4B6399),
                      fontSize: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF2A3F74)
                            : const Color(0xFFBAC9EE),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF7B63FF)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final t = _newNoteController.text.trim();
                  if (t.isEmpty) return;
                  widget.onAddCallNote(t);
                  _newNoteController.clear();
                },
                child: const Text('Hinzufügen'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioTrack(
      CallSession call, bool isDark, List<TranscriptTurn> transcript) {
    final duration = _timelineDurationSec.toDouble();
    final markers = _buildTimelineMarkers(call, transcript, duration);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF060E24) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF1C2D57) : const Color(0xFFD8E2FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Text(
                'Audio Player',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFFBFD1FF)
                        : const Color(0xFF223A6A)),
              ),
              Text(
                '${_formatClock(_currentPositionSec)} / ${_formatClock(duration)}',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF8EA2DD)
                      : const Color(0xFF5E74A8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  final ratio =
                      (details.localPosition.dx / constraints.maxWidth)
                          .clamp(0, 1);
                  _seekTo(duration * ratio);
                },
                onHorizontalDragUpdate: (details) {
                  final ratio =
                      (details.localPosition.dx / constraints.maxWidth)
                          .clamp(0, 1);
                  _seekTo(duration * ratio);
                },
                child: SizedBox(
                  height: 84,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WaveformPainter(
                            samples: _waveformForCall(call),
                            progress:
                                (_currentPositionSec / duration).clamp(0, 1),
                            isDark: isDark,
                          ),
                        ),
                      ),
                      ...markers.map(
                        (marker) => Positioned(
                          left: marker.leftRatio * constraints.maxWidth,
                          top: 16,
                          bottom: 16,
                          width: (marker.widthRatio * constraints.maxWidth)
                              .clamp(4, constraints.maxWidth),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _seekTo(marker.startSec),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: marker.color.withValues(alpha: 0.26),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color:
                                          marker.color.withValues(alpha: 0.8)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: markers
                .take(8)
                .map(
                  (marker) => ActionChip(
                    backgroundColor: marker.color.withValues(alpha: 0.18),
                    side:
                        BorderSide(color: marker.color.withValues(alpha: 0.9)),
                    onPressed: () => _seekTo(marker.startSec),
                    label: Text(
                        '${marker.label} ${_formatClock(marker.startSec)}'),
                  ),
                )
                .toList(),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF7D63FF),
              inactiveTrackColor: const Color(0xFF213768),
              thumbColor: Colors.white,
              trackHeight: 3,
            ),
            child: Slider(
              value: _currentPositionSec.clamp(0, duration),
              max: duration,
              onChanged: (value) => _seekTo(value),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6E44FF)),
                onPressed: _togglePlayback,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white),
              ),
              TextButton.icon(
                onPressed: () =>
                    _seekTo((_currentPositionSec - 10).clamp(0, duration)),
                icon: const Icon(Icons.replay_10, color: Color(0xFFA6B8E8)),
                label: const Text('10s',
                    style: TextStyle(color: Color(0xFFA6B8E8))),
              ),
              TextButton.icon(
                onPressed: () =>
                    _seekTo((_currentPositionSec + 10).clamp(0, duration)),
                icon: const Icon(Icons.forward_10, color: Color(0xFFA6B8E8)),
                label: const Text('10s',
                    style: TextStyle(color: Color(0xFFA6B8E8))),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF102246)
                      : const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _audioElement == null
                      ? 'Demo-Timeline'
                      : 'Originalaufnahme',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF8EA2DD)
                        : const Color(0xFF5E74A8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabStrip(bool isDark, {bool compact = false}) {
    final tabs = <({String label, int index, IconData icon})>[
      (label: 'Chat', index: 0, icon: Icons.chat_bubble_outline),
      (label: 'Live Info', index: 1, icon: Icons.monitor_heart_outlined),
      (label: 'Notizen', index: 2, icon: Icons.sticky_note_2_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1A3D) : const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF243A70) : const Color(0xFFD2DCF8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs
            .map((tab) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _tabButton(tab.label, tab.index,
                      icon: tab.icon, isDark: isDark, compact: compact),
                ))
            .toList()
          ..removeLast(),
      ),
    );
  }

  List<_TimelineMarker> _buildTimelineMarkers(
    CallSession call,
    List<TranscriptTurn> transcript,
    double duration,
  ) {
    if (transcript.isEmpty || duration <= 0) return const [];
    final markers = <_TimelineMarker>[];
    for (var i = 0; i < transcript.length; i++) {
      final start = _turnStartSec(i).toDouble();
      final end = _turnEndSec(i).toDouble();
      final widthRatio =
          ((end - start) / duration).clamp(0.01, 0.32).toDouble();
      final leftRatio = (start / duration).clamp(0.0, 0.99).toDouble();
      final turn = transcript[i];
      final isCaller = turn.role == 'caller';
      markers.add(
        _TimelineMarker(
          startSec: start,
          leftRatio: leftRatio,
          widthRatio: widthRatio,
          color: isCaller ? const Color(0xFF4DB6FF) : const Color(0xFF9A6BFF),
          label: isCaller ? 'Caller' : 'Assistant',
        ),
      );
    }
    return markers;
  }

  List<double> _waveformForCall(CallSession call, {int points = 220}) {
    final hash = _stableHash('${call.id}-${call.callerNumber}');
    final samples = <double>[];
    for (var i = 0; i < points; i++) {
      final x = i / (points - 1);
      final env = 0.55 + (0.45 * math.sin((x * math.pi * 2) + (hash % 7)));
      final toneA = math.sin((x * 24) + (hash % 13));
      final toneB = math.sin((x * 73) + (hash % 29));
      final toneC = math.sin((x * 145) + (hash % 47));
      final mixed = ((toneA * 0.5) + (toneB * 0.3) + (toneC * 0.2)).abs();
      final pulse = (((i + hash) % 23) == 0) ? 1.0 : 0.0;
      final sample =
          (0.08 + (mixed * env * 0.92) + (pulse * 0.35)).clamp(0.06, 1.0);
      samples.add(sample);
    }
    return samples;
  }

  int _stableHash(String input) {
    var hash = 7;
    for (final code in input.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    return hash;
  }

  Widget _buildSidePanel(BuildContext context, CallSession call, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF081330) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF1A2A56) : const Color(0xFFD8E2FB)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelSection(
              title: 'Anruf Details',
              isDark: isDark,
              child: Column(
                children: [
                  _metaRow('Telefonnummer', call.callerNumber, isDark),
                  _metaRow('Status', call.status, isDark),
                  _metaRow('Dauer', _formatDuration(call.durationSec), isDark),
                  _metaRow(
                      'Assistent', _assistantDisplayName(call.assistantId), isDark),
                  _metaRow('Tokens', '${call.metrics.tokenTotal}', isDark),
                  _metaRow('Region', 'DE', isDark),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenCustomerPage,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(36),
                      side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A3E70)
                              : const Color(0xFF4A5F95)),
                      foregroundColor: isDark
                          ? const Color(0xFFD2DFFF)
                          : const Color(0xFF243A6A),
                    ),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Anrufs Verlauf'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _panelSection(
              title: 'Schnellaktionen',
              isDark: isDark,
              child: Column(
                children: [
                  _quickAction(
                    call.status.toLowerCase() == 'archived'
                        ? 'Archivierung rückgängig machen'
                        : 'Anruf archivieren',
                    call.status.toLowerCase() == 'archived'
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    isDark,
                    widget.onToggleArchived,
                  ),
                  _quickAction(
                    call.important
                        ? 'Markierung entfernen'
                        : 'Als wichtig markieren',
                    call.important ? Icons.star : Icons.star_outline,
                    isDark,
                    widget.onToggleImportant,
                  ),
                  _quickAction(
                    'Anruf exportieren',
                    Icons.upload_file_outlined,
                    isDark,
                    _exportCallPdf,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _panelSection(
              title: 'Tools',
              isDark: isDark,
              child: Column(
                children: [
                  _toolButton(
                    call.blocked ? 'Blockierung aufheben' : 'Nummer blockieren',
                    const Color(0xFF7C1E34),
                    () => widget.onToggleBlock(!call.blocked),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Hilfreich',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFFCEE0FF)
                        : const Color(0xFF2C4374)),
              ),
              value: _helpful,
              onChanged: (value) => setState(() => _helpful = value),
            ),
            Row(
              children: [
                Text(
                  'Score',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFCEE0FF)
                        : const Color(0xFF2C4374),
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: 10,
                    divisions: 10,
                    value: _score,
                    label: _score.round().toString(),
                    onChanged: (value) => setState(() => _score = value),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _noteController,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF142246),
                fontSize: 12,
              ),
              decoration: InputDecoration(
                labelText: 'Interne Notiz',
                isDense: true,
                labelStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFFA5BAEE)
                      : const Color(0xFF4B6399),
                  fontSize: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A3F74)
                        : const Color(0xFFBAC9EE),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF7B63FF)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => widget.onSaveReview(
                _helpful,
                _score.round(),
                _noteController.text.trim(),
              ),
              child: const Text('Bewertung speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelSection({
    required String title,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1A3D) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF1D3468) : const Color(0xFFD8E2FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF142246),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF93A8DB) : const Color(0xFF4F679B),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF142246),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index,
      {required IconData icon, required bool isDark, bool compact = false}) {
    final selected = _activeTab == index;
    return FilledButton.icon(
      onPressed: () => setState(() => _activeTab = index),
      style: FilledButton.styleFrom(
        minimumSize: compact ? const Size(108, 34) : const Size(120, 38),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : null,
        backgroundColor: selected
            ? const Color(0xFF5A3CC2)
            : (isDark ? const Color(0xFF16294E) : const Color(0xFFDDE6FF)),
        foregroundColor: selected
            ? Colors.white
            : (isDark ? const Color(0xFFC6D5FF) : const Color(0xFF2A4476)),
        elevation: selected ? 1 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: compact ? 14 : 16),
      label: Text(label, style: TextStyle(fontSize: compact ? 11 : 12)),
    );
  }

  Widget _buildLiveInfo(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _infoCard('Audio Qualität', 'Stabil', isDark),
        _infoCard('Netzwerk', 'Niedrige Latenz', isDark),
        _infoCard('Segment Marker', '${widget.call.transcript.length} erkannt',
            isDark),
        _infoCard(
          'Token Input/Output',
          '${widget.call.metrics.tokenInput} / ${widget.call.metrics.tokenOutput}',
          isDark,
        ),
      ],
    );
  }

  Widget _infoCard(String title, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101F45) : const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark ? const Color(0xFF29417A) : const Color(0xFFD8E2FB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFAABCEA) : const Color(0xFF4F679B),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF142246),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
      String label, IconData icon, bool isDark, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDark ? const Color(0xFF9AB1E8) : const Color(0xFF4F679B),
        size: 18,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? const Color(0xFFD8E4FF) : const Color(0xFF142246),
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? const Color(0xFF7F95CB) : const Color(0xFF6A79A7),
        size: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _toolButton(String label, Color color, VoidCallback onPressed) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(36),
        backgroundColor: color,
        foregroundColor: Colors.white,
        alignment: Alignment.centerLeft,
      ),
      child: Text(label),
    );
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
}

class _TimelineMarker {
  const _TimelineMarker({
    required this.startSec,
    required this.leftRatio,
    required this.widthRatio,
    required this.color,
    required this.label,
  });

  final double startSec;
  final double leftRatio;
  final double widthRatio;
  final Color color;
  final String label;
}

class _TogglePlaybackIntent extends Intent {
  const _TogglePlaybackIntent();
}

class _SeekBackwardIntent extends Intent {
  const _SeekBackwardIntent();
}

class _SeekForwardIntent extends Intent {
  const _SeekForwardIntent();
}

class _SelectTabIntent extends Intent {
  const _SelectTabIntent(this.tabIndex);

  final int tabIndex;
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.samples,
    required this.progress,
    required this.isDark,
  });

  final List<double> samples;
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final barWidth = size.width / (samples.length * 1.08);
    final baseGap = barWidth * 0.08;

    final unplayedPaint = Paint()
      ..color = isDark ? const Color(0xFF6D7E9E) : const Color(0xFFA8B4CC)
      ..strokeCap = StrokeCap.round;
    final playedPaint = Paint()
      ..color = isDark ? const Color(0xFFA86CFF) : const Color(0xFF7D63FF)
      ..strokeCap = StrokeCap.round;
    final centerLinePaint = Paint()
      ..color = isDark ? const Color(0xFF243A68) : const Color(0xFFD6E0F5)
      ..strokeWidth = 1;

    canvas.drawLine(
        Offset(0, centerY), Offset(size.width, centerY), centerLinePaint);

    for (var i = 0; i < samples.length; i++) {
      final left = i * (barWidth + baseGap);
      final topAmp = samples[i] * (size.height * 0.42);
      final isPlayed = (i / (samples.length - 1)) <= progress;
      final paint = isPlayed ? playedPaint : unplayedPaint;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, centerY - topAmp, barWidth, topAmp * 2),
        const Radius.circular(999),
      );
      canvas.drawRRect(rect, paint);
    }

    final playheadX = (size.width * progress).clamp(0, size.width).toDouble();
    final playheadPaint = Paint()
      ..color = const Color(0xFFF2F6FF)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(playheadX, 4),
      Offset(playheadX, size.height - 4),
      playheadPaint,
    );
    canvas.drawCircle(Offset(playheadX, 4), 4, playheadPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.samples != samples ||
        oldDelegate.isDark != isDark;
  }
}
