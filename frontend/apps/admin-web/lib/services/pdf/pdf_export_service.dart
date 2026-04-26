import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

import '../../domain/admin_models.dart';

class PdfExportService {
  Future<void> exportPrefilledPdf({
    required String claimTitle,
    required Map<String, String> answers,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(),
          pageFormat: PdfPageFormat.a4,
        ),
        build: (context) => [
          pw.Text(
            'KlarAnspruch - Vorgefüllter Antrag',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Dokument: $claimTitle'),
          pw.SizedBox(height: 16),
          ...answers.entries.map(
            (e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text('${e.key}: ${e.value}'),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Hinweis: Unterschreiben und bei der zuständigen Stelle einreichen.',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    _downloadBytes(bytes, '${claimTitle.toLowerCase()}_callagent.pdf');
  }

  void _downloadBytes(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    anchor.remove();
  }

  Future<void> exportCallBriefing(CallSession call) async {
    final doc = pw.Document();
    final transcriptPreview = call.transcript
        .take(24)
        .map((t) => '[${t.role}] ${t.text}')
        .join('\n');
    final notesBlock = call.notes.isEmpty
        ? '(Keine Notizen)'
        : call.notes
            .map((n) => '${n.createdAt.toIso8601String()}\n${n.text}')
            .join('\n\n');
    final p = call.profile;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(),
          pageFormat: PdfPageFormat.a4,
        ),
        build: (context) => [
          pw.Text(
            'Anruf-Dossier (Export)',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Anruf-ID: ${call.id}'),
          pw.Text('Rufnummer: ${call.callerNumber}'),
          pw.Text('Status: ${call.status}'),
          pw.Text('Gestartet: ${call.startedAt.toIso8601String()}'),
          pw.Text('Dauer (s): ${call.durationSec}'),
          pw.Text('Assistent: ${call.assistantId}'),
          pw.SizedBox(height: 12),
          pw.Text('Kundendaten', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Name: ${p.displayName}'),
          pw.Text('E-Mail: ${p.email}'),
          pw.Text('Firma: ${p.company}'),
          pw.Text('Adresse: ${p.street}, ${p.zip} ${p.city}'),
          pw.Text('Aktenzeichen: ${p.caseReference}'),
          pw.Text('Geburtsdatum: ${p.birthDate}'),
          if (p.extraNotes.isNotEmpty) pw.Text('Zusatz: ${p.extraNotes}'),
          pw.SizedBox(height: 12),
          pw.Text('Markierungen', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('Markiert: ${call.marked ? "Ja" : "Nein"}'),
          pw.Text('Wichtig: ${call.important ? "Ja" : "Nein"}'),
          pw.Text('Warnung aktiv: ${call.warningActive ? "Ja" : "Nein"}'),
          pw.Text('Weiterleitung: ${call.isForwarded ? call.forwardedTo! : "Nein"}'),
          pw.SizedBox(height: 12),
          pw.Text('Notizen', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(notesBlock),
          pw.SizedBox(height: 12),
          pw.Text('Transkript (Auszug)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(transcriptPreview),
          pw.SizedBox(height: 16),
          pw.Text(
            'Hinweis: Export für interne Dokumentation. Inhalte prüfen und personenbezogene Daten schützen.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final safeId = call.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    _downloadBytes(bytes, 'anruf_${safeId}_export.pdf');
  }
}
