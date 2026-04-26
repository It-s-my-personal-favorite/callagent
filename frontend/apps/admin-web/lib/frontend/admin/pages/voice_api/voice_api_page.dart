import 'package:flutter/material.dart';

import '../../widgets/admin_common_widgets.dart';

class VoiceApiPage extends StatelessWidget {
  const VoiceApiPage({
    super.key,
    required this.formKey,
    required this.voiceApiConnected,
    required this.voiceApiChecking,
    required this.twilioAccountSidController,
    required this.twilioAuthTokenController,
    required this.localServerUrlController,
    required this.twilioPhoneNumberController,
    required this.deepgramApiKeyController,
    required this.onVerify,
    required this.onSave,
    required this.onReset,
  });

  final GlobalKey<FormState> formKey;
  final bool voiceApiConnected;
  final bool voiceApiChecking;
  final TextEditingController twilioAccountSidController;
  final TextEditingController twilioAuthTokenController;
  final TextEditingController localServerUrlController;
  final TextEditingController twilioPhoneNumberController;
  final TextEditingController deepgramApiKeyController;
  final VoidCallback onVerify;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice-API-Konfiguration',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hier werden die Umgebungsvariablen für Telefonie und Deepgram gesetzt und geprüft.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ConnectionStatusChip(
                  connected: voiceApiConnected,
                  checking: voiceApiChecking,
                ),
                const SizedBox(height: 20),
                EnvField(
                  envName: 'TWILIO_ACCOUNT_SID',
                  label: 'Telefonie Account SID',
                  controller: twilioAccountSidController,
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) return 'Pflichtfeld';
                    if (!trimmed.startsWith('AC') || trimmed.length != 34) {
                      return 'Muss mit AC starten und 34 Zeichen haben';
                    }
                    return null;
                  },
                ),
                EnvField(
                  envName: 'TWILIO_AUTH_TOKEN',
                  label: 'Telefonie Auth Token',
                  controller: twilioAuthTokenController,
                  obscureText: true,
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) return 'Pflichtfeld';
                    if (!RegExp(r'^[A-Za-z0-9]{32}$').hasMatch(trimmed)) {
                      return 'Muss 32 alphanumerische Zeichen haben';
                    }
                    return null;
                  },
                ),
                EnvField(
                  envName: 'LOCAL_SERVER_URL',
                  controller: localServerUrlController,
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) return 'Pflichtfeld';
                    final uri = Uri.tryParse(trimmed);
                    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                      return 'Ungültige URL';
                    }
                    final isLocalHttp = uri.scheme == 'http' &&
                        (uri.host == 'localhost' || uri.host == '127.0.0.1');
                    if (uri.scheme != 'https' && !isLocalHttp) {
                      return 'Erlaubt: https oder http://localhost (nur lokal)';
                    }
                    return null;
                  },
                ),
                EnvField(
                  envName: 'TWILIO_PHONE_NUMBER',
                  label: 'Telefonie Nummer',
                  controller: twilioPhoneNumberController,
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) return 'Pflichtfeld';
                    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(trimmed)) {
                      return 'Format: +49123456789';
                    }
                    return null;
                  },
                ),
                EnvField(
                  envName: 'DEEPGRAM_API_KEY',
                  controller: deepgramApiKeyController,
                  obscureText: true,
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) return 'Pflichtfeld';
                    if (trimmed.length < 20) return 'API Key ist zu kurz';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: voiceApiChecking ? null : onVerify,
                      icon: voiceApiChecking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_protected_setup),
                      label: const Text('Verbindung prüfen'),
                    ),
                    FilledButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.save),
                      label: const Text('Speichern'),
                    ),
                    OutlinedButton(
                      onPressed: onReset,
                      child: const Text('Zurücksetzen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
