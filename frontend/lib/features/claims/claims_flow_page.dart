import 'package:flutter/material.dart';

import '../../domain/claims_models.dart';
import '../../domain/rules/eligibility_engine.dart';
import '../../services/ai/ai_helper.dart';
import '../../services/forms/guided_forms.dart';
import '../../services/pdf/pdf_export_service.dart';

class ClaimsFlowPage extends StatefulWidget {
  const ClaimsFlowPage({super.key});

  @override
  State<ClaimsFlowPage> createState() => _ClaimsFlowPageState();
}

class _ClaimsFlowPageState extends State<ClaimsFlowPage> {
  final _engine = EligibilityEngine();
  final _pdf = PdfExportService();
  final AiHelper _aiHelper = OptionalAiHelper();

  int _step = 0;
  PersonaType _persona = PersonaType.student;
  bool _isStudent = true;
  bool _isSingleParent = false;
  bool _hasCareCase = false;
  bool _forOtherPerson = false;
  final _ageCtrl = TextEditingController(text: '24');
  final _childrenCtrl = TextEditingController(text: '0');
  final _incomeCtrl = TextEditingController(text: '900');

  List<EligibilityResult> _results = [];
  String? _selectedClaimId;
  List<FormQuestion> _questions = [];
  int _qIndex = 0;
  final Map<String, String> _answers = {};
  final _answerCtrl = TextEditingController();
  bool _aiEnabled = false;
  String _helpText = '';

