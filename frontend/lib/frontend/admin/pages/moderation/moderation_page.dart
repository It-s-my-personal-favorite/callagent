import 'package:flutter/material.dart';

import '../../../../domain/admin_models.dart';

class ModerationPage extends StatelessWidget {
  const ModerationPage({
    super.key,
    required this.blockedCalls,
    required this.onUnblock,
    required this.maskNumber,
  });

  final List<CallSession> blockedCalls;
  final ValueChanged<String> onUnblock;
  final String Function(String) maskNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Moderation', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.builder(
                itemCount: blockedCalls.length,
                itemBuilder: (context, index) {
                  final call = blockedCalls[index];
                  return ListTile(
                    leading: const Icon(Icons.block, color: Colors.red),
                    title: Text(maskNumber(call.callerNumber)),
                    subtitle: Text(call.internalReview.note),
                    trailing: TextButton(
                      onPressed: () => onUnblock(call.id),
                      child: const Text('Entsperren'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