  @override
  void dispose() {
    _ageCtrl.dispose();
    _childrenCtrl.dispose();
    _incomeCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KlarAnspruch - Guided Flow'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/admin'),
            child: const Text('Admin'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: switch (_step) {
          0 => _buildOnboarding(),
          1 => _buildResults(),
          2 => _buildGuidedQuestions(),
          _ => _buildFinish(),
        },
      ),
    );
  }

  Widget _buildOnboarding() {
    return ListView(
      children: [
        Text('Onboarding Profil', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        DropdownButtonFormField<PersonaType>(
          initialValue: _persona,
          decoration: const InputDecoration(labelText: 'Persona', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: PersonaType.student, child: Text('Studierende:r')),
            DropdownMenuItem(value: PersonaType.singleParent, child: Text('Alleinerziehend')),
            DropdownMenuItem(value: PersonaType.careCase, child: Text('Pflegefall')),
          ],
          onChanged: (value) => setState(() => _persona = value ?? PersonaType.student),
        ),
        const SizedBox(height: 12),
        _buildTextField(_ageCtrl, 'Alter'),
        const SizedBox(height: 12),
        _buildTextField(_incomeCtrl, 'Monatliches Einkommen'),
        const SizedBox(height: 12),
        _buildTextField(_childrenCtrl, 'Anzahl Kinder'),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _isStudent,
          onChanged: (v) => setState(() => _isStudent = v),
          title: const Text('Ist Student:in'),
        ),
        SwitchListTile(
          value: _isSingleParent,
          onChanged: (v) => setState(() => _isSingleParent = v),
          title: const Text('Ist alleinerziehend'),
        ),
        SwitchListTile(
          value: _hasCareCase,
          onChanged: (v) => setState(() => _hasCareCase = v),
          title: const Text('Pflegefall in der Familie'),
        ),
        SwitchListTile(
          value: _forOtherPerson,
          onChanged: (v) => setState(() => _forOtherPerson = v),
          title: const Text('Formular für andere Person ausfüllen'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _evaluate,
          child: const Text('Ansprüche prüfen'),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Erkannte Ansprüche', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final result = _results[index];
              return Card(
                child: ListTile(
                  title: Text(result.title),
                  subtitle: Text(result.reason),
                  leading: Chip(label: Text(_confidenceText(result.confidence))),
                  trailing: FilledButton.tonal(
                    onPressed: () => _startGuidedForm(result.claimId),
                    child: const Text('Formular starten'),
                  ),
                ),
              );
            },
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Zurück'),
        ),
      ],
    );
  }

  Widget _buildGuidedQuestions() {
    final q = _questions[_qIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Geführter Formularmodus', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Frage ${_qIndex + 1} von ${_questions.length}'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.label, style: Theme.of(context).textTheme.titleLarge),
                if (q.hint.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(q.hint),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('KI-Hilfe aktivieren'),
                    const SizedBox(width: 8),
                    Switch(
                      value: _aiEnabled,
                      onChanged: (v) async {
                        setState(() => _aiEnabled = v);
                        await _refreshHelpText();
                      },
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _helpText.isEmpty ? 'Hilfe wird geladen...' : _helpText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _answerCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Antwort eingeben',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton(
              onPressed: _qIndex == 0
                  ? null
                  : () => setState(() {
                      _qIndex -= 1;
                      _answerCtrl.text = _answers[_questions[_qIndex].id] ?? '';
                    }),
              child: const Text('Zurück'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _nextQuestion,
              child: Text(_qIndex == _questions.length - 1 ? 'Fertigstellen' : 'Weiter'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinish() {
    final title = _claimTitle(_selectedClaimId ?? 'antrag');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dokument erstellt', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Dein vorbefülltes Dokument für "$title" ist bereit.'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            await _pdf.exportPrefilledPdf(claimTitle: title, answers: _answers);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF heruntergeladen')),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('PDF herunterladen'),
        ),
        const SizedBox(height: 10),
        Text(
          'Nächster Schritt: Dokument unterschreiben und bei der zuständigen Stelle einreichen.',
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _step = 0;
            _results = [];
            _answers.clear();
            _selectedClaimId = null;
            _questions = [];
            _qIndex = 0;
          }),
          child: const Text('Neuen Fall starten'),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _evaluate() {
    final profile = UserProfile(
      persona: _persona,
      age: int.tryParse(_ageCtrl.text.trim()) ?? 24,
      isStudent: _isStudent,
      isSingleParent: _isSingleParent,
      childrenCount: int.tryParse(_childrenCtrl.text.trim()) ?? 0,
      monthlyIncome: int.tryParse(_incomeCtrl.text.trim()) ?? 0,
      forOtherPerson: _forOtherPerson,
      hasCareCaseInFamily: _hasCareCase,
    );
    setState(() {
      _results = _engine.evaluate(profile);
      _step = 1;
    });
  }

  void _startGuidedForm(String claimId) {
    setState(() {
      _selectedClaimId = claimId;
      _questions = GuidedForms.questionsForClaim(claimId);
      _qIndex = 0;
      _answers.clear();
      _answerCtrl.clear();
      _helpText = '';
      _step = 2;
    });
    _refreshHelpText();
  }

  void _nextQuestion() {
    final current = _questions[_qIndex];
    _answers[current.id] = _answerCtrl.text.trim();
    if (_qIndex == _questions.length - 1) {
      setState(() => _step = 3);
      return;
    }
    setState(() {
      _qIndex += 1;
      _answerCtrl.text = _answers[_questions[_qIndex].id] ?? '';
    });
    _refreshHelpText();
  }

  Future<void> _refreshHelpText() async {
    if (_questions.isEmpty) return;
    final currentQuestion = _questions[_qIndex];
    final text = await _aiHelper.simplifyQuestion(
      question: currentQuestion.label,
      enabled: _aiEnabled,
    );
    if (!mounted) return;
    setState(() => _helpText = text);
  }

  String _claimTitle(String claimId) {
    switch (claimId) {
      case 'bafoeg':
        return 'BAföG';
      case 'kindergeld':
        return 'Kindergeld';
      case 'kinderzuschlag':
        return 'Kinderzuschlag';
      case 'pflege':
        return 'Pflege-Unterstützung';
      default:
        return 'Antrag';
    }
  }

  String _confidenceText(EligibilityConfidence value) {
    switch (value) {
      case EligibilityConfidence.likely:
        return 'Wahrscheinlich';
      case EligibilityConfidence.check:
        return 'Prüfen';
      case EligibilityConfidence.unlikely:
        return 'Eher nicht';
    }
  }
}
